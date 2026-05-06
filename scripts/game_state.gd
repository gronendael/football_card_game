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

const PENDING_NONE := "none"
const PLAY_RUN := "run"
const PLAY_SHORT_PASS := "short_pass"
const PLAY_DEEP_PASS := "deep_pass"
const PLAY_FIELD_GOAL := "field_goal"

const MAX_CLOCK_SECONDS := 300
const HALF_SECONDS := 150
const MAX_ZONE := 7
const DEFAULT_START_ZONE := 2
const PHASE_CARD_QUEUE := "card_queue"

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
var drive_points: int = 6
var next_drive_start_zone: int = DEFAULT_START_ZONE
var plays_used_current_drive: int = 0
var drive_start_zone: int = DEFAULT_START_ZONE
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
	start_possession(possession_team, next_drive_start_zone)

func start_possession(team: String, start_zone: int) -> void:
	possession_team = team
	current_zone = clampi(start_zone, 1, MAX_ZONE)
	drive_start_zone = current_zone
	drive_points = 6
	plays_used_current_drive = 0
	selected_player_id = ""
	pending_play_type = PENDING_NONE

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

func add_score(team: String, points: int) -> void:
	if team == "home":
		score_home += points
	else:
		score_away += points

func is_touchdown() -> bool:
	return current_zone >= MAX_ZONE

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

	if game_time_remaining <= 0:
		end_game_if_time_up()
		return

	var next_team := "away" if possession_team == "home" else "home"
	if points_scored <= 0:
		next_drive_start_zone = DEFAULT_START_ZONE
	if phase == PHASE_GAME_OVER:
		return
	if not _just_switched_for_halftime:
		start_possession(next_team, next_drive_start_zone)
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
	start_possession(second_half_starter, next_drive_start_zone)
