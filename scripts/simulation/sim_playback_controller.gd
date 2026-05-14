extends RefCounted
class_name SimPlaybackController


static func seconds_per_tick() -> float:
	return 1.0 / float(SimConstants.TICKS_PER_SECOND)


## Blend two snapshots (tick a, tick b) for smooth motion; alpha in [0,1].
static func blend_snapshots(snap_a: Dictionary, snap_b: Dictionary, alpha: float) -> Dictionary:
	var u := clampf(alpha, 0.0, 1.0)
	var players_out: Array = []
	var pmap := {}
	for p in snap_b.get("players", []):
		if typeof(p) == TYPE_DICTIONARY:
			pmap[str(p.get("player_id", ""))] = p
	for pa in snap_a.get("players", []):
		if typeof(pa) != TYPE_DICTIONARY:
			continue
		var id := str(pa.get("player_id", ""))
		var pb: Dictionary = pmap.get(id, {}) as Dictionary
		var r0 := int(pa.get("global_row", 0))
		var c0 := int(pa.get("global_col", 0))
		var r1 := int(pb.get("global_row", r0)) if not pb.is_empty() else r0
		var c1 := int(pb.get("global_col", c0)) if not pb.is_empty() else c0
		var row := int(round(lerpf(float(r0), float(r1), u)))
		var col := int(round(lerpf(float(c0), float(c1), u)))
		var merged: Dictionary = pa.duplicate(true)
		merged["global_row"] = row
		merged["global_col"] = col
		players_out.append(merged)
	return {
		"tick": lerpf(float(snap_a.get("tick", 0)), float(snap_b.get("tick", 0)), u),
		"players": players_out,
		"ball_carrier_id": str(snap_b.get("ball_carrier_id", snap_a.get("ball_carrier_id", ""))),
		"ball_state": str(snap_b.get("ball_state", snap_a.get("ball_state", ""))),
	}
