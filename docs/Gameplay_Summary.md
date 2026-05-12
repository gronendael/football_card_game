Mobile Football Game - Master Gameplay Summary
Merged version including finalized design decisions.
GAMEPLAY SUMMARY

PRE-GAME
- Coin Toss
-- Away player selects heads or tails
-- Random coin flip
-- Team that wins the coin toss chooses either Kickoff or Receive
--- Kickoff -> 1st half - Kickoff to the other team; 2nd half - Receive kickoff from other team
--- Receive -> 1st half - Receive kickoff from other team; 2nd half - Kickoff to the other team

START GAME

1ST HALF KICKOFF
- Game Clock is NOT running; Play Clock IS running
- Kicking team selects Kickoff play; Receiving team selects Kickoff Receiving play (Based on Coin Toss results)
- Kickoff play executes and resolves

PLAY LOOP
PRE-SNAP PLAY SELECTION (Off = TEAM IN POSSESSION; Def = TEAM NOT IN POSSESSION)
- A **10s real-time** action bar (HUD progress bar) runs per window; it is not the numeric Play Clock label.
- **Offense first:** offense picks a **category** (Run / Pass / Field Goal / Punt where allowed); each category opens the **play picker** for a specific catalog **play id** from that team’s playbook. Selection becomes **tentative** until **Call Play** locks it (**Call Play** stays disabled until a tentative play exists). If time expires before lock: **Delay of game** — LOS moves **back one tile row** toward the offense’s own goal (no move when already on the last playable row before the own goal line); a new **10s** offense window starts.
- **Defense second:** after offense locks, defense may see **offensive formation only** (from `formation_id`; no routes or other offensive play details). Defense chooses a defensive call (tentative), then presses **Call Play** to lock (**disabled** until tentative). Defense has **10s**; if time expires before defense calls, **AI** selects and locks the recommended defensive call.
- In SIM/autoplay, AI uses situational punt logic (down, zone/field position, score differential, and time left in the current half/game) when choosing offense play type.
- **Private tentative previews before Call Play:** while a team has selected a play but not pressed **Call Play**, only that team sees its tentative formation. Opponent visibility starts only after the play is called.
- **Card phase:** after both plays are set, both teams have **10s** (same bar, reset) to queue cards and press **Ready** (**Ready** is not blocked by playing zero cards; disabled only when already readied, AI-controlled, or the phase disallows it); if time expires, teams not ready are auto-readied with **empty** queues.
- **Momentum** (per team, **≥ 0**, **no cap**): bank for card costs; **carries over** when possession changes (`GameState.start_possession` does not reset banks). New game / restart: both start at **1** (`start_game`). After each resolved play, both teams gain **+1**, except the **first** play of a new possession (`just_started_possession` / `_advance_both_teams_resources` in `game_scene.gd`).

