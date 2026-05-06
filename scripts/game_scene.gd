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

@onready var game_state: GameState = $GameState
@onready var play_resolver: PlayResolver = $PlayResolver
@onready var card_manager: CardManager = $CardManager
@onready var effect_manager: EffectManager = $EffectManager
@onready var targeting_manager: TargetingManager = $TargetingManager
@onready var player_data: PlayerData = $PlayerData
@onready var coach_data: CoachData = $CoachData

@onready var clock_label: Label = $HUDLayer/ClockLabel
@onready var half_label: Label = $HUDLayer/HalfLabel
@onready var score_label: Label = $HUDLayer/ScoreLabel
@onready var possession_label: Label = $HUDLayer/PossessionLabel
@onready var zone_label: Label = $HUDLayer/ZoneLabel
@onready var drive_points_label: Label = $HUDLayer/DrivePointsLabel
@onready var phase_label: Label = $HUDLayer/PhaseLabel
@onready var result_text: RichTextLabel = $HUDLayer/ResultText
@onready var momentum_label: Label = $HUDLayer/MomentumLabel
@onready var hand_label: Label = $HUDLayer/HandLabel

@onready var run_button: Button = $PlayButtons/RunButton
@onready var short_pass_button: Button = $PlayButtons/ShortPassButton
@onready var deep_pass_button: Button = $PlayButtons/DeepPassButton
@onready var field_goal_button: Button = $PlayButtons/FieldGoalButton
@onready var play_card_button: Button = $PlayButtons/PlayCardButton
@onready var ready_button: Button = get_node_or_null("PlayButtons/ReadyButton") as Button

@onready var players_container: HBoxContainer = $PlayersLayer/PlayersContainer
@onready var card_panel: VBoxContainer = $CardsPanel/CardPanel
@onready var targeting_panel: VBoxContainer = $TargetingPanel

var _player_tokens: Dictionary = {}
@export_range(1, 5, 1) var current_phase_level: int = 5
var _opponent_flat_def_mod: int = 10
var _staff_data: Dictionary = {}
var _pending_target_card: Dictionary = {}
var _turn_initialized: bool = false
var _queue_team: String = "home"

func _ready() -> void:
	randomize()

	# 1) Reset runtime state first (so start_game doesn't wipe loaded card state afterward)
	game_state.start_game()

	# 2) Load static data and initialize decks/hands
	_load_data()

	# 3) Wire scene logic and spawn tokens
	_wire_buttons()
	_spawn_players()

	# 4) Start-of-turn setup + HUD refresh
	_turn_initialized = false
	_begin_turn_if_needed()
	_update_ui()

func _load_data() -> void:
	player_data.load_from_json("res://data/players.json")
	coach_data.load_from_json("res://data/coaches.json")

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
	card_manager.draw(hh, dh, xh, 3, 5)
	game_state.hand_home = hh
	game_state.deck_home = dh
	game_state.discard_home = xh

	var ha: Array = game_state.hand_away
	var da: Array = game_state.deck_away
	var xa: Array = game_state.discard_away
	card_manager.draw(ha, da, xa, 3, 5)
	game_state.hand_away = ha
	game_state.deck_away = da
	game_state.discard_away = xa

	print("post init hand H:", game_state.hand_home.size(), " A:", game_state.hand_away.size())

func _wire_buttons() -> void:
	run_button.pressed.connect(func(): _on_select_play(PLAY_RUN))
	short_pass_button.pressed.connect(func(): _on_select_play(PLAY_SHORT_PASS))
	deep_pass_button.pressed.connect(func(): _on_select_play(PLAY_DEEP_PASS))
	field_goal_button.pressed.connect(func(): _on_select_play(PLAY_FIELD_GOAL))
	play_card_button.pressed.connect(_on_play_non_targeted_card)
	if ready_button:
		ready_button.pressed.connect(_on_ready_pressed)
	game_state.state_changed.connect(_update_ui)

