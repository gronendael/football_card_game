extends Control

const PHASE_PLAY_SELECTION := "play_selection"
const PHASE_RESOLVING := "resolving"
const PHASE_CARD_SELECTION := "card_selection"
const PHASE_TARGETING := "targeting"
const PHASE_CARD_QUEUE := "card_queue"
const PLAY_RUN := "run"
const PLAY_SHORT_PASS := "short_pass"
const PLAY_DEEP_PASS := "deep_pass"
const PLAY_FIELD_GOAL := "field_goal"
const PHASE_CONVERSION := "conversion"
const CONVERSION_XP := "xp"
const CONVERSION_2PT := "2pt"
const SIM_2PT_DIFFS := [-2, -5, -8, -10, 1, 5, 12]
const CLOCK_BASE_RATE := 2.0
const DEF_RUN := "run_def"
const DEF_MAN := "man_to_man"
const DEF_ZONE := "zone"
const DEF_FG := "fg_def"

const CARD_TILE_SCENE := preload("res://scenes/card_tile.tscn")

@onready var game_state: GameState = $GameManagers/GameState
@onready var play_resolver: PlayResolver = $GameManagers/PlayResolver
@onready var card_manager: CardManager = $GameManagers/CardManager
@onready var effect_manager: EffectManager = $GameManagers/EffectManager
@onready var targeting_manager: TargetingManager = $GameManagers/TargetingManager
@onready var player_data: PlayerData = $GameManagers/PlayerData
@onready var coach_data: CoachData = $GameManagers/CoachData
@onready var team_data: TeamData = $GameManagers/TeamData

@onready var game_clock_value_label: Label = get_node_or_null("HUDGroup/ClockPanel/GameClockValueLabel") as Label
@onready var play_clock_value_label: Label = get_node_or_null("HUDGroup/ClockPanel/PlayClockValueLabel") as Label
@onready var half_label: Label = $HUDGroup/GlobalHUD/HalfLabel
@onready var score_label: Label = $HUDGroup/GlobalHUD/ScoreLabel
@onready var possession_label: Label = $HUDGroup/GlobalHUD/PossessionLabel
@onready var zone_label: Label = $HUDGroup/GlobalHUD/ZoneLabel
@onready var drive_points_label: Label = $HUDGroup/GlobalHUD/DrivePointsLabel
@onready var phase_label: Label = $HUDGroup/GlobalHUD/PhaseLabel
@onready var result_text: RichTextLabel = $HUDGroup/PlayInfoHUD/ResultText
@onready var opponent_momentum_value_label: Label = get_node_or_null("OpponentGroup/OpponentHUD/OpponentMomentumPanel/OpponentMomentumValueLabel") as Label
@onready var opponent_hand_label: Label = $OpponentGroup/OpponentHUD/OpponentHandLabel
@onready var opponent_team_name_value_label: Label = get_node_or_null("OpponentGroup/OpponentHUD/OpponentTeamNamePanel/OpponentTeamNameValueLabel") as Label
@onready var opponent_tos_button: Button = get_node_or_null("OpponentGroup/OpponentHUD/OpponentTOsPanel") as Button
@onready var opponent_hud: Control = get_node_or_null("OpponentGroup/OpponentHUD") as Control
@onready var user_momentum_value_label: Label = get_node_or_null("UserGroup/UserHUD/UserMomentumValueLabel") as Label
@onready var user_hand_label: Label = $UserGroup/UserHUD/UserHandPanel/UserHandLabel
@onready var user_hand_cards: HBoxContainer = get_node_or_null("UserGroup/UserHUD/UserHandPanel/UserHandScroll/UserHandCards") as HBoxContainer
@onready var user_queued_label: Label = get_node_or_null("UserGroup/UserHUD/UserQueuedPanel/UserQueuedLabel") as Label
@onready var user_queued_cards: HBoxContainer = get_node_or_null("UserGroup/UserHUD/UserQueuedPanel/UserQueuedScroll/UserQueuedCards") as HBoxContainer
@onready var user_team_name_value_label: Label = get_node_or_null("UserGroup/UserHUD/UserTeamNameValueLabel") as Label
@onready var user_tos_button: Button = get_node_or_null("UserGroup/UserHUD/UserTimeoutsPanel/UserTOsPanel") as Button
@onready var user_forfeit_button: Button = get_node_or_null("UserGroup/UserHUD/UserForfeitButton") as Button
@onready var user_hud: Control = get_node_or_null("UserGroup/UserHUD") as Control
@onready var field_background: ColorRect = $Field/FieldBackground
@onready var ball_marker: ColorRect = $Field/BallMarker
@onready var possession_arrow: Label = $Field/PossessionArrow
@onready var possession_on_field_label: Label = $Field/PossessionOnFieldLabel
@onready var player_details_panel: Control = get_node_or_null("PlayerDetailsPanel") as Control
@onready var player_details_label: Label = get_node_or_null("PlayerDetailsPanel/PlayerDetailsLabel") as Label
@onready var event_log_text: RichTextLabel = get_node_or_null("HUDGroup/EventLogPanel/EventLogText") as RichTextLabel
@onready var phase_log_text: RichTextLabel = get_node_or_null("HUDGroup/PhaseLogPanel/PhaseLogText") as RichTextLabel
@onready var sim_status_label: Label = get_node_or_null("HUDGroup/GlobalHUD/SimStatusLabel") as Label
@onready var sim_stats_label: Label = get_node_or_null("HUDGroup/GlobalHUD/SimStatsLabel") as Label
@onready var user_team_label: Label = get_node_or_null("HUDGroup/GlobalHUD/UserTeamLabel") as Label
@onready var quit_button: Button = get_node_or_null("HUDGroup/GlobalHUD/QuitButton") as Button
@onready var speed_label: Label = (get_node_or_null("HUDGroup/SpeedPanel/SpeedLabel") as Label) if get_node_or_null("HUDGroup/SpeedPanel/SpeedLabel") != null else (get_node_or_null("HUDGroup/SimButtons/SpeedLabel") as Label)

@onready var opponent_play_buttons: Control = get_node_or_null("OpponentGroup/OpponentPlayButtons") as Control
@onready var opponent_run_button: Button = get_node_or_null("OpponentGroup/OpponentPlayButtons/OpponentRunButton") as Button
@onready var opponent_short_pass_button: Button = get_node_or_null("OpponentGroup/OpponentPlayButtons/OpponentShortPassButton") as Button
@onready var opponent_deep_pass_button: Button = get_node_or_null("OpponentGroup/OpponentPlayButtons/OpponentDeepPassButton") as Button
@onready var opponent_field_goal_button: Button = get_node_or_null("OpponentGroup/OpponentPlayButtons/OpponentFieldGoalButton") as Button
@onready var opponent_ready_button: Button = get_node_or_null("OpponentGroup/OpponentPlayButtons/OpponentReadyButton") as Button
@onready var opponent_extra_point_button: Button = get_node_or_null("OpponentGroup/OpponentPlayButtons/OpponentExtraPointButton") as Button
@onready var opponent_two_point_button: Button = get_node_or_null("OpponentGroup/OpponentPlayButtons/OpponentTwoPointButton") as Button

@onready var user_play_buttons: Control = get_node_or_null("UserGroup/UserHUD/UserPlayButtons") as Control
@onready var user_run_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtons/UserRunButton") as Button
@onready var user_short_pass_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtons/UserShortPassButton") as Button
@onready var user_deep_pass_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtons/UserDeepPassButton") as Button
@onready var user_field_goal_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtons/UserFieldGoalButton") as Button
@onready var user_ready_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtons/UserReadyButton") as Button
@onready var user_extra_point_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtons/UserExtraPointButton") as Button
@onready var user_two_point_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtons/UserTwoPointButton") as Button

@onready var start_button: Button = get_node_or_null("HUDGroup/SimButtons/Start") as Button
@onready var pause_button: Button = get_node_or_null("HUDGroup/SimButtons/Pause") as Button
@onready var restart_button: Button = get_node_or_null("HUDGroup/SimButtons/Restart") as Button
@onready var speed_down_button: Button = (get_node_or_null("HUDGroup/SpeedPanel/-") as Button) if get_node_or_null("HUDGroup/SpeedPanel/-") != null else (get_node_or_null("HUDGroup/SimButtons/-") as Button)
@onready var speed_up_button: Button = (get_node_or_null("HUDGroup/SpeedPanel/+") as Button) if get_node_or_null("HUDGroup/SpeedPanel/+") != null else (get_node_or_null("HUDGroup/SimButtons/+") as Button)
@onready var sim_timer: Timer = get_node_or_null("GameManagers/SimTimer") as Timer

@onready var opponent_players_container: GridContainer = get_node_or_null("OpponentGroup/OpponentPlayersContainer") as GridContainer
@onready var user_players_container: GridContainer = get_node_or_null("UserGroup/UserHUD/UserPlayersContainer") as GridContainer
@onready var card_panel: VBoxContainer = $CardsPanel/CardPanel
@onready var targeting_panel: VBoxContainer = $TargetingPanel

var _player_tokens: Dictionary = {}
@export_range(1, 5, 1) var current_phase_level: int = 5
var _opponent_flat_def_mod: int = 10
var _staff_data: Dictionary = {}
var _skills_db: Dictionary = {}
var _pending_target_card: Dictionary = {}
var _turn_initialized: bool = false
var _queue_team: String = "home"
var _last_defender_id: String = ""
var _last_skill_proc_text: String = ""
var _sim_running: bool = false
var _sim_speed: float = 1.0
var _clock_accumulator: float = 0.0
var _clock_running: bool = true
var _event_log_lines: Array[String] = []
const MAX_EVENT_LOG_LINES := 120
var _phase_log_lines: Array[String] = []
const MAX_PHASE_LOG_LINES := 180
var _phase_log_end_recorded: bool = false
var _turn_counter: int = 0
var _awaiting_defense_pick: bool = false
var _selected_defense_play: String = DEF_ZONE
var _play_ready_home: bool = false
var _play_ready_away: bool = false
var _defense_selected_explicit: bool = false

var _stats_games: int = 0
var _stats_home_wins: int = 0
var _stats_away_wins: int = 0
var _stats_ties: int = 0
var _stats_total_home_points: int = 0
var _stats_total_away_points: int = 0
var _stats_total_drives: int = 0
var _stats_total_plays: int = 0
var _stats_total_tds: int = 0
var _stats_total_fg_attempts: int = 0
var _stats_total_fg_makes: int = 0
var _stats_total_home_possessions: int = 0
var _stats_total_away_possessions: int = 0

var _game_plays: int = 0
var _game_tds: int = 0
var _game_fg_attempts: int = 0
var _game_fg_makes: int = 0
var _stats_recorded_for_current_game: bool = false
var _user_team: String = "home"
var _ai_think_lock: bool = false
var _cached_user_hand_sig: String = ""
var _cached_user_queue_sig: String = ""
var _resolved_cards_home: Array[String] = []
var _resolved_cards_away: Array[String] = []
var _resolved_effects_home: Array[String] = []
var _resolved_effects_away: Array[String] = []
var _turn_action_timer_active: bool = false
var _turn_action_time_remaining: float = 0.0
var _turn_action_timeout_handled: bool = false
var _turn_timed_out_home: bool = false
var _turn_timed_out_away: bool = false
var _manual_ready_pressed_home: bool = false
var _manual_ready_pressed_away: bool = false
var _last_play_clock_display_seconds: int = -1
var _ready_miss_streak_home: int = 0
var _ready_miss_streak_away: int = 0
var _clock_paused_for_ready_wait: bool = false
var _clock_running_before_ready_wait: bool = false
var _abandoned_game: bool = false
const TURN_ACTION_LIMIT_SECONDS := 40.0
const USER_READY_MISS_FORFEIT_TURNS := 3
const DEFAULT_USER_TEAM_ID := "bees"
const DEFAULT_OPPONENT_TEAM_ID := "cavs"
const DEFAULT_PRIMARY := Color(1.0, 1.0, 1.0, 1.0)
const DEFAULT_SECONDARY := Color(0.85, 0.85, 0.85, 1.0)
const DEFAULT_ACCENT := Color(0.35, 0.35, 0.35, 1.0)
var _home_team_id: String = DEFAULT_USER_TEAM_ID
var _away_team_id: String = DEFAULT_OPPONENT_TEAM_ID

func _zone_name(zone: int) -> String:
	match zone:
		GameState.ZONE_MY_END:
			return "MyEndZone"
		GameState.ZONE_START:
			return "StartZone"
		GameState.ZONE_ADVANCE:
			return "AdvanceZone"
		GameState.ZONE_MIDFIELD:
			return "MidfieldZone"
		GameState.ZONE_ATTACK:
			return "AttackZone"
		GameState.ZONE_RED:
			return "RedZone"
		GameState.ZONE_END:
			return "EndZone"
		_:
			return "UnknownZone"

func _team_display_name(team: String) -> String:
	var profile := _team_profile(team)
	return str(profile.get("name", team.capitalize()))

func _team_role_name(team: String) -> String:
	return "User" if team == _user_team else "Opponent"

func _team_score(team: String) -> int:
	return game_state.score_home if team == "home" else game_state.score_away

func _assign_user_team_random() -> void:
	_user_team = "home" if randf() < 0.5 else "away"
	if user_team_label:
		user_team_label.text = "You are: %s (%s)" % [_team_display_name(_user_team), _user_team.capitalize()]
	_append_event_log("[b]You are controlling: %s (%s)[/b]" % [_team_display_name(_user_team), _user_team.capitalize()])

func _team_profile(team: String) -> Dictionary:
	var team_id := _home_team_id if team == "home" else _away_team_id
	return team_data.get_by_id(team_id)

