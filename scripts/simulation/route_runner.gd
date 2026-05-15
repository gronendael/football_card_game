extends RefCounted
class_name RouteRunner


static func init_route_state(st: SimPlayerState) -> void:
	st.route_waypoint_index = 0
	st.route_stem_dir = Vector2i(0, -1)


static func compute_move_cell(st: SimPlayerState) -> Vector2i:
	if st.intent_action != "route":
		return st.grid_pos()
	var from := st.grid_pos()
	var target := _segment_target(st, from)
	var cell := ScrimmageSimCalculators.step_toward(from, target)
	if cell == target:
		_advance_waypoint(st)
	elif cell != from:
		st.route_stem_dir = cell - from
	return cell


static func _segment_target(st: SimPlayerState, from: Vector2i) -> Vector2i:
	if st.route_waypoint_index < st.route_waypoints.size():
		return from + st.route_waypoints[st.route_waypoint_index]
	return from + st.route_stem_dir


static func _advance_waypoint(st: SimPlayerState) -> void:
	if st.route_waypoint_index < st.route_waypoints.size():
		var seg: Vector2i = st.route_waypoints[st.route_waypoint_index]
		if seg != Vector2i.ZERO:
			st.route_stem_dir = seg
		st.route_waypoint_index += 1
