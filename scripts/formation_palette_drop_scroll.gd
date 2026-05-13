extends ScrollContainer
class_name FormationPaletteDropScroll
## Accepts drag from formation grid cells and clears the placement (same as former Trash behavior).

var editor_field: FormationEditorField


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return editor_field != null and editor_field.should_accept_remove_drop(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if editor_field:
		editor_field.apply_remove_drop(data)
