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
- **Positions** (JSON array): each entry `{ "role", "delta_row", "delta_col" }` relative to the **ball at the LOS center tile** `(0,0)`. Engine: row **0** = scoring end; positive ball movement decreases row index. **`side: "offense"`:** use **`delta_row` ≥ 0** only (LOS row = 0, larger = backfield toward own end); negative `delta_row` would be past the LOS toward the goal and is rejected at load. **`side: "defense"` / `"special"`:** negative `delta_row` is allowed (toward the offense’s scoring end / into the offensive backfield from the LOS).
- **7v7:** each formation lists **exactly 7** positions. Per-role counts must stay within global caps (see [docs/Team_Setup.md](Team_Setup.md)); [scripts/formations_catalog.gd](scripts/formations_catalog.gd) enforces count **== 7** and per-family maxima at load.
- Data: [data/formations.json](data/formations.json); loader/validation: [scripts/formations_catalog.gd](scripts/formations_catalog.gd)
- Role keys used in data include: `QB`, `RB1`…, `WR1`…, `OL1`…, `DL1`…, `LB1`…, `CB1`…, `S1`…, `K`, `P`, `RET1`/`RET2`, `ST1`…`ST6`

### OFFENSIVE PLAYS
- ID
- Name
- Type (Run, Short Pass, Deep Pass, **Spot kick** (FG + XP), Kickoff, Punt)
- **Formation ID** (references [data/formations.json](data/formations.json))
- Data: [data/plays.json](data/plays.json) (no per-play tile min/max on advancement; resolver defines ranges). Defense entries live in the same file with `side: "defense"` and ids such as `run_def`, `man_to_man`, `zone`, `fg_def` (aligned with engine play-type selection). Runtime lookup: [scripts/plays_catalog.gd](../scripts/plays_catalog.gd) (`formation_id_for`).
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
- **Formation ID** (same `formation_id` pattern as offense; seven roles from [data/formations.json](data/formations.json) via the play row in [data/plays.json](data/plays.json))

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

### FIELD ZONES (macro; `GameState` IDs 1–7)

`current_zone` is stored for the **possession (offense) team**. **Card modifiers and data** should use this **numeric ID** (not display strings).

| ID | Constant | Offense display | Defense display (same spot, defending team HUD) |
|----|-----------|-----------------|---------------------------------------------------|
| 1 | `ZONE_MY_END` | Defensive Endzone | Scoring Endzone |
| 2 | `ZONE_START` | Build Zone | Contain Zone |
| 3 | `ZONE_ADVANCE` | Advance Zone | Control Zone |
| 4 | `ZONE_MIDFIELD` | Midfield Zone | Midfield Zone |
| 5 | `ZONE_ATTACK` | Attack Zone | Pressure Zone |
| 6 | `ZONE_RED` | Red Zone | Goal Line Zone |
| 7 | `ZONE_END` | Scoring Endzone | Defensive Endzone |

- In-game **Zone** HUD label uses **offense** names when the viewer’s team has the ball, **defense** names when the viewer’s team is on defense (`scripts/game_scene.gd`: `_zone_display_for_team`).
- Event logs and resolver strings use **offense** names (`_zone_name`) as the canonical field description for the current possession. **Field goal** result lines: good `#66ff00`, missed `#ff6666` (then turnover text).

### GAME STATE (runtime / prototype)
- `downs` — current down, **1–4**; resets to **1** on new possession and on each new first down
- `first_down_chain_base_row_engine` / `first_down_target_row_engine` — engine tile row for LOS at chain start and yellow first-down line (**10 rows** toward the goal from base); `first_down_target_row_engine == -1` when **goal to go** (LOS within 10 rows of the scoring endzone — no first-down line; still 4 downs to score)
- `current_zone` — macro field position (**1–7**; see FIELD ZONES above); FG range and modifiers use zone IDs
- `current_los_row_engine` — authoritative LOS **engine tile row** (0 = top / scoring end); updated each play by `tile_delta`; `current_zone` is derived from this row (not reset from zone-only anchors between plays)
- **`TOUCHBACK_LOS_ROW_ENGINE` (25)** — **all** receiving-team starts that use the touchback spot: **opening kickoff** (`start_game`), **halftime second-half start** (`force_halftime_now`), **post-conversion kickoff**, and **punt into endzone** (via `next_drive_los_row_engine` + `end_possession`). Build zone, 5th tile / one row from Advance. `start_possession(..., los_row_override)`; `next_drive_los_row_engine` for punt `end_possession` handoff.
- User HUD **down & distance** text uses `downs` plus `max(0, current_los_row_engine - first_down_target_row_engine)` tile rows when `first_down_target_row_engine >= 0`; **goal to go** or `first_down_target_row_engine < 0` shows `… and Goal`
- Ball spot / first-down logic use **`current_los_row_engine`**; standard-play **defense matchup** and OC **`standard_zone_bonus`** adjust `tile_delta` in **whole tile rows** (not ×5)

### PUNT RETURN (resolver / `resolve_punt` modifier map)
- **Net tile rows** = `punt_rows - return_rows` (no minimum floor; can be negative). **Zone** after punt: `current_zone + round(net / 5)`, clamped to `[1, MAX_ZONE]` (`resolve_punt` → `game_scene` punt result).
- **1 tile row ≈ 1 yd** of return gain. Tiered sampling (see `scripts/play_resolver.gd`); returner = `PlayerData.get_primary_return_candidate(receiving team)` (speed + agility + catching vs punter tackling + awareness for coverage bias).
- Optional int keys on coordinators in [data/coaches_catalog.json](data/coaches_catalog.json): receiving team **`def_coord.bonus_defense.punt_return_bonus`** — shifts tier mass toward longer returns; punting team **`off_coord.bonus_offense.punt_coverage_bonus`** — shifts mass toward short / zero returns.
- **`card_return_bonus` / `card_coverage_bonus`** (ints, default **0** in `_build_punt_return_modifiers`) — reserved for queued card / effect hooks to nudge the same weights.

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

### LIVE GAME (GameScene HUD / testing)
- **`show_action_timer_bar`** (bool export on [scenes/game_scene.tscn](scenes/game_scene.tscn) root, mirrored by HUD **Play clock (10s)** `CheckButton`): **`true`** — 10s play clock, progress bar, delay-of-game / defense timeout pick / card-queue auto-ready from timer; **`false`** — no countdown or timer-driven behavior (analysis / testing).
- **`_defer_scrimmage_game_clock_until_first_snap`** (`game_scene.gd`): while **`true`**, the **game clock** does not run during scrimmage **offense** play-selection windows; cleared when **`_resolve_play`** starts (first snap of the half after play + cards); set again on **Restart** and when the **second half** begins (`_after_force_halftime_second_half`). While defer is on, **`_apply_sim_presnap_runoff`** does not subtract **`game_time_remaining`** (sim play clock bar still drains if enabled).
- **Last play toast:** after most play outcomes, a **2s** line centered on **`MobileFrame`** (bold italic colored text, **~88px** font, no panel); gain/loss/punt-net lines use **yard** phrasing only (tile rows ≈ yards; no duplicate tile-row suffix). See `game_scene.gd` (`_show_last_play_toast`, `_maybe_toast_after_standard_apply_play`).
