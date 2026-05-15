extends RefCounted
class_name PlaysCatalog

## Top-level keys are play ids (e.g. run_01). Each row has `play_type` (bucket).
var _plays: Dictionary = {}

const REQUIRED_BUCKETS := ["kickoff", "kickoff_return", "punt", "punt_return", "spot_kick", "fg_xp_def"]


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


func get_play(play_id: String) -> Dictionary:
	var d: Variant = _plays.get(play_id, {})
	return d if typeof(d) == TYPE_DICTIONARY else {}


func all_play_ids() -> Array[String]:
	var out: Array[String] = []
	for k in _plays.keys():
		out.append(str(k))
	return out


func formation_id_for(play_id: String) -> String:
	return str(get_play(play_id).get("formation_id", ""))


func bucket(play_id: String) -> String:
	return str(get_play(play_id).get("play_type", ""))


func play_ids_with_bucket(wanted_bucket: String) -> Array[String]:
	var out: Array[String] = []
	for k in _plays.keys():
		var pid := str(k)
		if bucket(pid) == wanted_bucket:
			out.append(pid)
	return out


func filter_play_ids(play_ids: Array, bucket: String) -> Array[String]:
	var out: Array[String] = []
	for pid in play_ids:
		var sid := str(pid)
		if bucket(sid) == bucket:
			out.append(sid)
	return out


func validate_playbook(play_ids: Array, max_slots: int) -> PackedStringArray:
	var errs: PackedStringArray = []
	if play_ids.is_empty():
		errs.append("playbook empty")
		return errs
	if play_ids.size() > max_slots:
		errs.append("playbook size %d exceeds max %d" % [play_ids.size(), max_slots])
	var seen := {}
	for pid in play_ids:
		seen[str(pid)] = true
	if seen.size() != play_ids.size():
		errs.append("duplicate play ids in playbook")
	var buckets_present := {}
	for pid in play_ids:
		var b := bucket(str(pid))
		if not b.is_empty():
			buckets_present[b] = true
	for req in REQUIRED_BUCKETS:
		if not buckets_present.has(req):
			errs.append("missing required play_type: %s" % req)
	for pid in play_ids:
		if not _plays.has(str(pid)):
			errs.append("unknown play id: %s" % str(pid))
	return errs
