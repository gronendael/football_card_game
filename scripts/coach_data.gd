extends Node
class_name CoachData

## coach id -> coach Dictionary (from coaches_catalog.json)
var coaches_by_id: Dictionary = {}


func load_catalog(path: String) -> void:
	coaches_by_id.clear()
	if not FileAccess.file_exists(path):
		push_warning("Coaches catalog missing: %s" % path)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var arr: Variant = parsed.get("coaches", [])
	if typeof(arr) != TYPE_ARRAY:
		return
	for item in arr:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var cid := str(item.get("id", ""))
		if cid.is_empty():
			continue
		coaches_by_id[cid] = item


func get_coach(coach_id: String) -> Dictionary:
	var d: Variant = coaches_by_id.get(coach_id, {})
	return d if typeof(d) == TYPE_DICTIONARY else {}
