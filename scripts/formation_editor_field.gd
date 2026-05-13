extends Panel
class_name FormationEditorField

const DND := FormationEditorCell.DND
const ROWS := 20
const COLS := 7
const LOS_ROW := 10
const CENTER_COL := 3

signal placements_changed(count: int)

var formation_shell: String = FormationsCatalog.FORMATION_SHELL_SCRIMMAGE_OFFENSE

var _grid: GridContainer
var _cells: Array[FormationEditorCell] = []


func _ready() -> void:
	_build_ui()


func set_formation_shell(shell: String) -> void:
	formation_shell = shell
	_rebuild_cells()


func _uses_circle_tokens() -> bool:
	match formation_shell:
		FormationsCatalog.FORMATION_SHELL_SCRIMMAGE_OFFENSE, FormationsCatalog.FORMATION_SHELL_KICK_FG_XP, FormationsCatalog.FORMATION_SHELL_PUNT, FormationsCatalog.FORMATION_SHELL_KICKOFF:
			return true
		_:
			return false


func _build_ui() -> void:
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(outer)
	_grid = GridContainer.new()
	_grid.columns = COLS
	outer.add_child(_grid)
	_rebuild_cells()


func _rebuild_cells() -> void:
	for c in _cells:
		if is_instance_valid(c):
			c.queue_free()
	_cells.clear()
	var circ := _uses_circle_tokens()
	for r in ROWS:
		for c in COLS:
			var cell := FormationEditorCell.new()
			cell.setup(self, r, c, circ, r == LOS_ROW)
			_grid.add_child(cell)
			_cells.append(cell)


func load_from_positions(positions: Array) -> void:
	clear_field()
	for p in positions:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var pd: Dictionary = p
		var role := str(pd.get("role", ""))
		var dr := int(pd.get("delta_row", 0))
		var dc := int(pd.get("delta_col", 0))
		var gr := LOS_ROW + dr
		var gc := CENTER_COL + dc
		var cell := _cell_at(gr, gc)
		if cell:
			cell.set_role(role)
	placements_changed.emit(_count_placed())


func clear_field() -> void:
	for cell in _cells:
		cell.clear_role()
	placements_changed.emit(0)


func _cell_at(gr: int, gc: int) -> FormationEditorCell:
	if gr < 0 or gr >= ROWS or gc < 0 or gc >= COLS:
		return null
	var idx := gr * COLS + gc
	if idx < 0 or idx >= _cells.size():
		return null
	return _cells[idx]


func _count_placed() -> int:
	var n := 0
	for cell in _cells:
		if not cell.role.is_empty():
			n += 1
	return n


func count_role_on_field(role_key: String) -> int:
	if role_key.is_empty():
		return 0
	var n := 0
	for cell in _cells:
		if cell.role == role_key:
			n += 1
	return n


func apply_drop(from_row: int, from_col: int, to_row: int, to_col: int, role: String) -> void:
	if to_row < 0 or to_col < 0:
		if from_row >= 0:
			var fc := _cell_at(from_row, from_col)
			if fc:
				fc.clear_role()
		placements_changed.emit(_count_placed())
		return
	var dest := _cell_at(to_row, to_col)
	if dest == null:
		return
	if from_row >= 0:
		var src := _cell_at(from_row, from_col)
		if src:
			if src == dest:
				return
			var sr := src.role
			src.clear_role()
			if dest.role.is_empty():
				dest.set_role(sr)
			else:
				var dr2 := dest.role
				dest.set_role(sr)
				src.set_role(dr2)
			placements_changed.emit(_count_placed())
			return
	if from_row < 0:
		if count_role_on_field(role) >= 1:
			return
		if dest.role.is_empty() and _count_placed() >= 7:
			return
		dest.set_role(role)
		placements_changed.emit(_count_placed())
		return


func build_positions_array() -> Array:
	var out: Array = []
	for cell in _cells:
		if cell.role.is_empty():
			continue
		var dr := cell.grid_row - LOS_ROW
		var dc := cell.grid_col - CENTER_COL
		out.append({"role": cell.role, "delta_row": dr, "delta_col": dc})
	return out


func should_accept_remove_drop(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = data
	if str(d.get("kind", "")) != DND:
		return false
	return int(d.get("from_row", -1)) >= 0


func apply_remove_drop(data: Variant) -> void:
	if not should_accept_remove_drop(data):
		return
	var d: Dictionary = data
	apply_drop(int(d.get("from_row", -1)), int(d.get("from_col", -1)), -1, -1, str(d.get("role", "")))
