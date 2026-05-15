extends CanvasLayer
class_name FormationTool

const FORMATIONS_PATH := "res://data/formations.json"
const FORMATION_TOOL_LIST_W := 560
const FORMATION_TOOL_COL1_W := 200
const FORMATION_TOOL_PALETTE_COL_W := 128
const FORMATION_TOOL_GRID_COL_W := 280
const FORMATION_TOOL_GRID_MIN_H := 660
const FORMATION_TOOL_PANEL_MIN_X := 664
const PALETTE_DROP_SCROLL := preload("res://scripts/formation_palette_drop_scroll.gd")

var _on_saved: Callable = Callable()
var _data: Array = []
var _edit_is_new: bool = false
var _edit_index: int = -1
var _pending_shell: String = ""
var _editing_id: String = ""

var _dim: ColorRect
var _panel: PanelContainer
var _stack: MarginContainer

var _list_view: VBoxContainer
var _shell_view: VBoxContainer
var _editor_view: VBoxContainer

var _formation_tree: Tree
var _filter_type: OptionButton
var _filter_tags: LineEdit
var _sort_col: int = 0
var _sort_asc: bool = true
var _shell_list: ItemList

var _name_edit: LineEdit
var _desc_edit: TextEdit
var _tags_edit: LineEdit
var _id_readout: LineEdit
var _editor_field: FormationEditorField
var _palette_box: VBoxContainer
var _status_label: Label


func setup(catalog: FormationsCatalog, on_saved: Callable) -> void:
	_on_saved = on_saved
	_data.clear()
	for f in catalog.formations:
		if typeof(f) == TYPE_DICTIONARY:
			_data.append((f as Dictionary).duplicate(true))


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_show_list()


func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	var margin_wrap := MarginContainer.new()
	margin_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_wrap.add_theme_constant_override("margin_left", 12)
	margin_wrap.add_theme_constant_override("margin_right", 12)
	margin_wrap.add_theme_constant_override("margin_top", 12)
	margin_wrap.add_theme_constant_override("margin_bottom", 12)
	add_child(margin_wrap)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	margin_wrap.add_child(scroll)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.custom_minimum_size = Vector2(FORMATION_TOOL_PANEL_MIN_X, 0)
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.14, 0.14, 0.16, 1.0)
	psb.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", psb)
	scroll.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	_stack = MarginContainer.new()
	margin.add_child(_stack)

	_list_view = _build_list_view()
	_shell_view = _build_shell_view()
	_editor_view = _build_editor_view()
	_stack.add_child(_list_view)
	_stack.add_child(_shell_view)
	_stack.add_child(_editor_view)
	_shell_view.visible = false
	_editor_view.visible = false