func _team_color(team: String, key: String, fallback: Color) -> Color:
	var profile := _team_profile(team)
	var colors_v: Variant = profile.get("colors", {})
	if typeof(colors_v) != TYPE_DICTIONARY:
		return fallback
	var colors: Dictionary = colors_v
	var color_hex := str(colors.get(key, ""))
	if color_hex.is_empty():
		return fallback
	if color_hex.begins_with("#"):
		return Color.html(color_hex)
	return Color.html("#" + color_hex)

func _init_team_ids_from_data() -> void:
	var ids := team_data.get_all_ids()
	if ids.is_empty():
		_home_team_id = DEFAULT_USER_TEAM_ID
		_away_team_id = DEFAULT_OPPONENT_TEAM_ID
		return
	if team_data.has_team(DEFAULT_USER_TEAM_ID):
		_home_team_id = DEFAULT_USER_TEAM_ID
	else:
		_home_team_id = ids[0]
	if team_data.has_team(DEFAULT_OPPONENT_TEAM_ID):
		_away_team_id = DEFAULT_OPPONENT_TEAM_ID
	else:
		_away_team_id = ids[0]
	if _away_team_id == _home_team_id and ids.size() > 1:
		_away_team_id = ids[1]

func _is_ai_controlled_team(team: String, include_user_autoplay: bool = false) -> bool:
	if team == _user_team:
		return include_user_autoplay and _sim_running
	return true

func _maybe_run_ai_inputs(include_user_autoplay: bool = false) -> void:
	if _ai_think_lock:
		return
	if game_state.phase == GameState.PHASE_GAME_OVER or game_state.phase == GameState.PHASE_HALFTIME:
		return
	_ai_think_lock = true

	if game_state.phase == PHASE_CONVERSION and game_state.conversion_type.is_empty():
		if _is_ai_controlled_team(game_state.conversion_team, include_user_autoplay):
			_choose_conversion(_sim_pick_conversion())
			_ai_think_lock = false
			return

	if game_state.phase == PHASE_CARD_QUEUE:
		if _is_ai_controlled_team("home", include_user_autoplay) and not game_state.home_ready:
			if not _did_team_timeout_this_turn("home"):
				_auto_queue_for_team("home", -1)
			_set_team_ready("home", true)
		if _is_ai_controlled_team("away", include_user_autoplay) and not game_state.away_ready:
			if not _did_team_timeout_this_turn("away"):
				_auto_queue_for_team("away", -1)
			_set_team_ready("away", true)
		_ai_think_lock = false
		return

	if _is_phase_allowed_for_play():
		var offense := game_state.possession_team
		var defense := "away" if offense == "home" else "home"
		if _is_ai_controlled_team(offense, include_user_autoplay) and game_state.pending_play_type == PLAY_NONE():
			_on_select_play_for_team(offense, _pick_sim_play_type(), true)
		if _is_ai_controlled_team(defense, include_user_autoplay) and not _defense_selected_explicit:
			_on_select_play_for_team(defense, _pick_sim_defense_play_for_offense(game_state.pending_play_type), true)
		if _is_ai_controlled_team(offense, include_user_autoplay):
			_on_ready_pressed_for_team(offense, true)
		if _is_ai_controlled_team(defense, include_user_autoplay):
			_on_ready_pressed_for_team(defense, true)

	_ai_think_lock = false

func _play_buttons_for_team(team: String) -> Dictionary:
	if team != _user_team:
		return {
			"container": opponent_play_buttons,
			"run": opponent_run_button,
			"short": opponent_short_pass_button,
			"deep": opponent_deep_pass_button,
			"fg": opponent_field_goal_button,
			"ready": opponent_ready_button,
			"xp": opponent_extra_point_button,
			"two": opponent_two_point_button
		}
	return {
		"container": user_play_buttons,
		"run": user_run_button,
		"short": user_short_pass_button,
		"deep": user_deep_pass_button,
		"fg": user_field_goal_button,
		"ready": user_ready_button,
		"xp": user_extra_point_button,
		"two": user_two_point_button
	}

func _ready() -> void:
	add_to_group("game_scene")
	randomize()
	if sim_timer == null:
		sim_timer = Timer.new()
		sim_timer.name = "SimTimer"
		sim_timer.wait_time = 1.0
		$GameManagers.add_child(sim_timer)

	# 1) Reset runtime state first (so start_game doesn't wipe loaded card state afterward)
	game_state.start_game()
	_ready_miss_streak_home = 0
	_ready_miss_streak_away = 0
	_manual_ready_pressed_home = false
	_manual_ready_pressed_away = false
	_abandoned_game = false
	_turn_action_timer_active = false
	_clock_running = false
	_clock_accumulator = 0.0
	_begin_new_game_stats()
	_assign_user_team_random()
	_phase_log_lines.clear()
	_phase_log_end_recorded = false
	_turn_counter = 0

	# 2) Load static data and initialize decks/hands
	_load_data()

	# 3) Wire scene logic and spawn tokens
	_wire_buttons()
	_spawn_players()

	# 4) Start-of-turn setup + HUD refresh
	_turn_initialized = false
	_begin_turn_if_needed()
	if not _turn_action_timer_active:
		_start_turn_action_timer()
	_append_phase_log("User=%s (%s), Opponent=%s" % [_team_display_name(_user_team), _user_team.capitalize(), _team_display_name("away" if _user_team == "home" else "home")], "start_game")
	_update_ui()
	_update_player_details("")
	if player_details_panel:
		player_details_panel.visible = false

func _process(delta: float) -> void:
	_tick_turn_action_timer(delta)
	if not _clock_running:
		return
	if game_state.phase == GameState.PHASE_GAME_OVER:
		return

	var clock_rate := (_sim_speed if _sim_running else 1.0) * CLOCK_BASE_RATE
	_clock_accumulator += delta * clock_rate
	while _clock_accumulator >= 1.0:
		_clock_accumulator -= 1.0
		_tick_game_clock_one_second()

func _tick_turn_action_timer(_delta: float) -> void:
	if not _turn_action_timer_active:
		return
	if game_state.phase == GameState.PHASE_GAME_OVER or game_state.phase == GameState.PHASE_HALFTIME:
		return
	if game_state.phase != PHASE_PLAY_SELECTION and game_state.phase != PHASE_CARD_QUEUE:
		return
	# When game clock is running, play clock is decremented in _tick_game_clock_one_second()
	# so both labels update on the same tick.
	if _clock_running:
		return
	var clock_rate := (_sim_speed if _sim_running else 1.0) * CLOCK_BASE_RATE
	_turn_action_time_remaining = maxf(0.0, _turn_action_time_remaining - (_delta * clock_rate))
	var display_seconds := int(ceili(_turn_action_time_remaining))
	if display_seconds != _last_play_clock_display_seconds:
		_last_play_clock_display_seconds = display_seconds
		_update_ui()
	if _turn_action_time_remaining <= 0.0 and not _turn_action_timeout_handled:
		_turn_action_timeout_handled = true
		_handle_turn_action_timeout()

func _start_turn_action_timer() -> void:
	_turn_action_timer_active = true
	_turn_action_time_remaining = TURN_ACTION_LIMIT_SECONDS
	_last_play_clock_display_seconds = int(ceili(TURN_ACTION_LIMIT_SECONDS))
	_turn_action_timeout_handled = false
	_turn_timed_out_home = false
	_turn_timed_out_away = false
	_manual_ready_pressed_home = false
	_manual_ready_pressed_away = false

func _stop_turn_action_timer() -> void:
	_turn_action_timer_active = false
	_turn_action_timeout_handled = false
	_last_play_clock_display_seconds = -1

func _team_is_ready(team: String) -> bool:
	return game_state.home_ready if team == "home" else game_state.away_ready

func _mark_timed_out_team(team: String) -> void:
	if team == "home":
		_turn_timed_out_home = true
	else:
		_turn_timed_out_away = true

func _did_team_timeout_this_turn(team: String) -> bool:
	return _turn_timed_out_home if team == "home" else _turn_timed_out_away

func _handle_turn_action_timeout() -> void:
	if game_state.phase != PHASE_PLAY_SELECTION and game_state.phase != PHASE_CARD_QUEUE:
		return
	_append_phase_subphase("turn_timeout_auto_ready")
	var offense := game_state.possession_team
	var defense := "away" if offense == "home" else "home"
	if game_state.pending_play_type == PLAY_NONE():
		_on_select_play_for_team(offense, _pick_sim_play_type(), true)
		_mark_timed_out_team(offense)
	if not _defense_selected_explicit:
		_on_select_play_for_team(defense, _pick_sim_defense_play_for_offense(game_state.pending_play_type), true)
		_mark_timed_out_team(defense)
	if game_state.phase != PHASE_CARD_QUEUE:
		return
	for team in ["home", "away"]:
		if _team_is_ready(team):
			continue
		_mark_timed_out_team(team)
		_set_team_ready(team, true)

func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	var hovered := get_viewport().gui_get_hovered_control()
	if opponent_players_container == null or user_players_container == null:
		_clear_selected_player()
		return
	if hovered != null and (
		opponent_players_container.is_ancestor_of(hovered) or user_players_container.is_ancestor_of(hovered) or hovered == opponent_players_container or hovered == user_players_container
	):
		return
	_clear_selected_player()

func _clear_selected_player() -> void:
	game_state.selected_player_id = ""
	for id in _player_tokens.keys():
		_player_tokens[id].set_selected(false)
	_update_player_details("")
	if player_details_panel:
		player_details_panel.visible = false

func _tick_game_clock_one_second() -> void:
	if game_state.half == 1:
		if game_state.game_time_remaining > GameState.HALF_SECONDS:
			game_state.game_time_remaining -= 1
			if game_state.game_time_remaining <= GameState.HALF_SECONDS:
				_append_phase_subphase("halftime")
				game_state.force_halftime_now()
				_update_ui()
				return
	else:
		if game_state.game_time_remaining > 0:
			game_state.game_time_remaining -= 1
			if game_state.game_time_remaining <= 0:
				game_state.game_time_remaining = 0
				game_state.end_game_if_time_up()
				_clock_running = false
				if sim_timer:
					sim_timer.stop()
				_update_ui()
				return

	if _turn_action_timer_active and (game_state.phase == PHASE_PLAY_SELECTION or game_state.phase == PHASE_CARD_QUEUE):
		_turn_action_time_remaining = maxf(0.0, _turn_action_time_remaining - 1.0)
		var display_seconds := int(ceili(_turn_action_time_remaining))
		if display_seconds != _last_play_clock_display_seconds:
			_last_play_clock_display_seconds = display_seconds
			_update_ui()
		if _turn_action_time_remaining <= 0.0 and not _turn_action_timeout_handled:
			_turn_action_timeout_handled = true
			_handle_turn_action_timeout()

	game_state.emit_signal("state_changed")

func _stop_clock(reason: String) -> void:
	if not _clock_running:
		return
	_clock_running = false
	_clock_accumulator = 0.0
	if not reason.is_empty():
		_append_event_log("[color=#9aa0a6][i]Clock stopped: %s[/i][/color]" % reason)

func _resume_clock_for_play() -> void:
	if game_state.phase == GameState.PHASE_GAME_OVER:
		return
	if not _clock_running:
		_clock_running = true
		_append_event_log("[color=#9aa0a6][i]Clock running[/i][/color]")

func _call_timeout(team: String) -> bool:
	var remaining := game_state.timeouts_home if team == "home" else game_state.timeouts_away
	if remaining <= 0:
		return false
	if team == "home":
		game_state.timeouts_home -= 1
	else:
		game_state.timeouts_away -= 1
	_turn_action_timer_active = true
	_turn_action_time_remaining = TURN_ACTION_LIMIT_SECONDS
	_last_play_clock_display_seconds = int(ceili(TURN_ACTION_LIMIT_SECONDS))
	_turn_action_timeout_handled = false
	_stop_clock("%s timeout" % team.capitalize())
	_append_event_log("[color=#ffd166][b](%s) TIMEOUT called - %d left[/b][/color]" % [team.capitalize(), remaining - 1])
	_update_ui()
	return true

func _maybe_sim_call_timeouts() -> bool:
	if not _clock_running:
		return false
	var sec := game_state.game_time_remaining
	var in_late_first := game_state.half == 1 and sec - GameState.HALF_SECONDS <= 30 and sec > GameState.HALF_SECONDS
	var in_late_second := game_state.half == 2 and sec <= 30 and sec > 0
	if not (in_late_first or in_late_second):
		return false
	var diff_home := game_state.score_home - game_state.score_away
	var diff_away := -diff_home
	if game_state.timeouts_home > 0 and diff_home < 0 and abs(diff_home) <= 8:
		return _call_timeout("home")
	if game_state.timeouts_away > 0 and diff_away < 0 and abs(diff_away) <= 8:
		return _call_timeout("away")
	return false

