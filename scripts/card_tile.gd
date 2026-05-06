extends PanelContainer

signal queue_requested(team: String, hand_index: int)
signal unqueue_requested(team: String, queue_index: int)

var card_data: Dictionary = {}

enum InteractionMode { NONE, HAND, QUEUED }
var _mode: InteractionMode = InteractionMode.NONE

var _queue_team: String = ""
var _hand_index: int = -1
var _queued_index: int = -1

var _press_armed: bool = false
var _drag_started: bool = false
var _press_pointer_global: Vector2 = Vector2.ZERO

const DRAG_START_PIXELS := 12.0


func setup(card: Dictionary) -> void:
	card_data = card.duplicate(true)
	var name_label := get_node_or_null("MarginContainer/VBoxContainer/NameLabel") as Label
	var stats_label := get_node_or_null("MarginContainer/VBoxContainer/StatsLabel") as Label
	if name_label:
		name_label.text = str(card.get("name", "Card"))
	if stats_label:
		var cost := int(card.get("cost", 0))
		var ctype := str(card.get("type", ""))
		var scope := str(card.get("target_type", ""))
		var desc := str(card.get("description", ""))
		if desc.length() > 72:
			desc = desc.substr(0, 69) + "..."
		var lines: Array[String] = []
		lines.append("Cost: %d" % cost)
		if not ctype.is_empty():
			lines.append(ctype)
		if not scope.is_empty():
			lines.append(scope)
		if not desc.is_empty():
			lines.append(desc)
		stats_label.text = "\n".join(lines)


func configure_hand_interaction(enabled: bool, team: String, index: int) -> void:
	_reset_press_state()
	if enabled:
		_mode = InteractionMode.HAND
		_queue_team = team
		_hand_index = index
		_queued_index = -1
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_mode = InteractionMode.NONE
		_hand_index = -1
		_queued_index = -1
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func configure_queued_interaction(enabled: bool, team: String, queue_index: int) -> void:
	_reset_press_state()
	if enabled:
		_mode = InteractionMode.QUEUED
		_queue_team = team
		_queued_index = queue_index
		_hand_index = -1
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		_mode = InteractionMode.NONE
		_hand_index = -1
		_queued_index = -1
		mouse_filter = Control.MOUSE_FILTER_IGNORE


func _reset_press_state() -> void:
	_press_armed = false
	_drag_started = false


func _gui_input(event: InputEvent) -> void:
	if _mode == InteractionMode.QUEUED:
		var mbq := event as InputEventMouseButton
		if mbq and mbq.button_index == MOUSE_BUTTON_LEFT and not mbq.pressed:
			unqueue_requested.emit(_queue_team, _queued_index)
			accept_event()
		return

	if _mode != InteractionMode.HAND or _hand_index < 0:
		return
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_press_armed = true
			_drag_started = false
			_press_pointer_global = get_global_mouse_position()
		else:
			if _press_armed and not _drag_started:
				queue_requested.emit(_queue_team, _hand_index)
				accept_event()
			_press_armed = false
			_drag_started = false
		return
	var mm := event as InputEventMouseMotion
	if mm and _press_armed and not _drag_started:
		if get_global_mouse_position().distance_to(_press_pointer_global) >= DRAG_START_PIXELS:
			_drag_started = true
			var preview := Label.new()
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
			preview.text = "  %s  " % str(card_data.get("name", "Card"))
			var payload: Dictionary = {"type": "queue_hand_card", "team": _queue_team, "index": _hand_index}
			force_drag(payload, preview)
			accept_event()
