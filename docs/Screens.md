HOME
Main landing page after opening the app
Shows current Team overview and quick actions
Includes:
-- Continue Season/Game
-- Quick Play
-- Claim Rewards
-- Missions Progress
-- Current Team Summary
--- Team Name
--- Team Logo
--- Team Identity
--- Active Coordinators
--- Record (Future)
-- Currency Summary
-- Notifications/Alerts
Example Alerts:
-- Rewards Ready to Claim
-- Roster Full
-- Deck Not Equipped
-- Playbook Not Equipped
-- Injured Players
-- Training Complete
TEAM
Main screen for managing the active Team
Recommended to organize using Tabs
TEAM Tabs:
-- Roster
-- Lineup
-- Position Assignments
-- Depth Chart
-- Coordinators
ROSTER TAB
View all Players on the Team Roster
Roster Limit: 50 Players
Sort/Filter Options:
-- Position
-- Rating
-- Archetype
-- Rarity
-- Injured
-- Fatigue
-- Favorites
LINEUP TAB
Manage active Lineup for Games
Lineup Limit: 22 Players
Lineup Minimum: 12 Players
Auto Fill Button:
-- Best Available
--- Accounts for Injuries
--- Accounts for Fatigue
--- Accounts for Position eligibility
POSITION ASSIGNMENTS TAB
Select/Deselect which Positions each Player may play
Quick Options:
-- Select All Offense
-- Select All Defense
-- Select All Specialists
-- Clear All
-- Reset Recommended
DEPTH CHART TAB
Prioritize Players for each Position
Example:
-- RB Priority
--- RB1
--- RB2
--- RB3
-- WR Priority
--- WR1
--- WR2
--- WR3
Used by AI for:
-- Automatic substitutions
-- Injuries
-- Fatigue
-- Formation requirements
COORDINATORS TAB
Manage Coordinators assigned to the Team
Includes:
-- Offensive Coordinator (OC)
-- Defensive Coordinator (DC)
Shows:
-- Coordinator Identity
-- Passive Effects
-- Granted Plays
-- Granted Cards
PLAYBOOK
The Playbook is the list of Plays available during a Game
Users may create/modify/delete Playbooks
Only 1 Playbook may be equipped at Game start
Playbook Size:
-- Minimum 3 Plays
-- Maximum 12 Plays
Includes:
-- Offensive Plays
-- Defensive Plays
-- Special Teams Plays
UI Suggestions:
-- Equipped Playbook
-- Current Play Count (e.g. 7/12)
-- Offensive Play Section
-- Defensive Play Section
-- Search/Filter
DECK
The Deck is the list of Cards available during a Game
Users may create/modify/delete Decks
Only 1 Deck may be equipped at Game start
Deck Size:
-- Minimum 8 Cards
-- Maximum 16 Cards
Includes:
-- Equipped Deck
-- Current Card Count (e.g. 12/16)
-- Card Cost Preview
-- Card Types
-- Duplicate Count
UI Suggestions:
-- Momentum Cost Breakdown
-- Search/Filter
-- Sort by Cost
-- Sort by Type
TRAINING
Used to improve Players over time
Players gain Training XP from Games
Users choose Training focus outside of Games
Includes:
-- Player XP
-- Recommended Training Paths
-- Training Progress
-- Stat Improvements
-- Skill Improvements
Example Recommended Paths:
-- Deep Threat WR
-- Possession WR
-- Power RB
-- Speed RB
-- Gunslinger QB
-- Field General QB
-- Lockdown CB
-- Ball Hawk S
PRE-GAME
Screen shown before starting a Game
Allows final review before entering gameplay
Shows:
-- Opponent Team
-- Team Strength Comparison
-- Active Coordinators
-- Equipped Playbook
-- Equipped Deck
-- Difficulty
-- Potential Rewards
-- Weather (Future)
Buttons:
-- Start Game
-- Edit Team
-- Cancel
Notifications:
-- Missing Playbook
-- Missing Deck
-- Invalid Lineup
-- Injured Players
GAME
Live Game screen
Includes:
-- **Tools** (`TopRightBar/ToolsMenuButton` on root `GameScene`, left of **Quit**): **Tools** menu — **Formation tool…** opens [`scenes/formation_tool.tscn`](scenes/formation_tool.tscn) (`FormationTool`): list/add/edit/delete formations; new entries get **auto-generated** `fmt_*` ids (**Id** read-only in editor). **Add/Edit** uses **three columns:** metadata (Id, Name, Description, Tags), vertical **role** list (**only roles not on the grid**; at most one token per role on the field; drag from list to place, from grid back to list to clear), **7×20** grid. **Save** rewrites `res://data/formations.json` and reloads the catalog (intended for **editor/dev**; exported `res://` may be read-only). Does not auto-update `formation_id` in [data/plays.json](data/plays.json). Panel is **scrollable** with screen margins. Detail: [docs/Tools.md](Tools.md).
-- Field (LOS / first-down markers; **BallChip** `🏈` at LOS, tinted by possession team; view mirrors when you are Away so your offense always advances toward the top)
-- Formation preview: before **Call Play**, only the selecting team sees its tentative formation. Opponent sees a team's formation only after that team calls. In defense window, defense sees called offense formation plus its tentative/called defense formation. Data: `formation_id` in [data/plays.json](data/plays.json) → [data/formations.json](data/formations.json); offense = white rounded chips, defense = red near-square chips; same-tile horizontal fan-out; defense markers shifted one perspective row
-- **Player token / details** (click): shows **display name** from roster `first_name` + `last_name` and **1–10** stat keys aligned with [Properties.md](Properties.md) (prototype omits a dedicated long-term **Role** line)
-- HUD
-- **GlobalHUD** (`HUDGroup/GlobalHUD`): **`PlayCountLabel`** — **`Plays: n`** where **n** is `_game_plays` in `game_scene.gd` (each resolved scrimmage in `_apply_play_result` and each punt in `_apply_punt_result`; reset with new game stats)
-- `UserTeamsScoresPanel`: full width with small horizontal inset from the mobile frame; **user** — possession icon in a **fixed-height row above** the name+score row (icon shown/hidden via alpha so the name and score do not shift); **opponent** — same (icon above score+name), opponent strip **right-aligned**; clocks centered between the two team strips
-- **`UserPlayButtonsRow`** (`HBoxContainer` on `UserHUD`): **`UserPlayRowPossessionIcon`** (`Label`, left of `UserPlayButtons`) — **🏈** when your team has possession (you’re on offense for this scrimmage pick), **🛡️** when you’re on defense; **`UserPhasePromptPanel`** (`MarginContainer`, no filled panel — spacing only) + **`UserPhasePromptLabel`**: uppercase **notification** text (gold + outline, right-aligned, **no wrap** — **SELECT PLAY** / **SELECT CARD(S)**) during **`play_selection`** / **`card_queue`** only; hidden elsewhere
-- **Last play toast** (`LastPlayToastLayer` on `GameScene`, `game_scene.gd`): **2s** centered over **`MobileFrame`** after a resolved play — large **bold italic** BBCode text, **no panel background** (tone colors: good / bad / warn / neutral / info). Covers scrimmage gain–loss / first down / TD / FG / turnovers / punt net / delay of game / XP / 2PT; restarts timer if a new outcome fires before 2s. **Yardage lines** (`N yard(s) Gain/Loss`, punt **Net N yard(s)** / **Net loss of N yard(s)**) use **yard** wording only (tile rows ≈ yards; no duplicate “tile rows” parenthetical).
-- **Play calc log** (`HUDGroup/CalcLogPanel`, to the right of **`PlayInfoHUD`** / Play Log): **Play calc log** title; filter **CheckButtons** (`CalcFilterResolver`, `CalcFilterPost` **Matchup**, `CalcFilterOutcome`, `CalcFilterTurnover`, `CalcFilterCards`, `CalcFilterSkills`, `CalcFilterSpecial`, `CalcFilterConversion`); **Prev** / **CalcLogIndexLabel** / **Next** (`CalcLogNextNav`, avoids clashing with sim **Next**); scroll + **`CalcLogText`** (`RichTextLabel`, BBCode). One **numbered slide per resolved scrimmage snap** (card queue through outcome / apply play) so filters apply within that snap; older snaps stay on separate Prev/Next pages. **Resolver** and **Matchup** filters both apply to the same resolver / matchup line category (either **on** shows those lines; turn **both** off to hide that block). Section headers omit when the whole block would be empty under the current filters. Lines that still carry seat tokens `home` / `away` show **team display names** from `teams.json`; scrimmage sim lines label players as **`{franchise display} {formation role} · {display name}`** (`PlayerStatView.display_name_from_dict`). **Restart** (and `_ready` after `start_game`) clears the log.
-- **`SpeedPanel`** (`HUDGroup/SpeedPanel`): **`-`** / **`+`** adjust sim speed; **`x2`** / **`x10`** jump to **2×** / **10×** (clamped **0.5–10**); label shows current multiplier
-- **`SimStepPanel`** (`HUDGroup/SimStepPanel`, below `SpeedPanel`): **`SimStepAfterPlayToggle`** — **1 play at a time** (while **Sim** is on, pause sim timer after each resolved scrimmage/punt/XP/2PT); **`SimStepNextButton`** — **Next** (resume sim tick)
-- Event log (timestamped lines; **pre-snap situation** bracket on scrimmage + punt resolution — e.g. `[1st & 10 from 22⬇️] ` from snap down/distance + `FieldGrid.perspective_row` LOS and ⬇️/⬆️ vs midfield; cleared before post-TD conversion; **per-play** `Team (play): ±tile rows toward goal` line first on scrimmage; then **turnover** / **turnover on downs** / **change of possession** lines where applicable; first downs in teal after those; **Field goal** explicit **good** (`#66ff00`) / **missed** (`#ff6666`) then missed-FG turnover line; **PUNT** lines include punt / return / net tile rows; **Touchback** line for punt-in-endzone, kickoff after TD, opening kickoff, halftime second half)
-- Score
-- Clock / **play clock** (`ActionTimerProgressBar` under `ClockPanel`; HUD **`ShowActionTimerBarToggle`** text **Play clock (10s)**): when **on**, **10s** real-time windows for offense pick → defense pick → card queue (numeric `PlayClockValueLabel` hidden); timeout → delay of game (offense), AI defense call (defense), or auto-ready empty (card queue). When **off** (`show_action_timer_bar` / toggle unchecked), **no** play-clock countdown, **no** timer-driven penalties or auto-picks, **no** bar — for analysis/testing. Same flag on root `GameScene` export. **Game clock:** same offense-only scrimmage window as `Gameplay_Summary` **GAME CLOCK**, plus **no tick until the first scrimmage snap of each half** is resolved (defer reset at second half / restart); then runs only during **offense** play selection until **Call Play**; stops for defense pick, card queue (through both **Ready**), and resolve; **Pause** (manual) toggles `_manual_pause_active`; **Sim** mode **Pause** toggles `_sim_tick_paused` (AI tick) while the game clock follows the offense-only rule. **Sim → Man:** `_auto_pause_after_sim_stop` until user unpause or user input (play / conversion / card / Ready)
-- Half
-- Possession
-- Zone (offense vs defense **display** names for same `current_zone` ID when user is on offense vs defense; see [Properties.md](Properties.md) FIELD ZONES)
-- Momentum (per-team bank **≥ 0**, **no maximum**; carries across possession changes — `GameState.start_possession` does not reset banks; `start_game` sets **1** each for the opening kickoff)
-- Downs (1–4); **Goal to go** when LOS is within 10 tile rows of the scoring endzone (`DownsLabel`: `Goal to go | Downs: n` or `Downs: n`; no first-down row, full endzone highlight on field)
-- Result Messages
-- Play Selection (offense: **Run / Pass / Field Goal / Punt** — each opens the **play picker** modal on a high **CanvasLayer**, positioned **centered over `MobileFrame`** (`_popup_play_pick_over_mobile_frame` in `game_scene.gd`): scrollable **cards** (`scenes/play_pick_card.tscn`) with play name + **3×3 formation** thumbnail; **✕** closes (**top right**); large green **Call Play** (**bottom right**) commits the selected card; **`UserBottomUIPanel` / opponent primary slot** stays labeled **Ready** and commits the tentative offense/defense play after the picker (same gating as before); deep-pass column hidden; **Extra point:** primary slot **Ready** disabled for the scoring team; **2PT** still commits from Run/Pass flow without tentative + Ready)
-- Card Selection (queue + **Ready** on **`UserBottomUIPanel`** / opponent primary; **Ready** stays available with **0** cards queued — disabled only when AI-controlled, already ready, or phase disallows)
-- **Down & distance** (`UserDownDistanceLabel` under `UserHUD`, tile rows to first down or TD): e.g. `1st and 10`, `3rd and Goal`; user timeouts: **`UserTimeoutButton`** under `UserBottomUIPanel` — clock icon + `(n)` remaining
-- Timeout Button
REWARDS
Claim Rewards after Games, Missions, Achievements, or Events
Reward Types:
-- Coins
-- Credits
-- Players
-- Coordinators
-- Cards
-- Plays
-- XP
-- Cosmetics
Notifications:
-- Roster Full
-- Duplicate Player
-- New Unlock
COLLECTION (Future)
View all owned content across the account
Categories:
-- Players
-- Coordinators
-- Cards
-- Plays
Separate from active Team management
SETTINGS
Game settings and preferences
Includes:
-- Audio
-- Graphics
-- Notifications
-- Accessibility
-- Account
-- Help
-- Support
-- Terms/Privacy
BOTTOM NAVIGATION (Recommended)
Home
Team
Playbook
Deck
Play
Rewards
Settings