PLAY EXECUTION & RESOLUTION
- After both teams are Ready in the card phase (or after auto-ready), queued cards execute then the play resolves
- Game clock follows **GAME CLOCK** (offense-only scrimmage rule; conversions / dead ball per that section)
- Based on the Plays & Cards selected modifiers are applied to players, cards, plays, coordinatores, etc.
- The Offense may progress zones, regress zones, or end up in the same zone based on the Play Resolution
- A Change of Possession may occur due to a Turnover, Running out of Downs (Turnover on Downs), 1st Half ends, Punt play, Kickoff Play
- Plays that start before the Game Clock expires in the 1st or 2nd half resolve completely even if the Game Clock expires during the play
- The Play resolves while visually displaying Player movements, ball movement from player to player, blocks, tackles, passes, runs, interceptions, fumbles, scoring, etc.
- **Last play summary (HUD):** for **2 seconds**, a short outcome line (**very large** bold italic text, ~**88px** default font, no background) appears **centered on the mobile frame** (tone-colored: gains / first down / TD / good FG / XP in green tones; losses / turnovers / misses in red; delay of game amber; punt net cyan; neutral gains gray). **Yardage** toasts use **N yard(s)** only (no separate “tile rows” suffix). Implemented in `game_scene.gd` (`_show_last_play_toast`).
- The in-game **event log** records each offensive play’s **tile rows gained toward the goal** (from LOS before vs after the play). **Scrimmage and punt** lines use a **pre-snap situation** prefix like `[1st & 10 from 22⬇️] ` (**down at snap**, **&**-joined distance in tile rows or **Goal**, **perspective** LOS row **R** via `FieldGrid.perspective_row(engine_los_at_snap, possession_team == "home")`, then **⬇️** if `R > FieldGrid.TOTAL_ROWS / 2` else **⬆️** — toward the user’s end vs the opponent). When that prefix is off, play-cycle lines still get the simple **`[1st Down]`**-style bracket from `_play_down_at_snap`. The situation prefix is **cleared before post-TD conversion** logs (and **2PT** resolution does not set it). On **turnover**, **turnover on downs**, and **defensive TD off turnover on downs**, the **tile-row line is logged first**, then the turnover / TOD lines. When a new first down is earned (normal scrimmage), the **First down** line in teal (`#2dd4bf`) follows the tile-row line. **Field goals:** **good** logs as `[color=#66ff00]Field goal good +3[/color]` (no duplicate generic tile-row line); **missed** logs **Field goal missed** then the turnover line (no duplicate tile-row line). **Post-TD conversion** then **change of possession** / kickoff lines follow the conversion result line.
- Play Loop resets allowing teams to run the next offense → defense → card windows (10s bar resets each window)
- Game clock behavior: see **GAME CLOCK** (offense-only scrimmage rule)

SCORING PLAYS, TURNOVERS, HALFTIME
- Game Clock is paused
- Play Clock resets based on Play Clock section

HALFTIME
- Game Clock pauses
- **Prototype:** whenever the engine applies second-half kickoff (`force_halftime_now`), the game scene re-initializes the scrimmage turn and clears stale ready/card-queue flags so Sim mode cannot sit idle with the clock running.
- Teams may:
-- Review stats
-- Adjust Deck
-- Adjust Playbook
-- Change Coordinators
-- Review injuries
-- Make Lineup adjustments
- No rewards granted at halftime


2ND HALF

2nd HALF KICKOFF
- Game Clock is NOT running; Play Clock IS running
- Team that Kicked off in the 1st half Receives the ball to start the 2nd half
- Kicking team selects Kickoff play; Receiving team selects Kickoff Receiving play
- Kickoff play executes and resolves
- Go back to Play Loop

END OF GAME
- Occurs when the Game Clock hits 0 in the 2nd Half
- Winner and Loser are declared based on Team Scores
- Team History is updated with:
-- Win/Loss count
-- Final Score
-- Player stats (e.g. number of catches, number of runs, number of passes completed, number of incomplete passes, tackles, turnovers forced, field goals made, touchdowns scored, and many more)
-- Coordinator stats (e.g. wins/losses, and more to come)
- In-game currency, plays, cards, etc. are awarded to both Teams based on the result

DOWNS
- The team in possession has 4 downs (numbered 1–4). A new possession starts on **Down 1**.
- After a play resolves without a new first down, the down increments (1→2→3→4).
- A **first down** is earned when the offense advances the ball **10 tile rows** toward the opponent’s goal from the line of scrimmage that started the current first-down chain; then downs reset to **1** and a new 10-row target is set from the new LOS row.
- **Goal to go:** when the offense’s LOS is within **10 tile rows** of the scoring endzone, there is **no first-down line**; yardage cannot earn a new first down. The offense still has **downs 1–4** to score a **touchdown** or **field goal** (or suffer turnover on downs / turnover / safety as usual). The field highlights the **entire scoring endzone** in yellow instead of a single first-down row.
- On a change of possession, downs reset to **1** for the new offense.
- If the offense is on **down 4** and the play ends without a first down (and the play does not otherwise change possession, e.g. score or turnover), it is **turnover on downs**; the opponent takes possession at the spot implied by the play result / field rules.
- On 4th down (or earlier if the team chooses), a team may punt (when implemented).

