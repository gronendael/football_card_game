extends RefCounted
class_name PlayCreatorValidators

const ROUTE_ROLES := ["RB", "WR", "TE"]
const OFFENSE_ACTIONS := ["run_block", "pass_block", "route", "carry", "drop_back", "handoff_mesh"]
const QB_MODES := ["handoff", "dropback_progression", "quick_throw"]


static func validate_play_dict(play_id: String, d: Dictionary, formations: FormationsCatalog) -> String:
	if play_id.strip_edges().is_empty():
		return "Play id is required."
	if str(d.get("name", "")).strip_edges().is_empty():
		return "Name is required."
	var side := str(d.get("side", ""))
	if side not in ["offense", "defense", "special"]:
		return "Side must be offense, defense, or special."
	var ptype := str(d.get("play_type", ""))
	if ptype.is_empty():
		return "Play type is required."
	var fid := str(d.get("formation_id", ""))
	if fid.is_empty():
		return "Formation is required."
	var form := formations.get_by_id(fid)
	if form.is_empty():
		return "Unknown formation_id: %s" % fid
	var form_side := str(form.get("side", ""))
	if form_side != side and not (side == "special" and form_side == "special"):
		return "Formation side (%s) does not match play side (%s)." % [form_side, side]
	if side == "offense" and ptype in ["run", "pass"]:
		var prog: Dictionary = d.get("receiver_progression", {}) as Dictionary
		for slot in ["primary", "secondary", "tertiary"]:
			var role := str(prog.get(slot, ""))
			if ptype == "pass" and role.is_empty() and slot == "primary":
				continue
			if not role.is_empty() and not _role_on_formation(form, role):
				return "Progression %s role %s not on formation." % [slot, role]
		var bcr := str(d.get("ball_carrier_role", ""))
		if ptype == "run" and not bcr.is_empty() and not _role_on_formation(form, bcr):
			return "Ball carrier role not on formation."
	return ""


static func _role_on_formation(form: Dictionary, role: String) -> bool:
	for p in form.get("positions", []) as Array:
		if typeof(p) == TYPE_DICTIONARY and str((p as Dictionary).get("role", "")) == role:
			return true
	return false


static func is_route_role(role: String) -> bool:
	var ru := role.to_upper()
	return ru.begins_with("RB") or ru.begins_with("WR") or ru.begins_with("TE")
