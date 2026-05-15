# Simulated play resolution (reference)

Worked examples and formulas for the **whole-play** scrimmage run/pass path (the “fast sim” in `scripts/resolution/`). The **tick sim** ([scripts/simulation/play_tick_engine.gd](../scripts/simulation/play_tick_engine.gd)) reuses the same helpers (`ScrimmageSimCalculators`, `TackleResolver`, `TurnoverResolver`, etc.) where applicable; numbers below match the legacy pipeline unless noted.

**Source of truth (code):** `run_play_resolver.gd`, `pass_sim_resolver.gd`, `matchup_resolver.gd`, `blocking_resolver.gd`, `tackle_resolver.gd`, `turnover_resolver.gd`, `route_resolver.gd`, `scrimmage_sim_calculators.gd`, `balance_constants.gd`.

---

## Run play (numeric walkthrough)

Assume `tile_delta_min = 0`, `tile_delta_max = 12` on the play row.

### 1) Lane strength (OL vs DL)

Summarize line-of-scrimmage edge before the RB’s raw stats.

- Each **DL:** contributes `pass_rush + block_shedding` to a sum; implementation counts **2 per DL** in the divisor (half-stat style average).
- Each **OL:** contributes `(blocking + strength) * 0.5`, count **1 per OL**.

Example: 2 DLs at PR 7 / shed 6 → each adds 13 → `dl_sum = 26`, `dl_n = 4` → `dl_avg = 6.5`.  
2 OLs at blocking 8 / strength 7 → `(8+7)*0.5 = 7.5` each → `ol_avg = 7.5`.

See `MatchupResolver.pick_run_lane_matchup`.

### 2) Crease score

Composite “how open is the hole”:

```
crease = ol_avg - dl_avg * 0.85 - lb_pen * 0.25 + noise_medium * 0.25
```

`lb_pen` = average over LBs of `awareness * 0.35`.  
`noise_medium` = `ResolutionBalanceConstants.noise_medium(rng)` (range −3..+3 in code).

See `BlockingResolver.run_crease_score` (also wrapped by `ScrimmageSimCalculators.run_lane_and_crease`).

### 3) Base run yards

```
base = crease*0.42 + speed*0.55 + agility*0.35 + strength*0.2 + noise_medium*0.35
yards = round(base), then clamp to `[tile_delta_min, tile_delta_max]`.
```

### 4) Tackler and YAC / broken tackle

Uses `TackleResolver.resolve_yards_after_catch` (same helper name as pass completions).

- Tackler pick: ~55% “best” LB (by tackling + awareness), else random DL, else safety.
- `tackle_p = (tackling + strength)*0.35 + awareness*0.15`
- `break_p = (agility + carrying)*0.35 + strength*0.2`
- `margin = tackle_p - break_p + noise_medium*0.4`
- If `margin < 0.8` → broken tackle → extra YAC `randi_range(3, 7)`; else YAC `randi_range(0, 4)`.

Tick sim adds optional `carrier_prior_broken_chain` to make repeat breaks harder.

### 5) Total gain

`total = clampi(yards + extra, tmin, tmax)` (play cap can “eat” YAC).

### 6) Fumble after contact

With tackler: `hit_q = 1 + tackling*0.04 + strength*0.02`; then `TurnoverResolver.roll_fumble_after_contact`. No tackler uses a softer branch in code.

---

## Pass play (short chain)

Same `tile_delta_min` / `tile_delta_max` clamp on final net rows toward goal.

**Tick sim (authority off, pass):** Same per-tick protection sampling and `pass_pressure_tick` logging for `tick_sim_event_log`; tick count is capped to dropback length. After each OL/DL sample, **grid nudge:** each defensive **DL** within **2 tiles** (Chebyshev) of the QB reduces protection by **0.32** (stacking, clamped total nudge **−1.25..0**), then pressure is re-derived via `map_pressure`. Final yards still come from whole-play `PassSimResolver.resolve`. Parallel tick lines are also appended to the play **`breakdown`** (header `--- Tick sim (dropback pressure samples) ---`) for HUD/calc slides.

**Tick sim (authority):** During QB dropback, each sim tick re-samples pass rush + protection (with RNG noise) via `ScrimmageSimCalculators.pass_rush_and_protection(..., emit_log=false)` and logs `pass_pressure_tick` (message includes grid nudge). On the **throw tick**, one full sample (`emit_log=true`, so `pass_ol_dl` + `pass_protection` appear in the breakdown) feeds `PassSimResolver.resolve_with_locked_pass_front` so INT/completion/YAC use that final pressure bucket without a second independent pass-front roll; throw tick applies the same grid nudge to the logged protection score before mapping pressure and resolving.

