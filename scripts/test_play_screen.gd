extends CanvasLayer
class_name TestPlayScreen

const FIELD_SCENE := preload("res://scenes/field.tscn")
const _LogBuilder := preload("res://scripts/test_play_log_builder.gd")
const _Narrative := preload("res://scripts/test_play_narrative_builder.gd")
const _Presets := preload("res://scripts/test_play_presets.gd")
const MARKER_SIZE := Vector2(22, 22)
const MARKER_FONT := 9
const FIELD_SCALE := 1.35
const TEST_LOS_ROW := 17
const TEST_ZONE := 4
const DEFAULT_DEF_RUN := "run_def_01"
const DEFAULT_DEF_PASS := "pass_def_01"
const ROLE_ITEM_HEIGHT := 24
const ROLE_LIST_SHOW_ALL_UP_TO := 16
const ROLE_LIST_SCROLL_ROWS := 8

var _plays: PlaysCatalog
var _formations: FormationsCatalog
var _initial_offense_play_id: String = ""
var _field_grid: FieldGrid
var _field_host: Control
var _marker_root: Node2D
var _markers: Dictionary = {}
var _ball_badge: Label

var _offense_play_ids: Array[String] = []
var _defense_play_ids: Array[String] = []
var _off_pick: OptionButton
var _def_mode: OptionButton
var _def_pick: OptionButton
var _status: Label
var _speed_pick: OptionButton
var _log_text: RichTextLabel
var _role_list: ItemList
var _roles_section: VBoxContainer
var _roles_toggle_btn: Button
var _role_scroll: ScrollContainer
var _log_scroll: ScrollContainer
var _nav_prev: Button
var _nav_next: Button
var _nav_label: Label
var _ball_filter: CheckBox
var _changes_only: CheckBox
var _play_events_filter: CheckBox
var _preset_pick: OptionButton
var _presets: Array[Dictionary] = []
var _save_preset_dialog: AcceptDialog
var _save_preset_name_edit: LineEdit

var _rng := RandomNumberGenerator.new()
var _snapshots: Array = []
var _beats: Array[Dictionary] = []
var _beat_index: int = -1
var _playing: bool = false
var _playback_speed: float = 1.0
var _outcome_text: String = ""
var _saved_tick_authority: bool = false
var _saved_test_early_throw: bool = false
var _saved_test_verbose: bool = false
var _offense_seat: String = "home"
var _all_roles: Array[String] = []
var _role_filter: Dictionary = {}


func setup(plays: PlaysCatalog, formations: FormationsCatalog, initial_offense_play_id: String = "") -> void:
	_plays = plays
	_formations = formations
	_initial_offense_play_id = initial_offense_play_id


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 4242
	_build_ui()
	_load_presets_into_ui()
	_refresh_play_lists()
	_update_def_controls()


func _exit_tree() -> void:
	PlayTickEngine.tick_authoritative = _saved_tick_authority
	PlayTickEngine.test_disable_early_throw = _saved_test_early_throw
	PlayTickEngine.test_verbose_log = _saved_test_verbose


var _play_accum: float = 0.0


