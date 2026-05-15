extends RefCounted
class_name PassTargetSelector

const THROW_READ := "read"
const THROW_FORCED_PRIMARY := "forced_primary"
const THROW_UNWILLING := "unwilling"
const THROW_THROWAWAY := "throwaway"

var _calc := ScrimmageSimCalculators.new()
var _matchup := MatchupResolver.new()


## Returns route entry plus throw_type (read / forced_primary / unwilling / throwaway).
func pick_throw_decision(
	ctx: PlaySimContext,
	play_row: Dictionary,
	route_list: Array,
	pressure: int,
	log: PlayEventLog
) -> Dictionary:
	var prog: Array[String] = PlayAuthoring.progression_roles(play_row)
	if prog.is_empty():
		prog = PlayRouteTemplates.filtered_progression(PlayAuthoring.offense_roles(ctx))
	if prog.is_empty() or route_list.is_empty():
		return {}
	var qb: Dictionary = ctx.qb_player()
	if qb.is_empty():
		return {}
	var qv := ctx.stat_view_for(qb)
	var awareness: int = qv.awareness()
	var throw_power: int = qv.throw_power()
	var max_arm := ScrimmageSimCalculators.max_throw_distance_cheb(throw_power)
	var max_steps := _max_progression_steps(awareness, pressure, prog.size())
	var force_primary: float = clampf(0.4 - float(awareness) * 0.045 + float(pressure) * 0.14, 0.08, 0.88)

	for step_i in range(max_steps):
		var role: String = prog[step_i]
		var entry: Dictionary = _entry_for_role(route_list, role)
		if entry.is_empty():
			continue
		var wr: Dictionary = entry.get("receiver", {}) as Dictionary
		var cb: Dictionary = entry.get("defender", {}) as Dictionary
		var recv_role := str(entry.get("recv_role", role))
		var sep: float = _separation_for_entry(ctx, entry)
		var beat := _roll_coverage_beat(ctx, wr, cb, recv_role, sep)
		var decides := _roll_qb_decision(ctx, awareness, pressure, step_i)

		if step_i == 0 and not beat and ctx.rng.randf() < force_primary:
			return _pack_decision(entry, THROW_FORCED_PRIMARY, step_i, beat, decides, pressure, max_arm, log, ctx, qb, wr, recv_role, true)

		if beat and decides:
			return _pack_decision(entry, THROW_READ, step_i, beat, decides, pressure, max_arm, log, ctx, qb, wr, recv_role, false)

	return _resolve_no_clean_read(ctx, play_row, route_list, prog, awareness, pressure, max_arm, throw_power, log, qb)


func pick_target(ctx: PlaySimContext, play_row: Dictionary, route_list: Array, pressure: int, log: PlayEventLog) -> Dictionary:
	var d := pick_throw_decision(ctx, play_row, route_list, pressure, log)
	if d.is_empty():
		return {}
	var entry: Dictionary = d.get("entry", {}) as Dictionary
	if entry.is_empty():
		return {}
	return entry


func _resolve_no_clean_read(
	ctx: PlaySimContext,
	play_row: Dictionary,
	route_list: Array,
	prog: Array[String],
	awareness: int,
	pressure: int,
	max_arm: int,
	throw_power: int,
	log: PlayEventLog,
	qb: Dictionary
) -> Dictionary:
	var panic_target := float(awareness) + 2.0 - float(pressure) * 1.15
	var unwilling := float(ctx.rng.randi_range(1, 10)) <= panic_target
	if unwilling:
		var entry := _best_in_range_entry(route_list, prog, max_arm)
		if entry.is_empty():
			entry = _best_sep_entry(route_list, prog)
		if entry.is_empty():
			return _throwaway_decision(route_list, prog, log, ctx, qb, pressure)
		var wr: Dictionary = entry.get("receiver", {}) as Dictionary
		var recv_role := str(entry.get("recv_role", ""))
		log.add(
			"qb_forced_throw",
			"QB unwilling throw to %s (awareness %d, pressure %d, arm %d tiles)" % [
				ctx.format_player_slot(wr, recv_role),
				awareness,
				pressure,
				max_arm,
			],
			{"primary_id": str(qb.get("id", "")), "secondary_id": str(wr.get("id", ""))},
			{"throw_type": THROW_UNWILLING, "max_arm": max_arm},
		)
		return _pack_decision(entry, THROW_UNWILLING, -1, false, false, pressure, max_arm, log, ctx, qb, wr, recv_role, false)
	return _throwaway_decision(route_list, prog, log, ctx, qb, pressure)


func _throwaway_decision(route_list: Array, prog: Array[String], log: PlayEventLog, ctx: PlaySimContext, qb: Dictionary, pressure: int) -> Dictionary:
	var entry := _entry_for_role(route_list, prog[0] if not prog.is_empty() else "")
	if entry.is_empty() and not route_list.is_empty():
		entry = route_list[0] as Dictionary
	var wr: Dictionary = entry.get("receiver", {}) as Dictionary if not entry.is_empty() else {}
	var recv_role := str(entry.get("recv_role", "WR"))
	log.add(
		"throwaway",
		"QB throwaway (awareness read failed, pressure %d)" % pressure,
		{"primary_id": str(qb.get("id", ""))},
		{"throw_type": THROW_THROWAWAY, "pressure": pressure},
	)
	return _pack_decision(entry, THROW_THROWAWAY, -1, false, false, pressure, 0, log, ctx, qb, wr, recv_role, false)


