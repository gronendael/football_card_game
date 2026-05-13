extends Label
class_name FormationPaletteLabel

var role_key: String = ""
var editor_field: FormationEditorField


func setup(role: String) -> void:
	role_key = role
	text = role
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_font_size_override("font_size", 14)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var lbl := Label.new()
	lbl.text = role_key
	set_drag_preview(lbl)
	return {"kind": FormationEditorCell.DND, "role": role_key, "from_row": -1, "from_col": -1}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return editor_field != null and editor_field.should_accept_remove_drop(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if editor_field:
		editor_field.apply_remove_drop(data)