func _spawn_players() -> void:
	for c in players_container.get_children():
		c.queue_free()
	_player_tokens.clear()

	var token_scene: PackedScene = preload("res://scenes/player.tscn")
	for p in player_data.players:
		var token: PlayerToken = token_scene.instantiate()
		players_container.add_child(token)
		token.bind_player(p)
		token.selected.connect(_on_player_selected)
		_player_tokens[p["id"]] = token

func _on_select_play(play_type: String) -> void:
	if not _is_phase_allowed_for_play():
		return

	_begin_turn_if_needed()
	game_state.pending_play_type = play_type
	if current_phase_level >= 3:
		_start_card_queue_phase()
	else:
		_resolve_play()

func _is_phase_allowed_for_play() -> bool:
	var p := game_state.phase
	if p == GameState.PHASE_GAME_OVER or p == GameState.PHASE_HALFTIME:
		return false
	return p == PHASE_PLAY_SELECTION or p == PHASE_CARD_SELECTION

func _begin_turn_if_needed() -> void:
	print("BEGIN TURN? init=", _turn_initialized, " phase=", game_state.phase, " level=", current_phase_level)
	if _turn_initialized:
		return
	if current_phase_level < 3:
		_turn_initialized = true
		return

	game_state.phase = PHASE_CARD_SELECTION
	_advance_both_teams_resources()
	_turn_initialized = true

	# Keep simple flow: after card phase setup, return to play selection
	game_state.phase = PHASE_PLAY_SELECTION

func _advance_both_teams_resources() -> void:
	if game_state.just_started_possession:
		game_state.just_started_possession = false
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
	var play_result: Dictionary

	if game_state.pending_play_type == PLAY_FIELD_GOAL and current_phase_level >= 2:
		var kicker_id := game_state.selected_player_id
		if kicker_id.is_empty():
			var best := player_data.get_best_kicker(game_state.possession_team)
			kicker_id = str(best.get("id", ""))
			game_state.selected_player_id = kicker_id

		var kicker := player_data.get_by_id(kicker_id)
		var staff_bonus := int(_staff_data[game_state.possession_team]["head_coach"].get("bonus", {}).get("field_goal_bonus", 0))
		play_result = play_resolver.resolve_field_goal(kicker_id, game_state.current_zone, kicker, _opponent_flat_def_mod - staff_bonus)
	else:
		if game_state.selected_player_id.is_empty():
			var team_players := player_data.get_team(game_state.possession_team)
			if team_players.size() > 0:
				game_state.selected_player_id = str(team_players[0].get("id", ""))

		play_result = play_resolver.resolve_standard_play(game_state.pending_play_type, game_state.selected_player_id, game_state.current_zone)
		play_result["breakdown"].append("Opponent defense: -%d" % _opponent_flat_def_mod)

		var staff_play_bonus := int(_staff_data[game_state.possession_team]["off_coord"].get("bonus", {}).get("standard_zone_bonus", 0))
		if staff_play_bonus != 0:
			play_result["zone_delta"] = max(int(play_result["zone_delta"]) + staff_play_bonus, 0)
			play_result["breakdown"].append("Staff bonus: %+d zone" % staff_play_bonus)

	_apply_play_result(play_result)

