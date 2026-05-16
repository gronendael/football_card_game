# Godot 4 Mobile Prototype Implementation Plan (Transfer Snapshot)

## Product vision — IFL

Futuristic **Intergalactic Football League (IFL)**: franchise-owned **unique generated** rosters; shared template catalogs (species, archetype, trait, coordinator). Football-first sim and UI; sci-fi supports identity, scouting, and long-term content—not combat or magic.

**Design docs:** [Worldbuilding.md](Worldbuilding.md), [Systems.md](Systems.md), [Data_Architecture.md](Data_Architecture.md), [Player_Generation.md](Player_Generation.md), [Balancing.md](Balancing.md), [Progression.md](Progression.md), [Art_Direction.md](Art_Direction.md).

**Stat scale:** all player stats **1–10** ([Balancing.md](Balancing.md), [Properties.md](Properties.md)). Prototype `data/players.json` already uses this scale.

## Current Goal

Deliver a stable 2v2 mobile-first prototype with:

- 7-zone drive progression
- Real-time game clock with enforced half boundary behavior
- Possession / drive / score loop
- Turnover system (downs, fumble, interception, missed FG)
- Field goals
- Post-touchdown conversions (Extra Point and 2-Point)
- Dual-team card economy (both teams progress each play)
- Queued card execution order per play (with ready states)

## Core Architecture

Keep a modular gameplay setup:

- [scripts/game_state.gd](scripts/game_state.gd): authoritative runtime state and transitions; **`current_los_row_engine`** holds LOS tile row, **`current_zone`** derived after each move
- [scripts/game_scene.gd](scripts/game_scene.gd): flow orchestration, UI wiring, **field lineup markers** (`Field` / `FieldLineupMarkers` on `field_grid`): after offense/defense plays are visible to the user, chips at formation tiles use **slotted roster names** ([PlaySimContext.lineup_slots](scripts/resolution/play_sim_context.gd), same rules as sim) plus fan-out / O–D separation; HUD **PlayerToken** grids remain for roster pick / details. **Tick sim playback** uses separate `SimPlaybackMarkers`. Builds **`PlaySimContext`** for run/pass and applies **`turnover_outcome`** from the sim (skips legacy `_roll_turnover_if_any` when present)
- [scripts/play_resolver.gd](scripts/play_resolver.gd): thin node delegating **run/pass** to [scripts/resolution/scrimmage_play_resolver.gd](scripts/resolution/scrimmage_play_resolver.gd) and **punt / spot kick / XP** to [scripts/resolution/special_teams_resolver_legacy.gd](scripts/resolution/special_teams_resolver_legacy.gd); ball movement uses **tile deltas**
- [scripts/resolution/](scripts/resolution/): modular stat-only scrimmage sim (`PlaySimContext`, `PlayerStatView`, matchup/blocking/route/pass/run/tackle/turnover helpers, `balance_constants.gd`) — no UI, no skills/cards/coach in this path yet. Shared **outcome calculators** live in [scripts/resolution/scrimmage_sim_calculators.gd](scripts/resolution/scrimmage_sim_calculators.gd) (pressure map, pass rush/protection bundle, run lane/crease, per-pair separation tiers) for reuse by tick sim and tests.
- [scripts/play_route_templates.gd](scripts/play_route_templates.gd): default offense run/pass routes, role actions, progression for formations; used at runtime when play JSON is incomplete.
- [scripts/pass_target_selector.gd](scripts/pass_target_selector.gd): QB progression targeting (coverage beat + awareness/pressure reads, early throw timing); called from `PassSimResolver` and tick dropback.
- [scripts/simulation/](scripts/simulation/): **tick play sim** ([scripts/simulation/play_tick_engine.gd](scripts/simulation/play_tick_engine.gd), **4 Hz** in [scripts/simulation/sim_constants.gd](scripts/simulation/sim_constants.gd)) — `SimWorld` / `SimPlayerState`, per-tick snapshots, `tick_sim_event_log` (extends [scripts/resolution/play_event_log.gd](scripts/resolution/play_event_log.gd) with optional `tick` / `global_row` / `global_col`). **Modes:** default **fast path** = existing whole-play `RunPlayResolver` / `PassSimResolver` (unchanged for balance/Monte Carlo). **Tick sim authority** (`PlayTickEngine.tick_authoritative`, Debug menu “Tick sim authority”) = tick orchestration owns run/pass outcome; legacy resolvers used as calculators inside ticks / fallback if tick result empty. **Pass + authority:** each pre-throw tick re-samples protection/pressure (silent logs); after each sample, a small **grid nudge** lowers protection when defensive DLs are within **2 tiles** (Chebyshev) of the QB, then pressure is re-mapped from the adjusted score; throw tick logs full OL/DL matchup lines once, then `PassSimResolver.resolve_with_locked_pass_front` applies that front to routes/INT/completion. **Parallel pass (authority off):** tick loop is capped to QB dropback length only; each tick still logs `pass_pressure_tick` (with grid nudge) into `tick_sim_event_log`, and those lines are also appended to the main play **`breakdown`** for HUD/calc visibility, while the whole-play pass resolver sets the outcome. **Playback** (`PlayTickEngine.visual_playback_enabled`, “Tick sim playback”) interpolates markers on the field from `play_result["tick_snapshots"]` ([scripts/simulation/sim_playback_controller.gd](scripts/simulation/sim_playback_controller.gd)); `_apply_play_result` is deferred until playback ends (`_pending_play_result_after_playback`); frozen snap possession for marker perspective (`_playback_offense_seat`); AI tick blocked while playback pending.
- [scripts/simulation/zone_coverage_runner.gd](scripts/simulation/zone_coverage_runner.gd) + [zone_coverage_profile.gd](scripts/simulation/zone_coverage_profile.gd): **`cover_zone`** soft threat scoring (field-wide ≤7 tiles, stacking penalties, role profiles), single-target tile movement + **facing** prediction, `receiver_zone_pressure_tier` from best defender, visual lean on snapshots. Defense **`role_assignments`** via **`PlaySimContext.defense_play_row`**.
- [scripts/formations_catalog.gd](scripts/formations_catalog.gd): [data/formations.json](data/formations.json) load/validate (**7** positions per formation, required **`formation_shell`**, shell/`side` consistency, per-role caps including **GUN**; offense positions must have `delta_row` ≥ 0). Public `validate_formation_dict` for the formation editor tool.
- [scripts/plays_catalog.gd](scripts/plays_catalog.gd): [data/plays.json](data/plays.json) load; **`formation_id_for(play_type)`** for offense and defense play-type ids
- [scripts/card_manager.gd](scripts/card_manager.gd): deck / hand / discard / draw / cost checks
- [scripts/effect_manager.gd](scripts/effect_manager.gd): applied effect lifecycle
- [scripts/targeting_manager.gd](scripts/targeting_manager.gd): target validation (Phase 4+)
- [scripts/player_data.gd](scripts/player_data.gd), [scripts/coach_data.gd](scripts/coach_data.gd): data loading
- [scripts/species_catalog.gd](scripts/species_catalog.gd): [data/species.json](data/species.json) load/validate; player `species_id` on roster rows (UI/details only in prototype — sim math unchanged)

