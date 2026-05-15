extends RefCounted
class_name TestPlayNarrativeBuilder

const ROLE_ORDER: Array[String] = [
	"QB", "RB1", "RB2", "OL1", "OL2", "OL3", "WR1", "WR2", "WR3", "TE1", "TE2",
	"DL1", "DL2", "DL3", "LB1", "LB2", "CB1", "CB2", "S1", "S2",
]


static func build_beats(
	snapshots: Array,
	sim_log: PlayEventLog,
	tick_play_result: Dictionary,
	play_bucket: String
) -> Array[Dictionary]:
	var beats: Array[Dictionary] = []
	if snapshots.is_empty():
		return beats
	var events_by_tick := _index_events_by_tick(sim_log)
	var snap0: Dictionary = snapshots[0] as Dictionary
	beats.append(_build_snap_beat(snap0))
	for i in range(1, snapshots.size()):
		var prev: Dictionary = snapshots[i - 1] as Dictionary
		var cur: Dictionary = snapshots[i] as Dictionary
		var tick := int(cur.get("tick", i))
		var evs: Array = events_by_tick.get(tick, []) as Array
		beats.append(_build_beat(i, tick, prev, cur, evs, play_bucket))
	if tick_play_result.has("breakdown"):
		_append_throw_beat(beats, snapshots, tick_play_result)
	return beats


static func format_beat(
	beat: Dictionary,
	role_filter: Dictionary,
	show_ball: bool,
	show_play_events: bool,
	changes_only: bool
) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var header := str(beat.get("header", ""))
	if not header.is_empty():
		lines.append("=== %s ===" % header)
	var sections: Array = beat.get("sections", []) as Array
	for sec_v in sections:
		if typeof(sec_v) != TYPE_DICTIONARY:
			continue
		var sec: Dictionary = sec_v
		var role := str(sec.get("role", ""))
		if role == "__ball__" and not show_ball:
			continue
		if role == "__throw__" and not show_play_events:
			continue
		if role != "__ball__" and role != "__throw__" and not _role_visible(role, role_filter, show_ball):
			continue
		var sec_lines: Array = []
		for line in sec.get("lines", []) as Array:
			var s := str(line)
			if changes_only and role not in ["__ball__", "__throw__"] and _is_stay_only_line(s):
				continue
			sec_lines.append(s)
		if sec_lines.is_empty():
			continue
		if role not in ["__ball__", "__throw__"]:
			lines.append(role + ":")
		for s in sec_lines:
			lines.append("  " + s if role not in ["__ball__", "__throw__"] else s)
		lines.append("")
	while lines.size() > 0 and lines[lines.size() - 1].is_empty():
		lines.resize(lines.size() - 1)
	return "\n".join(lines)


static func _is_stay_only_line(line: String) -> bool:
	return " stays on " in line or "At snap" in line


static func _build_snap_beat(snap: Dictionary) -> Dictionary:
	var sections: Array = []
	sections.append({
		"role": "__ball__",
		"lines": ["Snap — ball with %s." % _carrier_label(snap)],
	})
	for role in _sorted_roles(_all_roles_in_snap(snap)):
		var pd: Dictionary = _player_by_role(snap, role)
		if pd.is_empty():
			continue
		sections.append({
			"role": role,
			"lines": [_format_stay_line(role, pd, snap, "At snap")],
		})
	return {
		"beat_index": 0,
		"snapshot_index": 0,
		"tick": 0,
		"header": "Snap",
		"pause": false,
		"sections": sections,
	}


static func _build_beat(
	snap_i: int,
	tick: int,
	prev: Dictionary,
	cur: Dictionary,
	tick_events: Array,
	play_bucket: String
) -> Dictionary:
	var sections: Array = []
	var prev_carrier := _carrier_label(prev)
	var cur_carrier := _carrier_label(cur)
	var carrier_changed := prev_carrier != cur_carrier
	if carrier_changed:
		sections.append({
			"role": "__ball__",
			"lines": ["Ball is with %s." % cur_carrier],
		})
	var roles_done: Dictionary = {}
	for role in _sorted_roles(_all_roles_in_snap(cur)):
		roles_done[role] = true
		var lines := _lines_for_role_on_beat(role, prev, cur, tick_events, play_bucket)
		if lines.is_empty():
			continue
		sections.append({"role": role, "lines": lines})
	for ev in tick_events:
		var code := str(ev.get("code", ""))
		if code in ["sim_move", "sim_start"]:
			continue
		var roles := _roles_from_event(ev, cur)
		for role in roles:
			if roles_done.has(role):
				continue
			var extra := _humanize_event(ev, play_bucket)
			if extra.is_empty():
				continue
			sections.append({"role": role, "lines": [extra]})
	return {
		"beat_index": snap_i,
		"snapshot_index": snap_i,
		"tick": tick,
		"header": "Tick %d" % tick,
		"pause": _beat_should_pause(cur, tick_events),
		"sections": sections,
	}


