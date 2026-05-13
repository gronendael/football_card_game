extends Control

const PHASE_PLAY_SELECTION := "play_selection"
const PHASE_RESOLVING := "resolving"
const PHASE_CARD_SELECTION := "card_selection"
const PHASE_TARGETING := "targeting"
const PHASE_CARD_QUEUE := "card_queue"
const BUCKET_RUN := "run"
const BUCKET_PASS := "pass"
const BUCKET_SPOT_KICK := "spot_kick"
const BUCKET_PUNT := "punt"
const BUCKET_RUN_DEF := "run_def"
const BUCKET_PASS_DEF := "pass_def"
const BUCKET_FG_XP_DEF := "fg_xp_def"
const BUCKET_PUNT_RETURN := "punt_return"
const BUCKET_KICKOFF := "kickoff"
const BUCKET_KICKOFF_RETURN := "kickoff_return"
const PHASE_CONVERSION := "conversion"
const CONVERSION_XP := "xp"
const CONVERSION_2PT := "2pt"
const SIM_2PT_DIFFS := [-2, -5, -8, -10, 1, 5, 12]
const CLOCK_BASE_RATE := 2.0
const SAME_BUCKET_DEFENSE_EXTRA := 3
const FORMATION_TOOL_SCENE := preload("res://scenes/formation_tool.tscn")

const CALC_LOG_CAT_RESOLVER := "resolver"
const CALC_LOG_CAT_POST := "post"
const CALC_LOG_CAT_OUTCOME := "outcome"
const CALC_LOG_CAT_TURNOVER := "turnover"
const CALC_LOG_CAT_CARDS := "cards"
const CALC_LOG_CAT_SKILLS := "skills"
const CALC_LOG_CAT_SPECIAL := "special"
const CALC_LOG_CAT_CONVERSION := "conversion"
const CALC_LOG_PLACEHOLDER := "No matching lines for the current filters (or this step has no extra detail in the prototype)."

const PREVIEW_MARKER_SIZE := Vector2(26, 26)
const PREVIEW_MARKER_FONT := 9

const CARD_TILE_SCENE := preload("res://scenes/card_tile.tscn")
const PLAY_PICK_CARD_SCENE := preload("res://scenes/play_pick_card.tscn")

@onready var game_state: GameState = $GameManagers/GameState
@onready var play_resolver: PlayResolver = $GameManagers/PlayResolver
@onready var card_manager: CardManager = $GameManagers/CardManager
@onready var effect_manager: EffectManager = $GameManagers/EffectManager
@onready var targeting_manager: TargetingManager = $GameManagers/TargetingManager
@onready var player_data: PlayerData = $GameManagers/PlayerData
@onready var coach_data: CoachData = $GameManagers/CoachData
@onready var team_data: TeamData = $GameManagers/TeamData

@onready var game_clock_value_label: Label = get_node_or_null("UserGroup/UserHUD/UserTeamsScoresPanel/ClockPanel/GameClockValueLabel") as Label
@onready var play_clock_value_label: Label = get_node_or_null("UserGroup/UserHUD/UserTeamsScoresPanel/ClockPanel/PlayClockValueLabel") as Label
@onready var action_timer_progress_bar: ProgressBar = get_node_or_null("UserGroup/UserHUD/UserTeamsScoresPanel/ClockPanel/ActionTimerProgressBar") as ProgressBar
@onready var half_label: Label = $HUDGroup/GlobalHUD/HalfLabel
@onready var zone_label: Label = $HUDGroup/GlobalHUD/ZoneLabel
@onready var downs_label: Label = $HUDGroup/GlobalHUD/DownsLabel
@onready var play_count_label: Label = get_node_or_null("HUDGroup/GlobalHUD/PlayCountLabel") as Label
@onready var phase_label: Label = $HUDGroup/GlobalHUD/PhaseLabel
@onready var result_text: RichTextLabel = $HUDGroup/PlayInfoHUD/ResultText
@onready var opponent_momentum_value_label: Label = get_node_or_null("OpponentGroup/OpponentHUD/OpponentMomentumValueLabel") as Label
@onready var opponent_hand_label: Label = $OpponentGroup/OpponentHUD/OpponentHandPanel/OpponentHandLabel
@onready var opponent_team_name_value_label: Label = %"OpponentTeamNameValueLabel"
@onready var opponent_possession_icon_label: Label = %"OpponentPossessionHudIcon"
@onready var opponent_score_value_label: Label = $UserGroup/UserHUD/UserTeamsScoresPanel/OpponentTeamMargin/OpponentTeamColumn/OpponentTeamRow/OpponentScoreValueLabel
@onready var opponent_tos_button: Button = get_node_or_null("OpponentGroup/OpponentHUD/OpponentTimeoutsPanel/OpponentTOsPanel") as Button
@onready var opponent_hud: Control = get_node_or_null("OpponentGroup/OpponentHUD") as Control
@onready var user_momentum_value_label: Label = get_node_or_null("UserGroup/UserHUD/UserBottomUIPanel/UserMomentumValueLabel") as Label
@onready var user_hand_label: Label = $UserGroup/UserHUD/UserHandPanel/UserHandLabel
@onready var user_hand_cards: HBoxContainer = get_node_or_null("UserGroup/UserHUD/UserHandPanel/UserHandScroll/UserHandCards") as HBoxContainer
@onready var user_queued_label: Label = get_node_or_null("UserGroup/UserHUD/UserQueuedPanel/UserQueuedLabel") as Label
@onready var user_queued_cards: HBoxContainer = get_node_or_null("UserGroup/UserHUD/UserQueuedPanel/UserQueuedScroll/UserQueuedCards") as HBoxContainer
@onready var user_team_name_value_label: Label = %"UserTeamNameValueLabel"
@onready var user_possession_icon_label: Label = %"UserPossessionHudIcon"
@onready var user_score_value_label: Label = $UserGroup/UserHUD/UserTeamsScoresPanel/UserTeamMargin/UserTeamColumn/UserTeamRow/UserScoreValueLabel
@onready var user_down_distance_label: Label = get_node_or_null("UserGroup/UserHUD/UserDownDistanceLabel") as Label
@onready var user_tos_button: Button = get_node_or_null("UserGroup/UserHUD/UserBottomUIPanel/UserTimeoutButton") as Button
@onready var user_forfeit_button: Button = get_node_or_null("UserGroup/UserHUD/UserBottomUIPanel/UserForfeitButton") as Button
@onready var user_hud: Control = get_node_or_null("UserGroup/UserHUD") as Control
@onready var field_grid: Node = get_node_or_null("Field")
@onready var field_background: ColorRect = $Field/FieldBackground
@onready var ball_chip: Label = get_node_or_null("Field/BallChip") as Label
@onready var player_details_panel: Control = get_node_or_null("PlayerDetailsPanel") as Control
@onready var player_details_label: Label = get_node_or_null("PlayerDetailsPanel/PlayerDetailsLabel") as Label
@onready var event_log_text: RichTextLabel = get_node_or_null("HUDGroup/EventLogPanel/EventLogText") as RichTextLabel
@onready var phase_log_text: RichTextLabel = get_node_or_null("HUDGroup/PhaseLogPanel/PhaseLogText") as RichTextLabel
@onready var sim_status_label: Label = get_node_or_null("HUDGroup/GlobalHUD/SimStatusLabel") as Label
@onready var sim_stats_label: Label = get_node_or_null("HUDGroup/GlobalHUD/SimStatsLabel") as Label
@onready var user_team_label: Label = get_node_or_null("HUDGroup/GlobalHUD/UserTeamLabel") as Label
@onready var quit_button: Button = (get_node_or_null("TopRightBar/QuitButton") as Button) if get_node_or_null("TopRightBar/QuitButton") != null else ((get_node_or_null("QuitButton") as Button) if get_node_or_null("QuitButton") != null else (get_node_or_null("HUDGroup/GlobalHUD/QuitButton") as Button))
@onready var tools_menu_button: MenuButton = get_node_or_null("TopRightBar/ToolsMenuButton") as MenuButton
@onready var speed_label: Label = (get_node_or_null("HUDGroup/SpeedPanel/SpeedLabel") as Label) if get_node_or_null("HUDGroup/SpeedPanel/SpeedLabel") != null else (get_node_or_null("HUDGroup/SimButtons/SpeedLabel") as Label)

@onready var opponent_play_buttons: Control = get_node_or_null("OpponentGroup/OpponentHUD/OpponentPlayButtons") as Control
@onready var opponent_run_button: Button = get_node_or_null("OpponentGroup/OpponentHUD/OpponentPlayButtons/OpponentRunButton") as Button
@onready var opponent_pass_button: Button = get_node_or_null("OpponentGroup/OpponentHUD/OpponentPlayButtons/OpponentPassButton") as Button
@onready var opponent_field_goal_button: Button = get_node_or_null("OpponentGroup/OpponentHUD/OpponentPlayButtons/OpponentFieldGoalButton") as Button
@onready var opponent_punt_button: Button = get_node_or_null("OpponentGroup/OpponentHUD/OpponentPlayButtons/OpponentPuntButton") as Button
@onready var opponent_ready_button: Button = get_node_or_null("OpponentGroup/OpponentHUD/OpponentPlayButtons/OpponentReadyButton") as Button
@onready var opponent_extra_point_button: Button = get_node_or_null("OpponentGroup/OpponentHUD/OpponentPlayButtons/OpponentExtraPointButton") as Button
@onready var opponent_two_point_button: Button = get_node_or_null("OpponentGroup/OpponentHUD/OpponentPlayButtons/OpponentTwoPointButton") as Button

@onready var user_play_buttons: Control = get_node_or_null("UserGroup/UserHUD/UserPlayButtonsRow/UserPlayButtons") as Control
@onready var user_play_row_possession_icon: Label = %"UserPlayRowPossessionIcon"
@onready var user_phase_prompt_panel: MarginContainer = %"UserPhasePromptPanel"
@onready var user_phase_prompt_label: Label = %"UserPhasePromptLabel"
@onready var user_run_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtonsRow/UserPlayButtons/UserRunButton") as Button
@onready var user_pass_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtonsRow/UserPlayButtons/UserPassButton") as Button
@onready var user_field_goal_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtonsRow/UserPlayButtons/UserFieldGoalButton") as Button
@onready var user_punt_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtonsRow/UserPlayButtons/UserPuntButton") as Button
@onready var user_ready_button: Button = get_node_or_null("UserGroup/UserHUD/UserBottomUIPanel/UserReadyButton") as Button
@onready var user_extra_point_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtonsRow/UserPlayButtons/UserExtraPointButton") as Button
@onready var user_two_point_button: Button = get_node_or_null("UserGroup/UserHUD/UserPlayButtonsRow/UserPlayButtons/UserTwoPointButton") as Button

@onready var start_button: Button = get_node_or_null("HUDGroup/SimButtons/Start") as Button
@onready var pause_button: Button = get_node_or_null("HUDGroup/SimButtons/Pause") as Button
@onready var restart_button: Button = get_node_or_null("HUDGroup/SimButtons/Restart") as Button
@onready var speed_down_button: Button = (get_node_or_null("HUDGroup/SpeedPanel/-") as Button) if get_node_or_null("HUDGroup/SpeedPanel/-") != null else (get_node_or_null("HUDGroup/SimButtons/-") as Button)
@onready var speed_up_button: Button = (get_node_or_null("HUDGroup/SpeedPanel/+") as Button) if get_node_or_null("HUDGroup/SpeedPanel/+") != null else (get_node_or_null("HUDGroup/SimButtons/+") as Button)
@onready var speed_x2_button: Button = get_node_or_null("HUDGroup/SpeedPanel/SpeedX2") as Button
@onready var speed_x10_button: Button = get_node_or_null("HUDGroup/SpeedPanel/SpeedX10") as Button
@onready var sim_step_after_play_toggle: CheckButton = get_node_or_null("HUDGroup/SimStepPanel/SimStepAfterPlayToggle") as CheckButton
@onready var sim_step_next_button: Button = get_node_or_null("HUDGroup/SimStepPanel/SimStepNextButton") as Button
@onready var sim_timer: Timer = get_node_or_null("GameManagers/SimTimer") as Timer
@onready var show_action_timer_bar_toggle: CheckButton = get_node_or_null("HUDGroup/ShowActionTimerBarToggle") as CheckButton

@onready var calc_log_text: RichTextLabel = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcLogScroll/CalcLogText") as RichTextLabel
@onready var calc_log_prev_button: Button = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcNavRow/CalcLogPrev") as Button
@onready var calc_log_next_nav_button: Button = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcNavRow/CalcLogNextNav") as Button
@onready var calc_log_index_label: Label = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcNavRow/CalcLogIndexLabel") as Label
@onready var calc_filter_resolver: CheckButton = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcFilterGrid/CalcFilterResolver") as CheckButton
@onready var calc_filter_post: CheckButton = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcFilterGrid/CalcFilterPost") as CheckButton
@onready var calc_filter_outcome: CheckButton = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcFilterGrid/CalcFilterOutcome") as CheckButton
@onready var calc_filter_turnover: CheckButton = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcFilterGrid/CalcFilterTurnover") as CheckButton
@onready var calc_filter_cards: CheckButton = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcFilterGrid/CalcFilterCards") as CheckButton
@onready var calc_filter_skills: CheckButton = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcFilterGrid/CalcFilterSkills") as CheckButton
@onready var calc_filter_special: CheckButton = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcFilterGrid/CalcFilterSpecial") as CheckButton
@onready var calc_filter_conversion: CheckButton = get_node_or_null("HUDGroup/CalcLogPanel/CalcLogVBox/CalcFilterGrid/CalcFilterConversion") as CheckButton

@onready var opponent_players_container: GridContainer = get_node_or_null("OpponentGroup/OpponentPlayersContainer") as GridContainer
@onready var user_players_container: GridContainer = get_node_or_null("UserGroup/UserHUD/UserPlayersContainer") as GridContainer
@onready var cards_panel: Panel = get_node_or_null("CardsPanel") as Panel
@onready var card_panel: VBoxContainer = $CardsPanel/CardPanel
@onready var card_title_label: Label = get_node_or_null("CardsPanel/CardPanel/CardTitle") as Label
@onready var targeting_panel: VBoxContainer = $TargetingPanel
@onready var mobile_frame: Control = get_node_or_null("MobileFrame") as Control

var _player_tokens: Dictionary = {}
@export_range(1, 5, 1) var current_phase_level: int = 5
## When `false`, scrimmage **play clock is off**: no countdown, no timer-driven auto-ready / delay-of-game / defense auto-pick, no progress bar. Toggle HUD **Play clock** or here for analysis/testing.
@export var show_action_timer_bar: bool = true
var _opponent_flat_def_mod: int = 10
var _staff_data: Dictionary = {}
var _formations_catalog: FormationsCatalog
var _plays_catalog: PlaysCatalog
var _team_playbook_ids: Dictionary = {}
var _team_playbook_max: Dictionary = {}
var _play_pick_layer: CanvasLayer
var _play_pick_popup: PopupPanel
var _play_pick_scroll: ScrollContainer
var _play_pick_cards_wrap: GridContainer
var _play_pick_title_label: Label
var _play_pick_commit_btn: Button
var _play_pick_target_team: String = ""
var _play_pick_bucket_filter: String = ""
var _play_pick_selected_id: String = ""
var _formation_preview_root: Node2D
var _last_play_toast_layer: CanvasLayer
var _last_play_toast_root: Control
var _last_play_toast_rtl: RichTextLabel
var _last_play_toast_hide_timer: Timer
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
var _selected_defense_play: String = ""
var _play_ready_home: bool = false
var _play_ready_away: bool = false
var _defense_selected_explicit: bool = false
var _selected_cards_home: Array[String] = []
var _selected_cards_away: Array[String] = []

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
var _turn_manual_play_home: bool = false
var _turn_manual_play_away: bool = false
var _play_down_at_snap: int = 1
## Non-empty while logging lines for the current resolved scrimmage/punt play (`1st & 10 from 22⬇️` …).
var _event_log_play_situation_prefix: String = ""
var _offense_play_tentative: String = GameState.PENDING_NONE
var _defense_play_tentative: String = ""
var _play_pick_window: String = "offense"
var _current_action_window_duration: float = 10.0
var _manual_pause_active: bool = false
var _auto_pause_after_sim_stop: bool = false
var _sim_tick_paused: bool = false
var _game_clock_hold_after_rule_stop: bool = false
## Until the first scrimmage snap of each half (play + card queue resolved into `_resolve_play`), do not run the game clock during offense play-selection windows. Reset after halftime second-half kickoff and on full game restart.
var _defer_scrimmage_game_clock_until_first_snap: bool = true
var _abandoned_game: bool = false
var _sim_presnap_runoff_applied: bool = false
var _calc_log_entries: Array = []
var _calc_log_index: int = -1
var _calc_log_seq: int = 0
## One calc-log "slide" for the whole snap: cards → resolver → sim → turnover → outcome (filters still apply per line).
var _calc_log_snap_bundle_active: bool = false
var _calc_log_snap_bundle_title: String = ""
var _calc_log_snap_lines: Array = []
var _calc_log_snap_seen_cards: bool = false
var _calc_log_re_side_home: RegEx
var _calc_log_re_side_away: RegEx
## Set for the current `_resolve_play` scrimmage sim so turnover calc lines can label ball carrier / defender by team + formation role.
var _last_scrimmage_sim_ctx: PlaySimContext = null
## Per franchise id for the current match: off_field/def_field (7 each), kicker, punter, returner dicts from roster order.
var _match_field_packages: Dictionary = {}
const ACTION_WINDOW_SECONDS := 10.0
const DELAY_OF_GAME_HOLD_ROW := GameState.TILE_ROWS_TOTAL - 2
const SIM_RUNOFF_MIN_SECONDS := 18
const SIM_RUNOFF_MAX_SECONDS := 28
const SIM_RUNOFF_HURRY_MIN_SECONDS := 8
const SIM_RUNOFF_HURRY_MAX_SECONDS := 14
const SIM_RUNOFF_TWO_MIN_MIN_SECONDS := 6
const SIM_RUNOFF_TWO_MIN_MAX_SECONDS := 12
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
			return "Defensive Endzone"
		GameState.ZONE_START:
			return "Build Zone"
		GameState.ZONE_ADVANCE:
			return "Advance Zone"
		GameState.ZONE_MIDFIELD:
			return "Midfield Zone"
		GameState.ZONE_ATTACK:
			return "Attack Zone"
		GameState.ZONE_RED:
			return "Red Zone"
		GameState.ZONE_END:
			return "Scoring Endzone"
		_:
			return "Unknown Zone"

func _zone_name_defense(zone: int) -> String:
	match zone:
		GameState.ZONE_MY_END:
			return "Scoring Endzone"
		GameState.ZONE_START:
			return "Contain Zone"
		GameState.ZONE_ADVANCE:
			return "Control Zone"
		GameState.ZONE_MIDFIELD:
			return "Midfield Zone"
		GameState.ZONE_ATTACK:
			return "Pressure Zone"
		GameState.ZONE_RED:
			return "Goal Line Zone"
		GameState.ZONE_END:
			return "Defensive Endzone"
		_:
			return "Unknown Zone"

func _zone_display_for_team(zone: int, viewer_team: String) -> String:
	if viewer_team == game_state.possession_team:
		return _zone_name(zone)
	return _zone_name_defense(zone)

func _team_display_name(team: String) -> String:
	var profile := _team_profile(team)
	var n := str(profile.get("name", "")).strip_edges()
	if not n.is_empty():
		return n
	var tid := str(profile.get("id", "")).strip_edges()
	if not tid.is_empty():
		return tid
	return team

func _team_role_name(team: String) -> String:
	return "User" if team == _user_team else "Opponent"

func _team_score(team: String) -> int:
	return game_state.score_home if team == "home" else game_state.score_away

func _assign_user_team_random() -> void:
	_user_team = "home" if randf() < 0.5 else "away"
	if user_team_label:
		user_team_label.text = "You are: %s (%s)" % [_team_display_name(_user_team), _user_team.capitalize()]
	_append_event_log("[b]You are controlling: %s (%s)[/b]" % [_team_display_name(_user_team), _user_team.capitalize()])
	_sync_field_perspective_to_user_team()

func _sync_field_perspective_to_user_team() -> void:
	if field_grid == null:
		return
	field_grid.set("is_user_perspective_home", _user_team == "home")

func _franchise_id_for_seat(seat: String) -> String:
	return _home_team_id if seat == "home" else _away_team_id


func _franchise_display_name_from_id(fr_id: String) -> String:
	var p := team_data.get_by_id(fr_id)
	var n := str(p.get("name", "")).strip_edges()
	return n if not n.is_empty() else fr_id


func _rebuild_match_field_packages() -> void:
	_match_field_packages.clear()
	for fid in [_home_team_id, _away_team_id]:
		_match_field_packages[fid] = _compute_match_field_package_for_franchise(fid)


