extends RefCounted
class_name TestPlayLogBuilder

const PAUSE_KINDS: Array[String] = ["throw", "tackle", "touchdown"]


static func build(
	snapshots: Array,
	sim_log: PlayEventLog,
	tick_play_result: Dictionary,
	play_bucket: String
) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if snapshots.is_empty():
		return events
	_add_snap_event(events, snapshots[0] as Dictionary, play_bucket)
	var prev_reason := ""
	var prev_carrier := ""
	var prev_pressure := -1
	var throw_tick := -1
	for i in range(1, snapshots.size()):
		var prev: Dictionary = snapshots[i - 1] as Dictionary
		var cur: Dictionary = snapshots[i] as Dictionary
		var tick := int(cur.get("tick", i))
		var reason := str(cur.get("play_end_reason", ""))
		var carrier := str(cur.get("ball_carrier_id", ""))
		var pressure := int(cur.get("pass_pressure", 0))

		if play_bucket == "pass" and pressure != prev_pressure and prev_pressure >= 0:
			_add_pressure_event(events, i, tick, pressure, float(cur.get("pass_protection", 0.0)))
		elif play_bucket == "pass" and prev_pressure < 0 and tick > 0:
			_add_pressure_event(events, i, tick, pressure, float(cur.get("pass_protection", 0.0)))
		prev_pressure = pressure

		if carrier != prev_carrier and not carrier.is_empty() and not prev_carrier.is_empty():
			_add_ball_event(events, i, tick, prev, cur, prev_carrier, carrier)
		elif i == 1 and not carrier.is_empty():
			_add_ball_event(events, i, tick, prev, cur, "", carrier)

		var prev_roles := _role_map(prev)
		var cur_roles := _role_map(cur)
		for role in cur_roles.keys():
			var p0: Dictionary = prev_roles.get(role, {}) as Dictionary
			var p1: Dictionary = cur_roles[role] as Dictionary
			if p1.is_empty():
				continue
			var diff := _diff_player(p0, p1)
			if diff.is_empty():
				continue
			_add_player_change_event(events, i, tick, role, p0, p1, diff, play_bucket, prev, cur)

		for ev in sim_log.events:
			if int(ev.get("tick", -1)) != tick:
				continue
			var code := str(ev.get("code", ""))
			if code in ["sim_start", "sim_move"]:
				continue
			_add_sim_event(events, i, tick, ev, cur_roles, cur)

		if reason != prev_reason and not reason.is_empty():
			_add_end_event(events, i, tick, reason, cur, play_bucket)
			if reason == "pass_resolved" or reason == "incomplete" or reason == "interception":
				throw_tick = tick
		prev_reason = reason
		prev_carrier = carrier

	if throw_tick >= 0 or play_bucket == "pass":
		_append_resolver_events(events, snapshots, tick_play_result, play_bucket)

	return events


static func _add_snap_event(events: Array[Dictionary], snap: Dictionary, play_bucket: String) -> void:
	var bucket_lbl := "pass play" if play_bucket == "pass" else "run play"
	var carrier := _carrier_role_label(snap)
	var lines: Array[String] = ["Ball at snap: %s." % carrier]
	lines.append_array(_full_state_lines(snap, []))
	events.append({
		"kind": "snap",
		"pause": false,
		"snapshot_index": 0,
		"tick": 0,
		"headline": "Snap — %s lined up at midfield." % bucket_lbl.capitalize(),
		"lines": lines,
		"roles": all_roles_in_snap(snap),
		"ball_only": false,
	})


static func _add_pressure_event(events: Array[Dictionary], snap_i: int, tick: int, pressure: int, prot: float) -> void:
	events.append({
		"kind": "pressure",
		"pause": false,
		"snapshot_index": snap_i,
		"tick": tick,
		"headline": "Dropback — QB under pressure level %d." % pressure,
		"lines": ["Protection score %.1f." % prot],
		"roles": ["QB"],
		"ball_only": false,
	})