func _build_list_view() -> VBoxContainer:
	var vb := VBoxContainer.new()
	var title := Label.new()
	title.text = "Formation tool"
	title.add_theme_font_size_override("font_size", 22)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(FORMATION_TOOL_LIST_W, 0)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(title)

	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 8)
	vb.add_child(filter_row)
	var type_lbl := Label.new()
	type_lbl.text = "Type"
	filter_row.add_child(type_lbl)
	_filter_type = OptionButton.new()
	_filter_type.add_item("All", 0)
	_filter_type.add_item("Offense", 1)
	_filter_type.add_item("Defense", 2)
	_filter_type.add_item("Special", 3)
	_filter_type.custom_minimum_size = Vector2(120, 0)
	_filter_type.item_selected.connect(func(_idx: int) -> void: _refresh_formation_list())
	filter_row.add_child(_filter_type)
	var tags_lbl := Label.new()
	tags_lbl.text = "Tags"
	filter_row.add_child(tags_lbl)
	_filter_tags = LineEdit.new()
	_filter_tags.placeholder_text = "e.g. run, pass"
	_filter_tags.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_tags.text_changed.connect(_on_filter_tags_changed)
	filter_row.add_child(_filter_tags)

	_formation_tree = Tree.new()
	_formation_tree.columns = 3
	_formation_tree.column_titles_visible = true
	_formation_tree.hide_root = true
	_formation_tree.set_column_title(0, "ID")
	_formation_tree.set_column_title(1, "Name")
	_formation_tree.set_column_title(2, "Type")
	_formation_tree.set_column_custom_minimum_width(0, 140)
	_formation_tree.set_column_custom_minimum_width(1, 220)
	_formation_tree.set_column_custom_minimum_width(2, 88)
	_formation_tree.set_column_expand(0, false)
	_formation_tree.set_column_expand(1, true)
	_formation_tree.set_column_expand(2, false)
	_formation_tree.custom_minimum_size = Vector2(FORMATION_TOOL_LIST_W, 360)
	_formation_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_formation_tree.column_title_clicked.connect(_on_formation_tree_column_title_clicked)
	_formation_tree.item_activated.connect(_on_formation_tree_item_activated)
	vb.add_child(_formation_tree)

	var row := HBoxContainer.new()
	vb.add_child(row)
	var b_add := Button.new()
	b_add.text = "Add…"
	b_add.pressed.connect(_on_add_pressed)
	row.add_child(b_add)
	var b_edit := Button.new()
	b_edit.text = "Edit"
	b_edit.pressed.connect(_on_edit_pressed)
	row.add_child(b_edit)
	var b_del := Button.new()
	b_del.text = "Delete"
	b_del.pressed.connect(_on_delete_pressed)
	row.add_child(b_del)
	var b_close := Button.new()
	b_close.text = "Close"
	b_close.pressed.connect(_on_close_pressed)
	row.add_child(b_close)

	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size = Vector2(FORMATION_TOOL_LIST_W, 0)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.text = "Saves write %s (dev/editor). New play formation_id values are not updated automatically." % FORMATIONS_PATH
	vb.add_child(hint)
	return vb


func _build_shell_view() -> VBoxContainer:
	var vb := VBoxContainer.new()
	var t := Label.new()
	t.text = "Choose formation context"
	t.add_theme_font_size_override("font_size", 18)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.custom_minimum_size = Vector2(FORMATION_TOOL_LIST_W, 0)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(t)
	_shell_list = ItemList.new()
	_shell_list.custom_minimum_size = Vector2(FORMATION_TOOL_LIST_W, 280)
	for sh in FormationsCatalog.FORMATION_SHELLS:
		_shell_list.add_item("%s — %s" % [sh, FormationToolRolePalettes.shell_label(sh)])
	vb.add_child(_shell_list)
	var row := HBoxContainer.new()
	vb.add_child(row)
	var next := Button.new()
	next.text = "Next"
	next.pressed.connect(_on_shell_next_pressed)
	row.add_child(next)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(_show_list)
	row.add_child(back)
	return vb


func _build_editor_view() -> VBoxContainer:
	var vb := VBoxContainer.new()
	var row_cols := HBoxContainer.new()
	row_cols.add_theme_constant_override("separation", 8)
	row_cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(row_cols)

	var col1 := VBoxContainer.new()
	col1.custom_minimum_size = Vector2(FORMATION_TOOL_COL1_W, 0)
	col1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	var tags_box := _labeled("Tags (comma)", _mk_line_edit())
	_tags_edit = tags_box.get_child(1) as LineEdit
	col1.add_child(tags_box)

	var pal_scroll := PALETTE_DROP_SCROLL.new() as FormationPaletteDropScroll
	pal_scroll.custom_minimum_size = Vector2(FORMATION_TOOL_PALETTE_COL_W, 0)
	pal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	row_cols.add_child(pal_scroll)

	_palette_box = VBoxContainer.new()
	_palette_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_box.custom_minimum_size = Vector2(FORMATION_TOOL_PALETTE_COL_W - 4, 0)
	pal_scroll.add_child(_palette_box)

	_editor_field = FormationEditorField.new()
	_editor_field.custom_minimum_size = Vector2(FORMATION_TOOL_GRID_COL_W, FORMATION_TOOL_GRID_MIN_H)
	_editor_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_editor_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_editor_field.placements_changed.connect(_on_editor_placements_changed)
	pal_scroll.editor_field = _editor_field
	row_cols.add_child(_editor_field)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(FORMATION_TOOL_PANEL_MIN_X - 48, 0)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(_status_label)

	var rowb := HBoxContainer.new()
	vb.add_child(rowb)
	var save := Button.new()
	save.text = "Save"
	save.pressed.connect(_on_save_pressed)
	rowb.add_child(save)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(_on_editor_cancel_pressed)
	rowb.add_child(cancel)
	return vb


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
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.custom_minimum_size = Vector2(0, 0)
	return le