1. **Pass rush matchup** — DL vs worst OL margin (`MatchupResolver.pick_pass_rush_matchup`).
2. **Protection score** — OL blocking blend + QB awareness − rush edge + noise (`BlockingResolver.pass_protection_score`).
3. **Pressure 0–3** — `ScrimmageSimCalculators.map_pressure(protection_score)` thresholds: ≥22 → 0, ≥18 → 1, ≥14 → 2, else 3.
4. **Separation** — per route / checkdown. **Tick authority at throw:** `PlayTickEngine._receiver_separations_from_world` (live grid distance, man cover, `separation_tier`) passes routes into `PassSimResolver.resolve_with_locked_pass_front`. Formation-only stats via `RouteResolver.receiver_separations` otherwise.
5. **Sack (tick authority)** — Each dropback/throw tick: if a defender shares the QB’s **tile** (Chebyshev 0), `TackleResolver.roll_qb_sack_attempt` uses the standard tackle margin (`< 0.8` = QB evades, else sack). Evade sets contact cooldown; sack ends the play (`PlayTickEngine._compose_sack_play_result`). **Engage** (blocks) stays **adjacent** (`ENGAGE_RANGE_TILES` = 1). **Run tackles** also require same tile (`ScrimmageSimCalculators.can_attempt_tackle`).
6. **Target** — `PassTargetSelector.pick_throw_decision` walks progression (beat + read). If no clean read: Awareness roll → **unwilling throw** (best in-range receiver by `throw_power` max Chebyshev reach ~35–92% of field depth) or **throwaway** (incomplete). Forced primary on step 0 still allowed. `throw_accuracy` boosts completion on unwilling/forced throws; air yards clamped by `dist_from_qb` and arm.
7. **INT** — `TurnoverResolver.roll_interception` (pressure, coverage, separation, safety).
8. **Completion %** — roll vs blended accuracy / pressure / separation / coverage (penalties for unwilling/forced).
9. **Air yards** — `round(2 + sep*2.2 + receiver_speed*0.25 + throw_q*0.35)`, clamped to play min/max and QB arm when grid `dist_from_qb` is known.
10. **YAC / fumble** — same tackle helper + strip check on the receiver (fast path; tick YAC may add same-tile gate later).

### Tick route movement (`RouteRunner`)

- Single offense intent: **`route`** (Play Creator `start_action: route`; WR/TE when waypoints exist).
- **RB (pass):** play `routes` waypoints → `route`; no waypoints → **`pass_block`**.
- Waypoints are **indexed**, not popped; each tick **`step_toward`** the current segment cell (smoother than raw delta snaps).
- After the final waypoint, the receiver **keeps moving** one tile per tick along **`route_stem_dir`** (last segment direction).

### Tick cover zone (`ZoneCoverageRunner`)

- **`intent_action: cover_zone`** from defense play **`role_assignments`** (`PlayAuthoring.start_action_for_role` on `ctx.defense_play_row`), else role defaults (e.g. **S** → zone). Any defensive role can be assigned zone.
- **Monitor box** from defender’s current tile: ±**2** rows (field depth), ±**1** column (`SimConstants.ZONE_MONITOR_*`).
- **Overlapping claims:** each WR/TE/RB in a zone is assigned to the **nearest** Manhattan-distance zone defender; others **drift** without chasing that receiver.
- **Chase target:** among receivers this defender won, step toward **deepest** (smallest `global_row`, toward scoring end).
- **Empty zone:** drift toward deepest receiver **on the defender’s side** (cols `< LOS_BASE_COL` vs `>` vs middle column `== LOS_BASE_COL` uses whole width). Drift **clamped** to anchor ±**3** rows, ±**1** column (`ZONE_DRIFT_*`).
- **Pursue ball carrier:** Pass — after resolve (`pass_done`), carrier ≠ QB → pursue. Run — pursue when `carrier.global_row <= los_row_engine` **or** early via **awareness** roll while RB is still deeper than LOS.
- **Separation:** Zone defenders in the monitor box set **`receiver_zone_pressure_tier`** on receivers; merged with man CB tier in `_receiver_separations_from_world`.

---

## Related

- [Gameplay_Summary.md](Gameplay_Summary.md) — when fast vs tick authority applies.
- [Implementation_Plan.md](Implementation_Plan.md) — architecture and file map.
