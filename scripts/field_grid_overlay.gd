extends Node2D
class_name FieldGridOverlay

var show_tile_overlay: bool = true
var overlay_alpha: float = 0.14
var cols: int = 7
var total_rows: int = 35
var tile_width: float = 0.0
var tile_height: float = 0.0
var first_down_start_row: int = -1
var first_down_end_row: int = -1
var goal_to_go_start_row: int = -1
var goal_to_go_end_row: int = -1
var los_row: int = -1

func configure_grid(p_show_tile_overlay: bool, p_overlay_alpha: float, p_cols: int, p_total_rows: int, p_tile_width: float, p_tile_height: float) -> void:
	show_tile_overlay = p_show_tile_overlay
	overlay_alpha = p_overlay_alpha
	cols = p_cols
	total_rows = p_total_rows
	tile_width = p_tile_width
	tile_height = p_tile_height
	queue_redraw()

func set_markers(p_los_row: int, p_first_down_start_row: int, p_first_down_end_row: int, p_goal_to_go_start_row: int = -1, p_goal_to_go_end_row: int = -1) -> void:
	los_row = p_los_row
	first_down_start_row = p_first_down_start_row
	first_down_end_row = p_first_down_end_row
	goal_to_go_start_row = p_goal_to_go_start_row
	goal_to_go_end_row = p_goal_to_go_end_row
	queue_redraw()

func _draw() -> void:
	if not show_tile_overlay:
		return
	var field_w := float(cols) * tile_width
	var field_h := float(total_rows) * tile_height
	if goal_to_go_start_row >= 0 and goal_to_go_end_row >= goal_to_go_start_row:
		var gtop := float(goal_to_go_start_row) * tile_height
		var gheight := float(goal_to_go_end_row - goal_to_go_start_row + 1) * tile_height
		var g_rect := Rect2(0.0, gtop, field_w, gheight)
		draw_rect(g_rect, Color(0.85, 0.70, 0.05, 0.50), true)
		draw_rect(g_rect, Color(0.65, 0.50, 0.02, 0.90), false, 2.0)
	elif first_down_start_row >= 0 and first_down_end_row >= first_down_start_row:
		var top := float(first_down_start_row) * tile_height
		var height := float(first_down_end_row - first_down_start_row + 1) * tile_height
		var first_rect := Rect2(0.0, top, field_w, height)
		draw_rect(first_rect, Color(0.85, 0.70, 0.05, 0.50), true)
		draw_rect(first_rect, Color(0.65, 0.50, 0.02, 0.90), false, 2.0)
	if los_row >= 0:
		var los_top := float(los_row) * tile_height
		var los_rect := Rect2(0.0, los_top, field_w, tile_height)
		draw_rect(los_rect, Color(0.05, 0.25, 0.85, 0.60), true)
		draw_rect(los_rect, Color(0.02, 0.15, 0.65, 0.95), false, 2.0)
	for global_row in range(total_rows):
		for col in range(cols):
			var tile_rect := Rect2(float(col) * tile_width, float(global_row) * tile_height, tile_width, tile_height)
			draw_rect(tile_rect, Color(1.0, 1.0, 1.0, overlay_alpha * 0.35), true)
	var line_color := Color(1.0, 1.0, 1.0, 0.55)
	for c in range(cols + 1):
		var x := float(c) * tile_width
		draw_line(Vector2(x, 0.0), Vector2(x, field_h), line_color, 1.0)
	for r in range(total_rows + 1):
		var y := float(r) * tile_height
		draw_line(Vector2(0.0, y), Vector2(field_w, y), line_color, 1.0)
