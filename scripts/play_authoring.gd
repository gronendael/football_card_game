extends RefCounted
class_name PlayAuthoring

## Read optional play JSON from Play Creator ([data/plays.json](data/plays.json)).


static func route_waypoints_for_role(play_row: Dictionary, role: String) -> Array[Vector2i]:
	var routes: Dictionary = play_row.get("routes", {}) as Dictionary
	if not routes.has(role):
		return []
	var block: Dictionary = routes[role] as Dictionary
	var arr: Variant = block.get("waypoints", [])
	if typeof(arr) != TYPE_ARRAY:
		return []
	var out: Array[Vector2i] = []
	for s in arr as Array:
		if typeof(s) != TYPE_ARRAY or (s as Array).size() < 2:
			continue
		var a := s as Array
		out.append(Vector2i(int(a[0]), int(a[1])))
	return out


static func start_action_for_role(play_row: Dictionary, role: String) -> String:
	var ra: Dictionary = play_row.get("role_assignments", {}) as Dictionary
	if not ra.has(role):
		return ""
	var block: Dictionary = ra[role] as Dictionary
	return str(block.get("start_action", ""))


static func ball_carrier_role(play_row: Dictionary) -> String:
	return str(play_row.get("ball_carrier_role", ""))


static func progression_roles(play_row: Dictionary) -> Array[String]:
	var qb: Dictionary = play_row.get("qb_script", {}) as Dictionary
	var from_qb: Variant = qb.get("progression", [])
	if typeof(from_qb) == TYPE_ARRAY and not (from_qb as Array).is_empty():
		var out: Array[String] = []
		for r in from_qb as Array:
			var rs := str(r)
			if not rs.is_empty():
				out.append(rs)
		return out
	var prog: Dictionary = play_row.get("receiver_progression", {}) as Dictionary
	var out2: Array[String] = []
	for slot in ["primary", "secondary", "tertiary"]:
		var rs2 := str(prog.get(slot, ""))
		if not rs2.is_empty():
			out2.append(rs2)
	return out2


static func qb_dropback_ticks(play_row: Dictionary, ctx: PlaySimContext) -> int:
	var qb: Dictionary = play_row.get("qb_script", {}) as Dictionary
	if not qb.is_empty():
		var mode := str(qb.get("mode", ""))
		if mode == "quick_throw":
			return 1
		if qb.has("dropback_ticks"):
			return clampi(int(qb.get("dropback_ticks")), 1, 7)
	var pl := ctx.qb_player()
	if pl.is_empty():
		return 3
	var aw := ctx.stat_view_for(pl).awareness()
	return clampi(2 + aw / 3, 2, 6)


static func player_for_role(ctx: PlaySimContext, role: String) -> Dictionary:
	for s in ctx.offense_slots:
		if str(s.get("role", "")) == role:
			return s.get("player", {}) as Dictionary
	return {}


static func offense_roles(ctx: PlaySimContext) -> Array[String]:
	var out: Array[String] = []
	for s in ctx.offense_slots:
		var r := str(s.get("role", ""))
		if not r.is_empty():
			out.append(r)
	return out
