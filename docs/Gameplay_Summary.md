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
- Play Clock is running; Game Clock may be Paused or Unpaused depending on factors listed in the Game Clock section
- Both teams select a Play from their Playbook based on the Playbook that is currently equipped for their team
- Both teams select Cards from their Deck based on the Deck that is currently equipped for their team (Cards act as modifiers which may adjust percentage chance of success or failure, adding/substracting stats to players/coordinatores/teams, effects to playbooks/decks, effects to Game Clock/Play Clock, effects to Momentum, effects to Downs, and more.
- Both teams select Ready button when they are ready for the play to execute
- When a team selects a Play:
-- AI selects the Players for each position based on the Team's setup (see TEAM SETUP & PRE-GAME SETUP section)

PLAY EXECUTION & RESOLUTION
- After both Teams have pressed Ready button the current Play executes and resolves (or AI presses the Ready button)
- Pause/Unpause the Game Clock if appropriate (Game Clock does NOT Unpause for Extra Points or 2-point Conversions)
- Based on the Plays & Cards selected modifiers are applied to players, cards, plays, coordinatores, etc.
- The Offense may progress zones, regress zones, or end up in the same zone based on the Play Resolution
- A Change of Possession may occur due to a Turnover, Running out of Downs (Turnover on Downs), 1st Half ends, Punt play, Kickoff Play
- Plays that start before the Game Clock expires in the 1st or 2nd half resolve completely even if the Game Clock expires during the play
- The Play resolves while visually displaying Player movements, ball movement from player to player, blocks, tackles, passes, runs, interceptions, fumbles, scoring, etc.
- The in-game **event log** records each offensive play’s **tile rows gained toward the goal** (from LOS before vs after the play); when a new first down is earned, a separate **First down** line appears in teal (`#2dd4bf`), a color not used for other log highlights.
- Play Loop resets allowing Teams to select their next Play and Cards
- Play Clock resets
- Game Clock may be Paused or Unpaused depending on factors listed in the Game Clock section

SCORING PLAYS, TURNOVERS, HALFTIME
- Game Clock is paused
- Play Clock resets based on Play Clock section

HALFTIME
- Game Clock pauses
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
- Pauses on:
-- Game Start
-- Halftime Start
-- Change of Possession
-- Extra Points
-- 2-point Conversions
-- Timeouts
- Unpauses on:
-- When Game Clock is Paused, Unpause after both teams click Ready for the next play before the Play executes (except for Extra Points and 2-point Conversions)

PLAY CLOCK
- Normal play loop = 40 in-game seconds
- KO, XP, or 2P plays = 20 in-game seconds
- Amount of time players have to select a Play, select Cards, and press the Ready button
- If the Play Clock expires, AI chooses a Play for the team but does NOT play any Cards for the team and then presses the Ready button
- If the Play Clock expires on 3 consecutive plays, the team Forfeits the game
- Resets after each Play is resolved

TIMEOUTS
- A Timeout is called when a Team presses their Timeout button
- Game Clock pauses and restarts after both Team press the Ready button before the next play executes
- Play Clock resets

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
- Punt distance and landing zone are determined by the Punter’s stats and modifiers.
- Punts may be blocked by the Defense.
- The Receiving Team may attempt a return based on Returner ability, blocking, coverage, cards, and modifiers.
- Punt returns are resolved at the **tile** level, with large returns and touchdowns being uncommon.

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
- After a TD is scored by either team, the Game Clock pauses, the Play Clock resets to 20 and runs
- The team that scored the TD chooses a play FIRST; the opponent is notified as to what type of play the scoring team selected (XP or 2P)

- Scoring team:
-- Selects either XP or 2P (may add FAKE XP plays later), Cards, and presses Ready, the Play Clock resets to 20 to allow the non-scoring team to select a play

- Non-Scoring Team
-- Can see the type of play (XP or 2P) selected by the Scoring team before selecting their play
-- If the scoring team selected XP, may select a standard DEF play or XP Block play
-- If the scoring team selected 2P, may select a standard DEF play

- XP or 2P play is resolved

INJURIES
- There is a chance that individual players may be injured based on their Toughness stat
- Game Clock pauses
- Team with injury may make a substitution for the injured player
- Injury Timer - The team making the sub


FORFEIT
- Occurs when:
-- Team does not press the Ready button for 3 consecutive plays
-- Team presses the Forfeit button
- Team that Forfeits loses the game
-- If the Team winning Forfeits, the Game is considered a Loss for that team 
--- Recorded as a Forfeit Loss in the Team History for the Forfeiting team and a Forfeit Win in the Team History for the team that did not Forfeit; The current score of the game is recorded for both teams; if the score is 0-0, the game is Abandoned and nothing is recorded in Team Histories; Rewards for the non-Forfeiting team are still awarded
-- If the Team losing Forfeits, the Game is considered a Loss for that team 
--- Recorded as a Forfeit Loss in the Team History for the Forfeiting team and a Forfeit Win in the Team History for the team that did not Forfeit; The current score of the game is recorded for both teams; if the score is 0-0, the game is Abandoned and nothing is recorded in Team Histories; Rewards for the non-Forfeiting team are still awarded
- If both teams Forfeit simultaneously due to not pressing the Ready button for 3 consecutive turns OR they press the Forfeit button on the same turn, the Game is considered abandoned and no stats are recorded; It's as if the Game never happened; No Rewards are awarded for either team

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
- The chance of success starts with the Offensive vs the Defensive play selection. The Defense attempts to call a play that matches up well defensively against the Offensive playa Run against a Deep Pass Defense is more likely to succeed, a Deep Pass against a Run Defense is more likely to succeed
- Best matchups for Defense that give a higher success rate to the Defense:
-- Run Def vs Run Off
-- Short Pass Def vs Short Pass Off
-- Deep Pass Def vs Deep Pass Off
-- FG/XP block vs **spot kick** (FG/XP)
- If the Defensive play does not match the Offensive play, the Offense has a somewhat better chance of success
-- e.g. Deep Pass Defense vs Run - Much higher chance Run will gain more Tiles, Run Defense vs Short Pass Offense - Slightly higher chance Short Pass will gain more Tiles, etc.
- After the Play type comparison, modifiers are taken into account
-- Player modifiers
-- Coordinator modifiers
-- Card modifiers


ZONES
- My Endzone - The team's own Endzone they are defending; If the Off is tackled in this zone, the opponent is awarded a Safety (2 points)
- Build Zone - 1st Zone furthest from the Endzone the team is Attacking
- Advance Zone - 2nd Zone 
- Midfield Zone - 3rd Zone in the middle of the field
- Attack Zone - 4th Zone on the opponent's side of the field
- Red Zone - 5th Zone on the opponent's side of the field closest to the Endzone they are Attacking
- Endzone - Final Zone which scores a TD (6 points) and has the opportunity to kick and XP or go for a 2P

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
First downs are measured in **tile rows** (10 rows gained toward the opponent’s goal from the current chain’s line of scrimmage row). When **not** goal to go, the HUD/field highlights the target row in yellow. In **goal to go** (LOS within 10 tile rows of the scoring endzone), there is no first-down marker; the **full scoring endzone** is highlighted in yellow instead.
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