func _process(delta: float) -> void:
	if not _playing or _beats.is_empty():
		return
	_play_accum += delta
	if _play_accum < 0.35 / _playback_speed:
		return
	_play_accum = 0.0
	if _beat_index >= _beats.size() - 1:
		_playing = false
		_set_status(_outcome_text if not _outcome_text.is_empty() else "Playback finished.")
		return
	_beat_index += 1
	_apply_beat(_beat_index)
	if bool(_beats[_beat_index].get("pause", false)):
		_playing = false
		_set_status("Paused — %s" % str(_beats[_beat_index].get("header", "")))


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(root)

	var title := Label.new()
	title.text = "Test Play"
	title.add_theme_font_size_override("font_size", 20)
	root.add_child(title)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 6)
	root.add_child(bar)

	bar.add_child(_lbl("Offense"))
	_off_pick = OptionButton.new()
	_off_pick.custom_minimum_size = Vector2(160, 0)
	_off_pick.item_selected.connect(func(_i: int) -> void: _update_def_controls())
	bar.add_child(_off_pick)

	bar.add_child(_lbl("Defense"))
	_def_mode = OptionButton.new()
	_def_mode.add_item("Solo (default)", 0)
	_def_mode.add_item("Opponent play", 1)
	_def_mode.item_selected.connect(func(_i: int) -> void: _update_def_controls())
	bar.add_child(_def_mode)

	_def_pick = OptionButton.new()
	_def_pick.custom_minimum_size = Vector2(140, 0)
	bar.add_child(_def_pick)

	bar.add_child(_lbl("Speed"))
	_speed_pick = OptionButton.new()
	_speed_pick.add_item("1×", 0)
	_speed_pick.add_item("2×", 1)
	_speed_pick.item_selected.connect(_on_speed_changed)
	bar.add_child(_speed_pick)

	for txt in ["Reseed", "Snap", "Step", "Play", "Close"]:
		var b := Button.new()
		b.text = txt
		match txt:
			"Reseed":
				b.pressed.connect(_on_reseed_pressed)
			"Snap":
				b.pressed.connect(_on_snap_pressed)
			"Step":
				b.pressed.connect(_on_step_pressed)
			"Play":
				b.pressed.connect(_on_play_pressed)
			"Close":
				b.pressed.connect(_on_close_pressed)
		bar.add_child(b)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Full-screen test sim. Snap to begin. Step advances one tick beat."
	root.add_child(_status)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)

	_field_host = Control.new()
	_field_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_host.size_flags_stretch_ratio = 1.15
	_field_host.custom_minimum_size = Vector2(520, 400)
	body.add_child(_field_host)

	var field_center := CenterContainer.new()
	field_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	field_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field_host.add_child(field_center)

	var field_inst := FIELD_SCENE.instantiate() as Node2D
	field_inst.scale = Vector2(FIELD_SCALE, FIELD_SCALE)
	field_center.add_child(field_inst)
	_field_grid = field_inst as FieldGrid
	if _field_grid:
		_field_grid.is_user_perspective_home = true

	_marker_root = Node2D.new()
	_marker_root.name = "TestPlayMarkers"
	_marker_root.z_index = 40
	if _field_grid:
		_field_grid.add_child(_marker_root)

	_ball_badge = Label.new()
	_ball_badge.text = "🏈"
	_ball_badge.visible = false
	_ball_badge.z_index = 41
	_ball_badge.add_theme_font_size_override("font_size", 16)
	if _field_grid:
		_field_grid.add_child(_ball_badge)

	var log_panel := VBoxContainer.new()
	log_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_panel.size_flags_stretch_ratio = 1.0
	log_panel.custom_minimum_size = Vector2(320, 0)
	body.add_child(log_panel)

	var filter_row := HBoxContainer.new()
	log_panel.add_child(filter_row)

	_ball_filter = CheckBox.new()
	_ball_filter.text = "Ball"
	_ball_filter.button_pressed = true
	_ball_filter.toggled.connect(func(_on: bool) -> void: _refresh_beat_display())
	filter_row.add_child(_ball_filter)

	_changes_only = CheckBox.new()
	_changes_only.text = "Changes only"
	_changes_only.toggled.connect(func(_on: bool) -> void: _refresh_beat_display())
	filter_row.add_child(_changes_only)

	_play_events_filter = CheckBox.new()
	_play_events_filter.text = "Play events"
	_play_events_filter.tooltip_text = "Pressure, throw resolution, and other non-player lines while focused."
	_play_events_filter.toggled.connect(func(_on: bool) -> void: _refresh_beat_display())
	filter_row.add_child(_play_events_filter)

	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 4)
	log_panel.add_child(preset_row)

	preset_row.add_child(_lbl("Preset"))
	_preset_pick = OptionButton.new()
	_preset_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preset_pick.item_selected.connect(_on_preset_selected)
	preset_row.add_child(_preset_pick)

	var apply_preset_btn := Button.new()
	apply_preset_btn.text = "Apply"
	apply_preset_btn.pressed.connect(_on_preset_apply)
	preset_row.add_child(apply_preset_btn)

	var save_preset_btn := Button.new()
	save_preset_btn.text = "Save as…"
	save_preset_btn.pressed.connect(_on_preset_save_as)
	preset_row.add_child(save_preset_btn)

	var update_preset_btn := Button.new()
	update_preset_btn.text = "Update"
	update_preset_btn.pressed.connect(_on_preset_update)
	preset_row.add_child(update_preset_btn)

	var delete_preset_btn := Button.new()
	delete_preset_btn.text = "Delete"
	delete_preset_btn.pressed.connect(_on_preset_delete)
	preset_row.add_child(delete_preset_btn)

	_save_preset_dialog = AcceptDialog.new()
	_save_preset_dialog.title = "Save focus preset"
	_save_preset_dialog.ok_button_text = "Save"
	_save_preset_name_edit = LineEdit.new()
	_save_preset_name_edit.placeholder_text = "Preset name (e.g. WR1 vs CB1)"
	_save_preset_name_edit.custom_minimum_size = Vector2(280, 0)
	_save_preset_dialog.add_child(_save_preset_name_edit)
	_save_preset_dialog.confirmed.connect(_on_save_preset_dialog_confirmed)
	add_child(_save_preset_dialog)

	_roles_toggle_btn = Button.new()
	_roles_toggle_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_roles_toggle_btn.text = "Focus roles ▶ (all)"
	_roles_toggle_btn.pressed.connect(_toggle_roles_section)
	log_panel.add_child(_roles_toggle_btn)

	_roles_section = VBoxContainer.new()
	_roles_section.visible = false
	log_panel.add_child(_roles_section)

	var role_btns := HBoxContainer.new()
	_roles_section.add_child(role_btns)
	var select_all_btn := Button.new()
	select_all_btn.text = "All"
	select_all_btn.pressed.connect(_on_roles_select_all)
	role_btns.add_child(select_all_btn)
	var clear_roles_btn := Button.new()
	clear_roles_btn.text = "None"
	clear_roles_btn.pressed.connect(_on_roles_clear_all)
	role_btns.add_child(clear_roles_btn)

	_role_scroll = ScrollContainer.new()
	_role_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_roles_section.add_child(_role_scroll)

	_role_list = ItemList.new()
	_role_list.select_mode = ItemList.SELECT_MULTI
	_role_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_role_list.item_selected.connect(func(_i: int) -> void: _on_role_filter_changed())
	_role_list.multi_selected.connect(func(_i: int, _sel: bool) -> void: _on_role_filter_changed())
	_role_scroll.add_child(_role_list)

	var nav_row := HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 6)
	log_panel.add_child(nav_row)

	_nav_prev = Button.new()
	_nav_prev.text = "◀ Prev"
	_nav_prev.pressed.connect(_on_prev_beat_pressed)
	nav_row.add_child(_nav_prev)

	_nav_label = Label.new()
	_nav_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nav_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nav_label.text = "—"
	nav_row.add_child(_nav_label)

	_nav_next = Button.new()
	_nav_next.text = "Next ▶"
	_nav_next.pressed.connect(_on_next_beat_pressed)
	nav_row.add_child(_nav_next)

	_log_scroll = ScrollContainer.new()
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.custom_minimum_size = Vector2(0, 240)
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	log_panel.add_child(_log_scroll)

	_log_text = RichTextLabel.new()
	_log_text.bbcode_enabled = false
	_log_text.scroll_active = false
	_log_text.fit_content = true
	_log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_text.add_theme_font_size_override("normal_font_size", 13)
	_log_scroll.add_child(_log_text)