func _load_data() -> void:
	team_data.load_from_json("res://data/teams.json")
	_init_team_ids_from_data()
	player_data.load_from_json("res://data/players.json")
	coach_data.load_from_json("res://data/coaches.json")
	_load_skills_data()

	var cards_raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	var cards_typed: Array[Dictionary] = []
	if typeof(cards_raw) == TYPE_ARRAY:
		for item in cards_raw:
			if typeof(item) == TYPE_DICTIONARY:
				cards_typed.append(item)

	print("cards_raw type=", typeof(cards_raw))
	print("cards_typed size=", cards_typed.size())

	card_manager.setup(cards_typed)

	_staff_data = {
		"home": coach_data.get_team_staff("home"),
		"away": coach_data.get_team_staff("away")
	}

	# Reset card state explicitly
	game_state.hand_home = []
	game_state.hand_away = []
	game_state.discard_home = []
	game_state.discard_away = []

	game_state.deck_home = card_manager.build_deck(12)
	game_state.deck_away = card_manager.build_deck(12)

	print("deck_home size=", game_state.deck_home.size(), " deck_away size=", game_state.deck_away.size())

	# Draw using local refs, then assign back for deterministic mutation
	var hh: Array = game_state.hand_home
	var dh: Array = game_state.deck_home
	var xh: Array = game_state.discard_home
	card_manager.draw(hh, dh, xh, 2, 5)
	game_state.hand_home = hh
	game_state.deck_home = dh
	game_state.discard_home = xh

	var ha: Array = game_state.hand_away
	var da: Array = game_state.deck_away
	var xa: Array = game_state.discard_away
	card_manager.draw(ha, da, xa, 2, 5)
	game_state.hand_away = ha
	game_state.deck_away = da
	game_state.discard_away = xa

	print("post init hand H:", game_state.hand_home.size(), " A:", game_state.hand_away.size())

func _load_skills_data() -> void:
	_skills_db.clear()
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/skills.json"))
	if typeof(raw) != TYPE_ARRAY:
		return
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var skill_id := str(item.get("id", ""))
		if skill_id.is_empty():
			continue
		_skills_db[skill_id] = item

func _wire_buttons() -> void:
	var opponent_team := "away" if _user_team == "home" else "home"
	var opponent_buttons := _play_buttons_for_team(opponent_team)
	var user_buttons := _play_buttons_for_team(_user_team)

	var arun: Button = opponent_buttons.get("run") as Button
	var ashort: Button = opponent_buttons.get("short") as Button
	var adeep: Button = opponent_buttons.get("deep") as Button
	var afg: Button = opponent_buttons.get("fg") as Button
	var aready: Button = opponent_buttons.get("ready") as Button
	var axp: Button = opponent_buttons.get("xp") as Button
	var atwo: Button = opponent_buttons.get("two") as Button

	if arun:
		arun.pressed.connect(func(): _on_select_play_for_team(opponent_team, PLAY_RUN))
	if ashort:
		ashort.pressed.connect(func(): _on_select_play_for_team(opponent_team, PLAY_SHORT_PASS))
	if adeep:
		adeep.pressed.connect(func(): _on_select_play_for_team(opponent_team, PLAY_DEEP_PASS))
	if afg:
		afg.pressed.connect(func(): _on_select_play_for_team(opponent_team, PLAY_FIELD_GOAL))
	if aready:
		aready.pressed.connect(func(): _on_ready_pressed_for_team(opponent_team))
	if axp:
		axp.pressed.connect(func(): _choose_conversion_for_team(opponent_team, CONVERSION_XP))
	if atwo:
		atwo.pressed.connect(func(): _choose_conversion_for_team(opponent_team, CONVERSION_2PT))

	var hrun: Button = user_buttons.get("run") as Button
	var hshort: Button = user_buttons.get("short") as Button
	var hdeep: Button = user_buttons.get("deep") as Button
	var hfg: Button = user_buttons.get("fg") as Button
	var hready: Button = user_buttons.get("ready") as Button
	var hxp: Button = user_buttons.get("xp") as Button
	var htwo: Button = user_buttons.get("two") as Button

	if hrun:
		hrun.pressed.connect(func(): _on_select_play_for_team(_user_team, PLAY_RUN))
	if hshort:
		hshort.pressed.connect(func(): _on_select_play_for_team(_user_team, PLAY_SHORT_PASS))
	if hdeep:
		hdeep.pressed.connect(func(): _on_select_play_for_team(_user_team, PLAY_DEEP_PASS))
	if hfg:
		hfg.pressed.connect(func(): _on_select_play_for_team(_user_team, PLAY_FIELD_GOAL))
	if hready:
		hready.pressed.connect(func(): _on_ready_pressed_for_team(_user_team))
	if hxp:
		hxp.pressed.connect(func(): _choose_conversion_for_team(_user_team, CONVERSION_XP))
	if htwo:
		htwo.pressed.connect(func(): _choose_conversion_for_team(_user_team, CONVERSION_2PT))

	if start_button:
		start_button.pressed.connect(_on_start_sim_pressed)
	if pause_button:
		pause_button.pressed.connect(_on_pause_sim_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if speed_down_button:
		speed_down_button.pressed.connect(_on_speed_down_pressed)
	if speed_up_button:
		speed_up_button.pressed.connect(_on_speed_up_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if user_tos_button:
		user_tos_button.pressed.connect(func(): _call_timeout(_user_team))
	if user_forfeit_button:
		user_forfeit_button.pressed.connect(_on_user_forfeit_pressed)
	if sim_timer:
		sim_timer.timeout.connect(_on_sim_tick)
	game_state.state_changed.connect(_update_ui)

func _on_select_play_for_team(team: String, play_type: String, allow_ai: bool = false) -> void:
	if not allow_ai and _is_ai_controlled_team(team, false):
		return
	if not _is_phase_allowed_for_play():
		return
	if game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT:
		if team != game_state.conversion_team:
			return
		_on_select_play(play_type)
		return
	var offense := game_state.possession_team
	var defense := "away" if offense == "home" else "home"
	if team == offense:
		_on_select_play(play_type)
		return
	if team == defense:
		_selected_defense_play = _map_button_play_to_defense_play(play_type)
		_defense_selected_explicit = true
		if team == "home":
			_play_ready_home = false
		else:
			_play_ready_away = false
		_update_ui()
		_maybe_begin_after_play_selection()

func _on_play_non_targeted_card_for_team(team: String) -> void:
	if _is_ai_controlled_team(team, false):
		return
	if game_state.phase != PHASE_CARD_QUEUE:
		return
	if (team == "home" and game_state.home_ready) or (team == "away" and game_state.away_ready):
		return
	_on_play_non_targeted_card(team)

func _on_ready_pressed_for_team(team: String, allow_ai: bool = false) -> void:
	if not allow_ai and _is_ai_controlled_team(team, false):
		return
	if not allow_ai:
		if team == "home":
			_manual_ready_pressed_home = true
		else:
			_manual_ready_pressed_away = true
	_on_ready_pressed(team)

func _finalize_user_ready_activity_for_turn() -> void:
	var home_tracked := not _is_ai_controlled_team("home", false)
	var away_tracked := not _is_ai_controlled_team("away", false)
	if _sim_running and _user_team == "home":
		home_tracked = false
	if _sim_running and _user_team == "away":
		away_tracked = false

	if home_tracked:
		if _manual_ready_pressed_home:
			_ready_miss_streak_home = 0
		else:
			_ready_miss_streak_home += 1
			_append_event_log("[color=#ffb703][b]No Ready input (Home %d/%d)[/b][/color]" % [_ready_miss_streak_home, USER_READY_MISS_FORFEIT_TURNS])
	if away_tracked:
		if _manual_ready_pressed_away:
			_ready_miss_streak_away = 0
		else:
			_ready_miss_streak_away += 1
			_append_event_log("[color=#ffb703][b]No Ready input (Away %d/%d)[/b][/color]" % [_ready_miss_streak_away, USER_READY_MISS_FORFEIT_TURNS])

	var home_forfeit := home_tracked and _ready_miss_streak_home >= USER_READY_MISS_FORFEIT_TURNS
	var away_forfeit := away_tracked and _ready_miss_streak_away >= USER_READY_MISS_FORFEIT_TURNS
	if home_forfeit and away_forfeit:
		_apply_abandoned_game("ready_timeout_both")
		return
	if home_forfeit:
		_apply_forfeit("home", "ready_timeout")
		return
	if away_forfeit:
		_apply_forfeit("away", "ready_timeout")
		return

func _apply_forfeit(team: String, reason: String = "forfeit") -> void:
	if game_state.phase == GameState.PHASE_GAME_OVER:
		return
	var team_score := game_state.score_home if team == "home" else game_state.score_away
	var opp_score := game_state.score_away if team == "home" else game_state.score_home
	if reason == "ready_timeout":
		if team == "home":
			game_state.score_home = 0
			game_state.score_away = 7
		else:
			game_state.score_home = 7
			game_state.score_away = 0
	elif team_score > opp_score:
		if team == "home":
			game_state.score_home = 0
			game_state.score_away = 7
		else:
			game_state.score_home = 7
			game_state.score_away = 0
	if game_state.score_home > game_state.score_away:
		game_state.game_result = "home_win"
	elif game_state.score_away > game_state.score_home:
		game_state.game_result = "away_win"
	else:
		game_state.game_result = "tie"
	game_state.phase = GameState.PHASE_GAME_OVER
	_stop_turn_action_timer()
	_clock_running = false
	_clock_accumulator = 0.0
	if sim_timer:
		sim_timer.stop()
	var reason_text := "manual forfeit" if reason == "forfeit_button" else "forfeit: 3 turns without Ready"
	_append_event_log("[color=#ff4d6d][b]FORFEIT[/b][/color] %s (%s). Final: %s %d - %s %d." % [
		_team_display_name(team), reason_text, _team_display_name("home"), game_state.score_home, _team_display_name("away"), game_state.score_away
	])
	result_text.text = "[center][color=#ff4d6d][b]FORFEIT[/b][/color][/center]\nFinal: %s %d - %s %d" % [
		_team_display_name("home"), game_state.score_home, _team_display_name("away"), game_state.score_away
	]
	game_state.emit_signal("game_ended", game_state.game_result)
	game_state.emit_signal("state_changed")

func _apply_abandoned_game(reason: String = "abandoned") -> void:
	if game_state.phase == GameState.PHASE_GAME_OVER:
		return
	_abandoned_game = true
	game_state.phase = GameState.PHASE_GAME_OVER
	game_state.game_result = "abandoned"
	_stop_turn_action_timer()
	_clock_running = false
	_clock_accumulator = 0.0
	if sim_timer:
		sim_timer.stop()
	var reason_text := "both teams missed Ready 3 times" if reason == "ready_timeout_both" else reason
	_append_event_log("[color=#9aa0a6][b]ABANDONED[/b][/color] %s. Game not recorded." % reason_text)
	result_text.text = "[center][color=#9aa0a6][b]GAME ABANDONED[/b][/color][/center]\nNo final result recorded."
	game_state.emit_signal("state_changed")

func _choose_conversion_for_team(team: String, conv_type: String) -> void:
	if game_state.phase != PHASE_CONVERSION:
		return
	if team != game_state.conversion_team:
		return
	_choose_conversion(conv_type)

func _spawn_players() -> void:
	if user_players_container == null or opponent_players_container == null:
		push_warning("Player containers missing from scene tree.")
		return
	for c in user_players_container.get_children():
		c.queue_free()
	for c in opponent_players_container.get_children():
		c.queue_free()
	_player_tokens.clear()

	var token_scene: PackedScene = preload("res://scenes/player.tscn")
	for p in player_data.players:
		var token: PlayerToken = token_scene.instantiate()
		var team := str(p.get("team", ""))
		if team == "home":
			user_players_container.add_child(token)
		else:
			opponent_players_container.add_child(token)
		token.bind_player(p)
		token.selected.connect(_on_player_selected)
		_player_tokens[p["id"]] = token

func _on_select_play(play_type: String) -> void:
	if not _is_phase_allowed_for_play():
		return

	_begin_turn_if_needed()
	var is_two_point_attempt := game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT
	game_state.pending_play_type = play_type
	if is_two_point_attempt:
		_selected_defense_play = DEF_ZONE
		_begin_after_defense_pick()
		return
	if game_state.possession_team == "home":
		_play_ready_home = false
	else:
		_play_ready_away = false
	_update_ui()
	_maybe_begin_after_play_selection()

func _begin_after_defense_pick() -> void:
	if current_phase_level >= 3:
		_start_card_queue_phase()
	else:
		_resolve_play()

func _maybe_begin_after_play_selection() -> void:
	if game_state.pending_play_type == PLAY_NONE():
		return
	if not _defense_selected_explicit:
		return
	_begin_after_defense_pick()

func _map_button_play_to_defense_play(play_type: String) -> String:
	if play_type == PLAY_RUN:
		return DEF_RUN
	if play_type == PLAY_SHORT_PASS:
		return DEF_MAN
	if play_type == PLAY_FIELD_GOAL:
		return DEF_FG
	return DEF_ZONE

func _is_phase_allowed_for_play() -> bool:
	var p := game_state.phase
	if p == GameState.PHASE_GAME_OVER or p == GameState.PHASE_HALFTIME:
		return false
	if p == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT:
		return true
	return p == PHASE_PLAY_SELECTION or p == PHASE_CARD_SELECTION

func _begin_turn_if_needed() -> void:
	print("BEGIN TURN? init=", _turn_initialized, " phase=", game_state.phase, " level=", current_phase_level)
	if _turn_initialized:
		return
	_turn_initialized = true
	_turn_counter += 1
	_append_phase_log("Half %d | Turn %d | Possession: %s Ball | Zone: %s" % [game_state.half, _turn_counter, _team_display_name(game_state.possession_team), _zone_name(game_state.current_zone)], "start_turn")
	_append_phase_subphase("play_selection")
	_start_turn_action_timer()
	_advance_both_teams_resources()

func _advance_both_teams_resources() -> void:
	if game_state.just_started_possession:
		game_state.just_started_possession = false
		card_manager.draw(game_state.hand_home, game_state.deck_home, game_state.discard_home, 1, 5)
		card_manager.draw(game_state.hand_away, game_state.deck_away, game_state.discard_away, 1, 5)
		game_state.card_played_this_play_home = false
		game_state.card_played_this_play_away = false
		return
		
	game_state.momentum_home = clampi(game_state.momentum_home + 1, 0, 5)
	game_state.momentum_away = clampi(game_state.momentum_away + 1, 0, 5)

	card_manager.draw(game_state.hand_home, game_state.deck_home, game_state.discard_home, 1, 5)
	card_manager.draw(game_state.hand_away, game_state.deck_away, game_state.discard_away, 1, 5)

	game_state.card_played_this_play_home = false
	game_state.card_played_this_play_away = false
	
	print("DRAW BEFORE H:", game_state.hand_home.size(), " A:", game_state.hand_away.size())
	# draw calls...
	print("DRAW AFTER  H:", game_state.hand_home.size(), " A:", game_state.hand_away.size())

func _resolve_play() -> void:
	if game_state.pending_play_type == PLAY_NONE():
		return

	game_state.phase = PHASE_RESOLVING
	_append_phase_subphase("resolving")
	var play_result: Dictionary
	var defense_mod := _defense_modifier_for_play(game_state.pending_play_type, _selected_defense_play)

	if game_state.pending_play_type == PLAY_FIELD_GOAL and current_phase_level >= 2:
		var kicker := _kicker_for_fg_attempt()
		var kicker_id := str(kicker.get("id", ""))
		if kicker_id.is_empty():
			kicker_id = game_state.selected_player_id
		var staff_bonus := int(_staff_data[game_state.possession_team]["head_coach"].get("bonus", {}).get("field_goal_bonus", 0))
		play_result = play_resolver.resolve_field_goal(kicker_id, game_state.current_zone, kicker, _opponent_flat_def_mod + defense_mod - staff_bonus)
		play_result["breakdown"].append("Defense call: %s (%+d)" % [_selected_defense_play, defense_mod])
	else:
		if game_state.selected_player_id.is_empty():
			var team_players := player_data.get_team(game_state.possession_team)
			if team_players.size() > 0:
				game_state.selected_player_id = str(team_players[0].get("id", ""))

		play_result = play_resolver.resolve_standard_play(game_state.pending_play_type, game_state.selected_player_id, game_state.current_zone)
		play_result["breakdown"].append("Opponent defense: -%d" % _opponent_flat_def_mod)
		play_result["breakdown"].append("Defense call: %s (%+d)" % [_selected_defense_play, defense_mod])
		if defense_mod != 0:
			play_result["zone_delta"] = max(int(play_result["zone_delta"]) - 1, 0)
			play_result["breakdown"].append("Defense impact: -1 zone")

		var staff_play_bonus := int(_staff_data[game_state.possession_team]["off_coord"].get("bonus", {}).get("standard_zone_bonus", 0))
		if staff_play_bonus != 0:
			play_result["zone_delta"] = max(int(play_result["zone_delta"]) + staff_play_bonus, 0)
			play_result["breakdown"].append("Staff bonus: %+d zone" % staff_play_bonus)

	_apply_play_result(play_result)

func _defense_modifier_for_play(offense_play: String, defense_play: String) -> int:
	if offense_play == PLAY_RUN:
		if defense_play == DEF_RUN:
			return 5
		if defense_play == DEF_MAN:
			return -5
	elif offense_play == PLAY_SHORT_PASS or offense_play == PLAY_DEEP_PASS:
		if defense_play == DEF_MAN:
			return 5
		if defense_play == DEF_RUN:
			return -5
	elif offense_play == PLAY_FIELD_GOAL:
		if defense_play == DEF_FG:
			return 6
	return 0

func _apply_play_result(result: Dictionary) -> void:
	_last_skill_proc_text = ""
	var offense_team_for_summary := game_state.possession_team
	var offense_play_for_summary := game_state.pending_play_type
	var defense_play_for_summary := _selected_defense_play
	var zone_delta_for_summary := int(result.get("zone_delta", 0))
	var summary_result_text := str(result.get("result_text", ""))
	var is_two_point_attempt := game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT
	_game_plays += 1
	if game_state.pending_play_type == PLAY_FIELD_GOAL:
		_game_fg_attempts += 1
	game_state.plays_used_current_drive += 1
	game_state.drive_points -= 1
	game_state.apply_zone_delta(int(result.get("zone_delta", 0)))
	if is_two_point_attempt:
		if game_state.current_zone >= GameState.ZONE_END:
			game_state.add_score(game_state.conversion_team, 2)
			_append_event_log("[b]2-Point Conversion GOOD[/b]")
			summary_result_text = "2-Point Conversion GOOD"
			_finish_conversion("two_point_made", true)
		else:
			_append_event_log("[b]2-Point Conversion FAILED[/b]")
			summary_result_text = "2-Point Conversion FAILED"
			_finish_conversion("two_point_failed", false)
		_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, zone_delta_for_summary)
		game_state.pending_play_type = GameState.PENDING_NONE
		_selected_defense_play = DEF_ZONE
		_awaiting_defense_pick = false
		game_state.emit_signal("state_changed")
		return
	var turnover := _roll_turnover_if_any(game_state.pending_play_type, int(result.get("zone_delta", 0)))
	if bool(turnover.get("occurred", false)):
		var defensive_td := game_state.current_zone == GameState.ZONE_MY_END
		game_state.next_drive_start_zone = int(turnover.get("start_zone", GameState.DEFAULT_START_ZONE))
		game_state.end_possession(str(turnover.get("ended_by", "turnover")), 0)
		_stop_clock("turnover")
		var proc_line := ""
		if not _last_skill_proc_text.is_empty():
			proc_line = "\n[color=#ffd166][b]%s[/b][/color]" % _last_skill_proc_text
		var turnover_text := str(turnover.get("text", "Possession changes."))
		if defensive_td:
			turnover_text = "Turnover forced in MyEndZone."
		result_text.text = "[center][color=#ff4444][b]TURNOVER![/b][/color][/center]\n%s%s" % [turnover_text, proc_line]
		summary_result_text = turnover_text
		_append_event_log("[color=#ff6666][b]TURNOVER[/b][/color] %s" % turnover_text)
		if not _last_skill_proc_text.is_empty():
			_append_event_log("[color=#ffd166]%s[/color]" % _last_skill_proc_text)
		if defensive_td:
			var scoring_team := "away" if game_state.possession_team == "home" else "home"
			_game_tds += 1
			game_state.add_score(scoring_team, 6)
			game_state.conversion_pending = true
			game_state.conversion_team = scoring_team
			_append_event_log("[b]Defensive Touchdown (%s)![/b]" % scoring_team.capitalize())
			result_text.text = "[center][color=#ff4444][b]TURNOVER + DEFENSIVE TD![/b][/color][/center]\n%s%s" % [turnover_text, proc_line]
			summary_result_text = "TURNOVER + DEFENSIVE TD"
			_begin_post_td_conversion(scoring_team)
			_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, zone_delta_for_summary)
			game_state.pending_play_type = GameState.PENDING_NONE
			_selected_defense_play = DEF_ZONE
			_awaiting_defense_pick = false
			game_state.emit_signal("state_changed")
			return
		game_state.pending_play_type = GameState.PENDING_NONE
		_selected_defense_play = DEF_ZONE
		_awaiting_defense_pick = false
		_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, zone_delta_for_summary)
		_reset_next_turn_after_possession_change("turnover")
		game_state.emit_signal("state_changed")
		return

	var score_delta := int(result.get("score_delta", 0))
	if game_state.pending_play_type == PLAY_FIELD_GOAL and score_delta > 0:
		_game_fg_makes += 1
		game_state.add_score(game_state.possession_team, 3)
		game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
		game_state.end_possession("field_goal", 3)
		_stop_clock("field goal")
	elif game_state.pending_play_type == PLAY_FIELD_GOAL:
		game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
		game_state.end_possession("missed_field_goal", 0)
		_stop_clock("missed FG turnover")
		result_text.text = "[center][color=#ff4444][b]TURNOVER![/b][/color][/center]\nMissed FG. Opponent starts in %s." % _zone_name(game_state.next_drive_start_zone)
		summary_result_text = "Missed Field Goal (Turnover)"
		_append_event_log("[color=#ff6666][b]TURNOVER[/b][/color] Missed FG. Opponent starts in %s." % _zone_name(game_state.next_drive_start_zone))
	elif game_state.is_touchdown():
		_game_tds += 1
		game_state.add_score(game_state.possession_team, 6)
		game_state.conversion_pending = true
		game_state.conversion_team = game_state.possession_team
		game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
		game_state.end_possession("touchdown", 6)
		_stop_clock("touchdown")
		_begin_post_td_conversion(game_state.conversion_team)
		game_state.pending_play_type = GameState.PENDING_NONE
		_selected_defense_play = DEF_ZONE
		_awaiting_defense_pick = false
		game_state.emit_signal("state_changed")
		return
	elif game_state.game_time_remaining <= 0:
		game_state.end_game_if_time_up()
	elif game_state.drive_points <= 0:
		if game_state.current_zone == GameState.ZONE_MY_END:
			game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
			game_state.end_possession("turnover_on_downs", 0)
			_stop_clock("turnover on downs")
			var scoring_team := "away" if game_state.possession_team == "home" else "home"
			_game_tds += 1
			game_state.add_score(scoring_team, 6)
			game_state.conversion_pending = true
			game_state.conversion_team = scoring_team
			result_text.text = "[center][color=#ff4444][b]TURNOVER ON DOWNS + DEFENSIVE TD![/b][/color][/center]"
			summary_result_text = "TURNOVER ON DOWNS + DEFENSIVE TD"
			_append_event_log("[color=#ff6666][b]TURNOVER ON DOWNS[/b][/color] Defensive TD for %s." % scoring_team.capitalize())
			_begin_post_td_conversion(scoring_team)
			_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, zone_delta_for_summary)
			game_state.pending_play_type = GameState.PENDING_NONE
			_selected_defense_play = DEF_ZONE
			_awaiting_defense_pick = false
			game_state.emit_signal("state_changed")
			return
		game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
		game_state.end_possession("turnover_on_downs", 0)
		_stop_clock("turnover on downs")
		result_text.text = "[center][color=#ff4444][b]TURNOVER ON DOWNS![/b][/color][/center]\nOpponent starts in %s." % _zone_name(game_state.next_drive_start_zone)
		summary_result_text = "TURNOVER ON DOWNS"
		_append_event_log("[color=#ff6666][b]TURNOVER ON DOWNS[/b][/color] Opponent starts in %s." % _zone_name(game_state.next_drive_start_zone))
	else:
		game_state.phase = PHASE_PLAY_SELECTION

	game_state.pending_play_type = GameState.PENDING_NONE
	_selected_defense_play = DEF_ZONE
	_awaiting_defense_pick = false
	_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, zone_delta_for_summary)
	_append_event_log("[b]%s[/b]" % str(result.get("result_text", "")))

	if game_state.phase == GameState.PHASE_GAME_OVER:
		game_state.emit_signal("state_changed")
		return

	if game_state.should_force_halftime_now() and game_state.phase != GameState.PHASE_GAME_OVER:
		_append_phase_subphase("halftime")
		game_state.force_halftime_now()
		_turn_initialized = false
		game_state.emit_signal("state_changed")
		return
	
	print("END PLAY phase=", game_state.phase, " game_over=", game_state.phase == GameState.PHASE_GAME_OVER)
	
	_after_play_phase_hooks()
	game_state.emit_signal("state_changed")

