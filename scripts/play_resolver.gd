extends Node
class_name PlayResolver

const PLAY_RUN := "run"
const PLAY_SHORT_PASS := "short_pass"
const PLAY_DEEP_PASS := "deep_pass"
const PLAY_FIELD_GOAL := "field_goal"

func resolve_standard_play(play_type: String, selected_player_id: String, current_zone: int) -> Dictionary:
	var zone_delta := 0
	match play_type:
		PLAY_RUN:
			zone_delta = randi_range(0, 2)
		PLAY_SHORT_PASS:
			zone_delta = randi_range(0, 2)
		PLAY_DEEP_PASS:
			zone_delta = randi_range(0, 3)
		_:
			zone_delta = 0

	var success := zone_delta > 0
	var seconds_used := randi_range(5, 8)
	var breakdown := [
		"Play type: %s" % play_type,
		"Selected player: %s" % selected_player_id,
		"Random zone gain: +%d" % zone_delta,
		"Clock burned: %ds" % seconds_used
	]
	return {
		"play_type": play_type,
		"selected_player_id": selected_player_id,
		"success": success,
		"zone_delta": zone_delta,
		"score_delta": 0,
		"possession_switch": false,
		"clock_seconds_used": seconds_used,
		"result_text": "%s gained %d zone(s)." % [play_type, zone_delta],
		"breakdown": breakdown
	}

func resolve_field_goal(selected_player_id: String, current_zone: int, kick_stats: Dictionary, opponent_mod: int = 0) -> Dictionary:
	var base_chance := 0
	if current_zone == 6:
		base_chance = 75
	elif current_zone == 5:
		base_chance = 55
	elif current_zone == 4:
		base_chance = 35
	else:
		return {
			"play_type": PLAY_FIELD_GOAL,
			"selected_player_id": selected_player_id,
			"success": false,
			"zone_delta": 0,
			"score_delta": 0,
			"possession_switch": true,
			"clock_seconds_used": randi_range(5, 8),
			"result_text": "Field Goal unavailable from this zone.",
			"breakdown": ["Invalid field goal zone"]
		}

	var kick_accuracy: int = int(kick_stats.get("kick_accuracy", 50))
	var kick_power: int = int(kick_stats.get("kick_power", 50))
	var kick_consistency: int = int(kick_stats.get("kick_consistency", 50))
	var target := clampi(base_chance + int((kick_accuracy - 50) * 0.5) + int((kick_power - 50) * 0.2) + int((kick_consistency - 50) * 0.3) - opponent_mod, 5, 95)
	var roll := randi_range(1, 100)
	var success := roll <= target
	var seconds_used := randi_range(5, 8)
	return {
		"play_type": PLAY_FIELD_GOAL,
		"selected_player_id": selected_player_id,
		"success": success,
		"zone_delta": 0,
		"score_delta": 3 if success else 0,
		"possession_switch": true,
		"clock_seconds_used": seconds_used,
		"result_text": "Field Goal Good" if success else "Missed Field Goal",
		"breakdown": [
			"Base field goal chance: %d" % base_chance,
			"Kicker accuracy bonus: %d" % int((kick_accuracy - 50) * 0.5),
			"Opponent defense: -%d" % opponent_mod,
			"Final roll: %d vs target %d" % [roll, target]
		]
	}
