extends Sprite2D

func _process(delta: float) -> void:
	self.position.x += delta * 30
	if self.position.x >= 2685:
		get_tree().change_scene_to_file("res://scenes/mars_orbit.tscn")
