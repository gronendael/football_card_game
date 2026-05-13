extends RefCounted
class_name RouteResolver


func receiver_separations(ctx: PlaySimContext, matchups: MatchupResolver, log: PlayEventLog) -> Array[Dictionary]:
	var pairs := matchups.pair_wr_cb(ctx)
	var out: Array[Dictionary] = []
	for p in pairs:
		var wr: Dictionary = p.get("wr", {}) as Dictionary
		var cb: Dictionary = p.get("cb", {}) as Dictionary
		var wr_slot: Dictionary = p.get("slot", {}) as Dictionary
		var def_role: String = str(p.get("def_role", "CB"))
		if wr.is_empty():
			continue
		var recv_role := str(wr_slot.get("role", "WR"))
		var wv := ctx.stat_view_for(wr)
		var sep: float
		if cb.is_empty():
			sep = 2.0 + float(wv.route_running()) * 0.15
		else:
			var cv := ctx.stat_view_for(cb)
			sep = float(wv.route_running()) + float(wv.speed()) * 0.5 + float(wv.awareness()) * 0.3
			sep -= float(cv.coverage()) + float(cv.speed()) * 0.5 + float(cv.awareness()) * 0.2
		sep += float(ResolutionBalanceConstants.noise_small(ctx.rng)) * 0.15
		var cb_disp := ctx.format_player_slot(cb, def_role) if not cb.is_empty() else "coverage"
		log.add(
			"route_sep",
			"%s separation %.1f vs %s" % [ctx.format_player_slot(wr, recv_role), sep, cb_disp],
			{"primary_id": str(wr.get("id", "")), "secondary_id": str(cb.get("id", "")), "pos": "WR"},
			{"separation": sep}
		)
		out.append({"receiver": wr, "defender": cb, "separation": sep, "recv_role": recv_role})
	var rb := ctx.first_slot_role_prefix(ctx.offense_slots, "RB")
	var rb_pl: Dictionary = rb.get("player", {}) as Dictionary
	if not rb_pl.is_empty():
		var lb := matchups.best_lb(ctx)
		var rv := ctx.stat_view_for(rb_pl)
		var sep2 := 1.0
		if not lb.is_empty():
			sep2 = float(rv.speed()) * 0.25 + float(rv.route_running()) * 0.2 - float(ctx.stat_view_for(lb).tackling()) * 0.15
		else:
			sep2 = float(rv.speed()) * 0.25 + float(rv.route_running()) * 0.2 + 0.5
		sep2 += float(ctx.rng.randf_range(-0.4, 0.4))
		log.add(
			"route_checkdown",
			"%s vs %s checkdown separation %.1f" % [
				ctx.format_player_slot(rb_pl, ctx.role_for_player_id(str(rb_pl.get("id", "")))),
				ctx.format_player_slot(lb, ctx.role_for_player_id(str(lb.get("id", "")))),
				sep2,
			],
			{"primary_id": str(rb_pl.get("id", "")), "secondary_id": str(lb.get("id", ""))},
			{"separation": sep2}
		)
		out.append({"receiver": rb_pl, "defender": lb, "separation": sep2, "checkdown": true, "recv_role": "RB"})
	return out
