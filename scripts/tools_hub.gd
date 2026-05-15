extends Control
class_name ToolsHub

const FORMATION_TOOL_SCENE := preload("res://scenes/formation_tool.tscn")

var _formations_catalog: FormationsCatalog
var _plays_catalog: PlaysCatalog
var _tools_menu: MenuButton
var _status: Label


func _ready() -> void:
	_formations_catalog = FormationsCatalog.new()
	if not _formations_catalog.load_from_json("res://data/formations.json"):
		push_error("ToolsHub: failed to load formations.json")
	_plays_catalog = PlaysCatalog.new()
	if not _plays_catalog.load_from_json("res://data/plays.json"):
		push_error("ToolsHub: failed to load plays.json")
	_build_ui()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.11, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)

	var title := Label.new()
	title.text = "Football — Tools"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	top.add_child(title)

	_tools_menu = MenuButton.new()
	_tools_menu.text = "Tools"
	var pm := _tools_menu.get_popup()
	pm.add_item("Formation tool…", 0)
	pm.add_item("Test Play…", 1)
	pm.add_item("Play Creator…", 2)
	pm.id_pressed.connect(_on_tools_menu_id_pressed)
	top.add_child(_tools_menu)

	var play_game := Button.new()
	play_game.text = "Open full game"
	play_game.pressed.connect(_on_open_full_game_pressed)
	top.add_child(play_game)

	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(func() -> void: get_tree().quit())
	top.add_child(quit)

	var hint := Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = (
		"Edit formations, plays, and run Test Play without the full match UI.\n"
		+ "Use Tools above, or run this scene directly (F6 on tools_hub.tscn).\n"
		+ "Main game scene stays paused until you press Play or Sim."
	)
	root.add_child(hint)

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.text = "Catalogs loaded."
	root.add_child(_status)


func _on_tools_menu_id_pressed(id: int) -> void:
	if id == 0:
		var t := FORMATION_TOOL_SCENE.instantiate() as FormationTool
		t.setup(_formations_catalog, Callable(self, "_formation_tool_after_save"))
		add_child(t)
	elif id == 1:
		var t := TestPlayScreen.new()
		t.setup(_plays_catalog, _formations_catalog, "")
		add_child(t)
	elif id == 2:
		var t := PlayCreatorTool.new()
		t.setup(
			_plays_catalog,
			_formations_catalog,
			Callable(self, "_play_creator_after_save"),
			Callable(self, "_play_creator_test_play")
		)
		add_child(t)


func _formation_tool_after_save() -> void:
	if _formations_catalog.load_from_json("res://data/formations.json"):
		_set_status("Formations saved and reloaded.")
	else:
		_set_status("Save done; reload failed.")


func _play_creator_after_save() -> void:
	if _plays_catalog.load_from_json("res://data/plays.json"):
		_set_status("Plays saved and reloaded.")
	else:
		_set_status("Save done; reload failed.")


func _play_creator_test_play(play_id: String) -> void:
	var t := TestPlayScreen.new()
	t.setup(_plays_catalog, _formations_catalog, play_id)
	add_child(t)


func _on_open_full_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_scene.tscn")


func _set_status(t: String) -> void:
	if _status:
		_status.text = t