func _compute_match_field_package_for_franchise(fr_id: String) -> Dictionary:
	var tdoc := team_data.get_by_id(fr_id)
	var id_order: Array = tdoc.get("roster_player_ids", []) as Array
	var ordered: Array[Dictionary] = []
	for idv in id_order:
		var pd := player_data.get_by_id(str(idv))
		if not pd.is_empty():
			ordered.append(pd)
	var off_field: Array[Dictionary] = []
	var def_field: Array[Dictionary] = []
	var kicker: Dictionary = {}
	var punter: Dictionary = {}
	var returner: Dictionary = {}
	if ordered.size() >= 17:
		for i in range(7):
			off_field.append(ordered[i])
		for i in range(7, 14):
			def_field.append(ordered[i])
		kicker = ordered[14]
		punter = ordered[15]
		returner = ordered[16]
	else:
		push_warning("Franchise %s roster size %d (expected 17); using full list for sim." % [fr_id, ordered.size()])
		off_field = ordered.duplicate()
	return {
		"off_field": off_field,
		"def_field": def_field,
		"kicker": kicker,
		"punter": punter,
		"returner": returner,
	}


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
	if ids.size() < 2:
		OS.alert("teams.json must contain at least two distinct teams.", "Team data error")
		_home_team_id = DEFAULT_USER_TEAM_ID
		_away_team_id = DEFAULT_OPPONENT_TEAM_ID
		if _away_team_id == _home_team_id:
			_away_team_id = "cavs"
		return
	ids.shuffle()
	_home_team_id = ids[0]
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
	if _sim_running and _sim_tick_paused:
		return
	_ai_think_lock = true

	if game_state.phase == PHASE_CONVERSION and game_state.conversion_type.is_empty():
		if _is_ai_controlled_team(game_state.conversion_team, include_user_autoplay):
			_choose_conversion(_sim_pick_conversion())
		_ai_think_lock = false
		return

	if game_state.phase == PHASE_CARD_QUEUE:
		var home_ai := _is_ai_controlled_team("home", include_user_autoplay)
		var away_ai := _is_ai_controlled_team("away", include_user_autoplay)
		if home_ai and away_ai and not _sim_presnap_runoff_applied:
			_apply_sim_presnap_runoff()
			_sim_presnap_runoff_applied = true
		if home_ai and not game_state.home_ready:
			if not _did_team_timeout_this_turn("home"):
				_auto_select_for_team("home", -1)
			_set_team_ready("home", true)
		if away_ai and not game_state.away_ready:
			if not _did_team_timeout_this_turn("away"):
				_auto_select_for_team("away", -1)
			_set_team_ready("away", true)
		_ai_think_lock = false
		return

	if _is_phase_allowed_for_play():
		var offense := game_state.possession_team
		var defense := "away" if offense == "home" else "home"
		var offense_ai := _is_ai_controlled_team(offense, include_user_autoplay)
		var defense_ai := _is_ai_controlled_team(defense, include_user_autoplay)
		if _is_ai_controlled_team(offense, include_user_autoplay) and game_state.pending_play_type == PLAY_NONE():
			_on_select_play_for_team(offense, _pick_sim_play_type(), true)
		if _is_ai_controlled_team(defense, include_user_autoplay) and game_state.pending_play_type != PLAY_NONE() and not _defense_selected_explicit:
			_on_select_play_for_team(defense, _pick_sim_defense_play_for_offense(game_state.pending_play_type), true)

	_ai_think_lock = false

func _play_buttons_for_team(team: String) -> Dictionary:
	if team != _user_team:
		return {
			"container": opponent_play_buttons,
			"run": opponent_run_button,
			"pass": opponent_pass_button,
			"fg": opponent_field_goal_button,
			"punt": opponent_punt_button,
			"ready": opponent_ready_button,
			"xp": opponent_extra_point_button,
			"two": opponent_two_point_button
		}
	return {
		"container": user_play_buttons,
		"run": user_run_button,
		"pass": user_pass_button,
		"fg": user_field_goal_button,
		"punt": user_punt_button,
		"ready": user_ready_button,
		"xp": user_extra_point_button,
		"two": user_two_point_button
	}

func _ready() -> void:
	add_to_group("game_scene")
	randomize()
	_calc_log_re_side_home = RegEx.new()
	_calc_log_re_side_home.compile("(?<![A-Za-z0-9_])home(?![A-Za-z0-9_])")
	_calc_log_re_side_away = RegEx.new()
	_calc_log_re_side_away.compile("(?<![A-Za-z0-9_])away(?![A-Za-z0-9_])")
	if sim_timer == null:
		sim_timer = Timer.new()
		sim_timer.name = "SimTimer"
		sim_timer.wait_time = 1.0
		$GameManagers.add_child(sim_timer)

	# 1) Reset runtime state first (so start_game doesn't wipe loaded card state afterward)
	game_state.start_game()
	_calc_log_clear()
	_append_touchback_event_log("(opening kickoff).")
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
	_append_phase_log("User=%s (%s), Opponent=%s" % [_team_display_name(_user_team), _user_team.capitalize(), _team_display_name("away" if _user_team == "home" else "home")], "start_game")
	_update_ui()
	_update_player_details("")
	if player_details_panel:
		player_details_panel.visible = false
	_hide_card_info_panel()

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
	if not show_action_timer_bar or not _turn_action_timer_active:
		return
	if game_state.phase == GameState.PHASE_GAME_OVER or game_state.phase == GameState.PHASE_HALFTIME:
		return
	if game_state.phase != PHASE_PLAY_SELECTION and game_state.phase != PHASE_CARD_QUEUE:
		return
	if _manual_pause_active:
		return
	if _sim_step_waiting_for_next():
		return
	_turn_action_time_remaining = maxf(0.0, _turn_action_time_remaining - _delta)
	var display_seconds := int(ceili(_turn_action_time_remaining))
	if display_seconds != _last_play_clock_display_seconds:
		_last_play_clock_display_seconds = display_seconds
		_update_ui()
	if _turn_action_time_remaining <= 0.0 and not _turn_action_timeout_handled:
		_turn_action_timeout_handled = true
		_handle_turn_action_timeout()

func _start_turn_action_timer(duration: float = ACTION_WINDOW_SECONDS) -> void:
	if not show_action_timer_bar:
		return
	_current_action_window_duration = duration
	_turn_action_timer_active = true
	_turn_action_time_remaining = duration
	_last_play_clock_display_seconds = int(ceili(duration))
	_turn_action_timeout_handled = false
	_sim_presnap_runoff_applied = false
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
	if not show_action_timer_bar:
		return
	if game_state.phase != PHASE_PLAY_SELECTION and game_state.phase != PHASE_CARD_QUEUE:
		return
	_append_phase_subphase("turn_timeout_auto_ready")
	if game_state.phase == PHASE_PLAY_SELECTION:
		var offense := game_state.possession_team
		var defense := "away" if offense == "home" else "home"
		if _play_pick_window == "offense":
			_apply_delay_of_game_penalty()
			_offense_play_tentative = GameState.PENDING_NONE
			_turn_action_time_remaining = ACTION_WINDOW_SECONDS
			_turn_action_timeout_handled = false
			_update_ui()
			return
		if _play_pick_window == "defense":
			_on_select_play_for_team(defense, _pick_sim_defense_play_for_offense(game_state.pending_play_type), true)
			_mark_timed_out_team(defense)
			return
	if game_state.phase != PHASE_CARD_QUEUE:
		return
	for team in ["home", "away"]:
		if _team_is_ready(team):
			continue
		_mark_timed_out_team(team)
		_set_team_ready(team, true)

func _input(event: InputEvent) -> void:
	var mb_release := event as InputEventMouseButton
	if mb_release and not mb_release.pressed and mb_release.button_index == MOUSE_BUTTON_LEFT:
		if cards_panel and cards_panel.visible:
			_hide_card_info_panel()
	var st_release := event as InputEventScreenTouch
	if st_release and not st_release.pressed:
		if cards_panel and cards_panel.visible:
			_hide_card_info_panel()

	var is_press := false
	var press_pos := Vector2.ZERO
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		is_press = true
		press_pos = mb.position
	var st := event as InputEventScreenTouch
	if st and st.pressed:
		is_press = true
		press_pos = st.position
	if not is_press:
		return
	if cards_panel and cards_panel.visible:
		var panel_rect := Rect2(cards_panel.global_position, cards_panel.size)
		if not panel_rect.has_point(press_pos):
			_hide_card_info_panel()
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

func _show_card_info_panel(card: Dictionary) -> void:
	if not cards_panel or not card_title_label:
		return
	cards_panel.top_level = true
	cards_panel.z_index = 100
	card_title_label.text = "Name: %s\nCost: %d\nType: %s\nTarget: %s\n\n%s" % [
		str(card.get("name", "Card")),
		int(card.get("cost", 0)),
		str(card.get("type", "")),
		str(card.get("target_type", "")),
		str(card.get("description", ""))
	]
	if card_panel:
		card_panel.visible = true
	cards_panel.visible = true

func _hide_card_info_panel() -> void:
	if card_panel:
		card_panel.visible = false
	if cards_panel:
		cards_panel.visible = false

func _on_card_tile_info_requested(card: Dictionary) -> void:
	_show_card_info_panel(card)

func _tick_game_clock_one_second() -> void:
	if game_state.half == 1:
		if game_state.game_time_remaining > GameState.HALF_SECONDS:
			game_state.game_time_remaining -= 1
			if game_state.game_time_remaining <= GameState.HALF_SECONDS:
				_append_phase_subphase("halftime")
				game_state.force_halftime_now()
				_append_touchback_event_log("(halftime, second half).")
				_after_force_halftime_second_half()
				game_state.emit_signal("state_changed")
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

	game_state.emit_signal("state_changed")

func _stop_clock(reason: String, apply_hold_after: bool = true) -> void:
	if not _clock_running:
		return
	_manual_pause_active = false
	_clock_running = false
	_clock_accumulator = 0.0
	if apply_hold_after:
		_game_clock_hold_after_rule_stop = true
	if not reason.is_empty():
		_append_event_log("[color=#9aa0a6][i]Clock stopped: %s[/i][/color]" % reason)

func _scrimmage_offense_selecting_window() -> bool:
	if game_state.phase == GameState.PHASE_GAME_OVER or game_state.phase == GameState.PHASE_HALFTIME:
		return false
	if game_state.phase == PHASE_CONVERSION:
		if game_state.conversion_type.is_empty():
			return false
		if game_state.conversion_type == CONVERSION_2PT:
			return game_state.pending_play_type == PLAY_NONE() and _play_pick_window == "offense"
		return false
	if game_state.phase != PHASE_PLAY_SELECTION:
		return false
	return game_state.pending_play_type == PLAY_NONE() and _play_pick_window == "offense"


func _sync_game_clock_scrimmage_policy() -> void:
	if game_state.phase == GameState.PHASE_GAME_OVER or game_state.phase == GameState.PHASE_HALFTIME:
		_clock_running = false
		_clock_accumulator = 0.0
		return
	var want_run := _scrimmage_offense_selecting_window() and not _defer_scrimmage_game_clock_until_first_snap and not _manual_pause_active and not _auto_pause_after_sim_stop and not _game_clock_hold_after_rule_stop and not _sim_step_waiting_for_next()
	if want_run:
		if not _clock_running:
			_clock_running = true
	else:
		if _clock_running:
			_clock_accumulator = 0.0
		_clock_running = false


func _release_sim_to_man_auto_pause_if_any() -> void:
	if not _auto_pause_after_sim_stop:
		return
	_auto_pause_after_sim_stop = false
	_manual_pause_active = false
	_sync_game_clock_scrimmage_policy()


func _after_force_halftime_second_half() -> void:
	_defer_scrimmage_game_clock_until_first_snap = true
	game_state.home_ready = false
	game_state.away_ready = false
	_selected_cards_home.clear()
	_selected_cards_away.clear()
	_sim_presnap_runoff_applied = false
	_turn_initialized = false
	_begin_turn_if_needed()
	if _sim_running:
		_maybe_run_ai_inputs(true)

func _call_timeout(team: String) -> bool:
	var remaining := game_state.timeouts_home if team == "home" else game_state.timeouts_away
	if remaining <= 0:
		return false
	if team == "home":
		game_state.timeouts_home -= 1
	else:
		game_state.timeouts_away -= 1
	if show_action_timer_bar:
		_start_turn_action_timer(ACTION_WINDOW_SECONDS)
	else:
		_stop_turn_action_timer()
	_stop_clock("%s timeout" % team.capitalize(), false)
	_append_event_log("[color=#ffd166][b](%s) TIMEOUT called - %d left[/b][/color]" % [team.capitalize(), remaining - 1])
	_update_ui()
	return true

func _maybe_sim_call_timeouts() -> bool:
	if not _sim_running or _sim_tick_paused:
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
	if _formations_catalog == null:
		_formations_catalog = FormationsCatalog.new()
	if not _formations_catalog.load_from_json("res://data/formations.json"):
		push_error("formations.json failed to load or validate")
	if _plays_catalog == null:
		_plays_catalog = PlaysCatalog.new()
	if not _plays_catalog.load_from_json("res://data/plays.json"):
		push_error("plays.json failed to load")
	player_data.load_from_json("res://data/players.json")
	_rebuild_match_field_packages()
	coach_data.load_catalog("res://data/coaches_catalog.json")
	_load_team_playbooks_and_validate()
	_build_staff_from_team_assignments()
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


func _pid_bucket(play_id: String) -> String:
	if play_id.is_empty() or _plays_catalog == null:
		return ""
	return _plays_catalog.bucket(play_id)


func _team_id_for_seat(seat: String) -> String:
	return _home_team_id if seat == "home" else _away_team_id


func _playbook_play_ids_for_seat(seat: String) -> Array[String]:
	var tid := _team_id_for_seat(seat)
	var ids: Variant = _team_playbook_ids.get(tid, [])
	if typeof(ids) != TYPE_ARRAY:
		return []
	var out: Array[String] = []
	for x in ids:
		out.append(str(x))
	return out


func _playbook_max_for_seat(seat: String) -> int:
	var tid := _team_id_for_seat(seat)
	return int(_team_playbook_max.get(tid, 14))


func _first_play_id_in_book_for_bucket(team_seat: String, bucket: String) -> String:
	var opts := _plays_catalog.filter_play_ids(_playbook_play_ids_for_seat(team_seat), bucket)
	return opts[0] if opts.size() > 0 else ""


func _random_play_id_from_book_for_buckets(team_seat: String, buckets: Array) -> String:
	var pb := _playbook_play_ids_for_seat(team_seat)
	var pool: Array[String] = []
	for pid in pb:
		var b := _pid_bucket(str(pid))
		for bb in buckets:
			if b == str(bb):
				pool.append(str(pid))
				break
	if pool.is_empty():
		return ""
	return pool[randi_range(0, pool.size() - 1)]


func _sim_pick_defense_catalog_id(offense_play_id: String) -> String:
	var defense_seat := "away" if game_state.possession_team == "home" else "home"
	var ob := _pid_bucket(offense_play_id)
	var target_bucket := BUCKET_PASS_DEF
	match ob:
		BUCKET_RUN:
			target_bucket = BUCKET_RUN_DEF
		BUCKET_PASS:
			target_bucket = BUCKET_PASS_DEF
		BUCKET_SPOT_KICK:
			target_bucket = BUCKET_FG_XP_DEF
		BUCKET_PUNT:
			target_bucket = BUCKET_PUNT_RETURN
		_:
			target_bucket = BUCKET_PASS_DEF
	var opts := _plays_catalog.filter_play_ids(_playbook_play_ids_for_seat(defense_seat), target_bucket)
	if opts.is_empty():
		return _first_play_id_in_book_for_bucket(defense_seat, target_bucket)
	return opts[randi_range(0, opts.size() - 1)]


func _load_team_playbooks_and_validate() -> void:
	_team_playbook_ids.clear()
	_team_playbook_max.clear()
	for tid in team_data.get_all_ids():
		var t := team_data.get_by_id(tid)
		var pb_id := str(t.get("playbook_id", ""))
		if pb_id.is_empty():
			push_error("Team %s missing playbook_id" % tid)
			continue
		var ppath := "res://data/playbooks/%s.json" % pb_id
		if not FileAccess.file_exists(ppath):
			push_error("Playbook file missing: %s" % ppath)
			continue
		var doc = JSON.parse_string(FileAccess.get_file_as_string(ppath))
		if typeof(doc) != TYPE_DICTIONARY:
			push_error("Invalid playbook: %s" % pb_id)
			continue
		var pids: Array = doc.get("play_ids", [])
		var mx := int(doc.get("max_slots", 14))
		var arr: Array[String] = []
		for x in pids:
			arr.append(str(x))
		_team_playbook_ids[tid] = arr
		_team_playbook_max[tid] = mx
		var errs := _plays_catalog.validate_playbook(arr, mx)
		for e in errs:
			push_error("Playbook %s: %s" % [pb_id, e])


func _build_staff_from_team_assignments() -> void:
	var th := team_data.get_by_id(_home_team_id)
	var ta := team_data.get_by_id(_away_team_id)
	var hoc := coach_data.get_coach(str(th.get("off_coord_id", "")))
	var hdc := coach_data.get_coach(str(th.get("def_coord_id", "")))
	var aoc := coach_data.get_coach(str(ta.get("off_coord_id", "")))
	var adc := coach_data.get_coach(str(ta.get("def_coord_id", "")))
	_staff_data = {
		"home": {"off_coord": hoc, "def_coord": hdc},
		"away": {"off_coord": aoc, "def_coord": adc},
	}


func _apply_green_call_play_style(btn: Button) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.12, 0.62, 0.28, 1)
	n.corner_radius_top_left = 10
	n.corner_radius_top_right = 10
	n.corner_radius_bottom_right = 10
	n.corner_radius_bottom_left = 10
	n.content_margin_left = 16
	n.content_margin_top = 12
	n.content_margin_right = 16
	n.content_margin_bottom = 12
	var h := StyleBoxFlat.new()
	h.bg_color = Color(0.18, 0.72, 0.36, 1)
	h.corner_radius_top_left = 10
	h.corner_radius_top_right = 10
	h.corner_radius_bottom_right = 10
	h.corner_radius_bottom_left = 10
	h.content_margin_left = 16
	h.content_margin_top = 12
	h.content_margin_right = 16
	h.content_margin_bottom = 12
	var p := StyleBoxFlat.new()
	p.bg_color = Color(0.08, 0.48, 0.2, 1)
	p.corner_radius_top_left = 10
	p.corner_radius_top_right = 10
	p.corner_radius_bottom_right = 10
	p.corner_radius_bottom_left = 10
	p.content_margin_left = 16
	p.content_margin_top = 12
	p.content_margin_right = 16
	p.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_font_size_override("font_size", 22)


const PLAY_PICK_POPUP_SIZE := Vector2i(520, 540)


func _last_play_toast_color_for_tone(tone: String) -> String:
	match tone:
		"good":
			return "#66ff00"
		"bad":
			return "#ff5555"
		"warn":
			return "#ffb703"
		"info":
			return "#38bdf8"
		_:
			return "#e2e8f0"


func _ensure_last_play_toast_ui() -> void:
	if _last_play_toast_layer != null:
		return
	_last_play_toast_layer = CanvasLayer.new()
	_last_play_toast_layer.name = "LastPlayToastLayer"
	_last_play_toast_layer.layer = 18
	add_child(_last_play_toast_layer)
	_last_play_toast_root = Control.new()
	_last_play_toast_root.name = "LastPlayToastRoot"
	_last_play_toast_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_last_play_toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_last_play_toast_layer.add_child(_last_play_toast_root)
	_last_play_toast_rtl = RichTextLabel.new()
	_last_play_toast_rtl.name = "LastPlayToastText"
	_last_play_toast_rtl.bbcode_enabled = true
	_last_play_toast_rtl.fit_content = true
	_last_play_toast_rtl.scroll_active = false
	_last_play_toast_rtl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_last_play_toast_rtl.custom_minimum_size = Vector2(480, 0)
	_last_play_toast_rtl.add_theme_font_size_override("normal_font_size", 88)
	_last_play_toast_rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_last_play_toast_root.add_child(_last_play_toast_rtl)
	_last_play_toast_hide_timer = Timer.new()
	_last_play_toast_hide_timer.name = "LastPlayToastHideTimer"
	_last_play_toast_hide_timer.wait_time = 2.0
	_last_play_toast_hide_timer.one_shot = true
	_last_play_toast_hide_timer.timeout.connect(_hide_last_play_toast)
	_last_play_toast_layer.add_child(_last_play_toast_hide_timer)
	_last_play_toast_layer.visible = false


func _position_last_play_toast_over_mobile_frame() -> void:
	if _last_play_toast_rtl == null or mobile_frame == null:
		return
	var gr := mobile_frame.get_global_rect()
	var max_w := maxf(gr.size.x - 24.0, 200.0)
	_last_play_toast_rtl.custom_minimum_size = Vector2(max_w, 0)
	_last_play_toast_rtl.reset_size()
	var sz := _last_play_toast_rtl.size
	if sz.y < 8.0:
		sz.y = 100.0
	var center := gr.get_center()
	_last_play_toast_rtl.global_position = center - sz * 0.5


func _hide_last_play_toast() -> void:
	if _last_play_toast_hide_timer != null and _last_play_toast_hide_timer.is_stopped() == false:
		_last_play_toast_hide_timer.stop()
	if _last_play_toast_layer != null:
		_last_play_toast_layer.visible = false
	if _last_play_toast_rtl != null:
		_last_play_toast_rtl.clear()


func _show_last_play_toast(plain_line: String, tone: String) -> void:
	if plain_line.is_empty():
		return
	_ensure_last_play_toast_ui()
	if _last_play_toast_hide_timer:
		_last_play_toast_hide_timer.stop()
	var col := _last_play_toast_color_for_tone(tone)
	var safe := plain_line.replace("[", "(").replace("]", ")")
	_last_play_toast_rtl.text = "[center][b][i][color=%s]%s[/color][/i][/b][/center]" % [col, safe]
	_last_play_toast_layer.visible = true
	call_deferred("_position_last_play_toast_over_mobile_frame")
	if _last_play_toast_hide_timer:
		_last_play_toast_hide_timer.start()


