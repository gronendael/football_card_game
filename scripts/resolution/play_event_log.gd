extends RefCounted
class_name PlayEventLog

var events: Array[Dictionary] = []
var _seq: int = 0


func add(
	code: String,
	message: String,
	actors: Dictionary = {},
	data: Dictionary = {},
	sim_tick: int = -1,
	sim_global_row: int = -1,
	sim_global_col: int = -1
) -> void:
	_seq += 1
	var ev := {
		"code": code,
		"ts": _seq,
		"message": message,
		"actors": actors.duplicate(true),
		"data": data.duplicate(true),
	}
	if sim_tick >= 0:
		ev["tick"] = sim_tick
	if sim_global_row >= 0:
		ev["global_row"] = sim_global_row
	if sim_global_col >= 0:
		ev["global_col"] = sim_global_col
	events.append(ev)


func to_breakdown_strings() -> Array[String]:
	var out: Array[String] = []
	for e in events:
		out.append(str(e.get("message", "")))
	return out
