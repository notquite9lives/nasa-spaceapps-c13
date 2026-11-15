extends Button

var label1 = null

var label3 = null

func _ready() -> void:
	label1 = get_node("ares1")

	label3 = get_node("destination")


func _on_mars_mouse_exited() -> void:
	label1.hide()

	label3.hide()
	
func _on_mars_mouse_entered() -> void:
	label1.show()

	label3.show()
	

	