func _maybe_toast_after_standard_apply_play(
	offense_play_id: String,
	had_first_down: bool,
	tile_rows_toward_goal: int,
	skip_tile_row_event: bool,
	downs_res: int,
	score_delta: int
) -> void:
	if game_state.phase == GameState.PHASE_GAME_OVER:
		return
	var pbu := _pid_bucket(offense_play_id)
	if pbu == BUCKET_SPOT_KICK:
		if score_delta > 0:
			_show_last_play_toast("Field Goal Good!", "good")
		else:
			_show_last_play_toast("Field Goal Missed!", "bad")
	elif downs_res == 2:
		_show_last_play_toast("Turnover on Downs!", "bad")
	elif not skip_tile_row_event:
		if had_first_down:
			_show_last_play_toast("First Down!", "good")
		else:
			var n: int = maxi(tile_rows_toward_goal, -tile_rows_toward_goal)
			if n == 0:
				_show_last_play_toast("No Gain", "neutral")
			elif tile_rows_toward_goal > 0:
				var yw := "yard" if n == 1 else "yards"
				_show_last_play_toast("%d %s Gain" % [n, yw], "good")
			else:
				var ywl := "yard" if n == 1 else "yards"
				_show_last_play_toast("%d %s Loss" % [n, ywl], "bad")


func _popup_play_pick_over_mobile_frame() -> void:
	if _play_pick_popup == null:
		return
	var sz := PLAY_PICK_POPUP_SIZE
	if mobile_frame == null:
		_play_pick_popup.popup_centered(sz)
		return
	var gr := mobile_frame.get_global_rect()
	var pos := Vector2i(gr.get_center()) - sz / 2
	var min_x := int(gr.position.x)
	var min_y := int(gr.position.y)
	var max_x := int(gr.position.x + gr.size.x) - sz.x
	var max_y := int(gr.position.y + gr.size.y) - sz.y
	pos.x = clampi(pos.x, min_x, maxi(max_x, min_x))
	pos.y = clampi(pos.y, min_y, maxi(max_y, min_y))
	_play_pick_popup.popup(Rect2i(pos, sz))


func _ensure_play_pick_popup() -> void:
	if _play_pick_popup != null:
		return
	_play_pick_layer = CanvasLayer.new()
	_play_pick_layer.name = "PlayPickLayer"
	_play_pick_layer.layer = 20
	add_child(_play_pick_layer)

	_play_pick_popup = PopupPanel.new()
	_play_pick_popup.name = "PlayPickPopup"
	_play_pick_popup.exclusive = true
	_play_pick_layer.add_child(_play_pick_popup)

	var outer := MarginContainer.new()
	outer.name = "PlayPickMargin"
	outer.add_theme_constant_override("margin_left", 14)
	outer.add_theme_constant_override("margin_top", 12)
	outer.add_theme_constant_override("margin_right", 14)
	outer.add_theme_constant_override("margin_bottom", 14)
	_play_pick_popup.add_child(outer)

	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 10)
	outer.add_child(v)

	var title_row := HBoxContainer.new()
	_play_pick_title_label = Label.new()
	_play_pick_title_label.name = "PlayPickTitle"
	_play_pick_title_label.text = "Select play"
	_play_pick_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_play_pick_title_label)
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.flat = true
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.custom_minimum_size = Vector2(44, 40)
	close_btn.pressed.connect(_on_play_pick_cancel_pressed)
	title_row.add_child(close_btn)
	v.add_child(title_row)

	_play_pick_scroll = ScrollContainer.new()
	_play_pick_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_play_pick_scroll.custom_minimum_size = Vector2(460, 320)
	_play_pick_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(_play_pick_scroll)

	_play_pick_cards_wrap = GridContainer.new()
	_play_pick_cards_wrap.columns = 2
	_play_pick_cards_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_pick_scroll.add_child(_play_pick_cards_wrap)

	var bot := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot.add_child(spacer)
	_play_pick_commit_btn = Button.new()
	_play_pick_commit_btn.text = "Call Play"
	_play_pick_commit_btn.custom_minimum_size = Vector2(240, 64)
	_apply_green_call_play_style(_play_pick_commit_btn)
	_play_pick_commit_btn.pressed.connect(_on_play_pick_commit_pressed)
	bot.add_child(_play_pick_commit_btn)
	v.add_child(bot)

	_play_pick_popup.close_requested.connect(_on_play_pick_cancel_pressed)


func _refresh_play_pick_selection_visual() -> void:
	for c in _play_pick_cards_wrap.get_children():
		if c.has_method("set_selected") and c.has_method("get_play_id"):
			c.set_selected(str(c.get_play_id()) == _play_pick_selected_id)


func _on_play_pick_card_pressed(play_id: String) -> void:
	_play_pick_selected_id = play_id
	_refresh_play_pick_selection_visual()


func _open_play_category_picker(team_seat: String, bucket: String) -> void:
	_ensure_play_pick_popup()
	var pb_ids := _playbook_play_ids_for_seat(team_seat)
	var opts := _plays_catalog.filter_play_ids(pb_ids, bucket)
	if opts.is_empty():
		result_text.text = "No plays of this type in playbook."
		return
	_play_pick_target_team = team_seat
	_play_pick_bucket_filter = bucket
	for c in _play_pick_cards_wrap.get_children():
		c.queue_free()
	_play_pick_selected_id = ""
	if _play_pick_title_label:
		_play_pick_title_label.text = "Select (%s)" % bucket
	var first := true
	for pid in opts:
		var row := _plays_catalog.get_play(pid)
		var fid := _plays_catalog.formation_id_for(pid)
		var form := _formations_catalog.get_by_id(fid)
		var card := PLAY_PICK_CARD_SCENE.instantiate()
		_play_pick_cards_wrap.add_child(card)
		card.setup(pid, row, form, first)
		if first:
			_play_pick_selected_id = pid
			first = false
		card.pressed_play.connect(_on_play_pick_card_pressed)
	_refresh_play_pick_selection_visual()
	_popup_play_pick_over_mobile_frame()


func _on_play_pick_commit_pressed() -> void:
	if _play_pick_selected_id.is_empty():
		return
	var pid := _play_pick_selected_id
	var offense := game_state.possession_team
	var defense := "away" if offense == "home" else "home"
	var manual := true
	if _play_pick_target_team == offense:
		if _play_pick_target_team == _user_team:
			_release_sim_to_man_auto_pause_if_any()
		if _is_ai_controlled_team(offense, false):
			manual = false
		_commit_offense_play(pid, manual)
	elif _play_pick_target_team == defense:
		if _play_pick_target_team == _user_team:
			_release_sim_to_man_auto_pause_if_any()
		if _is_ai_controlled_team(defense, false):
			manual = false
		_commit_defense_play(pid, manual)
	_play_pick_popup.hide()


func _on_play_pick_cancel_pressed() -> void:
	if _play_pick_popup:
		_play_pick_popup.hide()


func _on_scrimmage_category_pressed(team_seat: String, ui_cat: String) -> void:
	var offense := game_state.possession_team
	var is_offense_row := team_seat == offense
	var bucket := ui_cat
	if is_offense_row:
		match ui_cat:
			"run":
				bucket = BUCKET_RUN
			"pass":
				bucket = BUCKET_PASS
			"fg":
				bucket = BUCKET_SPOT_KICK
			"punt":
				bucket = BUCKET_PUNT
	else:
		match ui_cat:
			"run":
				bucket = BUCKET_RUN_DEF
			"pass":
				bucket = BUCKET_PASS_DEF
			"fg":
				bucket = BUCKET_FG_XP_DEF
			"punt":
				bucket = BUCKET_PUNT_RETURN
	_open_play_category_picker(team_seat, bucket)


func _wire_buttons() -> void:
	var opponent_team := "away" if _user_team == "home" else "home"
	var opponent_buttons := _play_buttons_for_team(opponent_team)
	var user_buttons := _play_buttons_for_team(_user_team)

	var arun: Button = opponent_buttons.get("run") as Button
	var ashort: Button = opponent_buttons.get("short") as Button
	var adeep: Button = opponent_buttons.get("deep") as Button
	var afg: Button = opponent_buttons.get("fg") as Button
	var apunt: Button = opponent_buttons.get("punt") as Button
	var aready: Button = opponent_buttons.get("ready") as Button
	var axp: Button = opponent_buttons.get("xp") as Button
	var atwo: Button = opponent_buttons.get("two") as Button

	if arun:
		arun.pressed.connect(func(): _on_scrimmage_category_pressed(opponent_team, "run"))
	if ashort:
		ashort.text = "Pass"
		ashort.pressed.connect(func(): _on_scrimmage_category_pressed(opponent_team, "pass"))
	if adeep:
		adeep.visible = false
	if afg:
		afg.pressed.connect(func(): _on_scrimmage_category_pressed(opponent_team, "fg"))
	if apunt:
		apunt.pressed.connect(func(): _on_scrimmage_category_pressed(opponent_team, "punt"))
	if aready:
		aready.pressed.connect(func(): _on_primary_action_pressed_for_team(opponent_team))
	if axp:
		axp.pressed.connect(func(): _choose_conversion_for_team(opponent_team, CONVERSION_XP))
	if atwo:
		atwo.pressed.connect(func(): _choose_conversion_for_team(opponent_team, CONVERSION_2PT))

	var hrun: Button = user_buttons.get("run") as Button
	var hpass: Button = user_buttons.get("pass") as Button
	var hfg: Button = user_buttons.get("fg") as Button
	var hpunt: Button = user_buttons.get("punt") as Button
	var hready: Button = user_buttons.get("ready") as Button
	var hxp: Button = user_buttons.get("xp") as Button
	var htwo: Button = user_buttons.get("two") as Button

	if hrun:
		hrun.pressed.connect(func(): _on_scrimmage_category_pressed(_user_team, "run"))
	if hpass:
		hpass.text = "Pass"
	if hpass:
		hpass.pressed.connect(func(): _on_scrimmage_category_pressed(_user_team, "pass"))
	if hfg:
		hfg.pressed.connect(func(): _on_scrimmage_category_pressed(_user_team, "fg"))
	if hpunt:
		hpunt.pressed.connect(func(): _on_scrimmage_category_pressed(_user_team, "punt"))
	if hready:
		hready.pressed.connect(func(): _on_primary_action_pressed_for_team(_user_team))
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
	if speed_x2_button:
		speed_x2_button.pressed.connect(func(): _on_speed_preset_pressed(2.0))
	if speed_x10_button:
		speed_x10_button.pressed.connect(func(): _on_speed_preset_pressed(10.0))
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if tools_menu_button:
		var pm := tools_menu_button.get_popup()
		pm.add_item("Formation tool…", 0)
		pm.id_pressed.connect(_on_tools_menu_id_pressed)
	if user_tos_button:
		user_tos_button.pressed.connect(func(): _call_timeout(_user_team))
	if user_forfeit_button:
		user_forfeit_button.pressed.connect(_on_user_forfeit_pressed)
	if sim_timer:
		sim_timer.timeout.connect(_on_sim_tick)
	if sim_step_next_button:
		sim_step_next_button.pressed.connect(_on_sim_step_next_pressed)
	if sim_step_after_play_toggle:
		sim_step_after_play_toggle.toggled.connect(_on_sim_step_after_play_toggled)
	if show_action_timer_bar_toggle:
		show_action_timer_bar_toggle.set_pressed_no_signal(show_action_timer_bar)
		show_action_timer_bar_toggle.toggled.connect(_on_show_action_timer_bar_toggled)
	if calc_log_prev_button:
		calc_log_prev_button.pressed.connect(_on_calc_log_prev_pressed)
	if calc_log_next_nav_button:
		calc_log_next_nav_button.pressed.connect(_on_calc_log_next_nav_pressed)
	for f in [
		calc_filter_resolver, calc_filter_post, calc_filter_outcome, calc_filter_turnover,
		calc_filter_cards, calc_filter_skills, calc_filter_special, calc_filter_conversion
	]:
		if f:
			f.toggled.connect(_on_calc_filter_toggled)
	game_state.state_changed.connect(_update_ui)

func _on_primary_action_pressed_for_team(team: String) -> void:
	if game_state.phase == PHASE_CARD_QUEUE:
		_on_ready_pressed_for_team(team)
		return
	if game_state.phase == PHASE_PLAY_SELECTION:
		var offense := game_state.possession_team
		var defense := "away" if offense == "home" else "home"
		if team == offense:
			_try_commit_offense_play_for_team(team)
		elif team == defense:
			_try_commit_defense_play_for_team(team)

func _try_commit_offense_play_for_team(team: String) -> void:
	if team != game_state.possession_team:
		return
	if _is_ai_controlled_team(team, false):
		return
	if _offense_play_tentative == PLAY_NONE():
		result_text.text = "Select a play type first (Run, Short Pass, Deep Pass, or Field Goal)."
		return
	_commit_offense_play(_offense_play_tentative, true)

func _try_commit_defense_play_for_team(team: String) -> void:
	var offense := game_state.possession_team
	var defense := "away" if offense == "home" else "home"
	if team != defense:
		return
	if _is_ai_controlled_team(team, false):
		return
	if game_state.pending_play_type == PLAY_NONE():
		return
	if _defense_play_tentative.is_empty():
		result_text.text = "Select a defensive play first (Run Def, Man-to-Man, Zone, or FG Def)."
		return
	_commit_defense_play(_defense_play_tentative, true)

func _on_select_play_for_team(team: String, play_type: String, allow_ai: bool = false) -> void:
	if not allow_ai and team == _user_team:
		_release_sim_to_man_auto_pause_if_any()
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
		_begin_turn_if_needed()
		if allow_ai or _is_ai_controlled_team(offense, false):
			_commit_offense_play(play_type, false)
		else:
			_offense_play_tentative = play_type
		_update_ui()
		return
	if team == defense:
		if game_state.pending_play_type == PLAY_NONE():
			return
		if allow_ai:
			_commit_defense_play(play_type, false)
			return
		_defense_play_tentative = play_type
		_update_ui()
		return

func _on_special_play_button_for_team(team: String) -> void:
	var offense := game_state.possession_team
	var defense := "away" if offense == "home" else "home"
	if team == defense and _pid_bucket(game_state.pending_play_type) == BUCKET_PUNT:
		var pr := _first_play_id_in_book_for_bucket(team, BUCKET_PUNT_RETURN)
		if not pr.is_empty():
			_on_select_play_for_team(team, pr, false)
		return
	var fg := _random_play_id_from_book_for_buckets(team, [BUCKET_SPOT_KICK])
	if fg.is_empty():
		fg = "fg_01"
	_on_select_play_for_team(team, fg, false)

func _commit_offense_play(play_type: String, from_manual: bool) -> void:
	_begin_turn_if_needed()
	_stop_turn_action_timer()
	game_state.pending_play_type = play_type
	_offense_play_tentative = GameState.PENDING_NONE
	_defense_play_tentative = ""
	if from_manual:
		if game_state.possession_team == "home":
			_turn_manual_play_home = true
		else:
			_turn_manual_play_away = true
	_play_pick_window = "defense"
	_start_turn_action_timer(ACTION_WINDOW_SECONDS)
	_update_ui()

func _commit_defense_play(play_type: String, from_manual: bool) -> void:
	_selected_defense_play = play_type
	_defense_play_tentative = ""
	_defense_selected_explicit = true
	if from_manual:
		if game_state.possession_team == "home":
			_turn_manual_play_away = true
		else:
			_turn_manual_play_home = true
	_stop_turn_action_timer()
	_update_ui()
	_maybe_begin_after_play_selection()

func _on_play_non_targeted_card_for_team(team: String) -> void:
	if team == _user_team:
		_release_sim_to_man_auto_pause_if_any()
	if _is_ai_controlled_team(team, false):
		return
	if game_state.phase != PHASE_CARD_QUEUE:
		return
	if (team == "home" and game_state.home_ready) or (team == "away" and game_state.away_ready):
		return
	_on_play_non_targeted_card(team)

func _on_ready_pressed_for_team(team: String, allow_ai: bool = false) -> void:
	if not allow_ai and team == _user_team:
		_release_sim_to_man_auto_pause_if_any()
	if not allow_ai and _is_ai_controlled_team(team, false):
		return
	if not allow_ai:
		if team == "home":
			_manual_ready_pressed_home = true
		else:
			_manual_ready_pressed_away = true
	_on_ready_pressed(team)

func _finalize_user_ready_activity_for_turn() -> void:
	pass

func _apply_forfeit(team: String, reason: String = "forfeit") -> void:
	if game_state.phase == GameState.PHASE_GAME_OVER:
		return
	var team_score := game_state.score_home if team == "home" else game_state.score_away
	var opp_score := game_state.score_away if team == "home" else game_state.score_home
	if reason == "ready_timeout" or reason == "inaction_streak":
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
	_manual_pause_active = false
	_auto_pause_after_sim_stop = false
	_sim_tick_paused = false
	_game_clock_hold_after_rule_stop = false
	_clock_running = false
	_clock_accumulator = 0.0
	if sim_timer:
		sim_timer.stop()
	var reason_text := "manual forfeit" if reason == "forfeit_button" else "forfeit: 3 turns without a manual play call and without cards played"
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
	_manual_pause_active = false
	_auto_pause_after_sim_stop = false
	_sim_tick_paused = false
	_game_clock_hold_after_rule_stop = false
	_clock_running = false
	_clock_accumulator = 0.0
	if sim_timer:
		sim_timer.stop()
	var reason_text := "both teams missed Ready 3 times" if reason == "ready_timeout_both" else ("both teams: 3 turns without play+cards" if reason == "inaction_both" else reason)
	_append_event_log("[color=#9aa0a6][b]ABANDONED[/b][/color] %s. Game not recorded." % reason_text)
	result_text.text = "[center][color=#9aa0a6][b]GAME ABANDONED[/b][/color][/center]\nNo final result recorded."
	game_state.emit_signal("state_changed")

func _choose_conversion_for_team(team: String, conv_type: String) -> void:
	if game_state.phase != PHASE_CONVERSION:
		return
	if team != game_state.conversion_team:
		return
	if team == _user_team:
		_release_sim_to_man_auto_pause_if_any()
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
		var user_fr := _franchise_id_for_seat(_user_team)
		var opp_fr := _franchise_id_for_seat("away" if _user_team == "home" else "home")
		if team == user_fr:
			user_players_container.add_child(token)
		else:
			opponent_players_container.add_child(token)
		token.bind_player(p)
		token.selected.connect(_on_player_selected)
		_player_tokens[p["id"]] = token

func _on_select_play(play_type: String) -> void:
	if not _is_phase_allowed_for_play():
		return
	if game_state.phase != PHASE_CONVERSION or game_state.conversion_type != CONVERSION_2PT:
		return
	_release_sim_to_man_auto_pause_if_any()
	_begin_turn_if_needed()
	game_state.pending_play_type = play_type
	_selected_defense_play = ""
	_defense_selected_explicit = true
	_begin_after_defense_pick()

func _begin_after_defense_pick() -> void:
	_stop_turn_action_timer()
	_play_pick_window = "none"
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
	if _turn_counter > 0:
		_evaluate_inaction_streaks_for_completed_turn()
	if game_state.phase == GameState.PHASE_GAME_OVER:
		_turn_initialized = true
		return
	_turn_manual_play_home = false
	_turn_manual_play_away = false
	_play_down_at_snap = clampi(game_state.downs, 1, 4)
	_turn_counter += 1
	_turn_initialized = true
	_game_clock_hold_after_rule_stop = false
	_append_phase_log("Half %d | Turn %d | Possession: %s Ball | Zone: %s" % [game_state.half, _turn_counter, _team_display_name(game_state.possession_team), _zone_name(game_state.current_zone)], "start_turn")
	_append_phase_subphase("play_selection")
	_offense_play_tentative = GameState.PENDING_NONE
	_defense_play_tentative = ""
	_play_pick_window = "offense"
	_defense_selected_explicit = false
	_selected_defense_play = ""
	game_state.pending_play_type = GameState.PENDING_NONE
	_advance_both_teams_resources()
	_start_turn_action_timer(ACTION_WINDOW_SECONDS)
	_sync_game_clock_scrimmage_policy()

func _evaluate_inaction_streaks_for_completed_turn() -> void:
	var home_tracked := not _is_ai_controlled_team("home", false)
	var away_tracked := not _is_ai_controlled_team("away", false)
	if _sim_running and _user_team == "home":
		home_tracked = false
	if _sim_running and _user_team == "away":
		away_tracked = false
	if home_tracked:
		var had_manual_play := _turn_manual_play_home
		var had_cards := game_state.card_played_this_play_home
		if not had_manual_play and not had_cards:
			_ready_miss_streak_home += 1
			_append_event_log("[color=#ffb703][b]No play + no cards (Home %d/%d)[/b][/color]" % [_ready_miss_streak_home, USER_READY_MISS_FORFEIT_TURNS])
		else:
			_ready_miss_streak_home = 0
	if away_tracked:
		var had_manual_play_a := _turn_manual_play_away
		var had_cards_a := game_state.card_played_this_play_away
		if not had_manual_play_a and not had_cards_a:
			_ready_miss_streak_away += 1
			_append_event_log("[color=#ffb703][b]No play + no cards (Away %d/%d)[/b][/color]" % [_ready_miss_streak_away, USER_READY_MISS_FORFEIT_TURNS])
		else:
			_ready_miss_streak_away = 0
	var home_forfeit := home_tracked and _ready_miss_streak_home >= USER_READY_MISS_FORFEIT_TURNS
	var away_forfeit := away_tracked and _ready_miss_streak_away >= USER_READY_MISS_FORFEIT_TURNS
	if home_forfeit and away_forfeit:
		_apply_abandoned_game("inaction_both")
		return
	if home_forfeit:
		_apply_forfeit("home", "inaction_streak")
		return
	if away_forfeit:
		_apply_forfeit("away", "inaction_streak")
		return

