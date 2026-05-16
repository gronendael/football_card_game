extends CanvasLayer
class_name PlayCreatorTool

const PLAYS_PATH := "res://data/plays.json"
const ToolsModalLayout := preload("res://scripts/tools_modal_layout.gd")
const LIST_W := 720
const COL1_W := 220
const ASSIGN_W := 200
const GRID_W := 280
const PANEL_MIN_X := 820
const GRID_MIN_H := 660

const SUBTYPE_LABELS: Dictionary = {
	"run": "Run",
	"pass": "Pass",
	"spot_kick": "Spot kick",
	"punt": "Punt",
	"kickoff": "Kickoff",
	"run_def": "Run def",
	"pass_def": "Pass def",
	"fg_xp_def": "FG/XP def",
	"punt_return": "Punt return",
	"kickoff_return": "Kickoff return",
}

const SUBTYPES_BY_SIDE: Dictionary = {
	"offense": ["run", "pass", "spot_kick", "punt", "kickoff"],
	"defense": ["run_def", "pass_def", "fg_xp_def", "punt_return", "kickoff_return"],
	"special": ["spot_kick", "punt", "kickoff"],
}

var _on_saved: Callable = Callable()
var _on_test_play: Callable = Callable()
var _formations: FormationsCatalog
var _data: Dictionary = {}
var _edit_is_new: bool = false
var _editing_id: String = ""
var _dirty: bool = false
var _saved_snapshot: Dictionary = {}

var _dim: ColorRect
var _modal_scroll: ScrollContainer
var _panel: PanelContainer
var _stack: MarginContainer
var _list_view: VBoxContainer
var _editor_view: VBoxContainer
var _play_tree: Tree
var _filter_search: LineEdit
var _filter_type: OptionButton
var _filter_subtype: OptionButton
var _filter_formation: OptionButton
var _sort_col: int = 0
var _sort_asc: bool = true
var _id_readout: LineEdit
var _name_edit: LineEdit
var _desc_edit: TextEdit
var _side_pick: OptionButton
var _type_pick: OptionButton
var _formation_pick: OptionButton
var _play_editor: PlayEditorField
var _assign_box: VBoxContainer
var _qb_mode: OptionButton
var _qb_dropback: SpinBox
var _qb_handoff_role: OptionButton
var _prog_primary: OptionButton
var _prog_secondary: OptionButton
var _prog_tertiary: OptionButton
var _ball_carrier_role: OptionButton
var _role_actions: Dictionary = {}
var _status_label: Label


func setup(plays: PlaysCatalog, formations: FormationsCatalog, on_saved: Callable, on_test_play: Callable = Callable()) -> void:
	_formations = formations
	_on_saved = on_saved
	_on_test_play = on_test_play
	_data.clear()
	for pid in plays.all_play_ids():
		var row: Dictionary = plays.get_play(pid).duplicate(true)
		_data[pid] = row


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_refresh_formation_filter()
	_rebuild_subtype_filter()
	_show_list()


func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	var margin_wrap := MarginContainer.new()
	margin_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_wrap.add_theme_constant_override("margin_left", 12)
	margin_wrap.add_theme_constant_override("margin_right", 12)
	margin_wrap.add_theme_constant_override("margin_top", 12)
	margin_wrap.add_theme_constant_override("margin_bottom", 12)
	add_child(margin_wrap)

	_modal_scroll = ToolsModalLayout.add_centered_scroll(margin_wrap)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(PANEL_MIN_X, 0)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.14, 0.14, 0.16, 1.0)
	psb.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", psb)
	_modal_scroll.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	_stack = MarginContainer.new()
	margin.add_child(_stack)
	_list_view = _build_list_view()
	_editor_view = _build_editor_view()
	_stack.add_child(_list_view)
	_stack.add_child(_editor_view)
	_editor_view.visible = false


