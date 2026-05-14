extends RefCounted
class_name PlayTickEngine

const BUCKET_RUN := "run"
const BUCKET_PASS := "pass"

static var tick_authoritative: bool = false
static var debug_run_parallel: bool = true
static var visual_playback_enabled: bool = false

var _tackle := TackleResolver.new()
var _turnover := TurnoverResolver.new()
var _calc := ScrimmageSimCalculators.new()
var _pass_resolver := PassSimResolver.new()
var _matchup := MatchupResolver.new()


func run(
	ctx: PlaySimContext,
	los_row_engine: int,
	bucket: String,
	selected_ball_carrier_id: String,
	play_row: Dictionary
) -> Dictionary:
	var sim_log := PlayEventLog.new()
	var snapshots: Array = []
	var world := _build_world(ctx, los_row_engine, bucket, selected_ball_carrier_id, play_row)
	sim_log.add(
		"sim_start",
		"Tick sim start bucket=%s los=%d" % [bucket, los_row_engine],
		{},
		{"bucket": bucket},
		0,
		los_row_engine,
		SimConstants.LOS_BASE_COL
	)
	snapshots.append(world.snapshot())

	var qb_drop_ticks := _qb_drop_ticks(ctx)
	var max_ticks := SimConstants.MAX_PLAY_TICKS
	if not PlayTickEngine.tick_authoritative:
		if bucket == BUCKET_PASS:
			max_ticks = mini(max_ticks, qb_drop_ticks)
		else:
			max_ticks = mini(max_ticks, 40)
	elif bucket == BUCKET_RUN:
		max_ticks = mini(max_ticks, 64)

	var pass_resolved := false

	while world.tick_index < max_ticks and world.play_end_reason.is_empty():
		world.tick_index += 1
		if world.contact_cooldown > 0:
			world.contact_cooldown -= 1
		_process_shed_attempts(ctx, world, sim_log)
		_try_blocking_engagements(ctx, world, sim_log, bucket)
		_move_players(ctx, world, sim_log, bucket, qb_drop_ticks, pass_resolved)
		_update_coverage_tiers(ctx, world)
		if bucket == BUCKET_RUN and PlayTickEngine.tick_authoritative:
			_check_play_end_spatial(world, sim_log)
			if world.play_end_reason.is_empty():
				_process_run_tackle(ctx, world, play_row, sim_log)
		else:
			_check_play_end_spatial(world, sim_log)

		if bucket == BUCKET_PASS and not pass_resolved:
			var is_throw_tick := world.tick_index >= qb_drop_ticks
			var pp_tick := _calc.pass_rush_and_protection(ctx, sim_log, is_throw_tick and PlayTickEngine.tick_authoritative)
			world.last_pass_rush = pp_tick.get("rush", {}) as Dictionary
			var prot0 := float(pp_tick.get("protection", 18.0))
			var nudge := _grid_pass_protection_nudge(world)
			world.last_pass_protection = prot0 + nudge
			world.last_pass_pressure = ScrimmageSimCalculators.map_pressure(world.last_pass_protection)
			if PlayTickEngine.tick_authoritative:
				if not is_throw_tick:
					var qb_st := world.get_player(world.qb_id)
					var qr := world.los_row_engine
					var qc := SimConstants.LOS_BASE_COL
					if qb_st != null:
						qr = qb_st.global_row
						qc = qb_st.global_col
					sim_log.add(
						"pass_pressure_tick",
						"Pre-throw sample: pressure %d, protection %.1f (grid %+0.2f)" % [world.last_pass_pressure, world.last_pass_protection, nudge],
						{"primary_id": world.qb_id},
						{"pressure": world.last_pass_pressure, "protection": world.last_pass_protection, "grid_nudge": nudge},
						world.tick_index,
						qr,
						qc,
					)
				else:
					if absf(nudge) > 0.0001:
						for i in range(sim_log.events.size() - 1, -1, -1):
							var ev: Dictionary = sim_log.events[i]
							if str(ev.get("code", "")) != "pass_protection":
								continue
							var dat: Dictionary = (ev.get("data", {}) as Dictionary).duplicate(true)
							dat["protection"] = world.last_pass_protection
							dat["grid_nudge"] = nudge
							var re := float(dat.get("rush_edge", 0.0))
							ev["message"] = "Pass protection score %.1f (rush edge %.1f; grid %+0.2f)" % [world.last_pass_protection, re, nudge]
							ev["data"] = dat
							break
					var pr := _pass_resolver.resolve_with_locked_pass_front(
						ctx,
						play_row,
						sim_log,
						world.last_pass_rush,
						world.last_pass_pressure,
						world.last_pass_protection,
					)
					pass_resolved = true
					world.pending_pass_inner = pr.duplicate(true)
					_apply_pass_resolve_to_world(ctx, world, pr, sim_log)
					_finish_pass_reason(world, pr)
			elif not is_throw_tick:
				var qb_st2 := world.get_player(world.qb_id)
				var qr2 := world.los_row_engine
				var qc2 := SimConstants.LOS_BASE_COL
				if qb_st2 != null:
					qr2 = qb_st2.global_row
					qc2 = qb_st2.global_col
				sim_log.add(
					"pass_pressure_tick",
					"Parallel dropback sample: pressure %d, protection %.1f (grid %+0.2f)" % [world.last_pass_pressure, world.last_pass_protection, nudge],
					{"primary_id": world.qb_id},
					{"pressure": world.last_pass_pressure, "protection": world.last_pass_protection, "grid_nudge": nudge},
					world.tick_index,
					qr2,
					qc2,
				)

		snapshots.append(world.snapshot())

		if bucket == BUCKET_PASS and PlayTickEngine.tick_authoritative and pass_resolved:
			break

	if PlayTickEngine.tick_authoritative and bucket == BUCKET_RUN and world.play_end_reason.is_empty():
		world.play_end_reason = "clock"

	var tick_play_result: Dictionary = {}
	if PlayTickEngine.tick_authoritative and bucket == BUCKET_RUN:
		tick_play_result = _compose_run_play_result(ctx, world, play_row, selected_ball_carrier_id, sim_log)
	elif PlayTickEngine.tick_authoritative and bucket == BUCKET_PASS:
		var pr_pass: Dictionary = world.pending_pass_inner.duplicate(true) if not world.pending_pass_inner.is_empty() else {}
		if not pr_pass.is_empty():
			tick_play_result = pr_pass
			tick_play_result["event_log"] = sim_log.events.duplicate(true)
			var bd2: Array[String] = sim_log.to_breakdown_strings()
			var td2 := int(tick_play_result.get("tile_delta", 0))
			bd2.append("Net tile rows toward goal: %+d" % td2)
			tick_play_result["breakdown"] = bd2
			var km2: Array = []
			for e2 in sim_log.events:
				var c2 := str(e2.get("code", ""))
				if c2 in ["pass_ol_dl", "run_ol_dl", "route_sep", "pass_pressure_tick", "pass_protection", "qb_pressure"]:
					km2.append(e2.duplicate(true))
			tick_play_result["key_matchups"] = km2
			tick_play_result["play_type_bucket"] = "pass"

	return {
		"snapshots": snapshots,
		"sim_event_log": sim_log,
		"tick_play_result": tick_play_result,
	}