func _after_play_phase_hooks() -> void:
	# End of resolved play: next play can start with new card phase setup.
	_turn_initialized = false
	if game_state.phase == PHASE_PLAY_SELECTION:
		_play_ready_home = false
		_play_ready_away = false
		_defense_selected_explicit = false
		_selected_defense_play = DEF_ZONE
		_begin_turn_if_needed()
		
	print("AFTER PLAY HOOK -> reset turn init false")

func _kicker_for_fg_attempt() -> Dictionary:
	if not game_state.selected_player_id.is_empty():
		var selected := player_data.get_by_id(game_state.selected_player_id)
		if not selected.is_empty():
			return selected
	var best := player_data.get_best_kicker(game_state.possession_team)
	var best_id := str(best.get("id", ""))
	if not best_id.is_empty():
		game_state.selected_player_id = best_id
	return best

func _can_attempt_field_goal_from_current_zone() -> bool:
	if game_state.current_zone == GameState.ZONE_ATTACK or game_state.current_zone == GameState.ZONE_RED:
		return true
	if game_state.current_zone == GameState.ZONE_MIDFIELD:
		var kicker := _kicker_for_fg_attempt()
		return int(kicker.get("kick_power", 50)) > 80
	return false

func _map_possession_start_zone(zone_at_change: int) -> int:
	match zone_at_change:
		GameState.ZONE_START:
			return GameState.ZONE_RED
		GameState.ZONE_ADVANCE:
			return GameState.ZONE_ATTACK
		GameState.ZONE_MIDFIELD:
			return GameState.ZONE_MIDFIELD
		GameState.ZONE_ATTACK:
			return GameState.ZONE_ADVANCE
		GameState.ZONE_RED:
			return GameState.ZONE_START
		GameState.ZONE_END:
			return GameState.ZONE_START
		_:
			return GameState.ZONE_START

func _roll_turnover_if_any(play_type: String, zone_delta: int) -> Dictionary:
	if play_type == PLAY_FIELD_GOAL:
		return {"occurred": false}

	var offense_player := _get_offense_ball_carrier(play_type)
	var defense_player := _select_defender_for_play(play_type)
	var fumble_roll := _roll_fumble(play_type, offense_player, defense_player)
	if bool(fumble_roll.get("turnover", false)):
		return {
			"occurred": true,
			"ended_by": "fumble_recovery",
			"start_zone": _map_possession_start_zone(game_state.current_zone),
			"text": "Fumble recovery by defense at %s. Opponent starts in %s." % [_zone_name(game_state.current_zone), _zone_name(_map_possession_start_zone(game_state.current_zone))]
		}

	var int_roll := _roll_interception(play_type, offense_player, defense_player, zone_delta)
	if bool(int_roll.get("turnover", false)):
		return {
			"occurred": true,
			"ended_by": "interception",
			"start_zone": _map_possession_start_zone(game_state.current_zone),
			"text": "Interception at %s. Opponent starts in %s." % [_zone_name(game_state.current_zone), _zone_name(_map_possession_start_zone(game_state.current_zone))]
		}

	return {"occurred": false}