## Scrimmage resolution reference

Worked numeric examples and formula notes for the **whole-play** run/pass path (fast sim) are in [docs/Simulated_Play_Resolution.md](docs/Simulated_Play_Resolution.md). The plain-text pointer file [docs/Simulated Play Resolution.txt](Simulated%20Play%20Resolution.txt) redirects there. Tick sim reuses the same resolver math where possible ([scripts/resolution/scrimmage_sim_calculators.gd](scripts/resolution/scrimmage_sim_calculators.gd), [scripts/simulation/play_tick_engine.gd](scripts/simulation/play_tick_engine.gd)).

## Field and Scoring Rules

- 7 zones; `current_zone` is always for the **possession (offense)** team. IDs `GameState.ZONE_MY_END` … `ZONE_END` (1–7). **Card modifiers use zone ID** (see [docs/Properties.md](docs/Properties.md) FIELD ZONES).
- **Offense display names:** Defensive Endzone → Build Zone → Advance Zone → Midfield Zone → Attack Zone → Red Zone → Scoring Endzone.
- **Defense display names** (same ID, defending team’s lens / user on D in HUD): Scoring Endzone → Contain Zone → Control Zone → Midfield Zone → Pressure Zone → Goal Line Zone → Defensive Endzone.
- HUD zone label: `_zone_display_for_team` in [scripts/game_scene.gd](scripts/game_scene.gd). Logs / resolver text use offense `_zone_name` as canonical for the possession.
- Touchdown when offense reaches **Scoring Endzone** (ID 7)
- Touchdown = +6, Field Goal = +3
- Tie at 0:00 is a valid final result

