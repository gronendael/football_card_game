extends RefCounted
class_name PlaySimContext

var rng: RandomNumberGenerator
var possession_team: String = "home"
var offense_play_id: String = ""
var defense_play_id: String = ""
var offense_play_row: Dictionary = {}
var current_zone: int = 4
## Maps franchise id (e.g. "bees") -> display name for calc logs.
var franchise_labels: Dictionary = {}
## Each entry: { "role": String, "delta_col": int, "player": Dictionary }
var offense_slots: Array[Dictionary] = []
var defense_slots: Array[Dictionary] = []


static func build(
	p_rng: RandomNumberGenerator,
	poss_team: String,
	off_pid: String,
	def_pid: String,
	off_row: Dictionary,
	zone: int,
	offense_players: Array[Dictionary],
	defense_players: Array[Dictionary],
	off_formation: Dictionary,
	def_formation: Dictionary,
	franchise_display: Dictionary
) -> PlaySimContext:
	var ctx := PlaySimContext.new()
	ctx.rng = p_rng
	ctx.possession_team = poss_team
	ctx.offense_play_id = off_pid
	ctx.defense_play_id = def_pid
	ctx.offense_play_row = off_row
	ctx.current_zone = zone
	ctx.franchise_labels = franchise_display.duplicate(true)
	ctx.offense_slots = _assign_slots(offense_players, off_formation)
	ctx.defense_slots = _assign_slots(defense_players, def_formation)
	return ctx


static func _assign_slots(team: Array[Dictionary], formation: Dictionary) -> Array[Dictionary]:
	var pos_arr: Variant = formation.get("positions", [])
	if typeof(pos_arr) != TYPE_ARRAY:
		return []
	var slots: Array[Dictionary] = []
	for p in pos_arr as Array:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = p
		slots.append({
			"role": str(pd.get("role", "")),
			"delta_col": int(pd.get("delta_col", 0)),
			"delta_row": int(pd.get("delta_row", 0)),
		})
	slots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _slot_priority(a["role"]) < _slot_priority(b["role"])
	)
	var used_ids: Dictionary = {}
	var out: Array[Dictionary] = []
	for slot in slots:
		var role: String = str(slot["role"])
		var pick := _pick_player_for_role(team, role, used_ids)
		if pick.is_empty():
			continue
		var pid := str(pick.get("id", ""))
		if not pid.is_empty() and not used_ids.has(pid):
			used_ids[pid] = true
		var row := slot.duplicate(true)
		row["player"] = pick
		out.append(row)
	return out


static func _slot_priority(role: String) -> int:
	var r := role.to_upper()
	if r.begins_with("QB"):
		return 0
	if r.begins_with("OL"):
		return 1
	if r.begins_with("DL"):
		return 0
	if r.begins_with("LB"):
		return 2
	if r.begins_with("RB"):
		return 3
	if r.begins_with("TE"):
		return 4
	if r.begins_with("WR"):
		return 5
	if r.begins_with("CB"):
		return 6
	if r.begins_with("S"):
		return 7
	return 10


static func _role_fit_score(role: String, player: Dictionary) -> int:
	var r := role.to_upper()
	var p := PlayerStatView.from_dict(player)
	if r.begins_with("QB"):
		return p.throw_accuracy() * 3 + p.awareness() * 2 + p.throw_power()
	if r.begins_with("RB"):
		return p.carrying() * 2 + p.speed() * 2 + p.agility() + p.strength()
	if r.begins_with("WR") or r.begins_with("TE"):
		return p.route_running() * 2 + p.catching() * 2 + p.speed()
	if r.begins_with("OL"):
		return p.blocking() * 4 + p.strength()
	if r.begins_with("DL"):
		return p.pass_rush() * 2 + p.block_shedding() * 2 + p.strength()
	if r.begins_with("LB"):
		return p.tackling() * 2 + p.awareness() * 2 + p.speed()
	if r.begins_with("CB"):
		return p.coverage() * 2 + p.speed() * 2 + p.awareness()
	if r.begins_with("S"):
		return p.awareness() * 3 + p.coverage() * 2 + p.speed()
	return p.awareness() + p.speed()


static func _pick_player_for_role(team: Array[Dictionary], role: String, used_ids: Dictionary) -> Dictionary:
	if team.is_empty():
		return {}
	var best_unused: Dictionary = {}
	var best_unused_score := -999999
	var best_any: Dictionary = {}
	var best_any_score := -999999
	for pl in team:
		var pid := str(pl.get("id", ""))
		var sc := _role_fit_score(role, pl)
		if sc > best_any_score:
			best_any_score = sc
			best_any = pl
		if pid.is_empty() or used_ids.has(pid):
			continue
		if sc > best_unused_score:
			best_unused_score = sc
			best_unused = pl
	if not best_unused.is_empty():
		return best_unused
	return best_any


func first_slot_role_prefix(slots: Array[Dictionary], prefix: String) -> Dictionary:
	for s in slots:
		if str(s.get("role", "")).to_upper().begins_with(prefix.to_upper()):
			return s
	return {}


func all_slots_role_prefix(slots: Array[Dictionary], prefix: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in slots:
		if str(s.get("role", "")).to_upper().begins_with(prefix.to_upper()):
			out.append(s)
	return out


func qb_player() -> Dictionary:
	var s := first_slot_role_prefix(offense_slots, "QB")
	return s.get("player", {}) as Dictionary


func rb_player_for_run(selected_ball_carrier_id: String) -> Dictionary:
	if not selected_ball_carrier_id.is_empty():
		var found := _find_player_by_id(offense_slots, selected_ball_carrier_id)
		if not found.is_empty():
			return found
	var s := first_slot_role_prefix(offense_slots, "RB")
	return s.get("player", {}) as Dictionary


func _find_player_by_id(slots: Array[Dictionary], pid: String) -> Dictionary:
	for s in slots:
		var pl: Dictionary = s.get("player", {}) as Dictionary
		if str(pl.get("id", "")) == pid:
			return pl
	return {}


func stat_view_for(player: Dictionary) -> PlayerStatView:
	return PlayerStatView.from_dict(player)


func team_label_for(franchise_id: String) -> String:
	var s := str(franchise_labels.get(franchise_id, "")).strip_edges()
	return s if not s.is_empty() else franchise_id


func strip_side_prefix_from_name(raw: String, _franchise_id: String) -> String:
	return raw.strip_edges()


func role_for_player_id(pid: String) -> String:
	if pid.is_empty():
		return "?"
	for s in offense_slots:
		var pl: Dictionary = s.get("player", {}) as Dictionary
		if str(pl.get("id", "")) == pid:
			return str(s.get("role", "?"))
	for s2 in defense_slots:
		var pl2: Dictionary = s2.get("player", {}) as Dictionary
		if str(pl2.get("id", "")) == pid:
			return str(s2.get("role", "?"))
	return "?"


func format_player_slot(player: Dictionary, role: String) -> String:
	if player.is_empty():
		return "(none)"
	var tk := str(player.get("team", ""))
	var tl := team_label_for(tk)
	var r_st := role.strip_edges()
	var r_show := r_st if not r_st.is_empty() else "?"
	var nm := strip_side_prefix_from_name(PlayerStatView.display_name_from_dict(player), tk)
	return "%s %s · %s" % [tl, r_show, nm]
