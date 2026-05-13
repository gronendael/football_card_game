extends RefCounted
class_name BlockingResolver


func pass_protection_score(ctx: PlaySimContext, matchup: Dictionary, log: PlayEventLog) -> float:
	var ols := ctx.all_slots_role_prefix(ctx.offense_slots, "OL")
	if ols.is_empty():
		return 20.0
	var sum := 0.0
	for s in ols:
		var pl: Dictionary = s.get("player", {}) as Dictionary
		sum += float(ctx.stat_view_for(pl).blocking() + ctx.stat_view_for(pl).strength()) * 0.35
	var prot := sum / float(ols.size())
	var qb := ctx.qb_player()
	if not qb.is_empty():
		prot += float(ctx.stat_view_for(qb).awareness()) * 0.15
	var rush_edge: float = float(matchup.get("margin", 0.0))
	var pressure_adj := rush_edge * 0.9
	var score := prot - pressure_adj + float(ResolutionBalanceConstants.noise_small(ctx.rng)) * 0.4
	log.add(
		"pass_protection",
		"Pass protection score %.1f (rush edge %.1f)" % [score, rush_edge],
		{},
		{"protection": score, "rush_edge": rush_edge}
	)
	return score


func run_crease_score(ctx: PlaySimContext, lane_info: Dictionary, log: PlayEventLog) -> float:
	var ol_avg: float = float(lane_info.get("ol_avg", 18.0))
	var dl_avg: float = float(lane_info.get("dl_avg", 16.0))
	var lbs := ctx.all_slots_role_prefix(ctx.defense_slots, "LB")
	var lb_pen := 0.0
	for s in lbs:
		var pl: Dictionary = s.get("player", {}) as Dictionary
		lb_pen += float(ctx.stat_view_for(pl).awareness()) * 0.35
	if not lbs.is_empty():
		lb_pen /= float(lbs.size())
	var crease := ol_avg - dl_avg * 0.85 - lb_pen * 0.25 + float(ResolutionBalanceConstants.noise_medium(ctx.rng)) * 0.25
	log.add("run_crease", "Run crease composite %.1f" % crease, {}, {"crease": crease})
	return crease
