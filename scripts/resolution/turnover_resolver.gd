extends RefCounted
class_name TurnoverResolver


func roll_interception(
	ctx: PlaySimContext,
	qb: Dictionary,
	target_wr: Dictionary,
	cover_cb: Dictionary,
	separation: float,
	pressure_level: int,
	safety_player: Dictionary,
	log: PlayEventLog
) -> bool:
	var qv := ctx.stat_view_for(qb)
	var wv := ctx.stat_view_for(target_wr)
	var cv := ctx.stat_view_for(cover_cb) if not cover_cb.is_empty() else PlayerStatView.from_dict({})
	var sv := ctx.stat_view_for(safety_player) if not safety_player.is_empty() else PlayerStatView.from_dict({})
	var base := 3.5 + float(pressure_level) * 3.8
	base += float(cv.coverage() + cv.catching()) * 0.45
	base -= float(qv.awareness()) * 1.65
	base -= float(wv.catching()) * 0.35
	base -= separation * 5.5
	if separation > 1.4 and not safety_player.is_empty():
		base -= float(sv.awareness()) * 0.55
	base = clampf(base, 1.0, 20.0)
	var roll := ctx.rng.randf() * 100.0
	var pick := roll < base
	log.add(
		"int_check",
		"INT chance %.1f%% roll %.1f → %s" % [base, roll, "PICK" if pick else "safe"],
		{"primary_id": str(qb.get("id", "")), "secondary_id": str(cover_cb.get("id", ""))},
		{"chance": base, "roll": roll}
	)
	return pick


func roll_fumble_after_contact(
	ctx: PlaySimContext,
	carrier: Dictionary,
	tackler: Dictionary,
	hit_quality: float,
	log: PlayEventLog
) -> bool:
	if carrier.is_empty():
		return false
	var base := 3.5 if hit_quality > 1.2 else 2.2
	var security := float(ctx.stat_view_for(carrier).carrying()) * 3.5 + 40.0
	var def_tk := float(ctx.stat_view_for(tackler).tackling()) * 1.8 + float(ctx.stat_view_for(tackler).strength()) * 0.8 if not tackler.is_empty() else 50.0
	var chance := clampf(base + (def_tk - security) * 0.09 + hit_quality * 1.5, 1.0, 15.0)
	var roll := ctx.rng.randf() * 100.0
	var lost := roll < chance
	log.add(
		"fumble_check",
		"Fumble chance %.1f%% roll %.1f → %s" % [chance, roll, "FUMBLE" if lost else "secure"],
		{"primary_id": str(carrier.get("id", "")), "secondary_id": str(tackler.get("id", ""))},
		{"chance": chance}
	)
	return lost
