extends Node
class_name TargetingManager

func get_valid_targets(card: Dictionary, context: Dictionary) -> Array[Dictionary]:
	var target_type := str(card.get("target_type", "global"))
	var targets: Array[Dictionary] = []
	var my_team: Array = context.get("my_team_players", [])
	var opp_team: Array = context.get("opponent_players", [])
	var staff: Dictionary = context.get("staff", {})

	match target_type:
		"self_player":
			for p in my_team:
				targets.append({"type": "player", "id": p.get("id", ""), "team": "home"})
		"opponent_player":
			for p in opp_team:
				targets.append({"type": "player", "id": p.get("id", ""), "team": "away"})
		"self_team":
			targets.append({"type": "team", "id": "home"})
		"opponent_team":
			targets.append({"type": "team", "id": "away"})
		"head_coach", "offensive_coordinator", "defensive_coordinator":
			if staff.has(target_type):
				targets.append({"type": "staff", "id": staff[target_type].get("id", ""), "role": target_type})
		"play_type":
			for play_type in ["run", "pass", "spot_kick"]:
				targets.append({"type": "play_type", "id": play_type})
		_:
			targets.append({"type": "global", "id": "global"})

	return targets
