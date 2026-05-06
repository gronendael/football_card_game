extends Node
class_name PlayerData

var players: Array[Dictionary] = []

func load_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		players = []
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_ARRAY:
		players.clear()
		for item in parsed:
			if typeof(item) == TYPE_DICTIONARY:
				players.append(item)
	else:
		players.clear()

func get_team(team: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in players:
		if str(p.get("team", "")) == team:
			out.append(p)
	return out

func get_by_id(player_id: String) -> Dictionary:
	for p in players:
		if str(p.get("id", "")) == player_id:
			return p
	return {}

func get_best_kicker(team: String) -> Dictionary:
	var best: Dictionary = {}
	var best_acc := -1
	for p in players:
		if str(p.get("team", "")) != team:
			continue
		var acc := int(p.get("kick_accuracy", 0))
		if acc > best_acc:
			best_acc = acc
			best = p
	return best
