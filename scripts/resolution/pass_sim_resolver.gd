extends RefCounted
class_name PassSimResolver

var _matchup := MatchupResolver.new()
var _blocking := BlockingResolver.new()
var _routes := RouteResolver.new()
var _tackle := TackleResolver.new()
var _turnover := TurnoverResolver.new()


func map_pressure(protection_score: float) -> int:
	if protection_score >= 22.0:
		return 0
	if protection_score >= 18.0:
		return 1
	if protection_score >= 14.0:
		return 2
	return 3


func resolve(ctx: PlaySimContext, play_row: Dictionary, log: PlayEventLog) -> Dictionary:
	var tmin := int(play_row.get("tile_delta_min", 0))
	var tmax := int(play_row.get("tile_delta_max", 10))
	var qb := ctx.qb_player()
	if qb.is_empty():
		log.add("pass_abort", "No QB assigned", {}, {})
		return _fail_pass_dict(tmin, tmax, log, "Pass — no QB")

	var rush := _matchup.pick_pass_rush_matchup(ctx, log)
	var prot := _blocking.pass_protection_score(ctx, rush, log)
	var pressure := map_pressure(prot)
	log.add(
		"qb_pressure",
		"QB %s pressure level %d" % [ctx.format_player_slot(qb, ctx.role_for_player_id(str(qb.get("id", "")))), pressure],
		{"primary_id": str(qb.get("id", "")), "pos": "QB"},
		{"pressure": pressure}
	)

	var route_list := _routes.receiver_separations(ctx, _matchup, log)
	if route_list.is_empty():
		log.add("pass_abort", "No eligible receivers", {}, {})
		return _fail_pass_dict(tmin, tmax, log, "Pass — no receivers")

	route_list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("separation", 0.0)) > float(b.get("separation", 0.0))
	)

	var qv := ctx.stat_view_for(qb)
	var misread := ctx.rng.randi_range(1, 10) > qv.awareness() + 3 - pressure
	var pick_idx := 1 if misread and route_list.size() > 1 else 0
	var chosen: Dictionary = route_list[mini(pick_idx, route_list.size() - 1)]
	var target: Dictionary = chosen.get("receiver", {}) as Dictionary
	var sep: float = float(chosen.get("separation", 0.0))
	var cover_cb: Dictionary = chosen.get("defender", {}) as Dictionary

	var recv_role := str(chosen.get("recv_role", "WR"))
	log.add(
		"qb_target",
		"QB %s targeted %s" % [
			ctx.format_player_slot(qb, ctx.role_for_player_id(str(qb.get("id", "")))),
			ctx.format_player_slot(target, recv_role),
		],
		{"primary_id": str(qb.get("id", "")), "secondary_id": str(target.get("id", "")), "pos": "QB"},
		{"misread": misread}
	)

	var acc_eff := float(qv.throw_accuracy()) * (1.0 - 0.18 * float(pressure))
	var throw_q := acc_eff + float(qv.throw_power()) * 0.35 + float(ResolutionBalanceConstants.noise_medium(ctx.rng)) * 0.25

	var safety := _matchup.safety_player(ctx)
	if _turnover.roll_interception(ctx, qb, target, cover_cb, sep, pressure, safety, log):
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
	complete_pct = clampf(complete_pct, 6.0, 93.0)
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
