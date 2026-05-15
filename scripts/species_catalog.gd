extends RefCounted
class_name SpeciesCatalog

const DEFAULT_SPECIES_ID := "sp_velox"

var species: Array[Dictionary] = []


func load_from_json(path: String) -> bool:
	species.clear()
	if not FileAccess.file_exists(path):
		push_error("Species file missing: %s" % path)
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_ARRAY:
		push_error("species.json must be a JSON array")
		return false
	for item in parsed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var s: Dictionary = item
		if not validate_species_dict(s):
			return false
		species.append(s)
	return not species.is_empty()


func validate_species_dict(s: Dictionary) -> bool:
	var sid := str(s.get("id", ""))
	if sid.is_empty():
		push_error("species entry missing id")
		return false
	if str(s.get("display_name", "")).is_empty():
		push_error("species %s missing display_name" % sid)
		return false
	return true


func get_by_id(species_id: String) -> Dictionary:
	for s in species:
		if str(s.get("id", "")) == species_id:
			return s
	return {}


func display_name_for(species_id: String) -> String:
	var s := get_by_id(species_id)
	if s.is_empty():
		return species_id
	return str(s.get("display_name", species_id))


func all_ids() -> Array[String]:
	var out: Array[String] = []
	for s in species:
		out.append(str(s.get("id", "")))
	return out
