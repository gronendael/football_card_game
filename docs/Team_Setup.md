### PLAYERS & COACHES
Player - An indivdual player that users may add/remove from their team
- Players have a number of stats that effect play outcomes during a game (e.g. speed, strength, agility, toughness, tackling, blocking, hands, stamina, etc.)
- May have additional player, team, play, or game boosts/modifiers/buffs/debuffs

Coordinator - A coach assigned as either the Offensive Coordinator (OC) or Defensive Coordinator (DC).
- Provides Plays that may be added to the Playbook
- May provide Player, Team, Play, or Game modifiers/buffs/debuffs
- May provide unique Cards to the Team's available Decks
- Comes with:
-- 6 Core Plays always available:
--- Kickoff
--- Kickoff Return
--- Spot kick (FG/XP; play id **`spot_kick`**)
--- FG/XP block
--- Punt
--- Punt Return/Block
-- 2 Offensive Plays (OC)
-- 2 Defensive Plays (DC)

Roster - A list of all players and coaches on the user's Team that they have accumulated over the course of playing the app.
- Roster Limit: 50 players

Lineup - A list of players from the user's Roster that play in games
- Lineup Limit: 22 players
- Lineup Minimum: 17 players

Positions - All of the positions that should be occupied by a player on the field
- Offense Positions
-- Quarterback (QB) - Only 1 per play
-- Running Back (RB) - Up to 2 per play
-- Wide Receivers (WR) - Up to 5 per play
-- Tight Ends (TE) - Up to 2 per play
-- Offensive Line (OL)- Up to 4 per play

- Defense Positions
-- Defensive Line (DL) - Up to 4 per play
-- Linebackers (LB) - Up to 3 per play
-- Cornerbacks (CB) - Up to 3 per play
-- Safeties (S) - Up to 2 per play

- Specialists
-- Kicker (K) - Up to 1 per Kicking play
-- Punter (P) - Up to 1 per Punting play
-- Returner (RET) - Up to 1 per Kicking/Punting play

- Kickoff Positions (Other than Kicker and Returner)
-- Special Teams (ST) - Players on the Kickoff team that are trying to tackle the Returner; Players on the Receiving team that are trying to block for the Returner

- Bench
-- All players not currently involved in a play are considered on the Bench

- All players may play ALL positions


### PLAYER POSITION ASSIGNMENTS
- Each player by default may play in ANY position
- User can select/deselect positions for each player - No limit to how many positions a player can play
- Options for Select/Deselect All Off, Def, Specialists positions

- Example:
-- Player named John Smith may play LB, CB, or S
-- Player named Steve Harvey may play RB, WR, TE, or CB
-- Player named Phil Bartlett may play OL or DL
-- Player named Stan Stevens may play QB, WR, or CB

### PLAYER DEPTH CHART
- For each position, the Depth Chart shows which players (that are eligible for that position based on the Position Assignments section) is the 1st choice, 2nd choice, 3rd, etc.
- User selected Depth Chart (Manual)
-- Select a Position
-- View all player on the Roster eligible for that Position
-- Drag/Drop players to re-sort them
-- e.g. For CB position using the Example from the Position Assignment section, John Smith is #1 preference, Stan Stevens is #2 preference, Steve Harvey is #3 preference
- Auto Depth Chart - AI organizes "best" lineup based on player stats and position eligibility

### PRE-GAME SETUP
- Before starting a new Game, each team should have selected their Lineup, a Playbook, and a Deck

- If a team has not setup the Lineup prior to starting a new Game, AI picks the strongest roster based on the players available, accounting for Injuries and Low Stamina

- If a team had not equipped a Playbook or Deck, the user may not start a new game and should be notified as to what they need to equip

### PLAYS & FORMATIONS
- Formations are Play-specific and are a map of which positions are on the field for the Play and which Tile each position starts the play on
- **7v7:** each formation on file has **exactly 7** spots; counts per role family must respect field caps below (QB 1; RB ≤2; WR ≤5; TE ≤2; OL ≤4; DL ≤4; LB ≤3; CB ≤3; S ≤2; K 1; P 1; RET ≤2; ST ≤6). Data: [data/formations.json](../data/formations.json).
- Example shells (not exhaustive):
-- OFF: QB, RB, WR, WR, OL, OL, OL
-- DEF: DL, DL, LB, LB, CB, CB, S
- Each position starts on a specific Tile on the field for the Play

- Offensive Plays - Plays that can be run when the team is in possession of the ball
-- Uses Offensive Positions only

- Defensive Plays - Plays that can be run when the team is NOT in possession of the ball
-- Uses Defensive Positions only

- Kickoff Plays - Plays that can be run for Kickoffs
-- Uses Kicker and Returner positions
-- All other positions (6 for each team) are Special Teams players

- Kicking Plays - Field Goals and Extra Points that score points for the team in possession

- Punting Plays - Plays that can be run when the team is in possession of the ball that punt the ball to the other team which usually resolves in a Change of Possession

### DECK
- The Deck is the list of Cards that may be used during a game and can be from 8 - 16 cards
- Users may create/modify/delete Decks from the appropriate screen in the app
- A Deck should be equipped to the Team before starting any game, if not, the user should be notified
- A team may have multiple Decks created but only 1 may be equipped when starting a game
- Cards available for a Deck are determined by:
-- Specific Cards received as Rewards
-- Cards that are attached to HC, OC, DC

### PLAYBOOK
- The Playbook is a list of plays that may be used during a game and can be from 3 - 12 plays
- Users may create/modify/delete Playbooks from the appropriate screen in the app
- A Playbook should be Equipped to each Team before starting any game, if not, the user should be notified
- Plays available for a Playbook are determined by:
-- Specific Plays received as Rewards
-- Plays that are attached to HC, OC, DC
