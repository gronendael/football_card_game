extends RefCounted
class_name FormationsCatalog

## 7v7 on field; per-role caps align with docs/Team_Setup.md (positions on field).
const MAX_PLAYERS_ON_FIELD := 7
const ROLE_FAMILY_MAX := {
	"QB": 1,
	"RB": 2,
	"WR": 5,
	"TE": 2,
	"OL": 4,
	"DL": 4,
	"LB": 3,
	"CB": 3,
	"S": 2,
	"K": 1,
	"P": 1,
	"RET": 2,
	"ST": 6,
}

var formations: Array[Dictionary] = []

func load_from_json(path: String) -> bool:
	formations.clear()
	if not FileAccess.file_exists(path):
		push_error("Formations file missing: %s" % path)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_ARRAY:
		push_error("formations.json must be a JSON array")
		return false
	for item in parsed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var f: Dictionary = item
		if not _validate_formation(f):
			return false
		formations.append(f)
	return true

func get_by_id(formation_id: String) -> Dictionary:
	for f in formations:
		if str(f.get("id", "")) == formation_id:
			return f
	return {}

func _validate_formation(f: Dictionary) -> bool:
	var fid := str(f.get("id", ""))
	if fid.is_empty():
		push_error("Formation missing id")
		return false
	var side := str(f.get("side", ""))
	if side not in ["offense", "defense", "special"]:
		push_error("Formation %s: invalid side %s" % [fid, side])
		return false
	var pos: Variant = f.get("positions", [])
	if typeof(pos) != TYPE_ARRAY or pos.is_empty():
		push_error("Formation %s: positions must be a non-empty array" % fid)
		return false
	if pos.size() != MAX_PLAYERS_ON_FIELD:
		push_error("Formation %s: must have exactly %d positions (7v7), got %d" % [fid, MAX_PLAYERS_ON_FIELD, pos.size()])
		return false
	var family_counts := {}
	for p in pos:
		if typeof(p) != TYPE_DICTIONARY:
			push_error("Formation %s: invalid position entry" % fid)
			return false
		var pd: Dictionary = p
		if str(pd.get("role", "")).is_empty():
			push_error("Formation %s: position missing role" % fid)
			return false
		if not pd.has("delta_row") or not pd.has("delta_col"):
			push_error("Formation %s: position %s missing delta_row/delta_col" % [fid, pd.get("role")])
			return false
		var fam := _role_family(str(pd.get("role", "")))
		if fam.is_empty():
			push_error("Formation %s: unknown role prefix for %s" % [fid, pd.get("role")])
			return false
		family_counts[fam] = int(family_counts.get(fam, 0)) + 1
	for fam in family_counts.keys():
		var cap: int = int(ROLE_FAMILY_MAX.get(fam, 0))
		if cap <= 0:
			push_error("Formation %s: role family %s is not allowed in formations data" % [fid, fam])
			return false
		var c: int = int(family_counts[fam])
		if c > cap:
			push_error("Formation %s: too many %s (%d > max %d)" % [fid, fam, c, cap])
			return false
	return true


func _role_family(role: String) -> String:
	if role.begins_with("ST"):
		return "ST"
	if role.begins_with("RET"):
		return "RET"
	if role == "QB":
		return "QB"
	if role.begins_with("RB"):
		return "RB"
	if role.begins_with("WR"):
		return "WR"
	if role.begins_with("TE"):
		return "TE"
	if role.begins_with("OL"):
		return "OL"
	if role.begins_with("DL"):
		return "DL"
	if role.begins_with("LB"):
		return "LB"
	if role.begins_with("CB"):
		return "CB"
	if role.begins_with("S"):
		return "S"
	if role == "K":
		return "K"
	if role == "P":
		return "P"
	return ""
