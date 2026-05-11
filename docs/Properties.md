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
- Fan Support (earned over time; higher the rank, the more people at the game, and therefore the more noise that can disrupt the opponent; Home Field Advantage)

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

COACH_PLAYS
- List of Plays the Coach comes with
-- 6 Core Plays used if they are the Head Coach and are always in the Playbook
-- 2 Off Plays if they are the Offensive Coordinator (may be added to the Playbook by the user)
-- 2 Def Plays if they are the Defensive Coordinator (may be added to the Playbook by the user)

SPECIALTIES (List of specialties the coach has which gives boosts to players, plays, etc.)
- Specialty ID
- Specialty Rank

### FORMATIONS
- ID
- Name
- **Side**: `offense` | `defense` | `special` (special teams shells: spot kick, punt, kickoff, etc.)
- Optional: description, tags (strings)
- **Positions** (JSON array): each entry `{ "role", "delta_row", "delta_col" }` relative to the **ball at the LOS center tile** `(0,0)`. **Negative `delta_row`** = toward the offense’s **scoring end** (same direction as positive ball movement in sim). Multiple roles may share one tile; **even spacing within a tile is rendering-only**.
- **7v7:** each formation lists **exactly 7** positions. Per-role counts must stay within global caps (see [docs/Team_Setup.md](Team_Setup.md)); [scripts/formations_catalog.gd](scripts/formations_catalog.gd) enforces count **== 7** and per-family maxima at load.
- Data: [data/formations.json](data/formations.json); loader/validation: [scripts/formations_catalog.gd](scripts/formations_catalog.gd)
- Role keys used in data include: `QB`, `RB1`…, `WR1`…, `OL1`…, `DL1`…, `LB1`…, `CB1`…, `S1`…, `K`, `P`, `RET1`/`RET2`, `ST1`…`ST6`

### OFFENSIVE PLAYS
- ID
- Name
- Type (Run, Short Pass, Deep Pass, **Spot kick** (FG + XP), Kickoff, Punt)
- **Formation ID** (references [data/formations.json](data/formations.json))
- Data: [data/plays.json](data/plays.json) (no per-play tile min/max on advancement; resolver defines ranges)
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
- Name
- Type (Run Defense, Short Pass Defense, Deep Pass Defense, **FG/XP block**, **Kickoff return**, **Punt return**)
- Coverage Type (Man-to-Man, Zone)
- Blitzing Positions (List of player positions blitzing)
- Formation (List of 7 positions)

### PLAYBOOKS
- ID
- Name
- Cover
- Plays Maximum (Number of Plays)
- Plays Minimum (Number of Plays)
- List of Plays (manually added/removed by the user)

### CARDS
- ID
- Name
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

### DECKS
- ID
- Name
- Cover
- Deck Maximum (number of cards)
- Deck Minimum (number of cards)
- List of Cards (manually added/removed by ther user)

### GAME STATE (runtime / prototype)
- `downs` — current down, **1–4**; resets to **1** on new possession and on each new first down
- `first_down_chain_base_row_engine` / `first_down_target_row_engine` — engine tile row for LOS at chain start and yellow first-down line (**10 rows** toward the goal from base); `first_down_target_row_engine == -1` when **goal to go** (LOS within 10 rows of the scoring endzone — no first-down line; still 4 downs to score)
- `current_zone` — macro field position (named zones in UI; FG range and modifiers may still be zone-based)
- `current_los_row_engine` — authoritative LOS **engine tile row** (0 = top / scoring end); updated each play by `tile_delta`; `current_zone` is derived from this row (not reset from zone-only anchors between plays)
- Ball spot / first-down logic use **`current_los_row_engine`**; standard-play **defense matchup** and OC **`standard_zone_bonus`** adjust `tile_delta` in **whole tile rows** (not ×5)

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

### UNIFORMS
- ID
- Name
- Team ID
- Helmet ID
- Helmet Primary Color
- Helmet Secondary Color
- Helmet Accent Color
- Helmet Logo
- Jersey ID
- Jersey Primary Color
- Jersey Secondary Color
- Jersey Accent Color
- Pants ID
- Pants Primary Color
- Pants Secondary Color
- Pants Accent Color
- Socks ID
- Socks Primary Color
- Socks Secondary Color
- Socks Accent Color
- Shoes ID
- Shoes Primary Color
- Shoes Secondary Color
- Shoes Accent Color
- Home/Away/Alternate

### LOGO
- ID 
- Name
- Logo
- Image of Pattern (3 colors than can be changed by user)

### HELMET
- ID 
- Name
- Logo
- Image of Pattern (3 colors than can be changed by user)

### JERSEYS
- ID 
- Name
- Image of Pattern (3 colors than can be changed by user)

### PANTS
- ID 
- Name
- Image of Pattern (3 colors than can be changed by user)

### SOCKS
- ID 
- Name
- Image of Pattern (3 colors than can be changed by user)

### SHOES
- ID 
- Name
- Image of Pattern (3 colors than can be changed by user)

### STADIUMS
- ID
- Image of Stadium
- Altitude
- Chance of Snow
- Snow Severity Max (1 - Flurries, 5 = Blizzard)
- Chance of Rain
- Rain Severity Max (1 - Light Shower, 5 = Torrential Storm)
- Change of Wind
- Wind Severity Max (1 - Light Breeze, 5 = Hurricane Force winds)

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