func _qb_drop_ticks(ctx: PlaySimContext) -> int:
	var qb := ctx.qb_player()
	if qb.is_empty():
		return 3
	var aw := ctx.stat_view_for(qb).awareness()
	return clampi(2 + aw / 3, 2, 6)


func _build_world(
	ctx: PlaySimContext,
	los_row: int,
	bucket: String,
	carrier_id: String,
	_play_row: Dictionary
) -> SimWorld:
	var w := SimWorld.new()
	w.los_row_engine = los_row
	w.possession_team = ctx.possession_team
	w.play_bucket = bucket
	w.ball_state = SimConstants.BALL_IN_POSSESSION
	for s in ctx.offense_slots:
		_add_slot_player(w, ctx, s, "off", los_row)
	for s2 in ctx.defense_slots:
		_add_slot_player(w, ctx, s2, "def", los_row)
	_assign_man_coverage(w, ctx)
	_assign_routes(w, bucket)
	var rb := ctx.rb_player_for_run(carrier_id)
	var qb := ctx.qb_player()
	if bucket == BUCKET_RUN and not rb.is_empty():
		w.ball_carrier_id = str(rb.get("id", ""))
	elif not qb.is_empty():
		w.ball_carrier_id = str(qb.get("id", ""))
	w.qb_id = str(qb.get("id", "")) if not qb.is_empty() else ""
	var car := w.get_player(w.ball_carrier_id)
	if car != null:
		w.carrier_start_row = car.global_row
	return w