func _mk_line_edit() -> LineEdit:
	var le := LineEdit.new()
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	le.custom_minimum_size = Vector2(120, 0)
	return le


func _mk_desc_edit() -> TextEdit:
	var te := TextEdit.new()
	te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	te.custom_minimum_size = Vector2(0, 72)
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	return te


func _show_list() -> void:
	_list_view.visible = true
	_shell_view.visible = false
	_editor_view.visible = false
	_refresh_formation_list()


func _on_filter_tags_changed(_new_text: String) -> void:
	_refresh_formation_list()


func _on_formation_tree_column_title_clicked(column: int, _mouse_button_index: int) -> void:
	if _sort_col == column:
		_sort_asc = not _sort_asc
	else:
		_sort_col = column
		_sort_asc = true
	_refresh_formation_list()


func _on_formation_tree_item_activated() -> void:
	_on_edit_pressed()


func _formation_type_filter_value() -> String:
	match _filter_type.selected:
		1:
			return "offense"
		2:
			return "defense"
		3:
			return "special"
		_:
			return ""


func _formation_matches_tag_filter(d: Dictionary) -> bool:
	var raw := _filter_tags.text.strip_edges()
	if raw.is_empty():
		return true
	var tags: Variant = d.get("tags", [])
	if typeof(tags) != TYPE_ARRAY:
		return false
	var tag_low: Array[String] = []
	for t in tags:
		tag_low.append(str(t).to_lower())
	var tokens: Array[String] = []
	for part in raw.split(",", false):
		var needle := part.strip_edges().to_lower()
		if not needle.is_empty():
			tokens.append(needle)
	if tokens.is_empty():
		return true
	for needle in tokens:
		for tl in tag_low:
			if needle in tl or tl in needle:
				return true
	return false


func _formation_passes_filters(index: int) -> bool:
	var d: Dictionary = _data[index] as Dictionary
	var want_side := _formation_type_filter_value()
	if not want_side.is_empty() and str(d.get("side", "")) != want_side:
		return false
	return _formation_matches_tag_filter(d)


func _formation_sort_less(a: int, b: int) -> bool:
	var da: Dictionary = _data[a] as Dictionary
	var db: Dictionary = _data[b] as Dictionary
	var av := ""
	var bv := ""
	match _sort_col:
		0:
			av = str(da.get("id", ""))
			bv = str(db.get("id", ""))
		1:
			av = str(da.get("name", ""))
			bv = str(db.get("name", ""))
		2:
			av = str(da.get("side", ""))
			bv = str(db.get("side", ""))
	if av == bv:
		return a < b
	if _sort_asc:
		return av.nocasecmp_to(bv) < 0
	return av.nocasecmp_to(bv) > 0


func _formation_type_display(d: Dictionary) -> String:
	var side := str(d.get("side", ""))
	if side.is_empty():
		return ""
	return side.capitalize()


func _selected_formation_data_index() -> int:
	var item: TreeItem = _formation_tree.get_selected()
	if item == null:
		return -1
	return int(item.get_metadata(0))