## Clock, Halves, and Possession

- Real-time game clock starts at 5:00 (300s)
- Two halves of 2:30 (150s each)
- Clock counts down at 2 game-seconds per real second at sim speed x1; sim speed multiplies this rate
- Plays do not consume per-play clock time
- Clock stops on:
  - Any turnover (downs, fumble, interception, missed FG)
  - Any score (TD, FG, future safety)
  - Throughout post-TD conversion (Extra Point and 2-Point)
  - Any change of possession (kickoff window)
  - Any team timeout (3 per team for the entire game)
  - Future: player injury, penalty
- Clock resumes when both teams hit Ready on the next play
- Ready-wait behavior in card queue:
  - If offense presses `Ready` while defense is not ready and the clock is running, pause the clock while waiting
  - When defense presses `Ready`, resume only if the clock was running before that pause
- Game-start clock gate:
  - Clock remains stopped at game start
  - Clock starts only after both teams are Ready on the first turn, or when the **10s** card-queue timer auto-readies non-ready team(s)
- First-half boundary behavior:
  - Halftime triggers at 2:30 regardless of drive completion
  - If a final pre-halftime play scores (TD / FG), that score must count
  - Clock must not run below 2:30 in first half when crossing boundary
- Second-half start behavior:
  - 2nd half always starts at exactly 2:30
  - Opening possession determined by coin flip at game start
  - 2nd half opening possession is the team that did not receive opening possession
- Possession change rule:
  - Normal alternating possessions after drives
  - Halftime transition must not double-switch possession

### Timeouts

- Each team has 3 timeouts for the entire game (no per-half reset)
- Calling a timeout stops the clock until the next play is Ready
- Sim auto-calls a timeout only when:
  - Under 0:30 remaining in current half
  - Calling team is trailing by 1-8 points
  - Calling team has at least 1 timeout remaining
- Human mode: per-team Timeout button, callable while clock is running

## Drive Rules

- Every possession starts from `next_drive_start_zone`
- Default drive start zone = **Build Zone** (`ZONE_START`, ID 2)
- Downs start at **1** on each new possession and increment after plays that do not earn a new first down (up to **4**).
- A **first down** is earned when the ball reaches or crosses **10 tile rows** toward the opponent’s goal from the line of scrimmage that started the current first-down chain; downs reset to **1** and a new 10-row target is set from the new LOS row.
- **Goal to go:** when LOS is within **10 tile rows** of the scoring endzone, no first-down line is shown; yardage cannot earn a new first down; downs still run **1–4** toward a TD or FG; the **full scoring endzone** is highlighted in yellow on the field.
- **Scoring** field goals skip the normal down increment (possession ends); **missed** field goals still advance downs like other plays.
- Drive ends on:
  - Touchdown
  - Turnover on downs (4th down ends without a new first down and no other possession-changing outcome on that play)
  - Game time expired
  - Field goal attempt result (make / miss)
- On any turnover or change of possession, the team gaining possession starts based on where possession changed:
  - **Defensive Endzone** (ID 1) → defensive touchdown for the team that was not in possession (+6), then normal XP/2PT conversion flow
  - **Build Zone** → **Red Zone**
  - **Advance Zone** → **Attack Zone**
  - **Midfield Zone** → **Midfield Zone**
  - **Attack Zone** → **Advance Zone**
  - **Red Zone** → **Build Zone**
  - **Scoring Endzone** → **Build Zone**

## Field Goal Rules

- Allowed in **Attack Zone** and **Red Zone**
- Allowed in **Midfield Zone** only when the kicking player's `kick_power > 7` (stats are **1–10**)
- Disabled in **Defensive Endzone**, **Build Zone**, **Advance Zone**, and **Scoring Endzone** (unless Midfield eligibility is met)
- Base chance profile:
  - **Red Zone:** high
  - **Attack Zone:** medium
  - **Midfield Zone:** low
- FG make:
  - +3 points to team in possession
  - Possession switches
- FG miss:
  - Possession switches
  - Treated as turnover using turnover field-position mapping
- FG does not consume per-play clock time
- Kicker selection:
  - Use selected kicker if provided
  - Fallback to highest `kick_accuracy` on possessing team if none selected

## PlayResult Contract

All resolves must return:

