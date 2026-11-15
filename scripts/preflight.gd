extends Node2D

@export var mission: int = 1
@export var mission_1_json := "res://data/mission1.json"
const OPTIONS_3: PackedScene = preload("res://scenes/3_option.tscn")
const OPTIONS_2: PackedScene = preload("res://scenes/2_option.tscn")
var tcount := 0
var ccount := 0
var data := []


func cost_to_cost_and_unit(cost):
	
	var unit = ""
	if cost >= 1000000000:
		cost /= 1000000000
		unit = "B"
	elif cost >= 1000000:
		cost /= 1000000
		unit = "M"
	elif cost >= 1000:
		cost /= 1000
		unit = "K"
	else:
		unit = ""
		
	return [cost, unit]
	
	
func get_sign(number):
	if number < 0:
		return "-"
	else:
		return "+"
	
	
func _ready() -> void:
	match mission:
		1:
			data = get_data_from_json(mission_1_json)
			var result = await spawn_buttons(data)
			

func get_data_from_json(path):
	if not FileAccess.file_exists(path):
		push_error("File not found at " + path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	
	var data = JSON.parse_string(json_text)
	
	return data

signal choice_made(cost, integrity, pr)


func spawn_buttons(data):
	tcount = len(data)
	
	var temp = []
	var ccost = 0
	var unit = ""
	var pr = 0
	var pr_sign = "+"
	var integrity_sign = "+"
	var integrity = 0
	var loop_count = 1
	var buttons = null
	
	var budget_spent = 0
	var pr_difference = 0
	var integrity_difference = 0
	
	while ccount < tcount:
	
		var button_data = data[ccount]
	
		if len(button_data)-1 == 3:
			buttons = OPTIONS_3.instantiate()
			loop_count = 3
		else:
			buttons = OPTIONS_2.instantiate()
			loop_count = 2
	
		buttons.get_node("Control/Label2").text = button_data[0]
	
		for i in range(loop_count):
			
			var button = buttons.get_node("Control/Button" + str(i+1))
			
			button.pressed.connect(func(): choice_made.emit(button_data[i+1]["stat"]["cost"], button_data[i+1]["stat"]["int"], button_data[i+1]["stat"]["pr"]))
			
			button.get_child(0).text = button_data[i+1]["title"]
			button.get_child(1).text = button_data[i+1]["desc"]
			
			ccost = button_data[i+1]["stat"]["cost"]
			temp = cost_to_cost_and_unit(ccost)
			ccost = temp[0]
			unit = temp[1]
			pr = button_data[i+1]["stat"]["pr"]
			pr_sign = get_sign(pr)
			integrity = button_data[i+1]["stat"]["int"] * 100
			integrity_sign = get_sign(integrity)
			
			button.get_child(2).text = (
					"Cost: %.1f%s\n" +
					"PR: %s%d\n" +
					"Integrity: %s%d%%"
			) % [ccost, unit, pr_sign, abs(pr), integrity_sign, abs(integrity)]
	
		add_child(buttons)
	
		temp = await choice_made
		budget_spent += temp[0]
		integrity_difference += temp[1]
		pr_difference += temp[2]
		
		buttons.queue_free()
		
		print("Choice made!")
			
		ccount += 1
	self.get_parent().get_node("Sprite2D")
	get_tree().change_scene_to_file("res://scenes/earth-mars.tscn")
	return [budget_spent, integrity_difference, pr_difference]