func _pack_decision(
	entry: Dictionary,
	throw_type: String,
	step_i: int,
	beat: bool,
	decides: bool,
	pressure: int,
	max_arm: int,
	log: PlayEventLog,
	ctx: PlaySimContext,
	qb: Dictionary,
	wr: Dictionary,
	recv_role: String,
	forced_primary: bool
) -> Dictionary:
	if throw_type in [THROW_READ, THROW_FORCED_PRIMARY]:
		_log_pick(ctx, log, qb, wr, recv_role, step_i, forced_primary, beat, decides, pressure)
	var out := entry.duplicate(true)
	out["throw_type"] = throw_type
	out["max_throw_cheb"] = max_arm
	var dist := int(entry.get("dist_from_qb", -1))
	if dist >= 0 and dist > max_arm and throw_type == THROW_UNWILLING:
		out["out_of_range"] = true
	return out


func _best_in_range_entry(route_list: Array, prog: Array[String], max_arm: int) -> Dictionary:
	var best: Dictionary = {}
	var best_sep := -999.0
	for role in prog:
		var e: Dictionary = _entry_for_role(route_list, role)
		if e.is_empty():
			continue
		var dist := int(e.get("dist_from_qb", 0))
		if dist > max_arm:
			continue
		var sep := float(e.get("separation", 0.0))
		if sep > best_sep:
			best_sep = sep
			best = e
	return best


func _best_sep_entry(route_list: Array, prog: Array[String]) -> Dictionary:
	var best: Dictionary = {}
	var best_sep := -999.0
	for role in prog:
		var e: Dictionary = _entry_for_role(route_list, role)
		if e.is_empty():
			continue
		var sep := float(e.get("separation", 0.0))
		if sep > best_sep:
			best_sep = sep
			best = e
	if best.is_empty():
		for e in route_list:
			if typeof(e) != TYPE_DICTIONARY:
				continue
			var sep2 := float((e as Dictionary).get("separation", 0.0))
			if sep2 > best_sep:
				best_sep = sep2
				best = e as Dictionary
	return best


static func should_throw_early(ctx: PlaySimContext, play_row: Dictionary, pressure: int, tick_index: int, qb_drop_ticks: int) -> bool:
	if tick_index < 1:
		return false
	var qb: Dictionary = ctx.qb_player()
	if qb.is_empty():
		return false
	var aw: int = ctx.stat_view_for(qb).awareness()
	if pressure >= 3:
		return true
	if pressure >= 2 and tick_index >= maxi(1, qb_drop_ticks - 2):
		return true
	if pressure >= 1 and tick_index >= maxi(1, qb_drop_ticks - 1):
		return true
	if aw >= 8 and pressure >= 1 and tick_index >= 2:
		return true
	if tick_index >= qb_drop_ticks:
		return true
	return false


func _max_progression_steps(awareness: int, pressure: int, prog_len: int) -> int:
	var steps := prog_len
	if pressure >= 3:
		steps = 1
	elif pressure >= 2:
		steps = mini(2, prog_len)
	elif pressure >= 1:
		steps = mini(3, prog_len)
	if awareness <= 3:
		steps = mini(2, steps)
	return maxi(steps, 1)


func _roll_coverage_beat(ctx: PlaySimContext, wr: Dictionary, cb: Dictionary, recv_role: String, sep: float) -> bool:
	var wv := ctx.stat_view_for(wr)
	var off := float(wv.route_running()) * 0.35 + float(wv.speed()) * 0.25 + sep * 0.4
	var def := 5.0
	if not cb.is_empty():
		var cv := ctx.stat_view_for(cb)
		def = float(cv.coverage()) + float(cv.speed()) * 0.35 + float(cv.awareness()) * 0.2
	var roll := float(ctx.rng.randi_range(1, 10)) + off * 0.35
	return roll > def + float(ResolutionBalanceConstants.noise_small(ctx.rng)) * 0.2


func _roll_qb_decision(ctx: PlaySimContext, awareness: int, pressure: int, step_index: int) -> bool:
	var target := float(awareness) + 2.5 - float(pressure) * 1.1 - float(step_index) * 0.65
	return float(ctx.rng.randi_range(1, 10)) <= target


func _separation_for_entry(ctx: PlaySimContext, entry: Dictionary) -> float:
	if entry.has("separation"):
		return float(entry.get("separation", 0.0))
	var wr: Dictionary = entry.get("receiver", {}) as Dictionary
	var cb: Dictionary = entry.get("defender", {}) as Dictionary
	var recv_role := str(entry.get("recv_role", "WR"))
	if bool(entry.get("checkdown", false)):
		var lb := _matchup.best_lb(ctx)
		return _calc.separation_rb_checkdown(ctx, wr, lb)
	return _calc.separation_wr_vs_cb(ctx, wr, cb, recv_role)


func _entry_for_role(route_list: Array, role: String) -> Dictionary:
	for e in route_list:
		if typeof(e) != TYPE_DICTIONARY:
			continue
		if str((e as Dictionary).get("recv_role", "")) == role:
			return e as Dictionary
	return {}


func _log_pick(
	ctx: PlaySimContext,
	log: PlayEventLog,
	qb: Dictionary,
	wr: Dictionary,
	recv_role: String,
	step_i: int,
	forced_primary: bool,
	beat: bool,
	decides: bool,
	pressure: int
) -> void:
	log.add(
		"qb_target",
		"QB %s targeted %s (prog step %d, beat=%s, read=%s, forced=%s, pressure %d)" % [
			ctx.format_player_slot(qb, ctx.role_for_player_id(str(qb.get("id", "")))),
			ctx.format_player_slot(wr, recv_role),
			step_i,
			beat,
			decides,
			forced_primary,
			pressure,
		],
		{"primary_id": str(qb.get("id", "")), "secondary_id": str(wr.get("id", ""))},
		{"prog_step": step_i, "coverage_beat": beat, "qb_read": decides, "forced_primary": forced_primary},
	)
