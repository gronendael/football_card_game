extends RefCounted
class_name PlayEventLog

var events: Array[Dictionary] = []
var _seq: int = 0


func add(code: String, message: String, actors: Dictionary = {}, data: Dictionary = {}) -> void:
	_seq += 1
	events.append({
		"code": code,
		"ts": _seq,
		"message": message,
		"actors": actors.duplicate(true),
		"data": data.duplicate(true),
	})


func to_breakdown_strings() -> Array[String]:
	var out: Array[String] = []
	for e in events:
		out.append(str(e.get("message", "")))
	return out