func _apply_delay_of_game_penalty() -> void:
	if game_state.current_los_row_engine < DELAY_OF_GAME_HOLD_ROW:
		game_state.apply_ball_movement_tile_delta(-1)
	game_state.sync_goal_to_go_first_down_after_play()
	_append_event_log("[color=#ffb703][b]Delay of game[/b][/color] — offense. LOS back one tile row (toward own goal) where applicable.")
	_append_phase_subphase("delay_of_game")
	_show_last_play_toast("Delay of Game Penalty", "warn")

func _advance_both_teams_resources() -> void:
	if game_state.just_started_possession:
		game_state.just_started_possession = false
		card_manager.draw(game_state.hand_home, game_state.deck_home, game_state.discard_home, 1, 5)
		card_manager.draw(game_state.hand_away, game_state.deck_away, game_state.discard_away, 1, 5)
		game_state.card_played_this_play_home = false
		game_state.card_played_this_play_away = false
		return
		
	game_state.momentum_home += 1
	game_state.momentum_away += 1

	card_manager.draw(game_state.hand_home, game_state.deck_home, game_state.discard_home, 1, 5)
	card_manager.draw(game_state.hand_away, game_state.deck_away, game_state.discard_away, 1, 5)

	game_state.card_played_this_play_home = false
	game_state.card_played_this_play_away = false
	
	print("DRAW BEFORE H:", game_state.hand_home.size(), " A:", game_state.hand_away.size())
	# draw calls...
	print("DRAW AFTER  H:", game_state.hand_home.size(), " A:", game_state.hand_away.size())


func _build_scrimmage_play_sim_context(offense_play_id: String, defense_play_id: String, play_row: Dictionary) -> PlaySimContext:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var poss := game_state.possession_team
	var def_seat := "away" if poss == "home" else "home"
	var off_fr := _franchise_id_for_seat(poss)
	var def_fr := _franchise_id_for_seat(def_seat)
	var off_pkg: Dictionary = _match_field_packages.get(off_fr, {}) as Dictionary
	var def_pkg: Dictionary = _match_field_packages.get(def_fr, {}) as Dictionary
	var off_players: Array = off_pkg.get("off_field", [])
	var def_players: Array = def_pkg.get("def_field", [])
	if off_players.is_empty():
		off_players = player_data.get_team(off_fr)
	if def_players.is_empty():
		def_players = player_data.get_team(def_fr)
	var labels := {
		off_fr: _franchise_display_name_from_id(off_fr),
		def_fr: _franchise_display_name_from_id(def_fr),
	}
	var off_f := _formations_catalog.get_by_id(_plays_catalog.formation_id_for(offense_play_id))
	var def_f := _formations_catalog.get_by_id(_plays_catalog.formation_id_for(defense_play_id))
	if off_f.is_empty():
		off_f = _formations_catalog.get_by_id("off_i")
	if def_f.is_empty():
		def_f = _formations_catalog.get_by_id("def_43")
	if off_f.is_empty() or def_f.is_empty():
		push_error("Scrimmage sim: formations missing for play/defense ids")
	return PlaySimContext.build(
		rng,
		poss,
		offense_play_id,
		defense_play_id,
		play_row,
		game_state.current_zone,
		off_players,
		def_players,
		off_f,
		def_f,
		labels
	)


func _resolve_play() -> void:
	if game_state.pending_play_type == PLAY_NONE():
		return
	_last_scrimmage_sim_ctx = null
	if _defer_scrimmage_game_clock_until_first_snap:
		_defer_scrimmage_game_clock_until_first_snap = false
		_sync_game_clock_scrimmage_policy()
	_stop_turn_action_timer()

	game_state.phase = PHASE_RESOLVING
	_append_phase_subphase("resolving")
	var pid := game_state.pending_play_type
	var pbucket := _pid_bucket(pid)
	var defense_mod := _defense_modifier_for_play(pid, _selected_defense_play)

	if pbucket == BUCKET_PUNT:
		var punter := _kicker_for_fg_attempt()
		var return_called := _pid_bucket(_selected_defense_play) == BUCKET_PUNT_RETURN
		var mods := _build_punt_return_modifiers()
		var punt_result := play_resolver.resolve_punt(game_state.current_los_row_engine, punter, return_called, mods)
		punt_result["breakdown"].append("Defense call: %s" % _selected_defense_play)
		var spec_lines: Array[String] = [
			"Punt return modifiers (returner vs punter): speed %d, agility %d, catching %d vs tackling %d, awareness %d." % [
				int(mods.get("return_speed", 0)), int(mods.get("return_agility", 0)), int(mods.get("return_catching", 0)),
				int(mods.get("coverage_tackling", 0)), int(mods.get("coverage_awareness", 0))
			],
			"Coach/card shifts: staff return %+d, staff coverage %+d, card return %+d, card coverage %+d." % [
				int(mods.get("staff_return_bonus", 0)), int(mods.get("staff_coverage_bonus", 0)),
				int(mods.get("card_return_bonus", 0)), int(mods.get("card_coverage_bonus", 0))
			]
		]
		_calc_log_push_slide_flat("Punt — setup", spec_lines, CALC_LOG_CAT_SPECIAL)
		_calc_log_push_breakdown_slide("Punt — resolver", punt_result)
		_apply_punt_result(punt_result)
		return

	var play_result: Dictionary
	if pbucket == BUCKET_SPOT_KICK and current_phase_level >= 2:
		var kicker := _kicker_for_fg_attempt()
		var kicker_id := str(kicker.get("id", ""))
		if kicker_id.is_empty():
			kicker_id = game_state.selected_player_id
		var off_bo := _staff_data[game_state.possession_team]["off_coord"].get("bonus_offense", {}) as Dictionary
		var staff_bonus := int(off_bo.get("standard_zone_bonus", 0))
		play_result = play_resolver.resolve_spot_kick(kicker_id, game_state.current_zone, kicker, _opponent_flat_def_mod + defense_mod - staff_bonus)
		play_result["breakdown"].append("Defense call: %s (%+d)" % [_selected_defense_play, defense_mod])
	else:
		if game_state.selected_player_id.is_empty():
			var team_players := player_data.get_team(_franchise_id_for_seat(game_state.possession_team))
			if team_players.size() > 0:
				game_state.selected_player_id = str(team_players[0].get("id", ""))

		var row := _plays_catalog.get_play(pid)
		var sim_ctx := _build_scrimmage_play_sim_context(pid, _selected_defense_play, row)
		_last_scrimmage_sim_ctx = sim_ctx
		play_result = play_resolver.resolve_scrimmage_play(sim_ctx, pid, row, pbucket, game_state.selected_player_id)
		play_result["breakdown"].append("Defense call (formation shell only; no yard modifiers): %s" % _selected_defense_play)
		var tile_delta := int(play_result.get("tile_delta", 0))
		play_result["tile_delta"] = tile_delta
		play_result["result_text"] = "%s: %+d tile rows toward goal." % [str(play_result.get("play_type", "")), tile_delta]
		if not str(play_result.get("tackled_by_id", "")).is_empty():
			_last_defender_id = str(play_result.get("tackled_by_id", ""))

	if pbucket == BUCKET_SPOT_KICK and current_phase_level >= 2:
		_calc_log_push_breakdown_slide("Field goal — resolver", play_result)
	else:
		_calc_log_push_breakdown_slide("Scrimmage — resolver & matchup", play_result)

	_apply_play_result(play_result)

func _build_punt_return_modifiers() -> Dictionary:
	var offense := game_state.possession_team
	var defense := "away" if offense == "home" else "home"
	var def_fr := _franchise_id_for_seat(defense)
	var off_fr := _franchise_id_for_seat(offense)
	var pkgd: Dictionary = _match_field_packages.get(def_fr, {})
	var ret: Dictionary = pkgd.get("returner", {})
	if ret.is_empty():
		ret = player_data.get_primary_return_candidate(def_fr)
	var pkgo: Dictionary = _match_field_packages.get(off_fr, {})
	var punter: Dictionary = pkgo.get("punter", {})
	if punter.is_empty():
		punter = _kicker_for_fg_attempt()
	var st_d: Dictionary = _staff_data.get(defense, {}) as Dictionary
	var st_o: Dictionary = _staff_data.get(offense, {}) as Dictionary
	var dc_d: Dictionary = st_d.get("def_coord", {}) as Dictionary
	var oc_o: Dictionary = st_o.get("off_coord", {}) as Dictionary
	var b_d_d: Dictionary = dc_d.get("bonus_defense", {}) as Dictionary
	var b_o_o: Dictionary = oc_o.get("bonus_offense", {}) as Dictionary
	var s_ret := int(b_d_d.get("punt_return_bonus", 0))
	var s_cov := int(b_o_o.get("punt_coverage_bonus", 0))
	return {
		"return_speed": int(ret.get("speed", 5)),
		"return_agility": int(ret.get("agility", 5)),
		"return_catching": int(ret.get("catching", 5)),
		"coverage_tackling": int(punter.get("tackling", 5)),
		"coverage_awareness": int(punter.get("awareness", 5)),
		"staff_return_bonus": s_ret,
		"staff_coverage_bonus": s_cov,
		"card_return_bonus": 0,
		"card_coverage_bonus": 0
	}


func _apply_punt_result(result: Dictionary) -> void:
	var snap_down := clampi(game_state.downs, 1, 4)
	var snap_los := game_state.current_los_row_engine
	var snap_fd := game_state.first_down_target_row_engine
	var snap_goal := snap_fd < 0 or snap_los <= GameState.FIRST_DOWN_TILE_ROWS
	_begin_event_log_play_situation(snap_down, snap_los, snap_fd, snap_goal)
	var offense_play_for_summary := game_state.pending_play_type
	var offense_team_for_summary := game_state.possession_team
	var defense_play_for_summary := _selected_defense_play
	var summary_result_text := str(result.get("result_text", "Punt"))
	var post_row := int(result.get("post_punt_los_row_engine", game_state.current_los_row_engine))
	post_row = clampi(post_row, 0, GameState.TILE_ROWS_TOTAL - 1)
	var zone_after_offense_view := int(result.get("zone_after_current_offense", game_state.zone_from_engine_row(post_row)))
	var net_rows := int(result.get("net_rows", 5))
	var punt_rows := int(result.get("punt_rows", net_rows))
	var return_rows := int(result.get("return_rows", 0))
	_game_plays += 1
	game_state.plays_used_current_drive += 1
	game_state.current_los_row_engine = post_row
	game_state.current_zone = game_state.zone_from_engine_row(post_row)
	game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
	if zone_after_offense_view >= GameState.ZONE_END:
		game_state.next_drive_los_row_engine = GameState.TOUCHBACK_LOS_ROW_ENGINE
	else:
		game_state.next_drive_los_row_engine = -1
	game_state.end_possession("punt", 0)
	_stop_clock("punt")
	_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, -net_rows)
	_append_event_log("[color=#4da3ff][b]PUNT[/b][/color] Punt %d tile rows, return %d tile rows, net %d. Opponent starts in %s." % [punt_rows, return_rows, net_rows, _zone_name(game_state.next_drive_start_zone)])
	_calc_log_push_slide_flat("Punt — result & possession", [
		"Punt: %d tile rows out, return %d, net %d toward receiving goal." % [punt_rows, return_rows, net_rows],
		"Receiving drive starts in %s; new LOS row (engine) %d." % [_zone_name(game_state.next_drive_start_zone), post_row],
		"Punt into endzone (touchback path): %s." % ("yes" if zone_after_offense_view >= GameState.ZONE_END else "no"),
	], CALC_LOG_CAT_SPECIAL)
	if zone_after_offense_view >= GameState.ZONE_END:
		_append_touchback_event_log("(punt into endzone).")
	if net_rows >= 0:
		var net_abs := net_rows
		var yw := "yard" if net_abs == 1 else "yards"
		_show_last_play_toast("Punt — Net %d %s" % [net_abs, yw], "info")
	else:
		var loss: int = maxi(net_rows, -net_rows)
		var ywl := "yard" if loss == 1 else "yards"
		_show_last_play_toast("Punt — Net loss of %d %s" % [loss, ywl], "bad")
	game_state.pending_play_type = GameState.PENDING_NONE
	_selected_defense_play = ""
	_awaiting_defense_pick = false
	_end_event_log_play_situation()
	_reset_next_turn_after_possession_change("punt")
	_calc_log_commit_snap_bundle_if_active()
	_sim_try_pause_step_after_play()
	game_state.emit_signal("state_changed")

## 0 = normal; 1 = turnover on downs + defensive TD (caller returns); 2 = turnover on downs, caller runs common footer
func _apply_downs_and_first_down_after_play(
	row_after_engine: int,
	offense_team_for_summary: String,
	offense_play_for_summary: String,
	defense_play_for_summary: String,
	summary_result_text: String,
	tile_rows_toward_goal: int,
	earned_first_down: bool
) -> int:
	if earned_first_down:
		game_state.downs = 1
		game_state.reset_first_down_chain_from_current_zone()
		return 0
	if game_state.downs == 4:
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
			var tod_summary := "TURNOVER ON DOWNS + DEFENSIVE TD"
			_append_event_log_play_tile_rows_line(offense_team_for_summary, offense_play_for_summary, tile_rows_toward_goal)
			_append_event_log("[color=#ff6666][b]TURNOVER ON DOWNS[/b][/color]")
			_calc_log_push_slide_flat("Outcome — turnover on downs (defensive TD)", [
				"Fourth-down stop in the scoring endzone: defense scores +6 for %s (conversion follows)." % _team_display_name(scoring_team),
			], CALC_LOG_CAT_OUTCOME)
			_end_event_log_play_situation()
			_begin_post_td_conversion(scoring_team)
			_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, tod_summary, tile_rows_toward_goal)
			game_state.pending_play_type = GameState.PENDING_NONE
			_selected_defense_play = ""
			_awaiting_defense_pick = false
			_sim_try_pause_step_after_play()
			game_state.emit_signal("state_changed")
			return 1
		game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
		game_state.end_possession("turnover_on_downs", 0)
		_stop_clock("turnover on downs")
		result_text.text = "[center][color=#ff4444][b]TURNOVER ON DOWNS![/b][/color][/center]\nOpponent starts in %s." % _zone_name(game_state.next_drive_start_zone)
		_calc_log_push_slide_flat("Outcome — turnover on downs", [
			"Failed to convert on 4th down outside the scoring endzone.",
			"Opponent takes over in %s." % _zone_name(game_state.next_drive_start_zone),
		], CALC_LOG_CAT_OUTCOME)
		return 2
	game_state.downs += 1
	return 0

func _defense_modifier_for_play(offense_play_id: String, defense_play_id: String) -> int:
	var ob := _pid_bucket(offense_play_id)
	var db := _pid_bucket(defense_play_id)
	if ob == BUCKET_RUN and db == BUCKET_RUN_DEF:
		return 5 + SAME_BUCKET_DEFENSE_EXTRA
	if ob == BUCKET_PASS and db == BUCKET_PASS_DEF:
		return 5 + SAME_BUCKET_DEFENSE_EXTRA
	if ob == BUCKET_RUN and db == BUCKET_PASS_DEF:
		return -5
	if ob == BUCKET_PASS and db == BUCKET_RUN_DEF:
		return -5
	if ob == BUCKET_SPOT_KICK and db == BUCKET_FG_XP_DEF:
		return 6
	if ob == BUCKET_PUNT and db == BUCKET_PUNT_RETURN:
		return 0
	return 0

func _apply_play_result(result: Dictionary) -> void:
	_last_skill_proc_text = ""
	var offense_team_for_summary := game_state.possession_team
	var offense_play_for_summary := game_state.pending_play_type
	var defense_play_for_summary := _selected_defense_play
	var summary_result_text := str(result.get("result_text", ""))
	var is_two_point_attempt := game_state.conversion_pending and game_state.conversion_type == CONVERSION_2PT
	if not is_two_point_attempt:
		var snap_down := clampi(game_state.downs, 1, 4)
		var snap_los := game_state.current_los_row_engine
		var snap_fd := game_state.first_down_target_row_engine
		var snap_goal := snap_fd < 0 or snap_los <= GameState.FIRST_DOWN_TILE_ROWS
		_begin_event_log_play_situation(snap_down, snap_los, snap_fd, snap_goal)
	_game_plays += 1
	if _pid_bucket(game_state.pending_play_type) == BUCKET_SPOT_KICK:
		_game_fg_attempts += 1
	game_state.plays_used_current_drive += 1
	var row_before_engine: int = game_state.current_los_row_engine
	var prev_fd_target: int = game_state.first_down_target_row_engine
	game_state.apply_ball_movement_tile_delta(int(result.get("tile_delta", 0)))
	var row_after_engine: int = game_state.current_los_row_engine
	var tile_rows_toward_goal: int = row_before_engine - row_after_engine
	var earned_first_down: bool = (not game_state.is_goal_to_go()) and prev_fd_target >= 0 and row_after_engine <= prev_fd_target
	var score_delta_early := int(result.get("score_delta", 0))
	if is_two_point_attempt:
		var z2 := game_state.current_zone
		var conv_lines: Array = [
			{"cat": CALC_LOG_CAT_CONVERSION, "text": "Two-point try succeeds if the ball ends in the scoring endzone (zone index ≥ %d)." % GameState.ZONE_END},
			{"cat": CALC_LOG_CAT_OUTCOME, "text": "After movement, zone is %s (index %d)." % [_zone_name(z2), z2]},
			{"cat": CALC_LOG_CAT_OUTCOME, "text": "Result: %s." % ("GOOD (+2)" if z2 >= GameState.ZONE_END else "NO GOOD")}
		]
		_calc_log_push_slide(_calc_log_slide_title("2-point conversion"), conv_lines)
		_calc_log_commit_snap_bundle_if_active()
		if game_state.current_zone >= GameState.ZONE_END:
			game_state.add_score(game_state.conversion_team, 2)
			_append_event_log("[b]2-Point Conversion GOOD[/b]")
			summary_result_text = "2-Point Conversion GOOD"
			_finish_conversion("two_point_made", true)
			_show_last_play_toast("2-Point Conversion GOOD!", "good")
		else:
			_append_event_log("[b]2-Point Conversion FAILED[/b]")
			summary_result_text = "2-Point Conversion FAILED"
			_finish_conversion("two_point_failed", false)
			_show_last_play_toast("2-Point Conversion FAILED!", "bad")
		game_state.sync_goal_to_go_first_down_after_play()
		_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, tile_rows_toward_goal)
		game_state.pending_play_type = GameState.PENDING_NONE
		_selected_defense_play = ""
		_awaiting_defense_pick = false
		_end_event_log_play_situation()
		_sim_try_pause_step_after_play()
		game_state.emit_signal("state_changed")
		return
	var turnover: Dictionary
	var toe: Variant = result.get("turnover_outcome", null)
	if typeof(toe) == TYPE_DICTIONARY:
		turnover = (toe as Dictionary).duplicate(true)
		if bool(turnover.get("occurred", false)) and int(turnover.get("start_zone", -1)) < 0:
			turnover["start_zone"] = _map_possession_start_zone(game_state.current_zone)
	else:
		turnover = _roll_turnover_if_any(game_state.pending_play_type, int(result.get("tile_delta", 0)))
	var tcalc: Array = turnover.get("calc_lines", []) as Array
	if not tcalc.is_empty():
		_calc_log_push_slide(_calc_log_slide_title("Turnover checks"), tcalc)
	if not _last_skill_proc_text.is_empty():
		_calc_log_push_slide_flat("Skills — procs", [_last_skill_proc_text], CALC_LOG_CAT_SKILLS)
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
			turnover_text = "Turnover forced in %s." % _zone_name(GameState.ZONE_MY_END)
		result_text.text = "[center][color=#ff4444][b]TURNOVER![/b][/color][/center]\n%s%s" % [turnover_text, proc_line]
		summary_result_text = turnover_text
		_append_event_log_play_tile_rows_line(offense_team_for_summary, offense_play_for_summary, tile_rows_toward_goal)
		_append_event_log("[color=#ff6666][b]TURNOVER[/b][/color] %s" % turnover_text)
		if not _last_skill_proc_text.is_empty():
			_append_event_log("[color=#ffd166]%s[/color]" % _last_skill_proc_text)
		if defensive_td:
			var scoring_team := "away" if game_state.possession_team == "home" else "home"
			_game_tds += 1
			game_state.add_score(scoring_team, 6)
			game_state.conversion_pending = true
			game_state.conversion_team = scoring_team
			result_text.text = "[center][color=#ff4444][b]TURNOVER + DEFENSIVE TD![/b][/color][/center]\n%s%s" % [turnover_text, proc_line]
			summary_result_text = "TURNOVER + DEFENSIVE TD"
			_calc_log_push_slide_flat("Outcome — defensive TD (turnover)", [
				"Defense scores in the scoring endzone; +6 to %s pending conversion." % _team_display_name(scoring_team),
			], CALC_LOG_CAT_OUTCOME)
			_calc_log_commit_snap_bundle_if_active()
			_end_event_log_play_situation()
			_begin_post_td_conversion(scoring_team)
			_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, tile_rows_toward_goal)
			_show_last_play_toast("Turnover — Defensive TD!", "bad")
			game_state.pending_play_type = GameState.PENDING_NONE
			_selected_defense_play = ""
			_awaiting_defense_pick = false
			_sim_try_pause_step_after_play()
			game_state.emit_signal("state_changed")
			return
		game_state.pending_play_type = GameState.PENDING_NONE
		_selected_defense_play = ""
		_awaiting_defense_pick = false
		_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, tile_rows_toward_goal)
		_show_last_play_toast("Turnover!", "bad")
		_reset_next_turn_after_possession_change("turnover")
		_end_event_log_play_situation()
		_calc_log_commit_snap_bundle_if_active()
		_sim_try_pause_step_after_play()
		game_state.emit_signal("state_changed")
		return

	var downs_res: int = 0
	var had_first_down: bool = earned_first_down
	var skip_downs := is_two_point_attempt or bool(turnover.get("occurred", false)) or game_state.is_touchdown() or (_pid_bucket(game_state.pending_play_type) == BUCKET_SPOT_KICK and score_delta_early > 0)
	if not skip_downs:
		downs_res = _apply_downs_and_first_down_after_play(row_after_engine, offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, tile_rows_toward_goal, earned_first_down)
		if downs_res == 1:
			_show_last_play_toast("Turnover on Downs — Defensive TD!", "bad")
			_end_event_log_play_situation()
			_calc_log_commit_snap_bundle_if_active()
			_sim_try_pause_step_after_play()
			return

	var score_delta := score_delta_early
	var skip_tile_row_event := false
	if _pid_bucket(game_state.pending_play_type) == BUCKET_SPOT_KICK and score_delta > 0:
		_game_fg_makes += 1
		game_state.add_score(game_state.possession_team, 3)
		_append_event_log("[color=#66ff00][b]Field goal good[/b][/color] +3 — %s." % _team_display_name(offense_team_for_summary))
		skip_tile_row_event = true
		game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
		game_state.end_possession("field_goal", 3)
		_stop_clock("field goal")
	elif _pid_bucket(game_state.pending_play_type) == BUCKET_SPOT_KICK:
		game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
		game_state.end_possession("missed_field_goal", 0)
		_stop_clock("missed FG turnover")
		result_text.text = "[center][color=#ff4444][b]TURNOVER![/b][/color][/center]\nMissed FG. Opponent starts in %s." % _zone_name(game_state.next_drive_start_zone)
		summary_result_text = "Missed Field Goal (Turnover)"
		_append_event_log("[color=#FFFF00][b]Field goal missed[/b][/color] — %s." % _team_display_name(offense_team_for_summary))
		_append_event_log("[color=#ff6666][b]TURNOVER[/b][/color] Missed FG. Opponent starts in %s." % _zone_name(game_state.next_drive_start_zone))
		skip_tile_row_event = true
	elif game_state.is_touchdown():
		_game_tds += 1
		game_state.add_score(game_state.possession_team, 6)
		game_state.conversion_pending = true
		game_state.conversion_team = game_state.possession_team
		game_state.next_drive_start_zone = _map_possession_start_zone(game_state.current_zone)
		game_state.end_possession("touchdown", 6)
		_stop_clock("touchdown")
		_calc_log_push_slide_flat("Outcome — touchdown", [
			"Offensive touchdown for %s (+6, conversion pending)." % _team_display_name(offense_team_for_summary),
			"LOS row after the score (engine): %d." % row_after_engine,
		], CALC_LOG_CAT_OUTCOME)
		_calc_log_commit_snap_bundle_if_active()
		_end_event_log_play_situation()
		_begin_post_td_conversion(game_state.conversion_team)
		game_state.pending_play_type = GameState.PENDING_NONE
		_selected_defense_play = ""
		_awaiting_defense_pick = false
		_show_last_play_toast("Touchdown!", "good")
		_sim_try_pause_step_after_play()
		game_state.emit_signal("state_changed")
		return
	elif game_state.game_time_remaining <= 0:
		game_state.end_game_if_time_up()
	elif downs_res != 2:
		game_state.phase = PHASE_PLAY_SELECTION

	game_state.pending_play_type = GameState.PENDING_NONE
	_selected_defense_play = ""
	_awaiting_defense_pick = false
	game_state.sync_goal_to_go_first_down_after_play()
	_render_last_play_info(offense_team_for_summary, offense_play_for_summary, defense_play_for_summary, summary_result_text, tile_rows_toward_goal)
	if not skip_tile_row_event:
		_append_event_log_play_tile_rows_line(offense_team_for_summary, offense_play_for_summary, tile_rows_toward_goal)
	if had_first_down and not skip_tile_row_event:
		_append_event_log("[color=#2dd4bf][b]First down[/b][/color] — %s." % _team_display_name(offense_team_for_summary))
	if downs_res == 2:
		_append_event_log("[color=#ff6666][b]TURNOVER ON DOWNS[/b][/color] Opponent starts in %s." % _zone_name(game_state.next_drive_start_zone))

	var outcome_lines: Array = [
		{"cat": CALC_LOG_CAT_OUTCOME, "text": "Summary: %s" % summary_result_text},
		{"cat": CALC_LOG_CAT_OUTCOME, "text": "Tile rows toward goal: %+d." % tile_rows_toward_goal},
		{"cat": CALC_LOG_CAT_OUTCOME, "text": "Points from this play’s score bundle: %d." % score_delta},
	]
	if _pid_bucket(offense_play_for_summary) == BUCKET_SPOT_KICK:
		outcome_lines.append({"cat": CALC_LOG_CAT_SPECIAL, "text": "Field goal path: %s." % ("made (+3 possession ends)" if score_delta > 0 else "missed (turnover on miss)")})
	if had_first_down:
		outcome_lines.append({"cat": CALC_LOG_CAT_OUTCOME, "text": "First down earned on this play."})
	if downs_res == 2:
		outcome_lines.append({"cat": CALC_LOG_CAT_OUTCOME, "text": "Turnover on downs — opponent starts in %s." % _zone_name(game_state.next_drive_start_zone)})
	_calc_log_push_slide(_calc_log_slide_title("Outcome — apply play"), outcome_lines)

	_calc_log_commit_snap_bundle_if_active()

	_maybe_toast_after_standard_apply_play(offense_play_for_summary, had_first_down, tile_rows_toward_goal, skip_tile_row_event, downs_res, score_delta)

	if game_state.phase == GameState.PHASE_GAME_OVER:
		_end_event_log_play_situation()
		_sim_try_pause_step_after_play()
		game_state.emit_signal("state_changed")
		return

	if game_state.should_force_halftime_now() and game_state.phase != GameState.PHASE_GAME_OVER:
		_append_phase_subphase("halftime")
		game_state.force_halftime_now()
		_append_touchback_event_log("(halftime, second half).")
		_sim_try_pause_step_after_play()
		_after_force_halftime_second_half()
		_end_event_log_play_situation()
		game_state.emit_signal("state_changed")
		return
	
	print("END PLAY phase=", game_state.phase, " game_over=", game_state.phase == GameState.PHASE_GAME_OVER)
	
	_end_event_log_play_situation()
	_after_play_phase_hooks()
	_sim_try_pause_step_after_play()
	game_state.emit_signal("state_changed")

