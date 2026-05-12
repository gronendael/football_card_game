# Godot 4 Mobile Prototype Implementation Plan (Transfer Snapshot)

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
- [scripts/game_scene.gd](scripts/game_scene.gd): flow orchestration, UI wiring, **field formation preview** (labeled markers from plays → formations; fan-out / offense–defense nudge / defense row shift)
- [scripts/play_resolver.gd](scripts/play_resolver.gd): standard + **spot kick** resolution; ball movement uses **tile deltas** (zones remain for range, modifiers, UI labels)
- [scripts/formations_catalog.gd](scripts/formations_catalog.gd): [data/formations.json](data/formations.json) load/validate (**7** positions per formation, per-role caps; offense positions must have `delta_row` ≥ 0)
- [scripts/plays_catalog.gd](scripts/plays_catalog.gd): [data/plays.json](data/plays.json) load; **`formation_id_for(play_type)`** for offense and defense play-type ids
- [scripts/card_manager.gd](scripts/card_manager.gd): deck / hand / discard / draw / cost checks
- [scripts/effect_manager.gd](scripts/effect_manager.gd): applied effect lifecycle
- [scripts/targeting_manager.gd](scripts/targeting_manager.gd): target validation (Phase 4+)
- [scripts/player_data.gd](scripts/player_data.gd), [scripts/coach_data.gd](scripts/coach_data.gd): data loading

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
- Allowed in **Midfield Zone** only when the kicking player's `kick_power > 80`
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
  - Adjusted by kicker baseline stats (and any skills that modify them):
    - +/- (kick_accuracy - 50) * 0.5
    - +/- (kick_power - 50) * 0.2
    - +/- (kick_consistency - 50) * 0.3
    - minus opponent flat defense modifier
  - Clamp final chance to 50-99
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
- Baseline player stats (authoritative core attributes):
  - `speed`
  - `strength`
  - `awareness`
  - `passing`
  - `catching` (replaces `hands`)
  - `blocking`
  - `tackling`
  - `agility`
  - `coverage`
  - `ball_security`
  - `kick_power`
  - `kick_accuracy`
  - `kick_consistency`
  - `route_running`
  - `stamina`
  - `injury`
  - `toughness`
- Skill system data model:
  - Skill definitions live in separate [data/skills.json](data/skills.json) for scalability
  - Player records reference skill levels (per skill) in [data/players.json](data/players.json)
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
  - **Punt resolution** (`resolve_punt`): punt distance in tile rows from kicker stats. **No Punt Return** → **0** return rows. **Punt Return** → tiered return tile rows (`play_resolver.gd`: bands 0 | 1–5 | 6–19 | 20–29 | 30–34 field cap, NFL-ish base weights, **stats/coach/card modifiers** shift weights via `_build_punt_return_modifiers()` in `game_scene.gd`). **Net** = punt rows − return rows (true difference, can be negative). **Ball spot:** post-punt engine LOS = engine LOS before the punt **minus** `net_rows` (clamped to valid engine rows); **zone** = `zone_from_engine_row` of that row (same mapping as scrimmage ball movement — no `round(net / 5)` zone steps). Event log includes punt / return / net tile rows.
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
  - Root Control with managers as child nodes; **LastPlayToastLayer** (`CanvasLayer` layer 18): **2s** outcome line over **`MobileFrame`** (very large bold italic BBCode ~88px, no background; `game_scene.gd`; yardage toasts: **N yard(s)** only, no “tile rows” duplicate); **`UserPlayButtonsRow`** — **`UserPhasePromptPanel`** (`MarginContainer`) + **`UserPhasePromptLabel`** (uppercase notification, not a button chip)
  - HUD labels for clock / half / score / possession / zone / down / phase / result; **`GlobalHUD`** includes **`PlayCountLabel`** (`Plays: n`, **n** = `_game_plays`); **ClockPanel** includes `ActionTimerProgressBar` (10s when `show_action_timer_bar`); **`ShowActionTimerBarToggle`** on `HUDGroup`; legacy `PlayClockValueLabel` hidden; **UserDownDistanceLabel** on `UserHUD` (`1st and 10` / `3rd and Goal`, tile rows); **`UserPlayButtonsRow`** + **`UserPlayRowPossessionIcon`**; **`SpeedPanel`**: `-` / `+` adjust sim speed, **`SpeedX2`** / **`SpeedX10`** jump to **2×** / **10×** (clamped **0.5–10**); event log: **pre-snap situation** bracket on scrimmage + punt (snap down/`&`/distance or Goal + `FieldGrid.perspective_row` + ⬇️/⬆️ vs midfield; cleared before post-TD conversion; no prefix on 2PT-only `_apply_play_result`); **tile-row play line first**, then **turnover** / **turnover on downs** / **first down** as applicable; **FG** make/miss explicit lines in `_apply_play_result` (`#66ff00` good, `#ff6666` miss + turnover); **Game clock:** `_sync_game_clock_scrimmage_policy()` (end of `_update_ui`) sets `_clock_running` only in `_scrimmage_offense_selecting_window()` when **`not _defer_scrimmage_game_clock_until_first_snap`** (cleared at `_resolve_play` entry; re-armed on **Restart** and `_after_force_halftime_second_half`) unless `_manual_pause_active`, `_auto_pause_after_sim_stop`, or `_game_clock_hold_after_rule_stop` (`_stop_clock(..., true)`); **Sim** pause uses `_sim_tick_paused` + `sim_timer` decoupled from `_clock_running`; **manual** Pause toggles `_manual_pause_active`; **Sim → Man** `_auto_pause_after_sim_stop`. **Halftime:** `_after_force_halftime_second_half` after `force_halftime_now`
  - **`SimStepPanel`** (`HUDGroup/SimStepPanel`, below **`SpeedPanel`**): **1 play at a time** toggle + **Next** — when Sim is on and the toggle is checked, `_sim_try_pause_step_after_play()` pauses `sim_timer` after each resolved scrimmage/punt, XP attempt, and 2PT attempt; **Next** clears `_sim_tick_paused` and restarts the sim tick (`game_scene.gd`).
  - **Play calc log** (`HUDGroup/CalcLogPanel`, right of **`PlayInfoHUD`**): filters map to line categories in `_calc_log_cat_enabled` (`Resolver` / `CalcFilterPost`→**Matchup** / `Outcome` / `Turnover` / `Cards` / `Skills` / `Special` / `Conversion` / `Clock`); **Prev** / **CalcLogNextNav** step slides; `_calc_log_clear()` on Restart and in `_ready` after `start_game`.
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

- [data/players.json](data/players.json)
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
- Economy / ads / meta progression
- Full 7v7 simulation
- Advanced animations
