extends Camera2D

var x: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var prnt := get_parent()
	var target := prnt.get_node("Ares1")
	x = target.position.x
	
	x = clamp(x, 0, 2299)
	self.position.x = lerpf(self.position.x, x, 0.5)