- `play_type`
- `selected_player_id`
- `success`
- `zone_delta`
- `score_delta`
- `possession_switch`
- `clock_seconds_used`
- `result_text`
- `breakdown` (short explanatory strings)
- **Scrimmage extensions (run/pass):** `turnover_outcome` (`occurred`, `ended_by`, `start_zone` may be `-1` until `game_scene` patches post-movement, `text`, `calc_lines` — resolvers leave `calc_lines` empty so the play calc log does not duplicate `breakdown`; `_roll_turnover_if_any` in `game_scene` still fills `calc_lines` for post-snap checks), `event_log` (structured sim events; same narrative as `breakdown` messages), `key_matchups` (subset of `event_log` by `code`: `pass_ol_dl`, `run_ol_dl`, `route_sep`, `pass_pressure_tick`, `pass_protection`, `qb_pressure`), `play_type_bucket`, `incomplete_pass`, `pressure_level`, `target_receiver_id`, `tackled_by_id`, `broken_tackles`

Note: engine uses **`tile_delta`** (signed tile rows toward goal) for ball movement; older docs may say `zone_delta`.

## Drive Summary Hook

At possession end, append summary with:

- `possession_team`
- `plays_used`
- `zones_gained`
- `points_scored`
- `ended_by`

Allowed `ended_by` values:

- `touchdown`
- `game_time_expired`
- `field_goal`
- `missed_field_goal`
- `turnover_on_downs`
- `fumble_recovery`
- `interception`
- `extra_point_made`
- `extra_point_missed`
- `two_point_made`
- `two_point_failed`

Note: possession summaries still use **`field_goal`** / **`missed_field_goal`** above; the **offensive play type id** in [data/plays.json](data/plays.json) and sim code is **`spot_kick`** (FG + XP).

## Card / Momentum System

### Team Progression

- Both teams track independent:
  - `momentum`
  - deck / hand / discard
- Both teams progress each play (not only team in possession)
- Card draw cadence:
  - At game start, each team draws 2 cards
  - At start of turn (before play selection), each team draws 1 card
  - First turn expectation: each team has 3 cards before first play selection (2 pre-game + 1 start-turn draw)
  - No additional draw occurs when card queue phase starts

## Post-Touchdown Conversions

- After every touchdown, the scoring team gets a single conversion attempt before the kickoff.
- Two options:
  - Extra Point (XP):
    - Kick attempt from **Attack Zone**
    - Uses kicking stats (similar to a Field Goal)
    - Made: +1 point for scoring team
    - Missed: no additional points
  - 2-Point Conversion (2PT):
    - One play (Run, Short Pass, or Deep Pass) from **Red Zone**
    - Card queue + ready phase still applies (cards can affect outcome)
    - Success only if the team advances to **Scoring Endzone** on this play -> +2 points
    - Failure (zero or negative zone change) -> no additional points
- Extra Point probability:
  - Base 80% chance made
  - Adjusted by kicker baseline stats on **1–10** scale (and any skills that modify them); `kick_consistency` defaults to `(kick_accuracy + kick_power) / 2` when absent:
    - `+ (kick_accuracy - 5) * 4` percentage points
    - `+ (kick_power - 5) * 3` percentage points
    - `+ (kick_consistency - 5) * 2` percentage points
    - minus opponent flat defense modifier
  - Clamp final chance to 5–95
- Choice UX:
  - Human mode: present `Extra Point` and `2-Point` buttons
  - Sim mode: auto-pick using post-TD score differential (scoring_team - opponent):
    - Pick 2-Point when differential equals exactly one of: -2, -5, -8, -10, +1, +5, +12
    - Otherwise pick Extra Point
- Post-conversion behavior:
  - Normal post-TD kickoff is performed using the existing kicker `kick_power` rule
  - Conversion result does not change kickoff logic
- New `ended_by` values used for conversion outcomes:
  - `extra_point_made`
  - `extra_point_missed`
  - `two_point_made`
  - `two_point_failed`

## Turnovers and Player Stats

### Scrimmage stat-only resolution (prototype)

- **Run** and **pass** outcomes are produced by `ScrimmagePlayResolver` using formations (offense + defensive call’s `formation_id`), raw roster stats, and injected RNG. No card, coach, `EffectManager`, or skill modifiers apply to this path yet.
- Turnovers on scrimmage (**interception**, **fumble**) are decided inside the sim and returned as `turnover_outcome`; `game_scene` applies **`start_zone`** after LOS movement when the sim left it unset (`-1`).
- **Punt / FG / XP** still use `SpecialTeamsResolverLegacy` (global RNG, prior behavior).

