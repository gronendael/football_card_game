extends Node
class_name PlayerData

const DEFAULT_SPECIES_ID := "sp_velox"
const FALLBACK_SPECIES_IDS: Array[String] = ["sp_velox", "sp_gravik", "sp_cerebron", "sp_durant"]

var players: Array[Dictionary] = []

func load_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		players = []
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_ARRAY:
		players.clear()
		var idx := 0
		for item in parsed:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var row: Dictionary = (item as Dictionary).duplicate(true)
			_ensure_species_id_on_row(row, idx)
			players.append(row)
			idx += 1
	else:
		players.clear()


func _ensure_species_id_on_row(row: Dictionary, roster_index: int) -> void:
	if not str(row.get("species_id", "")).is_empty():
		return
	if FALLBACK_SPECIES_IDS.is_empty():
		row["species_id"] = DEFAULT_SPECIES_ID
		return
	row["species_id"] = FALLBACK_SPECIES_IDS[roster_index % FALLBACK_SPECIES_IDS.size()]


static func species_id_from_dict(player: Dictionary) -> String:
	var sid := str(player.get("species_id", "")).strip_edges()
	return sid if not sid.is_empty() else DEFAULT_SPECIES_ID

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

## Best punt-return profile on `team` by speed + agility (expand later with depth-chart PR).
func get_primary_return_candidate(team: String) -> Dictionary:
	var best: Dictionary = {}
	var best_score := -1
	for p in players:
		if str(p.get("team", "")) != team:
			continue
		var sc := int(p.get("speed", 0)) + int(p.get("agility", 0))
		if sc > best_score:
			best_score = sc
			best = p
	return best