func _after_play_phase_hooks() -> void:
	# End of resolved play: next play can start with new card phase setup.
	_turn_initialized = false
	if game_state.phase == PHASE_PLAY_SELECTION:
		_play_ready_home = false
		_play_ready_away = false
		_defense_selected_explicit = false
		_selected_defense_play = ""
		_begin_turn_if_needed()
		
	print("AFTER PLAY HOOK -> reset turn init false")

func _kicker_for_fg_attempt() -> Dictionary:
	if not game_state.selected_player_id.is_empty():
		var selected := player_data.get_by_id(game_state.selected_player_id)
		if not selected.is_empty():
			return selected
	var fr := _franchise_id_for_seat(game_state.possession_team)
	var pkg: Dictionary = _match_field_packages.get(fr, {})
	var k: Dictionary = pkg.get("kicker", {})
	if not k.is_empty():
		var kid := str(k.get("id", ""))
		if not kid.is_empty():
			game_state.selected_player_id = kid
		return k
	var best := player_data.get_best_kicker(fr)
	var best_id := str(best.get("id", ""))
	if not best_id.is_empty():
		game_state.selected_player_id = best_id
	return best

func _can_attempt_field_goal_from_current_zone() -> bool:
	if game_state.current_zone == GameState.ZONE_ATTACK or game_state.current_zone == GameState.ZONE_RED:
		return true
	if game_state.current_zone == GameState.ZONE_MIDFIELD:
		var kicker := _kicker_for_fg_attempt()
		return int(kicker.get("kick_power", 5)) > 7
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
	var pb := _pid_bucket(play_type)
	if pb == BUCKET_SPOT_KICK or pb == BUCKET_PUNT:
		var skip_lines: Array = [
			{"cat": CALC_LOG_CAT_TURNOVER, "text": "Turnover checks do not run on field goals / punts in this prototype."}
		]
		return {"occurred": false, "calc_lines": skip_lines}

	var offense_player := _get_offense_ball_carrier(play_type)
	var defense_player := _select_defender_for_play(play_type)
	var off_name: String
	var def_name: String
	if _last_scrimmage_sim_ctx != null:
		off_name = _last_scrimmage_sim_ctx.format_player_slot(
			offense_player,
			_last_scrimmage_sim_ctx.role_for_player_id(str(offense_player.get("id", "")))
		)
		def_name = _last_scrimmage_sim_ctx.format_player_slot(
			defense_player,
			_last_scrimmage_sim_ctx.role_for_player_id(str(defense_player.get("id", "")))
		)
	else:
		off_name = _calc_log_format_player_roster(offense_player)
		def_name = _calc_log_format_player_roster(defense_player)
	var header: Array = [
		{"cat": CALC_LOG_CAT_TURNOVER, "text": "Ball carrier considered: %s. Defender model: %s." % [off_name, def_name]}
	]
	var fumble_roll := _roll_fumble(play_type, offense_player, defense_player)
	var merged: Array = header.duplicate()
	for s in fumble_roll.get("lines", []):
		merged.append({"cat": CALC_LOG_CAT_TURNOVER, "text": str(s)})
	if bool(fumble_roll.get("turnover", false)):
		merged.append({"cat": CALC_LOG_CAT_TURNOVER, "text": "Result: fumble lost — turnover."})
		return {
			"occurred": true,
			"ended_by": "fumble_recovery",
			"start_zone": _map_possession_start_zone(game_state.current_zone),
			"text": "Fumble recovery by defense at %s. Opponent starts in %s." % [_zone_name(game_state.current_zone), _zone_name(_map_possession_start_zone(game_state.current_zone))],
			"calc_lines": merged
		}

	var int_roll := _roll_interception(play_type, offense_player, defense_player, zone_delta)
	for s in int_roll.get("lines", []):
		merged.append({"cat": CALC_LOG_CAT_TURNOVER, "text": str(s)})
	if bool(int_roll.get("turnover", false)):
		merged.append({"cat": CALC_LOG_CAT_TURNOVER, "text": "Result: interception — turnover."})
		return {
			"occurred": true,
			"ended_by": "interception",
			"start_zone": _map_possession_start_zone(game_state.current_zone),
			"text": "Interception at %s. Opponent starts in %s." % [_zone_name(game_state.current_zone), _zone_name(_map_possession_start_zone(game_state.current_zone))],
			"calc_lines": merged
		}

	merged.append({"cat": CALC_LOG_CAT_TURNOVER, "text": "Result: possession kept (no fumble, no interception)."})
	return {"occurred": false, "calc_lines": merged}

func _get_offense_ball_carrier(play_type: String) -> Dictionary:
	if not game_state.selected_player_id.is_empty():
		return player_data.get_by_id(game_state.selected_player_id)
	var fr := _franchise_id_for_seat(game_state.possession_team)
	var pkg: Dictionary = _match_field_packages.get(fr, {})
	var offense_team: Array = pkg.get("off_field", [])
	if offense_team.is_empty():
		offense_team = player_data.get_team(fr)
	if offense_team.is_empty():
		return {}
	if _pid_bucket(play_type) == BUCKET_RUN:
		return offense_team[-1]
	return offense_team[0]


func _select_defender_for_play(play_type: String) -> Dictionary:
	var defense_seat := "away" if game_state.possession_team == "home" else "home"
	var def_fr := _franchise_id_for_seat(defense_seat)
	var pkg: Dictionary = _match_field_packages.get(def_fr, {})
	var defenders: Array = pkg.get("def_field", [])
	if defenders.is_empty():
		defenders = player_data.get_team(def_fr)
	if defenders.is_empty():
		return {}

	var best: Dictionary = defenders[0]
	var best_score: int = -999
	for d in defenders:
		var score := 0
		if _pid_bucket(play_type) == BUCKET_RUN:
			score = _effective_stat(d, "tackling", 5)
		else:
			score = _effective_stat(d, "coverage", 5) + _effective_stat(d, "catching", 5)
		if score > best_score:
			best_score = score
			best = d
	_last_defender_id = str(best.get("id", ""))
	return best

func _roll_fumble(play_type: String, offense: Dictionary, defense: Dictionary) -> Dictionary:
	var base := 4.0 if _pid_bucket(play_type) == BUCKET_RUN else 2.0
	var security := _effective_stat(offense, "carrying", 5)
	var defender_tackling := _effective_stat(defense, "tackling", 5)
	var ball_strip_bonus := _skill_chance_bonus_pct(defense, "ball_stripping", "fumble_forced_pct")
	var big_hit_bonus := _skill_chance_bonus_pct(defense, "big_hit", "fumble_forced_pct")
	var chance := clampf(base + float(defender_tackling - security) * 0.5 + ball_strip_bonus + big_hit_bonus, 1.0, 14.0)
	var proc_labels: Array[String] = []
	if ball_strip_bonus > 0.0:
		proc_labels.append("Ball Stripping")
	if big_hit_bonus > 0.0:
		proc_labels.append("Big Hit")
	if not proc_labels.is_empty():
		_last_skill_proc_text = "Proc: %s" % ", ".join(proc_labels)
	var roll := randf() * 100.0
	var triggered := roll < chance
	var lines: Array[String] = []
	lines.append("Fumble risk: base %.1f%% (%s)." % [base, "run play" if _pid_bucket(play_type) == BUCKET_RUN else "pass play"])
	lines.append("Ball security (offense): %d; defender tackling: %d." % [security, defender_tackling])
	lines.append("Skill chance add-ons (defense): Ball Stripping +%.1f%%, Big Hit +%.1f%%." % [ball_strip_bonus, big_hit_bonus])
	lines.append("Stripped fumble chance after clamp: %.1f%%." % chance)
	lines.append("Roll: %.2f (need roll below %.2f to fumble)." % [roll, chance])
	lines.append("Fumble this play: %s." % ("yes" if triggered else "no"))
	return {"turnover": triggered, "lines": lines}


func _roll_interception(play_type: String, offense: Dictionary, defense: Dictionary, zone_delta: int) -> Dictionary:
	if _pid_bucket(play_type) != BUCKET_PASS:
		return {"turnover": false, "lines": ["Interception check skipped (not a pass play)."]}
	var base := 6.0 if zone_delta >= 8 else 4.0
	var coverage := _effective_stat(defense, "coverage", 5)
	var def_catching := _effective_stat(defense, "catching", 5)
	var off_awareness := _effective_stat(offense, "awareness", 5)
	var off_catching := _effective_stat(offense, "catching", 5)
	var off_passing := _effective_stat(offense, "passing", 5)
	var hawk_bonus := _skill_chance_bonus_pct(defense, "ball_hawk", "interception_pct")
	var frozen_rope_protect := float(_skill_level(offense, "frozen_rope")) * 0.5
	var chance := clampf(base + float((coverage + def_catching) - (off_awareness + off_catching + off_passing)) * 0.35 + hawk_bonus - frozen_rope_protect, 1.0, 16.0)
	var int_proc_labels: Array[String] = []
	if hawk_bonus > 0.0:
		int_proc_labels.append("Ball Hawk")
	if frozen_rope_protect > 0.0:
		int_proc_labels.append("Frozen Rope")
	if not int_proc_labels.is_empty():
		_last_skill_proc_text = "Proc: %s" % ", ".join(int_proc_labels)
	var roll := randf() * 100.0
	var triggered := roll < chance
	var lines: Array[String] = []
	lines.append("Interception base: %.1f%% (long pass bonus uses tile gain toward goal: %d rows this play)." % [base, zone_delta])
	lines.append("Defense coverage %d + hands %d vs offense awareness %d + catch %d + pass %d." % [coverage, def_catching, off_awareness, off_catching, off_passing])
	lines.append("Skill modifiers: Ball Hawk +%.1f%% chance; Frozen Rope −%.1f%%." % [hawk_bonus, frozen_rope_protect])
	lines.append("Pick chance after clamp: %.1f%%." % chance)
	lines.append("Roll: %.2f (need roll below %.2f for interception)." % [roll, chance])
	lines.append("Interception this play: %s." % ("yes" if triggered else "no"))
	return {"turnover": triggered, "lines": lines}

func _effective_stat(player: Dictionary, key: String, fallback: int) -> int:
	var pv := PlayerStatView.from_dict(player)
	var value := 0
	match key:
		"speed":
			value = pv.speed()
		"strength":
			value = pv.strength()
		"stamina":
			value = pv.stamina()
		"awareness":
			value = pv.awareness()
		"acceleration":
			value = pv.acceleration()
		"catching":
			value = pv.catching()
		"carrying":
			value = pv.carrying()
		"ball_security":
			value = pv.carrying()
		"agility":
			value = pv.agility()
		"toughness":
			value = pv.toughness()
		"tackling":
			value = pv.tackling()
		"blocking":
			value = pv.blocking()
		"route_running":
			value = pv.route_running()
		"coverage":
			value = pv.coverage()
		"pass_rush":
			value = pv.pass_rush()
		"block_shedding":
			value = pv.block_shedding()
		"throw_power":
			value = pv.throw_power()
		"throw_accuracy":
			value = pv.throw_accuracy()
		"kick_power":
			value = pv.kick_power()
		"kick_accuracy":
			value = pv.kick_accuracy()
		"passing":
			value = (pv.throw_power() + pv.throw_accuracy()) / 2
		"kick_consistency":
			value = (pv.kick_power() + pv.kick_accuracy()) / 2
		_:
			value = clampi(int(player.get(key, fallback)), 1, 99)
	var skills := _player_skills(player)
	for skill_id in skills.keys():
		var level := clampi(int(skills[skill_id]), 1, 10)
		var def = _skills_db.get(str(skill_id), {})
		if typeof(def) != TYPE_DICTIONARY:
			continue
		var stat_mods: Dictionary = def.get("stat_mods", {})
		for mk in stat_mods.keys():
			if _skill_stat_mod_key_matches(str(mk), key):
				value += int(stat_mods.get(mk, 0)) * level
	return clampi(value, 1, 99)


