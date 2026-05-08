extends PanelContainer

signal queue_requested(team: String, hand_index: int)
signal unqueue_requested(team: String, queue_index: int)
signal selection_toggled(team: String, card_id: String)
signal info_hold_started(card: Dictionary)
signal info_hold_ended()

var card_data: Dictionary = {}

enum InteractionMode { NONE, HAND, QUEUED }
var _mode: InteractionMode = InteractionMode.NONE

var _queue_team: String = ""
var _hand_index: int = -1
var _queued_index: int = -1

var _press_armed: bool = false
var _drag_started: bool = false
var _press_pointer_global: Vector2 = Vector2.ZERO
var _press_started_ms: int = 0
var _long_press_triggered: bool = false
var _press_is_touch: bool = false

const DRAG_START_PIXELS := 12.0
const LONG_PRESS_MOUSE_MS := 250
const LONG_PRESS_TOUCH_MS := 350


func _ready() -> void:
	set_process(true)


func setup(card: Dictionary) -> void:
	card_data = card.duplicate(true)
	var name_label := get_node_or_null("MarginContainer/VBoxContainer/NameLabel") as Label
	var stats_label := get_node_or_null("MarginContainer/VBoxContainer/StatsLabel") as Label
	if name_label:
		name_label.text = str(card.get("name", "Card"))
	if stats_label:
		stats_label.visible = false
		stats_label.text = ""


func set_selected_state(selected: bool) -> void:
	modulate = Color(0.58, 1.0, 0.68, 1.0) if selected else Color(1, 1, 1, 1)


func set_affordable_state(affordable: bool) -> void:
	modulate.a = 1.0 if affordable else 0.45


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
	_long_press_triggered = false
	_press_started_ms = 0
	_press_is_touch = false


func _gui_input(event: InputEvent) -> void:
	if _mode == InteractionMode.NONE:
		return
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_press_armed = true
			_drag_started = false
			_long_press_triggered = false
			_press_is_touch = false
			_press_pointer_global = get_global_mouse_position()
			_press_started_ms = Time.get_ticks_msec()
			accept_event()
		else:
			if _press_armed:
				if _long_press_triggered:
					info_hold_ended.emit()
				elif not mb.double_click and not _drag_started and _mode == InteractionMode.HAND:
					selection_toggled.emit(_queue_team, str(card_data.get("instance_id", card_data.get("id", ""))))
				accept_event()
			_reset_press_state()
		return
	var st := event as InputEventScreenTouch
	if st:
		if st.pressed:
			_press_armed = true
			_drag_started = false
			_long_press_triggered = false
			_press_is_touch = true
			_press_pointer_global = st.position
			_press_started_ms = Time.get_ticks_msec()
			accept_event()
		else:
			if _press_armed:
				if _long_press_triggered:
					info_hold_ended.emit()
				elif not st.double_tap and not _drag_started and _mode == InteractionMode.HAND:
					selection_toggled.emit(_queue_team, str(card_data.get("instance_id", card_data.get("id", ""))))
				accept_event()
			_reset_press_state()
		return
	var mm := event as InputEventMouseMotion
	if mm and _press_armed:
		accept_event()
	var sd := event as InputEventScreenDrag
	if sd and _press_armed:
		accept_event()


func _process(_delta: float) -> void:
	if not _press_armed or _long_press_triggered:
		return
	var held_ms := Time.get_ticks_msec() - _press_started_ms
	var threshold := LONG_PRESS_TOUCH_MS if _press_is_touch else LONG_PRESS_MOUSE_MS
	if held_ms >= threshold:
		_long_press_triggered = true
		info_hold_started.emit(card_data.duplicate(true))