CLOCKS

GAME CLOCK
- **Scrimmage (prototype):** runs **only** while the offense is in **play selection** with no offensive call locked yet (`pending_play_type` unset, offense pick window), **and** the **first scrimmage snap of the current half** has already been resolved (`_defer_scrimmage_game_clock_until_first_snap` cleared at `_resolve_play` entry in `game_scene.gd`). When offense presses **Call Play**, the game clock **stops** through defense play selection, the card queue (both **Ready**), and play resolution / dead-ball; it **starts again** on the next snap’s offense play-selection window (`_sync_game_clock_scrimmage_policy` in `game_scene.gd`) once defer is off. **Sim** autopilot uses `_sim_tick_paused` for the pause button so the sim tick can run while the game clock is off during defense/cards.
- **Half openers:** `_defer_scrimmage_game_clock_until_first_snap` is **true** at a new game / **Restart** and again when the **second half** begins (`_after_force_halftime_second_half`); the clock stays **off** for that half’s first presnap (offense → defense → cards → resolve) even if the offense play-selection window would otherwise allow it. **Sim** `_apply_sim_presnap_runoff` also skips **`game_time_remaining`** drain while defer is on (play-clock drain still applies if the play clock is enabled).
- Still **off** for: conversion choice / XP attempt (not in offense-only window), halftime phase, game over, and other `_stop_clock(..., apply_hold_after=true)` outcomes (hold cleared when a new turn begins via `_begin_turn_if_needed`). **Timeouts** use `_stop_clock(..., false)` so the offense window can tick again after a timeout when defer is already cleared.
- **Manual HUD Pause** / **Sim → Man** still gate the clock via `_manual_pause_active` / `_auto_pause_after_sim_stop` on top of the rule above.

ACTION TIMER (replaces legacy Play Clock for scrimmage plays)
- **10 real seconds** per window: offense play pick → defense play pick → simultaneous card queue (bar resets each time).
- Offense expiration: delay of game (LOS back one tile row when allowed), then new 10s for offense.
- Defense expiration: AI picks the recommended defense.
- Card window expiration: auto-ready with **no** cards queued for teams not ready.
- **Forfeit (per team):** if the same team finishes **3 consecutive turns** with **no manual offensive/defensive play call** for their role **and** **no cards played** that turn, that team forfeits (tracked per human-controlled side; sim autoplay suppresses this tracking).
- Bar uses **wall time** (not game-clock seconds).
- **Manual mode HUD Pause:** **Pause** toggles `_manual_pause_active`; the action bar stops while that flag is set. **Sim** mode: **Pause** toggles `_sim_tick_paused` (sim AI tick), separate from the offense-only game clock.
- **Sim → Man:** leaving **Sim** auto-pauses the game clock and action bar until **Pause** resumes the clock or the user acts (play pick, conversion choice, card selection / Ready / play card).
- **Sim — one play at a time:** `HUDGroup/SimStepPanel` below **`SpeedPanel`**: check **1 play at a time** to pause the sim tick (`_sim_tick_paused` + `SimTimer` stop) after each resolved scrimmage/punt, after **XP** resolution, and after **2PT** resolution (`_sim_try_pause_step_after_play` in `game_scene.gd`); **Next** resumes the sim tick until the following resolution. Pause is applied **before** `state_changed` so `_update_ui` → `_maybe_run_ai_inputs` does not advance AI until you press **Next**; while paused, `_maybe_run_ai_inputs` returns early when `_sim_running` and `_sim_tick_paused`. While waiting for **Next** (`_sim_step_waiting_for_next()`), **game clock** and **play clock** (`_sync_game_clock_scrimmage_policy`, `_tick_turn_action_timer`) do not advance.