func _refresh_formation_list() -> void:
	_formation_tree.clear()
	var indices: Array[int] = []
	for i in _data.size():
		if _formation_passes_filters(i):
			indices.append(i)
	indices.sort_custom(func(a: int, b: int) -> bool: return _formation_sort_less(a, b))
	for i in indices:
		var d: Dictionary = _data[i] as Dictionary
		var row := _formation_tree.create_item()
		row.set_text(0, str(d.get("id", "")))
		row.set_text(1, str(d.get("name", "")))
		row.set_text(2, _formation_type_display(d))
		row.set_metadata(0, i)


func _on_add_pressed() -> void:
	_list_view.visible = false
	_shell_view.visible = true
	_editor_view.visible = false
	_shell_list.deselect_all()


func _on_shell_next_pressed() -> void:
	var sel := _shell_list.get_selected_items()
	if sel.is_empty():
		return
	_pending_shell = FormationsCatalog.FORMATION_SHELLS[sel[0]]
	_edit_is_new = true
	_edit_index = -1
	_open_editor_new()


func _open_editor_new() -> void:
	_editing_id = _gen_unique_formation_id()
	_id_readout.text = _editing_id
	_name_edit.text = "New formation"
	_desc_edit.text = ""
	_tags_edit.text = ""
	_editor_field.set_formation_shell(_pending_shell)
	_editor_field.clear_field()
	_list_view.visible = false
	_shell_view.visible = false
	_editor_view.visible = true
	_status_label.text = "Place exactly 7 positions."


func _on_edit_pressed() -> void:
	var idx := _selected_formation_data_index()
	if idx < 0:
		return
	_edit_is_new = false
	_edit_index = idx
	var src: Dictionary = _data[_edit_index]
	_editing_id = str(src.get("id", ""))
	_id_readout.text = _editing_id
	_name_edit.text = str(src.get("name", ""))
	_desc_edit.text = str(src.get("description", ""))
	var tags: Variant = src.get("tags", [])
	var ts: PackedStringArray = PackedStringArray()
	if typeof(tags) == TYPE_ARRAY:
		for t in tags:
			ts.append(str(t))
	_tags_edit.text = ", ".join(ts)
	var sh := str(src.get("formation_shell", ""))
	_editor_field.set_formation_shell(sh)
	_editor_field.load_from_positions(src.get("positions", []) as Array)
	_list_view.visible = false
	_shell_view.visible = false
	_editor_view.visible = true
	_status_label.text = ""


func _on_editor_placements_changed(_count: int) -> void:
	_rebuild_palette()


func _rebuild_palette() -> void:
	for c in _palette_box.get_children():
		c.queue_free()
	var shell := _pending_shell if _edit_is_new else str((_data[_edit_index] as Dictionary).get("formation_shell", ""))
	for r in FormationToolRolePalettes.roles_for_shell(shell):
		if _editor_field.count_role_on_field(r) >= 1:
			continue
		var pl := FormationPaletteLabel.new()
		pl.setup(r)
		pl.editor_field = _editor_field
		pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pl.custom_minimum_size = Vector2(FORMATION_TOOL_PALETTE_COL_W - 8, 0)
		pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_palette_box.add_child(pl)
	var filler := PaletteDropFiller.new()
	filler.editor_field = _editor_field
	filler.mouse_filter = Control.MOUSE_FILTER_STOP
	filler.custom_minimum_size = Vector2(maxf(FORMATION_TOOL_PALETTE_COL_W - 8.0, 32.0), 140.0)
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_palette_box.add_child(filler)


func _on_delete_pressed() -> void:
	var idx := _selected_formation_data_index()
	if idx < 0:
		return
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Delete formation %s?" % str((_data[idx] as Dictionary).get("id", ""))
	add_child(dlg)
	dlg.confirmed.connect(func():
		var backup := _snapshot_data()
		_data.remove_at(idx)
		if not _save_all_to_disk():
			_data = backup
			push_error("Delete failed to write disk; reverted.")
		dlg.queue_free()
		_refresh_formation_list()
	)
	dlg.popup_centered()