func _build_list_view() -> VBoxContainer:
	var vb := VBoxContainer.new()
	var title := Label.new()
	title.text = "Play Creator"
	title.add_theme_font_size_override("font_size", 22)
	vb.add_child(title)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	vb.add_child(filter_row)
	filter_row.add_child(_mk_lbl("Search"))
	_filter_search = LineEdit.new()
	_filter_search.placeholder_text = "Play name"
	_filter_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_search.text_changed.connect(func(_t: String) -> void: _refresh_play_list())
	filter_row.add_child(_filter_search)
	filter_row.add_child(_mk_lbl("Type"))
	_filter_type = OptionButton.new()
	_filter_type.add_item("All", 0)
	_filter_type.add_item("Offense", 1)
	_filter_type.add_item("Defense", 2)
	_filter_type.add_item("Special", 3)
	_filter_type.item_selected.connect(_on_filter_type_changed)
	filter_row.add_child(_filter_type)
	filter_row.add_child(_mk_lbl("Sub-type"))
	_filter_subtype = OptionButton.new()
	_filter_subtype.custom_minimum_size = Vector2(120, 0)
	_filter_subtype.item_selected.connect(func(_i: int) -> void: _refresh_play_list())
	filter_row.add_child(_filter_subtype)
	filter_row.add_child(_mk_lbl("Formation"))
	_filter_formation = OptionButton.new()
	_filter_formation.custom_minimum_size = Vector2(140, 0)
	_filter_formation.item_selected.connect(func(_i: int) -> void: _refresh_play_list())
	filter_row.add_child(_filter_formation)

	_play_tree = Tree.new()
	_play_tree.columns = 4
	_play_tree.column_titles_visible = true
	_play_tree.hide_root = true
	_play_tree.set_column_title(0, "ID")
	_play_tree.set_column_title(1, "Name")
	_play_tree.set_column_title(2, "Type")
	_play_tree.set_column_title(3, "Formation")
	_play_tree.set_column_expand(1, true)
	_play_tree.custom_minimum_size = Vector2(LIST_W, 360)
	_play_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_play_tree.column_title_clicked.connect(_on_tree_column_clicked)
	_play_tree.item_activated.connect(_on_tree_activated)
	vb.add_child(_play_tree)

	var row := HBoxContainer.new()
	vb.add_child(row)
	for txt in ["Add…", "Edit", "Delete", "Close"]:
		var b := Button.new()
		b.text = txt
		match txt:
			"Add…":
				b.pressed.connect(_on_add_pressed)
			"Edit":
				b.pressed.connect(_on_edit_pressed)
			"Delete":
				b.pressed.connect(_on_delete_pressed)
			"Close":
				b.pressed.connect(_on_close_pressed)
		row.add_child(b)
	return vb


func _build_editor_view() -> VBoxContainer:
	var vb := VBoxContainer.new()
	var row_cols := HBoxContainer.new()
	row_cols.add_theme_constant_override("separation", 8)
	row_cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(row_cols)

	var col1 := VBoxContainer.new()
	col1.custom_minimum_size = Vector2(COL1_W, 0)
	row_cols.add_child(col1)
	var id_box := _labeled("Id", _mk_id_readout())
	_id_readout = id_box.get_child(1) as LineEdit
	col1.add_child(id_box)
	var name_box := _labeled("Name", _mk_line_edit())
	_name_edit = name_box.get_child(1) as LineEdit
	col1.add_child(name_box)
	var desc_box := _labeled("Description", _mk_desc_edit())
	_desc_edit = desc_box.get_child(1) as TextEdit
	col1.add_child(desc_box)
	_side_pick = OptionButton.new()
	_side_pick.add_item("offense", 0)
	_side_pick.add_item("defense", 1)
	_side_pick.add_item("special", 2)
	_side_pick.item_selected.connect(_on_side_changed)
	col1.add_child(_labeled("Side", _side_pick))
	_type_pick = OptionButton.new()
	_type_pick.item_selected.connect(_on_type_changed)
	col1.add_child(_labeled("Play type", _type_pick))
	_formation_pick = OptionButton.new()
	_formation_pick.item_selected.connect(_on_formation_changed)
	col1.add_child(_labeled("Formation", _formation_pick))

	_assign_box = VBoxContainer.new()
	_assign_box.custom_minimum_size = Vector2(ASSIGN_W, 0)
	row_cols.add_child(_assign_box)

	_play_editor = PlayEditorField.new()
	_play_editor.custom_minimum_size = Vector2(GRID_W, GRID_MIN_H)
	_play_editor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row_cols.add_child(_play_editor)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_status_label)

	var rowb := HBoxContainer.new()
	vb.add_child(rowb)
	var test_b := Button.new()
	test_b.text = "Test play"
	test_b.pressed.connect(_on_test_pressed)
	rowb.add_child(test_b)
	var save := Button.new()
	save.text = "Save"
	save.pressed.connect(_on_save_pressed)
	rowb.add_child(save)
	var close_b := Button.new()
	close_b.text = "Close"
	close_b.pressed.connect(_on_close_editor_pressed)
	rowb.add_child(close_b)
	if not _play_editor.routes_changed.is_connected(_mark_dirty):
		_play_editor.routes_changed.connect(_mark_dirty)
	return vb


