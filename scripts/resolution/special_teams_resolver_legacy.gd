extends RefCounted
class_name SpecialTeamsResolverLegacy

const BUCKET_SPOT_KICK := "spot_kick"
const PLAY_PUNT := "punt"
const ZONE_MIDFIELD := 4
const ZONE_ATTACK := 5
const ZONE_RED := 6

const _PUNT_RETURN_TIER_BASE := [0.30, 0.40, 0.15, 0.12, 0.03]
const _PUNT_RETURN_ROWS_MAX := 34


func _zone_name(zone: int) -> String:
	match zone:
		1:
			return "Defensive Endzone"
		2:
			return "Build Zone"
		3:
			return "Advance Zone"
		4:
			return "Midfield Zone"
		5:
			return "Attack Zone"
		6:
			return "Red Zone"
		7:
			return "Scoring Endzone"
		_:
			return "Unknown Zone"


func resolve_spot_kick(selected_player_id: String, current_zone: int, kick_stats: Dictionary, opponent_mod: int = 0) -> Dictionary:
	var kick_accuracy: int = int(kick_stats.get("kick_accuracy", 5))
	var kick_power: int = int(kick_stats.get("kick_power", 5))
	var kick_consistency: int = int(kick_stats.get("kick_consistency", (kick_accuracy + kick_power) / 2))
	var base_chance := 0
	if current_zone == ZONE_RED:
		base_chance = 75
	elif current_zone == ZONE_ATTACK:
		base_chance = 55
	elif current_zone == ZONE_MIDFIELD and kick_power >= 8:
		base_chance = 35
	else:
		return {
			"play_type": BUCKET_SPOT_KICK,
			"selected_player_id": selected_player_id,
			"success": false,
			"tile_delta": 0,
			"score_delta": 0,
			"possession_switch": true,
			"clock_seconds_used": 0,
			"result_text": "Spot kick unavailable from %s." % _zone_name(current_zone),
			"breakdown": ["Invalid spot kick zone: %s" % _zone_name(current_zone)]
		}

	var target := clampi(base_chance + int((kick_accuracy - 5) * 4.0) + int((kick_power - 5) * 3.0) + int((kick_consistency - 5) * 2.0) - opponent_mod, 5, 95)
	var roll := randi_range(1, 100)
	var success := roll <= target
	return {
		"play_type": BUCKET_SPOT_KICK,
		"selected_player_id": selected_player_id,
		"success": success,
		"tile_delta": 0,
		"score_delta": 3 if success else 0,
		"possession_switch": true,
		"clock_seconds_used": 0,
		"result_text": "Spot kick good" if success else "Missed spot kick",
		"breakdown": [
			"Base spot kick chance: %d" % base_chance,
			"Kicker accuracy bonus: %d" % int((kick_accuracy - 5) * 4.0),
			"Opponent defense: -%d" % opponent_mod,
			"Final roll: %d vs target %d" % [roll, target]
		]
	}


func resolve_extra_point(selected_player_id: String, kick_stats: Dictionary, opponent_mod: int = 0) -> Dictionary:
	var base_chance := 80
	var kick_accuracy: int = int(kick_stats.get("kick_accuracy", 5))
	var kick_power: int = int(kick_stats.get("kick_power", 5))
	var kick_consistency: int = int(kick_stats.get("kick_consistency", (kick_accuracy + kick_power) / 2))
	var target := clampi(
		base_chance
		+ int((kick_accuracy - 5) * 4.0)
		+ int((kick_power - 5) * 3.0)
		+ int((kick_consistency - 5) * 2.0)
		- opponent_mod,
		50, 99
	)
	var roll := randi_range(1, 100)
	var success := roll <= target
	return {
		"play_type": BUCKET_SPOT_KICK,
		"selected_player_id": selected_player_id,
		"success": success,
		"tile_delta": 0,
		"score_delta": 1 if success else 0,
		"possession_switch": true,
		"clock_seconds_used": 0,
		"result_text": "Extra Point Good" if success else "Missed Extra Point",
		"breakdown": [
			"Base XP chance: %d" % base_chance,
			"Kicker accuracy bonus: %d" % int((kick_accuracy - 5) * 4.0),
			"Kicker power bonus: %d" % int((kick_power - 5) * 3.0),
			"Kicker consistency bonus: %d" % int((kick_consistency - 5) * 2.0),
			"Opponent defense: -%d" % opponent_mod,
			"Final roll: %d vs target %d" % [roll, target]
		]
	}


func _punt_normalize_weights(w: Array) -> void:
	var s := 0.0
	for x in w:
		s += float(x)
	if s <= 0.0:
		return
	for i in range(w.size()):
		w[i] = float(w[i]) / s


func _punt_pick_weighted_index(w: Array) -> int:
	var r := randf()
	var c := 0.0
	for i in range(w.size()):
		c += float(w[i])
		if r <= c:
			return i
	return w.size() - 1


func _punt_sample_rows_in_tier(tier: int) -> int:
	match tier:
		0:
			return 0
		1:
			if randf() < 0.68:
				return randi_range(1, 2)
			return randi_range(3, 5)
		2:
			return clampi(6 + int(sqrt(randf()) * 14.0), 6, 19)
		3:
			return randi_range(20, 29)
		4:
			return randi_range(30, _PUNT_RETURN_ROWS_MAX)
	return 0