func _get_offense_ball_carrier(play_type: String) -> Dictionary:
	if not game_state.selected_player_id.is_empty():
		return player_data.get_by_id(game_state.selected_player_id)
	var offense_team := player_data.get_team(game_state.possession_team)
	if offense_team.is_empty():
		return {}
	if play_type == PLAY_RUN:
		return offense_team[-1]
	return offense_team[0]

func _select_defender_for_play(play_type: String) -> Dictionary:
	var defense_team_name := "away" if game_state.possession_team == "home" else "home"
	var defenders: Array[Dictionary] = player_data.get_team(defense_team_name)
	if defenders.is_empty():
		return {}

	var best: Dictionary = defenders[0]
	var best_score: int = -999
	for d in defenders:
		var score := 0
		if play_type == PLAY_RUN:
			score = _effective_stat(d, "tackling", 60)
		else:
			score = _effective_stat(d, "coverage", 60) + _effective_stat(d, "catching", 60)
		if score > best_score:
			best_score = score
			best = d
	_last_defender_id = str(best.get("id", ""))
	return best

func _roll_fumble(play_type: String, offense: Dictionary, defense: Dictionary) -> Dictionary:
	var base := 4.0 if play_type == PLAY_RUN else 2.0
	var security := _effective_stat(offense, "ball_security", 65)
	var defender_tackling := _effective_stat(defense, "tackling", 60)
	var ball_strip_bonus := _skill_chance_bonus_pct(defense, "ball_stripping", "fumble_forced_pct")
	var big_hit_bonus := _skill_chance_bonus_pct(defense, "big_hit", "fumble_forced_pct")
	var chance := clampf(base + float(defender_tackling - security) * 0.08 + ball_strip_bonus + big_hit_bonus, 1.0, 14.0)
	var proc_labels: Array[String] = []
	if ball_strip_bonus > 0.0:
		proc_labels.append("Ball Stripping")
	if big_hit_bonus > 0.0:
		proc_labels.append("Big Hit")
	if not proc_labels.is_empty():
		_last_skill_proc_text = "Proc: %s" % ", ".join(proc_labels)
	return {"turnover": randf() * 100.0 < chance}

func _roll_interception(play_type: String, offense: Dictionary, defense: Dictionary, zone_delta: int) -> Dictionary:
	if play_type != PLAY_SHORT_PASS and play_type != PLAY_DEEP_PASS:
		return {"turnover": false}
	var base := 4.0 if play_type == PLAY_SHORT_PASS else 6.0
	var coverage := _effective_stat(defense, "coverage", 60)
	var def_catching := _effective_stat(defense, "catching", 60)
	var off_awareness := _effective_stat(offense, "awareness", 65)
	var off_catching := _effective_stat(offense, "catching", 65)
	var off_passing := _effective_stat(offense, "passing", 65)
	var hawk_bonus := _skill_chance_bonus_pct(defense, "ball_hawk", "interception_pct")
	var frozen_rope_protect := float(_skill_level(offense, "frozen_rope")) * 0.5
	var chance := clampf(base + float((coverage + def_catching) - (off_awareness + off_catching + off_passing)) * 0.05 + hawk_bonus - frozen_rope_protect, 1.0, 16.0)
	var int_proc_labels: Array[String] = []
	if hawk_bonus > 0.0:
		int_proc_labels.append("Ball Hawk")
	if frozen_rope_protect > 0.0:
		int_proc_labels.append("Frozen Rope")
	if not int_proc_labels.is_empty():
		_last_skill_proc_text = "Proc: %s" % ", ".join(int_proc_labels)
	return {"turnover": randf() * 100.0 < chance}

func _effective_stat(player: Dictionary, key: String, fallback: int) -> int:
	var value := int(player.get(key, fallback))
	var skills := _player_skills(player)
	for skill_id in skills.keys():
		var level := clampi(int(skills[skill_id]), 1, 10)
		var def = _skills_db.get(str(skill_id), {})
		if typeof(def) != TYPE_DICTIONARY:
			continue
		var stat_mods: Dictionary = def.get("stat_mods", {})
		if stat_mods.has(key):
			value += int(stat_mods.get(key, 0)) * level
	return value

func _skill_level(player: Dictionary, skill_id: String) -> int:
	var skills := _player_skills(player)
	if not skills.has(skill_id):
		return 0
	return clampi(int(skills[skill_id]), 1, 10)

func _skill_chance_bonus_pct(player: Dictionary, skill_id: String, chance_key: String) -> float:
	var level := _skill_level(player, skill_id)
	if level <= 0:
		return 0.0
	var def = _skills_db.get(skill_id, {})
	if typeof(def) != TYPE_DICTIONARY:
		return 0.0
	var chance_mods: Dictionary = def.get("chance_mods", {})
	return float(chance_mods.get(chance_key, 0.0)) * float(level)

func _player_skills(player: Dictionary) -> Dictionary:
	var skills = player.get("skills", {})
	return skills if typeof(skills) == TYPE_DICTIONARY else {}

func _update_token_visuals() -> void:
	for id in _player_tokens.keys():
		var token = _player_tokens[id]
		var p := player_data.get_by_id(str(id))
		if p.is_empty():
			continue
		var team := str(p.get("team", "home"))
		var base_color := Color(0.60, 0.78, 1.0, 1.0) if team == "home" else Color(1.0, 0.70, 0.70, 1.0)
		if team == game_state.possession_team:
			base_color = base_color.lightened(0.20)
		if str(id) == _last_defender_id:
			base_color = Color(1.0, 1.0, 0.45, 1.0)
		token.modulate = base_color

func _on_play_non_targeted_card(team: String = "") -> void:
	if current_phase_level < 3:
		return
	if game_state.phase != PHASE_CARD_QUEUE and _active_card_played_this_play():
		return

	if game_state.phase == PHASE_CARD_QUEUE:
		var queue_team := team if not team.is_empty() else _queue_team
		var queue_hand: Array = _hand_for_team(queue_team)
		if queue_hand.is_empty():
			result_text.text = "No cards available for %s." % queue_team
			_append_event_log("No cards available for %s." % queue_team)
			return
		if not _queue_first_affordable_hand_card(queue_team):
			result_text.text = "Not enough Momentum to queue a card."
			_append_event_log("Not enough Momentum to queue a card.")
			return
		var last_q: Dictionary = game_state.queued_cards_home[-1] if queue_team == "home" else game_state.queued_cards_away[-1]
		var qcard: Dictionary = last_q.get("card", {})
		result_text.text = "Queued card (%s): %s" % [queue_team, str(qcard.get("name", "Card"))]
		_append_event_log("Queued card (%s): %s" % [queue_team, str(qcard.get("name", "Card"))])
		return

	if _active_hand().is_empty():
		return
	var card: Dictionary = _active_hand()[0]

	if current_phase_level >= 4 and str(card.get("target_type", "global")) != "global":
		_begin_targeted_card(card)
		return

	var r := card_manager.play_non_targeted_card(card, _active_momentum())
	if not bool(r.get("ok", false)):
		result_text.text = str(r.get("reason", "Card failed."))
		_append_event_log(str(r.get("reason", "Card failed.")))
		return

	_set_active_momentum(_active_momentum() - int(r.get("momentum_cost", 0)))
	_set_active_card_played_this_play(true)

	_active_discard().append(card)
	_active_hand().remove_at(0)

	effect_manager.add_effect({
		"effect_data": r.get("effect_data", {})
	}, "plays", 1)

	result_text.text = "Played card (%s): %s" % [_active_team(), str(card.get("name", "Card"))]
	_append_event_log("Played card (%s): %s" % [_active_team(), str(card.get("name", "Card"))])
	_update_ui()

func _update_ui() -> void:
	_maybe_finalize_game_stats()
	if game_clock_value_label:
		game_clock_value_label.text = "Game Clock: " + _format_time(game_state.game_time_remaining)
	half_label.text = "Half: %d" % game_state.half
	score_label.text = "Score %s:%d %s:%d" % [_team_display_name("home"), game_state.score_home, _team_display_name("away"), game_state.score_away]
	if user_team_label:
		user_team_label.text = "You are: %s (%s)" % [_team_display_name(_user_team), _user_team.capitalize()]
	if user_hud:
		user_hud.visible = true
	if opponent_hud:
		opponent_hud.visible = false
	if user_play_buttons:
		user_play_buttons.visible = true
	if opponent_play_buttons:
		opponent_play_buttons.visible = false
	possession_label.text = "Possession: %s Ball (H:%d A:%d)" % [_team_display_name(game_state.possession_team), game_state.home_possessions, game_state.away_possessions]
	var display_zone := game_state.current_zone
	if game_state.conversion_pending and game_state.phase == PHASE_CONVERSION:
		display_zone = GameState.ZONE_END
	zone_label.text = "Zone: %s" % _zone_name(display_zone)
	drive_points_label.text = "Drive Points: %d" % game_state.drive_points
	phase_label.text = "Phase: %s (P%d)" % [game_state.phase, current_phase_level]
	var play_clock_visible := _turn_action_timer_active
	if play_clock_value_label:
		play_clock_value_label.text = "Play Clock: " + "%d" % int(ceili(_turn_action_time_remaining)) if play_clock_visible else "-"

	var user_team := _user_team
	var opponent_team := "away" if user_team == "home" else "home"
	if opponent_momentum_value_label:
		opponent_momentum_value_label.text = "%d" % (game_state.momentum_away if opponent_team == "away" else game_state.momentum_home)
	if user_momentum_value_label:
		user_momentum_value_label.text = "%d" % (game_state.momentum_home if user_team == "home" else game_state.momentum_away)
	if opponent_tos_button:
		var opp_tos := game_state.timeouts_away if opponent_team == "away" else game_state.timeouts_home
		opponent_tos_button.text = "TOs\n%d" % opp_tos
		opponent_tos_button.disabled = true
	if user_tos_button:
		var user_tos := game_state.timeouts_home if user_team == "home" else game_state.timeouts_away
		user_tos_button.text = "%d" % user_tos
		user_tos_button.disabled = user_tos <= 0
	if user_forfeit_button:
		user_forfeit_button.disabled = game_state.phase == GameState.PHASE_GAME_OVER
	var opp_hand_n := game_state.hand_away.size() if opponent_team == "away" else game_state.hand_home.size()
	var opp_queue_n := game_state.queued_cards_away.size() if opponent_team == "away" else game_state.queued_cards_home.size()
	opponent_hand_label.text = "Hand (%d)\nQueued (%d)" % [opp_hand_n, opp_queue_n]

	var user_hand_n := game_state.hand_home.size() if user_team == "home" else game_state.hand_away.size()
	var user_queue_n := game_state.queued_cards_home.size() if user_team == "home" else game_state.queued_cards_away.size()
	user_hand_label.text = "Hand (%d)" % user_hand_n
	if user_queued_label:
		user_queued_label.text = "Queued (%d)" % user_queue_n
	_rebuild_user_card_tiles()
	if game_state.phase == PHASE_CARD_QUEUE:
		phase_label.text = "Phase: %s (simultaneous queue)" % game_state.phase

	var offense_team := game_state.possession_team
	var defense_team := "away" if offense_team == "home" else "home"
	if game_state.phase == PHASE_PLAY_SELECTION and game_state.pending_play_type == PLAY_NONE():
		phase_label.text = "Phase: play_selection (simultaneous)"

	for team in ["away", "home"]:
		var row := _play_buttons_for_team(team)
		var row_container: Control = row.get("container") as Control
		var row_run: Button = row.get("run") as Button
		var row_short: Button = row.get("short") as Button
		var row_deep: Button = row.get("deep") as Button
		var row_fg: Button = row.get("fg") as Button
		var row_ready: Button = row.get("ready") as Button
		var row_xp: Button = row.get("xp") as Button
		var row_two: Button = row.get("two") as Button

		var is_offense_row: bool = team == offense_team
		var is_defense_row: bool = team == defense_team
		var ai_controls_now: bool = _is_ai_controlled_team(team, true)
		var in_play_selection: bool = game_state.phase == PHASE_PLAY_SELECTION
		var can_choose_play: bool = in_play_selection and (is_offense_row or is_defense_row)

		if row_run:
			row_run.text = "Run Def" if is_defense_row else "Run"
			row_run.disabled = not can_choose_play
		if row_short:
			row_short.text = "Man-to-Man" if is_defense_row else "Short Pass"
			row_short.disabled = not can_choose_play
		if row_deep:
			row_deep.text = "Zone" if is_defense_row else "Deep Pass"
			row_deep.disabled = not can_choose_play
		if row_fg:
			row_fg.text = "FG Def" if is_defense_row else "Field Goal"
			if is_defense_row:
				row_fg.disabled = not can_choose_play
			elif can_choose_play:
				row_fg.disabled = not (current_phase_level >= 2 and _can_attempt_field_goal_from_current_zone())
				if game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT:
					row_fg.disabled = true
			else:
				row_fg.disabled = true

		var row_is_ready: bool = game_state.home_ready if team == "home" else game_state.away_ready
		var can_queue_for_row: bool = game_state.phase == PHASE_CARD_QUEUE and not row_is_ready
		if row_ready:
			if game_state.phase == PHASE_CARD_QUEUE:
				row_ready.text = "Ready" if row_is_ready else "Ready"
				row_ready.disabled = not can_queue_for_row
			else:
				row_ready.text = "Ready"
				row_ready.disabled = true
		if row_xp:
			row_xp.visible = game_state.phase == PHASE_CONVERSION and game_state.conversion_type.is_empty() and team == game_state.conversion_team
		if row_two:
			row_two.visible = game_state.phase == PHASE_CONVERSION and game_state.conversion_type.is_empty() and team == game_state.conversion_team
		if ai_controls_now:
			if row_run:
				row_run.disabled = true
			if row_short:
				row_short.disabled = true
			if row_deep:
				row_deep.disabled = true
			if row_fg:
				row_fg.disabled = true
			if row_ready:
				row_ready.disabled = true
			if row_xp:
				row_xp.disabled = true
			if row_two:
				row_two.disabled = true
	targeting_panel.visible = current_phase_level >= 4
	card_panel.visible = current_phase_level >= 3
	_update_staff_ui()
	_update_field_ball_marker()
	_update_token_visuals()
	_update_sim_ui()
	_maybe_run_ai_inputs(_sim_running)