static func _lines_for_role_on_beat(
	role: String,
	prev: Dictionary,
	cur: Dictionary,
	tick_events: Array,
	play_bucket: String
) -> Array[String]:
	var lines: Array[String] = []
	var p0 := _player_by_role(prev, role)
	var p1 := _player_by_role(cur, role)
	if p1.is_empty():
		return lines
	lines.append(_format_movement_line(role, p0, p1, cur))
	for ev in tick_events:
		var code := str(ev.get("code", ""))
		if code in ["sim_move", "sim_start"]:
			continue
		if not _event_mentions_role(ev, role, cur):
			continue
		var msg := _humanize_event(ev, play_bucket)
		if msg.is_empty():
			continue
		lines.append(msg)
	return lines


static func _format_movement_line(role: String, p0: Dictionary, p1: Dictionary, snap: Dictionary) -> String:
	var intent := _plain_intent(str(p1.get("intent_action", "")))
	var target := _target_role_label(snap, p1)
	var pos1 := _tile_str(p1)
	if p0.is_empty():
		return "%s at %s (action: %s, target: %s)." % [role, pos1, intent, target]
	var pos0 := _tile_str(p0)
	if pos0 == pos1:
		return "%s stays on %s (action: %s, target: %s)." % [role, pos1, intent, target]
	var dr := int(p1.get("global_row", 0)) - int(p0.get("global_row", 0))
	var dc := int(p1.get("global_col", 0)) - int(p0.get("global_col", 0))
	var move_desc := "moved" if absi(dr) + absi(dc) > 0 else "stays"
	return "%s %s to %s (action: %s, target: %s)." % [role, move_desc, pos1, intent, target]


static func _format_stay_line(role: String, pd: Dictionary, snap: Dictionary, prefix: String) -> String:
	return "%s %s on %s (action: %s, target: %s)." % [
		role,
		prefix,
		_tile_str(pd),
		_plain_intent(str(pd.get("intent_action", ""))),
		_target_role_label(snap, pd),
	]


static func _target_role_label(snap: Dictionary, pd: Dictionary) -> String:
	var id_map := _id_to_role(snap)
	for key in ["man_cover_target_id", "engaged_with_player_id"]:
		var tid := str(pd.get(key, ""))
		if tid.is_empty():
			continue
		var role := str(id_map.get(tid, ""))
		if not role.is_empty():
			return role
	return "None"


static func _humanize_event(ev: Dictionary, play_bucket: String) -> String:
	var code := str(ev.get("code", ""))
	var msg := str(ev.get("message", ""))
	match code:
		"block_attempt":
			return msg
		"engage_block":
			return msg.replace("engaged", "engages with").replace("Engaged", "engages with")
		"coverage_sep":
			return msg
		"shed_block", "shed_block_fail":
			return msg
		"pass_pressure_tick":
			return msg.replace("Pre-throw sample:", "Pressure check:").replace("Parallel dropback sample:", "Pressure check:")
		"pass_protection", "pass_ol_dl", "route_sep", "qb_target", "qb_pressure":
			return msg
		"incomplete", "completion", "sack", "qb_evade", "throwaway", "qb_forced_throw":
			return msg
		_:
			if code.is_empty():
				return ""
			return msg


static func _append_throw_beat(beats: Array[Dictionary], snapshots: Array, tpr: Dictionary) -> void:
	var bd: Variant = tpr.get("breakdown", [])
	if typeof(bd) != TYPE_ARRAY:
		return
	var snap_i := snapshots.size() - 1
	var tick := int((snapshots[snap_i] as Dictionary).get("tick", 0))
	var lines: Array[String] = []
	for line in bd as Array:
		var s := str(line).strip_edges()
		if s.is_empty():
			continue
		lines.append(s)
	if lines.is_empty():
		return
	var sections: Array = [{"role": "__throw__", "lines": lines}]
	beats.append({
		"beat_index": beats.size(),
		"snapshot_index": snap_i,
		"tick": tick,
		"header": "Throw resolution",
		"pause": true,
		"sections": sections,
	})


