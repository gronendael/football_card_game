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
- [scripts/game_scene.gd](scripts/game_scene.gd): flow orchestration and UI wiring
- [scripts/play_resolver.gd](scripts/play_resolver.gd): standard + **spot kick** resolution; ball movement uses **tile deltas** (zones remain for range, modifiers, UI labels)
- [scripts/formations_catalog.gd](scripts/formations_catalog.gd): [data/formations.json](data/formations.json) load/validate (**7** positions per formation, per-role caps)
- [scripts/card_manager.gd](scripts/card_manager.gd): deck / hand / discard / draw / cost checks
- [scripts/effect_manager.gd](scripts/effect_manager.gd): applied effect lifecycle
- [scripts/targeting_manager.gd](scripts/targeting_manager.gd): target validation (Phase 4+)
- [scripts/player_data.gd](scripts/player_data.gd), [scripts/coach_data.gd](scripts/coach_data.gd): data loading

## Field and Scoring Rules

- 7 zones, named relative to the team currently in possession:
  - `MyEndZone` (own endzone)
  - `StartZone` (default drive start)
  - `AdvanceZone`
  - `MidfieldZone`
  - `AttackZone`
  - `RedZone`
  - `EndZone` (scoring endzone)
- Internal numeric IDs used by the engine map directly to these names:
  - 1 = `MyEndZone`
  - 2 = `StartZone`
  - 3 = `AdvanceZone`
  - 4 = `MidfieldZone`
  - 5 = `AttackZone`
  - 6 = `RedZone`
  - 7 = `EndZone`
- Zone names are perspective-based: from the offense's point of view, `MyEndZone` is their own endzone and `EndZone` is the scoring endzone. On a possession change, the named zones flip relative to the new offense.
- Code rename: replace numeric zone usage with name-based identifiers in scripts, UI, event log, and breakdowns. All displays should use the named zones (e.g. `RedZone` instead of `Zone 6`).
- Touchdown when offense reaches `EndZone`
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
  - Clock starts only after both teams are Ready on the first turn, or when the 15s Play Clock auto-readies non-ready team(s)
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
- Default drive start zone = `StartZone`
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
  - `MyEndZone` -> defensive touchdown for the team that was not in possession (+6), then normal XP/2PT conversion flow
  - `StartZone` -> `RedZone`
  - `AdvanceZone` -> `AttackZone`
  - `MidfieldZone` -> `MidfieldZone`
  - `AttackZone` -> `AdvanceZone`
  - `RedZone` -> `StartZone`
  - `EndZone` -> `StartZone`

## Field Goal Rules

- Allowed in `AttackZone` and `RedZone`
- Allowed in `MidfieldZone` only when the kicking player's `kick_power > 80`
- Disabled in `MyEndZone`, `StartZone`, `AdvanceZone`, and `EndZone` (unless `MidfieldZone` eligibility is met)
- Base chance profile:
  - `RedZone`: high
  - `AttackZone`: medium
  - `MidfieldZone`: low
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
	- Kick attempt from `AttackZone`
	- Uses kicking stats (similar to a Field Goal)
	- Made: +1 point for scoring team
	- Missed: no additional points
  - 2-Point Conversion (2PT):
	- One play (Run, Short Pass, or Deep Pass) from `RedZone`
	- Card queue + ready phase still applies (cards can affect outcome)
	- Success only if the team advances to `EndZone` on this play -> +2 points
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

### Possession-Change Momentum Reset

- On each possession change, both teams reset to exactly 1 momentum
- Start-of-play increment must not immediately push this to 2 on first play after possession change (use one-play skip flag)

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
- Play Clock:
  - At the start of each play cycle, both teams get 15 real-world seconds total to select play + queue cards + press `Ready` (wall-clock, not game-clock seconds)
gam  - If timer expires, any team not already ready is auto-readied
  - If offense/defense play was missing at timeout, AI picker fills missing play selections for that team
  - Teams that time out do not get auto-queued cards for that turn (already queued cards still execute)

### Turn Phase Order (Loop)

- Start turn
- Resolve start-turn effects
- Draw 1 card per team
- Resolve draw-triggered effects
- Teams select play
- Resolve play-selection triggers
- Teams queue cards
- Resolve queue triggers
- Teams press `Ready`
- Resolve ready triggers
- Resolve play outcome
- End turn
- Resolve end-turn effects

### Queue Runtime State

In `GameState`, maintain:

- `queued_cards_home`, `queued_cards_away`
- `queued_momentum_spent_home`, `queued_momentum_spent_away`
- `home_ready`, `away_ready`

### Dynamic Possession Play UI

- Two team play rows are shown (`AwayPlayButtons`, `HomePlayButtons`) and both teams can select in parallel.
- Team in possession row is offense controls:
  - `Run`, `Short Pass`, `Deep Pass`, `Field Goal`, `Play Card`, `Ready`
- Non-possession row is defense controls:
  - `Run Def`, `Man-to-Man`, `Zone`, `FG Def`, `Play Card`, `Ready`
- Simultaneous play selection flow:
  - Offense selects offensive play
  - Defense selects defensive play (or defaults to `Zone` by pressing `Ready`)
  - Both teams press `Ready`
  - Card queue phase starts (or play resolves directly if card phase disabled)
- Simultaneous card queue flow:
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
  - Root Control with managers as child nodes
  - HUD labels for clock / half / score / possession / zone / down / phase / result; event log uses tile rows toward goal per play and teal **First down** lines
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
- Opponent AI acts immediately when input is needed (play selection, defense call, card queue ready).
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
- [data/coaches.json](data/coaches.json)
- [data/plays.json](data/plays.json) (play ids + `formation_id` + metadata; **spot_kick** replaces legacy field goal key)
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