func _lbl(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


func _refresh_play_lists() -> void:
	_offense_play_ids.clear()
	_defense_play_ids.clear()
	_off_pick.clear()
	_def_pick.clear()
	if _plays == null:
		return
	for pid in _plays.all_play_ids():
		var row: Dictionary = _plays.get_play(pid)
		var side := str(row.get("side", ""))
		var bucket := str(row.get("play_type", ""))
		if side == "offense" and (bucket == "run" or bucket == "pass"):
			_offense_play_ids.append(pid)
			_off_pick.add_item("%s — %s" % [pid, row.get("name", "")])
		elif side == "defense" and (bucket == "run_def" or bucket == "pass_def"):
			_defense_play_ids.append(pid)
			_def_pick.add_item("%s — %s" % [pid, row.get("name", "")])
	_offense_play_ids.sort()
	_defense_play_ids.sort()
	if not _initial_offense_play_id.is_empty():
		for i in _offense_play_ids.size():
			if _offense_play_ids[i] == _initial_offense_play_id:
				_off_pick.select(i)
				break
		_initial_offense_play_id = ""


func _update_def_controls() -> void:
	var solo := _def_mode.selected == 0
	_def_pick.visible = not solo
	_def_pick.disabled = solo


func _on_speed_changed(_idx: int) -> void:
	_playback_speed = 2.0 if _speed_pick.selected == 1 else 1.0


func _on_reseed_pressed() -> void:
	_rng.randomize()
	_set_status("New RNG seed.")


func _on_snap_pressed() -> void:
	_run_sim_and_show()


func _on_step_pressed() -> void:
	_on_next_beat_pressed()


func _on_prev_beat_pressed() -> void:
	_playing = false
	if _beats.is_empty():
		_on_snap_pressed()
		return
	if _beat_index > 0:
		_beat_index -= 1
		_apply_beat(_beat_index)
		_update_beat_status()
	else:
		_set_status("At snap.")


func _on_next_beat_pressed() -> void:
	_playing = false
	if _beats.is_empty():
		_on_snap_pressed()
		return
	if _beat_index < _beats.size() - 1:
		_beat_index += 1
		_apply_beat(_beat_index)
		_update_beat_status()
	else:
		_set_status(_outcome_text if not _outcome_text.is_empty() else "End of play.")


func _on_play_pressed() -> void:
	if _beats.is_empty():
		_on_snap_pressed()
		if _beats.is_empty():
			return
	if _beat_index < 0:
		_beat_index = 0
		_apply_beat(0)
	_play_accum = 0.0
	_playing = true


func _on_close_pressed() -> void:
	queue_free()


func _toggle_roles_section() -> void:
	_roles_section.visible = not _roles_section.visible
	_update_roles_toggle_label()


func _update_roles_toggle_label() -> void:
	if _roles_toggle_btn == null:
		return
	var arrow := "▼" if _roles_section.visible else "▶"
	var n := _role_list.item_count if _role_list else 0
	var sel := _selected_role_count()
	var filt := "all" if not _is_focus_mode() else "%d focused" % sel
	_roles_toggle_btn.text = "Focus roles %s (%s)" % [arrow, filt]


func _selected_role_count() -> int:
	var c := 0
	for i in _role_list.item_count:
		if _role_list.is_selected(i):
			c += 1
	return c


func _sync_role_filter_from_list() -> void:
	_role_filter.clear()
	var n := _role_list.item_count
	var sel := _selected_role_count()
	if n == 0 or sel == 0 or sel >= n:
		return
	for i in n:
		if _role_list.is_selected(i):
			_role_filter[_role_list.get_item_text(i)] = true


func _on_roles_select_all() -> void:
	_select_all_roles(true)
	_on_role_filter_changed()


func _deselect_all_roles() -> void:
	for i in _role_list.item_count:
		_role_list.deselect(i)


## ItemList.select(index, single): single=true clears other picks; single=false adds to multi-selection.
func _select_all_roles(selected: bool) -> void:
	_deselect_all_roles()
	if not selected:
		return
	for i in _role_list.item_count:
		_role_list.select(i, false)


func _on_roles_clear_all() -> void:
	_select_all_roles(false)
	_on_role_filter_changed()


func _on_role_filter_changed() -> void:
	_sync_role_filter_from_list()
	_update_roles_toggle_label()
	if _beat_index >= 0 and _beat_index < _beats.size():
		var snap_i := int(_beats[_beat_index].get("snapshot_index", 0))
		_render_snapshot(snap_i)
	_refresh_beat_display()


func _is_focus_mode() -> bool:
	return not _role_filter.is_empty()


func _role_in_focus(role: String) -> bool:
	if role.is_empty():
		return false
	if not _is_focus_mode():
		return true
	return _role_filter.has(role)


func _carrier_role_in_snap(snap: Dictionary) -> String:
	var cid := str(snap.get("ball_carrier_id", ""))
	if cid.is_empty():
		return ""
	for pd_v in snap.get("players", []) as Array:
		if typeof(pd_v) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = pd_v
		if str(pd.get("player_id", "")) == cid:
			return str(pd.get("role", ""))
	return ""


func _should_show_ball_for_snap(snap: Dictionary) -> bool:
	if not _ball_filter.button_pressed:
		return false
	if not _is_focus_mode():
		return true
	var car_role := _carrier_role_in_snap(snap)
	return _role_in_focus(car_role)


func _load_presets_into_ui() -> void:
	_presets = _Presets.load_all()
	_refresh_preset_dropdown()


func _refresh_preset_dropdown() -> void:
	if _preset_pick == null:
		return
	_preset_pick.clear()
	_preset_pick.add_item("— Custom —")
	for p in _presets:
		_preset_pick.add_item(str(p.get("name", "Preset")))
	_preset_pick.select(0)


func _current_preset_index() -> int:
	return _preset_pick.selected - 1 if _preset_pick else -1


func _on_preset_selected(_idx: int) -> void:
	pass


func _on_preset_apply() -> void:
	var idx := _current_preset_index()
	if idx < 0:
		return
	var preset: Dictionary = _presets[idx]
	var want: Array = preset.get("roles", []) as Array
	var missing: Array[String] = []
	_deselect_all_roles()
	for role_v in want:
		var role := str(role_v)
		var found := false
		for i in _role_list.item_count:
			if _role_list.get_item_text(i) == role:
				_role_list.select(i, false)
				found = true
				break
		if not found:
			missing.append(role)
	_ball_filter.button_pressed = bool(preset.get("show_ball", true))
	_play_events_filter.button_pressed = bool(preset.get("play_events", false))
	_on_role_filter_changed()
	if not missing.is_empty():
		_set_status("Applied preset; missing on field: %s" % ", ".join(missing))
	else:
		_set_status("Applied preset: %s" % str(preset.get("name", "")))


func _on_preset_save_as() -> void:
	if _role_list.item_count == 0:
		_set_status("Snap first to list roles.")
		return
	if _selected_role_count() == 0:
		_set_status("Select at least one focus role before saving.")
		return
	_save_preset_name_edit.text = ""
	_save_preset_dialog.popup_centered(Vector2i(360, 120))


func _on_save_preset_dialog_confirmed() -> void:
	var name := _save_preset_name_edit.text.strip_edges()
	if name.is_empty():
		_set_status("Preset name required.")
		return
	var roles: Array[String] = []
	for i in _role_list.item_count:
		if _role_list.is_selected(i):
			roles.append(_role_list.get_item_text(i))
	var preset := {
		"id": _Presets.make_id(name),
		"name": name,
		"roles": roles,
		"show_ball": _ball_filter.button_pressed,
		"play_events": _play_events_filter.button_pressed,
	}
	_presets.append(preset)
	var err := _Presets.save_all(_presets)
	if err != OK:
		_set_status("Could not save presets.")
		return
	_refresh_preset_dropdown()
	for i in _preset_pick.item_count:
		if _preset_pick.get_item_text(i) == name:
			_preset_pick.select(i)
			break
	_set_status("Saved preset: %s" % name)


func _on_preset_update() -> void:
	var idx := _current_preset_index()
	if idx < 0:
		_set_status("Choose a preset to update, or use Save as…")
		return
	if _selected_role_count() == 0:
		_set_status("Select at least one focus role.")
		return
	var roles: Array[String] = []
	for i in _role_list.item_count:
		if _role_list.is_selected(i):
			roles.append(_role_list.get_item_text(i))
	_presets[idx]["roles"] = roles
	_presets[idx]["show_ball"] = _ball_filter.button_pressed
	_presets[idx]["play_events"] = _play_events_filter.button_pressed
	var err := _Presets.save_all(_presets)
	if err != OK:
		_set_status("Could not save presets.")
		return
	_refresh_preset_dropdown()
	_preset_pick.select(idx + 1)
	_set_status("Updated preset: %s" % str(_presets[idx].get("name", "")))


func _on_preset_delete() -> void:
	var idx := _current_preset_index()
	if idx < 0:
		_set_status("Choose a preset to delete.")
		return
	var name := str(_presets[idx].get("name", ""))
	_presets.remove_at(idx)
	_Presets.save_all(_presets)
	_refresh_preset_dropdown()
	_set_status("Deleted preset: %s" % name)


func _selected_offense_id() -> String:
	var i := _off_pick.selected
	if i < 0 or i >= _offense_play_ids.size():
		return ""
	return _offense_play_ids[i]


func _selected_defense_id() -> String:
	if _def_mode.selected == 0:
		var off := _selected_offense_id()
		var bucket := _plays.bucket(off) if _plays else ""
		return DEFAULT_DEF_PASS if bucket == "pass" else DEFAULT_DEF_RUN
	var i := _def_pick.selected
	if i < 0 or i >= _defense_play_ids.size():
		return DEFAULT_DEF_RUN
	return _defense_play_ids[i]


func _run_sim_and_show() -> void:
	_clear_markers()
	_playing = false
	_snapshots.clear()
	_beats.clear()
	_beat_index = -1
	_outcome_text = ""
	_log_text.clear()
	var off_id := _selected_offense_id()
	if off_id.is_empty():
		_set_status("Select an offense play.")
		return
	var def_id := _selected_defense_id()
	var off_row: Dictionary = _plays.get_play(off_id)
	var bucket := str(off_row.get("play_type", ""))
	if bucket != "run" and bucket != "pass":
		_set_status("Only run/pass offense plays are supported.")
		return
	var off_fid := _plays.formation_id_for(off_id)
	var def_fid := _plays.formation_id_for(def_id)
	var off_form: Dictionary = _formations.get_by_id(off_fid)
	var def_form: Dictionary = _formations.get_by_id(def_fid)
	if off_form.is_empty() or def_form.is_empty():
		_set_status("Missing formation for play.")
		return

	_saved_tick_authority = PlayTickEngine.tick_authoritative
	_saved_test_early_throw = PlayTickEngine.test_disable_early_throw
	_saved_test_verbose = PlayTickEngine.test_verbose_log
	PlayTickEngine.tick_authoritative = true
	PlayTickEngine.test_disable_early_throw = true
	PlayTickEngine.test_verbose_log = true
	_offense_seat = "home"

	var carrier_id := ""
	var bcr := str(off_row.get("ball_carrier_role", ""))
	if bucket == "run" and not bcr.is_empty():
		var pool := TestPlayStatFactory.build_team_pool("test_off")
		var slots := PlaySimContext.lineup_slots(pool, off_form)
		for s in slots:
			if str(s.get("role", "")) == bcr:
				var pl: Dictionary = s.get("player", {}) as Dictionary
				carrier_id = str(pl.get("id", ""))
				break

	var def_row: Dictionary = _plays.get_play(def_id) as Dictionary
	var ctx := PlaySimContext.build(
		_rng,
		"home",
		off_id,
		def_id,
		off_row,
		TEST_ZONE,
		TestPlayStatFactory.build_team_pool("test_off"),
		TestPlayStatFactory.build_team_pool("test_def"),
		off_form,
		def_form,
		{"test_off": "Test Offense", "test_def": "Test Defense"},
		def_row
	)
	var engine := PlayTickEngine.new()
	var tr: Dictionary = engine.run(ctx, TEST_LOS_ROW, bucket, carrier_id, off_row)
	_snapshots = tr.get("snapshots", []) as Array
	var sim_log: PlayEventLog = tr.get("sim_event_log", null) as PlayEventLog
	var tpr: Dictionary = tr.get("tick_play_result", {}) as Dictionary
	if sim_log == null:
		sim_log = PlayEventLog.new()

	var saved_focus := _capture_focus_role_selection()
	_populate_role_filters(saved_focus)
	_beats = _Narrative.build_beats(_snapshots, sim_log, tpr, bucket)

	if not tpr.is_empty():
		var td := int(tpr.get("tile_delta", 0))
		_outcome_text = "Outcome: %+d tile rows toward goal." % td
		var toe: Dictionary = tpr.get("turnover_outcome", {}) as Dictionary
		if bool(toe.get("occurred", false)):
			_outcome_text = "Turnover: %s." % str(toe.get("text", toe.get("ended_by", "")))
	else:
		_outcome_text = "Sim finished."

	if _snapshots.is_empty() or _beats.is_empty():
		_set_status("No snapshots or beats produced.")
		return

	_beat_index = 0
	_apply_beat(0)
	_update_beat_status()
	var mode := "solo default defense" if _def_mode.selected == 0 else def_id
	var end_snap: Dictionary = _snapshots[_snapshots.size() - 1] as Dictionary
	var end_reason := str(end_snap.get("play_end_reason", ""))
	var reason_txt := " Ended: %s." % end_reason if not end_reason.is_empty() else ""
	_set_status("Snap: %s vs %s — %d beats, %d ticks.%s Step or Play." % [
		off_id, mode, _beats.size(), _snapshots.size() - 1, reason_txt
	])


func _capture_focus_role_selection() -> Array[String]:
	var out: Array[String] = []
	if _role_list == null:
		return out
	for i in _role_list.item_count:
		if _role_list.is_selected(i):
			out.append(_role_list.get_item_text(i))
	return out


func _populate_role_filters(restore_roles: Array[String] = []) -> void:
	_all_roles.clear()
	_role_list.clear()
	_role_filter.clear()
	if _snapshots.is_empty():
		return
	var seen: Dictionary = {}
	for snap_v in _snapshots:
		for role in _LogBuilder.all_roles_in_snap(snap_v as Dictionary):
			seen[role] = true
	for role in seen.keys():
		_all_roles.append(str(role))
	_all_roles.sort()
	for role in _all_roles:
		_role_list.add_item(role)
	_resize_role_list()
	if restore_roles.is_empty():
		_select_all_roles(true)
	else:
		_deselect_all_roles()
		for role in restore_roles:
			for i in _role_list.item_count:
				if _role_list.get_item_text(i) == role:
					_role_list.select(i, false)
					break
	_sync_role_filter_from_list()
	_update_roles_toggle_label()


func _resize_role_list() -> void:
	if _role_list == null or _role_scroll == null:
		return
	var n := _role_list.item_count
	var content_h := maxi(n, 1) * ROLE_ITEM_HEIGHT
	_role_list.custom_minimum_size = Vector2(280, content_h)
	var viewport_rows := n if n <= ROLE_LIST_SHOW_ALL_UP_TO else ROLE_LIST_SCROLL_ROWS
	_role_scroll.custom_minimum_size = Vector2(0, viewport_rows * ROLE_ITEM_HEIGHT)
	_role_scroll.vertical_scroll_mode = (
		ScrollContainer.SCROLL_MODE_DISABLED if n <= ROLE_LIST_SHOW_ALL_UP_TO
		else ScrollContainer.SCROLL_MODE_AUTO
	)


func _apply_beat(idx: int) -> void:
	if idx < 0 or idx >= _beats.size():
		return
	var beat: Dictionary = _beats[idx]
	var snap_i := int(beat.get("snapshot_index", 0))
	snap_i = clampi(snap_i, 0, _snapshots.size() - 1)
	_render_snapshot(snap_i)
	_refresh_beat_display()
	_update_nav_label()


func _refresh_beat_display() -> void:
	if _log_text == null or _beat_index < 0 or _beat_index >= _beats.size():
		return
	_log_text.text = _Narrative.format_beat(
		_beats[_beat_index],
		_role_filter,
		_ball_filter.button_pressed,
		_play_events_filter.button_pressed,
		_changes_only.button_pressed
	)
	if _log_scroll:
		_log_text.custom_minimum_size.x = maxf(_log_scroll.size.x - 12.0, 280.0)
		call_deferred("_scroll_log_top")


func _scroll_log_top() -> void:
	if _log_scroll:
		_log_scroll.scroll_vertical = 0


func _update_nav_label() -> void:
	if _nav_label == null:
		return
	if _beats.is_empty() or _beat_index < 0:
		_nav_label.text = "—"
		_nav_prev.disabled = true
		_nav_next.disabled = true
		return
	_nav_label.text = "Beat %d / %d" % [_beat_index + 1, _beats.size()]
	_nav_prev.disabled = _beat_index <= 0
	_nav_next.disabled = _beat_index >= _beats.size() - 1


func _update_beat_status() -> void:
	if _beat_index < 0 or _beat_index >= _beats.size():
		return
	var beat := _beats[_beat_index]
	var extra := " (paused)" if bool(beat.get("pause", false)) else ""
	_set_status("%s — beat %d / %d%s" % [
		str(beat.get("header", "")),
		_beat_index + 1,
		_beats.size(),
		extra,
	])


func _clear_markers() -> void:
	_markers.clear()
	if _marker_root == null:
		return
	for c in _marker_root.get_children():
		c.queue_free()
	if _ball_badge:
		_ball_badge.visible = false


func _render_snapshot(idx: int) -> void:
	if idx < 0 or idx >= _snapshots.size():
		return
	_apply_snap(_snapshots[idx] as Dictionary)


func _apply_snap(snap: Dictionary) -> void:
	var carrier_id := str(snap.get("ball_carrier_id", ""))
	var plist: Array = snap.get("players", []) as Array
	var seen: Dictionary = {}
	for pd_v in plist:
		if typeof(pd_v) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = pd_v
		var pid := str(pd.get("player_id", ""))
		var role := str(pd.get("role", ""))
		if pid.is_empty():
			continue
		seen[pid] = true
		var in_focus := _role_in_focus(role)
		var wp := _world_pos(pd)
		var is_def := str(pd.get("side", "")) == "def"
		var panel: Control = _markers.get(pid, null) as Control
		if panel == null:
			panel = _make_marker(role, is_def)
			_marker_root.add_child(panel)
			_markers[pid] = panel
		panel.visible = in_focus
		if not in_focus:
			continue
		panel.position = wp - MARKER_SIZE * 0.5
		_set_carrier_highlight(panel, pid == carrier_id)
	for pid in _markers.keys():
		if not seen.has(pid):
			var p: Control = _markers[pid] as Control
			if is_instance_valid(p):
				p.queue_free()
			_markers.erase(pid)
	if _ball_badge:
		if not carrier_id.is_empty() and _should_show_ball_for_snap(snap):
			var car_pd: Dictionary = {}
			for pd_v2 in plist:
				if typeof(pd_v2) == TYPE_DICTIONARY and str(pd_v2.get("player_id", "")) == carrier_id:
					car_pd = pd_v2
					break
			if not car_pd.is_empty() and _role_in_focus(str(car_pd.get("role", ""))):
				var wp2 := _world_pos(car_pd)
				_ball_badge.position = wp2 + Vector2(-8, -22)
				_ball_badge.visible = true
			else:
				_ball_badge.visible = false
		else:
			_ball_badge.visible = false


func _world_pos(pd: Dictionary) -> Vector2:
	if _field_grid == null:
		return Vector2.ZERO
	var g_row := int(pd.get("global_row", 0))
	var g_col := int(pd.get("global_col", 0))
	var offense_home := _offense_seat == "home"
	var is_def := str(pd.get("side", "")) == "def"
	var disp_r: int
	if is_def:
		var d := int(_field_grid.perspective_row(g_row, offense_home))
		disp_r = clampi(d - 1, 0, FieldGrid.TOTAL_ROWS - 1)
	else:
		disp_r = int(_field_grid.perspective_row(g_row, offense_home))
		disp_r = clampi(disp_r, 0, FieldGrid.TOTAL_ROWS - 1)
	var base: Vector2 = _field_grid.world_pos_from_tile(disp_r, g_col)
	return base + ZoneCoverageRunner.visual_world_offset(_field_grid, pd)


func _make_marker(role_label: String, is_defense: bool) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = MARKER_SIZE
	panel.size = MARKER_SIZE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.35, 0.85, 1.0, 0.88) if not is_defense else Color(1.0, 0.55, 0.2, 0.88)
	sb.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	panel.set_meta("stylebox", sb)
	var lbl := Label.new()
	var abbrev := role_label.strip_edges()
	if abbrev.length() > 3:
		abbrev = abbrev.substr(0, 3)
	lbl.text = abbrev
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", MARKER_FONT)
	panel.add_child(lbl)
	return panel


func _set_carrier_highlight(panel: Panel, on: bool) -> void:
	var sb: StyleBoxFlat = panel.get_meta("stylebox", null) as StyleBoxFlat
	if sb == null:
		return
	var w := 3 if on else 0
	sb.border_width_left = w
	sb.border_width_top = w
	sb.border_width_right = w
	sb.border_width_bottom = w
	sb.border_color = Color(1.0, 0.92, 0.2, 1.0) if on else Color(0, 0, 0, 0)


func _set_status(t: String) -> void:
	if _status:
		_status.text = t