func _apply_play_result(result: Dictionary) -> void:
	game_state.apply_clock(int(result.get("clock_seconds_used", 0)))
	game_state.plays_used_current_drive += 1
	game_state.drive_points -= 1
	game_state.apply_zone_delta(int(result.get("zone_delta", 0)))

	var score_delta := int(result.get("score_delta", 0))
	if game_state.pending_play_type == PLAY_FIELD_GOAL and score_delta > 0:
		game_state.add_score(game_state.possession_team, 3)
		_set_next_drive_start_zone_from_kick_power()
		game_state.end_possession("field_goal", 3)
	elif game_state.pending_play_type == PLAY_FIELD_GOAL:
		game_state.end_possession("missed_field_goal", 0)
	elif game_state.is_touchdown():
		game_state.add_score(game_state.possession_team, 6)
		_set_next_drive_start_zone_from_kick_power()
		game_state.end_possession("touchdown", 6)
	elif game_state.game_time_remaining <= 0:
		game_state.end_game_if_time_up()
	elif game_state.drive_points <= 0:
		game_state.end_possession("drive_points_depleted", 0)
	else:
		game_state.phase = PHASE_PLAY_SELECTION

	game_state.pending_play_type = GameState.PENDING_NONE
	result_text.text = "[b]%s[/b]\n%s" % [str(result.get("result_text", "")), "\n".join(result.get("breakdown", []))]

	if game_state.phase == GameState.PHASE_GAME_OVER:
		game_state.emit_signal("state_changed")
		return

	if game_state.should_force_halftime_now() and game_state.phase != GameState.PHASE_GAME_OVER:
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
		_begin_turn_if_needed()
		
	print("AFTER PLAY HOOK -> reset turn init false")

func _set_next_drive_start_zone_from_kick_power() -> void:
	var kicker := player_data.get_by_id(game_state.selected_player_id)
	var kick_power := int(kicker.get("kick_power", 50))
	game_state.next_drive_start_zone = 2 if kick_power >= 60 else 3

func _on_play_non_targeted_card() -> void:
	if current_phase_level < 3:
		return
	if game_state.phase != PHASE_CARD_QUEUE and _active_card_played_this_play():
		return

	if game_state.phase == PHASE_CARD_QUEUE:
		var queue_hand: Array = _hand_for_team(_queue_team)
		if queue_hand.is_empty():
			result_text.text = "No cards available for %s." % _queue_team
			return
		var queued_card: Dictionary = queue_hand[0]
		if not _queue_card_for_team(_queue_team, queued_card):
			result_text.text = "Not enough Momentum to queue card."
			return
		result_text.text = "Queued card (%s): %s" % [_queue_team, str(queued_card.get("name", "Card"))]
		_update_ui()
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
		return

	_set_active_momentum(_active_momentum() - int(r.get("momentum_cost", 0)))
	_set_active_card_played_this_play(true)

	_active_discard().append(card)
	_active_hand().remove_at(0)

	effect_manager.add_effect({
		"effect_data": r.get("effect_data", {})
	}, "plays", 1)

	result_text.text = "Played card (%s): %s" % [_active_team(), str(card.get("name", "Card"))]
	_update_ui()

func _update_ui() -> void:
	clock_label.text = _format_time(game_state.game_time_remaining)
	half_label.text = "Half: %d" % game_state.half
	score_label.text = "Score H:%d A:%d" % [game_state.score_home, game_state.score_away]
	possession_label.text = "Possession: %s (H:%d A:%d)" % [game_state.possession_team, game_state.home_possessions, game_state.away_possessions]
	zone_label.text = "Zone: %d/7" % game_state.current_zone
	drive_points_label.text = "Drive Points: %d" % game_state.drive_points
	phase_label.text = "Phase: %s (P%d)" % [game_state.phase, current_phase_level]

	# Show both teams so progression is visible regardless of possession.
	momentum_label.text = "Momentum H:%d A:%d" % [game_state.momentum_home, game_state.momentum_away]
	hand_label.text = "Hand H:%d A:%d" % [game_state.hand_home.size(), game_state.hand_away.size()]
	if game_state.phase == PHASE_CARD_QUEUE:
		phase_label.text = "Phase: %s (%s queue)" % [game_state.phase, _queue_team]

	field_goal_button.disabled = not (current_phase_level >= 2 and game_state.current_zone >= 4 and game_state.current_zone <= 6)
	play_card_button.disabled = not (current_phase_level >= 3 and not _hand_for_team(_queue_team).is_empty() and game_state.phase == PHASE_CARD_QUEUE)
	if ready_button:
		ready_button.disabled = game_state.phase != PHASE_CARD_QUEUE
	targeting_panel.visible = current_phase_level >= 4
	card_panel.visible = current_phase_level >= 3
	_update_staff_ui()

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

	if game_state.phase == PHASE_TARGETING and not _pending_target_card.is_empty():
		_apply_targeted_card(player_id)

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
	if not has_node("HUDLayer/StaffSummaryLabel"):
		return
	var label: Label = $HUDLayer/StaffSummaryLabel
	if current_phase_level < 5:
		label.text = "Staff: locked until Phase 5"
		return
	var hc = _staff_data["home"].get("head_coach", {})
	var oc = _staff_data["home"].get("off_coord", {})
	var dc = _staff_data["home"].get("def_coord", {})
	label.text = "Staff: HC %s | OC %s | DC %s" % [hc.get("style", "None"), oc.get("style", "None"), dc.get("style", "None")]

