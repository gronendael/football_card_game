extends Node
class_name GameState

signal state_changed
signal possession_started(team: String)
signal possession_ended(summary: Dictionary)
signal halftime_started
signal game_ended(result: String)

const PHASE_PLAY_SELECTION := "play_selection"
const PHASE_RESOLVING := "resolving"
const PHASE_DRIVE_OVER := "drive_over"
const PHASE_HALFTIME := "halftime"
const PHASE_GAME_OVER := "game_over"
const PHASE_CARD_SELECTION := "card_selection"
const PHASE_TARGETING := "targeting"
const PHASE_CONVERSION := "conversion"

const PENDING_NONE := "none"
## `pending_play_type` holds a catalog **play id** (e.g. run_01). Use PlaysCatalog.bucket() for run/pass/kick buckets.
const BUCKET_RUN := "run"
const BUCKET_PASS := "pass"
const BUCKET_SPOT_KICK := "spot_kick"

const MAX_CLOCK_SECONDS := 300
const HALF_SECONDS := 150
const MAX_ZONE := 7
const ZONE_MY_END := 1
const ZONE_START := 2
const ZONE_ADVANCE := 3
const ZONE_MIDFIELD := 4
const ZONE_ATTACK := 5
const ZONE_RED := 6
const ZONE_END := 7
const DEFAULT_START_ZONE := ZONE_START
const PHASE_CARD_QUEUE := "card_queue"

const TILE_ROWS_PER_ZONE := 5
const TILE_ROWS_TOTAL := MAX_ZONE * TILE_ROWS_PER_ZONE
const FIRST_DOWN_TILE_ROWS := 10
## Receiving possession LOS for touchback-style spots — Build zone row **25** (5th tile of Build / 1 row from Advance at row 24; engine row 0 = scoring end). Used: game start, halftime 2nd half, post-conversion kickoff, punt-into-endzone.
const TOUCHBACK_LOS_ROW_ENGINE := 25

var game_time_remaining: int = MAX_CLOCK_SECONDS
var half: int = 1
var halftime_pending: bool = false
var just_started_possession: bool = false

var score_home: int = 0
var score_away: int = 0
var game_result: String = "in_progress"

var possession_team: String = "home"
var first_half_starting_team: String = "home"
var home_possessions: int = 0
var away_possessions: int = 0
var current_zone: int = DEFAULT_START_ZONE
## Current down (1–4). First down resets to 1; turnover on downs after 4th without a new first down.
var downs: int = 1
var next_drive_start_zone: int = DEFAULT_START_ZONE
## If `>= 0`, next `start_possession` from `end_possession` uses this engine LOS row (touchback). Otherwise use `los_row_engine_from_zone(start_zone)`.
var next_drive_los_row_engine: int = -1
var plays_used_current_drive: int = 0
var drive_start_zone: int = DEFAULT_START_ZONE
## Authoritative LOS engine tile row (0 = top / scoring end). `current_zone` is derived from this after moves.
var current_los_row_engine: int = 0
## Engine-space LOS tile row (0 = top / scoring endzone strip). First-down line is 10 rows toward the goal (smaller row index), or **-1** in goal-to-go (no first-down line).
var first_down_chain_base_row_engine: int = 0
var first_down_target_row_engine: int = 0
var _just_switched_for_halftime: bool = false

var phase: String = PHASE_PLAY_SELECTION
var selected_player_id: String = ""
var pending_play_type: String = PENDING_NONE

var momentum_home: int = 0
var momentum_away: int = 0

var deck_home: Array = []
var hand_home: Array = []
var discard_home: Array = []

var deck_away: Array = []
var hand_away: Array = []
var discard_away: Array = []

var card_played_this_play_home: bool = false
var card_played_this_play_away: bool = false

var drive_summaries: Array[Dictionary] = []

var queued_cards_home: Array = []
var queued_cards_away: Array = []
var queued_momentum_spent_home: int = 0
var queued_momentum_spent_away: int = 0
var home_ready: bool = false
var away_ready: bool = false
var conversion_pending: bool = false
var conversion_team: String = ""
var conversion_type: String = ""

var timeouts_home: int = 3
var timeouts_away: int = 3

func start_game() -> void:
	game_time_remaining = MAX_CLOCK_SECONDS
	half = 1
	halftime_pending = false
	score_home = 0
	score_away = 0
	game_result = "in_progress"
	first_half_starting_team = "home" if randf() < 0.5 else "away"
	possession_team = first_half_starting_team
	home_possessions = 0
	away_possessions = 0
	next_drive_start_zone = DEFAULT_START_ZONE
	next_drive_los_row_engine = -1
	drive_summaries.clear()
	_just_switched_for_halftime = false
	momentum_home = 0
	momentum_away = 0

	deck_home.clear()
	hand_home.clear()
	discard_home.clear()

	deck_away.clear()
	hand_away.clear()
	discard_away.clear()

	card_played_this_play_home = false
	card_played_this_play_away = false
	conversion_pending = false
	conversion_team = ""
	conversion_type = ""
	timeouts_home = 3
	timeouts_away = 3
	start_possession(possession_team, next_drive_start_zone, TOUCHBACK_LOS_ROW_ENGINE)