func _begin_targeted_card(card: Dictionary) -> void:
	_pending_target_card = card
	var context := {
		"my_team_players": player_data.get_team(game_state.possession_team),
		"opponent_players": player_data.get_team("away" if game_state.possession_team == "home" else "home"),
		"staff": {
			"head_coach": _staff_data[game_state.possession_team].get("head_coach", {}),
			"offensive_coordinator": _staff_data[game_state.possession_team].get("off_coord", {}),
			"defensive_coordinator": _staff_data[game_state.possession_team].get("def_coord", {})
		}
	}

	var targets := targeting_manager.get_valid_targets(card, context)
	if targets.is_empty():
		result_text.text = "No valid targets for card."
		return

	for id in _player_tokens.keys():
		_player_tokens[id].set_highlighted(false)

	for t in targets:
		if t.get("type", "") == "player":
			var pid := str(t.get("id", ""))
			if _player_tokens.has(pid):
				_player_tokens[pid].set_highlighted(true)

	game_state.phase = PHASE_TARGETING
	result_text.text = "Select a highlighted target to apply %s." % str(card.get("name", "Card"))

func _on_player_selected(player_id: String) -> void:
	game_state.selected_player_id = player_id
	for id in _player_tokens.keys():
		_player_tokens[id].set_selected(id == player_id)
	_update_player_details(player_id)
	if player_details_panel:
		player_details_panel.visible = true

	if game_state.phase == PHASE_TARGETING and not _pending_target_card.is_empty():
		_apply_targeted_card(player_id)

	_update_ui()

func _update_player_details(player_id: String) -> void:
	if not player_details_label:
		return
	if player_id.is_empty():
		player_details_label.text = "Select a player token to view details."
		return

	var p := player_data.get_by_id(player_id)
	if p.is_empty():
		player_details_label.text = "Player not found: %s" % player_id
		return

	var skills := _player_skills(p)
	var skill_parts: Array[String] = []
	for k in skills.keys():
		skill_parts.append("%s Lv%d" % [str(k), int(skills[k])])
	skill_parts.sort()
	var skills_text := "-" if skill_parts.is_empty() else ", ".join(skill_parts)

	var baseline_keys: Array[String] = [
		"speed", "strength", "awareness", "passing", "catching", "blocking",
		"tackling", "agility", "coverage", "ball_security", "kick_power",
		"kick_accuracy", "kick_consistency", "route_running", "stamina",
		"injury", "toughness"
	]
	var stat_lines: Array[String] = []
	for key in baseline_keys:
		var base := int(p.get(key, 0))
		var eff := _effective_stat(p, key, base)
		if eff != base:
			stat_lines.append("%s: %d (%+d)" % [key, eff, eff - base])
		else:
			stat_lines.append("%s: %d" % [key, base])

	var fumble_force_bonus := _skill_chance_bonus_pct(p, "ball_stripping", "fumble_forced_pct") + _skill_chance_bonus_pct(p, "big_hit", "fumble_forced_pct")
	var int_bonus := _skill_chance_bonus_pct(p, "ball_hawk", "interception_pct")
	var frozen_rope_bonus := float(_skill_level(p, "frozen_rope")) * 1.0

	player_details_label.text = "Name: %s\nTeam: %s\nRole: %s\n\nSkills: %s\n\n%s\n\nDerived:\nFumble Force Bonus: +%.1f%%\nInterception Bonus: +%.1f%%\nFrozen Rope Passing Bonus: +%.1f" % [
		str(p.get("name", player_id)),
		str(p.get("team", "unknown")),
		str(p.get("role", "n/a")),
		skills_text,
		"\n".join(stat_lines),
		fumble_force_bonus,
		int_bonus,
		frozen_rope_bonus
	]

func _append_event_log(message: String) -> void:
	if message.is_empty():
		return
	var ts := _format_time(game_state.game_time_remaining)
	var team_label := _team_display_name(game_state.possession_team)
	_event_log_lines.append("[%s] (%s) %s" % [ts, team_label, message])
	if _event_log_lines.size() > MAX_EVENT_LOG_LINES:
		_event_log_lines = _event_log_lines.slice(_event_log_lines.size() - MAX_EVENT_LOG_LINES, _event_log_lines.size())
	if event_log_text:
		event_log_text.text = "\n".join(_event_log_lines)

func _append_phase_log(message: String, marker: String = "") -> void:
	var line := message
	if marker == "start_game":
		line = "[color=#66ff66][b]START GAME[/b][/color] %s" % message
	elif marker == "start_turn":
		line = "[color=#ffd166][b]START TURN[/b][/color] %s" % message
	elif marker == "end_game":
		line = "[color=#ff6666][b]END GAME[/b][/color] %s" % message
	_phase_log_lines.append(line)
	if _phase_log_lines.size() > MAX_PHASE_LOG_LINES:
		_phase_log_lines = _phase_log_lines.slice(_phase_log_lines.size() - MAX_PHASE_LOG_LINES, _phase_log_lines.size())
	if phase_log_text:
		phase_log_text.bbcode_text = "\n".join(_phase_log_lines)
		phase_log_text.scroll_to_line(max(0, phase_log_text.get_line_count() - 1))

func _phase_context_snapshot() -> String:
	var poss := _team_display_name(game_state.possession_team)
	var zone := _zone_name(game_state.current_zone)
	var gclock := _format_time(game_state.game_time_remaining)
	var pclock := "%d" % int(ceili(_turn_action_time_remaining)) if _turn_action_timer_active else "-"
	var off_play := str(game_state.pending_play_type)
	if off_play == GameState.PENDING_NONE:
		off_play = "-"
	var def_play := str(_selected_defense_play)
	if def_play.is_empty():
		def_play = "-"
	var user_queue_n := game_state.queued_cards_home.size() if _user_team == "home" else game_state.queued_cards_away.size()
	var opp_queue_n := game_state.queued_cards_away.size() if _user_team == "home" else game_state.queued_cards_home.size()
	return "poss=%s | zone=%s | game=%s | play=%ss | off=%s | def=%s | q(U/O)=%d/%d" % [poss, zone, gclock, pclock, off_play, def_play, user_queue_n, opp_queue_n]

func _append_phase_subphase(name: String, details: String = "") -> void:
	var ctx := _phase_context_snapshot()
	var extra := details.strip_edges()
	var message := "  - %s | %s" % [name, ctx]
	if not extra.is_empty():
		message += " | " + extra
	_append_phase_log("[color=#9aa0a6]%s[/color]" % message)

func _reset_next_turn_after_possession_change(reason: String = "") -> void:
	game_state.phase = PHASE_PLAY_SELECTION
	game_state.home_ready = false
	game_state.away_ready = false
	game_state.pending_play_type = GameState.PENDING_NONE
	_selected_defense_play = DEF_ZONE
	_defense_selected_explicit = false
	_awaiting_defense_pick = false
	_play_ready_home = false
	_play_ready_away = false
	_turn_initialized = false
	_append_phase_subphase("change_of_possession", reason)
	_begin_turn_if_needed()
	_update_ui()

func _apply_targeted_card(player_id: String) -> void:
	var card := _pending_target_card
	_pending_target_card = {}

	var r := card_manager.play_non_targeted_card(card, _active_momentum())
	if not bool(r.get("ok", false)):
		result_text.text = str(r.get("reason", "Card failed."))
		return

	_set_active_momentum(_active_momentum() - int(r.get("momentum_cost", 0)))
	_set_active_card_played_this_play(true)

	_active_discard().append(card)
	_active_hand().remove_at(0)

	var effect := {"effect_data": r.get("effect_data", {}), "target_player_id": player_id}
	effect_manager.add_effect(effect, "plays", 1)

	for id in _player_tokens.keys():
		_player_tokens[id].set_highlighted(false)

	game_state.phase = PHASE_PLAY_SELECTION
	result_text.text = "Played %s on %s" % [str(card.get("name", "Card")), player_id]

func _update_staff_ui() -> void:
	var user_team := _user_team
	var opponent_team := "away" if user_team == "home" else "home"
	var user_primary := _team_color(user_team, "primary", DEFAULT_PRIMARY)
	var user_secondary := _team_color(user_team, "secondary", DEFAULT_SECONDARY)
	var user_accent := _team_color(user_team, "accent", DEFAULT_ACCENT)
	if user_team_name_value_label:
		user_team_name_value_label.text = _team_display_name(user_team)
		user_team_name_value_label.add_theme_color_override("font_color", user_primary)
	if user_momentum_value_label:
		user_momentum_value_label.add_theme_color_override("font_color", user_secondary)
	if user_tos_button:
		user_tos_button.add_theme_color_override("font_color", user_secondary)
		user_tos_button.add_theme_color_override("font_hover_color", user_secondary)
		user_tos_button.add_theme_color_override("font_disabled_color", user_accent)

	var opp_primary := _team_color(opponent_team, "primary", DEFAULT_PRIMARY)
	var opp_secondary := _team_color(opponent_team, "secondary", DEFAULT_SECONDARY)
	if opponent_team_name_value_label:
		opponent_team_name_value_label.text = _team_display_name(opponent_team)
		opponent_team_name_value_label.add_theme_color_override("font_color", opp_primary)
	if opponent_momentum_value_label:
		opponent_momentum_value_label.add_theme_color_override("font_color", opp_secondary)
	if opponent_tos_button:
		opponent_tos_button.add_theme_color_override("font_color", opp_secondary)

func _format_time(seconds_total: int) -> String:
	var m := seconds_total / 60
	var s := seconds_total % 60
	return "%d:%02d" % [m, s]

func _update_field_ball_marker() -> void:
	var zone := clampi(game_state.current_zone, 1, 7)
	if game_state.conversion_pending and game_state.phase == PHASE_CONVERSION:
		zone = GameState.ZONE_END
	var field_h: float = field_background.size.y
	var field_w: float = field_background.size.x
	var zone_h: float = field_h / 7.0
	var index_from_bottom: int = zone - 1
	var center_y: float = field_h - (float(index_from_bottom) + 0.5) * zone_h
	if game_state.possession_team != _user_team:
		center_y = field_h - center_y

	ball_marker.position = Vector2(field_w * 0.5 - ball_marker.size.x * 0.5, center_y - ball_marker.size.y * 0.5)

	var is_home := game_state.possession_team == "home"
	ball_marker.color = Color(0.2, 0.5, 1.0, 1.0) if is_home else Color(1.0, 0.3, 0.3, 1.0)
	possession_arrow.text = "▶"
	possession_arrow.modulate = ball_marker.color
	possession_arrow.position = Vector2(ball_marker.position.x - 28.0, ball_marker.position.y + 8.0)

	possession_on_field_label.text = "%s Ball" % _team_display_name(game_state.possession_team)
	possession_on_field_label.modulate = ball_marker.color
	possession_on_field_label.position = Vector2(ball_marker.position.x + ball_marker.size.x + 8.0, ball_marker.position.y + 8.0)

func _update_sim_ui() -> void:
	if sim_status_label:
		sim_status_label.text = "USER AUTO: %s | %.2fx" % ["ON" if _sim_running else "OFF", _sim_speed]
	if start_button:
		start_button.text = "Man" if _sim_running else "Sim"
	if speed_label:
		var shown_speed := str(int(_sim_speed)) if is_equal_approx(_sim_speed, round(_sim_speed)) else str(_sim_speed)
		speed_label.text = "x%s" % shown_speed
	if pause_button:
		pause_button.text = "⏸️" if _clock_running else "▶️"
	_update_sim_stats_ui()

func _on_start_sim_pressed() -> void:
	_sim_running = not _sim_running
	if _sim_running:
		_apply_sim_timer_speed()
		if sim_timer and sim_timer.is_stopped():
			sim_timer.start()
		_maybe_run_ai_inputs(true)
	elif sim_timer:
		sim_timer.stop()
	_update_ui()

func _on_pause_sim_pressed() -> void:
	_clock_running = not _clock_running
	if sim_timer:
		if _sim_running and _clock_running:
			_apply_sim_timer_speed()
			if sim_timer.is_stopped():
				sim_timer.start()
		else:
			sim_timer.stop()
	_update_ui()

