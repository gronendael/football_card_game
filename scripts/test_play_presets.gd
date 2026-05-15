extends RefCounted
class_name TestPlayPresets

const FILE_PATH := "user://test_play_presets.json"


static func load_all() -> Array[Dictionary]:
	if not FileAccess.file_exists(FILE_PATH):
		return []
	var f := FileAccess.open(FILE_PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var arr: Variant = (parsed as Dictionary).get("presets", [])
	if typeof(arr) != TYPE_ARRAY:
		return []
	var out: Array[Dictionary] = []
	for item in arr as Array:
		if typeof(item) == TYPE_DICTIONARY:
			out.append(_normalize_preset(item as Dictionary))
	return out


static func save_all(presets: Array[Dictionary]) -> Error:
	var normalized: Array = []
	for p in presets:
		normalized.append(_normalize_preset(p))
	var body := {"version": 1, "presets": normalized}
	var text := JSON.stringify(body, "\t")
	var f := FileAccess.open(FILE_PATH, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_CREATE
	f.store_string(text)
	f.close()
	return OK


static func _normalize_preset(d: Dictionary) -> Dictionary:
	var roles: Array[String] = []
	var raw: Variant = d.get("roles", [])
	if typeof(raw) == TYPE_ARRAY:
		for r in raw as Array:
			var rs := str(r).strip_edges()
			if not rs.is_empty():
				roles.append(rs)
	return {
		"id": str(d.get("id", make_id(str(d.get("name", "preset"))))),
		"name": str(d.get("name", "Untitled")),
		"roles": roles,
		"show_ball": bool(d.get("show_ball", true)),
		"play_events": bool(d.get("play_events", false)),
	}


static func make_id(name: String) -> String:
	var slug := name.to_lower().strip_edges()
	slug = slug.replace(" ", "_")
	var clean := ""
	for i in slug.length():
		var c := slug[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_":
			clean += c
	if clean.is_empty():
		clean = "preset"
	return clean + "_" + str(Time.get_ticks_msec() % 100000)
