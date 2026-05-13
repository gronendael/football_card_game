extends RefCounted
class_name PlayerStatView

## Stat-only view: roster JSON uses **1–10** integers per `Properties.md` keys.
var id: String = ""
var name: String = ""
var raw: Dictionary = {}


static func display_name_from_dict(d: Dictionary) -> String:
	var fn := str(d.get("first_name", "")).strip_edges()
	var ln := str(d.get("last_name", "")).strip_edges()
	if not fn.is_empty() or not ln.is_empty():
		return (fn + " " + ln).strip_edges()
	return str(d.get("name", d.get("id", "")))


static func from_dict(d: Dictionary) -> PlayerStatView:
	var v := PlayerStatView.new()
	v.raw = d
	v.id = str(d.get("id", ""))
	v.name = display_name_from_dict(d)
	return v


func _raw_int(key: String, default_v: int = 5) -> int:
	return int(raw.get(key, default_v))


## Data is already 1–10; clamp for safety.
func s10_from_key(key: String, default_v: int = 5) -> int:
	return clampi(_raw_int(key, default_v), 1, 10)


func speed() -> int:
	return s10_from_key("speed")


func strength() -> int:
	return s10_from_key("strength")


func stamina() -> int:
	return s10_from_key("stamina")


func awareness() -> int:
	return s10_from_key("awareness")


func agility() -> int:
	return s10_from_key("agility")


func catching() -> int:
	return s10_from_key("catching")


func tackling() -> int:
	return s10_from_key("tackling")


func toughness() -> int:
	return s10_from_key("toughness")


func blocking() -> int:
	return s10_from_key("blocking")


func route_running() -> int:
	return s10_from_key("route_running")


func coverage() -> int:
	return s10_from_key("coverage")


func carrying() -> int:
	if raw.has("carrying"):
		return s10_from_key("carrying")
	return s10_from_key("ball_security")


func throw_power() -> int:
	if raw.has("throw_power"):
		return s10_from_key("throw_power")
	return s10_from_key("passing")


func throw_accuracy() -> int:
	if raw.has("throw_accuracy"):
		return s10_from_key("throw_accuracy")
	return s10_from_key("passing")


func pass_rush() -> int:
	if raw.has("pass_rush"):
		return s10_from_key("pass_rush")
	var blended := int(round((float(s10_from_key("strength")) + float(s10_from_key("tackling"))) * 0.5))
	return clampi(blended, 1, 10)


func block_shedding() -> int:
	if raw.has("block_shedding"):
		return s10_from_key("block_shedding")
	var blended := int(round((float(s10_from_key("strength")) + float(s10_from_key("tackling"))) * 0.5))
	return clampi(blended, 1, 10)


func acceleration() -> int:
	if raw.has("acceleration"):
		return s10_from_key("acceleration")
	return s10_from_key("agility")


func kick_power() -> int:
	return s10_from_key("kick_power")


func kick_accuracy() -> int:
	return s10_from_key("kick_accuracy")