func _on_restart_pressed() -> void:
	_sim_running = false
	_clock_running = false
	_clock_accumulator = 0.0
	_awaiting_defense_pick = false
	_selected_defense_play = DEF_ZONE
	_play_ready_home = false
	_play_ready_away = false
	_defense_selected_explicit = false
	_cached_user_hand_sig = ""
	_cached_user_queue_sig = ""
	_turn_action_timer_active = false
	_turn_action_time_remaining = TURN_ACTION_LIMIT_SECONDS
	_turn_action_timeout_handled = false
	_turn_timed_out_home = false
	_turn_timed_out_away = false
	_manual_ready_pressed_home = false
	_manual_ready_pressed_away = false
	_ready_miss_streak_home = 0
	_ready_miss_streak_away = 0
	_clock_paused_for_ready_wait = false
	_clock_running_before_ready_wait = false
	_abandoned_game = false
	_phase_log_lines.clear()
	_phase_log_end_recorded = false
	_turn_counter = 0
	if sim_timer:
		sim_timer.stop()
	game_state.start_game()
	_begin_new_game_stats()
	_assign_user_team_random()
	_load_data()
	_turn_initialized = false
	_begin_turn_if_needed()
	if not _turn_action_timer_active:
		_start_turn_action_timer()
	_append_phase_log("User=%s (%s), Opponent=%s" % [_team_display_name(_user_team), _user_team.capitalize(), _team_display_name("away" if _user_team == "home" else "home")], "start_game")
	result_text.text = "Ready."
	_update_ui()

func _on_reset_stats_pressed() -> void:
	_stats_games = 0
	_stats_home_wins = 0
	_stats_away_wins = 0
	_stats_ties = 0
	_stats_total_home_points = 0
	_stats_total_away_points = 0
	_stats_total_drives = 0
	_stats_total_plays = 0
	_stats_total_tds = 0
	_stats_total_fg_attempts = 0
	_stats_total_fg_makes = 0
	_stats_total_home_possessions = 0
	_stats_total_away_possessions = 0
	_update_ui()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_user_forfeit_pressed() -> void:
	_apply_forfeit(_user_team, "forfeit_button")

func _on_speed_up_pressed() -> void:
	_sim_speed = minf(_sim_speed + 1.0, 10.0)
	_apply_sim_timer_speed()
	_update_ui()

func _on_speed_down_pressed() -> void:
	_sim_speed = maxf(_sim_speed - 0.5, 0.5)
	_apply_sim_timer_speed()
	_update_ui()

func _apply_sim_timer_speed() -> void:
	if not sim_timer:
		return
	sim_timer.wait_time = 1.0 / _sim_speed
	if _sim_running and sim_timer.is_stopped():
		sim_timer.start()

func _on_sim_tick() -> void:
	if not _sim_running:
		return
	if game_state.phase == GameState.PHASE_GAME_OVER:
		_on_pause_sim_pressed()
		return
	if _maybe_sim_call_timeouts():
		return
	_maybe_run_ai_inputs(true)

func _pick_sim_defense_play_for_offense(offense_play: String) -> String:
	if offense_play == PLAY_RUN:
		return PLAY_RUN
	if offense_play == PLAY_SHORT_PASS or offense_play == PLAY_DEEP_PASS:
		return PLAY_SHORT_PASS
	if offense_play == PLAY_FIELD_GOAL:
		return PLAY_FIELD_GOAL
	return PLAY_DEEP_PASS

func _pick_sim_play_type() -> String:
	if game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT:
		var roll2 := randf()
		if roll2 < 0.5:
			return PLAY_RUN
		if roll2 < 0.85:
			return PLAY_SHORT_PASS
		return PLAY_DEEP_PASS
	if current_phase_level >= 2 and _can_attempt_field_goal_from_current_zone() and randf() < 0.2:
		return PLAY_FIELD_GOAL
	var roll := randf()
	if roll < 0.45:
		return PLAY_RUN
	if roll < 0.8:
		return PLAY_SHORT_PASS
	return PLAY_DEEP_PASS

func _auto_queue_for_team(team: String, max_cards: int) -> void:
	var queued := 0
	while max_cards < 0 or queued < max_cards:
		var hand: Array = _hand_for_team(team)
		if hand.is_empty():
			return
		if not _queue_card_for_team(team, {}, {}, 0):
			return
		queued += 1

func _sim_pick_conversion() -> String:
	var team := game_state.conversion_team
	var team_score := game_state.score_home if team == "home" else game_state.score_away
	var opp_score := game_state.score_away if team == "home" else game_state.score_home
	var diff := team_score - opp_score
	return CONVERSION_2PT if SIM_2PT_DIFFS.has(diff) else CONVERSION_XP

func _begin_post_td_conversion(team: String) -> void:
	game_state.phase = PHASE_CONVERSION
	game_state.conversion_type = ""
	game_state.possession_team = team
	_append_phase_subphase("conversion_choice")
	_stop_clock("conversion")
	if _sim_running:
		_choose_conversion(_sim_pick_conversion())
	else:
		result_text.text = "[b]Touchdown![/b]\nChoose conversion: Extra Point or 2-Point."
		_append_event_log("Touchdown scored. Awaiting conversion choice.")

func _choose_conversion(conv_type: String) -> void:
	if game_state.phase != PHASE_CONVERSION:
		return
	if not game_state.conversion_type.is_empty():
		return
	game_state.conversion_type = conv_type
	game_state.possession_team = game_state.conversion_team
	_append_phase_subphase("conversion_attempt", "type=%s" % conv_type)
	if conv_type == CONVERSION_XP:
		_append_event_log("Extra Point attempt from %s." % _zone_name(GameState.ZONE_ATTACK))
		_run_extra_point_attempt()
		return
	game_state.current_zone = GameState.ZONE_RED
	game_state.drive_points = 1
	game_state.pending_play_type = PENDING_NONE()
	result_text.text = "[b]2-Point Conversion[/b]\nSelect Run or Pass play."
	_append_event_log("2-Point attempt from %s." % _zone_name(GameState.ZONE_RED))
	_update_ui()

func _run_extra_point_attempt() -> void:
	var team := game_state.conversion_team
	var kicker := player_data.get_best_kicker(team)
	var kicker_id := str(kicker.get("id", ""))
	var staff_bonus := int(_staff_data[team]["head_coach"].get("bonus", {}).get("field_goal_bonus", 0))
	var xp_result := play_resolver.resolve_extra_point(kicker_id, kicker, _opponent_flat_def_mod - staff_bonus)
	if bool(xp_result.get("success", false)):
		game_state.add_score(team, 1)
		result_text.text = "[center][color=#66ff66][b]EXTRA POINT GOOD[/b][/color][/center]"
		_append_event_log("[b]Extra Point GOOD[/b]")
		_finish_conversion("extra_point_made", true)
	else:
		result_text.text = "[center][color=#ff6666][b]EXTRA POINT MISSED[/b][/color][/center]"
		_append_event_log("[b]Extra Point MISSED[/b]")
		_finish_conversion("extra_point_missed", false)
	game_state.emit_signal("state_changed")

func _finish_conversion(ended_by: String, made: bool) -> void:
	var _unused := made
	var scoring_team := game_state.possession_team
	game_state.conversion_pending = false
	game_state.phase = PHASE_PLAY_SELECTION
	game_state.conversion_type = ""
	game_state.conversion_team = ""
	game_state.next_drive_start_zone = _map_possession_start_zone(GameState.ZONE_END)
	var next_team := "away" if scoring_team == "home" else "home"
	game_state.start_possession(next_team, game_state.next_drive_start_zone)
	_append_event_log("[color=#4da3ff][b]CHANGE OF POSSESSION[/b][/color]")
	_append_event_log("Kickoff: %s starts in %s." % [next_team.capitalize(), _zone_name(game_state.next_drive_start_zone)])
	_reset_next_turn_after_possession_change("conversion:%s" % ended_by)

func PENDING_NONE() -> String:
	return GameState.PENDING_NONE

func _begin_new_game_stats() -> void:
	_game_plays = 0
	_game_tds = 0
	_game_fg_attempts = 0
	_game_fg_makes = 0
	_stats_recorded_for_current_game = false

func _maybe_finalize_game_stats() -> void:
	if _stats_recorded_for_current_game:
		return
	if game_state.phase != GameState.PHASE_GAME_OVER:
		return
	if not _phase_log_end_recorded:
		_append_phase_log("Final: %s %d - %s %d (%s)" % [_team_display_name("home"), game_state.score_home, _team_display_name("away"), game_state.score_away, game_state.game_result], "end_game")
		_phase_log_end_recorded = true
	if _abandoned_game:
		_stats_recorded_for_current_game = true
		return

	_stats_games += 1
	if game_state.game_result == "home_win":
		_stats_home_wins += 1
	elif game_state.game_result == "away_win":
		_stats_away_wins += 1
	else:
		_stats_ties += 1

	_stats_total_home_points += game_state.score_home
	_stats_total_away_points += game_state.score_away
	_stats_total_drives += game_state.drive_summaries.size()
	_stats_total_plays += _game_plays
	_stats_total_tds += _game_tds
	_stats_total_fg_attempts += _game_fg_attempts
	_stats_total_fg_makes += _game_fg_makes
	_stats_total_home_possessions += game_state.home_possessions
	_stats_total_away_possessions += game_state.away_possessions
	_stats_recorded_for_current_game = true

func _update_sim_stats_ui() -> void:
	if not sim_stats_label:
		return
	if _stats_games <= 0:
		sim_stats_label.text = "N=0 | H:0 A:0 T:0"
		return

	var games := float(_stats_games)
	var avg_home := float(_stats_total_home_points) / games
	var avg_away := float(_stats_total_away_points) / games
	var avg_total := avg_home + avg_away
	var avg_drives := float(_stats_total_drives) / games
	var avg_plays_per_drive := float(_stats_total_plays) / maxf(float(_stats_total_drives), 1.0)
	var td_rate := (float(_stats_total_tds) / maxf(float(_stats_total_plays), 1.0)) * 100.0
	var fg_attempt_rate := (float(_stats_total_fg_attempts) / maxf(float(_stats_total_plays), 1.0)) * 100.0
	var fg_make_rate := (float(_stats_total_fg_makes) / maxf(float(_stats_total_fg_attempts), 1.0)) * 100.0
	var avg_home_poss := float(_stats_total_home_possessions) / games
	var avg_away_poss := float(_stats_total_away_possessions) / games

	sim_stats_label.text = "N=%d H:%d A:%d T:%d | AvgPts H:%.1f A:%.1f Tot:%.1f | Drives:%.1f Plays/Drive:%.2f | TD%%:%.1f FG Att%%:%.1f FG Make%%:%.1f | Poss H:%.1f A:%.1f" % [
		_stats_games, _stats_home_wins, _stats_away_wins, _stats_ties,
		avg_home, avg_away, avg_total,
		avg_drives, avg_plays_per_drive,
		td_rate, fg_attempt_rate, fg_make_rate,
		avg_home_poss, avg_away_poss
	]

func _active_team() -> String:
	return game_state.possession_team

func _active_hand() -> Array:
	return game_state.hand_home if _active_team() == "home" else game_state.hand_away

func _active_deck() -> Array:
	return game_state.deck_home if _active_team() == "home" else game_state.deck_away

func _active_discard() -> Array:
	return game_state.discard_home if _active_team() == "home" else game_state.discard_away

func _active_momentum() -> int:
	return game_state.momentum_home if _active_team() == "home" else game_state.momentum_away

func _set_active_momentum(value: int) -> void:
	if _active_team() == "home":
		game_state.momentum_home = value
	else:
		game_state.momentum_away = value

func _active_card_played_this_play() -> bool:
	return game_state.card_played_this_play_home if _active_team() == "home" else game_state.card_played_this_play_away

func _set_active_card_played_this_play(value: bool) -> void:
	if _active_team() == "home":
		game_state.card_played_this_play_home = value
	else:
		game_state.card_played_this_play_away = value

func PLAY_NONE() -> String:
	return GameState.PENDING_NONE

# --- Add to game_scene.gd ---

func _start_card_queue_phase() -> void:
	game_state.phase = PHASE_CARD_QUEUE
	_queue_team = game_state.possession_team
	_append_phase_subphase("card_queue")

	# reset queues/readiness each play
	game_state.queued_cards_home = []
	game_state.queued_cards_away = []
	game_state.queued_momentum_spent_home = 0
	game_state.queued_momentum_spent_away = 0
	game_state.home_ready = false
	game_state.away_ready = false

	_update_ui()


func _queue_first_affordable_hand_card(team: String) -> bool:
	var hand := _hand_for_team(team)
	var momentum: int = game_state.momentum_home if team == "home" else game_state.momentum_away
	var queued_spent: int = game_state.queued_momentum_spent_home if team == "home" else game_state.queued_momentum_spent_away
	var remaining: int = momentum - queued_spent
	for i in range(hand.size()):
		var c = hand[i]
		if typeof(c) != TYPE_DICTIONARY:
			continue
		if int((c as Dictionary).get("cost", 0)) <= remaining:
			return _queue_card_for_team(team, {}, {}, i)
	return false


func _queue_card_for_team(team: String, card: Dictionary = {}, target := {}, hand_index: int = -1) -> bool:
	var hand: Array = game_state.hand_home if team == "home" else game_state.hand_away
	var card_to_queue: Dictionary = {}
	if hand_index >= 0:
		if hand_index >= hand.size():
			return false
		var hc = hand[hand_index]
		if typeof(hc) != TYPE_DICTIONARY:
			return false
		card_to_queue = hc
	else:
		card_to_queue = card
	if card_to_queue.is_empty():
		return false

	var cost: int = int(card_to_queue.get("cost", 0))

	var momentum: int = game_state.momentum_home if team == "home" else game_state.momentum_away
	var queued_spent: int = game_state.queued_momentum_spent_home if team == "home" else game_state.queued_momentum_spent_away
	var remaining: int = momentum - queued_spent

	if cost > remaining:
		return false

	var entry: Dictionary = {
		"team": team,
		"card": card_to_queue,
		"target": target,
		"cost": cost
	}

	if team == "home":
		game_state.queued_cards_home.append(entry)
		game_state.queued_momentum_spent_home += cost
	else:
		game_state.queued_cards_away.append(entry)
		game_state.queued_momentum_spent_away += cost

	if hand_index >= 0:
		hand.remove_at(hand_index)
	else:
		_remove_card_from_team_hand_by_id(team, str(card_to_queue.get("id", "")))

	_update_ui()
	return true