func _mk_lbl(t: String) -> Label:
	var l := Label.new()
	l.text = t
	return l


func _labeled(lbl: String, ctl: Control) -> VBoxContainer:
	var v := VBoxContainer.new()
	var l := Label.new()
	l.text = lbl
	v.add_child(l)
	v.add_child(ctl)
	return v


func _mk_id_readout() -> LineEdit:
	var le := LineEdit.new()
	le.editable = false
	le.focus_mode = Control.FOCUS_NONE
	return le


func _mk_line_edit() -> LineEdit:
	var le := LineEdit.new()
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return le


func _mk_desc_edit() -> TextEdit:
	var te := TextEdit.new()
	te.custom_minimum_size = Vector2(0, 64)
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	return te


func _show_list() -> void:
	_list_view.visible = true
	_editor_view.visible = false
	_dirty = false
	_refresh_play_list()
	call_deferred("_clamp_modal_on_screen")


func _mark_dirty() -> void:
	_dirty = true


func _on_filter_type_changed(_i: int) -> void:
	_rebuild_subtype_filter()
	_refresh_play_list()


func _rebuild_subtype_filter() -> void:
	_filter_subtype.clear()
	_filter_subtype.add_item("All", 0)
	_filter_subtype.set_item_metadata(0, "")
	var ti := _filter_type.selected
	if ti <= 0:
		return
	var sides: Array[String] = ["", "offense", "defense", "special"]
	var side: String = sides[ti]
	var types: Variant = SUBTYPES_BY_SIDE.get(side, [])
	if typeof(types) != TYPE_ARRAY:
		return
	var idx := 1
	for t in types as Array:
		var pt := str(t)
		var lbl: String = str(SUBTYPE_LABELS.get(pt, pt))
		_filter_subtype.add_item(lbl, idx)
		_filter_subtype.set_item_metadata(idx, pt)
		idx += 1


func _refresh_formation_filter() -> void:
	_filter_formation.clear()
	_filter_formation.add_item("All", 0)
	_filter_formation.set_item_metadata(0, "")
	if _formations == null:
		return
	var i := 1
	for f in _formations.formations:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		var fid := str((f as Dictionary).get("id", ""))
		if fid.is_empty():
			continue
		_filter_formation.add_item(fid, i)
		_filter_formation.set_item_metadata(i, fid)
		i += 1


func _play_passes_filters(pid: String) -> bool:
	var d: Dictionary = _data.get(pid, {}) as Dictionary
	var q := _filter_search.text.strip_edges().to_lower()
	if not q.is_empty():
		var nm := str(d.get("name", "")).to_lower()
		var idl := pid.to_lower()
		if q not in nm and q not in idl:
			return false
	var ti := _filter_type.selected
	if ti > 0:
		var sides: Array[String] = ["", "offense", "defense", "special"]
		var want: String = sides[ti]
		if str(d.get("side", "")) != want:
			return false
	var si := _filter_subtype.selected
	if si > 0:
		var want_pt: String = str(_filter_subtype.get_item_metadata(si))
		if str(d.get("play_type", "")) != want_pt:
			return false
	var fi := _filter_formation.selected
	if fi > 0:
		var want_f := str(_filter_formation.get_item_metadata(fi))
		if str(d.get("formation_id", "")) != want_f:
			return false
	return true


func _refresh_play_list() -> void:
	_play_tree.clear()
	var ids: Array[String] = []
	for pid in _data.keys():
		ids.append(str(pid))
	ids.sort()
	for pid in ids:
		if not _play_passes_filters(pid):
			continue
		var d: Dictionary = _data[pid] as Dictionary
		var row := _play_tree.create_item()
		row.set_text(0, pid)
		row.set_text(1, str(d.get("name", "")))
		row.set_text(2, str(d.get("play_type", "")))
		row.set_text(3, str(d.get("formation_id", "")))
		row.set_metadata(0, pid)


func _on_tree_column_clicked(column: int, _mouse_button_index: int) -> void:
	if _sort_col == column:
		_sort_asc = not _sort_asc
	else:
		_sort_col = column
		_sort_asc = true
	_refresh_play_list()