func _add_slot_player(w: SimWorld, ctx: PlaySimContext, slot: Dictionary, side: String, los_row: int) -> void:
	var pl: Dictionary = slot.get("player", {}) as Dictionary
	var pid := str(pl.get("id", ""))
	if pid.is_empty():
		return
	var role := str(slot.get("role", "?"))
	var dr := int(slot.get("delta_row", 0))
	var dc := int(slot.get("delta_col", 0))
	var rel_row := los_row + dr
	var rel_col := SimConstants.LOS_BASE_COL + dc
	rel_row = clampi(rel_row, 0, SimConstants.TILE_ROWS_TOTAL - 1)
	rel_col = clampi(rel_col, 0, SimConstants.COLS - 1)
	var st := SimPlayerState.new()
	st.player_id = pid
	st.role = role
	st.side = side
	st.global_row = rel_row
	st.global_col = rel_col
	st.facing = Vector2i(0, -1) if side == "off" else Vector2i(0, 1)
	st.intent_action = _default_intent(role, side, w.play_bucket)
	st.active_state = "moving"
	w.players[pid] = st


func _default_intent(role: String, side: String, bucket: String) -> String:
	var r := role.to_upper()
	if side == "off":
		if r.begins_with("OL"):
			return "pass_block" if bucket == BUCKET_PASS else "run_block"
		if r.begins_with("QB"):
			return "drop_back" if bucket == BUCKET_PASS else "carry"
		if r.begins_with("RB"):
			return "pass_block" if bucket == BUCKET_PASS else "carry"
		if r.begins_with("WR") or r.begins_with("TE"):
			return "run_route"
		return "moving"
	if r.begins_with("DL"):
		return "pass_rush" if bucket == BUCKET_PASS else "run_stop"
	if r.begins_with("LB"):
		return "pass_rush" if bucket == BUCKET_PASS else "run_stop"
	if r.begins_with("CB"):
		return "cover_man"
	if r.begins_with("S"):
		return "cover_zone"
	return "pursue"


func _assign_man_coverage(w: SimWorld, ctx: PlaySimContext) -> void:
	var pairs := _matchup.pair_wr_cb(ctx)
	for p in pairs:
		var wr: Dictionary = p.get("wr", {}) as Dictionary
		var cb: Dictionary = p.get("defender", {}) as Dictionary
		var wid := str(wr.get("id", ""))
		var cid := str(cb.get("id", ""))
		if wid.is_empty() or cid.is_empty():
			continue
		var cbs := w.get_player(cid)
		if cbs != null:
			cbs.man_cover_target_id = wid


func _assign_routes(w: SimWorld, bucket: String) -> void:
	for pid in w.players.keys():
		var st: SimPlayerState = w.players[pid] as SimPlayerState
		if st == null:
			continue
		var r := st.role.to_upper()
		if st.side != "off":
			continue
		if r.begins_with("WR") or r.begins_with("TE"):
			st.route_waypoints = _route_waypoints_for_role(st.global_col)
		elif r.begins_with("RB") and bucket == BUCKET_PASS:
			st.route_waypoints = _flatten_route(Vector2i(0, 1), 3)