static func _add_ball_event(
	events: Array[Dictionary],
	snap_i: int,
	tick: int,
	prev: Dictionary,
	cur: Dictionary,
	from_id: String,
	to_id: String
) -> void:
	var from_role := _role_for_id(prev, from_id)
	var to_role := _role_for_id(cur, to_id)
	var tile := _tile_str(_player_dict(cur, to_id))
	var headline := "Ball — now with %s at %s." % [to_role, tile]
	if not from_role.is_empty():
		headline = "Ball — %s to %s at %s." % [from_role, to_role, tile]
	events.append({
		"kind": "ball",
		"pause": false,
		"snapshot_index": snap_i,
		"tick": tick,
		"headline": headline,
		"lines": [_state_line(cur, _player_dict(cur, to_id), to_role)],
		"roles": _ball_roles(from_role, to_role),
		"ball_only": true,
	})


static func _add_player_change_event(
	events: Array[Dictionary],
	snap_i: int,
	tick: int,
	role: String,
	p0: Dictionary,
	p1: Dictionary,
	diff: Dictionary,
	play_bucket: String,
	prev_snap: Dictionary,
	cur_snap: Dictionary
) -> void:
	var headline := _change_headline(role, p0, p1, diff, play_bucket, tick, cur_snap)
	var event_roles: Array[String] = [role]
	if diff.has("engaged_with_player_id"):
		var eng_id := str(p1.get("engaged_with_player_id", ""))
		if eng_id.is_empty():
			eng_id = str(p0.get("engaged_with_player_id", ""))
		var partner := _role_for_id(cur_snap, eng_id)
		if partner.is_empty():
			partner = _role_for_id(prev_snap, eng_id)
		if not partner.is_empty() and partner not in event_roles:
			event_roles.append(partner)
	events.append({
		"kind": "move",
		"pause": false,
		"snapshot_index": snap_i,
		"tick": tick,
		"headline": headline,
		"lines": [_state_line(cur_snap, p1, role), _change_detail(cur_snap, p0, p1, diff)],
		"roles": event_roles,
		"ball_only": false,
	})


static func _add_sim_event(
	events: Array[Dictionary],
	snap_i: int,
	tick: int,
	ev: Dictionary,
	cur_roles: Dictionary,
	cur_snap: Dictionary
) -> void:
	var code := str(ev.get("code", ""))
	var msg := str(ev.get("message", ""))
	var plain := _humanize_sim_message(code, msg)
	var kind := "block" if code == "engage_block" else "sim"
	var roles: Array[String] = []
	if code == "engage_block":
		var actors: Dictionary = ev.get("actors", {}) as Dictionary
		var id_map := _id_role_map(cur_snap)
		for pid_key in ["primary_id", "secondary_id"]:
			var pid := str(actors.get(pid_key, ""))
			if pid.is_empty():
				continue
			var rr := str(id_map.get(pid, ""))
			if not rr.is_empty() and rr not in roles:
				roles.append(rr)
	if roles.is_empty():
		for r in cur_roles.keys():
			if msg.contains(str(r)):
				roles.append(str(r))
	events.append({
		"kind": kind,
		"pause": false,
		"snapshot_index": snap_i,
		"tick": tick,
		"headline": plain,
		"lines": [msg] if plain != msg else [],
		"roles": roles,
		"ball_only": false,
	})