func _on_tree_activated() -> void:
	_on_edit_pressed()


func _selected_play_id() -> String:
	var item: TreeItem = _play_tree.get_selected()
	if item == null:
		return ""
	return str(item.get_metadata(0))


func _on_add_pressed() -> void:
	_edit_is_new = true
	_editing_id = _gen_play_id("offense", "run")
	var fid := ""
	for f in _formations.formations:
		if typeof(f) == TYPE_DICTIONARY and str((f as Dictionary).get("side", "")) == "offense":
			fid = str((f as Dictionary).get("id", ""))
			break
	_open_editor(_editing_id, {
		"name": "New play",
		"side": "offense",
		"play_type": "run",
		"formation_id": fid,
		"tile_delta_min": 0,
		"tile_delta_max": 10,
		"description": "",
	})


func _on_edit_pressed() -> void:
	var pid := _selected_play_id()
	if pid.is_empty():
		return
	_edit_is_new = false
	_editing_id = pid
	_open_editor(pid, (_data[pid] as Dictionary).duplicate(true))


func _open_editor(pid: String, row: Dictionary) -> void:
	_editing_id = pid
	_id_readout.text = pid
	_name_edit.text = str(row.get("name", "New play"))
	_desc_edit.text = str(row.get("description", ""))
	_set_side_pick(str(row.get("side", "offense")))
	_rebuild_type_pick()
	_set_type_pick(str(row.get("play_type", _type_pick.get_item_text(0))))
	_rebuild_formation_pick()
	_set_formation_pick(str(row.get("formation_id", "")))
	_load_assignments_from_row(row)
	_list_view.visible = false
	_editor_view.visible = true
	_dirty = false
	_saved_snapshot = _build_row_from_editor()
	if not _name_edit.text_changed.is_connected(_mark_dirty):
		_name_edit.text_changed.connect(_mark_dirty)
	if not _desc_edit.text_changed.is_connected(_mark_dirty):
		_desc_edit.text_changed.connect(_mark_dirty)
	_status_label.text = ""
	call_deferred("_clamp_modal_on_screen")


func _clamp_modal_on_screen() -> void:
	await get_tree().process_frame
	ToolsModalLayout.clamp_scroll_to_viewport(_modal_scroll, _panel)


func _set_side_pick(side: String) -> void:
	for i in _side_pick.item_count:
		if _side_pick.get_item_text(i) == side:
			_side_pick.select(i)
			return
	_side_pick.select(0)


func _current_side() -> String:
	return _side_pick.get_item_text(_side_pick.selected)


func _rebuild_type_pick() -> void:
	_type_pick.clear()
	var side := _current_side()
	if side == "offense":
		for t in ["run", "pass", "spot_kick", "punt", "kickoff"]:
			_type_pick.add_item(t)
	elif side == "defense":
		for t in ["run_def", "pass_def", "fg_xp_def", "punt_return", "kickoff_return"]:
			_type_pick.add_item(t)
	else:
		for t in ["spot_kick", "punt", "kickoff"]:
			_type_pick.add_item(t)


func _set_type_pick(ptype: String) -> void:
	for i in _type_pick.item_count:
		if _type_pick.get_item_text(i) == ptype:
			_type_pick.select(i)
			return
	if _type_pick.item_count > 0:
		_type_pick.select(0)


func _current_play_type() -> String:
	if _type_pick.item_count == 0:
		return ""
	return _type_pick.get_item_text(_type_pick.selected)


func _rebuild_formation_pick() -> void:
	_formation_pick.clear()
	var side := _current_side()
	for f in _formations.formations:
		if typeof(f) != TYPE_DICTIONARY:
			continue
		var fd: Dictionary = f
		if str(fd.get("side", "")) != side:
			continue
		var fid := str(fd.get("id", ""))
		_formation_pick.add_item("%s — %s" % [fid, fd.get("name", "")])
		_formation_pick.set_item_metadata(_formation_pick.item_count - 1, fid)


func _set_formation_pick(fid: String) -> void:
	for i in _formation_pick.item_count:
		if str(_formation_pick.get_item_metadata(i)) == fid:
			_formation_pick.select(i)
			return
	if _formation_pick.item_count > 0:
		_formation_pick.select(0)


func _current_formation_id() -> String:
	if _formation_pick.selected < 0:
		return ""
	return str(_formation_pick.get_item_metadata(_formation_pick.selected))


