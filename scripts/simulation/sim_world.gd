extends RefCounted
class_name SimWorld

var tick_index: int = 0
var los_row_engine: int = 0
var possession_team: String = "home"
var ball_state: String = SimConstants.BALL_IN_POSSESSION
var ball_carrier_id: String = ""
var qb_id: String = ""
var play_bucket: String = ""
var players: Dictionary = {} ## id -> SimPlayerState
var play_end_reason: String = ""
var carrier_start_row: int = 0
var contact_cooldown: int = 0
var last_tackler_id: String = ""
## Latest pass-front sample during tick sim dropback (used at throw).
var last_pass_rush: Dictionary = {}
var last_pass_pressure: int = 0
var last_pass_protection: float = 18.0
## Set after pass resolves (tick-authoritative pass path).
var pending_pass_inner: Dictionary = {}


static func zone_from_engine_row(row: int) -> int:
	var zidx: int = clampi(row / 5, 0, 6)
	return clampi(7 - zidx, 1, 7)


func get_player(pid: String) -> SimPlayerState:
	if not players.has(pid):
		return null
	return players[pid] as SimPlayerState


func all_players_array() -> Array[SimPlayerState]:
	var out: Array[SimPlayerState] = []
	for k in players.keys():
		var p: SimPlayerState = players[k] as SimPlayerState
		if p != null:
			out.append(p)
	return out


func snapshot() -> Dictionary:
	var plist: Array = []
	for p in all_players_array():
		plist.append(p.to_dict())
	return {
		"tick": tick_index,
		"los_row_engine": los_row_engine,
		"possession_team": possession_team,
		"play_bucket": play_bucket,
		"ball_state": ball_state,
		"ball_carrier_id": ball_carrier_id,
		"play_end_reason": play_end_reason,
		"pass_pressure": last_pass_pressure,
		"players": plist,
	}