- Turnover types:
  - Turnover on downs (4th down without a new first down)
  - Fumble recovery (run or post-catch on pass)
  - Interception (pass plays only)
  - Missed field goal
- Defensive matchup selection is position-based defaults:
  - Run/fumble checks: LB or S profile
  - Short/deep pass interception checks: CB or S profile
  - Pass pressure influence via pass-rush profile
- Offensive ball carrier source is play-type role based:
  - Run uses runner role
  - Pass uses receiver role
- Baseline player stats in roster JSON (**1–10** integers; see [docs/Properties.md](docs/Properties.md)): `speed`, `strength`, `stamina`, `awareness`, `acceleration`, `catching`, `carrying`, `agility`, `toughness`, `tackling`, `throw_power`, `throw_accuracy`, `blocking`, `route_running`, `pass_rush`, `coverage`, `block_shedding`, `kick_power`, `kick_accuracy`. `PlayerStatView` still accepts legacy keys `passing` / `ball_security` if present. `injury` reserved for future use.
- Match sim uses **field packages** from each franchise’s 17-player roster order in [data/teams.json](data/teams.json) (`roster_player_ids`: offense field group, defense field group, kicker, punter, returner).
- Skill system data model:
  - Skill definitions live in separate [data/skills.json](data/skills.json) for scalability
  - Player records may include optional per-skill levels in [data/players.json](data/players.json) (generated prototype rosters omit `skills`)
  - Skill levels use range `1-10`
  - Skills may apply:
    - stat modifiers (point-based)
    - percentage chance modifiers
- Skill scaling rules:
  - Modifier skills change target stat by increments of `1` per level
  - Percentage skills change chance by increments of `0.5%` per level
- Initial skills:
  - `ball_stripping`: increases defender fumble-causing chance (%)
  - `ball_hawk`: increases defender interception chance (%)
  - `big_hit`: adds modifier to `tackling` and increases fumble-causing chance (%)
  - `frozen_rope`: adds modifier to `passing`
  - `wrap_it_up`: adds modifier to baseline `ball_security`
- Turnover chance profile:
  - Keep overall turnover frequency low (target ~5-8% of plays before tuning)
- Turnover notifications:
  - Use high-visibility UI text when a turnover occurs

### Possession-Change Momentum

- **No reset** on `start_possession`: each team keeps its momentum bank across drives (non‑negative integers, **no maximum** in `game_scene.gd`). New game / restart: `start_game` sets both to **1** before the opening `start_possession`.
- Start-of-play **+1** to both teams must not run on the **first** play after a possession change (use `just_started_possession` skip in `_advance_both_teams_resources`).

### Queue-and-Ready Card Phase

- Each play enters card queue phase before resolve
- Both teams can queue multiple cards simultaneously
- Constraint is momentum threshold (no per-play hard card-count limit)
- Each team marks Ready independently when their queue is finalized
- After both teams ready, execute queues in alternating index order:
  - Possession team `queue[0]`
  - Non-possession team `queue[0]`
  - Possession team `queue[1]`
  - Non-possession team `queue[1]`
  - Continue until both queues exhausted
- After queue execution, resolve play outcome
- Manual card input behavior:
  - In manual mode, user queues cards by dragging/clicking specific hand cards into queue (no required `Play Card` button usage)
  - Queued cards can be removed back to hand before user presses `Ready`