TIMEOUTS
- A Timeout is called when a Team presses their Timeout button
- Game clock stops for the timeout call, then may run again during the **offense** play-selection window under the scrimmage rule above (not tied to both teams **Ready** on the prior play).
- Action timer resets for the timeout window

PLAYS
OFFENSIVE PLAYS
- Only selected by the Team in Possession
- May select any Offensive Play from the Playbook (including Punt, **spot kick** / FG)
- AI reviews the formation for the selected play and automatically chooses the players from the lineup for each position needed based on the team's Depth Chart

DEFENSIVE PLAYS
- Only selected by the Team NOT in Possession
- May select any Defensive Play from the Playbook
- AI reviews the formation for the selected play and automatically chooses the players from the lineup for each position needed based on the team's Depth Chart

KICKOFF PLAYS
- The Kicking Team kicks the ball to the Receiving Team.
- Kick distance and landing zone are determined by the Kicker’s stats and modifiers.
- The Receiving Team attempts a return based on the Returner’s stats, blocking, coverage players, cards, and other modifiers.
- Returns are resolved at the **tile** level (zones are not used for ball movement; they may still drive modifiers and UI labels).
- Most returns result in little to moderate advancement, while long returns and return touchdowns are rare outcomes.

PUNTING PLAYS
- The Punting Team punts the ball to the Receiving Team.
- **Punt** is available on offense buttons on all downs.
- Defense can choose **Punt Return** only when offense selected Punt.
- **Punt distance** (tile rows) uses kicker stats (randomized range + power/consistency). **If defense does not call Punt Return**, return is **0** tile rows — receiving team spots the ball at punt distance only (no return roll). **If defense calls Punt Return**, return length uses **tiered tile-row bands** (1 row ≈ 1 yd): **0** | **1–5** (most common) | **6–19** | **20–29** | **30–34** (field-capped “splash”), with base weights tuned NFL-ish (~10–15% mass in the **20+**-row tiers combined, **40+ yd** analogue in the top tier at low base weight). **Player stats** (returner speed/agility/catching vs punter tackling/awareness), **coach bonuses** (`punt_return_bonus` / `punt_coverage_bonus` on head coach or DC `bonus` maps), and **card hooks** (`card_return_bonus` / `card_coverage_bonus` in code, default 0) **shift tier weights** before the roll. **Net** = punt rows minus return rows (can be negative on long returns). **Receiving team start:** post-punt engine LOS = punting team’s engine LOS before the punt **minus** `net_rows` (clamped); zone is derived from that row (`zone_from_engine_row`), matching scrimmage ball-movement sign — not `round(net / 5)` zone steps from the old zone. Resolver `breakdown` can list the adjusted tier weights; event log records punt, return, and net tile rows.
- **Punt touchback:** If resolved punt position reaches the **scoring endzone** (zone ≥ endzone on the punting offense resolution), the receiving team starts at **`TOUCHBACK_LOS_ROW_ENGINE` (25)** — **5th tile of Build zone** (one engine row into Build from Advance). The **event log** adds a separate **Touchback** line after the punt summary.

SCORING
TOUCHDOWN
- 6 points for OFF

EXTRA POINT PLAYS
- 1 point for OFF

2-POINT CONVERSION PLAYS
- 2 points for OFF

SPOT KICK (FG) PLAYS
- 3 points for OFF (play id **`spot_kick`** in data; XP uses the same offensive play type)

SAFETY 
- 2 points for DEF

