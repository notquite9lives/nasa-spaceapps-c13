extends Sprite2D

@export var orbit_speed: float = 0.15

func _process(delta: float) -> void:
	get_parent().rotation += orbit_speed * delta