- Play clock / action timer (HUD **`ActionTimerProgressBar`** + toggle **`ShowActionTimerBarToggle`** / export **`show_action_timer_bar`**; replaces legacy combined play clock for scrimmage):
  - When **`show_action_timer_bar`** is **`false`**: timer **does not run** — no bar, no countdown, no delay-of-game / defense AI timeout pick / card-queue auto-ready from the timer (analysis mode). When **`true`**: full behavior below.
  - **Inspector / HUD:** same flag; toggling off mid-window calls `_stop_turn_action_timer()`; toggling on during `PHASE_PLAY_SELECTION` or `PHASE_CARD_QUEUE` restarts a full **10s** window.
  - **Play selection:** offense has **10s** to set a **tentative** play + **Call Play** (button disabled until tentative); on expiration → delay of game (LOS back one tile row toward own goal when not already on hold row `TILE_ROWS_TOTAL - 2`), then another **10s** offense window. After offense locks, defense has **10s** for tentative + **Call Play**; on expiration before defense calls → AI recommended defense is selected and locked. **XP:** primary slot shows **Call Play** disabled for the conversion team before auto-resolve.
  - Offense AI in sim/autoplay uses situational punt logic (`_sim_should_call_punt`) based on down, zone, score differential, and current-half time left.
  - **Punt resolution** (`resolve_punt`): punt distance in tile rows from kicker stats. **No Punt Return** → **0** return rows. **Punt Return** → tiered return tile rows (`play_resolver.gd`: bands 0 | 1–5 | 6–19 | 20–29 | 30–34 field cap, football-calibrated base weights, **stats/coach/card modifiers** shift weights via `_build_punt_return_modifiers()` in `game_scene.gd`). **Net** = punt rows − return rows (true difference, can be negative). **Ball spot:** post-punt engine LOS = engine LOS before the punt **minus** `net_rows` (clamped to valid engine rows); **zone** = `zone_from_engine_row` of that row (same mapping as scrimmage ball movement — no `round(net / 5)` zone steps). Event log includes punt / return / net tile rows.
  - **Touchback LOS (row 25):** Opening possession (`start_game`), halftime second half (`force_halftime_now`), post-score **kickoff**, and punt into **endzone** (`zone_after >= ZONE_END` → `next_drive_los_row_engine` + `end_possession`) all use `GameState.TOUCHBACK_LOS_ROW_ENGINE` via `start_possession(..., los_row_override)`. **Event log:** `_append_touchback_event_log(suffix)` after each of those flows (opening kickoff, halftime, post-TD kickoff, punt endzone).
  - **Card queue:** **10s** simultaneous window (only when play clock on); on expiration → auto-ready **empty** for teams not ready.
  - Decrement uses **real delta time** in `_process` (not tied to running game clock ticks).
  - **Forfeit (per tracked team):** 3 consecutive completed turns with **no manual play call** for that team’s role and **no cards played**; `scripts/game_scene.gd` (`_evaluate_inaction_streaks_for_completed_turn`).
- Post-TD: `PHASE_CONVERSION` with empty `conversion_type` → scoring team chooses **XP** or **2PT** (`ExtraPointButton` / `TwoPointButton`). **XP:** `_choose_conversion(CONVERSION_XP)` → `_run_extra_point_attempt()` (kicker stats). **2PT:** `_choose_conversion(CONVERSION_2PT)` → normal play-selection / resolve path. Sim / AI scoring team: `_maybe_run_ai_inputs` + `_sim_pick_conversion()`.

### Turn Phase Order (Loop)

- Start turn
- Resolve start-turn effects
- Draw 1 card per team
- Resolve draw-triggered effects
- Offense selects tentative play + **Call Play** (10s bar when play clock on; **Call Play** disabled until tentative)
- Defense selects tentative play + **Call Play** (10s bar when play clock on; AI auto-calls on timeout; **Call Play** disabled until tentative)
- Teams queue cards + **Ready** (10s bar when play clock on; auto-ready empty on timeout; **Ready** not blocked by zero cards)
- Execute queued cards
- Resolve play outcome
- End turn
- Resolve end-turn effects

### Queue Runtime State

In `GameState`, maintain:

- `queued_cards_home`, `queued_cards_away`
- `queued_momentum_spent_home`, `queued_momentum_spent_away`
- `home_ready`, `away_ready`

### Dynamic Possession Play UI

- Two team play rows are shown (`OpponentPlayButtons`, `UserPlayButtons` inside `UserPlayButtonsRow` mapped by seat); **`UserPlayRowPossessionIcon`** (🏈 offense / 🛡️ defense for the user’s current scrimmage role). **Offense picks before defense** on scrimmage downs.
- Offense row: **Run / Pass / Field Goal / Punt** (as enabled) open **`PlayPickPopup`** on a **`CanvasLayer`** — scrollable **`play_pick_card`** tiles (name + 3×3 formation thumbnail), **✕** top-right, large green **Call Play** bottom-right; **`UserReadyButton`** / opponent primary slot stays labeled **`Ready`** and commits the tentative offense play (**disabled** until a tentative play exists).
- Defense row: defense categories → same picker; **`Ready`** commits defensive tentative play after offense has locked (**disabled** until tentative exists). Card phase: **`Ready`** not blocked by zero cards (still disabled when already readied / AI / wrong phase).
- Formation preview privacy (multiplayer-ready rule): before **`Ready`** commits the line, only the selecting team sees its own tentative formation; opponent sees it only after that team calls. During defense window, defense can see called offense formation plus its own tentative defense formation.
- Card queue flow:
  - Both teams can queue cards concurrently
  - Both teams press `Ready` independently
  - Resolution begins only when both are ready
