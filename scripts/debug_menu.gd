extends PanelContainer

@onready var event_log_panel = $"../HUDGroup/EventLogPanel"
@onready var phase_log_panel = $"../HUDGroup/PhaseLogPanel"
@onready var play_log_panel = $"../HUDGroup/PlayInfoHUD"
@onready var play_calc_log_panel = $"../HUDGroup/CalcLogPanel"
@onready var oppHUD_panel = $"../OpponentGroup/OpponentHUD"

func _ready():
	$VBoxContainer/EventLog.button_pressed = true
	$VBoxContainer/PhaseLog.button_pressed = true
	$VBoxContainer/PlayLog.button_pressed = true
	$VBoxContainer/PlayCalcLog.button_pressed = true
	$VBoxContainer/OppHUD.button_pressed = false
	event_log_panel.visible = true
	phase_log_panel.visible = true
	play_log_panel.visible = true
	play_calc_log_panel.visible = true
	oppHUD_panel.visible = false
	
func _on_event_log_toggled(toggled_on: bool) -> void:
	event_log_panel.visible = toggled_on

func _on_phase_log_toggled(toggled_on: bool) -> void:
	phase_log_panel.visible = toggled_on

func _on_play_log_toggled(toggled_on: bool) -> void:
	play_log_panel.visible = toggled_on

func _on_opp_hud_toggled(toggled_on: bool) -> void:
	oppHUD_panel.visible = toggled_on

func _on_play_calc_log_toggled(toggled_on: bool) -> void:
	play_calc_log_panel.visible = toggled_on
