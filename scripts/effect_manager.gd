extends Node
class_name EffectManager

var active_effects: Array[Dictionary] = []

func add_effect(effect: Dictionary, duration_type: String = "plays", duration_value: int = 1) -> void:
	var entry := effect.duplicate(true)
	entry["duration_type"] = duration_type
	entry["duration_value"] = duration_value
	active_effects.append(entry)

func tick_play() -> void:
	for i in range(active_effects.size() - 1, -1, -1):
		var effect := active_effects[i]
		if effect.get("duration_type", "plays") == "plays":
			effect["duration_value"] = int(effect.get("duration_value", 1)) - 1
			if int(effect["duration_value"]) <= 0:
				active_effects.remove_at(i)
			else:
				active_effects[i] = effect

func clear_drive_effects() -> void:
	for i in range(active_effects.size() - 1, -1, -1):
		var t := str(active_effects[i].get("duration_type", "plays"))
		if t == "drive":
			active_effects.remove_at(i)

func collect_modifiers(play_type: String) -> Dictionary:
	var out := {
		"zone_bonus": 0,
		"field_goal_bonus": 0,
		"defense_penalty": 0
	}
	for effect in active_effects:
		var data: Dictionary = effect.get("effect_data", {})
		if data.has("zone_bonus"):
			out["zone_bonus"] += int(data["zone_bonus"])
		if play_type == "spot_kick" and data.has("field_goal_bonus"):
			out["field_goal_bonus"] += int(data["field_goal_bonus"])
		if data.has("defense_penalty"):
			out["defense_penalty"] += int(data["defense_penalty"])
	return out