TOUCHDOWNS
- After a TD, the Game Clock pauses. The **scoring team** chooses **Extra Point** or **2-Point Conversion**.
- **Extra Point:** after the user (or AI) selects XP, the attempt **auto-resolves** from kicker stats via `resolve_extra_point` (no separate offensive play call). The shared primary button shows **Call Play** **disabled** for the scoring team during the XP attempt (no action).
- **2-Point:** selecting 2PT enters the normal scrimmage play flow (play selection / cards per phase level), then resolves like a regular play.
- After the conversion attempt finishes, **kickoff** / change of possession: receiving team starts at **touchback** LOS row **25** (`TOUCHBACK_LOS_ROW_ENGINE`). **Opening kickoff** (game start) and **halftime second-half** receiving possession use the same row **25** spot (prototype: no kick return resolution yet). The **event log** adds a **Touchback** line for opening kickoff, halftime, post-TD kickoff, and punt-in-endzone (suffix text distinguishes the case).

INJURIES
- There is a chance that individual players may be injured based on their Toughness stat
- Game Clock pauses
- Team with injury may make a substitution for the injured player
- Injury Timer - The team making the sub


FORFEIT
- Occurs when:
-- **Per team:** that team finishes **3 consecutive turns** with **no manual play call** (offense “Call Play” / defense call) **and** **no cards played** that turn (simulated auto-picks do not count as manual)
-- Team presses the Forfeit button
- Team that Forfeits loses the game
-- If the Team winning Forfeits, the Game is considered a Loss for that team 
--- Recorded as a Forfeit Loss in the Team History for the Forfeiting team and a Forfeit Win in the Team History for the team that did not Forfeit; The current score of the game is recorded for both teams; if the score is 0-0, the game is Abandoned and nothing is recorded in Team Histories; Rewards for the non-Forfeiting team are still awarded
-- If the Team losing Forfeits, the Game is considered a Loss for that team 
--- Recorded as a Forfeit Loss in the Team History for the Forfeiting team and a Forfeit Win in the Team History for the team that did not Forfeit; The current score of the game is recorded for both teams; if the score is 0-0, the game is Abandoned and nothing is recorded in Team Histories; Rewards for the non-Forfeiting team are still awarded
- If both teams forfeit simultaneously (e.g. both hit the 3-turn inaction threshold together) **or** they press the Forfeit button on the same turn, the game is **abandoned** and no stats are recorded; no rewards for either team

CHANGES OF POSSESSION
- Turnover on downs (offense on down 4 does not earn a new first down and does not otherwise lose possession on that play)
- Turnovers
-- Fumbles (DEF forces the OFF player to drop the ball and recovers it or OFF player drops the ball)
--- May occur on every play
--- Only the player holding the ball may Fumble
--- Fumbles are NOT automatically recovered by the Opponent (Turnover); they may be recovered by either team
--- Fumble recovery is based on:
---- A. Player proximity to the ball (Players must be close to the ball; the closer a player is, the better chance they will recover it)
---- B. Player stats if more than 1 player has an opportunity for recovery
---- C. Card modifiers that increase/decrease chances of recovery
-- Interceptions (DEF catches a pass intended for an OFF player)
--- Do NOT occur on Run type plays
- Punts (OFF punts ball to DEF)
- Kickoffs (OFF kicks off to DEF)
- Halftime (Team that Received KO in the 1st Half kicks off in the 2nd Half)

BASE PLAY TYPE SUCCESS/RESOLUTION
- As the Offense attempts to move the ball toward the scoring end (**tile** resolution for ball position), **zones** remain for range checks (e.g. FG range), modifiers, and named field regions. The type of play selected by both the Offense and Defense is fundamental to determining the success of the play
- The chance of success starts with the offensive **play id** vs the defensive **play id** (each has a `play_type` bucket from [data/plays.json](data/plays.json)). Defense tries to match buckets: **run_def** vs **run**, **pass_def** vs **pass**, **fg_xp_def** vs **spot_kick**, **punt_return** vs **punt**. Matching buckets favors defense on yardage; mismatches (e.g. **pass_def** vs **run**, **run_def** vs **pass**) favor offense.
- Best matchups for Defense that give a higher success rate to the Defense:
-- **run_def** vs **run**
-- **pass_def** vs **pass**
-- **fg_xp_def** vs **spot_kick** (FG/XP)
-- **punt_return** vs **punt**
- If buckets do not align, offense tends to gain more tile rows on standard scrimmage plays (resolver applies bucket matchup modifiers before coordinator bonuses).
- After the Play type comparison, modifiers are taken into account
-- Player modifiers
-- Coordinator modifiers
-- Card modifiers


