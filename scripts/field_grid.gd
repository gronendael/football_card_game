extends Node2D
class_name FieldGrid

const ZONE_COUNT := 7
const ROWS_PER_ZONE := 5
const COLS := 7
const TOTAL_ROWS := ZONE_COUNT * ROWS_PER_ZONE
const SPEED_DIVISOR := 20.0

@export var show_tile_overlay: bool = true
@export var overlay_alpha: float = 0.14
## True = no row flip when home has the ball. GameScene sets this to (_user_team == "home") so the local player always attacks toward the top of the field.
@export var is_user_perspective_home: bool = true

@onready var field_background: ColorRect = $FieldBackground
@onready var tile_layer: Node2D = $TileLayer

var tile_width: float = 0.0
var tile_height: float = 0.0
var tile_lookup: Dictionary = {}

func _ready() -> void:
	_refresh_metrics()
	_rebuild_overlay()
	_sync_overlay_config()

func _refresh_metrics() -> void:
	tile_width = field_background.size.x / float(COLS)
	tile_height = field_background.size.y / float(TOTAL_ROWS)

func _rebuild_overlay() -> void:
	for child in tile_layer.get_children():
		child.queue_free()
	tile_lookup.clear()
	for global_row in range(TOTAL_ROWS):
		for col in range(COLS):
			var zone := global_row / ROWS_PER_ZONE
			var zone_row := global_row % ROWS_PER_ZONE
			var tile_data := {
				"zone": zone,
				"zone_row": zone_row,
				"global_row": global_row,
				"col": col
			}
			tile_lookup[_tile_key(global_row, col)] = tile_data
	_sync_overlay_config()

func zone_to_row_range(zone: int) -> Vector2i:
	var clamped_zone := clampi(zone, 0, ZONE_COUNT - 1)
	var start_row := clamped_zone * ROWS_PER_ZONE
	return Vector2i(start_row, start_row + ROWS_PER_ZONE - 1)

func tile_coord(zone: int, zone_row: int, col: int) -> Vector2i:
	var clamped_zone := clampi(zone, 0, ZONE_COUNT - 1)
	var clamped_zone_row := clampi(zone_row, 0, ROWS_PER_ZONE - 1)
	var clamped_col := clampi(col, 0, COLS - 1)
	return Vector2i(clamped_zone * ROWS_PER_ZONE + clamped_zone_row, clamped_col)

func tile_id(global_row: int, col: int) -> Dictionary:
	var clamped_row := clampi(global_row, 0, TOTAL_ROWS - 1)
	var clamped_col := clampi(col, 0, COLS - 1)
	var zone := clamped_row / ROWS_PER_ZONE
	var zone_row := clamped_row % ROWS_PER_ZONE
	return {
		"zone": zone,
		"zone_row": zone_row,
		"global_row": clamped_row,
		"col": clamped_col
	}

func world_pos_from_tile(global_row: int, col: int) -> Vector2:
	var clamped_row := clampi(global_row, 0, TOTAL_ROWS - 1)
	var clamped_col := clampi(col, 0, COLS - 1)
	return Vector2(
		(float(clamped_col) + 0.5) * tile_width,
		(float(clamped_row) + 0.5) * tile_height
	)

func tile_data_from_los(los_row: int, row_offset: int, col_offset: int, base_col: int = 3) -> Dictionary:
	var rel_row := los_row + row_offset
	var rel_col := base_col + col_offset
	return tile_id(rel_row, rel_col)

func world_pos_from_los(los_row: int, row_offset: int, col_offset: int, base_col: int = 3) -> Vector2:
	var data := tile_data_from_los(los_row, row_offset, col_offset, base_col)
	return world_pos_from_tile(int(data.get("global_row", 0)), int(data.get("col", 0)))

func perspective_row(global_row: int, offense_is_home: bool) -> int:
	var row := clampi(global_row, 0, TOTAL_ROWS - 1)
	var should_flip := offense_is_home != is_user_perspective_home
	if should_flip:
		return (TOTAL_ROWS - 1) - row
	return row

func tiles_per_step_from_speed(speed: float) -> int:
	return maxi(1, int(floor(speed / SPEED_DIVISOR)))

func get_tile_data(global_row: int, col: int) -> Dictionary:
	var key := _tile_key(clampi(global_row, 0, TOTAL_ROWS - 1), clampi(col, 0, COLS - 1))
	if tile_lookup.has(key):
		return tile_lookup[key]
	return tile_id(global_row, col)

## Display-space tile rows after perspective_row. first_down_* = -1 hides first-down band. goal_to_go_* = -1 hides goal-to-go endzone fill.
func set_field_line_display_rows(los_row: int, first_down_start_row: int, first_down_end_row: int, goal_to_go_start_row: int = -1, goal_to_go_end_row: int = -1) -> void:
	var los_clamped := clampi(los_row, 0, TOTAL_ROWS - 1)
	var fd0 := first_down_start_row
	var fd1 := first_down_end_row
	var g0 := goal_to_go_start_row
	var g1 := goal_to_go_end_row
	if g0 >= 0 and g1 >= 0:
		g0 = clampi(g0, 0, TOTAL_ROWS - 1)
		g1 = clampi(g1, 0, TOTAL_ROWS - 1)
		if g1 < g0:
			var tg := g0
			g0 = g1
			g1 = tg
	if fd0 >= 0 and fd1 >= 0:
		fd0 = clampi(fd0, 0, TOTAL_ROWS - 1)
		fd1 = clampi(fd1, 0, TOTAL_ROWS - 1)
		if fd1 < fd0:
			var t := fd0
			fd0 = fd1
			fd1 = t
	else:
		fd0 = -1
		fd1 = -1
	_set_overlay_markers(los_clamped, fd0, fd1, g0, g1)

func _tile_key(global_row: int, col: int) -> String:
	return "%d:%d" % [global_row, col]

func _sync_overlay_config() -> void:
	if tile_layer == null or not tile_layer.has_method("configure_grid"):
		return
	tile_layer.call("configure_grid", show_tile_overlay, overlay_alpha, COLS, TOTAL_ROWS, tile_width, tile_height)

func _set_overlay_markers(los_row: int, first_down_start_row: int, first_down_end_row: int, goal_to_go_start_row: int = -1, goal_to_go_end_row: int = -1) -> void:
	if tile_layer == null or not tile_layer.has_method("set_markers"):
		return
	tile_layer.call("set_markers", los_row, first_down_start_row, first_down_end_row, goal_to_go_start_row, goal_to_go_end_row)
