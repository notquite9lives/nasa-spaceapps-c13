extends Control


const HOVER_SCALE := Vector2(1.06, 1.06)
const HOVER_TINT := Color(0.72, 1.25, 1.32, 1.0)
const IDLE_TINT := Color(1.0, 1.0, 1.0, 1.0)
const TWEEN_TIME := 0.16

@onready var _panel: Panel = $MenuPanel

var _buttons: Array[Button] = []


func _ready() -> void:
	_buttons = [get_node("play"), get_node("credits"), get_node("quit")]
	for button: Button in _buttons:
		button.pivot_offset = button.size * 0.5
		button.mouse_entered.connect(_on_hover_changed.bind(button, true))
		button.mouse_exited.connect(_on_hover_changed.bind(button, false))
		button.focus_entered.connect(_on_hover_changed.bind(button, true))
		button.focus_exited.connect(_on_hover_changed.bind(button, false))
	_panel.modulate = Color(1, 1, 1, 0.85)
	_float_panel()


func _on_hover_changed(button: Button, hovered: bool) -> void:
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", HOVER_SCALE if hovered else Vector2.ONE, TWEEN_TIME)
	tween.tween_property(button, "modulate", HOVER_TINT if hovered else IDLE_TINT, TWEEN_TIME)


func _float_panel() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_panel, "modulate:a", 0.7, 2.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_panel, "modulate:a", 0.92, 2.4).set_trans(Tween.TRANS_SINE)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/missionselect.tscn")
	
	