func _skill_stat_mod_key_matches(mod_key: String, lookup_key: String) -> bool:
	if mod_key == lookup_key:
		return true
	if lookup_key == "passing" and mod_key == "passing":
		return true
	if lookup_key in ["carrying", "ball_security"] and mod_key == "ball_security":
		return true
	return false

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
		var poss_fr := _franchise_id_for_seat(game_state.possession_team)
		var team := str(p.get("team", ""))
		var base_color := Color(0.60, 0.78, 1.0, 1.0) if team == poss_fr else Color(1.0, 0.70, 0.70, 1.0)
		if team == poss_fr:
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
		var picked := false
		for card in queue_hand:
			if typeof(card) != TYPE_DICTIONARY:
				continue
			var cd := card as Dictionary
			if _toggle_selected_card_for_team(queue_team, str(cd.get("instance_id", cd.get("id", "")))):
				result_text.text = "Selected card (%s): %s" % [queue_team, str(cd.get("name", "Card"))]
				_append_event_log("Selected card (%s): %s" % [queue_team, str(cd.get("name", "Card"))])
				picked = true
				break
		if not picked:
			result_text.text = "Not enough Momentum to select a card."
			_append_event_log("Not enough Momentum to select a card.")
			return
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
		game_clock_value_label.text = _format_time(game_state.game_time_remaining)
	half_label.text = "Half: %d" % game_state.half
	if user_team_label:
		user_team_label.text = "You are: %s (%s)" % [_team_display_name(_user_team), _user_team.capitalize()]
	if user_hud:
		user_hud.visible = true
	if opponent_hud:
		opponent_hud.visible = true
	if user_play_buttons:
		user_play_buttons.visible = true
	if opponent_play_buttons:
		opponent_play_buttons.visible = true
	var display_zone := game_state.current_zone
	if game_state.conversion_pending and game_state.phase == PHASE_CONVERSION:
		display_zone = GameState.ZONE_END
	zone_label.text = "Zone: %s" % _zone_display_for_team(display_zone, _user_team)
	if game_state.is_goal_to_go():
		downs_label.text = "Goal to go | Downs: %d" % game_state.downs
	else:
		downs_label.text = "Downs: %d" % game_state.downs
	if play_count_label:
		play_count_label.text = "Plays: %d" % _game_plays
	if user_down_distance_label:
		user_down_distance_label.text = _format_down_and_distance_for_hud()
	var offense_team := game_state.possession_team
	var defense_team := "away" if offense_team == "home" else "home"
	phase_label.text = "Phase: %s (P%d)" % [game_state.phase, current_phase_level]
	var bar_phase := game_state.phase == PHASE_PLAY_SELECTION or game_state.phase == PHASE_CARD_QUEUE
	var play_clock_visible := show_action_timer_bar and _turn_action_timer_active and bar_phase
	var bar_draw_visible := play_clock_visible
	if play_clock_value_label:
		play_clock_value_label.visible = false
	if action_timer_progress_bar:
		action_timer_progress_bar.visible = bar_draw_visible
		if bar_draw_visible and _current_action_window_duration > 0.0:
			action_timer_progress_bar.value = clampf(_turn_action_time_remaining / _current_action_window_duration, 0.0, 1.0) * action_timer_progress_bar.max_value
		elif bar_draw_visible:
			action_timer_progress_bar.value = 0.0
	if show_action_timer_bar_toggle:
		show_action_timer_bar_toggle.set_pressed_no_signal(show_action_timer_bar)

	var user_team := _user_team
	var opponent_team := "away" if user_team == "home" else "home"
	if user_possession_icon_label:
		var show_u := game_state.possession_team == user_team
		user_possession_icon_label.modulate.a = 1.0 if show_u else 0.0
	if opponent_possession_icon_label:
		var show_o := game_state.possession_team == opponent_team
		opponent_possession_icon_label.modulate.a = 1.0 if show_o else 0.0
	if user_play_row_possession_icon:
		user_play_row_possession_icon.text = "🏈" if game_state.possession_team == user_team else "🛡️"
		user_play_row_possession_icon.modulate.a = 1.0
	_sync_selected_cards_with_hand("home")
	_sync_selected_cards_with_hand("away")
	if user_score_value_label:
		user_score_value_label.text = "%d" % (game_state.score_home if user_team == "home" else game_state.score_away)
	if opponent_score_value_label:
		opponent_score_value_label.text = "%d" % (game_state.score_home if opponent_team == "home" else game_state.score_away)
	if opponent_momentum_value_label:
		var opp_momentum := game_state.momentum_away if opponent_team == "away" else game_state.momentum_home
		if game_state.phase == PHASE_CARD_QUEUE:
			opp_momentum = _remaining_momentum_for_team(opponent_team)
		opponent_momentum_value_label.text = "%d" % opp_momentum
	if user_momentum_value_label:
		var user_momentum := game_state.momentum_home if user_team == "home" else game_state.momentum_away
		if game_state.phase == PHASE_CARD_QUEUE:
			user_momentum = _remaining_momentum_for_team(user_team)
		user_momentum_value_label.text = "%d" % user_momentum
	if opponent_tos_button:
		var opp_tos := game_state.timeouts_away if opponent_team == "away" else game_state.timeouts_home
		opponent_tos_button.text = "%d" % opp_tos
		opponent_tos_button.disabled = true
	if user_tos_button:
		var user_tos := game_state.timeouts_home if user_team == "home" else game_state.timeouts_away
		user_tos_button.text = "(%d)" % user_tos
		user_tos_button.disabled = user_tos <= 0
	if user_forfeit_button:
		user_forfeit_button.disabled = game_state.phase == GameState.PHASE_GAME_OVER
	var opp_hand_n := game_state.hand_away.size() if opponent_team == "away" else game_state.hand_home.size()
	var opp_selected_n := (_selected_cards_away.size() if opponent_team == "away" else _selected_cards_home.size()) if game_state.phase == PHASE_CARD_QUEUE else 0
	opponent_hand_label.text = "Hand (%d)\nSelected (%d)" % [opp_hand_n, opp_selected_n]

	var user_hand_n := game_state.hand_home.size() if user_team == "home" else game_state.hand_away.size()
	var user_selected_n := (_selected_cards_home.size() if user_team == "home" else _selected_cards_away.size()) if game_state.phase == PHASE_CARD_QUEUE else 0
	user_hand_label.text = "Hand (%d)" % user_hand_n
	if user_queued_label:
		user_queued_label.text = "Selected (%d)" % user_selected_n
	_rebuild_user_card_tiles()
	if game_state.phase == PHASE_CARD_QUEUE:
		phase_label.text = "Phase: %s (cards — 10s)" % game_state.phase
	elif game_state.phase == PHASE_PLAY_SELECTION:
		if game_state.pending_play_type == PLAY_NONE():
			phase_label.text = "Phase: play_selection (offense — 10s)"
		else:
			phase_label.text = "Phase: play_selection (defense — 10s)"
	elif game_state.phase == PHASE_CONVERSION:
		if game_state.conversion_type.is_empty():
			phase_label.text = "Phase: conversion (choose XP or 2PT)"
		else:
			phase_label.text = "Phase: conversion (%s)" % game_state.conversion_type

	if user_phase_prompt_panel and user_phase_prompt_label:
		if game_state.phase == PHASE_CARD_QUEUE:
			user_phase_prompt_panel.visible = true
			user_phase_prompt_label.text = "Select Card(s)"
		elif game_state.phase == PHASE_PLAY_SELECTION:
			user_phase_prompt_panel.visible = true
			user_phase_prompt_label.text = "Select Play"
		else:
			user_phase_prompt_panel.visible = false

	for team in ["away", "home"]:
		var row := _play_buttons_for_team(team)
		var row_container: Control = row.get("container") as Control
		var row_run: Button = row.get("run") as Button
		var row_pass: Button = row.get("pass") as Button
		var row_fg: Button = row.get("fg") as Button
		var row_punt: Button = row.get("punt") as Button
		var row_ready: Button = row.get("ready") as Button
		var row_xp: Button = row.get("xp") as Button
		var row_two: Button = row.get("two") as Button

		var is_offense_row: bool = team == offense_team
		var is_defense_row: bool = team == defense_team
		var ai_controls_now: bool = _is_ai_controlled_team(team, true)
		var in_play_selection: bool = game_state.phase == PHASE_PLAY_SELECTION
		var in_two_point_play_pick: bool = game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT
		var can_offense_pick := in_play_selection and is_offense_row
		var can_defense_pick := in_play_selection and is_defense_row and game_state.pending_play_type != PLAY_NONE()
		var can_choose_play: bool = (can_offense_pick or can_defense_pick) or (in_two_point_play_pick and is_offense_row)

		if row_run:
			row_run.text = "Run Def" if is_defense_row else "Run"
			row_run.disabled = not can_choose_play
		if row_pass:
			row_pass.text = "Pass Def" if is_defense_row else "Pass"
			row_pass.disabled = not can_choose_play
		if row_fg:
			if is_defense_row and _pid_bucket(game_state.pending_play_type) == BUCKET_PUNT:
				row_fg.text = "Punt Return"
			else:
				row_fg.text = "FG Def" if is_defense_row else "Field Goal"
			if is_defense_row:
				row_fg.disabled = not can_choose_play
			elif can_choose_play:
				row_fg.disabled = not (current_phase_level >= 2 and _can_attempt_field_goal_from_current_zone())
				if game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT:
					row_fg.disabled = true
			else:
				row_fg.disabled = true
		if row_punt:
			row_punt.text = "Punt"
			row_punt.visible = not is_defense_row
			row_punt.disabled = not (in_play_selection and is_offense_row)

		var row_is_ready: bool = game_state.home_ready if team == "home" else game_state.away_ready
		if row_ready:
			if game_state.phase == PHASE_CARD_QUEUE:
				row_ready.text = "Ready"
				row_ready.disabled = ai_controls_now or row_is_ready
			elif game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_XP and team == game_state.conversion_team:
				row_ready.text = "Ready"
				row_ready.disabled = true
			elif game_state.phase == PHASE_PLAY_SELECTION:
				if team == offense_team or team == defense_team:
					row_ready.text = "Ready"
					var has_tentative := false
					if team == offense_team:
						has_tentative = _offense_play_tentative != GameState.PENDING_NONE
					else:
						has_tentative = not _defense_play_tentative.is_empty()
					if team == offense_team:
						row_ready.disabled = ai_controls_now or not has_tentative
					else:
						row_ready.disabled = ai_controls_now or game_state.pending_play_type == PLAY_NONE() or not has_tentative
				else:
					row_ready.text = "Ready"
					row_ready.disabled = true
			else:
				row_ready.text = "Ready"
				row_ready.disabled = true
		if row_xp:
			row_xp.visible = game_state.phase == PHASE_CONVERSION and game_state.conversion_type.is_empty() and team == game_state.conversion_team
			row_xp.disabled = not row_xp.visible
		if row_two:
			row_two.visible = game_state.phase == PHASE_CONVERSION and game_state.conversion_type.is_empty() and team == game_state.conversion_team
			row_two.disabled = not row_two.visible
		if ai_controls_now:
			if row_run:
				row_run.disabled = true
			if row_pass:
				row_pass.disabled = true
			if row_fg:
				row_fg.disabled = true
			if row_punt:
				row_punt.disabled = true
			if row_ready:
				row_ready.disabled = true
			if row_xp:
				row_xp.disabled = true
			if row_two:
				row_two.disabled = true
	targeting_panel.visible = current_phase_level >= 4
	if cards_panel and not cards_panel.visible:
		card_panel.visible = false
	_update_staff_ui()
	_update_field_ball_marker()
	_refresh_formation_preview()
	_update_token_visuals()
	_sync_game_clock_scrimmage_policy()
	_update_sim_ui()
	_maybe_run_ai_inputs(_sim_running)

func _begin_targeted_card(card: Dictionary) -> void:
	_pending_target_card = card
	var context := {
		"my_team_players": player_data.get_team(_franchise_id_for_seat(game_state.possession_team)),
		"opponent_players": player_data.get_team(_franchise_id_for_seat("away" if game_state.possession_team == "home" else "home")),
		"staff": {
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
		"speed", "strength", "stamina", "awareness", "acceleration", "catching", "carrying", "agility",
		"toughness", "tackling", "throw_power", "throw_accuracy", "blocking", "route_running",
		"pass_rush", "coverage", "block_shedding", "kick_power", "kick_accuracy"
	]
	var stat_lines: Array[String] = []
	for key in baseline_keys:
		var base := int(p.get(key, 0))
		if base <= 0:
			base = 5
		var eff := _effective_stat(p, key, base)
		if eff != base:
			stat_lines.append("%s: %d (%+d)" % [key, eff, eff - base])
		else:
			stat_lines.append("%s: %d" % [key, base])

	var fumble_force_bonus := _skill_chance_bonus_pct(p, "ball_stripping", "fumble_forced_pct") + _skill_chance_bonus_pct(p, "big_hit", "fumble_forced_pct")
	var int_bonus := _skill_chance_bonus_pct(p, "ball_hawk", "interception_pct")
	var frozen_rope_bonus := float(_skill_level(p, "frozen_rope")) * 1.0

	player_details_label.text = "Name: %s\nTeam: %s\n\nSkills: %s\n\n%s\n\nDerived:\nFumble Force Bonus: +%.1f%%\nInterception Bonus: +%.1f%%\nFrozen Rope Passing Bonus: +%.1f" % [
		PlayerStatView.display_name_from_dict(p),
		str(p.get("team", "unknown")),
		skills_text,
		"\n".join(stat_lines),
		fumble_force_bonus,
		int_bonus,
		frozen_rope_bonus
	]

func _format_bracketed_event_log_situation(snap_down: int, snap_los_engine: int, snap_fd_target: int, snap_goal_to_go: bool) -> String:
	var d := clampi(snap_down, 1, 4)
	var ord := "1st"
	if d == 2:
		ord = "2nd"
	elif d == 3:
		ord = "3rd"
	elif d == 4:
		ord = "4th"
	var dist_str := "Goal" if snap_goal_to_go else str(maxi(0, snap_los_engine - snap_fd_target))
	var pr := snap_los_engine
	if field_grid:
		pr = field_grid.perspective_row(snap_los_engine, game_state.possession_team == "home")
	var mid := FieldGrid.TOTAL_ROWS / 2
	var arrow := "⬇️" if pr > mid else "⬆️"
	return "[%s & %s from %d%s] " % [ord, dist_str, pr, arrow]


func _begin_event_log_play_situation(snap_down: int, snap_los_engine: int, snap_fd_target: int, snap_goal_to_go: bool) -> void:
	_event_log_play_situation_prefix = _format_bracketed_event_log_situation(snap_down, snap_los_engine, snap_fd_target, snap_goal_to_go)


func _end_event_log_play_situation() -> void:
	_event_log_play_situation_prefix = ""


func _format_down_and_distance_for_hud() -> String:
	if game_state.phase == GameState.PHASE_GAME_OVER or game_state.phase == GameState.PHASE_HALFTIME:
		return "—"
	if game_state.phase == PHASE_CONVERSION and game_state.conversion_type.is_empty():
		return "—"
	if game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_XP:
		return "Extra point"
	var d := clampi(game_state.downs, 1, 4)
	var ord := "1st"
	if d == 2:
		ord = "2nd"
	elif d == 3:
		ord = "3rd"
	elif d == 4:
		ord = "4th"
	if game_state.is_goal_to_go() or game_state.first_down_target_row_engine < 0:
		return "%s and Goal" % ord
	var rows_left := game_state.current_los_row_engine - game_state.first_down_target_row_engine
	return "%s and %d" % [ord, maxi(0, rows_left)]

func _format_down_label(down: int) -> String:
	var n := clampi(down, 1, 4)
	if n == 1:
		return "1st Down"
	if n == 2:
		return "2nd Down"
	if n == 3:
		return "3rd Down"
	return "4th Down"

func _calc_log_localize_team_tokens_in_text(s: String) -> String:
	if s.is_empty():
		return s
	if _calc_log_re_side_home == null or _calc_log_re_side_away == null:
		return s
	var hn := _team_display_name("home")
	var an := _team_display_name("away")
	var t := _calc_log_re_side_home.sub(s, hn, true)
	t = _calc_log_re_side_away.sub(t, an, true)
	return t


func _calc_log_format_player_roster(p: Dictionary) -> String:
	if p.is_empty():
		return "(none)"
	var tk := str(p.get("team", ""))
	var tn := _franchise_display_name_from_id(tk)
	var nm := PlayerStatView.display_name_from_dict(p)
	return "%s · %s (%s)" % [tn, nm, str(p.get("id", "?"))]


func _calc_log_begin_snap_bundle() -> void:
	if _calc_log_snap_bundle_active:
		return
	_calc_log_snap_bundle_active = true
	_calc_log_snap_lines.clear()
	_calc_log_snap_seen_cards = false
	_calc_log_snap_bundle_title = _calc_log_next_title("Play snap")


func _calc_log_commit_snap_bundle_if_active() -> void:
	if not _calc_log_snap_bundle_active:
		return
	_calc_log_snap_bundle_active = false
	_calc_log_snap_seen_cards = false
	if _calc_log_snap_lines.is_empty():
		_calc_log_refresh_view()
		return
	_calc_log_entries.append({"title": _calc_log_snap_bundle_title, "lines": _calc_log_snap_lines.duplicate(true)})
	_calc_log_snap_lines.clear()
	_calc_log_snap_bundle_title = ""
	_calc_log_index = _calc_log_entries.size() - 1
	_calc_log_refresh_view()


func _calc_log_snap_append_separator_gated(plain_label: String, gate_line_objs: Array) -> void:
	var txt := "[i]── %s ──[/i]" % plain_label
	var cats: Array[String] = []
	for lo in gate_line_objs:
		if typeof(lo) != TYPE_DICTIONARY:
			continue
		var c := str((lo as Dictionary).get("cat", CALC_LOG_CAT_RESOLVER))
		var found := false
		for ex in cats:
			if ex == c:
				found = true
				break
		if not found:
			cats.append(c)
	_calc_log_snap_lines.append({
		"text": _calc_log_localize_team_tokens_in_text(txt),
		"sep_gate_cats": cats,
		"cat": cats[0] if cats.size() > 0 else CALC_LOG_CAT_RESOLVER,
	})


func _calc_log_snap_append_separator(plain_label: String, cat: String) -> void:
	_calc_log_snap_append_separator_gated(plain_label, [{"cat": cat}])


func _calc_log_snap_append_line_objs(line_objs: Array) -> void:
	for lo in line_objs:
		if typeof(lo) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = (lo as Dictionary).duplicate(true)
		d["text"] = _calc_log_localize_team_tokens_in_text(str(d.get("text", "")))
		_calc_log_snap_lines.append(d)


func _calc_log_snap_append_flat_lines(texts: Array, cat: String) -> void:
	for t in texts:
		_calc_log_snap_lines.append({"cat": cat, "text": _calc_log_localize_team_tokens_in_text(str(t))})


func _calc_log_snap_append_section(plain_title: String, texts: Array, cat: String) -> void:
	_calc_log_snap_append_separator(plain_title, cat)
	_calc_log_snap_append_flat_lines(texts, cat)


func _calc_log_cat_enabled(cat: String) -> bool:
	if cat == CALC_LOG_CAT_RESOLVER or cat == CALC_LOG_CAT_POST:
		var r := calc_filter_resolver
		var p := calc_filter_post
		if r == null and p == null:
			return true
		var r_on := r == null or r.button_pressed
		var p_on := p == null or p.button_pressed
		return r_on or p_on
	var b: CheckButton = null
	match cat:
		CALC_LOG_CAT_OUTCOME:
			b = calc_filter_outcome
		CALC_LOG_CAT_TURNOVER:
			b = calc_filter_turnover
		CALC_LOG_CAT_CARDS:
			b = calc_filter_cards
		CALC_LOG_CAT_SKILLS:
			b = calc_filter_skills
		CALC_LOG_CAT_SPECIAL:
			b = calc_filter_special
		CALC_LOG_CAT_CONVERSION:
			b = calc_filter_conversion
		_:
			return true
	return b == null or b.button_pressed


func _calc_log_sep_gate_any_enabled(gate_cats: Variant) -> bool:
	if typeof(gate_cats) != TYPE_ARRAY:
		return false
	for x in gate_cats as Array:
		if _calc_log_cat_enabled(str(x)):
			return true
	return false


func _calc_log_line_passes_category_filter(d: Dictionary) -> bool:
	return _calc_log_cat_enabled(str(d.get("cat", CALC_LOG_CAT_RESOLVER)))


func _calc_log_clear() -> void:
	_calc_log_snap_bundle_active = false
	_calc_log_snap_lines.clear()
	_calc_log_snap_bundle_title = ""
	_calc_log_snap_seen_cards = false
	_calc_log_entries.clear()
	_calc_log_index = -1
	_calc_log_seq = 0
	_last_scrimmage_sim_ctx = null
	_calc_log_refresh_view()


func _calc_log_next_title(prefix: String) -> String:
	_calc_log_seq += 1
	return "#%d — %s" % [_calc_log_seq, prefix]


func _calc_log_slide_title(plain_prefix: String) -> String:
	return plain_prefix if _calc_log_snap_bundle_active else _calc_log_next_title(plain_prefix)


func _calc_log_push_slide(title: String, line_objs: Array) -> void:
	var processed: Array = []
	for lo in line_objs:
		if typeof(lo) != TYPE_DICTIONARY:
			continue
		var d: Dictionary = (lo as Dictionary).duplicate(true)
		d["text"] = _calc_log_localize_team_tokens_in_text(str(d.get("text", "")))
		processed.append(d)
	if _calc_log_snap_bundle_active:
		if not processed.is_empty():
			var label := title
			if title.contains(" — "):
				label = title.get_slice(" — ", 1)
			_calc_log_snap_append_separator_gated(label, processed)
			_calc_log_snap_append_line_objs(processed)
		_calc_log_refresh_view()
		return
	_calc_log_entries.append({"title": title, "lines": processed})
	_calc_log_index = _calc_log_entries.size() - 1
	_calc_log_refresh_view()


func _calc_log_push_slide_flat(plain_title: String, texts: Array, cat: String) -> void:
	var full_title := _calc_log_slide_title(plain_title)
	var line_objs: Array = []
	for t in texts:
		line_objs.append({"cat": cat, "text": _calc_log_localize_team_tokens_in_text(str(t))})
	_calc_log_push_slide(full_title, line_objs)


func _calc_log_push_breakdown_slide(plain_title: String, result: Dictionary) -> void:
	var bd: Array = result.get("breakdown", []) as Array
	var line_objs: Array = []
	for s in bd:
		var st := _calc_log_localize_team_tokens_in_text(str(s))
		line_objs.append({"cat": CALC_LOG_CAT_RESOLVER, "text": st})
	var full_title := _calc_log_slide_title(plain_title)
	_calc_log_push_slide(full_title, line_objs)


func _calc_log_refresh_view() -> void:
	if calc_log_index_label:
		var n := _calc_log_entries.size()
		if n == 0 or _calc_log_index < 0:
			calc_log_index_label.text = "— / —"
		else:
			calc_log_index_label.text = "%d / %d" % [_calc_log_index + 1, n]
	if calc_log_prev_button:
		calc_log_prev_button.disabled = _calc_log_index <= 0
	if calc_log_next_nav_button:
		calc_log_next_nav_button.disabled = _calc_log_index < 0 or _calc_log_index >= _calc_log_entries.size() - 1
	if calc_log_text == null:
		return
	if _calc_log_entries.is_empty():
		calc_log_text.text = "[i]%s[/i]" % CALC_LOG_PLACEHOLDER
		return
	var idx := clampi(_calc_log_index, 0, _calc_log_entries.size() - 1)
	var entry: Dictionary = _calc_log_entries[idx]
	var title := str(entry.get("title", "Entry"))
	var lines_raw: Array = entry.get("lines", []) as Array
	var shown: Array[String] = []
	var i := 0
	while i < lines_raw.size():
		var lo = lines_raw[i]
		if typeof(lo) != TYPE_DICTIONARY:
			i += 1
			continue
		var d := lo as Dictionary
		if d.has("sep_gate_cats"):
			if not _calc_log_sep_gate_any_enabled(d.get("sep_gate_cats", [])):
				i += 1
				continue
			var j := i + 1
			var has_visible := false
			while j < lines_raw.size():
				var lo2 = lines_raw[j]
				if typeof(lo2) != TYPE_DICTIONARY:
					j += 1
					continue
				var d2 := lo2 as Dictionary
				if d2.has("sep_gate_cats"):
					break
				if _calc_log_line_passes_category_filter(d2):
					has_visible = true
					break
				j += 1
			if has_visible:
				shown.append(str(d.get("text", "")))
			i += 1
			continue
		if _calc_log_line_passes_category_filter(d):
			shown.append(str(d.get("text", "")))
		i += 1
	var body := "\n".join(shown)
	if body.strip_edges().is_empty():
		body = CALC_LOG_PLACEHOLDER
	calc_log_text.text = "[b]%s[/b]\n\n%s" % [title, body]


func _on_calc_log_prev_pressed() -> void:
	if _calc_log_index > 0:
		_calc_log_index -= 1
		_calc_log_refresh_view()


func _on_calc_log_next_nav_pressed() -> void:
	if _calc_log_index < _calc_log_entries.size() - 1:
		_calc_log_index += 1
		_calc_log_refresh_view()


func _on_calc_filter_toggled(_pressed: bool) -> void:
	_calc_log_refresh_view()


func _append_event_log(message: String) -> void:
	if message.is_empty():
		return
	var ts := _format_time(game_state.game_time_remaining)
	var team_label := _team_display_name(game_state.possession_team)
	var prefix_part := ""
	if not _event_log_play_situation_prefix.is_empty():
		prefix_part = _event_log_play_situation_prefix
	elif _turn_initialized and game_state.phase != GameState.PHASE_GAME_OVER and game_state.phase != GameState.PHASE_HALFTIME:
		prefix_part = "[%s] " % _format_down_label(_play_down_at_snap)
	_event_log_lines.append("[%s] (%s) %s%s" % [ts, team_label, prefix_part, message])
	if _event_log_lines.size() > MAX_EVENT_LOG_LINES:
		_event_log_lines = _event_log_lines.slice(_event_log_lines.size() - MAX_EVENT_LOG_LINES, _event_log_lines.size())
	if event_log_text:
		event_log_text.text = "\n".join(_event_log_lines)


func _append_event_log_play_tile_rows_line(offense_team: String, offense_play_id: String, tile_rows: int) -> void:
	_append_event_log("%s (%s): [b]%+d tile rows[/b] toward goal." % [
		_team_display_name(offense_team),
		_friendly_play_name(offense_play_id, false),
		tile_rows,
	])


func _append_touchback_event_log(suffix: String) -> void:
	_append_event_log("[color=#4da3ff][b]Touchback[/b][/color] %s" % suffix)
	_calc_log_push_slide_flat("Touchback", [
		"Receiving team spots the ball at touchback row %d (engine)." % GameState.TOUCHBACK_LOS_ROW_ENGINE,
		"Context: %s" % suffix.strip_edges(),
	], CALC_LOG_CAT_SPECIAL)


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
	var user_sel_n := _selected_cards_home.size() if _user_team == "home" else _selected_cards_away.size()
	var opp_sel_n := _selected_cards_away.size() if _user_team == "home" else _selected_cards_home.size()
	return "poss=%s | zone=%s | game=%s | play=%ss | off=%s | def=%s | sel(U/O)=%d/%d" % [poss, zone, gclock, pclock, off_play, def_play, user_sel_n, opp_sel_n]

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
	_selected_defense_play = ""
	_defense_selected_explicit = false
	_awaiting_defense_pick = false
	_play_ready_home = false
	_play_ready_away = false
	_offense_play_tentative = GameState.PENDING_NONE
	_defense_play_tentative = ""
	_play_pick_window = "offense"
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
	if user_score_value_label:
		user_score_value_label.add_theme_color_override("font_color", user_primary)
	if user_momentum_value_label:
		user_momentum_value_label.add_theme_color_override("font_color", user_secondary)
	if user_tos_button:
		user_tos_button.add_theme_color_override("font_color", user_secondary)
		user_tos_button.add_theme_color_override("font_hover_color", user_secondary)
		user_tos_button.add_theme_color_override("font_disabled_color", user_accent)
		user_tos_button.add_theme_color_override("icon_normal_color", user_secondary)
		user_tos_button.add_theme_color_override("icon_hover_color", user_secondary)
		user_tos_button.add_theme_color_override("icon_disabled_color", user_accent)

	var opp_primary := _team_color(opponent_team, "primary", DEFAULT_PRIMARY)
	var opp_secondary := _team_color(opponent_team, "secondary", DEFAULT_SECONDARY)
	if opponent_team_name_value_label:
		opponent_team_name_value_label.text = _team_display_name(opponent_team)
		opponent_team_name_value_label.add_theme_color_override("font_color", opp_primary)
	if opponent_score_value_label:
		opponent_score_value_label.add_theme_color_override("font_color", opp_primary)
	if opponent_momentum_value_label:
		opponent_momentum_value_label.add_theme_color_override("font_color", opp_secondary)
	if opponent_tos_button:
		opponent_tos_button.add_theme_color_override("font_color", opp_secondary)


func _ensure_formation_preview_layer() -> void:
	if _formation_preview_root != null:
		return
	if field_grid == null:
		return
	_formation_preview_root = Node2D.new()
	_formation_preview_root.name = "FormationPreview"
	_formation_preview_root.z_index = 40
	(field_grid as Node).add_child(_formation_preview_root)


func _preview_los_engine_row() -> int:
	var r := game_state.current_los_row_engine
	if game_state.conversion_pending and game_state.phase == PHASE_CONVERSION:
		r = game_state.los_row_engine_from_zone(GameState.ZONE_END)
	return r


func _preview_visible_play_ids_for_viewer(viewer_team: String) -> Dictionary:
	var offense_play := ""
	var defense_play := ""
	var offense_team := game_state.possession_team
	var defense_team := "away" if offense_team == "home" else "home"
	if game_state.phase == PHASE_RESOLVING:
		if game_state.pending_play_type != GameState.PENDING_NONE:
			offense_play = game_state.pending_play_type
		if _defense_selected_explicit:
			defense_play = _selected_defense_play
		return {"offense_play": offense_play, "defense_play": defense_play}
	if game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT:
		if game_state.pending_play_type != GameState.PENDING_NONE:
			offense_play = game_state.pending_play_type
		if _defense_selected_explicit:
			defense_play = _selected_defense_play
		return {"offense_play": offense_play, "defense_play": defense_play}
	if game_state.phase != PHASE_PLAY_SELECTION and game_state.phase != PHASE_CARD_QUEUE:
		return {"offense_play": "", "defense_play": ""}
	if game_state.pending_play_type != GameState.PENDING_NONE:
		offense_play = game_state.pending_play_type
	elif viewer_team == offense_team and _offense_play_tentative != GameState.PENDING_NONE:
		offense_play = _offense_play_tentative
	if _defense_selected_explicit:
		defense_play = _selected_defense_play
	elif viewer_team == defense_team and not _defense_play_tentative.is_empty():
		defense_play = _defense_play_tentative
	return {"offense_play": offense_play, "defense_play": defense_play}

func _should_show_formation_preview() -> bool:
	if field_grid == null:
		return false
	if game_state.phase == GameState.PHASE_GAME_OVER or game_state.phase == GameState.PHASE_HALFTIME:
		return false
	if game_state.phase == PHASE_CONVERSION and game_state.conversion_type.is_empty():
		return false
	var visible := _preview_visible_play_ids_for_viewer(_user_team)
	return not str(visible.get("offense_play", "")).is_empty() or not str(visible.get("defense_play", "")).is_empty()


func _preview_display_row_for_defense(global_row: int, offense_is_home: bool) -> int:
	var d := int(field_grid.call("perspective_row", global_row, offense_is_home))
	var user_on_offense := _user_team == game_state.possession_team
	var adj := -1 if user_on_offense else 1
	return clampi(d + adj, 0, FieldGrid.TOTAL_ROWS - 1)


func _formation_marker_specs_from_play(play_id: String, los_eng: int, offense_home: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if play_id.is_empty() or _plays_catalog == null or _formations_catalog == null or field_grid == null:
		return out
	var fid := _plays_catalog.formation_id_for(play_id)
	if fid.is_empty():
		return out
	var f: Dictionary = _formations_catalog.get_by_id(fid)
	if f.is_empty():
		return out
	var pos_arr: Variant = f.get("positions", [])
	if typeof(pos_arr) != TYPE_ARRAY:
		return out
	var side := str(f.get("side", "offense"))
	var is_sq := side == "defense"
	for p in pos_arr:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = p
		var role := str(pd.get("role", ""))
		var drow := int(pd.get("delta_row", 0))
		var dcol := int(pd.get("delta_col", 0))
		var td: Dictionary = field_grid.call("tile_data_from_los", los_eng, drow, dcol, 3) as Dictionary
		var g_row := int(td.get("global_row", 0))
		var g_col := int(td.get("col", 0))
		var disp_r: int
		if is_sq:
			disp_r = _preview_display_row_for_defense(g_row, offense_home)
		else:
			disp_r = int(field_grid.call("perspective_row", g_row, offense_home))
			disp_r = clampi(disp_r, 0, FieldGrid.TOTAL_ROWS - 1)
		var w: Vector2 = field_grid.call("world_pos_from_tile", disp_r, g_col) as Vector2
		out.append({"world": w, "sq": is_sq, "role": role, "dr": disp_r, "gc": g_col})
	return out


func _apply_intragroup_fanout(specs: Array[Dictionary]) -> void:
	var groups: Dictionary = {}
	for i in range(specs.size()):
		var m: Dictionary = specs[i]
		var k := "%d:%d:%s" % [int(m["dr"]), int(m["gc"]), "d" if bool(m["sq"]) else "o"]
		if not groups.has(k):
			groups[k] = []
		(groups[k] as Array).append(i)
	for k in groups.keys():
		var idxs: Array = groups[k] as Array
		if idxs.size() <= 1:
			continue
		var step := 9.0
		var start := -0.5 * step * float(idxs.size() - 1)
		for j in range(idxs.size()):
			var ii := int(idxs[j])
			var mm: Dictionary = specs[ii]
			var wv: Vector2 = mm["world"]
			mm["world"] = wv + Vector2(start + step * float(j), 0.0)


func _separate_offense_defense(specs: Array[Dictionary]) -> void:
	for _iter in range(6):
		var changed := false
		for i in range(specs.size()):
			var di: Dictionary = specs[i]
			if not bool(di["sq"]):
				continue
			for j in range(specs.size()):
				var oj: Dictionary = specs[j]
				if bool(oj["sq"]):
					continue
				var dv: Vector2 = di["world"]
				var ov: Vector2 = oj["world"]
				if dv.distance_to(ov) >= 22.0:
					continue
				var push: Vector2 = dv - ov
				if push.length_squared() < 0.0001:
					push = Vector2(1, 0)
				else:
					push = push.normalized()
				di["world"] = dv + push * 4.5
				changed = true
		if not changed:
			break


func _make_preview_marker_ui(world_center: Vector2, role: String, is_square: bool) -> void:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size = PREVIEW_MARKER_SIZE
	p.size = PREVIEW_MARKER_SIZE
	p.position = world_center - PREVIEW_MARKER_SIZE * 0.5
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.92) if not is_square else Color(0.82, 0.12, 0.12, 0.92)
	if is_square:
		sb.set_corner_radius_all(2)
	else:
		sb.set_corner_radius_all(13)
	p.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = role
	lbl.custom_minimum_size = PREVIEW_MARKER_SIZE
	lbl.size = PREVIEW_MARKER_SIZE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", PREVIEW_MARKER_FONT)
	lbl.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05, 1.0) if not is_square else Color(1, 1, 1, 1))
	p.add_child(lbl)
	_formation_preview_root.add_child(p)


