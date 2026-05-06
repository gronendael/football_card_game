extends Node
class_name CoachData

var coaches: Dictionary = {}

func load_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		coaches = {}
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		coaches = parsed
	else:
		coaches = {}

func get_team_staff(team: String) -> Dictionary:
	return coaches.get(team, {
		"head_coach": {"id": "none", "name": "None", "bonus": {}},
		"off_coord": {"id": "none", "name": "None", "bonus": {}},
		"def_coord": {"id": "none", "name": "None", "bonus": {}}
	})
