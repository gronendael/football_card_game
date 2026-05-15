extends RefCounted
class_name PassSimResolver

var _matchup := MatchupResolver.new()
var _routes := RouteResolver.new()
var _tackle := TackleResolver.new()
var _turnover := TurnoverResolver.new()
var _calc := ScrimmageSimCalculators.new()
var _target_sel := PassTargetSelector.new()


func map_pressure(protection_score: float) -> int:
	return ScrimmageSimCalculators.map_pressure(protection_score)


func resolve(ctx: PlaySimContext, play_row: Dictionary, log: PlayEventLog) -> Dictionary:
	var pp := _calc.pass_rush_and_protection(ctx, log, true)
	return _resolve_after_pass_front(ctx, play_row, log, pp)


## Throw after tick sim dropback: use last sampled rush / protection / pressure (no second pass-front RNG).
func resolve_with_locked_pass_front(
	ctx: PlaySimContext,
	play_row: Dictionary,
	log: PlayEventLog,
	rush: Dictionary,
	pressure: int,
	protection: float,
	precomputed_routes: Array = []
) -> Dictionary:
	var pp := {"rush": rush, "pressure": pressure, "protection": protection}
	return _resolve_after_pass_front(ctx, play_row, log, pp, precomputed_routes)


func _resolve_after_pass_front(
	ctx: PlaySimContext,
	play_row: Dictionary,
	log: PlayEventLog,
	pp: Dictionary,
	precomputed_routes: Array = []
) -> Dictionary:
	var tmin := int(play_row.get("tile_delta_min", 0))
	var tmax := int(play_row.get("tile_delta_max", 10))
	var qb := ctx.qb_player()
	if qb.is_empty():
		log.add("pass_abort", "No QB assigned", {}, {})
		return _fail_pass_dict(tmin, tmax, log, "Pass — no QB")

	var rush: Dictionary = pp.get("rush", {}) as Dictionary
	var pressure := int(pp.get("pressure", 0))
	var prot: float = float(pp.get("protection", 18.0))
	log.add(
		"qb_pressure",
		"QB %s pressure level %d" % [ctx.format_player_slot(qb, ctx.role_for_player_id(str(qb.get("id", "")))), pressure],
		{"primary_id": str(qb.get("id", "")), "pos": "QB"},
		{"pressure": pressure, "protection": prot}
	)

	var route_list: Array[Dictionary] = []
	if not precomputed_routes.is_empty():
		for entry in precomputed_routes:
			if typeof(entry) == TYPE_DICTIONARY:
				route_list.append(entry as Dictionary)
	else:
		route_list = _routes.receiver_separations(ctx, _matchup, log)
	if route_list.is_empty():
		log.add("pass_abort", "No eligible receivers", {}, {})
		return _fail_pass_dict(tmin, tmax, log, "Pass — no receivers")

	var prog_order: Array[String] = PlayAuthoring.progression_roles(play_row)
	if prog_order.is_empty():
		prog_order = PlayRouteTemplates.filtered_progression(PlayAuthoring.offense_roles(ctx))
	route_list = _filter_route_list_to_progression(route_list, prog_order)
	if route_list.is_empty():
		log.add("pass_abort", "No receivers in progression", {}, {})
		return _fail_pass_dict(tmin, tmax, log, "Pass — no progression targets")

	var decision: Dictionary = _target_sel.pick_throw_decision(ctx, play_row, route_list, pressure, log)
	if decision.is_empty():
		log.add("pass_abort", "No throw decision (no receivers)", {}, {})
		return _fail_pass_dict(tmin, tmax, log, "Pass — no receiver")
	var throw_type := str(decision.get("throw_type", PassTargetSelector.THROW_READ))
	if throw_type == PassTargetSelector.THROW_THROWAWAY:
		log.add("incomplete", "Throwaway — incomplete", {}, {})
		return {
			"tile_delta": 0,
			"score_delta": 0,
			"success": false,
			"result_text": "Throwaway — incomplete",
			"incomplete_pass": true,
			"pressure_level": pressure,
			"target_receiver_id": "",
			"tackled_by_id": "",
			"broken_tackles": 0,
			"turnover_outcome": {"occurred": false, "calc_lines": []},
			"throw_type": throw_type,
		}
	var target: Dictionary = decision.get("receiver", {}) as Dictionary
	if target.is_empty():
		log.add("pass_abort", "No throw target", {}, {})
		return _fail_pass_dict(tmin, tmax, log, "Pass — no target")
	var sep: float = float(decision.get("separation", 0.0))
	var cover_cb: Dictionary = decision.get("defender", {}) as Dictionary
	var recv_role := str(decision.get("recv_role", "WR"))

	var qv := ctx.stat_view_for(qb)
	var throw_acc: int = qv.throw_accuracy()
	var throw_pwr: int = qv.throw_power()
	var max_arm: int = int(decision.get("max_throw_cheb", ScrimmageSimCalculators.max_throw_distance_cheb(throw_pwr)))

	var acc_eff := float(throw_acc) * (1.0 - 0.18 * float(pressure))
	var throw_q := acc_eff + float(throw_pwr) * 0.35 + float(ResolutionBalanceConstants.noise_medium(ctx.rng)) * 0.25

	var safety := _matchup.safety_player(ctx)
	if throw_type != PassTargetSelector.THROW_THROWAWAY and _turnover.roll_interception(ctx, qb, target, cover_cb, sep, pressure, safety, log):
		return {
			"tile_delta": 0,
			"score_delta": 0,
			"success": false,
			"result_text": "Interception",
			"incomplete_pass": false,
			"pressure_level": pressure,
			"target_receiver_id": str(target.get("id", "")),
			"tackled_by_id": str(cover_cb.get("id", "")),
			"broken_tackles": 0,
			"turnover_outcome": {
				"occurred": true,
				"ended_by": "interception",
				"start_zone": -1,
				"text": "Interception.",
				"calc_lines": [],
			},
		}

	var tv := ctx.stat_view_for(target)
	var cv := ctx.stat_view_for(cover_cb) if not cover_cb.is_empty() else PlayerStatView.from_dict({})
	var complete_pct := 32.0 + throw_q * 3.2 + sep * 9.0 - float(pressure) * 7.0 - float(cv.coverage()) * 1.4
	match throw_type:
		PassTargetSelector.THROW_UNWILLING:
			complete_pct -= 22.0
			complete_pct += float(throw_acc) * 2.8
		PassTargetSelector.THROW_FORCED_PRIMARY:
			complete_pct -= 10.0
			complete_pct += float(throw_acc) * 1.4
	complete_pct = clampf(complete_pct, 4.0, 93.0)
	var comp_roll := ctx.rng.randf() * 100.0
	if comp_roll >= complete_pct:
		log.add("incomplete", "Pass incomplete (roll %.1f vs %.1f%%)" % [comp_roll, complete_pct], {}, {})
		return {
			"tile_delta": 0,
			"score_delta": 0,
			"success": false,
			"result_text": "Incomplete pass",
			"incomplete_pass": true,
			"pressure_level": pressure,
			"target_receiver_id": str(target.get("id", "")),
			"tackled_by_id": "",
			"broken_tackles": 0,
			"turnover_outcome": {"occurred": false, "calc_lines": []},
		}

	log.add("completion", "Completion (roll %.1f vs %.1f%%)" % [comp_roll, complete_pct], {}, {})

	var air := int(round(2.0 + sep * 2.2 + float(tv.speed()) * 0.25 + throw_q * 0.35))
	var dist_qb := int(decision.get("dist_from_qb", -1))
	if dist_qb >= 0:
		air = mini(air, dist_qb + 1)
		air = mini(air, max_arm)
	air = clampi(air, tmin, tmax)

	var tackler := _tackle.pick_pass_tackler(ctx, target, _matchup)
	var yac_res := _tackle.resolve_yards_after_catch(ctx, target, tackler, log)
	var yac: int = int(yac_res.get("yac", 0))
	var total := clampi(air + yac, tmin, tmax)

	var rush_margin: float = float(rush.get("margin", 0.0))
	var hit_q := rush_margin * 0.15 + float(pressure) * 0.35
	var fumble := false
	if tackler and not (str(tackler.get("id", "")).is_empty()):
		fumble = _turnover.roll_fumble_after_contact(ctx, target, tackler, hit_q, log)
	if fumble:
		return {
			"tile_delta": total,
			"score_delta": 0,
			"success": total > 0,
			"result_text": "Fumble after catch",
			"incomplete_pass": false,
			"pressure_level": pressure,
			"target_receiver_id": str(target.get("id", "")),
			"tackled_by_id": str(tackler.get("id", "")),
			"broken_tackles": int(yac_res.get("broken", 0)),
			"turnover_outcome": {
				"occurred": true,
				"ended_by": "fumble_recovery",
				"start_zone": -1,
				"text": "Fumble lost.",
				"calc_lines": [],
			},
		}

	return {
		"tile_delta": total,
		"score_delta": 0,
		"success": total > 0,
		"result_text": "Pass complete for %d" % total,
		"incomplete_pass": false,
		"pressure_level": pressure,
		"target_receiver_id": str(target.get("id", "")),
		"tackled_by_id": str(yac_res.get("tackled_by", "")),
		"broken_tackles": int(yac_res.get("broken", 0)),
		"turnover_outcome": {"occurred": false, "calc_lines": []},
		"throw_type": throw_type,
	}


func _fail_pass_dict(_tmin: int, _tmax: int, log: PlayEventLog, result_label: String) -> Dictionary:
	return {
		"tile_delta": 0,
		"score_delta": 0,
		"success": false,
		"result_text": result_label,
		"incomplete_pass": true,
		"pressure_level": 0,
		"target_receiver_id": "",
		"tackled_by_id": "",
		"broken_tackles": 0,
		"turnover_outcome": {"occurred": false, "calc_lines": []},
	}


func _filter_route_list_to_progression(route_list: Array[Dictionary], prog_order: Array[String]) -> Array[Dictionary]:
	if prog_order.is_empty():
		return route_list
	var out: Array[Dictionary] = []
	for e in route_list:
		var role := str(e.get("recv_role", ""))
		if role in prog_order:
			out.append(e)
	return out