func _refresh_formation_preview() -> void:
	_ensure_formation_preview_layer()
	if _formation_preview_root == null:
		return
	for c in _formation_preview_root.get_children():
		c.queue_free()
	if not _should_show_formation_preview():
		return
	if _formations_catalog == null or _plays_catalog == null or field_grid == null:
		return
	var los_eng := _preview_los_engine_row()
	var offense_home := game_state.possession_team == "home"
	var specs: Array[Dictionary] = []
	var visible := _preview_visible_play_ids_for_viewer(_user_team)
	var offense_play := str(visible.get("offense_play", ""))
	var defense_play := str(visible.get("defense_play", ""))
	if not offense_play.is_empty():
		specs.append_array(_formation_marker_specs_from_play(offense_play, los_eng, offense_home))
	if not defense_play.is_empty():
		specs.append_array(_formation_marker_specs_from_play(defense_play, los_eng, offense_home))
	if specs.is_empty():
		return
	_apply_intragroup_fanout(specs)
	_separate_offense_defense(specs)
	for m in specs:
		_make_preview_marker_ui(m["world"] as Vector2, str(m["role"]), bool(m["sq"]))


func _format_time(seconds_total: int) -> String:
	var m := seconds_total / 60
	var s := seconds_total % 60
	return "%d:%02d" % [m, s]

func _tile_data_from_los(los_row: int, row_offset: int, col_offset: int, base_col: int = 3) -> Dictionary:
	if field_grid == null:
		return {}
	return field_grid.call("tile_data_from_los", los_row, row_offset, col_offset, base_col)

func _tile_world_pos(global_row: int, col: int, offense_is_home: bool = true) -> Vector2:
	if field_grid == null:
		return Vector2.ZERO
	var row_for_perspective: int = int(field_grid.call("perspective_row", global_row, offense_is_home))
	return field_grid.call("world_pos_from_tile", row_for_perspective, col)

func _tiles_per_step_for_speed(speed: float) -> int:
	if field_grid == null:
		return 1
	return int(field_grid.call("tiles_per_step_from_speed", speed))

func _update_field_ball_marker() -> void:
	var zone := clampi(game_state.current_zone, 1, 7)
	var los_eng: int = game_state.current_los_row_engine
	if game_state.conversion_pending and game_state.phase == PHASE_CONVERSION:
		zone = GameState.ZONE_END
		los_eng = game_state.los_row_engine_from_zone(zone)
	var field_h: float = field_background.size.y
	var field_w: float = field_background.size.x
	var offense_is_home := game_state.possession_team == "home"
	var chip_half := Vector2(20, 20)
	if ball_chip:
		chip_half = ball_chip.custom_minimum_size * 0.5
	if field_grid != null:
		var los_disp: int = int(field_grid.call("perspective_row", los_eng, offense_is_home))
		var ball_center: Vector2 = field_grid.call("world_pos_from_tile", los_disp, 3)
		if ball_chip:
			ball_chip.position = ball_center - chip_half
		if game_state.conversion_pending and game_state.phase == PHASE_CONVERSION:
			field_grid.call("set_field_line_display_rows", los_disp, -1, -1, -1, -1)
		elif game_state.is_goal_to_go():
			var ez0_eng := 0
			var ez4_eng := GameState.TILE_ROWS_PER_ZONE - 1
			var ez0_disp: int = int(field_grid.call("perspective_row", ez0_eng, offense_is_home))
			var ez4_disp: int = int(field_grid.call("perspective_row", ez4_eng, offense_is_home))
			var ez_lo := mini(ez0_disp, ez4_disp)
			var ez_hi := maxi(ez0_disp, ez4_disp)
			field_grid.call("set_field_line_display_rows", los_disp, -1, -1, ez_lo, ez_hi)
		else:
			var fd_eng := game_state.first_down_target_row_engine
			if fd_eng < 0:
				field_grid.call("set_field_line_display_rows", los_disp, -1, -1, -1, -1)
			else:
				var fd_disp: int = int(field_grid.call("perspective_row", fd_eng, offense_is_home))
				field_grid.call("set_field_line_display_rows", los_disp, fd_disp, fd_disp, -1, -1)
	else:
		var zone_h: float = field_h / 7.0
		var index_from_bottom: int = zone - 1
		var center_y: float = field_h - (float(index_from_bottom) + 0.5) * zone_h
		if game_state.possession_team != _user_team:
			center_y = field_h - center_y
		if ball_chip:
			ball_chip.position = Vector2(field_w * 0.5 - chip_half.x, center_y - chip_half.y)

	if ball_chip:
		var is_home := game_state.possession_team == "home"
		ball_chip.modulate = Color(0.2, 0.5, 1.0, 1.0) if is_home else Color(1.0, 0.3, 0.3, 1.0)

func _update_sim_ui() -> void:
	if sim_status_label:
		sim_status_label.text = "USER AUTO: %s | %.2fx" % ["ON" if _sim_running else "OFF", _sim_speed]
	if start_button:
		start_button.text = "Man" if _sim_running else "Sim"
	if speed_label:
		var shown_speed := str(int(_sim_speed)) if is_equal_approx(_sim_speed, round(_sim_speed)) else str(_sim_speed)
		speed_label.text = "x%s" % shown_speed
	if pause_button:
		var show_pause_icon := (_sim_running and not _sim_tick_paused) or (not _sim_running and _scrimmage_offense_selecting_window() and not _manual_pause_active and not _auto_pause_after_sim_stop)
		pause_button.text = "⏸️" if show_pause_icon else "▶️"
	_update_sim_stats_ui()
	_update_sim_step_controls()

func _on_start_sim_pressed() -> void:
	_sim_running = not _sim_running
	if _sim_running:
		_manual_pause_active = false
		_auto_pause_after_sim_stop = false
		_sim_tick_paused = false
		_apply_sim_timer_speed()
		if sim_timer and sim_timer.is_stopped():
			sim_timer.start()
		_maybe_run_ai_inputs(true)
	else:
		_auto_pause_after_sim_stop = true
		_manual_pause_active = true
		if sim_timer:
			sim_timer.stop()
	_sync_game_clock_scrimmage_policy()
	_update_ui()

func _on_show_action_timer_bar_toggled(pressed: bool) -> void:
	show_action_timer_bar = pressed
	if not pressed:
		_stop_turn_action_timer()
	elif game_state.phase == PHASE_PLAY_SELECTION or game_state.phase == PHASE_CARD_QUEUE:
		_start_turn_action_timer(ACTION_WINDOW_SECONDS)
	_update_ui()

func _on_pause_sim_pressed() -> void:
	if _sim_running:
		_sim_tick_paused = not _sim_tick_paused
		if sim_timer:
			if _sim_running and not _sim_tick_paused:
				_apply_sim_timer_speed()
				if sim_timer.is_stopped():
					sim_timer.start()
			else:
				sim_timer.stop()
	else:
		_manual_pause_active = not _manual_pause_active
		if not _manual_pause_active:
			_auto_pause_after_sim_stop = false
		_sync_game_clock_scrimmage_policy()
	_update_ui()

func _on_restart_pressed() -> void:
	_sim_running = false
	_sim_tick_paused = false
	_clock_running = false
	_clock_accumulator = 0.0
	_hide_last_play_toast()
	_awaiting_defense_pick = false
	_selected_defense_play = ""
	_play_ready_home = false
	_play_ready_away = false
	_defense_selected_explicit = false
	_cached_user_hand_sig = ""
	_cached_user_queue_sig = ""
	_turn_action_timer_active = false
	_turn_action_time_remaining = ACTION_WINDOW_SECONDS
	_turn_action_timeout_handled = false
	_turn_timed_out_home = false
	_turn_timed_out_away = false
	_manual_ready_pressed_home = false
	_manual_ready_pressed_away = false
	_ready_miss_streak_home = 0
	_ready_miss_streak_away = 0
	_manual_pause_active = false
	_auto_pause_after_sim_stop = false
	_game_clock_hold_after_rule_stop = false
	_defer_scrimmage_game_clock_until_first_snap = true
	_abandoned_game = false
	_phase_log_lines.clear()
	_phase_log_end_recorded = false
	_turn_counter = 0
	_calc_log_clear()
	if sim_timer:
		sim_timer.stop()
	game_state.start_game()
	_append_touchback_event_log("(opening kickoff).")
	_begin_new_game_stats()
	_assign_user_team_random()
	_load_data()
	_spawn_players()
	_turn_initialized = false
	_offense_play_tentative = GameState.PENDING_NONE
	_play_pick_window = "offense"
	_begin_turn_if_needed()
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


func _on_tools_menu_id_pressed(id: int) -> void:
	if id != 0:
		return
	if _formations_catalog == null:
		push_error("Formations not loaded")
		return
	var t := FORMATION_TOOL_SCENE.instantiate() as FormationTool
	t.setup(_formations_catalog, Callable(self, "_formation_tool_after_save"))
	add_child(t)


func _formation_tool_after_save() -> void:
	if _formations_catalog and not _formations_catalog.load_from_json("res://data/formations.json"):
		push_error("Failed to reload formations.json after tool save")


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


func _on_speed_preset_pressed(target: float) -> void:
	_sim_speed = clampf(target, 0.5, 10.0)
	_apply_sim_timer_speed()
	_update_ui()


func _apply_sim_timer_speed() -> void:
	if not sim_timer:
		return
	sim_timer.wait_time = 1.0 / _sim_speed
	if _sim_running and not _sim_tick_paused and sim_timer.is_stopped():
		sim_timer.start()


func _sim_step_after_play_enabled() -> bool:
	return sim_step_after_play_toggle != null and sim_step_after_play_toggle.button_pressed


func _sim_step_waiting_for_next() -> bool:
	return _sim_running and _sim_tick_paused and _sim_step_after_play_enabled()


func _update_sim_step_controls() -> void:
	if sim_step_next_button:
		sim_step_next_button.disabled = not (_sim_running and _sim_tick_paused and _sim_step_after_play_enabled())


func _sim_try_pause_step_after_play() -> void:
	if not _sim_running or not _sim_step_after_play_enabled():
		return
	_sim_tick_paused = true
	if sim_timer:
		sim_timer.stop()
	_update_sim_step_controls()
	_sync_game_clock_scrimmage_policy()


func _on_sim_step_next_pressed() -> void:
	if not _sim_running:
		return
	_sim_tick_paused = false
	_apply_sim_timer_speed()
	_update_ui()


func _on_sim_step_after_play_toggled(_pressed: bool) -> void:
	if not _sim_running:
		_update_sim_step_controls()
		return
	if not _sim_step_after_play_enabled() and _sim_tick_paused:
		_sim_tick_paused = false
		_apply_sim_timer_speed()
	_update_ui()

func _on_sim_tick() -> void:
	if not _sim_running or _sim_tick_paused:
		return
	if game_state.phase == GameState.PHASE_GAME_OVER:
		_sim_tick_paused = true
		if sim_timer:
			sim_timer.stop()
		return
	if _maybe_sim_call_timeouts():
		return
	_maybe_run_ai_inputs(true)

