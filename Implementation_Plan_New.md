# Godot 4 Mobile Prototype Implementation Plan (Transfer Snapshot)

## Current Goal

Deliver a stable 2v2 mobile-first prototype with:

- 7-zone drive progression
- Simulated game clock with enforced half boundary behavior
- Possession / drive / score loop
- Field goals
- Dual-team card economy (both teams progress each play)
- Queued card execution order per play (with ready states)

## Core Architecture

Keep a modular gameplay setup:

- [scripts/game_state.gd](scripts/game_state.gd): authoritative runtime state and transitions
- [scripts/game_scene.gd](scripts/game_scene.gd): flow orchestration and UI wiring
- [scripts/play_resolver.gd](scripts/play_resolver.gd): standard + field goal resolution
- [scripts/card_manager.gd](scripts/card_manager.gd): deck / hand / discard / draw / cost checks
- [scripts/effect_manager.gd](scripts/effect_manager.gd): applied effect lifecycle
- [scripts/targeting_manager.gd](scripts/targeting_manager.gd): target validation (Phase 4+)
- [scripts/player_data.gd](scripts/player_data.gd), [scripts/coach_data.gd](scripts/coach_data.gd): data loading

## Field and Scoring Rules

- 7 zones:
  - Zone 1: own endzone
  - Zone 2: starting field zone
  - Zone 3: field zone
  - Zone 4: long FG range
  - Zone 5: medium FG range
  - Zone 6: short FG range
  - Zone 7: scoring endzone
- Touchdown when `current_zone >= 7`
- Touchdown = +6, Field Goal = +3
- No conversion / extra point / overtime in this version
- Tie at 0:00 is a valid final result

## Clock, Halves, and Possession

- Simulated game clock starts at 5:00 (300s)
- Two halves of 2:30 (150s each)
- Each resolved play / FG consumes 5-8s of simulated time
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

## Drive Rules

- Every possession starts from `next_drive_start_zone`
- Default drive start zone = Zone 2
- Each play costs 1 Drive Point
- Drive ends on:
  - Touchdown
  - Drive points depleted
  - Game time expired
  - Field goal attempt result (make / miss)
- On non-scoring drive end: reset `next_drive_start_zone` to Zone 2
- On scoring drive end: set `next_drive_start_zone` from kicker `kick_power`:
  - Higher kick power => opponent Zone 2
  - Lower kick power => opponent Zone 3

## Field Goal Rules

- Allowed only in Zones 4, 5, 6
- Disabled in Zones 1, 2, 3, 7
- Base chance profile:
  - Zone 6: high
  - Zone 5: medium
  - Zone 4: low
- FG make:
  - +3 points to team in possession
  - Possession switches
- FG miss:
  - Possession switches
- FG consumes simulated play time (5-8s)
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
- `drive_points_depleted`
- `game_time_expired`
- `field_goal`
- `missed_field_goal`

## Card / Momentum System

### Team Progression

- Both teams track independent:
  - `momentum`
  - deck / hand / discard
- Both teams progress each play (not only team in possession)

### Possession-Change Momentum Reset

- On each possession change, both teams reset to exactly 1 momentum
- Start-of-play increment must not immediately push this to 2 on first play after possession change (use one-play skip flag)

### Queue-and-Ready Card Phase

- Each play enters card queue phase before resolve
- Both teams can queue multiple cards in chosen order
- Constraint is momentum threshold (no per-play hard card-count limit)
- Team marks Ready when queue finalized
- After both teams ready, execute queues in alternating index order:
  - Possession team `queue[0]`
  - Non-possession team `queue[0]`
  - Possession team `queue[1]`
  - Non-possession team `queue[1]`
  - Continue until both queues exhausted
- After queue execution, resolve play outcome

### Queue Runtime State

In `GameState`, maintain:

- `queued_cards_home`, `queued_cards_away`
- `queued_momentum_spent_home`, `queued_momentum_spent_away`
- `home_ready`, `away_ready`

## Scene / UI Structure

- [scenes/game_scene.tscn](scenes/game_scene.tscn)
  - Root Control with managers as child nodes
  - HUD labels for clock / half / score / possession / zone / drive points / phase / result
  - Play buttons (Run, Short Pass, Deep Pass, Field Goal, card controls)
  - Player token container and card / target panels
- [scenes/player.tscn](scenes/player.tscn)
  - Root Control with `NameLabel` and `SelectButton`
  - [scripts/player.gd](scripts/player.gd) attached to player root

## Data Files

- [data/players.json](data/players.json)
- [data/cards.json](data/cards.json)
- [data/coaches.json](data/coaches.json)
- [data/plays.json](data/plays.json)

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
- Real-time clock pressure
