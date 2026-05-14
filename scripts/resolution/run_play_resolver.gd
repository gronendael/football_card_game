extends RefCounted
class_name RunPlayResolver

var _matchup := MatchupResolver.new()
var _tackle := TackleResolver.new()
var _turnover := TurnoverResolver.new()
var _calc := ScrimmageSimCalculators.new()


func resolve(ctx: PlaySimContext, play_row: Dictionary, selected_ball_carrier_id: String, log: PlayEventLog) -> Dictionary:
	var tmin := int(play_row.get("tile_delta_min", 0))
	var tmax := int(play_row.get("tile_delta_max", 10))
	var rb := ctx.rb_player_for_run(selected_ball_carrier_id)
	if rb.is_empty():
		log.add("run_abort", "No ball carrier", {}, {})
		return _fail_run(tmin, tmax, log)

	var lane_crease := _calc.run_lane_and_crease(ctx, log)
	var lane: Dictionary = lane_crease.get("lane", {}) as Dictionary
	var crease: float = float(lane_crease.get("crease", 0.0))
	var rv := ctx.stat_view_for(rb)
	var base := crease * 0.42 + float(rv.speed()) * 0.55 + float(rv.agility()) * 0.35 + float(rv.strength()) * 0.2
	base += float(ResolutionBalanceConstants.noise_medium(ctx.rng)) * 0.35
	var yards := int(round(base))
	yards = clampi(yards, tmin, tmax)

	var tackler := _pick_run_tackler(ctx)
	var yac_res := _tackle.resolve_yards_after_catch(ctx, rb, tackler, log)
	var extra := int(yac_res.get("yac", 0))
	var total := clampi(yards + extra, tmin, tmax)

	var hit_q := 1.0
	if not tackler.is_empty():
		hit_q = 1.0 + float(ctx.stat_view_for(tackler).tackling()) * 0.04 + float(ctx.stat_view_for(tackler).strength()) * 0.02
	else:
		hit_q = 0.55

	var fumble := false
	if not tackler.is_empty():
		fumble = _turnover.roll_fumble_after_contact(ctx, rb, tackler, hit_q, log)

	if fumble:
		return {
			"tile_delta": total,
			"score_delta": 0,
			"success": total > 0,
			"result_text": "Fumble on run",
			"incomplete_pass": false,
			"pressure_level": 0,
			"target_receiver_id": "",
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
		"result_text": "Run for %d" % total,
		"incomplete_pass": false,
		"pressure_level": 0,
		"target_receiver_id": "",
		"tackled_by_id": str(yac_res.get("tackled_by", str(tackler.get("id", "")))),
		"broken_tackles": int(yac_res.get("broken", 0)),
		"turnover_outcome": {"occurred": false, "calc_lines": []},
	}


func _pick_run_tackler(ctx: PlaySimContext) -> Dictionary:
	var lb := _matchup.best_lb(ctx)
	if not lb.is_empty() and ctx.rng.randf() < 0.55:
		return lb
	var dls := ctx.all_slots_role_prefix(ctx.defense_slots, "DL")
	if not dls.is_empty():
		var s: Dictionary = dls[ctx.rng.randi_range(0, dls.size() - 1)]
		return s.get("player", {}) as Dictionary
	return _matchup.safety_player(ctx)


func _fail_run(tmin: int, tmax: int, log: PlayEventLog) -> Dictionary:
	return {
		"tile_delta": clampi(0, tmin, tmax),
		"score_delta": 0,
		"success": false,
		"result_text": "Run — no RB",
		"incomplete_pass": false,
		"pressure_level": 0,
		"target_receiver_id": "",
		"tackled_by_id": "",
		"broken_tackles": 0,
		"turnover_outcome": {"occurred": false, "calc_lines": []},
	}