static func _add_end_event(
	events: Array[Dictionary],
	snap_i: int,
	tick: int,
	reason: String,
	snap: Dictionary,
	play_bucket: String
) -> void:
	var kind := "end"
	var pause := false
	var headline := "Play ended (%s)." % reason
	if reason in ["pass_resolved", "incomplete", "interception"]:
		return
	match reason:
		"tackle":
			kind = "tackle"
			pause = true
			headline = "Tackle — ball carrier brought down."
		"touchdown":
			kind = "touchdown"
			pause = true
			headline = "Touchdown — ball carrier reached the end zone."
		"fumble":
			kind = "tackle"
			pause = true
			headline = "Fumble — ball is loose."
		"incomplete":
			kind = "throw"
			pause = true
			headline = "Incomplete pass."
		"interception":
			kind = "throw"
			pause = true
			headline = "Interception."
		"pass_resolved":
			kind = "throw"
			pause = true
			headline = "Pass complete — play moves to catch and run."
		"sack":
			kind = "tackle"
			pause = true
			headline = "Sack — QB brought down in the pocket."
		"clock":
			headline = "Whistle — run play timed out in the sim."
	events.append({
		"kind": kind,
		"pause": pause,
		"snapshot_index": snap_i,
		"tick": tick,
		"headline": headline,
		"lines": ["Reason code: %s." % reason],
		"roles": [_carrier_role_label(snap)],
		"ball_only": false,
	})


static func _append_resolver_events(
	events: Array[Dictionary],
	snapshots: Array,
	tpr: Dictionary,
	play_bucket: String
) -> void:
	if play_bucket != "pass" or tpr.is_empty():
		return
	var snap_i := snapshots.size() - 1
	var tick := int((snapshots[snap_i] as Dictionary).get("tick", 0))
	var bd: Variant = tpr.get("breakdown", [])
	if typeof(bd) != TYPE_ARRAY:
		return
	var lines: Array[String] = []
	for line in bd as Array:
		var s := str(line).strip_edges()
		if s.is_empty():
			continue
		lines.append(_humanize_resolver_line(s))
	var headline := "Throw — pass resolution."
	var result := str(tpr.get("result_text", ""))
	if not result.is_empty():
		headline = "Throw — %s." % result
	events.append({
		"kind": "throw",
		"pause": true,
		"snapshot_index": snap_i,
		"tick": tick,
		"headline": headline,
		"lines": lines,
		"roles": [],
		"ball_only": false,
	})


