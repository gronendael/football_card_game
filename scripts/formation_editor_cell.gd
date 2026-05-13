extends Panel
class_name FormationEditorCell

const DND := "formation_editor_role"

var grid_row: int = 0
var grid_col: int = 0
var role: String = ""
var _circle_style: bool = true
var _is_los_row: bool = false
var _field: FormationEditorField


func setup(p_field: FormationEditorField, p_row: int, p_col: int, circle_tokens: bool, is_los_row: bool = false) -> void:
	_field = p_field
	grid_row = p_row
	grid_col = p_col
	_circle_style = circle_tokens
	_is_los_row = is_los_row
	custom_minimum_size = Vector2(32, 28)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_style()


func set_role(r: String) -> void:
	role = r
	_refresh_style()


func clear_role() -> void:
	role = ""
	_refresh_style()


func _refresh_style() -> void:
	var sb := StyleBoxFlat.new()
	var empty_bg := Color(0.92, 0.96, 1.0, 1.0) if _is_los_row else Color(0.15, 0.18, 0.22, 0.95)
	var filled := Color(0.25, 0.45, 0.35, 0.95) if _circle_style else Color(0.35, 0.32, 0.55, 0.95)
	sb.bg_color = empty_bg if role.is_empty() else filled
	sb.set_border_width_all(1)
	sb.border_color = Color(0.05, 0.05, 0.05, 1)
	var rad := 14 if _circle_style else 3
	sb.corner_radius_top_left = rad
	sb.corner_radius_top_right = rad
	sb.corner_radius_bottom_right = rad
	sb.corner_radius_bottom_left = rad
	add_theme_stylebox_override("panel", sb)
	queue_redraw()


func _draw() -> void:
	if role.is_empty():
		return
	var f := ThemeDB.fallback_font
	var sz := 11
	draw_string(f, Vector2(4, 18), role, HORIZONTAL_ALIGNMENT_LEFT, -1, sz)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if role.is_empty():
		return null
	var lbl := Label.new()
	lbl.text = role
	set_drag_preview(lbl)
	return {"kind": DND, "role": role, "from_row": grid_row, "from_col": grid_col}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return str((data as Dictionary).get("kind", "")) == DND


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var d: Dictionary = data
	if str(d.get("kind", "")) != DND:
		return
	var r := str(d.get("role", ""))
	if r.is_empty():
		return
	var fr := int(d.get("from_row", -1))
	var fc := int(d.get("from_col", -1))
	if _field:
		_field.apply_drop(fr, fc, grid_row, grid_col, r)