func _punt_adjusted_tier_weights(m: Dictionary) -> Array:
	var w: Array = []
	for x in _PUNT_RETURN_TIER_BASE:
		w.append(float(x))
	var sp := int(m.get("return_speed", 65))
	var ag := int(m.get("return_agility", 65))
	var ca := int(m.get("return_catching", 60))
	var long_bias := clampf((float(sp + ag + ca) - 195.0) / 220.0, -0.12, 0.14)
	var tk := int(m.get("coverage_tackling", 58))
	var aw := int(m.get("coverage_awareness", 65))
	var cov_bias := clampf((float(tk + aw) - 120.0) / 200.0, -0.10, 0.12)
	var staff_ret := float(m.get("staff_return_bonus", 0)) * 0.004
	var staff_cov := float(m.get("staff_coverage_bonus", 0)) * 0.004
	var card_ret := float(m.get("card_return_bonus", 0)) * 0.003
	var card_cov := float(m.get("card_coverage_bonus", 0)) * 0.003
	long_bias = clampf(long_bias + staff_ret + card_ret, -0.18, 0.22)
	cov_bias = clampf(cov_bias + staff_cov + card_cov, -0.18, 0.22)
	w[0] *= 1.0 + cov_bias * 0.55 - long_bias * 0.35
	w[1] *= 1.0 + cov_bias * 0.35 - long_bias * 0.22
	w[2] *= 1.0 - cov_bias * 0.18 + long_bias * 0.28
	w[3] *= 1.0 - cov_bias * 0.35 + long_bias * 0.45
	w[4] *= 1.0 - cov_bias * 0.45 + long_bias * 0.65
	for i in range(w.size()):
		w[i] = maxf(float(w[i]), 0.0005)
	_punt_normalize_weights(w)
	return w


func _punt_return_tile_rows_from_modifiers(m: Dictionary) -> Dictionary:
	var w := _punt_adjusted_tier_weights(m)
	var tier := _punt_pick_weighted_index(w)
	var rows := _punt_sample_rows_in_tier(tier)
	var tier_label: String
	match tier:
		0:
			tier_label = "0"
		1:
			tier_label = "1–5"
		2:
			tier_label = "6–19"
		3:
			tier_label = "20–39"
		_:
			tier_label = "40+"
	return {"rows": rows, "tier": tier, "tier_label": tier_label, "weights": w}


func _punt_zone_from_engine_row(row: int) -> int:
	var zidx := clampi(row / GameState.TILE_ROWS_PER_ZONE, 0, GameState.MAX_ZONE - 1)
	return clampi(GameState.ZONE_END - zidx, 1, GameState.MAX_ZONE)


func resolve_punt(los_row_engine: int, kick_stats: Dictionary, defense_called_return: bool = false, return_modifiers: Dictionary = {}) -> Dictionary:
	var kick_power: int = int(kick_stats.get("kick_power", 5))
	var kick_accuracy: int = int(kick_stats.get("kick_accuracy", 5))
	var kick_consistency: int = int(kick_stats.get("kick_consistency", (kick_accuracy + kick_power) / 2))
	var punt_rows := randi_range(8, 18) + int((kick_power - 5) * 0.4) + int((kick_consistency - 5) * 0.2)
	punt_rows = clampi(punt_rows, 6, 22)
	var return_rows := 0
	var return_meta := {}
	if defense_called_return:
		return_meta = _punt_return_tile_rows_from_modifiers(return_modifiers)
		return_rows = int(return_meta.get("rows", 0))
		return_rows = clampi(return_rows, 0, _PUNT_RETURN_ROWS_MAX)
	var net_rows := punt_rows - return_rows
	var post_punt_los_row_engine := clampi(los_row_engine - net_rows, 0, GameState.TILE_ROWS_TOTAL - 1)
	var zone_after_offense_view := _punt_zone_from_engine_row(post_punt_los_row_engine)
	var return_line := ("Return: %d tile rows" % return_rows) if defense_called_return else "Return: 0 tile rows (no Punt Return)"
	var bd: Array = [
		"Punt distance: %d rows" % punt_rows,
		return_line,
		"Net: %d rows" % net_rows,
		"Post-punt LOS engine row: %d (zone %d)" % [post_punt_los_row_engine, zone_after_offense_view]
	]
	if defense_called_return and not return_meta.is_empty():
		bd.append(
			"Return tier %s (weights 0|1–5|6–19|20–39|40+: %.2f|%.2f|%.2f|%.2f|%.2f)"
			% [
				str(return_meta.get("tier_label", "?")),
				float(return_meta["weights"][0]),
				float(return_meta["weights"][1]),
				float(return_meta["weights"][2]),
				float(return_meta["weights"][3]),
				float(return_meta["weights"][4])
			]
		)
	return {
		"play_type": PLAY_PUNT,
		"punt_rows": punt_rows,
		"return_rows": return_rows,
		"net_rows": net_rows,
		"post_punt_los_row_engine": post_punt_los_row_engine,
		"zone_after_current_offense": zone_after_offense_view,
		"result_text": "Punt %d tile rows, return %d tile rows, net %d." % [punt_rows, return_rows, net_rows],
		"breakdown": bd
	}
