PROPERTIES
### TEAM
- ID
- Team Name
- Location (City, State)
- Stadium Name
- Icon
- Logo
- Mascot
- Primary Color
- Secondary Color
- Accent Color
- Jersey ID
- Current Playbook ID
- Current Deck ID
- Head Coach ID
- Offensive Coordinator ID
- Defensive Coordinator ID
- Player IDs for current Lineup
- Players IDs for entire Roster
- Wins/Losses/Ties
- Level/Ranking

### PLAYERS
BIO
- ID
- First Name
- Last Name
- Age
- College
- Hometown (City, State, Country)
- Current Team ID
- Picture/Image
- Jersey Number
- Height
- Weight
- Experience (Number of years played or Rookie)
- XP/Level


CORE (1-100)
- Speed
- Strength
- Agility
- Awareness
- Catching
- Stamina
- Toughness (Injury likelihood)

OFFENSE (1-100)
- Passing
- Ball Handling
- Blocking
- Route Running

DEFENSE (1-100)
- Tackling
- Coverage
- Pass Rush

SPECIAL TEAMS (1-100)
- Kick Power
- Kick Accuracy

SKILLS (List of Special Skills the player has which give boosts)
- Skill ID
- Skill Rank

### COACHES
BIO
- ID
- First Name
- Last Name
- Age
- Current Team ID

CORE (1-100)
- Leadership
- Game Management
- IQ

OFFENSE (1-100)
- Run Offense
- Short Pass 
- Deep Pass 

DEFENSE (1-100)
- Run Defense
- Short Pass Defense
- Deep Pass Defense

PLAYBOOK
- List of Plays the Coach comes with
-- 6 Core Plays used if they are the Head Coach and are always in the Playbook
-- 2 Off Plays if they are the Offensive Coordinator (may be added to the Playbook by the user)
-- 2 Def Plays if they are the Defensive Coordinator (may be added to the Playbook by the user)

SPECIALTIES (List of specialties the coach has which gives boosts to players, plays, etc.)
- Specialty ID
- Specialty Rank

### OFFENSIVE PLAYS
- ID
- Play Name
- Type (Run, Short Pass, Deep Pass, FG, XP, Kickoff, Punt)
- Formation (List of 7 positions and their Tile locations)
- Run Path
-- Tile path the RB will take for a Run Play
- Routes (List of 3-5 routes)
-- Tile path for RBs, WRs and TEs to follow on Run or Pass Plays
- Ball Carrier (for Run plays)
- Primary Target (for Pass plays)
- Secondary Target (for Pass plays)
- Base Success Rating
- Fatigue Cost
- QB Dropback Depth

### DEFENSIVE PLAYS
- ID
- Play Name
- Type (Run Defense, Short Pass Defense, Deep Pass Defense, FG/XP Block, Kickoff Return, Punt Return)
- Coverage Type (Man-to-Man, Zone)
- Blitzing Positions (List of player positions blitzing)
- Formation (List of 7 positions)

### CARDS
- ID
- Card Name
- Description
- Rarity
- Momentum Cost
- Type (Area of the game that the card effects; Player, Play, Game Clock, Play Clock, Momentum, Hand, Deck, Playbook, Coach, Blitz, etc.)
- Effect Type
- Affected Stat
- Modifier Type (value or percentage)
- Modifier Value
- Duration
- Target Scope (single player, team, play, zone, all offense, all defense)
- Valid Target(s)
- Condition (only on run plays, only while losing, only in red zone, etc.)
- Number of Plays the effect lasts (one time, multiple plays, persistent for remainder game)
- Phase (Phase the card takes effect in)
- Can Stack?
- Max Stack Count


### SKILLS (for Players)
- ID
- Skill Name
- Description
- Effects
- Rank Max
- Effect per Rank
- Trigger Condition
- Stacking Rule
- Unlock Level
- Applies to Position
- Applies to Play Type 

### SPECIALTIES (for Coaches)
- ID
- Specialty Name
- Description
- Effects

### JERSEYS
- ID
- Image of Pattern

### STADIUMS
- ID
- Image of Stadium

### SEASON EVENTS
- ID
- Week/Game Number
- Schedule
- Standings
- Wins/Losses/Ties
- Team IDs (List of teams competing in the Season)

### LEAGUES
- ID
- League Name
- League Level (associated with Team Level)
- Schedule
- Standings
- Wins/Losses/Ties
- Team IDs (List of teams competing in the Season)