func _route_waypoints_for_role(start_col: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var lat := signi(start_col - 3)
	if lat == 0:
		lat = 1
	for i in range(10):
		out.append(Vector2i(0, -1) if i % 2 == 0 else Vector2i(lat, -1))
	return out


func _flatten_route(step: Vector2i, count: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i in count:
		out.append(step)
	return out


func _process_shed_attempts(ctx: PlaySimContext, w: SimWorld, sim_log: PlayEventLog) -> void:
	for pid in w.players.keys():
		var d: SimPlayerState = w.players[pid] as SimPlayerState
		if d == null or d.side != "def":
			continue
		if d.engaged_with_player_id.is_empty():
			continue
		var blk := w.get_player(d.engaged_with_player_id)
		if blk == null:
			d.engaged_with_player_id = ""
			continue
		var def_pl := _find_player_dict(ctx, pid)
		var blk_pl := _find_player_dict(ctx, blk.player_id)
		if _tackle.roll_shed_block(ctx, def_pl, blk_pl, sim_log):
			d.engaged_with_player_id = ""
			blk.engaged_with_player_id = ""
			d.active_state = "pursue"
			blk.active_state = "moving"


func _try_blocking_engagements(ctx: PlaySimContext, w: SimWorld, sim_log: PlayEventLog, bucket: String) -> void:
	for pid in w.players.keys():
		var ol: SimPlayerState = w.players[pid] as SimPlayerState
		if ol == null or ol.side != "off":
			continue
		if not ol.role.to_upper().begins_with("OL"):
			continue
		if not ol.engaged_with_player_id.is_empty():
			continue
		var want := "pass_block" if bucket == BUCKET_PASS else "run_block"
		if ol.intent_action != want and ol.intent_action != "pass_block" and ol.intent_action != "run_block":
			continue
		for pid2 in w.players.keys():
			var dl: SimPlayerState = w.players[pid2] as SimPlayerState
			if dl == null or dl.side != "def":
				continue
			if not dl.role.to_upper().begins_with("DL"):
				continue
			if not dl.engaged_with_player_id.is_empty():
				continue
			if ScrimmageSimCalculators.chebyshev(ol.grid_pos(), dl.grid_pos()) != 1:
				continue
			if ScrimmageSimCalculators.behind_for_block(dl, ol):
				continue
			var roll := ctx.rng.randf()
			if not PlayTickEngine.tick_authoritative:
				roll = float((w.tick_index * 17 + ol.global_col * 5 + dl.global_col * 11) % 100) / 100.0
			if roll > 0.75:
				continue
			ol.engaged_with_player_id = dl.player_id
			dl.engaged_with_player_id = ol.player_id
			ol.active_state = "blocking"
			dl.active_state = "blocking"
			sim_log.add(
				"engage_block",
				"OL %s engaged DL %s" % [ol.player_id, dl.player_id],
				{"primary_id": ol.player_id, "secondary_id": dl.player_id},
				{},
				w.tick_index,
				ol.global_row,
				ol.global_col
			)
			break


func _move_players(ctx: PlaySimContext, w: SimWorld, sim_log: PlayEventLog, bucket: String, qb_drop_ticks: int, pass_done: bool) -> void:
	var carrier := w.get_player(w.ball_carrier_id)
	var goal := Vector2i(3, 0)
	if carrier != null:
		goal = Vector2i(carrier.global_col, 0)
	for pid in w.players.keys():
		var st: SimPlayerState = w.players[pid] as SimPlayerState
		if st == null:
			continue
		if not st.engaged_with_player_id.is_empty():
			continue
		var from := st.grid_pos()
		var to_cell := from
		var rup := st.role.to_upper()
		if st.side == "off":
			if rup.begins_with("QB"):
				if bucket == BUCKET_PASS and w.tick_index <= qb_drop_ticks and not pass_done:
					to_cell = ScrimmageSimCalculators.step_toward(from, from + Vector2i(0, 1))
				else:
					to_cell = from
			elif rup.begins_with("RB") and bucket == BUCKET_RUN and st.player_id == w.ball_carrier_id:
				to_cell = ScrimmageSimCalculators.step_toward(from, goal)
			elif rup.begins_with("RB") and bucket == BUCKET_PASS:
				if not st.route_waypoints.is_empty():
					var step: Vector2i = st.route_waypoints[0]
					st.route_waypoints.remove_at(0)
					to_cell = from + step
			elif (rup.begins_with("WR") or rup.begins_with("TE")) and not st.route_waypoints.is_empty():
				var step2: Vector2i = st.route_waypoints[0]
				st.route_waypoints.remove_at(0)
				to_cell = from + step2
			elif rup.begins_with("OL"):
				## Slight slide toward nearest DL for run block
				if bucket == BUCKET_RUN:
					var nearest := _nearest_opponent_tile(w, st)
					if nearest != Vector2i(-1, -1):
						to_cell = ScrimmageSimCalculators.step_toward(from, nearest)
		else:
			## Defense
			if rup.begins_with("CB") and not st.man_cover_target_id.is_empty():
				var wrp := w.get_player(st.man_cover_target_id)
				if wrp != null:
					to_cell = ScrimmageSimCalculators.step_toward(from, wrp.grid_pos())
			elif carrier != null:
				to_cell = ScrimmageSimCalculators.step_toward(from, carrier.grid_pos())
		to_cell.x = clampi(to_cell.x, 0, SimConstants.COLS - 1)
		to_cell.y = clampi(to_cell.y, 0, SimConstants.TILE_ROWS_TOTAL - 1)
		if to_cell != from:
			st.global_col = to_cell.x
			st.global_row = to_cell.y
			st.facing = to_cell - from
			sim_log.add(
				"sim_move",
				"%s moved to r%d c%d" % [st.player_id, st.global_row, st.global_col],
				{"primary_id": st.player_id},
				{"role": st.role},
				w.tick_index,
				st.global_row,
				st.global_col
			)


func _nearest_opponent_tile(w: SimWorld, st: SimPlayerState) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 999
	for pid2 in w.players.keys():
		var o: SimPlayerState = w.players[pid2] as SimPlayerState
		if o == null or o.side != "def":
			continue
		var d := ScrimmageSimCalculators.chebyshev(st.grid_pos(), o.grid_pos())
		if d < best_d:
			best_d = d
			best = o.grid_pos()
	return best


func _update_coverage_tiers(ctx: PlaySimContext, w: SimWorld) -> void:
	for pid in w.players.keys():
		var cb: SimPlayerState = w.players[pid] as SimPlayerState
		if cb == null or cb.side != "def" or not cb.role.to_upper().begins_with("CB"):
			continue
		if cb.man_cover_target_id.is_empty():
			continue
		var wrs := w.get_player(cb.man_cover_target_id)
		if wrs == null:
			continue
		var wrd := _find_player_dict(ctx, wrs.player_id)
		var cbd := _find_player_dict(ctx, cb.player_id)
		var sep := _calc.separation_wr_vs_cb(ctx, wrd, cbd, wrs.role)
		if ScrimmageSimCalculators.chebyshev(cb.grid_pos(), wrs.grid_pos()) <= SimConstants.COVERAGE_NEAR_TILES:
			cb.separation_tier = ScrimmageSimCalculators.separation_tier_from_scalar(sep)
		else:
			cb.separation_tier = SimConstants.SEP_OPEN


func _process_run_tackle(ctx: PlaySimContext, w: SimWorld, play_row: Dictionary, sim_log: PlayEventLog) -> void:
	var car := w.get_player(w.ball_carrier_id)
	if car == null:
		return
	if w.contact_cooldown > 0:
		return
	if SimWorld.zone_from_engine_row(car.global_row) >= 7:
		return
	var car_dict := _find_player_dict(ctx, car.player_id)
	var tackler_st: SimPlayerState = null
	var best_d := 99
	for pid in w.players.keys():
		var d: SimPlayerState = w.players[pid] as SimPlayerState
		if d == null or d.side != "def":
			continue
		if not d.engaged_with_player_id.is_empty():
			continue
		var dist := ScrimmageSimCalculators.chebyshev(car.grid_pos(), d.grid_pos())
		if dist <= SimConstants.TACKLE_RANGE_TILES and dist < best_d:
			best_d = dist
			tackler_st = d
	if tackler_st == null:
		return
	var tackler := _find_player_dict(ctx, tackler_st.player_id)
	var yac_res := _tackle.resolve_yards_after_catch(ctx, car_dict, tackler, sim_log, car.broken_tackle_chain)
	w.contact_cooldown = 1
	var broken := int(yac_res.get("broken", 0))
	if broken != 0:
		car.broken_tackle_chain += 1
		var yac := int(yac_res.get("yac", 0))
		for _i in yac:
			var nxt := car.grid_pos() + Vector2i(0, -1)
			nxt.x = clampi(nxt.x, 0, SimConstants.COLS - 1)
			nxt.y = clampi(nxt.y, 0, SimConstants.TILE_ROWS_TOTAL - 1)
			car.global_row = nxt.y
			car.global_col = nxt.x
		sim_log.add("sim_broken", "Broken tackle chain %d" % car.broken_tackle_chain, {"primary_id": car.player_id}, {}, w.tick_index, car.global_row, car.global_col)
		return

	var hit_q := 1.0 + float(ctx.stat_view_for(tackler).tackling()) * 0.04 + float(ctx.stat_view_for(tackler).strength()) * 0.02
	if _turnover.roll_fumble_after_contact(ctx, car_dict, tackler, hit_q, sim_log):
		w.play_end_reason = "fumble"
		w.ball_state = SimConstants.BALL_FUMBLE
		w.last_tackler_id = tackler_st.player_id
		return
	w.play_end_reason = "tackle"
	w.last_tackler_id = tackler_st.player_id


func _check_play_end_spatial(w: SimWorld, sim_log: PlayEventLog) -> void:
	var car := w.get_player(w.ball_carrier_id)
	if car == null:
		return
	if SimWorld.zone_from_engine_row(car.global_row) >= 7:
		w.play_end_reason = "touchdown"
		sim_log.add("sim_td", "Ball carrier reached scoring zone", {"primary_id": car.player_id}, {}, w.tick_index, car.global_row, car.global_col)


func _apply_pass_resolve_to_world(ctx: PlaySimContext, w: SimWorld, pr: Dictionary, sim_log: PlayEventLog) -> void:
	var tid := str(pr.get("target_receiver_id", ""))
	if tid.is_empty():
		return
	var tgt := w.get_player(tid)
	if tgt == null:
		return
	w.ball_carrier_id = tid
	w.ball_state = SimConstants.BALL_IN_POSSESSION
	sim_log.add("sim_pass_applied", "Possession to %s" % tid, {"primary_id": tid}, {}, w.tick_index, tgt.global_row, tgt.global_col)


func _finish_pass_reason(w: SimWorld, pr: Dictionary) -> void:
	if bool(pr.get("incomplete_pass", false)):
		w.play_end_reason = "incomplete"
		return
	var toe: Dictionary = pr.get("turnover_outcome", {}) as Dictionary
	if bool(toe.get("occurred", false)):
		var eb := str(toe.get("ended_by", ""))
		w.play_end_reason = eb if not eb.is_empty() else "turnover"
		return
	w.play_end_reason = "pass_resolved"


## Slight protection penalty when defensive DLs are within 2 tiles of the QB (Chebyshev).
func _grid_pass_protection_nudge(w: SimWorld) -> float:
	var qb := w.get_player(w.qb_id)
	if qb == null:
		return 0.0
	var qg := qb.grid_pos()
	var n := 0
	for pid in w.players.keys():
		var p: SimPlayerState = w.players[pid] as SimPlayerState
		if p == null or p.side != "def":
			continue
		if not str(p.role).to_upper().begins_with("DL"):
			continue
		if ScrimmageSimCalculators.chebyshev(qg, p.grid_pos()) <= 2:
			n += 1
	return clampf(-0.32 * float(n), -1.25, 0.0)


func _compose_run_play_result(
	ctx: PlaySimContext,
	w: SimWorld,
	play_row: Dictionary,
	selected_ball_carrier_id: String,
	sim_log: PlayEventLog
) -> Dictionary:
	var tmin := int(play_row.get("tile_delta_min", 0))
	var tmax := int(play_row.get("tile_delta_max", 10))
	var rb := ctx.rb_player_for_run(selected_ball_carrier_id)
	if rb.is_empty():
		return {}
	var car := w.get_player(w.ball_carrier_id)
	var end_row := w.los_row_engine if car == null else car.global_row
	var td := clampi(w.los_row_engine - end_row, tmin, tmax)
	var tackled_by := w.last_tackler_id if w.play_end_reason == "tackle" else ""
	if w.play_end_reason == "fumble":
		tackled_by = w.last_tackler_id
	var broken_n := 0
	if car != null:
		broken_n = car.broken_tackle_chain
	var turnover := {"occurred": false, "calc_lines": []}
	var result_text := "Run for %d" % td
	if w.play_end_reason == "fumble":
		turnover = {"occurred": true, "ended_by": "fumble_recovery", "start_zone": -1, "text": "Fumble lost.", "calc_lines": []}
		result_text = "Fumble on run"
	elif w.play_end_reason == "touchdown":
		result_text = "Touchdown run"
	var bd: Array[String] = sim_log.to_breakdown_strings()
	bd.append("Net tile rows toward goal: %+d" % td)
	var km: Array = []
	for e in sim_log.events:
		var c := str(e.get("code", ""))
		if c in ["pass_ol_dl", "run_ol_dl", "route_sep"]:
			km.append(e.duplicate(true))
	return {
		"tile_delta": td,
		"score_delta": 0,
		"success": td > 0,
		"result_text": result_text,
		"incomplete_pass": false,
		"pressure_level": 0,
		"target_receiver_id": "",
		"tackled_by_id": tackled_by,
		"broken_tackles": broken_n,
		"turnover_outcome": turnover,
		"breakdown": bd,
		"event_log": sim_log.events.duplicate(true),
		"key_matchups": km,
		"play_type_bucket": "run",
	}


func _find_player_dict(ctx: PlaySimContext, pid: String) -> Dictionary:
	for s in ctx.offense_slots:
		var pl: Dictionary = s.get("player", {}) as Dictionary
		if str(pl.get("id", "")) == pid:
			return pl
	for s2 in ctx.defense_slots:
		var pl2: Dictionary = s2.get("player", {}) as Dictionary
		if str(pl2.get("id", "")) == pid:
			return pl2
	return {}
