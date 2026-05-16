extends RefCounted
class_name ZoneCoverageRunner

const STACK_PENALTY_ONE := 4.0
const STACK_PENALTY_TWO_PLUS := 12.0
const REACTION_DELAY_SCORE_SCALE := 0.35
const VISUAL_LEAN_TILES := 0.22


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


static func observed_velocity(recv: SimPlayerState) -> Vector2i:
	return recv.facing


static func lead_ticks_for_defender(ctx: PlaySimContext, def_st: SimPlayerState) -> int:
	var dd := player_dict_for_id(ctx, def_st.player_id)
	if dd.is_empty():
		return 1
	var sv := ctx.stat_view_for(dd)
	var blend := float(sv.awareness() + sv.coverage()) * 0.5
	return clampi(1 + int(blend - 5.0) / 3, 1, SimConstants.ZONE_PREDICT_LEAD_MAX)


static func predicted_cell(recv: SimPlayerState, lead_ticks: int) -> Vector2i:
	var pos := recv.grid_pos()
	var v := observed_velocity(recv)
	if v == Vector2i.ZERO or lead_ticks <= 0:
		return pos
	var pred := pos + v * lead_ticks
	pred.x = clampi(pred.x, 0, SimConstants.COLS - 1)
	pred.y = clampi(pred.y, 0, SimConstants.TILE_ROWS_TOTAL - 1)
	return pred


static func clamp_to_anchor(target: Vector2i, anchor: Vector2i, prof: ZoneCoverageProfile) -> Vector2i:
	var cx := clampi(target.x, anchor.x - prof.anchor_max_col, anchor.x + prof.anchor_max_col)
	var cy := clampi(target.y, anchor.y - prof.anchor_max_row, anchor.y + prof.anchor_max_row)
	return Vector2i(cx, cy)


static func prepare_zone_tick(
	ctx: PlaySimContext,
	w: SimWorld,
	play_row: Dictionary,
	bucket: String,
	pass_done: bool
) -> void:
	for pid in w.players.keys():
		var z: SimPlayerState = w.players[pid] as SimPlayerState
		if z != null and z.side == "def" and z.intent_action == "cover_zone":
			z.zone_target_id = ""
			z.zone_target_row = -1
			z.zone_target_col = -1
	var defs := _zone_defenders_sorted(w)
	for def_st in defs:
		_assign_zone_target_for_defender(def_st, ctx, w, play_row, bucket, pass_done, defs)
		_update_visual_lean(def_st, w)


static func _zone_defenders_sorted(w: SimWorld) -> Array[SimPlayerState]:
	var out: Array[SimPlayerState] = []
	for pid in w.players.keys():
		var st: SimPlayerState = w.players[pid] as SimPlayerState
		if st != null and st.side == "def" and st.intent_action == "cover_zone":
			out.append(st)
	out.sort_custom(func(a: SimPlayerState, b: SimPlayerState) -> bool:
		return a.player_id < b.player_id
	)
	return out


static func _assign_zone_target_for_defender(
	def_st: SimPlayerState,
	ctx: PlaySimContext,
	w: SimWorld,
	play_row: Dictionary,
	bucket: String,
	pass_done: bool,
	all_defs: Array[SimPlayerState]
) -> void:
	var carrier := w.get_player(w.ball_carrier_id)
	if should_pursue_ball_carrier(def_st, w, ctx, bucket, pass_done) and carrier != null:
		def_st.zone_target_id = carrier.player_id
		var lead := lead_ticks_for_defender(ctx, def_st)
		var tgt := predicted_cell(carrier, mini(lead, 2))
		def_st.zone_target_row = tgt.y
		def_st.zone_target_col = tgt.x
		return
	var best_recv: SimPlayerState = null
	var best_score := -999999.0
	for recv in _skill_receiver_states(w):
		var score := threat_score(
			def_st, recv, ctx, w, play_row, all_defs, true
		)
		if score > best_score:
			best_score = score
			best_recv = recv
	if best_recv == null:
		def_st.zone_target_id = ""
		def_st.zone_target_row = def_st.zone_anchor_row
		def_st.zone_target_col = def_st.zone_anchor_col
		return
	def_st.zone_target_id = best_recv.player_id
	var lead2 := lead_ticks_for_defender(ctx, def_st)
	var pred := predicted_cell(best_recv, lead2)
	def_st.zone_target_row = pred.y
	def_st.zone_target_col = pred.x


static func threat_score(
	def_st: SimPlayerState,
	recv: SimPlayerState,
	ctx: PlaySimContext,
	w: SimWorld,
	play_row: Dictionary,
	all_defs: Array[SimPlayerState],
	apply_stack_penalty: bool
) -> float:
	if not _receiver_eligible(def_st, recv, w):
		return -999999.0
	var prof := ZoneCoverageProfile.for_role(def_st.role)
	var def_pos := def_st.grid_pos()
	var recv_pos := recv.grid_pos()
	var route_depth := maxi(0, def_pos.y - recv_pos.y)
	var score := float(route_depth) * 3.0 * prof.depth_mult
	if route_depth >= 3:
		score += prof.prefer_deep_bonus
	if route_depth <= 2:
		score += prof.prefer_shallow_bonus
	score += _separation_bonus(recv)
	score += _progression_bonus(play_row, recv.role)
	score += _role_bonus(recv.role)
	var dist := float(ScrimmageSimCalculators.chebyshev(def_pos, recv_pos))
	score -= dist * (1.1 / maxf(0.35, prof.aggression))
	var width_d := absf(float(recv_pos.x) - float(def_pos.x))
	score -= width_d * prof.width_penalty_scale
	if apply_stack_penalty:
		var others := _teammates_targeting_receiver(recv.player_id, def_st.player_id, all_defs)
		if others == 1:
			score -= STACK_PENALTY_ONE
		elif others >= 2:
			score -= STACK_PENALTY_TWO_PLUS
	if w.tick_index <= prof.reaction_delay_ticks:
		score *= REACTION_DELAY_SCORE_SCALE
	return score


