extends Camera2D

@export var scroll_speed: float = 600.0
@export var min_x: float = 0.0     
@export var max_x: float = 5000.0  

@export var left_button: BaseButton
@export var right_button: BaseButton


func _ready():
	var anim := get_node("Sprite2D/AnimationPlayer")
	anim.queue_free()
	
func _process(delta: float) -> void:
	var direction: float = 0.0

	if (left_button and left_button.button_pressed) or Input.is_action_pressed("nav_left"):
		direction -= 1.0
		print("left")


	if (right_button and right_button.button_pressed) or Input.is_action_pressed("nav_right"):
		direction += 1.0
		print("right")
	position.x += direction * scroll_speed * delta
	position.x = clamp(position.x, min_x, max_x)
	