func _on_side_changed(_i: int) -> void:
	if _edit_is_new:
		_editing_id = _gen_play_id(_current_side(), _current_play_type())
		_id_readout.text = _editing_id
	_rebuild_type_pick()
	_rebuild_formation_pick()
	if _formation_pick.item_count > 0:
		_formation_pick.select(0)
		var form := _formations.get_by_id(_current_formation_id())
		if not form.is_empty():
			_play_editor.load_formation(form)
	_rebuild_assignments_ui()
	_mark_dirty()


func _on_type_changed(_i: int) -> void:
	_rebuild_assignments_ui()
	_mark_dirty()


func _on_formation_changed(_i: int) -> void:
	var fid := _current_formation_id()
	var form := _formations.get_by_id(fid)
	if not form.is_empty():
		_play_editor.load_formation(form)
	_rebuild_assignments_ui()
	_mark_dirty()


func _rebuild_assignments_ui() -> void:
	for c in _assign_box.get_children():
		c.queue_free()
	_role_actions.clear()
	_ball_carrier_role = null
	_qb_mode = null
	_qb_dropback = null
	_qb_handoff_role = null
	_prog_primary = null
	_prog_secondary = null
	_prog_tertiary = null
	var side := _current_side()
	var ptype := _current_play_type()
	var form := _formations.get_by_id(_current_formation_id())
	if not form.is_empty():
		_play_editor.load_formation(form)
	if side == "defense" and ptype in ["run_def", "pass_def"]:
		_build_defense_role_actions_ui()
		return
	if side != "offense" or ptype not in ["run", "pass"]:
		return
	_assign_box.add_child(_mk_lbl("Role actions"))
	for role in _play_editor.roles_on_field():
		var row := HBoxContainer.new()
		var rl := Label.new()
		rl.text = role
		rl.custom_minimum_size = Vector2(48, 0)
		row.add_child(rl)
		var ob := OptionButton.new()
		for a in PlayCreatorValidators.OFFENSE_ACTIONS:
			ob.add_item(a)
		_role_actions[role] = ob
		row.add_child(ob)
		_assign_box.add_child(row)
	if ptype == "run":
		_assign_box.add_child(_mk_lbl("Ball carrier"))
		_ball_carrier_role = OptionButton.new()
		for role in _play_editor.roles_on_field():
			if role.to_upper().begins_with("RB"):
				_ball_carrier_role.add_item(role)
		_assign_box.add_child(_ball_carrier_role)
	if ptype == "pass":
		_assign_box.add_child(_mk_lbl("QB script"))
		_qb_mode = OptionButton.new()
		for m in PlayCreatorValidators.QB_MODES:
			_qb_mode.add_item(m)
		_qb_mode.item_selected.connect(_mark_dirty)
		_assign_box.add_child(_qb_mode)
		_qb_dropback = SpinBox.new()
		_qb_dropback.min_value = 1
		_qb_dropback.max_value = 7
		_qb_dropback.value = 5
		_qb_dropback.value_changed.connect(_mark_dirty)
		_assign_box.add_child(_labeled("Dropback ticks", _qb_dropback))
		_qb_handoff_role = OptionButton.new()
		for role in _play_editor.roles_on_field():
			if role.to_upper().begins_with("RB"):
				_qb_handoff_role.add_item(role)
		_assign_box.add_child(_labeled("Handoff role", _qb_handoff_role))
		_assign_box.add_child(_mk_lbl("Progression"))
		_prog_primary = _prog_option()
		_prog_secondary = _prog_option()
		_prog_tertiary = _prog_option()
		_assign_box.add_child(_labeled("Primary", _prog_primary))
		_assign_box.add_child(_labeled("Secondary", _prog_secondary))
		_assign_box.add_child(_labeled("Tertiary", _prog_tertiary))


func _build_defense_role_actions_ui() -> void:
	_assign_box.add_child(_mk_lbl("Role actions"))
	for role in _play_editor.roles_on_field():
		var row := HBoxContainer.new()
		var rl := Label.new()
		rl.text = role
		rl.custom_minimum_size = Vector2(48, 0)
		row.add_child(rl)
		var ob := OptionButton.new()
		for a in PlayCreatorValidators.DEFENSE_ACTIONS:
			ob.add_item(a)
		ob.item_selected.connect(_mark_dirty)
		_role_actions[role] = ob
		row.add_child(ob)
		_assign_box.add_child(row)
		_apply_defense_action_default(role, ob)


