extends PanelContainer

signal pressed_play(play_id: String)

const CELL := 20

var _play_id: String = ""
var _grid: GridContainer


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var nl := get_node_or_null("MarginContainer/VBoxContainer/NameLabel") as Label
	var gr := get_node_or_null("MarginContainer/VBoxContainer/FormationGrid") as GridContainer
	if nl:
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if gr:
		gr.mouse_filter = Control.MOUSE_FILTER_IGNORE


func get_play_id() -> String:
	return _play_id


func setup(play_id: String, play_row: Dictionary, formation: Dictionary, selected: bool) -> void:
	_play_id = play_id
	var nl := get_node_or_null("MarginContainer/VBoxContainer/NameLabel") as Label
	_grid = get_node_or_null("MarginContainer/VBoxContainer/FormationGrid") as GridContainer
	if nl == null or _grid == null:
		push_error("PlayPickCard: missing NameLabel or FormationGrid")
		return
	nl.text = str(play_row.get("name", play_id))
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_fill_grid(formation)
	set_selected(selected)


func set_selected(on: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.22, 0.32, 1)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	if on:
		sb.border_color = Color(0.95, 0.85, 0.2, 1)
	else:
		sb.border_color = Color(0.38, 0.44, 0.54, 1)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_right = 8
	sb.corner_radius_bottom_left = 8
	add_theme_stylebox_override("panel", sb)


func _fill_grid(formation: Dictionary) -> void:
	if _grid == null:
		return
	for c in _grid.get_children():
		c.queue_free()

	var pos_raw: Variant = formation.get("positions", [])
	var occupied: Array = []
	for _j in 9:
		occupied.append(false)

	if typeof(pos_raw) != TYPE_ARRAY or pos_raw.is_empty():
		_emit_cells(occupied, str(formation.get("side", "offense")))
		return

	var rows: Array[int] = []
	var cols: Array[int] = []
	for p in pos_raw:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = p
		rows.append(int(pd.get("delta_row", 0)))
		cols.append(int(pd.get("delta_col", 0)))
	if rows.is_empty():
		_emit_cells(occupied, str(formation.get("side", "offense")))
		return

	var min_r: int = rows[0]
	var max_r: int = rows[0]
	var min_c: int = cols[0]
	var max_c: int = cols[0]
	for i in range(rows.size()):
		min_r = mini(min_r, rows[i])
		max_r = maxi(max_r, rows[i])
		min_c = mini(min_c, cols[i])
		max_c = maxi(max_c, cols[i])

	for i in range(rows.size()):
		var dr := rows[i]
		var dc := cols[i]
		var gr := 1
		var gc := 1
		if max_r != min_r:
			gr = int(round(float(dr - min_r) / float(max_r - min_r) * 2.0))
		if max_c != min_c:
			gc = int(round(float(dc - min_c) / float(max_c - min_c) * 2.0))
		gr = clampi(gr, 0, 2)
		gc = clampi(gc, 0, 2)
		var idx := gr * 3 + gc
		if idx >= 0 and idx < 9:
			occupied[idx] = true

	_emit_cells(occupied, str(formation.get("side", "offense")))


func _emit_cells(occupied: Array, side: String) -> void:
	var dot_off := Color(0.55, 0.78, 1.0, 1)
	var dot_def := Color(1.0, 0.52, 0.42, 1)
	var empty := Color(0.12, 0.13, 0.18, 1)
	for i in 9:
		var cell := ColorRect.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.custom_minimum_size = Vector2(CELL, CELL)
		var on: bool = occupied[i] if i < occupied.size() else false
		if on:
			cell.color = dot_def if side == "defense" else dot_off
		else:
			cell.color = empty
		_grid.add_child(cell)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			pressed_play.emit(_play_id)