ZONES
- Numeric **zone ID** `current_zone` (1–7) is authoritative for rules and **card modifiers** (see [docs/Properties.md](Properties.md) FIELD ZONES).
- **Offense** (possession team) display names: **Defensive Endzone** (own end; safety if offense tackled here) → **Build Zone** → **Advance Zone** → **Midfield Zone** → **Attack Zone** → **Red Zone** → **Scoring Endzone** (TD).
- **Defense** display names (same ID, defending team’s HUD): **Scoring Endzone** → **Contain Zone** → **Control Zone** → **Midfield Zone** → **Pressure Zone** → **Goal Line Zone** → **Defensive Endzone**.

REWARDS (To be fleshed out later)
- In-game currency
- New Cards
- New Plays
- Player Boosts
- Coordinator Boosts

FINALIZED GLOBAL DESIGN DECISIONS
•	User is the Head Coach. Only Offensive and Defensive Coordinators exist.
•	Automatic substitutions occur between possessions, timeouts, and injuries.
•	Games target 3 to 5 minutes.
•	Training-based evolution, not automatic game evolution.
•	Optional rewarded ads only. No forced ads.
•	No contracts.
•	Roster limit: 50. Lineup: 12 to 22.
•	Deck size: 8 to 16 cards. Playbook: 3 to 12 plays.
•	No overtime in V1. Ties allowed.
•	Offline single-player supported.

PLATFORM PHILOSOPHY
TARGET PLATFORMS
The game is designed for:
-- Mobile
-- PC (Steam)
CORE DESIGN GOAL
Gameplay systems should function well on both:
-- Touch controls
-- Mouse controls
No platform should have a major gameplay advantage.

MOBILE-FIRST DESIGN
The game is primarily designed around:
-- Short sessions
-- Readable UI
-- Fast decisions
-- Touch-friendly controls
PC SUPPORT
PC version should preserve the same gameplay rules and pacing while improving:
-- Screen space usage
-- Information visibility
-- Menu navigation
-- Visual polish
CROSS-PLATFORM GAMEPLAY
Core gameplay systems remain identical across platforms.

Examples:
-- Same rules
-- Same cards
-- Same teams
-- Same progression
-- Same balance philosophy

UI SCALING
UI should support:
-- Portrait mobile layouts
-- Landscape PC layouts
-- Dynamic scaling
-- Mouse and touch input
INPUT DESIGN
All gameplay interactions should be achievable through:
-- Single tap/click
-- Drag and drop (optional)
-- Minimal precision requirements
SESSION LENGTH
Average Game length target remains:
-- 3 to 5 minutes

Across all platforms.

PLAYER IDENTITY & RECOGNITION
CORE PHILOSOPHY
Players are intended to feel unique and recognizable without requiring duplicate universal Players shared across all Teams.
Recognition should come from:
-- Position
-- Archetype
-- Traits
-- Visual indicators
-- Gameplay behavior
-- Team identity
The game does NOT rely on all Teams owning identical Players like a traditional trading card game.
PLAYER RECOGNITION

Players should become recognizable through:
-- Archetype labels
-- Trait keywords
-- Playstyle
-- Performance during Games
-- Visual presentation

Example:
Marcus Reed
WR
Deep Threat
Traits:
-- Burner
-- Sideline Specialist

Experienced Players should quickly understand:
-- Strong deep threat
-- Dangerous vertical receiver
-- High explosive-play potential