func _apply_defense_action_default(role: String, ob: OptionButton) -> void:
	var r := role.to_upper()
	var default_act := "pursue"
	if r.begins_with("CB"):
		default_act = "cover_man"
	elif r.begins_with("S"):
		default_act = "cover_zone"
	elif r.begins_with("DL") or r.begins_with("LB"):
		default_act = "pass_rush"
	for i in ob.item_count:
		if ob.get_item_text(i) == default_act:
			ob.select(i)
			return


func _prog_option() -> OptionButton:
	var ob := OptionButton.new()
	ob.add_item("")
	for role in _play_editor.roles_on_field():
		if PlayCreatorValidators.is_route_role(role):
			ob.add_item(role)
	return ob


func _load_assignments_from_row(row: Dictionary) -> void:
	_rebuild_assignments_ui()
	var ra: Dictionary = row.get("role_assignments", {}) as Dictionary
	for role in _role_actions.keys():
		var ob: OptionButton = _role_actions[role] as OptionButton
		var act := str((ra.get(role, {}) as Dictionary).get("start_action", ""))
		for i in ob.item_count:
			if ob.get_item_text(i) == act:
				ob.select(i)
				break
	_play_editor.set_routes(row.get("routes", {}) as Dictionary)
	if _ball_carrier_role != null:
		var bcr := str(row.get("ball_carrier_role", ""))
		for i in _ball_carrier_role.item_count:
			if _ball_carrier_role.get_item_text(i) == bcr:
				_ball_carrier_role.select(i)
				break
	var qb: Dictionary = row.get("qb_script", {}) as Dictionary
	if _qb_mode != null:
		var mode := str(qb.get("mode", "dropback_progression"))
		for i in _qb_mode.item_count:
			if _qb_mode.get_item_text(i) == mode:
				_qb_mode.select(i)
				break
		if _qb_dropback != null:
			_qb_dropback.value = int(qb.get("dropback_ticks", 5))
		var hr := str(qb.get("handoff_role", ""))
		if _qb_handoff_role != null:
			for i in _qb_handoff_role.item_count:
				if _qb_handoff_role.get_item_text(i) == hr:
					_qb_handoff_role.select(i)
					break
	var prog: Dictionary = row.get("receiver_progression", {}) as Dictionary
	_set_prog_pick(_prog_primary, str(prog.get("primary", "")))
	_set_prog_pick(_prog_secondary, str(prog.get("secondary", "")))
	_set_prog_pick(_prog_tertiary, str(prog.get("tertiary", "")))


func _set_prog_pick(ob: OptionButton, role: String) -> void:
	if ob == null:
		return
	for i in ob.item_count:
		if ob.get_item_text(i) == role:
			ob.select(i)
			return


func _build_row_from_editor() -> Dictionary:
	var row: Dictionary = {
		"name": _name_edit.text.strip_edges(),
		"side": _current_side(),
		"play_type": _current_play_type(),
		"formation_id": _current_formation_id(),
		"description": _desc_edit.text.strip_edges(),
	}
	var ptype := _current_play_type()
	if ptype in ["run", "pass"]:
		if not row.has("tile_delta_min"):
			row["tile_delta_min"] = 0
		if not row.has("tile_delta_max"):
			row["tile_delta_max"] = 13 if ptype == "pass" else 10
	var side := _current_side()
	if side == "offense" and ptype in ["run", "pass"]:
		var ra: Dictionary = {}
		for role in _role_actions.keys():
			var ob: OptionButton = _role_actions[role] as OptionButton
			ra[role] = {"start_action": ob.get_item_text(ob.selected)}
		row["role_assignments"] = ra
	elif side == "defense" and ptype in ["run_def", "pass_def"]:
		var ra_def: Dictionary = {}
		for role in _role_actions.keys():
			var ob_def: OptionButton = _role_actions[role] as OptionButton
			ra_def[role] = {"start_action": ob_def.get_item_text(ob_def.selected)}
		row["role_assignments"] = ra_def
		var routes := _play_editor.get_routes()
		if not routes.is_empty():
			row["routes"] = routes
		if ptype == "run" and _ball_carrier_role != null and _ball_carrier_role.item_count > 0:
			row["ball_carrier_role"] = _ball_carrier_role.get_item_text(_ball_carrier_role.selected)
		if ptype == "pass":
			var prog: Dictionary = {}
			if _prog_primary != null:
				prog["primary"] = _prog_primary.get_item_text(_prog_primary.selected)
			if _prog_secondary != null:
				prog["secondary"] = _prog_secondary.get_item_text(_prog_secondary.selected)
			if _prog_tertiary != null:
				prog["tertiary"] = _prog_tertiary.get_item_text(_prog_tertiary.selected)
			row["receiver_progression"] = prog
			if _qb_mode != null:
				var mode := _qb_mode.get_item_text(_qb_mode.selected)
				var qb: Dictionary = {"mode": mode}
				if mode == "handoff" and _qb_handoff_role != null and _qb_handoff_role.item_count > 0:
					qb["handoff_role"] = _qb_handoff_role.get_item_text(_qb_handoff_role.selected)
				elif _qb_dropback != null:
					qb["dropback_ticks"] = int(_qb_dropback.value)
					var order: Array = []
					for role in [prog.get("primary", ""), prog.get("secondary", ""), prog.get("tertiary", "")]:
						if not str(role).is_empty():
							order.append(role)
					qb["progression"] = order
				row["qb_script"] = qb
	# Preserve existing tile caps when editing legacy rows
	if not _edit_is_new and _data.has(_editing_id):
		var prev: Dictionary = _data[_editing_id] as Dictionary
		if prev.has("tile_delta_min"):
			row["tile_delta_min"] = prev["tile_delta_min"]
		if prev.has("tile_delta_max"):
			row["tile_delta_max"] = prev["tile_delta_max"]
	return row


