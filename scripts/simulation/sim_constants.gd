extends RefCounted
class_name SimConstants

## Simulation ticks per second (gameplay clock, not render FPS).
const TICKS_PER_SECOND := 4
## Hard cap to avoid infinite loops during development.
const MAX_PLAY_TICKS := 200
## Engine rows (0 = scoring end); 7 zones × 5 rows.
const TILE_ROWS_TOTAL := 35
const COLS := 7
const LOS_BASE_COL := 3
## Chebyshev distance for coverage “nearby” reactions (spec: within 2 tiles).
const COVERAGE_NEAR_TILES := 2
## Chebyshev distance to attempt tackle / engagement.
const TACKLE_RANGE_TILES := 1

const BALL_IN_POSSESSION := "ball_in_possession"
const BALL_HANDOFF := "handoff_in_progress"
const BALL_PASS_AIR := "pass_in_air"
const BALL_FUMBLE := "fumble_loose"
const BALL_KICK_AIR := "kick_in_air"
const BALL_DEAD := "dead_ball"

const SEP_OPEN := "open"
const SEP_TIGHT := "tight_coverage"
const SEP_CONTESTED := "contested"
const SEP_SMOTHERED := "smothered"