func _format_time(seconds_total: int) -> String:
	var m := seconds_total / 60
	var s := seconds_total % 60
	return "%02d:%02d" % [m, s]

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

	# reset queues/readiness each play
	game_state.queued_cards_home = []
	game_state.queued_cards_away = []
	game_state.queued_momentum_spent_home = 0
	game_state.queued_momentum_spent_away = 0
	game_state.home_ready = false
	game_state.away_ready = false

	# both teams progress each play, except first play right after possession change
	if game_state.just_started_possession:
		game_state.just_started_possession = false
	else:
		game_state.momentum_home = clampi(game_state.momentum_home + 1, 0, 5)
		game_state.momentum_away = clampi(game_state.momentum_away + 1, 0, 5)
		card_manager.draw(game_state.hand_home, game_state.deck_home, game_state.discard_home, 1, 5)
		card_manager.draw(game_state.hand_away, game_state.deck_away, game_state.discard_away, 1, 5)

	_update_ui()


func _queue_card_for_team(team: String, card: Dictionary, target := {}) -> bool:
	var cost: int = int(card.get("cost", 0))

	var momentum: int = game_state.momentum_home if team == "home" else game_state.momentum_away
	var queued_spent: int = game_state.queued_momentum_spent_home if team == "home" else game_state.queued_momentum_spent_away
	var remaining: int = momentum - queued_spent

	if cost > remaining:
		return false

	var entry: Dictionary = {
		"team": team,
		"card": card,
		"target": target,
		"cost": cost
	}

	if team == "home":
		game_state.queued_cards_home.append(entry)
		game_state.queued_momentum_spent_home += cost
	else:
		game_state.queued_cards_away.append(entry)
		game_state.queued_momentum_spent_away += cost

	_update_ui()
	return true


func _set_team_ready(team: String, ready: bool) -> void:
	if team == "home":
		game_state.home_ready = ready
	else:
		game_state.away_ready = ready

	_update_ui()

	if game_state.home_ready and game_state.away_ready:
		_execute_queued_cards_in_order()

func _on_ready_pressed() -> void:
	if game_state.phase != PHASE_CARD_QUEUE:
		return
	_set_team_ready(_queue_team, true)
	if not game_state.home_ready or not game_state.away_ready:
		var just_readied := _queue_team
		_queue_team = "away" if _queue_team == "home" else "home"
		result_text.text = "%s ready. %s queue turn." % [just_readied.capitalize(), _queue_team.capitalize()]
		_update_ui()


func _execute_queued_cards_in_order() -> void:
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
	var card_id := str(card.get("id", ""))

	if team == "home":
		game_state.momentum_home = max(game_state.momentum_home - cost, 0)
		_remove_card_from_team_hand_by_id("home", card_id)
		game_state.discard_home.append(card)
	else:
		game_state.momentum_away = max(game_state.momentum_away - cost, 0)
		_remove_card_from_team_hand_by_id("away", card_id)
		game_state.discard_away.append(card)

	effect_manager.add_effect({
		"effect_data": card.get("effect_data", {}),
		"queued_team": team
	}, "plays", 1)

	# optional combat log
	result_text.text += "\n%s played %s" % [team.capitalize(), str(card.get("name", "Card"))]


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
