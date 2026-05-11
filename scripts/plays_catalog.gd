extends RefCounted
class_name PlaysCatalog

## Top-level keys match play type ids (offense/defense/special) used in game_scene / game_state.
var _plays: Dictionary = {}


func load_from_json(path: String) -> bool:
	_plays.clear()
	if not FileAccess.file_exists(path):
		push_error("Plays file missing: %s" % path)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("plays.json must be a JSON object")
		return false
	_plays = parsed
	return true


func get_play(play_type: String) -> Dictionary:
	var d: Variant = _plays.get(play_type, {})
	return d if typeof(d) == TYPE_DICTIONARY else {}


func formation_id_for(play_type: String) -> String:
	return str(get_play(play_type).get("formation_id", ""))