func _pick_sim_defense_play_for_offense(offense_play: String) -> String:
	return _sim_pick_defense_catalog_id(offense_play)

func _pick_sim_play_type() -> String:
	var seat := game_state.possession_team
	if game_state.phase == PHASE_CONVERSION and game_state.conversion_type == CONVERSION_2PT:
		var roll2 := randf()
		if roll2 < 0.5:
			var r := _random_play_id_from_book_for_buckets(seat, [BUCKET_RUN])
			return r if not r.is_empty() else _first_play_id_in_book_for_bucket(seat, BUCKET_RUN)
		var p := _random_play_id_from_book_for_buckets(seat, [BUCKET_PASS])
		return p if not p.is_empty() else _first_play_id_in_book_for_bucket(seat, BUCKET_PASS)
	if _sim_should_call_punt():
		var pu := _random_play_id_from_book_for_buckets(seat, [BUCKET_PUNT])
		return pu if not pu.is_empty() else _first_play_id_in_book_for_bucket(seat, BUCKET_PUNT)
	if current_phase_level >= 2 and _can_attempt_field_goal_from_current_zone() and randf() < 0.2:
		var fg := _random_play_id_from_book_for_buckets(seat, [BUCKET_SPOT_KICK])
		return fg if not fg.is_empty() else _first_play_id_in_book_for_bucket(seat, BUCKET_SPOT_KICK)
	var roll := randf()
	if roll < 0.45:
		var r2 := _random_play_id_from_book_for_buckets(seat, [BUCKET_RUN])
		return r2 if not r2.is_empty() else _first_play_id_in_book_for_bucket(seat, BUCKET_RUN)
	if roll < 0.8:
		var p2 := _random_play_id_from_book_for_buckets(seat, [BUCKET_PASS])
		return p2 if not p2.is_empty() else _first_play_id_in_book_for_bucket(seat, BUCKET_PASS)
	return _first_play_id_in_book_for_bucket(seat, BUCKET_PASS)

func _sim_seconds_left_in_current_half() -> int:
	if game_state.half == 1:
		return max(game_state.game_time_remaining - GameState.HALF_SECONDS, 0)
	return game_state.game_time_remaining

func _sim_should_call_punt() -> bool:
	if game_state.phase == PHASE_CONVERSION:
		return false
	var zone := game_state.current_zone
	var down := game_state.downs
	var team := game_state.possession_team
	var opp := "away" if team == "home" else "home"
	var team_score := game_state.score_home if team == "home" else game_state.score_away
	var opp_score := game_state.score_home if opp == "home" else game_state.score_away
	var diff := team_score - opp_score
	var sec_left := _sim_seconds_left_in_current_half()
	var fg_range := current_phase_level >= 2 and _can_attempt_field_goal_from_current_zone()
	if down >= 4:
		if fg_range:
			return false
		if zone <= GameState.ZONE_MIDFIELD:
			if diff < 0 and sec_left <= 20:
				return false
			return true
		if zone == GameState.ZONE_ATTACK:
			return diff > 0 and sec_left <= 60
		return false
	if down == 3 and zone <= GameState.ZONE_ADVANCE and diff >= 0 and sec_left <= 30:
		return randf() < 0.35
	if down <= 2 and zone == GameState.ZONE_MY_END and diff >= 8 and sec_left <= 60:
		return randf() < 0.15
	return false


func _sim_should_hurry_up(team: String) -> bool:
	var opp := "away" if team == "home" else "home"
	var team_score := game_state.score_home if team == "home" else game_state.score_away
	var opp_score := game_state.score_home if opp == "home" else game_state.score_away
	var trailing := team_score < opp_score
	if not trailing:
		return false
	if game_state.half == 1:
		return game_state.game_time_remaining <= (GameState.HALF_SECONDS + 90)
	return game_state.game_time_remaining <= 120


func _roll_sim_presnap_runoff_seconds() -> int:
	var scale := clampf(float(GameState.MAX_CLOCK_SECONDS) / 900.0, 0.20, 1.0)
	var min_s := maxi(1, int(round(float(SIM_RUNOFF_MIN_SECONDS) * scale)))
	var max_s := maxi(min_s, int(round(float(SIM_RUNOFF_MAX_SECONDS) * scale)))
	var under_two := (game_state.half == 1 and game_state.game_time_remaining <= (GameState.HALF_SECONDS + 120)) or (game_state.half == 2 and game_state.game_time_remaining <= 120)
	if under_two:
		min_s = maxi(1, int(round(float(SIM_RUNOFF_TWO_MIN_MIN_SECONDS) * scale)))
		max_s = maxi(min_s, int(round(float(SIM_RUNOFF_TWO_MIN_MAX_SECONDS) * scale)))
	var poss := game_state.possession_team
	if _sim_should_hurry_up(poss):
		min_s = maxi(1, int(round(float(SIM_RUNOFF_HURRY_MIN_SECONDS) * scale)))
		max_s = maxi(min_s, int(round(float(SIM_RUNOFF_HURRY_MAX_SECONDS) * scale)))
	return randi_range(min_s, max_s)


func _apply_sim_presnap_runoff() -> void:
	if game_state.phase != PHASE_CARD_QUEUE:
		return
	if game_state.phase == GameState.PHASE_GAME_OVER or game_state.phase == GameState.PHASE_HALFTIME:
		return
	var runoff := _roll_sim_presnap_runoff_seconds()
	if runoff <= 0:
		return
	if not _defer_scrimmage_game_clock_until_first_snap:
		game_state.game_time_remaining = max(game_state.game_time_remaining - runoff, 0)
	if show_action_timer_bar and _turn_action_timer_active and (game_state.phase == PHASE_PLAY_SELECTION or game_state.phase == PHASE_CARD_QUEUE):
		_turn_action_time_remaining = maxf(0.0, _turn_action_time_remaining - float(runoff))
		_last_play_clock_display_seconds = int(ceili(_turn_action_time_remaining))
	if game_state.half == 1 and game_state.game_time_remaining <= GameState.HALF_SECONDS and game_state.phase != GameState.PHASE_HALFTIME:
		game_state.force_halftime_now()
		_append_touchback_event_log("(halftime, second half).")
		_after_force_halftime_second_half()
	if game_state.game_time_remaining <= 0:
		game_state.game_time_remaining = 0
		game_state.end_game_if_time_up()
		if game_state.phase == GameState.PHASE_GAME_OVER:
			_clock_running = false
			if sim_timer:
				sim_timer.stop()
	_update_ui()

func _auto_select_for_team(team: String, max_cards: int) -> void:
	var picks := 0
	var hand: Array = _hand_for_team(team)
	for card in hand:
		if max_cards >= 0 and picks >= max_cards:
			break
		if typeof(card) != TYPE_DICTIONARY:
			continue
		var cd := card as Dictionary
		var cid := str(cd.get("instance_id", cd.get("id", "")))
		if cid.is_empty():
			continue
		if _is_card_selected(team, cid):
			continue
		var card_cost := int(cd.get("cost", 0))
		if card_cost > _remaining_momentum_for_team(team):
			continue
		if _toggle_selected_card_for_team(team, cid):
			picks += 1

func _sim_pick_conversion() -> String:
	var team := game_state.conversion_team
	var team_score := game_state.score_home if team == "home" else game_state.score_away
	var opp_score := game_state.score_away if team == "home" else game_state.score_home
	var diff := team_score - opp_score
	return CONVERSION_2PT if SIM_2PT_DIFFS.has(diff) else CONVERSION_XP

func _begin_post_td_conversion(team: String) -> void:
	game_state.phase = PHASE_CONVERSION
	game_state.conversion_type = ""
	game_state.conversion_team = team
	game_state.possession_team = team
	_append_event_log("[color=#66ff00][b]Touchdown![/b][/color] %s +6." % _team_display_name(team))
	_calc_log_push_slide_flat("Conversion — start", [
		"Scoring side for conversion: %s." % _team_display_name(team),
		"Choose extra point (auto roll) or a full two-point scrimmage play.",
	], CALC_LOG_CAT_CONVERSION)
	_append_phase_subphase("conversion_choice")
	_stop_clock("conversion")
	if _sim_running:
		_choose_conversion(_sim_pick_conversion())
	elif _is_ai_controlled_team(team, false):
		_choose_conversion(_sim_pick_conversion())
	else:
		result_text.text = "[b]Touchdown![/b]\nChoose Extra Point (auto from kicker stats) or 2-Point (normal play)."
		_append_event_log("Awaiting conversion: Extra Point or 2-point.")
	_update_ui()

func _choose_conversion(conv_type: String) -> void:
	if game_state.phase != PHASE_CONVERSION:
		return
	if not game_state.conversion_type.is_empty():
		return
	game_state.conversion_type = conv_type
	game_state.possession_team = game_state.conversion_team
	_append_phase_subphase("conversion_attempt", "type=%s" % conv_type)
	_calc_log_push_slide_flat("Conversion — choice", [
		"%s commits to %s." % [
			_team_display_name(game_state.conversion_team),
			"extra point (resolver roll)" if conv_type == CONVERSION_XP else "two-point try (normal scrimmage flow)"
		],
	], CALC_LOG_CAT_CONVERSION)
	if conv_type == CONVERSION_XP:
		_append_event_log("Extra Point attempt from %s." % _zone_name(GameState.ZONE_ATTACK))
		_update_ui()
		_run_extra_point_attempt()
		return
	game_state.current_zone = GameState.ZONE_RED
	game_state.current_los_row_engine = game_state.los_row_engine_from_zone(game_state.current_zone)
	game_state.reset_first_down_chain_from_current_zone()
	game_state.downs = 1
	game_state.pending_play_type = PENDING_NONE()
	_play_pick_window = "offense"
	result_text.text = "[b]2-Point Conversion[/b]\nSelect Run or Pass play."
	_append_event_log("2-Point attempt from %s." % _zone_name(GameState.ZONE_RED))
	_update_ui()

func _run_extra_point_attempt() -> void:
	var team := game_state.conversion_team
	var kicker := player_data.get_best_kicker(_franchise_id_for_seat(team))
	var kicker_id := str(kicker.get("id", ""))
	var staff_bonus := int((_staff_data[team]["off_coord"].get("bonus_offense", {}) as Dictionary).get("standard_zone_bonus", 0))
	var xp_result := play_resolver.resolve_extra_point(kicker_id, kicker, _opponent_flat_def_mod - staff_bonus)
	_calc_log_push_breakdown_slide("Conversion — extra point resolver", xp_result)
	if bool(xp_result.get("success", false)):
		game_state.add_score(team, 1)
		result_text.text = "[center][color=#66ff66][b]EXTRA POINT GOOD[/b][/color][/center]"
		_append_event_log("[b]Extra Point GOOD[/b]")
		_finish_conversion("extra_point_made", true)
		_show_last_play_toast("Extra Point Good!", "good")
	else:
		result_text.text = "[center][color=#ff6666][b]EXTRA POINT MISSED[/b][/color][/center]"
		_append_event_log("[b]Extra Point MISSED[/b]")
		_finish_conversion("extra_point_missed", false)
		_show_last_play_toast("Extra Point Missed!", "bad")
	_sim_try_pause_step_after_play()
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
	game_state.start_possession(next_team, game_state.next_drive_start_zone, GameState.TOUCHBACK_LOS_ROW_ENGINE)
	_calc_log_push_slide_flat("Conversion — kickoff / new possession", [
		"Receiving team: %s at touchback row %d." % [next_team.capitalize(), GameState.TOUCHBACK_LOS_ROW_ENGINE],
		"Drive start zone (mapped): %s." % _zone_name(game_state.next_drive_start_zone),
	], CALC_LOG_CAT_CONVERSION)
	_append_event_log("[color=#4da3ff][b]CHANGE OF POSSESSION[/b][/color]")
	_append_event_log("Kickoff: %s — Build zone LOS row %d (%s)." % [next_team.capitalize(), GameState.TOUCHBACK_LOS_ROW_ENGINE, _zone_name(game_state.current_zone)])
	_append_touchback_event_log("(kickoff after TD).")
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
	_sim_presnap_runoff_applied = false
	_selected_cards_home.clear()
	_selected_cards_away.clear()
	_selected_cards_home.clear()
	_selected_cards_away.clear()

	_start_turn_action_timer(ACTION_WINDOW_SECONDS)
	_sync_game_clock_scrimmage_policy()
	_update_ui()


func _selected_cards_for_team(team: String) -> Array[String]:
	return _selected_cards_home if team == "home" else _selected_cards_away


func _selected_spent_for_team(team: String) -> int:
	var spent := 0
	var hand := _hand_for_team(team)
	var selected := _selected_cards_for_team(team)
	for card in hand:
		if typeof(card) != TYPE_DICTIONARY:
			continue
		var cd := card as Dictionary
		if selected.has(str(cd.get("instance_id", cd.get("id", "")))):
			spent += int(cd.get("cost", 0))
	return spent


func _remaining_momentum_for_team(team: String) -> int:
	var momentum: int = game_state.momentum_home if team == "home" else game_state.momentum_away
	return max(momentum - _selected_spent_for_team(team), 0)


func _is_card_selected(team: String, card_id: String) -> bool:
	if card_id.is_empty():
		return false
	return _selected_cards_for_team(team).has(card_id)


func _toggle_selected_card_for_team(team: String, card_id: String) -> bool:
	if team == _user_team:
		_release_sim_to_man_auto_pause_if_any()
	if card_id.is_empty():
		return false
	if game_state.phase != PHASE_CARD_QUEUE:
		return false
	if (team == "home" and game_state.home_ready) or (team == "away" and game_state.away_ready):
		return false
	var selected := _selected_cards_for_team(team)
	if selected.has(card_id):
		selected.erase(card_id)
		_update_ui()
		return true
	var hand := _hand_for_team(team)
	var card_cost := -1
	var card_name := "Card"
	for card in hand:
		if typeof(card) != TYPE_DICTIONARY:
			continue
		var cd := card as Dictionary
		if str(cd.get("instance_id", cd.get("id", ""))) == card_id:
			card_cost = int(cd.get("cost", 0))
			card_name = str(cd.get("name", "Card"))
			break
	if card_cost < 0:
		return false
	if card_cost > _remaining_momentum_for_team(team):
		result_text.text = "Not enough Momentum to select %s." % card_name
		_append_event_log("Not enough Momentum to select %s." % card_name)
		return false
	selected.append(card_id)
	_update_ui()
	return true


func _sync_selected_cards_with_hand(team: String) -> void:
	var hand := _hand_for_team(team)
	var valid: Dictionary = {}
	for card in hand:
		if typeof(card) == TYPE_DICTIONARY:
			valid[str((card as Dictionary).get("instance_id", (card as Dictionary).get("id", "")))] = true
	var selected := _selected_cards_for_team(team)
	for i in range(selected.size() - 1, -1, -1):
		if not valid.has(selected[i]):
			selected.remove_at(i)


func _build_queued_from_selected(team: String) -> void:
	var hand := _hand_for_team(team)
	var selected := _selected_cards_for_team(team)
	var queue: Array = game_state.queued_cards_home if team == "home" else game_state.queued_cards_away
	queue.clear()
	var selected_set: Dictionary = {}
	for card_id in selected:
		selected_set[str(card_id)] = true
	for i in range(hand.size() - 1, -1, -1):
		var raw: Variant = hand[i]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var card := raw as Dictionary
		var cid := str(card.get("instance_id", card.get("id", "")))
		if not selected_set.has(cid):
			continue
		queue.push_front({
			"team": team,
			"card": card.duplicate(true),
			"target": {},
			"cost": int(card.get("cost", 0))
		})
		hand.remove_at(i)
	if team == "home":
		game_state.queued_momentum_spent_home = _selected_spent_for_team(team)
	else:
		game_state.queued_momentum_spent_away = _selected_spent_for_team(team)
	selected.clear()


func _on_hand_card_tile_selection_toggled(team: String, card_id: String) -> void:
	_toggle_selected_card_for_team(team, card_id)


func _set_team_ready(team: String, ready: bool) -> void:
	if team == "home":
		game_state.home_ready = ready
	else:
		game_state.away_ready = ready

	_update_ui()

	if game_state.home_ready and game_state.away_ready:
		_build_queued_from_selected("home")
		_build_queued_from_selected("away")
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

	if game_state.pending_play_type != PLAY_NONE():
		_calc_log_begin_snap_bundle()

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
		_calc_log_commit_snap_bundle_if_active()
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
		game_state.card_played_this_play_home = true
	else:
		game_state.momentum_away = max(game_state.momentum_away - cost, 0)
		game_state.discard_away.append(card)
		_resolved_cards_away.append(str(card.get("name", "Card")))
		game_state.card_played_this_play_away = true

	effect_manager.add_effect({
		"effect_data": card.get("effect_data", {}),
		"queued_team": team
	}, "plays", 1)
	var effect_text := _friendly_effects_text(card.get("effect_data", {}))
	var cname := str(card.get("name", "Card"))
	var card_lines: Array[String] = ["%s spends %d momentum on [b]%s[/b]." % [_team_display_name(team), cost, cname]]
	if not effect_text.is_empty():
		card_lines.append("Effect: %s" % effect_text)
	if _calc_log_snap_bundle_active:
		if not _calc_log_snap_seen_cards:
			_calc_log_snap_seen_cards = true
			_calc_log_snap_append_section("Cards — queue resolve", card_lines, CALC_LOG_CAT_CARDS)
		else:
			_calc_log_snap_append_flat_lines(card_lines, CALC_LOG_CAT_CARDS)
	else:
		_calc_log_push_slide_flat("Cards — queue resolve", card_lines, CALC_LOG_CAT_CARDS)
	if not effect_text.is_empty():
		if team == "home":
			_resolved_effects_home.append(effect_text)
		else:
			_resolved_effects_away.append(effect_text)


func _remove_card_from_team_hand_by_id(team: String, card_id: String) -> bool:
	var hand: Array = game_state.hand_home if team == "home" else game_state.hand_away
	for idx in range(hand.size()):
		var c: Dictionary = hand[idx]
		if str(c.get("instance_id", c.get("id", ""))) == card_id:
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
		parts.append("%s:%d" % [str(d.get("instance_id", d.get("id", ""))), int(d.get("cost", 0))])
	return "|".join(parts)


func _queue_visual_signature(entries: Array) -> String:
	var parts: Array[String] = []
	for item in entries:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var cd: Dictionary = (item as Dictionary).get("card", {})
		parts.append("%s:%d" % [str(cd.get("instance_id", cd.get("id", ""))), int(cd.get("cost", 0))])
	return "|".join(parts)


func _rebuild_user_card_tiles() -> void:
	var show_strips := current_phase_level >= 3

	if user_hand_cards:
		var hand_scroll := user_hand_cards.get_parent()
		if hand_scroll:
			hand_scroll.visible = show_strips

	if not show_strips:
		return

	var hand: Array = _hand_for_team(_user_team)
	var hs := _hand_visual_signature(hand)
	var selected_sig := "|".join(_selected_cards_for_team(_user_team))
	var remaining := _remaining_momentum_for_team(_user_team)
	var qs := "%s#%d" % [selected_sig, remaining]
	if hs == _cached_user_hand_sig and qs == _cached_user_queue_sig:
		return
	_cached_user_hand_sig = hs
	_cached_user_queue_sig = qs

	if user_hand_cards:
		_clear_card_strip_children(user_hand_cards)

	if user_hand_cards:
		for i in range(hand.size()):
			var card = hand[i]
			if typeof(card) != TYPE_DICTIONARY:
				continue
			var tile := CARD_TILE_SCENE.instantiate()
			user_hand_cards.add_child(tile)
			if tile.has_method("setup"):
				tile.setup(card as Dictionary)
			if tile.has_method("set_selected_state"):
				tile.set_selected_state(_is_card_selected(_user_team, str((card as Dictionary).get("instance_id", (card as Dictionary).get("id", "")))))
			if tile.has_method("set_affordable_state"):
				var card_cost := int((card as Dictionary).get("cost", 0))
				var can_afford := true
				if game_state.phase == PHASE_CARD_QUEUE:
					can_afford = _is_card_selected(_user_team, str((card as Dictionary).get("instance_id", (card as Dictionary).get("id", "")))) or card_cost <= remaining
				tile.set_affordable_state(can_afford)
			if tile.has_signal("selection_toggled"):
				tile.configure_hand_interaction(true, _user_team, i)
				tile.selection_toggled.connect(_on_hand_card_tile_selection_toggled)
			if tile.has_signal("info_hold_started"):
				tile.info_hold_started.connect(_on_card_tile_info_requested)
			if tile.has_signal("info_hold_ended"):
				tile.info_hold_ended.connect(_hide_card_info_panel)

func _friendly_play_name(play: String, is_defense: bool = false) -> String:
	if play.is_empty() or play == GameState.PENDING_NONE:
		return "-"
	var row := _plays_catalog.get_play(play)
	var nm := str(row.get("name", ""))
	if not nm.is_empty():
		return nm
	var b := _pid_bucket(play)
	match b:
		BUCKET_RUN:
			return "Run"
		BUCKET_PASS:
			return "Pass"
		BUCKET_SPOT_KICK:
			return "Field goal"
		BUCKET_PUNT:
			return "Punt"
		BUCKET_RUN_DEF:
			return "Run defense"
		BUCKET_PASS_DEF:
			return "Pass defense"
		BUCKET_FG_XP_DEF:
			return "FG/XP defense"
		BUCKET_PUNT_RETURN:
			return "Punt return"
		_:
			return play

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

func _render_last_play_info(offense_team: String, offense_play: String, defense_play: String, result_line: String, tile_rows_toward_goal: int) -> void:
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
	var zone_txt := "Tile rows toward goal: %+d" % tile_rows_toward_goal
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
