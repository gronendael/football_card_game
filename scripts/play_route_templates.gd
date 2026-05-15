extends RefCounted
class_name PlayRouteTemplates

const DEFAULT_PROGRESSION: Array[String] = ["WR1", "WR2", "TE1", "RB1", "RB2", "TE2", "WR3"]

static func enrich_play_row(play_row: Dictionary, formation: Dictionary) -> Dictionary:
	var out: Dictionary = play_row.duplicate(true)
	var ptype := str(out.get("play_type", ""))
	if ptype != "run" and ptype != "pass":
		return out
	var roles := _formation_roles(formation)
	if roles.is_empty():
		return out
	if not out.has("role_assignments"):
		out["role_assignments"] = _default_role_assignments(ptype, roles)
	if not out.has("routes"):
		out["routes"] = _default_routes(ptype, roles)
	if ptype == "run" and not out.has("ball_carrier_role"):
		out["ball_carrier_role"] = _pick_carrier_role(roles)
	if ptype == "pass":
		if not out.has("receiver_progression"):
			out["receiver_progression"] = _default_progression_dict(roles)
		if not out.has("qb_script"):
			out["qb_script"] = _default_qb_script(roles)
	return out


static func _formation_roles(formation: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for p in formation.get("positions", []) as Array:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var r := str((p as Dictionary).get("role", ""))
		if not r.is_empty():
			out.append(r)
	return out


static func _pick_carrier_role(roles: Array[String]) -> String:
	for r in roles:
		if r.to_upper().begins_with("RB"):
			return r
	return ""


static func _default_progression_dict(roles: Array[String]) -> Dictionary:
	var order := filtered_progression(roles)
	var d: Dictionary = {}
	if order.size() > 0:
		d["primary"] = order[0]
	if order.size() > 1:
		d["secondary"] = order[1]
	if order.size() > 2:
		d["tertiary"] = order[2]
	return d


static func _default_qb_script(roles: Array[String]) -> Dictionary:
	return {
		"mode": "dropback_progression",
		"dropback_ticks": 5,
		"progression": filtered_progression(roles),
	}


static func filtered_progression(roles: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for want in DEFAULT_PROGRESSION:
		if want in roles:
			out.append(want)
	for r in roles:
		var ru := r.to_upper()
		if (ru.begins_with("WR") or ru.begins_with("TE") or ru.begins_with("RB")) and r not in out:
			out.append(r)
	return out


static func _default_role_assignments(ptype: String, roles: Array[String]) -> Dictionary:
	var ra: Dictionary = {}
	var carrier := _pick_carrier_role(roles) if ptype == "run" else ""
	var rb_i := 0
	var wr_i := 0
	for role in roles:
		var ru := role.to_upper()
		if ru.begins_with("OL") or ru == "QB":
			ra[role] = {"start_action": "pass_block" if ptype == "pass" else "run_block"}
		elif ru.begins_with("RB"):
			rb_i += 1
			if ptype == "run":
				if role == carrier:
					ra[role] = {"start_action": "carry"}
				elif rb_i == 1:
					ra[role] = {"start_action": "run_block"}
				else:
					ra[role] = {"start_action": "run_block"}
			else:
				ra[role] = {"start_action": "route"}
		elif ru.begins_with("WR") or ru.begins_with("TE"):
			wr_i += 1
			if ptype == "run":
				ra[role] = {"start_action": "run_block" if wr_i % 2 == 0 else "route"}
			else:
				ra[role] = {"start_action": "route"}
	return ra


static func _default_routes(ptype: String, roles: Array[String]) -> Dictionary:
	var routes: Dictionary = {}
	var carrier := _pick_carrier_role(roles) if ptype == "run" else ""
	var rb_i := 0
	var wr_i := 0
	for role in roles:
		var ru := role.to_upper()
		var wps: Array = []
		if ru.begins_with("RB"):
			rb_i += 1
			if ptype == "run" and role == carrier:
				wps = _wps_run_carrier()
			elif ptype == "run":
				wps = _wps_run_lead_block()
			elif ptype == "pass":
				wps = _wps_pass_flat(role)
		elif ru.begins_with("WR") or ru.begins_with("TE"):
			wr_i += 1
			if ptype == "run":
				var ra: Dictionary = _default_role_assignments(ptype, roles)
				var act := str((ra.get(role, {}) as Dictionary).get("start_action", ""))
				if act == "route":
					wps = _wps_run_clear_out(role)
			else:
				wps = _wps_pass_receiver(wr_i, role)
		if not wps.is_empty():
			routes[role] = {"waypoints": wps}
	return routes


static func _wps_run_carrier() -> Array:
	return _chain([[0, -1], [0, -1], [0, -1], [-1, -1], [0, -1], [0, -1]])


static func _wps_run_lead_block() -> Array:
	return _chain([[0, -1], [1, 0], [0, -1]])


static func _wps_run_clear_out(_role: String) -> Array:
	var lat := -1 if str(_role).contains("1") or str(_role).ends_with("3") else 1
	return _chain([[0, -1], [lat, -1], [0, -1]])


static func _wps_pass_flat(_role: String) -> Array:
	var lat := -1 if int(_role.get_slice("RB", 1)) % 2 == 1 else 1
	return _chain([[lat, 0], [lat, -1], [0, -1], [0, -1]])


static func _wps_pass_receiver(idx: int, role: String) -> Array:
	var ru := role.to_upper()
	if ru.begins_with("TE"):
		return _chain([[0, -1], [0, -1], [1, -1], [0, -1]])
	match idx % 3:
		0:
			return _chain([[0, -1], [0, -2], [0, -1], [1, -1], [0, -1]])
		1:
			return _chain([[0, -1], [1, 0], [0, -1], [0, -2]])
		_:
			return _chain([[1, -1], [0, -1], [0, -1], [-1, -1]])


static func _chain(steps: Array) -> Array:
	var out: Array = []
	for s in steps:
		if typeof(s) == TYPE_ARRAY and (s as Array).size() >= 2:
			out.append([int(s[0]), int(s[1])])
	return out


static func intent_blocks_route(intent: String) -> bool:
	return intent == "run_block" or intent == "pass_block"