static func _role_map(snap: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for pd_v in snap.get("players", []) as Array:
		if typeof(pd_v) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = pd_v
		var role := str(pd.get("role", ""))
		if not role.is_empty():
			out[role] = pd
	return out


static func role_for_player_id(snap: Dictionary, player_id: String) -> String:
	return _role_for_id(snap, player_id)


static func all_roles_in_snap(snap: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for r in _role_map(snap).keys():
		out.append(str(r))
	out.sort()
	return out


static func _diff_player(p0: Dictionary, p1: Dictionary) -> Dictionary:
	var diff: Dictionary = {}
	for key in ["global_row", "global_col", "intent_action", "active_state", "engaged_with_player_id", "separation_tier", "man_cover_target_id"]:
		var a: Variant = p0.get(key, null)
		var b: Variant = p1.get(key, null)
		if p0.is_empty():
			diff[key] = b
		elif str(a) != str(b):
			diff[key] = b
	return diff


static func _change_headline(
	role: String,
	p0: Dictionary,
	p1: Dictionary,
	diff: Dictionary,
	_play_bucket: String,
	tick: int,
	snap: Dictionary
) -> String:
	if diff.has("global_row") or diff.has("global_col"):
		return "%s moved to %s (tick %d)." % [role, _tile_str(p1), tick]
	if diff.has("engaged_with_player_id"):
		var eng := str(p1.get("engaged_with_player_id", ""))
		if eng.is_empty():
			return "%s disengaged (tick %d)." % [role, tick]
		var partner := _role_for_id(snap, eng)
		if partner.is_empty():
			partner = "opponent"
		return "%s engaged %s (tick %d)." % [role, partner, tick]
	if diff.has("active_state"):
		return "%s is now %s (tick %d)." % [role, _plain_state(str(p1.get("active_state", ""))), tick]
	return "%s updated (tick %d)." % [role, tick]


static func _change_detail(snap: Dictionary, p0: Dictionary, p1: Dictionary, diff: Dictionary) -> String:
	var parts: Array[String] = []
	if diff.has("global_row") or diff.has("global_col"):
		parts.append("Tile %s → %s." % [_tile_str(p0), _tile_str(p1)])
	if diff.has("intent_action"):
		parts.append("Intent: %s → %s." % [_plain_intent(str(p0.get("intent_action", ""))), _plain_intent(str(p1.get("intent_action", "")))])
	if diff.has("active_state"):
		parts.append("Status: %s → %s." % [_plain_state(str(p0.get("active_state", ""))), _plain_state(str(p1.get("active_state", "")))])
	if diff.has("engaged_with_player_id"):
		var e0 := str(p0.get("engaged_with_player_id", ""))
		var e1 := str(p1.get("engaged_with_player_id", ""))
		if e1.is_empty():
			parts.append("Target: None.")
		else:
			parts.append("Target: %s." % _role_for_id(snap, e1))
	if diff.has("separation_tier"):
		parts.append("Coverage: %s → %s." % [str(p0.get("separation_tier", "")), str(p1.get("separation_tier", ""))])
	if diff.has("man_cover_target_id"):
		var t0 := _role_for_id(snap, str(p0.get("man_cover_target_id", "")))
		var t1 := _role_for_id(snap, str(p1.get("man_cover_target_id", "")))
		if t0.is_empty():
			t0 = "None"
		if t1.is_empty():
			t1 = "None"
		parts.append("Target: %s → %s." % [t0, t1])
	return " ".join(parts)


static func _target_role_label(snap: Dictionary, pd: Dictionary) -> String:
	for key in ["man_cover_target_id", "engaged_with_player_id"]:
		var tid := str(pd.get(key, ""))
		if tid.is_empty():
			continue
		var role := _role_for_id(snap, tid)
		if not role.is_empty():
			return role
	return "None"


static func _state_line(snap: Dictionary, pd: Dictionary, role: String) -> String:
	if pd.is_empty():
		return "%s — (off field)" % role
	var sep := ""
	if pd.has("separation_tier"):
		var tier := str(pd.get("separation_tier", ""))
		if not tier.is_empty():
			sep = " Coverage grade: %s." % tier
	return "%s at %s — %s, %s. Target: %s.%s" % [
		role,
		_tile_str(pd),
		_plain_intent(str(pd.get("intent_action", ""))),
		_plain_state(str(pd.get("active_state", ""))),
		_target_role_label(snap, pd),
		sep,
	]


static func _full_state_lines(snap: Dictionary, role_filter: Array) -> Array[String]:
	var lines: Array[String] = []
	var rmap := _role_map(snap)
	var roles: Array = rmap.keys()
	roles.sort()
	for role in roles:
		if not role_filter.is_empty() and role not in role_filter:
			continue
		lines.append(_state_line(snap, rmap[role] as Dictionary, str(role)))
	return lines


static func format_event_display(
	ev: Dictionary,
	changes_only: bool,
	role_filter: Dictionary,
	show_ball: bool,
	show_play_events: bool
) -> String:
	if not _event_visible(ev, role_filter, show_ball, show_play_events):
		return ""
	var out := str(ev.get("headline", ""))
	var lines: Array = ev.get("lines", []) as Array
	if str(ev.get("kind", "")) == "snap" and not role_filter.is_empty():
		lines = _filter_lines_for_focus(lines, role_filter)
	for line in lines:
		var s := str(line)
		if s.is_empty():
			continue
		if changes_only and not s.contains("→") and not s.contains("changed") and not s.contains("moved"):
			continue
		out += "\n  " + s
	return out


static func _event_visible(ev: Dictionary, role_filter: Dictionary, show_ball: bool, show_play_events: bool) -> bool:
	if bool(ev.get("ball_only", false)):
		return show_ball
	var focus := not role_filter.is_empty()
	var kind := str(ev.get("kind", ""))
	if focus and not show_play_events:
		if kind in ["pressure", "throw"]:
			return false
		if kind == "end" and not bool(ev.get("pause", false)):
			return false
	if not focus:
		return true
	if _roles_touch_filter(ev, role_filter):
		return true
	return false


static func _roles_touch_filter(ev: Dictionary, role_filter: Dictionary) -> bool:
	for r in ev.get("roles", []) as Array:
		if role_filter.has(str(r)):
			return true
	for r in ev.get("related_roles", []) as Array:
		if role_filter.has(str(r)):
			return true
	return false


static func _filter_lines_for_focus(lines: Array, role_filter: Dictionary) -> Array:
	var out: Array = []
	for line_v in lines:
		var s := str(line_v)
		if s.begins_with("Ball at snap"):
			out.append(s)
			continue
		for role in role_filter.keys():
			if s.begins_with(str(role) + " "):
				out.append(s)
				break
	return out


static func _ball_roles(from_role: String, to_role: String) -> Array[String]:
	var out: Array[String] = []
	if not from_role.is_empty():
		out.append(from_role)
	if not to_role.is_empty() and to_role not in out:
		out.append(to_role)
	return out


static func _id_role_map(snap: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for pd_v in snap.get("players", []) as Array:
		if typeof(pd_v) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = pd_v
		var pid := str(pd.get("player_id", ""))
		var role := str(pd.get("role", ""))
		if not pid.is_empty() and not role.is_empty():
			out[pid] = role
	return out


static func _carrier_role_label(snap: Dictionary) -> String:
	var cid := str(snap.get("ball_carrier_id", ""))
	return _role_for_id(snap, cid) if not cid.is_empty() else "unknown"


static func _role_for_id(snap: Dictionary, pid: String) -> String:
	for pd_v in snap.get("players", []) as Array:
		if typeof(pd_v) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = pd_v
		if str(pd.get("player_id", "")) == pid:
			return str(pd.get("role", ""))
	return ""


static func _player_dict(snap: Dictionary, pid: String) -> Dictionary:
	for pd_v in snap.get("players", []) as Array:
		if typeof(pd_v) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = pd_v
		if str(pd.get("player_id", "")) == pid:
			return pd
	return {}


static func _tile_str(pd: Dictionary) -> String:
	if pd.is_empty():
		return "(?, ?)"
	return "(%d, %d)" % [int(pd.get("global_col", 0)), int(pd.get("global_row", 0))]


static func _plain_intent(intent: String) -> String:
	match intent:
		"run_block":
			return "run blocking"
		"pass_block":
			return "pass blocking"
		"route":
			return "running a route"
		"carry":
			return "carrying the ball"
		"drop_back":
			return "dropping back"
		"pass_rush":
			return "pass rushing"
		"run_stop":
			return "run stopping"
		"cover_man":
			return "man coverage"
		"cover_zone":
			return "zone coverage"
		"pursue":
			return "pursuing"
		_:
			return intent.replace("_", " ") if not intent.is_empty() else "idle"


static func _plain_state(state: String) -> String:
	match state:
		"moving":
			return "moving"
		"blocking":
			return "blocking"
		"pursue":
			return "pursuing"
		_:
			return state.replace("_", " ") if not state.is_empty() else "idle"


static func _humanize_sim_message(code: String, msg: String) -> String:
	match code:
		"engage_block":
			return "Block — players engaged in the trenches."
		"pass_pressure_tick":
			return msg.replace("Pre-throw sample:", "Dropback —").replace("Parallel dropback sample:", "Dropback —")
		"sim_broken":
			return "Broken tackle — ball carrier kept going."
		"sim_pass_applied":
			return "Pass — ball delivered to the receiver."
		_:
			return msg


static func _humanize_resolver_line(line: String) -> String:
	var s := line
	s = s.replace("Pass protection score", "Protection")
	s = s.replace("pressure level", "under pressure level")
	return s