static func _receiver_eligible(def_st: SimPlayerState, recv: SimPlayerState, w: SimWorld) -> bool:
	var dist := ScrimmageSimCalculators.chebyshev(def_st.grid_pos(), recv.grid_pos())
	if dist > SimConstants.ZONE_MAX_THREAT_RANGE:
		return false
	if recv.global_row > def_st.global_row + SimConstants.ZONE_BEHIND_DEFENDER_ROWS:
		return false
	return true


static func _separation_bonus(recv: SimPlayerState) -> float:
	match recv.receiver_zone_pressure_tier:
		SimConstants.SEP_OPEN:
			return 3.0
		SimConstants.SEP_TIGHT:
			return 2.0
		SimConstants.SEP_CONTESTED:
			return 1.0
		SimConstants.SEP_SMOTHERED:
			return 0.0
	return 1.5


static func _progression_bonus(play_row: Dictionary, recv_role: String) -> float:
	var roles := PlayAuthoring.progression_roles(play_row)
	for i in roles.size():
		if str(roles[i]) == recv_role:
			if i == 0:
				return 1.5
			if i == 1:
				return 1.0
			return 0.5
	return 0.0


static func _role_bonus(recv_role: String) -> float:
	var r := recv_role.to_upper()
	if r.begins_with("WR"):
		return 1.0
	if r.begins_with("TE"):
		return 0.5
	if r.begins_with("RB"):
		return 0.25
	return 0.0


static func _teammates_targeting_receiver(
	recv_id: String,
	self_id: String,
	all_defs: Array[SimPlayerState]
) -> int:
	var n := 0
	for d in all_defs:
		if d.player_id == self_id:
			continue
		if d.zone_target_id == recv_id:
			n += 1
	return n


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
	var defs := _zone_defenders_sorted(w)
	var recvs := _skill_receiver_states(w)
	var play_row: Dictionary = ctx.offense_play_row
	for recv in recvs:
		var best_def: SimPlayerState = null
		var best_score := -999999.0
		for def_st in defs:
			var score := threat_score(def_st, recv, ctx, w, play_row, defs, false)
			if score > best_score:
				best_score = score
				best_def = def_st
		if best_def == null or best_score < -100000.0:
			continue
		var rd := player_dict_for_id(ctx, recv.player_id)
		var zd := player_dict_for_id(ctx, best_def.player_id)
		var sep := calc.separation_wr_vs_cb(ctx, rd, zd, recv.role)
		var new_tier := ScrimmageSimCalculators.separation_tier_from_scalar(sep)
		recv.receiver_zone_pressure_tier = merge_worse_receiver_tier(recv.receiver_zone_pressure_tier, new_tier)


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
		var lead := lead_ticks_for_defender(ctx, st)
		var pursue_tgt := predicted_cell(carrier, mini(lead, 2))
		return ScrimmageSimCalculators.step_toward(from, pursue_tgt)
	if not st.zone_target_id.is_empty():
		var recv := w.get_player(st.zone_target_id)
		if recv != null:
			var lead := lead_ticks_for_defender(ctx, st)
			var tgt := predicted_cell(recv, lead)
			return ScrimmageSimCalculators.step_toward(from, tgt)
		if st.zone_target_row >= 0:
			var tgt := Vector2i(st.zone_target_col, st.zone_target_row)
			return ScrimmageSimCalculators.step_toward(from, tgt)
	var anchor := Vector2i(st.zone_anchor_col, st.zone_anchor_row)
	return ScrimmageSimCalculators.step_toward(from, anchor)


static func _update_visual_lean(def_st: SimPlayerState, w: SimWorld) -> void:
	var from := def_st.grid_pos()
	var tgt := Vector2i(def_st.zone_target_col, def_st.zone_target_row)
	if def_st.zone_target_row < 0:
		def_st.zone_visual_bias_col = 0.0
		def_st.zone_visual_bias_row = 0.0
		return
	var delta := Vector2(tgt.x - from.x, tgt.y - from.y)
	if delta.length_squared() < 0.0001:
		def_st.zone_visual_bias_col = 0.0
		def_st.zone_visual_bias_row = 0.0
		return
	var scaled := delta.normalized() * VISUAL_LEAN_TILES
	def_st.zone_visual_bias_col = scaled.x
	def_st.zone_visual_bias_row = scaled.y


static func visual_world_offset(field_grid: FieldGrid, pd: Dictionary) -> Vector2:
	if field_grid == null:
		return Vector2.ZERO
	var bc := float(pd.get("zone_visual_bias_col", 0.0))
	var br := float(pd.get("zone_visual_bias_row", 0.0))
	if absf(bc) < 0.001 and absf(br) < 0.001:
		return Vector2.ZERO
	return Vector2(bc * field_grid.tile_width, br * field_grid.tile_height)
