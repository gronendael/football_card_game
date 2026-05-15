extends RefCounted
class_name ZoneCoverageRunner


static func player_dict_for_id(ctx: PlaySimContext, pid: String) -> Dictionary:
	for s in ctx.offense_slots:
		var pl: Dictionary = s.get("player", {}) as Dictionary
		if str(pl.get("id", "")) == pid:
			return pl
	for s2 in ctx.defense_slots:
		var pl2: Dictionary = s2.get("player", {}) as Dictionary
		if str(pl2.get("id", "")) == pid:
			return pl2
	return {}


static func receiver_in_monitor_rect(def_st: SimPlayerState, recv_pos: Vector2i) -> bool:
	var d := def_st.grid_pos()
	return (
		absi(recv_pos.y - d.y) <= SimConstants.ZONE_MONITOR_ROWS_HALF
		and absi(recv_pos.x - d.x) <= SimConstants.ZONE_MONITOR_COLS_HALF
	)


static func clamp_to_drift_anchor(target: Vector2i, anchor: Vector2i) -> Vector2i:
	var cx := clampi(
		target.x,
		anchor.x - SimConstants.ZONE_DRIFT_COLS_HALF,
		anchor.x + SimConstants.ZONE_DRIFT_COLS_HALF
	)
	var cy := clampi(
		target.y,
		anchor.y - SimConstants.ZONE_DRIFT_ROWS_HALF,
		anchor.y + SimConstants.ZONE_DRIFT_ROWS_HALF
	)
	return Vector2i(cx, cy)


static func _tier_rank(t: String) -> int:
	match t:
		SimConstants.SEP_SMOTHERED:
			return 4
		SimConstants.SEP_CONTESTED:
			return 3
		SimConstants.SEP_TIGHT:
			return 2
		_:
			return 1


static func merge_worse_receiver_tier(a: String, b: String) -> String:
	return a if _tier_rank(a) >= _tier_rank(b) else b


static func adjust_sep_for_coverage_tier(sep: float, tier: String) -> float:
	match tier:
		SimConstants.SEP_OPEN:
			return maxf(sep, 2.2)
		SimConstants.SEP_TIGHT:
			return maxf(sep, 1.2)
		SimConstants.SEP_CONTESTED:
			return minf(sep, 0.8)
		SimConstants.SEP_SMOTHERED:
			return minf(sep, 0.1)
	return sep


static func reset_receiver_zone_tiers(w: SimWorld) -> void:
	for pid in w.players.keys():
		var st: SimPlayerState = w.players[pid] as SimPlayerState
		if st == null or st.side != "off":
			continue
		var r := st.role.to_upper()
		if r.begins_with("WR") or r.begins_with("TE") or r.begins_with("RB"):
			st.receiver_zone_pressure_tier = SimConstants.SEP_OPEN


static func apply_zone_receiver_pressure(ctx: PlaySimContext, w: SimWorld, calc: ScrimmageSimCalculators) -> void:
	for pid in w.players.keys():
		var zst: SimPlayerState = w.players[pid] as SimPlayerState
		if zst == null or zst.side != "def":
			continue
		if zst.intent_action != "cover_zone":
			continue
		var zd := player_dict_for_id(ctx, zst.player_id)
		for pid2 in w.players.keys():
			var rst: SimPlayerState = w.players[pid2] as SimPlayerState
			if rst == null or rst.side != "off":
				continue
			var ru := rst.role.to_upper()
			if not (ru.begins_with("WR") or ru.begins_with("TE") or ru.begins_with("RB")):
				continue
			if not receiver_in_monitor_rect(zst, rst.grid_pos()):
				continue
			var rd := player_dict_for_id(ctx, rst.player_id)
			var recv_role := rst.role
			var sep := calc.separation_wr_vs_cb(ctx, rd, zd, recv_role)
			var new_tier := ScrimmageSimCalculators.separation_tier_from_scalar(sep)
			rst.receiver_zone_pressure_tier = merge_worse_receiver_tier(rst.receiver_zone_pressure_tier, new_tier)


static func _skill_receiver_states(w: SimWorld) -> Array[SimPlayerState]:
	var out: Array[SimPlayerState] = []
	for pid in w.players.keys():
		var st: SimPlayerState = w.players[pid] as SimPlayerState
		if st == null or st.side != "off":
			continue
		var r := st.role.to_upper()
		if r.begins_with("WR") or r.begins_with("TE") or r.begins_with("RB"):
			out.append(st)
	return out