func start_possession(team: String, start_zone: int, los_row_override: int = -1) -> void:
	possession_team = team
	if los_row_override >= 0:
		current_los_row_engine = clampi(los_row_override, 0, TILE_ROWS_TOTAL - 1)
		current_zone = zone_from_engine_row(current_los_row_engine)
	else:
		current_zone = clampi(start_zone, 1, MAX_ZONE)
		current_los_row_engine = los_row_engine_from_zone(current_zone)
	drive_start_zone = current_zone
	next_drive_los_row_engine = -1
	downs = 1
	plays_used_current_drive = 0
	selected_player_id = ""
	pending_play_type = PENDING_NONE
	reset_first_down_chain_from_current_zone()

	# Reset both teams to exactly 1 on possession change.
	momentum_home = 1
	momentum_away = 1

	# Mark first play of this possession so start-of-play gain can be skipped once.
	just_started_possession = true

	card_played_this_play_home = false
	card_played_this_play_away = false

	phase = PHASE_PLAY_SELECTION

	if team == "home":
		home_possessions += 1
	else:
		away_possessions += 1

	emit_signal("possession_started", team)
	emit_signal("state_changed")

func apply_clock(seconds_used: int) -> void:
	if half == 1:
		game_time_remaining = maxi(HALF_SECONDS, game_time_remaining - seconds_used)
		if game_time_remaining <= HALF_SECONDS:
			halftime_pending = true
	else:
		game_time_remaining = maxi(0, game_time_remaining - seconds_used)

func apply_zone_delta(zone_delta: int) -> void:
	current_zone = clampi(current_zone + zone_delta, 1, MAX_ZONE)
	current_los_row_engine = los_row_engine_from_zone(current_zone)

## Map engine LOS row (0 = top / scoring end) to game zone 1..7.
func zone_from_engine_row(row: int) -> int:
	var zidx := clampi(row / TILE_ROWS_PER_ZONE, 0, MAX_ZONE - 1)
	return clampi(ZONE_END - zidx, 1, MAX_ZONE)

## Positive tile_delta moves the ball toward the scoring end (engine row decreases).
func apply_ball_movement_tile_delta(tile_delta: int) -> void:
	var r1 := clampi(current_los_row_engine - tile_delta, 0, TILE_ROWS_TOTAL - 1)
	current_los_row_engine = r1
	current_zone = zone_from_engine_row(r1)

func los_row_engine_from_zone(zone: int) -> int:
	var zone_top_based := clampi(ZONE_END - zone, 0, MAX_ZONE - 1)
	return zone_top_based * TILE_ROWS_PER_ZONE + 2

## True when LOS is within FIRST_DOWN_TILE_ROWS (10) tile rows of the scoring endzone (engine rows 0–4).
func is_goal_to_go() -> bool:
	return current_los_row_engine <= FIRST_DOWN_TILE_ROWS

func reset_first_down_chain_from_current_zone() -> void:
	first_down_chain_base_row_engine = current_los_row_engine
	if is_goal_to_go():
		first_down_target_row_engine = -1
	else:
		first_down_target_row_engine = maxi(0, first_down_chain_base_row_engine - FIRST_DOWN_TILE_ROWS)

## After a play (same possession), keep FD target invalid in goal-to-go or restore chain after leaving it.
func sync_goal_to_go_first_down_after_play() -> void:
	if is_goal_to_go():
		first_down_target_row_engine = -1
		first_down_chain_base_row_engine = current_los_row_engine
	elif first_down_target_row_engine < 0:
		reset_first_down_chain_from_current_zone()

func add_score(team: String, points: int) -> void:
	if team == "home":
		score_home += points
	else:
		score_away += points

func is_touchdown() -> bool:
	return current_zone >= ZONE_END

func end_possession(ended_by: String, points_scored: int = 0) -> void:
	phase = PHASE_DRIVE_OVER
	var summary := {
		"possession_team": possession_team,
		"plays_used": plays_used_current_drive,
		"zones_gained": max(current_zone - drive_start_zone, 0),
		"points_scored": points_scored,
		"ended_by": ended_by
	}
	drive_summaries.append(summary)
	emit_signal("possession_ended", summary)

	if conversion_pending and ended_by == "touchdown":
		emit_signal("state_changed")
		return

	if game_time_remaining <= 0:
		end_game_if_time_up()
		return

	var next_team := "away" if possession_team == "home" else "home"
	var keep_turnover_spot := ended_by == "turnover_on_downs" or ended_by == "fumble_recovery" or ended_by == "interception" or ended_by == "missed_field_goal" or ended_by == "punt"
	if points_scored <= 0 and not keep_turnover_spot:
		next_drive_start_zone = DEFAULT_START_ZONE
		next_drive_los_row_engine = -1
	if phase == PHASE_GAME_OVER:
		return
	if not _just_switched_for_halftime:
		start_possession(next_team, next_drive_start_zone, next_drive_los_row_engine)
	_just_switched_for_halftime = false

func end_game_if_time_up() -> void:
	phase = PHASE_GAME_OVER
	if score_home > score_away:
		game_result = "home_win"
	elif score_away > score_home:
		game_result = "away_win"
	else:
		game_result = "tie"
	emit_signal("game_ended", game_result)
	emit_signal("state_changed")

func should_force_halftime_now() -> bool:
	return half == 1 and game_time_remaining <= HALF_SECONDS

func force_halftime_now() -> void:
	if half != 1:
		return

	half = 2
	game_time_remaining = HALF_SECONDS
	phase = PHASE_HALFTIME

	var second_half_starter := "away" if first_half_starting_team == "home" else "home"
	next_drive_start_zone = DEFAULT_START_ZONE
	start_possession(second_half_starter, next_drive_start_zone, TOUCHBACK_LOS_ROW_ENGINE)
