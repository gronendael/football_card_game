extends RefCounted
class_name ScrimmageSimCalculators

var _matchup := MatchupResolver.new()
var _blocking := BlockingResolver.new()


static func map_pressure(protection_score: float) -> int:
	if protection_score >= 22.0:
		return 0
	if protection_score >= 18.0:
		return 1
	if protection_score >= 14.0:
		return 2
	return 3


## Returns: rush (Dictionary), protection (float), pressure (int). If emit_log is false, skip pass_ol_dl / pass_protection log lines (tick sim pre-throw samples).
func pass_rush_and_protection(ctx: PlaySimContext, log: PlayEventLog, emit_log: bool = true) -> Dictionary:
	var rush: Dictionary = _matchup.pick_pass_rush_matchup(ctx, log, emit_log)
	var prot: float = _blocking.pass_protection_score(ctx, rush, log, emit_log)
	var pressure: int = ScrimmageSimCalculators.map_pressure(prot)
	return {"rush": rush, "protection": prot, "pressure": pressure}


## Returns: lane (Dictionary), crease (float)
func run_lane_and_crease(ctx: PlaySimContext, log: PlayEventLog) -> Dictionary:
	var lane: Dictionary = _matchup.pick_run_lane_matchup(ctx, log)
	var crease: float = _blocking.run_crease_score(ctx, lane, log)
	return {"lane": lane, "crease": crease}


## Scalar separation for one WR/TE vs CB (same structure as RouteResolver loop body).
func separation_wr_vs_cb(ctx: PlaySimContext, wr: Dictionary, cb: Dictionary, recv_role: String) -> float:
	if wr.is_empty():
		return 0.0
	var wv := ctx.stat_view_for(wr)
	if cb.is_empty():
		return 2.0 + float(wv.route_running()) * 0.15
	var cv := ctx.stat_view_for(cb)
	var sep: float = float(wv.route_running()) + float(wv.speed()) * 0.5 + float(wv.awareness()) * 0.3
	sep -= float(cv.coverage()) + float(cv.speed()) * 0.5 + float(cv.awareness()) * 0.2
	sep += float(ResolutionBalanceConstants.noise_small(ctx.rng)) * 0.15
	return sep


func separation_rb_checkdown(ctx: PlaySimContext, rb: Dictionary, lb: Dictionary) -> float:
	if rb.is_empty():
		return 0.0
	var rv := ctx.stat_view_for(rb)
	if lb.is_empty():
		return float(rv.speed()) * 0.25 + float(rv.route_running()) * 0.2 + 0.5
	return float(rv.speed()) * 0.25 + float(rv.route_running()) * 0.2 - float(ctx.stat_view_for(lb).tackling()) * 0.15


static func separation_tier_from_scalar(sep: float) -> String:
	if sep >= 1.8:
		return SimConstants.SEP_OPEN
	if sep >= 0.9:
		return SimConstants.SEP_TIGHT
	if sep >= 0.2:
		return SimConstants.SEP_CONTESTED
	return SimConstants.SEP_SMOTHERED


static func chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))


## Tackle attempts require the same tile (Chebyshev 0).
static func can_attempt_tackle(defender_pos: Vector2i, carrier_pos: Vector2i) -> bool:
	return chebyshev(defender_pos, carrier_pos) == 0


## Max throw reach (Chebyshev tiles) from QB throw_power (1–10), relative to field depth.
static func max_throw_distance_cheb(throw_power: int) -> int:
	var p := clampi(throw_power, 1, 10)
	var min_d := int(round(float(SimConstants.TILE_ROWS_TOTAL) * 0.35))
	var max_d := int(round(float(SimConstants.TILE_ROWS_TOTAL) * 0.92))
	return clampi(int(lerpf(float(min_d), float(max_d), float(p - 1) / 9.0)), min_d, max_d)


static func step_toward(from: Vector2i, to: Vector2i) -> Vector2i:
	if from == to:
		return from
	var dr: int = signi(to.y - from.y)
	var dc: int = signi(to.x - from.x)
	return from + Vector2i(dc, dr)


static func behind_for_block(defender: SimPlayerState, blocker: SimPlayerState) -> bool:
	## Defender deeper in offensive backfield (higher engine row) than OL — no legal engagement from behind.
	return defender.global_row > blocker.global_row