- This first pass includes light defensive effects:
  - `Run Def` improves defense against `Run`
  - `Man-to-Man` improves defense against `Short Pass` / `Deep Pass`
  - `Zone` is neutral baseline
  - `FG Def` improves defense against `Field Goal` and `Extra Point`

## Scene / UI Structure

- [scenes/game_scene.tscn](scenes/game_scene.tscn)
  - Root Control with managers as child nodes; **`TopRightBar`** (`HBoxContainer`): **`ToolsMenuButton`** (`MenuButton`, **Tools** popup — **Formation tool…** → [`scenes/formation_tool.tscn`](scenes/formation_tool.tscn); **Test Play…** → [`scripts/test_play_screen.gd`](scripts/test_play_screen.gd); **Play Creator…** → [`scripts/play_creator_tool.gd`](scripts/play_creator_tool.gd); conventions in [Tools.md](Tools.md)) and **`QuitButton`**; **LastPlayToastLayer** (`CanvasLayer` layer 18): **2s** outcome line over **`MobileFrame`** (very large bold italic BBCode ~88px, no background; `game_scene.gd`; yardage toasts: **N yard(s)** only, no “tile rows” duplicate); **`UserPlayButtonsRow`** — **`UserPhasePromptPanel`** (`MarginContainer`) + **`UserPhasePromptLabel`** (uppercase notification, not a button chip)
  - HUD labels for clock / half / score / possession / zone / down / phase / result; **`GlobalHUD`** includes **`PlayCountLabel`** (`Plays: n`, **n** = `_game_plays`); **ClockPanel** includes `ActionTimerProgressBar` (10s when `show_action_timer_bar`); **`ShowActionTimerBarToggle`** on `HUDGroup`; legacy `PlayClockValueLabel` hidden; **UserDownDistanceLabel** on `UserHUD` (`1st and 10` / `3rd and Goal`, tile rows); **`UserPlayButtonsRow`** + **`UserPlayRowPossessionIcon`**; **`SpeedPanel`**: `-` / `+` adjust sim speed, **`SpeedX2`** / **`SpeedX10`** jump to **2×** / **10×** (clamped **0.5–10**); event log: **pre-snap situation** bracket on scrimmage + punt (snap down/`&`/distance or Goal + `FieldGrid.perspective_row` + ⬇️/⬆️ vs midfield; cleared before post-TD conversion; no prefix on 2PT-only `_apply_play_result`); **tile-row play line first**, then **turnover** / **turnover on downs** / **first down** as applicable; **FG** make/miss explicit lines in `_apply_play_result` (`#66ff00` good, `#ff6666` miss + turnover); **Game clock:** `_sync_game_clock_scrimmage_policy()` (end of `_update_ui`) sets `_clock_running` only in `_scrimmage_offense_selecting_window()` when **`not _defer_scrimmage_game_clock_until_first_snap`** (cleared at `_resolve_play` entry; re-armed on **Restart** and `_after_force_halftime_second_half`) unless `_manual_pause_active`, `_auto_pause_after_sim_stop`, or `_game_clock_hold_after_rule_stop` (`_stop_clock(..., true)`); **Sim** pause uses `_sim_tick_paused` + `sim_timer` decoupled from `_clock_running`; **manual** Pause toggles `_manual_pause_active`; **Sim → Man** `_auto_pause_after_sim_stop`. **Halftime:** `_after_force_halftime_second_half` after `force_halftime_now`
  - **`SimStepPanel`** (`HUDGroup/SimStepPanel`, below **`SpeedPanel`**): **1 play at a time** toggle + **Next** — when Sim is on and the toggle is checked, `_sim_try_pause_step_after_play()` pauses `sim_timer` after each resolved scrimmage/punt, XP attempt, and 2PT attempt; **Next** clears `_sim_tick_paused` and restarts the sim tick (`game_scene.gd`).
  - **Play calc log** (`HUDGroup/CalcLogPanel`, right of **`PlayInfoHUD`**): `_calc_log_cat_enabled` — **Resolver** and **Matchup** (`CalcFilterPost`) share visibility for resolver-category lines (either filter **on** shows them; both **off** hides that block); other filters map to `Outcome` / `Turnover` / `Cards` / `Skills` / `Special` / `Conversion`. Section headers (`── … ──`) use a union of the categories in that block: the header appears only if at least one of those filters is on **and** at least one following content line in that block would be visible (avoids orphan headers, including mixed-category slides). No separate clock calc-log filter (presnap runoff is not logged here). **Prev** / **CalcLogNextNav** step slides; `_calc_log_clear()` on Restart and in `_ready` after `start_game`.
  - [scenes/field.tscn](scenes/field.tscn): **`BallChip`** (`Label`, football emoji at LOS; possession tint); removed legacy `BallMarker` / `PossessionArrow` / `PossessionOnFieldLabel`
  - `UserTeamLabel` showing random per-game assignment (`You are: Home/Away`)
  - Play buttons (Run, Short Pass, Deep Pass, Field Goal, card controls)
  - Player token container and card / target panels
  - `Field` / [scripts/field_grid.gd](scripts/field_grid.gd): `is_user_perspective_home` is set from `(_user_team == "home")` on assign/restart so the **local** offense always advances toward the **top** of the field (multiplayer-ready per-client seat).
