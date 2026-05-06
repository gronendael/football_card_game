extends Control

## Full-area drop target behind queued card tiles (tiles use MOUSE_FILTER_IGNORE).


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return str(data.get("type", "")) == "queue_hand_card"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	for n in get_tree().get_nodes_in_group("game_scene"):
		if n.has_method("try_queue_hand_card_from_drag_data"):
			n.try_queue_hand_card_from_drag_data(data)
			break
