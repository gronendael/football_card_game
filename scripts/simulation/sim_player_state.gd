extends RefCounted
class_name SimPlayerState

var player_id: String = ""
var role: String = ""
## "off" or "def"
var side: String = "off"
var global_row: int = 0
var global_col: int = 0
var intent_action: String = ""
var active_state: String = "idle"
var engaged_with_player_id: String = ""
## Step deltas (col, row); row negative = toward scoring end.
var route_waypoints: Array[Vector2i] = []
var facing: Vector2i = Vector2i(0, -1)
## Progressive penalty after broken tackles (spec).
var broken_tackle_chain: int = 0
## Assigned man coverage target (defender player_id).
var man_cover_target_id: String = ""
var separation_tier: String = SimConstants.SEP_OPEN


func grid_pos() -> Vector2i:
	return Vector2i(global_col, global_row)


func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"role": role,
		"side": side,
		"global_row": global_row,
		"global_col": global_col,
		"intent_action": intent_action,
		"active_state": active_state,
		"engaged_with_player_id": engaged_with_player_id,
		"facing_col": facing.x,
		"facing_row": facing.y,
		"man_cover_target_id": man_cover_target_id,
		"separation_tier": separation_tier,
		"broken_tackle_chain": broken_tackle_chain,
	}