func _on_editor_cancel_pressed() -> void:
	_show_list()


func _on_save_pressed() -> void:
	var positions: Array = _editor_field.build_positions_array()
	if positions.size() != FormationsCatalog.MAX_PLAYERS_ON_FIELD:
		_status_label.text = "Need exactly 7 positions on the field (got %d)." % positions.size()
		return
	var idv := _editing_id.strip_edges()
	var nmv := _name_edit.text.strip_edges()
	if idv.is_empty():
		_status_label.text = "Missing formation id (internal error)."
		return
	if nmv.is_empty():
		_status_label.text = "Name is required."
		return
	var shell := _pending_shell if _edit_is_new else str((_data[_edit_index] as Dictionary).get("formation_shell", ""))
	var side := str(FormationsCatalog.FORMATION_SHELL_EXPECTED_SIDE.get(shell, "offense"))
	var tags := _parse_tags(_tags_edit.text)
	var dict := {
		"id": idv,
		"name": nmv,
		"side": side,
		"formation_shell": shell,
		"description": _desc_edit.text.strip_edges(),
		"tags": tags,
		"positions": positions,
	}
	if not FormationsCatalog.new().validate_formation_dict(dict):
		_status_label.text = "Validation failed (see Output)."
		return
	if _id_duplicate(dict, _edit_index if not _edit_is_new else -1):
		_status_label.text = "Duplicate formation id."
		return
	var backup := _snapshot_data()
	if _edit_is_new:
		_data.append(dict)
	else:
		_data[_edit_index] = dict
	if not _save_all_to_disk():
		_data = backup
		_status_label.text = "Failed to write file (reverted)."
		return
	if _on_saved.is_valid():
		_on_saved.call()
	_show_list()


func _snapshot_data() -> Array:
	var backup: Array = []
	for x in _data:
		if typeof(x) == TYPE_DICTIONARY:
			backup.append((x as Dictionary).duplicate(true))
	return backup


func _gen_unique_formation_id() -> String:
	for _i in 512:
		var cand := "fmt_%d_%d" % [Time.get_ticks_usec(), randi() % 100000]
		if not _id_string_in_use(cand):
			return cand
	return "fmt_%d" % Time.get_ticks_usec()


func _id_string_in_use(idv: String) -> bool:
	for item in _data:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if str((item as Dictionary).get("id", "")) == idv:
			return true
	return false


func _id_duplicate(d: Dictionary, except_index: int) -> bool:
	var idv := str(d.get("id", ""))
	for i in _data.size():
		if i == except_index:
			continue
		if str((_data[i] as Dictionary).get("id", "")) == idv:
			return true
	return false


func _parse_tags(s: String) -> Array:
	var out: Array = []
	for part in s.split(",", false):
		var t := part.strip_edges()
		if not t.is_empty():
			out.append(t)
	return out


func _save_all_to_disk() -> bool:
	var cat := FormationsCatalog.new()
	for item in _data:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		if not cat.validate_formation_dict(item as Dictionary):
			push_error("Formation tool: validation failed before write")
			return false
	var txt := JSON.stringify(_data, "\t") + "\n"
	var f := FileAccess.open(FORMATIONS_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write %s" % FORMATIONS_PATH)
		return false
	f.store_string(txt)
	f.close()
	return true


func _on_close_pressed() -> void:
	queue_free()


class PaletteDropFiller extends Control:
	var editor_field: FormationEditorField


	func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
		return editor_field != null and editor_field.should_accept_remove_drop(data)


	func _drop_data(_at_position: Vector2, data: Variant) -> void:
		if editor_field:
			editor_field.apply_remove_drop(data)
