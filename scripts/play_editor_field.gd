extends Panel
class_name PlayEditorField

signal routes_changed

const STEP_DIRS: Array[Dictionary] = [
	{"label": "N", "dc": 0, "dr": -1},
	{"label": "NE", "dc": 1, "dr": -1},
	{"label": "E", "dc": 1, "dr": 0},
	{"label": "SE", "dc": 1, "dr": 1},
	{"label": "S", "dc": 0, "dr": 1},
	{"label": "SW", "dc": -1, "dr": 1},
	{"label": "W", "dc": -1, "dr": 0},
	{"label": "NW", "dc": -1, "dr": -1},
]

var _field: FormationEditorField
var _overlay: Control
var _role_pick: OptionButton
var _routes: Dictionary = {}
var _selected_role: String = ""


func _ready() -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(outer)
	_field = FormationEditorField.new()
	_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field.set_tokens_editable(false)
	outer.add_child(_field)
	var row := HBoxContainer.new()
	outer.add_child(row)
	var role_l := Label.new()
	role_l.text = "Route role"
	row.add_child(role_l)
	_role_pick = OptionButton.new()
	_role_pick.item_selected.connect(_on_role_picked)
	row.add_child(_role_pick)
	var step_ob := OptionButton.new()
	for d in STEP_DIRS:
		step_ob.add_item(str(d.get("label", "")))
	row.add_child(step_ob)
	var add_b := Button.new()
	add_b.text = "Add step"
	add_b.pressed.connect(func() -> void: _on_add_step(step_ob.selected))
	row.add_child(add_b)
	var undo_b := Button.new()
	undo_b.text = "Undo"
	undo_b.pressed.connect(_on_undo_step_pressed)
	row.add_child(undo_b)
	var clr_b := Button.new()
	clr_b.text = "Clear route"
	clr_b.pressed.connect(_on_clear_route_pressed)
	row.add_child(clr_b)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 10
	_field.add_child(_overlay)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_on_overlay_draw)


func load_formation(formation: Dictionary) -> void:
	var shell := str(formation.get("formation_shell", FormationsCatalog.FORMATION_SHELL_SCRIMMAGE_OFFENSE))
	_field.set_formation_shell(shell)
	_field.load_from_positions(formation.get("positions", []) as Array)
	_rebuild_role_picker()
	_overlay.queue_redraw()


func set_routes(routes: Dictionary) -> void:
	_routes = {}
	for k in routes.keys():
		var role := str(k)
		var wp: Variant = routes[role]
		if typeof(wp) != TYPE_DICTIONARY:
			continue
		var arr: Variant = (wp as Dictionary).get("waypoints", [])
		if typeof(arr) != TYPE_ARRAY:
			continue
		_routes[role] = _normalize_waypoints(arr as Array)
	_overlay.queue_redraw()


func get_routes() -> Dictionary:
	var out: Dictionary = {}
	for role in _routes.keys():
		var steps: Array = _routes[role] as Array
		if steps.is_empty():
			continue
		out[role] = {"waypoints": steps.duplicate(true)}
	return out


func set_selected_route_role(role: String) -> void:
	_selected_role = role
	for i in _role_pick.item_count:
		if _role_pick.get_item_text(i) == role:
			_role_pick.select(i)
			return


func roles_on_field() -> Array[String]:
	var out: Array[String] = []
	for cell in _field.build_positions_array():
		if typeof(cell) != TYPE_DICTIONARY:
			continue
		out.append(str((cell as Dictionary).get("role", "")))
	return out


func _rebuild_role_picker() -> void:
	_role_pick.clear()
	var route_roles: Array[String] = []
	for r in roles_on_field():
		var ru := r.to_upper()
		if ru.begins_with("RB") or ru.begins_with("WR") or ru.begins_with("TE"):
			route_roles.append(r)
	route_roles.sort()
	for r in route_roles:
		_role_pick.add_item(r)
	if route_roles.is_empty():
		_selected_role = ""
	elif _selected_role.is_empty() or _selected_role not in route_roles:
		_selected_role = route_roles[0]
	if not _selected_role.is_empty():
		set_selected_route_role(_selected_role)


func _normalize_waypoints(arr: Array) -> Array:
	var out: Array = []
	for s in arr:
		if typeof(s) != TYPE_ARRAY or (s as Array).size() < 2:
			continue
		var a := s as Array
		out.append([int(a[0]), int(a[1])])
	return out


func _on_role_picked(idx: int) -> void:
	if idx < 0:
		return
	_selected_role = _role_pick.get_item_text(idx)
	_overlay.queue_redraw()


func _on_add_step(step_idx: int) -> void:
	if _selected_role.is_empty() or step_idx < 0 or step_idx >= STEP_DIRS.size():
		return
	var d: Dictionary = STEP_DIRS[step_idx]
	if not _routes.has(_selected_role):
		_routes[_selected_role] = []
	var lst: Array = _routes[_selected_role] as Array
	if lst.size() >= 16:
		return
	lst.append([int(d.get("dc", 0)), int(d.get("dr", 0))])
	_routes[_selected_role] = lst
	_overlay.queue_redraw()
	routes_changed.emit()


func _on_undo_step_pressed() -> void:
	if _selected_role.is_empty() or not _routes.has(_selected_role):
		return
	var lst: Array = _routes[_selected_role] as Array
	if lst.is_empty():
		return
	lst.pop_back()
	_routes[_selected_role] = lst
	_overlay.queue_redraw()
	routes_changed.emit()


func _on_clear_route_pressed() -> void:
	if _selected_role.is_empty():
		return
	_routes[_selected_role] = []
	_overlay.queue_redraw()
	routes_changed.emit()


func _role_start_grid(role: String) -> Vector2i:
	for p in _field.build_positions_array():
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = p
		if str(pd.get("role", "")) != role:
			continue
		var dr := int(pd.get("delta_row", 0))
		var dc := int(pd.get("delta_col", 0))
		return Vector2i(FormationEditorField.CENTER_COL + dc, FormationEditorField.LOS_ROW + dr)
	return Vector2i(FormationEditorField.CENTER_COL, FormationEditorField.LOS_ROW)


func _on_overlay_draw() -> void:
	for role in _routes.keys():
		var steps: Array = _routes.get(role, []) as Array
		if steps.is_empty():
			continue
		var pos := _role_start_grid(role)
		var pts: PackedVector2Array = PackedVector2Array()
		pts.append(_field.get_cell_center_local(pos.y, pos.x))
		for s in steps:
			if typeof(s) != TYPE_ARRAY or (s as Array).size() < 2:
				continue
			var a := s as Array
			pos.x += int(a[0])
			pos.y += int(a[1])
			pos.x = clampi(pos.x, 0, FormationEditorField.COLS - 1)
			pos.y = clampi(pos.y, 0, FormationEditorField.ROWS - 1)
			pts.append(_field.get_cell_center_local(pos.y, pos.x))
		var col := Color(1.0, 0.95, 0.2, 0.95) if role == _selected_role else Color(0.4, 1.0, 0.5, 0.85)
		for i in range(pts.size() - 1):
			_overlay.draw_line(pts[i], pts[i + 1], col, 2.0, true)
		for i in range(pts.size()):
			_overlay.draw_circle(pts[i], 3.0, col)
