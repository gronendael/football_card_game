extends Node
class_name TeamData

var teams: Array[Dictionary] = []

func load_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		teams = []
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		teams = []
		return
	teams.clear()
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			teams.append(item)

func get_by_id(team_id: String) -> Dictionary:
	for t in teams:
		if str(t.get("id", "")) == team_id:
			return t
	return {}

func has_team(team_id: String) -> bool:
	return not get_by_id(team_id).is_empty()

func get_all_ids() -> Array[String]:
	var ids: Array[String] = []
	for t in teams:
		var team_id := str(t.get("id", ""))
		if not team_id.is_empty():
			ids.append(team_id)
	return ids