func _on_save_pressed() -> void:
	var row := _build_row_from_editor()
	var err := PlayCreatorValidators.validate_play_dict(_editing_id, row, _formations)
	if not err.is_empty():
		_status_label.text = err
		return
	if _edit_is_new and _data.has(_editing_id):
		_status_label.text = "Duplicate play id."
		return
	var backup := _data.duplicate(true)
	_data[_editing_id] = row
	if not _save_all():
		_data = backup
		_status_label.text = "Failed to write file (reverted)."
		return
	if _on_saved.is_valid():
		_on_saved.call()
	_dirty = false
	_saved_snapshot = _build_row_from_editor()
	_status_label.text = "Saved."


func _editor_has_unsaved_changes() -> bool:
	if _dirty:
		return true
	return JSON.stringify(_build_row_from_editor()) != JSON.stringify(_saved_snapshot)


func _on_test_pressed() -> void:
	if _editor_has_unsaved_changes():
		_status_label.text = "Save the play before testing."
		return
	if _on_test_play.is_valid():
		_on_test_play.call(_editing_id)


func _on_close_editor_pressed() -> void:
	if not _editor_has_unsaved_changes():
		_show_list()
		return
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Save changes to %s?" % _editing_id
	dlg.ok_button_text = "Save"
	dlg.cancel_button_text = "Cancel"
	add_child(dlg)
	dlg.confirmed.connect(func():
		_on_save_pressed()
		dlg.queue_free()
	)
	dlg.canceled.connect(func():
		dlg.queue_free()
	)
	dlg.custom_action.connect(func(action: String):
		if action == "discard":
			_show_list()
		dlg.queue_free()
	)
	dlg.add_button("Discard", false, "discard")
	dlg.popup_centered()


func _on_delete_pressed() -> void:
	var pid := _selected_play_id()
	if pid.is_empty():
		return
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Delete play %s?" % pid
	add_child(dlg)
	dlg.confirmed.connect(func():
		var backup := _data.duplicate(true)
		_data.erase(pid)
		if not _save_all():
			_data = backup
		else:
			if _on_saved.is_valid():
				_on_saved.call()
		dlg.queue_free()
		_refresh_play_list()
	)
	dlg.popup_centered()


func _save_all() -> bool:
	var txt := JSON.stringify(_data, "\t") + "\n"
	var f := FileAccess.open(PLAYS_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write %s" % PLAYS_PATH)
		return false
	f.store_string(txt)
	f.close()
	return true


func _gen_play_id(side: String, ptype: String) -> String:
	var prefix := "play_off"
	if side == "defense":
		prefix = "play_def"
	elif side == "special":
		prefix = "play_sp"
	for _i in 512:
		var cand := "%s_%d" % [prefix, randi() % 100000]
		if not _data.has(cand):
			return cand
	return "%s_%d" % [prefix, Time.get_ticks_usec()]


func _on_close_pressed() -> void:
	queue_free()
