extends RefCounted
class_name ZoneCoverageProfile

## Tuning knobs for cover_zone (hardcoded v1).

var depth_mult: float = 1.0
var prefer_deep_bonus: float = 0.0
var prefer_shallow_bonus: float = 0.0
var width_penalty_scale: float = 0.12
var aggression: float = 1.0
var reaction_delay_ticks: int = 0
var anchor_max_row: int = 3
var anchor_max_col: int = 1


static func for_role(role: String) -> ZoneCoverageProfile:
	var r := role.to_upper()
	var p := ZoneCoverageProfile.new()
	if r.begins_with("S"):
		p.depth_mult = 1.25
		p.prefer_deep_bonus = 2.0
		p.aggression = 0.75
		p.anchor_max_row = 4
		p.reaction_delay_ticks = 0
	elif r.begins_with("CB"):
		p.depth_mult = 1.0
		p.width_penalty_scale = 0.18
		p.aggression = 1.0
		p.anchor_max_row = 3
	elif r.begins_with("LB"):
		p.depth_mult = 0.9
		p.prefer_shallow_bonus = 1.5
		p.aggression = 1.25
		p.anchor_max_row = 3
		p.reaction_delay_ticks = 1
	elif r.begins_with("DL"):
		p.depth_mult = 0.85
		p.prefer_shallow_bonus = 2.0
		p.aggression = 1.15
		p.anchor_max_row = 2
		p.anchor_max_col = 1
		p.reaction_delay_ticks = 2
	else:
		p.depth_mult = 1.0
		p.aggression = 1.0
	return p
