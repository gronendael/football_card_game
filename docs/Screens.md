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
-- Field (LOS / first-down markers; **BallChip** `🏈` at LOS, tinted by possession team; view mirrors when you are Away so your offense always advances toward the top)
-- Formation preview: before **Call Play**, only the selecting team sees its tentative formation. Opponent sees a team's formation only after that team calls. In defense window, defense sees called offense formation plus its tentative/called defense formation. Data: `formation_id` in [data/plays.json](data/plays.json) → [data/formations.json](data/formations.json); offense = white rounded chips, defense = red near-square chips; same-tile horizontal fan-out; defense markers shifted one perspective row
-- HUD
-- `UserTeamsScoresPanel`: full width with small horizontal inset from the mobile frame; **user** — possession icon in a **fixed-height row above** the name+score row (icon shown/hidden via alpha so the name and score do not shift); **opponent** — same (icon above score+name), opponent strip **right-aligned**; clocks centered between the two team strips
-- Event log (timestamped lines; per-play movement in tile rows toward goal; first downs in teal; **Field goal** explicit **good** (`#66ff00`) / **missed** (`#ff6666`) + turnover line; **PUNT** lines include punt / return / net tile rows; **Touchback** line for punt-in-endzone, kickoff after TD, opening kickoff, halftime second half)
-- Score
-- Clock / **action timer** (`ActionTimerProgressBar` under `ClockPanel`: 10s real-time windows for offense pick → defense pick → card queue; numeric play-clock label hidden). **Game clock:** runs only during **offense** play selection until **Call Play**; stops for defense pick, card queue (through both **Ready**), and resolve; **Pause** (manual) toggles `_manual_pause_active`; **Sim** mode **Pause** toggles `_sim_tick_paused` (AI tick) while the game clock follows the offense-only rule. **Sim → Man:** `_auto_pause_after_sim_stop` until user unpause or user input (play / conversion / card / Ready)
-- Half
-- Possession
-- Zone (offense vs defense **display** names for same `current_zone` ID when user is on offense vs defense; see [Properties.md](Properties.md) FIELD ZONES)
-- Momentum
-- Downs (1–4); **Goal to go** when LOS is within 10 tile rows of the scoring endzone (`DownsLabel`: `Goal to go | Downs: n` or `Downs: n`; no first-down row, full endzone highlight on field)
-- Result Messages
-- Play Selection (offense: Run / Short Pass / Deep Pass / Field Goal / **Punt** + **Call Play** — **Call Play** enabled only after a **tentative** play is selected; defense: play type + **Call Play** after offense locks, same tentative rule; **Extra point:** primary slot shows **Call Play** disabled for the scoring team; **2PT** still commits from Run/Pass buttons without tentative + Call Play)
-- Card Selection (queue + **Ready**; same button as Call Play relabeled; **Ready** stays available with **0** cards queued — disabled only when AI-controlled, already ready, or phase disallows)
-- **Down & distance** (`UserDownDistanceLabel` under `UserHUD`, tile rows to first down or TD): e.g. `1st and 10`, `3rd and Goal`; timeouts stay in `UserTimeoutsPanel` (`UserTOsColumn` + `UserTOsPanel`)
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