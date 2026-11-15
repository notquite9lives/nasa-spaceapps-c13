extends Sprite2D

@export var speed: float = 30.0
var boost_factor: float = 1.0

func _process(delta: float) -> void:
	var current_speed := speed * boost_factor
	if Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SHIFT):
		current_speed = speed * max(boost_factor, 3.0)
	self.position.x += delta * current_speed
	if self.position.x >= 2685:
		get_tree().change_scene_to_file("res://scenes/mars_orbit.tscn")
