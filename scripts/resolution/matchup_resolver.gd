extends RefCounted
class_name MatchupResolver


func pick_pass_rush_matchup(ctx: PlaySimContext, log: PlayEventLog) -> Dictionary:
	var dls := ctx.all_slots_role_prefix(ctx.defense_slots, "DL")
	var ols := ctx.all_slots_role_prefix(ctx.offense_slots, "OL")
	if dls.is_empty() or ols.is_empty():
		return {"dl": {}, "ol": {}, "margin": 0.0}
	var best_dl: Dictionary = {}
	var best_dl_rush := -1
	for s in dls:
		var pl: Dictionary = s.get("player", {}) as Dictionary
		var pr := ctx.stat_view_for(pl).pass_rush()
		if pr > best_dl_rush:
			best_dl_rush = pr
			best_dl = pl
	var worst_ol: Dictionary = {}
	var worst_ol_blk := 999
	for s in ols:
		var pl2: Dictionary = s.get("player", {}) as Dictionary
		var blk := ctx.stat_view_for(pl2).blocking()
		if blk < worst_ol_blk:
			worst_ol_blk = blk
			worst_ol = pl2
	var margin := float(ctx.stat_view_for(best_dl).pass_rush() - ctx.stat_view_for(worst_ol).blocking())
	log.add(
		"pass_ol_dl",
		"DL %s vs OL %s (pass rush edge %.1f)" % [
			ctx.format_player_slot(best_dl, ctx.role_for_player_id(str(best_dl.get("id", "")))),
			ctx.format_player_slot(worst_ol, ctx.role_for_player_id(str(worst_ol.get("id", "")))),
			margin,
		],
		{"primary_id": str(best_dl.get("id", "")), "secondary_id": str(worst_ol.get("id", "")), "pos": "DL"},
		{"margin": margin}
	)
	return {"dl": best_dl, "ol": worst_ol, "margin": margin}


func pick_run_lane_matchup(ctx: PlaySimContext, log: PlayEventLog) -> Dictionary:
	var dls := ctx.all_slots_role_prefix(ctx.defense_slots, "DL")
	var ols := ctx.all_slots_role_prefix(ctx.offense_slots, "OL")
	if dls.is_empty():
		return {"dl": {}, "ol_avg": 0.0, "dl_avg": 0.0}
	var dl_sum := 0.0
	var dl_n := 0
	for s in dls:
		var pl: Dictionary = s.get("player", {}) as Dictionary
		dl_sum += float(ctx.stat_view_for(pl).pass_rush() + ctx.stat_view_for(pl).block_shedding())
		dl_n += 2
	var ol_sum := 0.0
	var ol_n := 0
	for s in ols:
		var pl2: Dictionary = s.get("player", {}) as Dictionary
		ol_sum += float(ctx.stat_view_for(pl2).blocking() + ctx.stat_view_for(pl2).strength()) * 0.5
		ol_n += 1
	var ol_avg := ol_sum / float(max(1, ol_n))
	var dl_avg := dl_sum / float(max(1, dl_n))
	log.add(
		"run_ol_dl",
		"Run lane: OL strength %.1f vs DL penetration %.1f" % [ol_avg, dl_avg],
		{},
		{"ol_avg": ol_avg, "dl_avg": dl_avg}
	)
	return {"dl_avg": dl_avg, "ol_avg": ol_avg}


func pair_wr_cb(ctx: PlaySimContext) -> Array[Dictionary]:
	var wrs := []
	for s in ctx.offense_slots:
		var role := str(s.get("role", "")).to_upper()
		if role.begins_with("WR") or role.begins_with("TE"):
			wrs.append(s)
	wrs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("delta_col", 0)) < int(b.get("delta_col", 0))
	)
	var cbs := ctx.all_slots_role_prefix(ctx.defense_slots, "CB")
	cbs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("delta_col", 0)) < int(b.get("delta_col", 0))
	)
	var pairs: Array[Dictionary] = []
	for i in range(wrs.size()):
		var wr_slot: Dictionary = wrs[i]
		var wr_pl: Dictionary = wr_slot.get("player", {}) as Dictionary
		var wcol := int(wr_slot.get("delta_col", 0))
		var best_cb: Dictionary = {}
		var def_role := "CB"
		var best_d := 999
		if i < cbs.size():
			var cb_slot_i: Dictionary = cbs[i]
			best_cb = cb_slot_i.get("player", {}) as Dictionary
			def_role = str(cb_slot_i.get("role", "CB"))
		else:
			for s in cbs:
				var cb_pl: Dictionary = s.get("player", {}) as Dictionary
				var d := absi(int(s.get("delta_col", 0)) - wcol)
				if d < best_d:
					best_d = d
					best_cb = cb_pl
					def_role = str(s.get("role", "CB"))
		pairs.append({"wr": wr_pl, "cb": best_cb, "slot": wr_slot, "def_role": def_role})
	return pairs


func safety_player(ctx: PlaySimContext) -> Dictionary:
	var s := ctx.first_slot_role_prefix(ctx.defense_slots, "S")
	return s.get("player", {}) as Dictionary


func best_lb(ctx: PlaySimContext) -> Dictionary:
	var lbs := ctx.all_slots_role_prefix(ctx.defense_slots, "LB")
	if lbs.is_empty():
		return {}
	var best: Dictionary = {}
	var best_sc := -1
	for s in lbs:
		var pl: Dictionary = s.get("player", {}) as Dictionary
		var sc := ctx.stat_view_for(pl).tackling() + ctx.stat_view_for(pl).awareness()
		if sc > best_sc:
			best_sc = sc
			best = pl
	return best
