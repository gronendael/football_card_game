extends Node
class_name PlayResolver

const PLAY_RUN := "run"
const PLAY_SHORT_PASS := "short_pass"
const PLAY_DEEP_PASS := "deep_pass"
const PLAY_SPOT_KICK := "spot_kick"
const PLAY_PUNT := "punt"
const ZONE_MIDFIELD := 4
const ZONE_ATTACK := 5
const ZONE_RED := 6

## Tier weights: 0 rows | 1–5 | 6–19 | 20–39 | 40+ tile rows (1 row ≈ 1 yd). Tuned ~NFL-ish; shifted by modifiers.
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

func resolve_standard_play(play_type: String, selected_player_id: String, current_zone: int) -> Dictionary:
	var tile_delta := 0
	match play_type:
		PLAY_RUN:
			tile_delta = randi_range(0, 10)
		PLAY_SHORT_PASS:
			tile_delta = randi_range(0, 10)
		PLAY_DEEP_PASS:
			tile_delta = randi_range(0, 15)
		_:
			tile_delta = 0

	var success := tile_delta > 0
	var breakdown := [
		"Play type: %s" % play_type,
		"Selected player: %s" % selected_player_id,
		"Tile rows toward goal: +%d" % tile_delta
	]
	return {
		"play_type": play_type,
		"selected_player_id": selected_player_id,
		"success": success,
		"tile_delta": tile_delta,
		"score_delta": 0,
		"possession_switch": false,
		"clock_seconds_used": 0,
		"result_text": "%s: %+d tile rows toward goal." % [play_type, tile_delta],
		"breakdown": breakdown
	}

func resolve_spot_kick(selected_player_id: String, current_zone: int, kick_stats: Dictionary, opponent_mod: int = 0) -> Dictionary:
	var kick_accuracy: int = int(kick_stats.get("kick_accuracy", 50))
	var kick_power: int = int(kick_stats.get("kick_power", 50))
	var kick_consistency: int = int(kick_stats.get("kick_consistency", 50))
	var base_chance := 0
	if current_zone == ZONE_RED:
		base_chance = 75
	elif current_zone == ZONE_ATTACK:
		base_chance = 55
	elif current_zone == ZONE_MIDFIELD and kick_power > 80:
		base_chance = 35
	else:
		return {
			"play_type": PLAY_SPOT_KICK,
			"selected_player_id": selected_player_id,
			"success": false,
			"tile_delta": 0,
			"score_delta": 0,
			"possession_switch": true,
			"clock_seconds_used": 0,
			"result_text": "Spot kick unavailable from %s." % _zone_name(current_zone),
			"breakdown": ["Invalid spot kick zone: %s" % _zone_name(current_zone)]
		}

	var target := clampi(base_chance + int((kick_accuracy - 50) * 0.5) + int((kick_power - 50) * 0.2) + int((kick_consistency - 50) * 0.3) - opponent_mod, 5, 95)
	var roll := randi_range(1, 100)
	var success := roll <= target
	return {
		"play_type": PLAY_SPOT_KICK,
		"selected_player_id": selected_player_id,
		"success": success,
		"tile_delta": 0,
		"score_delta": 3 if success else 0,
		"possession_switch": true,
		"clock_seconds_used": 0,
		"result_text": "Spot kick good" if success else "Missed spot kick",
		"breakdown": [
			"Base spot kick chance: %d" % base_chance,
			"Kicker accuracy bonus: %d" % int((kick_accuracy - 50) * 0.5),
			"Opponent defense: -%d" % opponent_mod,
			"Final roll: %d vs target %d" % [roll, target]
		]
	}

func resolve_extra_point(selected_player_id: String, kick_stats: Dictionary, opponent_mod: int = 0) -> Dictionary:
	var base_chance := 80
	var kick_accuracy: int = int(kick_stats.get("kick_accuracy", 50))
	var kick_power: int = int(kick_stats.get("kick_power", 50))
	var kick_consistency: int = int(kick_stats.get("kick_consistency", 50))
	var target := clampi(
		base_chance
		+ int((kick_accuracy - 50) * 0.5)
		+ int((kick_power - 50) * 0.2)
		+ int((kick_consistency - 50) * 0.3)
		- opponent_mod,
		50, 99
	)
	var roll := randi_range(1, 100)
	var success := roll <= target
	return {
		"play_type": PLAY_SPOT_KICK,
		"selected_player_id": selected_player_id,
		"success": success,
		"tile_delta": 0,
		"score_delta": 1 if success else 0,
		"possession_switch": true,
		"clock_seconds_used": 0,
		"result_text": "Extra Point Good" if success else "Missed Extra Point",
		"breakdown": [
			"Base XP chance: %d" % base_chance,
			"Kicker accuracy bonus: %d" % int((kick_accuracy - 50) * 0.5),
			"Kicker power bonus: %d" % int((kick_power - 50) * 0.2),
			"Kicker consistency bonus: %d" % int((kick_consistency - 50) * 0.3),
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
	## Short tiers: more mass when coverage is strong / returner weak.
	w[0] *= 1.0 + cov_bias * 0.55 - long_bias * 0.35
	w[1] *= 1.0 + cov_bias * 0.35 - long_bias * 0.22
	## Mid / long: more mass when returner is strong / coverage weak.
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


func resolve_punt(current_zone: int, kick_stats: Dictionary, defense_called_return: bool = false, return_modifiers: Dictionary = {}) -> Dictionary:
	var kick_power: int = int(kick_stats.get("kick_power", 50))
	var kick_consistency: int = int(kick_stats.get("kick_consistency", 50))
	var punt_rows := randi_range(8, 18) + int((kick_power - 50) * 0.08) + int((kick_consistency - 50) * 0.04)
	punt_rows = clampi(punt_rows, 6, 22)
	var return_rows := 0
	var return_meta := {}
	if defense_called_return:
		return_meta = _punt_return_tile_rows_from_modifiers(return_modifiers)
		return_rows = int(return_meta.get("rows", 0))
		return_rows = clampi(return_rows, 0, _PUNT_RETURN_ROWS_MAX)
	var net_rows := maxi(punt_rows - return_rows, 3)
	var zone_delta := maxi(int(round(float(net_rows) / 5.0)), 1)
	var zone_after_offense_view := clampi(current_zone + zone_delta, 1, 7)
	var return_line := ("Return: %d tile rows" % return_rows) if defense_called_return else "Return: 0 tile rows (no Punt Return)"
	var bd: Array = [
		"Punt distance: %d rows" % punt_rows,
		return_line,
		"Net: %d rows" % net_rows
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
		"zone_after_current_offense": zone_after_offense_view,
		"result_text": "Punt %d tile rows, return %d tile rows, net %d." % [punt_rows, return_rows, net_rows],
		"breakdown": bd
	}
