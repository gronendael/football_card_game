extends RefCounted
class_name TackleResolver


func resolve_yards_after_catch(
	ctx: PlaySimContext,
	ball_carrier: Dictionary,
	defender: Dictionary,
	log: PlayEventLog
) -> Dictionary:
	if defender.is_empty():
		var yac0 := ctx.rng.randi_range(2, 8)
		log.add(
			"yac_open",
			"%s: extra YAC %d (open field)" % [
				ctx.format_player_slot(ball_carrier, ctx.role_for_player_id(str(ball_carrier.get("id", "")))),
				yac0,
			],
			{"primary_id": str(ball_carrier.get("id", ""))},
			{"yac": yac0}
		)
		return {"yac": yac0, "tackled_by": "", "broken": 0}
	var bv := ctx.stat_view_for(ball_carrier)
	var dv := ctx.stat_view_for(defender)
	var tackle_p := float(dv.tackling() + dv.strength()) * 0.35 + float(dv.awareness()) * 0.15
	var break_p := float(bv.agility() + bv.carrying()) * 0.35 + float(bv.strength()) * 0.2
	var margin := tackle_p - break_p + float(ResolutionBalanceConstants.noise_medium(ctx.rng)) * 0.4
	var broken := 0
	var yac := 0
	if margin < 0.8:
		broken = 1
		yac = ctx.rng.randi_range(3, 7)
		log.add(
			"broken_tackle",
			"%s broke tackle vs %s (+%d YAC)" % [
				ctx.format_player_slot(ball_carrier, ctx.role_for_player_id(str(ball_carrier.get("id", "")))),
				ctx.format_player_slot(defender, ctx.role_for_player_id(str(defender.get("id", "")))),
				yac,
			],
			{
				"primary_id": str(ball_carrier.get("id", "")),
				"secondary_id": str(defender.get("id", "")),
				"pos": str(ball_carrier.get("role", "WR")),
			},
			{"yac": yac}
		)
	else:
		yac = ctx.rng.randi_range(0, 4)
		log.add(
			"tackle",
			"%s tackled by %s after %d YAC" % [
				ctx.format_player_slot(ball_carrier, ctx.role_for_player_id(str(ball_carrier.get("id", "")))),
				ctx.format_player_slot(defender, ctx.role_for_player_id(str(defender.get("id", "")))),
				yac,
			],
			{
				"primary_id": str(defender.get("id", "")),
				"secondary_id": str(ball_carrier.get("id", "")),
				"pos": "DEF",
			},
			{"yac": yac}
		)
	return {"yac": yac, "tackled_by": str(defender.get("id", "")), "broken": broken}


func pick_pass_tackler(ctx: PlaySimContext, target_wr: Dictionary, matchups: MatchupResolver) -> Dictionary:
	var pairs := matchups.pair_wr_cb(ctx)
	for p in pairs:
		var wr: Dictionary = p.get("wr", {}) as Dictionary
		if str(wr.get("id", "")) == str(target_wr.get("id", "")):
			var cb: Dictionary = p.get("defender", {}) as Dictionary
			if not cb.is_empty():
				return cb
	var s_approx := matchups.safety_player(ctx)
	if not s_approx.is_empty():
		return s_approx
	return matchups.best_lb(ctx)
