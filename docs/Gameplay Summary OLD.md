GAMEPLAY SUMMARY

### PRE-GAME
- Coin Toss
-- Away player selects heads or tails
-- Random coin flip
-- Team that wins the coin toss chooses either Kickoff or Receive
--- Kickoff -> 1st half - Kickoff to the other team; 2nd half - Receive kickoff from other team
--- Receive -> 1st half - Receive kickoff from other team; 2nd half - Kickoff to the other team

### START GAME

1ST HALF KICKOFF
- Game Clock is NOT running; Play Clock IS running
- Kicking team selects Kickoff play; Receiving team selects Kickoff Receiving play (Based on Coin Toss results)
- Kickoff play executes and resolves

### PLAY LOOP
PRE-SNAP PLAY SELECTION (Off = TEAM IN POSSESSION; Def = TEAM NOT IN POSSESSION)
- Play Clock is running; Game Clock may be Paused or Unpaused depending on factors listed in the Game Clock section
- Both teams select a Play from their Playbook based on the Playbook that is currently equipped for their team
- Both teams select Cards from their Deck based on the Deck that is currently equipped for their team (Cards act as modifiers which may adjust percentage chance of success or failure, adding/substracting stats to players/coaches/teams, effects to playbooks/decks, effects to Game Clock/Play Clock, effects to Momentum, effects to Downs, and more.
- Both teams select Ready button when they are ready for the play to execute
- When a team selects a Play:
-- AI selects the Players for each position based on the Team's setup (see TEAM SETUP & PRE-GAME SETUP section)

PLAY EXECUTION & RESOLUTION
- After both Teams have pressed Ready button the current Play executes and resolves (or AI presses the Ready button)
- Pause/Unpause the Game Clock if appropriate (Game Clock does NOT Unpause for Extra Points or 2-point Conversions)
- Based on the Plays & Cards selected modifiers are applied to players, cards, plays, coaches, etc.
- The Offense may progress zones, regress zones, or end up in the same zone based on the Play Resolution
- A Change of Possession may occur due to a Turnover, Running out of Downs (Turnover on Downs), 1st Half ends, Punt play, Kickoff Play
- Plays that start before the Game Clock expires in the 1st or 2nd half resolve completely even if the Game Clock expires during the play
- The Play resolves while visually displaying Player movements, ball movement from player to player, blocks, tackles, passes, runs, interceptions, fumbles, scoring, etc.
- Play Loop resets allowing Teams to select their next Play and Cards
- Play Clock resets
- Game Clock may be Paused or Unpaused depending on factors listed in the Game Clock section

SCORING PLAYS, TURNOVERS, HALFTIME
- Game Clock is paused
- Play Clock resets based on Play Clock section

### HALFTIME
- Teams may 

### 2ND HALF

2nd HALF KICKOFF
- Game Clock is NOT running; Play Clock IS running
- Team that Kicked off in the 1st half Receives the ball to start the 2nd half
- Kicking team selects Kickoff play; Receiving team selects Kickoff Receiving play
- Kickoff play executes and resolves
- Go back to Play Loop

### END OF GAME
- Occurs when the Game Clock hits 0 in the 2nd Half
- Winner and Loser are declared based on Team Scores
- Team History is updated with:
-- Win/Loss count
-- Final Score
-- Player stats (e.g. number of catches, number of runs, number of passes completed, number of incomplete passes, tackles, turnovers forced, field goals made, touchdowns scored, and many more)
-- Coach stats (e.g. wins/losses, and more to come)
- In-game currency, plays, cards, etc. are awarded to both Teams based on the result

### DOWNS
- The team in possession as 4 Downs to gain 2 zones starting from 1 and going to 4
- When a team first gains possession of the ball, they start with 1st Down
- After a play is resolved, the Down increments
- On a Change of Possesion, the Downs reset to 1 for the team that now has possession
- If the team in possession does not gain 2 zones within the 4 Downs, there is a Turnover on Downs and their opponent gains possession in the same zone that the previous team ended up at
- On 4th Down (or earlier if the Team in Possession chooses), a Team may Punt

### CLOCKS

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

### TIMEOUTS
- A Timeout is called when a Team presses their Timeout button
- Game Clock pauses and restarts after both Team press the Ready button before the next play executes
- Play Clock resets

### PLAYS
OFFENSIVE PLAYS
- Only selected by the Team in Possession
- May select any Offensive Play from the Playbook (including Punt, FG)
- AI reviews the formation for the selected play and automatically chooses the players from the lineup for each position needed based on the team's Depth Chart

DEFENSIVE PLAYS
- Only selected by the Team NOT in Possession
- May select any Defensive Play from the Playbook
- AI reviews the formation for the selected play and automatically chooses the players from the lineup for each position needed based on the team's Depth Chart

KICKOFF PLAYS
- The Kicking Team kicks the ball to the Receiving Team.
- Kick distance and landing zone are determined by the Kicker’s stats and modifiers.
- The Receiving Team attempts a return based on the Returner’s stats, blocking, coverage players, cards, and other modifiers.
- Returns are resolved at the tile level and then converted into zone advancement.
- Most returns result in little to moderate advancement, while long returns and return touchdowns are rare outcomes.

PUNTING PLAYS
- The Punting Team punts the ball to the Receiving Team.
- Punt distance and landing zone are determined by the Punter’s stats and modifiers.
- Punts may be blocked by the Defense.
- The Receiving Team may attempt a return based on Returner ability, blocking, coverage, cards, and modifiers.
- Punt returns are resolved at the tile level and converted into zone advancement, with large returns and touchdowns being uncommon.

### SCORING
TOUCHDOWN
- 6 points for OFF

EXTRA POINT PLAYS
- 1 point for OFF

2-POINT CONVERSION PLAYS
- 2 points for OFF

FIELD GOAL PLAYS
- 3 points for OFF

SAFETY 
- 2 points for DEF

### TOUCHDOWNS
- After a TD is scored by either team, the Game Clock pauses, the Play Clock resets to 20 and runs
- The team that scored the TD chooses a play FIRST; the opponent is notified as to what type of play the scoring team selected (XP or 2P)

- Scoring team:
-- Selects either XP or 2P (may add FAKE XP plays later), Cards, and presses Ready, the Play Clock resets to 20 to allow the non-scoring team to select a play

- Non-Scoring Team
-- Can see the type of play (XP or 2P) selected by the Scoring team before selecting their play
-- If the scoring team selected XP, may select a standard DEF play or XP Block play
-- If the scoring team selected 2P, may select a standard DEF play

- XP or 2P play is resolved

### INJURIES
- There is a chance that individual players may be injured based on their Toughness stat
- Game Clock pauses
- Team with injury may make a substitution for the injured player
- Injury Timer - The team making the sub


### FORFEIT
- Occurs when:
-- Team does not press the Ready button for 3 consecutive plays
-- Team presses the Forfeit button
- Team that Forfeits loses the game
-- If the Team winning Forfeits, the Game is considered a Loss for that team 
--- Recorded as a Forfeit Loss in the Team History for the Forfeiting team and a Forfeit Win in the Team History for the team that did not Forfeit; The current score of the game is recorded for both teams; if the score is 0-0, the game is Abandoned and nothing is recorded in Team Histories; Rewards for the non-Forfeiting team are still awarded
-- If the Team losing Forfeits, the Game is considered a Loss for that team 
--- Recorded as a Forfeit Loss in the Team History for the Forfeiting team and a Forfeit Win in the Team History for the team that did not Forfeit; The current score of the game is recorded for both teams; if the score is 0-0, the game is Abandoned and nothing is recorded in Team Histories; Rewards for the non-Forfeiting team are still awarded
- If both teams Forfeit simultaneously due to not pressing the Ready button for 3 consecutive turns OR they press the Forfeit button on the same turn, the Game is considered abandoned and no stats are recorded; It's as if the Game never happened; No Rewards are awarded for either team

### CHANGES OF POSSESSION
- Turnover on Downs (Downs have reached 4 and Off does not gain 2 zones)
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

### BASE PLAY TYPE SUCCESS/RESOLUTION
- As the Offense attempts to gain zones and move the ball up the field, the type of play selected by both the Offense and Defense is fundamental to determing the success of the play
- The chance of success starts with the Offensive vs the Defensive play selection. The Defense attempts to call a play that matches up well defensively against the Offensive playa Run against a Deep Pass Defense is more likely to succeed, a Deep Pass against a Run Defense is more likely to succeed
- Best matchups for Defense that give a higher success rate to the Defense:
-- Run Def vs Run Off
-- Short Pass Def vs Short Pass Off
-- Deep Pass Def vs Deep Pass Off
-- FG Block vs FG 
- If the Defensive play does not match the Offensive play, the Offense has a somewhat better chance of success
-- e.g. Deep Pass Defense vs Run - Much higher chance Run will gain more Tiles, Run Defense vs Short Pass Offense - Slightly higher chance Short Pass will gain more Tiles, etc.
- After the Play type comparison, modifiers are taken into account
-- Player modifiers
-- Coach modifiers
-- Card modifiers


### ZONES
- My Endzone - The team's own Endzone they are defending; If the Off is tackled in this zone, the opponent is awarded a Safety (2 points)
- Build Zone - 1st Zone furthest from the Endzone the team is Attacking
- Advance Zone - 2nd Zone 
- Midfield Zone - 3rd Zone in the middle of the field
- Attack Zone - 4th Zone on the opponent's side of the field
- Red Zone - 5th Zone on the opponent's side of the field closest to the Endzone they are Attacking
- Endzone - Final Zone which scores a TD (6 points) and has the opportunity to kick and XP or go for a 2P

### REWARDS (To be fleshed out later)
- In-game currency
- New Cards
- New Plays
- Player Boosts
- Coach Boosts