- [scenes/player.tscn](scenes/player.tscn)
  - Root Control with `NameLabel` and `SelectButton`
  - [scripts/player.gd](scripts/player.gd) attached to player root

## Single-Player Control Architecture (Current)

- On each game start/restart, user is randomly assigned `home` or `away`.
- User controls only their assigned team for offense/defense play picks and card queue actions.
- Opponent team is always AI-controlled.
- Opponent AI acts immediately when input is needed (offense commit, defense call after offense locks, card queue ready).
- `SimButtons` provide optional autoplay for the user's team:
  - When enabled, user team input is AI-driven too
  - When disabled, user team remains manual while opponent stays AI
- User controls include a `Forfeit` action:
  - Forfeit is available only on the visible user-controlled side
  - Manual forfeit scoring:
	- If forfeiting team is leading, final score is forced to `7-0` loss for forfeiting team
	- If forfeiting team is losing, current score becomes final
- Inactivity forfeit (user-controlled team only):
  - If user fails to press `Ready` for 3 consecutive turns, user team forfeits automatically
  - Auto-forfeit logs event and final score outcome
- This architecture is single-player only; multiplayer can be layered later without changing core game rules/state.

## Data Files

- [data/players.json](data/players.json) (global `id`, franchise `team`, bio + 1–10 stats)
- [data/teams.json](data/teams.json) (`roster_player_ids` per franchise)
- [data/skills.json](data/skills.json)
- [data/cards.json](data/cards.json)
- [data/coaches_catalog.json](data/coaches_catalog.json) (OC/DC ids referenced by [data/teams.json](data/teams.json); `bonus_offense` / `bonus_defense`)
- [data/playbooks/](data/playbooks/) per-team playbook JSON (`play_ids`, `max_slots`; validated vs catalog)
- [data/plays.json](data/plays.json) (catalog: each play id has `play_type` bucket — **run**, **pass**, **run_def**, **pass_def**, **spot_kick**, **punt**, **fg_xp_def**, **punt_return**, specials, etc.)
- [data/formations.json](data/formations.json)

Use typed conversion when loading JSON arrays to satisfy typed GDScript arrays.

## Stability Checklist for Transfer

- Type warnings treated as errors are resolved (explicit types / casts where needed)
- Scene node types match attached scripts (Control scripts on Control nodes)
- Node paths in scripts exactly match scene tree names
- `start_game()` and `_load_data()` ordering avoids wiping initialized card state
- Opening hands initialize correctly for both teams (non-zero)
- Halftime boundary behavior verified with scoring play at boundary
- Game-over phase prevents additional scoring / actions
- Queue-ready alternating execution works with unequal queue lengths

## Out of Scope

- Multiplayer
- Full recruitment economy implementation (design: [Progression.md](Progression.md); monetization philosophy only in V1)
- Species/training generation pipelines in code (design: [Data_Architecture.md](Data_Architecture.md), [Player_Generation.md](Player_Generation.md))
- Full 7v7 simulation
- Advanced animations
