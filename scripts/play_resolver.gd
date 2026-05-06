extends Node
class_name PlayResolver

const PLAY_RUN := "run"
const PLAY_SHORT_PASS := "short_pass"
const PLAY_DEEP_PASS := "deep_pass"
const PLAY_FIELD_GOAL := "field_goal"
const ZONE_MIDFIELD := 4
const ZONE_ATTACK := 5
const ZONE_RED := 6

func _zone_name(zone: int) -> String:
	match zone:
		1:
			return "MyEndZone"
		2:
			return "StartZone"
		3:
			return "AdvanceZone"
		4:
			return "MidfieldZone"
		5:
			return "AttackZone"
		6:
			return "RedZone"
		7:
			return "EndZone"
		_:
			return "UnknownZone"

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
	var breakdown := [
		"Play type: %s" % play_type,
		"Selected player: %s" % selected_player_id,
		"Random zone gain: +%d" % zone_delta
	]
	return {
		"play_type": play_type,
		"selected_player_id": selected_player_id,
		"success": success,
		"zone_delta": zone_delta,
		"score_delta": 0,
		"possession_switch": false,
		"clock_seconds_used": 0,
		"result_text": "%s gained %d zone(s)." % [play_type, zone_delta],
		"breakdown": breakdown
	}

func resolve_field_goal(selected_player_id: String, current_zone: int, kick_stats: Dictionary, opponent_mod: int = 0) -> Dictionary:
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
			"play_type": PLAY_FIELD_GOAL,
			"selected_player_id": selected_player_id,
			"success": false,
			"zone_delta": 0,
			"score_delta": 0,
			"possession_switch": true,
			"clock_seconds_used": 0,
			"result_text": "Field Goal unavailable from %s." % _zone_name(current_zone),
			"breakdown": ["Invalid field goal zone: %s" % _zone_name(current_zone)]
		}

	var target := clampi(base_chance + int((kick_accuracy - 50) * 0.5) + int((kick_power - 50) * 0.2) + int((kick_consistency - 50) * 0.3) - opponent_mod, 5, 95)
	var roll := randi_range(1, 100)
	var success := roll <= target
	return {
		"play_type": PLAY_FIELD_GOAL,
		"selected_player_id": selected_player_id,
		"success": success,
		"zone_delta": 0,
		"score_delta": 3 if success else 0,
		"possession_switch": true,
		"clock_seconds_used": 0,
		"result_text": "Field Goal Good" if success else "Missed Field Goal",
		"breakdown": [
			"Base field goal chance: %d" % base_chance,
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
		"play_type": "extra_point",
		"selected_player_id": selected_player_id,
		"success": success,
		"zone_delta": 0,
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