static func _index_events_by_tick(sim_log: PlayEventLog) -> Dictionary:
	var out: Dictionary = {}
	for ev in sim_log.events:
		var tick := int(ev.get("tick", 0))
		if not out.has(tick):
			out[tick] = []
		(out[tick] as Array).append(ev)
	return out


static func _role_visible(role: String, role_filter: Dictionary, show_ball: bool) -> bool:
	if role == "__ball__" or role == "__throw__":
		return show_ball or role == "__throw__"
	if role_filter.is_empty():
		return true
	return role_filter.has(role)


static func _beat_should_pause(cur: Dictionary, tick_events: Array) -> bool:
	var reason := str(cur.get("play_end_reason", ""))
	if reason in ["tackle", "touchdown", "fumble", "incomplete", "interception", "sack"]:
		return true
	for ev in tick_events:
		var code := str(ev.get("code", ""))
		if code in ["tackle", "touchdown", "fumble", "incomplete", "interception", "completion", "sack"]:
			return true
	return false


static func _event_mentions_role(ev: Dictionary, role: String, snap: Dictionary) -> bool:
	for r in _roles_from_event(ev, snap):
		if r == role:
			return true
	return false


static func _roles_from_event(ev: Dictionary, snap: Dictionary) -> Array[String]:
	var roles: Array[String] = []
	var msg := str(ev.get("message", ""))
	for r in _all_roles_in_snap(snap):
		if msg.contains(r):
			roles.append(r)
	var actors: Dictionary = ev.get("actors", {}) as Dictionary
	var id_map := _id_to_role(snap)
	for pid_key in ["primary_id", "secondary_id"]:
		var pid := str(actors.get(pid_key, ""))
		if id_map.has(pid):
			var role := str(id_map[pid])
			if role not in roles:
				roles.append(role)
	return roles


static func _sorted_roles(roles: Array) -> Array[String]:
	var out: Array[String] = []
	for want in ROLE_ORDER:
		if want in roles:
			out.append(want)
	for r in roles:
		if r not in out:
			out.append(str(r))
	return out


static func _all_roles_in_snap(snap: Dictionary) -> Array:
	var out: Array = []
	for pd_v in snap.get("players", []) as Array:
		if typeof(pd_v) != TYPE_DICTIONARY:
			continue
		var role := str((pd_v as Dictionary).get("role", ""))
		if not role.is_empty():
			out.append(role)
	return out


static func _player_by_role(snap: Dictionary, role: String) -> Dictionary:
	for pd_v in snap.get("players", []) as Array:
		if typeof(pd_v) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = pd_v
		if str(pd.get("role", "")) == role:
			return pd
	return {}


static func _id_to_role(snap: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for pd_v in snap.get("players", []) as Array:
		if typeof(pd_v) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = pd_v
		out[str(pd.get("player_id", ""))] = str(pd.get("role", ""))
	return out


static func _carrier_label(snap: Dictionary) -> String:
	var cid := str(snap.get("ball_carrier_id", ""))
	if cid.is_empty():
		return "unknown"
	var id_map := _id_to_role(snap)
	return str(id_map.get(cid, cid))


static func _tile_str(pd: Dictionary) -> String:
	if pd.is_empty():
		return "(?, ?)"
	return "(%d, %d)" % [int(pd.get("global_col", 0)), int(pd.get("global_row", 0))]


static func _plain_intent(intent: String) -> String:
	match intent:
		"run_block":
			return "run block"
		"pass_block":
			return "pass block"
		"route":
			return "run route"
		"carry":
			return "carry"
		"drop_back":
			return "drop back"
		"pass_rush":
			return "pass rush"
		"run_stop":
			return "run stop"
		"cover_man":
			return "cover man"
		"cover_zone":
			return "cover zone"
		"pursue":
			return "pursue"
		_:
			return intent.replace("_", " ") if not intent.is_empty() else "idle"


static func _role_sort_key(role: String) -> int:
	var idx := ROLE_ORDER.find(role)
	return idx if idx >= 0 else 999
