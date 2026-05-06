extends Control
class_name PlayerToken

signal selected(player_id: String)

@onready var name_label: Label = $NameLabel
@onready var button: Button = $SelectButton

var player_id: String = ""

func _ready() -> void:
	if not name_label:
		push_error("PlayerToken missing child node: NameLabel")
	if not button:
		push_error("PlayerToken missing child node: SelectButton")
	else:
		button.pressed.connect(_on_pressed)

func bind_player(data: Dictionary) -> void:
	player_id = str(data.get("id", ""))
	name_label.text = str(data.get("name", "Player"))

func set_highlighted(enabled: bool) -> void:
	modulate = Color(1.0, 1.0, 0.6) if enabled else Color(1, 1, 1)

func set_selected(enabled: bool) -> void:
	button.button_pressed = enabled

func _on_pressed() -> void:
	emit_signal("selected", player_id)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$NameLabel.global_position = $PlayerSprite.global_position + Vector2(0, -40)
	