ARCHETYPES
Each Position contains multiple Archetypes that define gameplay tendencies and strengths.

Examples:

QB
-- Gunslinger
-- Mobile QB
-- Field General

RB
-- Power Back
-- Elusive Back
-- Receiving Back

WR
-- Deep Threat
-- Possession Receiver
-- Route Runner

CB
-- Ball Hawk
-- Press Corner
-- Zone Specialist

TRAITS
Traits act as readable gameplay keywords that communicate a Player’s strengths and tendencies.

Examples:
-- Burner
--- Increased deep separation

-- Sure Hands
--- Reduced fumble chance

-- Ball Hawk
--- Increased interception chance

-- Enforcer
--- Increased tackle/fumble pressure

-- Pocket Presence
--- Reduced pressure penalties

VISUAL READABILITY
Archetypes and Traits should use consistent visual indicators.

Examples:
-- Icons
-- Colors
-- Badges
-- Labels

Goal:

Opponents should quickly identify important threats during gameplay.
GAMEPLAY PERSONALITY
Players should feel memorable through their in-game performance and tendencies.

Examples:
-- Fast WR repeatedly beating coverage deep
-- Ball Hawk CB creating turnovers
-- Power RB consistently breaking tackles

PLAYER GENERATION RULES
Players are generated around strong identities instead of evenly distributed stats.
Archetypes should create clear strengths and weaknesses.

Bad Example:

Balanced stats with no clear role

Good Example:
Deep Threat WR
-- Very high Speed
-- Strong deep route ability
-- Lower short-route effectiveness

Possession WR
-- Strong Hands
-- Reliable short catches
-- Lower explosive-play ability

SCOUTING & OPPONENT RECOGNITION
Pre-game scouting may highlight important opposing Players.

Examples:
-- Elite Deep Threat WR
-- Ball Hawk CB
-- Mobile QB
-- Elite Pass Rusher

Goal:

Encourage strategic planning and player recognition over time.

FIELD STRUCTURE
LOCAL FIELD VIEW
- The simulation uses one shared engine orientation; the **on-field view mirrors** when you are assigned **Away** so **your offense always advances toward the top** of the screen (same seat as Home). Future multiplayer uses the same rule per client.
- **Formation preview:** field markers come from play `formation_id` (relative to LOS). Before call: selecting team sees only its tentative formation (defense also keeps the called offense view once offense is called). After call: both sides can see called formations as phase rules allow. Offense chips are white/rounded, defense chips red/near-square, with same-tile fan-out and a one-row perspective shift for defense readability.
ZONES
Zones represent major field progression.
Zones are used for:
-- Scoring range
-- Field position
-- Strategic state
TILES
Tiles represent smaller movement units within Zones.
Tiles are primarily used for:
-- Visual movement
-- First-down distance (10 rows toward the goal from the chain LOS)
-- Play resolution
-- Returns
-- Positioning
-- Micro progression
GAMEPLAY PRIORITY
Gameplay uses zones for macro field position and resolution; **first downs** use the **tile row grid** (10 rows toward the goal per chain).
FIRST DOWNS
First downs are measured in **tile rows** (10 rows gained toward the opponent’s goal from the current chain’s line of scrimmage row). When **not** goal to go, the HUD/field highlights the target row in yellow. In **goal to go** (LOS within 10 tile rows of the scoring endzone), there is no first-down marker; the **full scoring endzone** is highlighted in yellow instead. The **user** HUD shows **down and distance** (tile rows to first down or TD) via `UserDownDistanceLabel`, e.g. `1st and 10`, `3rd and Goal`.
PLAY RESOLUTION
Plays may gain or lose Tiles.
Tile progress converts naturally into Zone advancement.

Example:

5 Tiles gained
Advance into next Zone
DESIGN GOAL
Maintain:
-- Fast gameplay
-- Readable field position
-- Strategic clarity

Without requiring full tile-by-tile simulation