static func _zone_defenders(w: SimWorld) -> Array[SimPlayerState]:
	var out: Array[SimPlayerState] = []
	for pid in w.players.keys():
		var st: SimPlayerState = w.players[pid] as SimPlayerState
		if st != null and st.side == "def" and st.intent_action == "cover_zone":
			out.append(st)
	return out


static func _recv_nearest_zone_owner(w: SimWorld) -> Dictionary:
	## recv_player_id -> zone_def_player_id
	var zone_defs := _zone_defenders(w)
	var skill := _skill_receiver_states(w)
	var recv_to_def: Dictionary = {}
	for recv in skill:
		var best_d: SimPlayerState = null
		var best_md := 999
		var rp := recv.grid_pos()
		for z in zone_defs:
			if not receiver_in_monitor_rect(z, rp):
				continue
			var md := absi(z.global_col - recv.global_col) + absi(z.global_row - recv.global_row)
			if md < best_md:
				best_md = md
				best_d = z
		if best_d != null:
			recv_to_def[recv.player_id] = best_d.player_id
	return recv_to_def


static func _deepest_receiver_on_side(def_col: int, pool: Array[SimPlayerState]) -> SimPlayerState:
	var mid := SimConstants.LOS_BASE_COL
	var filt: Array[SimPlayerState] = []
	if def_col < mid:
		for r in pool:
			if r.global_col < mid:
				filt.append(r)
	elif def_col > mid:
		for r in pool:
			if r.global_col > mid:
				filt.append(r)
	else:
		filt = pool.duplicate()
	if filt.is_empty():
		filt = pool.duplicate()
	var best: SimPlayerState = null
	for r in filt:
		if best == null or r.global_row < best.global_row:
			best = r
	return best


static func should_pursue_ball_carrier(
	st: SimPlayerState,
	w: SimWorld,
	ctx: PlaySimContext,
	bucket: String,
	pass_done: bool
) -> bool:
	var carrier := w.get_player(w.ball_carrier_id)
	if carrier == null:
		return false
	if carrier.player_id == w.qb_id:
		return false
	if bucket == "pass" and pass_done:
		return true
	if bucket == "run":
		if carrier.global_row <= w.los_row_engine:
			return true
		var dd := player_dict_for_id(ctx, st.player_id)
		if not dd.is_empty():
			var aw := ctx.stat_view_for(dd).awareness()
			var p := clampf(0.07 + float(aw - 5) * 0.065, 0.05, 0.48)
			if ctx.rng.randf() < p:
				return true
	return false


static func compute_cover_zone_move(
	st: SimPlayerState,
	w: SimWorld,
	ctx: PlaySimContext,
	bucket: String,
	pass_done: bool
) -> Vector2i:
	var from := st.grid_pos()
	var carrier := w.get_player(w.ball_carrier_id)
	if should_pursue_ball_carrier(st, w, ctx, bucket, pass_done) and carrier != null:
		return ScrimmageSimCalculators.step_toward(from, carrier.grid_pos())
	var anchor := Vector2i(st.zone_anchor_col, st.zone_anchor_row)
	var recv_owned := _recv_nearest_zone_owner(w)
	var mine: Array[SimPlayerState] = []
	for rid in recv_owned.keys():
		if str(recv_owned[rid]) != st.player_id:
			continue
		var rs := w.get_player(str(rid))
		if rs != null and receiver_in_monitor_rect(st, rs.grid_pos()):
			mine.append(rs)
	if mine.is_empty():
		var pool := _skill_receiver_states(w)
		var drift_tgt := _deepest_receiver_on_side(st.global_col, pool)
		if drift_tgt == null:
			return ScrimmageSimCalculators.step_toward(from, anchor)
		var clamped := clamp_to_drift_anchor(drift_tgt.grid_pos(), anchor)
		return ScrimmageSimCalculators.step_toward(from, clamped)
	var best: SimPlayerState = mine[0]
	for r in mine:
		if r.global_row < best.global_row:
			best = r
	return ScrimmageSimCalculators.step_toward(from, best.grid_pos())