func try_queue_hand_card_from_drag_data(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var team := str(data.get("team", ""))
	var idx := int(data.get("index", -1))
	_try_queue_hand_card_at_index(team, idx, false)


func _on_queued_card_tile_unqueue_requested(team: String, queue_index: int) -> void:
	_unqueue_card_at_index(team, queue_index)


func _unqueue_card_at_index(team: String, queue_index: int) -> void:
	if game_state.phase != PHASE_CARD_QUEUE:
		return
	if _is_ai_controlled_team(team, false):
		return
	if (team == "home" and game_state.home_ready) or (team == "away" and game_state.away_ready):
		return
	var q: Array = game_state.queued_cards_home if team == "home" else game_state.queued_cards_away
	if queue_index < 0 or queue_index >= q.size():
		return
	var entry: Dictionary = q[queue_index]
	var cost := int(entry.get("cost", 0))
	var card: Dictionary = entry.get("card", {})
	q.remove_at(queue_index)
	if team == "home":
		game_state.queued_momentum_spent_home = maxi(0, game_state.queued_momentum_spent_home - cost)
		game_state.hand_home.insert(0, card.duplicate(true))
	else:
		game_state.queued_momentum_spent_away = maxi(0, game_state.queued_momentum_spent_away - cost)
		game_state.hand_away.insert(0, card.duplicate(true))
	result_text.text = "Returned %s to hand." % str(card.get("name", "Card"))
	_append_event_log("Returned %s to hand." % str(card.get("name", "Card")))
	_update_ui()


func _on_hand_card_tile_queue_requested(team: String, hand_index: int) -> void:
	_try_queue_hand_card_at_index(team, hand_index, false)


func _try_queue_hand_card_at_index(team: String, hand_index: int, allow_ai: bool = false) -> void:
	if not allow_ai and _is_ai_controlled_team(team, false):
		return
	if game_state.phase != PHASE_CARD_QUEUE:
		return
	if (team == "home" and game_state.home_ready) or (team == "away" and game_state.away_ready):
		return
	var hand := _hand_for_team(team)
	if hand_index < 0 or hand_index >= hand.size():
		return
	if not _queue_card_for_team(team, {}, {}, hand_index):
		result_text.text = "Not enough Momentum to queue that card."
		_append_event_log("Not enough Momentum to queue that card.")
		return
	var qc: Dictionary = (game_state.queued_cards_home[-1] if team == "home" else game_state.queued_cards_away[-1]).get("card", {})
	result_text.text = "Queued card (%s): %s" % [team, str(qc.get("name", "Card"))]
	_append_event_log("Queued card (%s): %s" % [team, str(qc.get("name", "Card"))])


func _set_team_ready(team: String, ready: bool) -> void:
	if team == "home":
		game_state.home_ready = ready
	else:
		game_state.away_ready = ready

	if game_state.phase == PHASE_CARD_QUEUE and ready:
		var offense := game_state.possession_team
		var defense := "away" if offense == "home" else "home"
		var offense_ready := _team_is_ready(offense)
		var defense_ready := _team_is_ready(defense)
		if team == offense and offense_ready and not defense_ready and not _clock_paused_for_ready_wait:
			_clock_running_before_ready_wait = _clock_running
			if _clock_running:
				_clock_running = false
			_clock_paused_for_ready_wait = true
		elif team == defense and offense_ready and defense_ready and _clock_paused_for_ready_wait:
			if _clock_running_before_ready_wait:
				_clock_running = true
			_clock_paused_for_ready_wait = false
			_clock_running_before_ready_wait = false

	_update_ui()

	if game_state.home_ready and game_state.away_ready:
		if _clock_paused_for_ready_wait:
			if _clock_running_before_ready_wait:
				_clock_running = true
			_clock_paused_for_ready_wait = false
			_clock_running_before_ready_wait = false
		_resume_clock_for_play()
		_finalize_user_ready_activity_for_turn()
		if game_state.phase == GameState.PHASE_GAME_OVER:
			return
		_stop_turn_action_timer()
		_execute_queued_cards_in_order()

func _on_ready_pressed(team: String = "") -> void:
	if team.is_empty():
		return
	if game_state.phase == PHASE_CARD_QUEUE:
		_set_team_ready(team, true)
		return
	return


func _execute_queued_cards_in_order() -> void:
	_resolved_cards_home = []
	_resolved_cards_away = []
	_resolved_effects_home = []
	_resolved_effects_away = []
	var offense := game_state.possession_team
	var defense := "away" if offense == "home" else "home"

	var q_offense: Array = game_state.queued_cards_home if offense == "home" else game_state.queued_cards_away
	var q_defense: Array = game_state.queued_cards_home if defense == "home" else game_state.queued_cards_away

	var i := 0
	var max_len := maxi(q_offense.size(), q_defense.size())

	while i < max_len:
		if i < q_offense.size():
			_execute_queued_card(q_offense[i])
		if i < q_defense.size():
			_execute_queued_card(q_defense[i])
		i += 1

	# clear queue state after execution
	game_state.queued_cards_home = []
	game_state.queued_cards_away = []
	game_state.queued_momentum_spent_home = 0
	game_state.queued_momentum_spent_away = 0
	game_state.home_ready = false
	game_state.away_ready = false

	# continue normal play flow
	if game_state.pending_play_type != PLAY_NONE():
		_resolve_play()
	else:
		game_state.phase = PHASE_PLAY_SELECTION
		_update_ui()


func _execute_queued_card(entry: Dictionary) -> void:
	var team := str(entry.get("team", "home"))
	var card: Dictionary = entry.get("card", {})
	var cost := int(entry.get("cost", 0))

	if team == "home":
		game_state.momentum_home = max(game_state.momentum_home - cost, 0)
		game_state.discard_home.append(card)
		_resolved_cards_home.append(str(card.get("name", "Card")))
	else:
		game_state.momentum_away = max(game_state.momentum_away - cost, 0)
		game_state.discard_away.append(card)
		_resolved_cards_away.append(str(card.get("name", "Card")))

	effect_manager.add_effect({
		"effect_data": card.get("effect_data", {}),
		"queued_team": team
	}, "plays", 1)
	var effect_text := _friendly_effects_text(card.get("effect_data", {}))
	if not effect_text.is_empty():
		if team == "home":
			_resolved_effects_home.append(effect_text)
		else:
			_resolved_effects_away.append(effect_text)


func _remove_card_from_team_hand_by_id(team: String, card_id: String) -> bool:
	var hand: Array = game_state.hand_home if team == "home" else game_state.hand_away
	for idx in range(hand.size()):
		var c: Dictionary = hand[idx]
		if str(c.get("id", "")) == card_id:
			hand.remove_at(idx)
			if team == "home":
				game_state.hand_home = hand
			else:
				game_state.hand_away = hand
			return true
	return false

func _hand_for_team(team: String) -> Array:
	return game_state.hand_home if team == "home" else game_state.hand_away


func _clear_card_strip_children(container: Node) -> void:
	for c in container.get_children():
		c.queue_free()


func _hand_visual_signature(hand: Array) -> String:
	var parts: Array[String] = []
	for item in hand:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d := item as Dictionary
		parts.append("%s:%d" % [str(d.get("id", "")), int(d.get("cost", 0))])
	return "|".join(parts)


func _queue_visual_signature(entries: Array) -> String:
	var parts: Array[String] = []
	for item in entries:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var cd: Dictionary = (item as Dictionary).get("card", {})
		parts.append("%s:%d" % [str(cd.get("id", "")), int(cd.get("cost", 0))])
	return "|".join(parts)


func _rebuild_user_card_tiles() -> void:
	var show_strips := current_phase_level >= 3

	if user_hand_cards:
		var hand_scroll := user_hand_cards.get_parent()
		if hand_scroll:
			hand_scroll.visible = show_strips
	if user_queued_cards:
		var queued_scroll := user_queued_cards.get_parent()
		if queued_scroll:
			queued_scroll.visible = show_strips
	if user_queued_label:
		user_queued_label.visible = show_strips

	if not show_strips:
		return

	var hand: Array = _hand_for_team(_user_team)
	var queue: Array = game_state.queued_cards_home if _user_team == "home" else game_state.queued_cards_away
	var hs := _hand_visual_signature(hand)
	var qs := _queue_visual_signature(queue)
	if hs == _cached_user_hand_sig and qs == _cached_user_queue_sig:
		return
	_cached_user_hand_sig = hs
	_cached_user_queue_sig = qs

	if user_hand_cards:
		_clear_card_strip_children(user_hand_cards)
	if user_queued_cards:
		_clear_card_strip_children(user_queued_cards)
		user_queued_cards.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if user_hand_cards:
		for i in range(hand.size()):
			var card = hand[i]
			if typeof(card) != TYPE_DICTIONARY:
				continue
			var tile := CARD_TILE_SCENE.instantiate()
			user_hand_cards.add_child(tile)
			if tile.has_method("setup"):
				tile.setup(card as Dictionary)
			if tile.has_signal("queue_requested"):
				tile.configure_hand_interaction(true, _user_team, i)
				tile.queue_requested.connect(_on_hand_card_tile_queue_requested)

	if user_queued_cards:
		var user_ready := game_state.home_ready if _user_team == "home" else game_state.away_ready
		var allow_unqueue: bool = game_state.phase == PHASE_CARD_QUEUE and not _sim_running and not user_ready
		for qi in range(queue.size()):
			var entry = queue[qi]
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var cd: Dictionary = (entry as Dictionary).get("card", {})
			if cd.is_empty():
				continue
			var qtile := CARD_TILE_SCENE.instantiate()
			user_queued_cards.add_child(qtile)
			if qtile.has_method("setup"):
				qtile.setup(cd)
			if qtile.has_method("configure_queued_interaction"):
				qtile.configure_queued_interaction(allow_unqueue, _user_team, qi)
			if allow_unqueue and qtile.has_signal("unqueue_requested"):
				qtile.unqueue_requested.connect(_on_queued_card_tile_unqueue_requested)

func _friendly_play_name(play: String, is_defense: bool = false) -> String:
	if is_defense:
		match play:
			DEF_RUN:
				return "Run Def"
			DEF_MAN:
				return "Man-to-Man"
			DEF_ZONE:
				return "Zone"
			DEF_FG:
				return "FG Def"
			_:
				return "-"
	match play:
		PLAY_RUN:
			return "Run"
		PLAY_SHORT_PASS:
			return "Short Pass"
		PLAY_DEEP_PASS:
			return "Deep Pass"
		PLAY_FIELD_GOAL:
			return "Field Goal"
		_:
			return "-"

func _friendly_effects_text(effect_data: Dictionary) -> String:
	if effect_data.is_empty():
		return ""
	var parts: Array[String] = []
	for key in effect_data.keys():
		var k := str(key)
		var v: Variant = effect_data[key]
		match k:
			"zone_bonus":
				parts.append("Zone %+d" % int(v))
			"defense_penalty":
				parts.append("Defense %+d" % int(v))
			"field_goal_bonus":
				parts.append("FG %+d" % int(v))
			_:
				parts.append("%s %s" % [k, str(v)])
	return ", ".join(parts)

func _render_last_play_info(offense_team: String, offense_play: String, defense_play: String, result_line: String, zone_delta: int) -> void:
	var opponent_team := "away" if _user_team == "home" else "home"
	var user_play := _friendly_play_name(offense_play, false) if offense_team == _user_team else _friendly_play_name(defense_play, true)
	var opponent_play := _friendly_play_name(offense_play, false) if offense_team == opponent_team else _friendly_play_name(defense_play, true)
	var user_cards := _resolved_cards_home if _user_team == "home" else _resolved_cards_away
	var opponent_cards := _resolved_cards_away if _user_team == "home" else _resolved_cards_home
	var user_effects := _resolved_effects_home if _user_team == "home" else _resolved_effects_away
	var opponent_effects := _resolved_effects_away if _user_team == "home" else _resolved_effects_home
	var user_cards_txt := "-" if user_cards.is_empty() else ", ".join(user_cards)
	var opponent_cards_txt := "-" if opponent_cards.is_empty() else ", ".join(opponent_cards)
	var user_effects_txt := "-" if user_effects.is_empty() else "; ".join(user_effects)
	var opponent_effects_txt := "-" if opponent_effects.is_empty() else "; ".join(opponent_effects)
	var zone_txt := "Zone Gain/Loss: %+d" % zone_delta
	result_text.text = "[b]Opponent Play Selected:[/b] %s\n[b]Opponent Played Cards:[/b] %s\n[b]Opponent Card Effects:[/b] %s\n\n[b]User Play Selected:[/b] %s\n[b]User Played Cards:[/b] %s\n[b]User Card Effects:[/b] %s\n\n[b]Play Result:[/b] %s\n[b]%s[/b]" % [
		opponent_play, opponent_cards_txt, opponent_effects_txt,
		user_play, user_cards_txt, user_effects_txt,
		result_line, zone_txt
	]

func _format_hand_names(hand: Array) -> String:
	if hand.is_empty():
		return "-"
	var names: Array[String] = []
	for card in hand:
		if typeof(card) == TYPE_DICTIONARY:
			names.append(str(card.get("name", "Card")))
	return ", ".join(names)

func _format_queued_card_names(queue_entries: Array) -> String:
	if queue_entries.is_empty():
		return "-"
	var names: Array[String] = []
	for entry in queue_entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = entry.get("card", {})
		names.append(str(card.get("name", "Card")))
	return ", ".join(names)
