extends Node

@export var alerts_json_mission_1 := "res://data/alerts_mission1.json"
@export var alerts_json_mission_2_stage_1 := "res://data/alerts_mission2_stage1"
@export var alerts_json_mission_2_stage_2 := "res://data/alerts_mission2_stage2"
@onready var alert_timer = $AlertTimer

var ALERT_OBJECT = preload("res://scenes/alert.tscn")

var budget_spent = 0
var integrity_difference = 0
var pr_difference = 0

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
	
	
func get_data_from_json(path):
	if not FileAccess.file_exists(path):
		push_error("File not found at " + path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	
	var data = JSON.parse_string(json_text)
	
	return data

signal choice_made(cost, integrity, pr)

func _ready() -> void:
	spawn_alert(1, 1, 10)

func spawn_alert(mission, stage, time):
	var path = ""
	var ccost = 0
	var temp = []
	var unit = ''
	var pr = 0
	var pr_sign = ''
	var integrity = 0
	var integrity_sign = ''
	
	if mission == 1:
		path = alerts_json_mission_1
	elif mission == 2:
		if stage == 1:
			path = alerts_json_mission_2_stage_1
		else:
			path = alerts_json_mission_2_stage_2
			
	var data = get_data_from_json(path)
	
	var button_data = data[randi_range(0, len(data)-1)]
	
	var buttons = ALERT_OBJECT.instantiate()
	
	buttons.get_node("Control/Label2").text = "ALERT: " + button_data[0]
	
	for i in range(3):
		var button = buttons.get_node("Control/Button" + str(i+1))
			
		button.pressed.connect(func(): choice_made.emit(button_data[i+1]["stat"]["cost"], button_data[i+1]["stat"]["int"], button_data[i+1]["stat"]["pr"]))
		
		#button.size.y = 350
			
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
	
	alert_timer.one_shot = true
	alert_timer.wait_time = time
	
	var on_timeout = func(): choice_made.emit(0, 0, 0)
	alert_timer.timeout.connect(on_timeout, CONNECT_ONE_SHOT)
	alert_timer.start()
	
	temp = await choice_made
	
	alert_timer.stop()
	if alert_timer.timeout.is_connected(on_timeout):
		alert_timer.timeout.disconnect(on_timeout)
		
	budget_spent += temp[0]
	integrity_difference += temp[1]
	pr_difference += temp[2]
		
	buttons.queue_free()
		
	print("Alert resolved")
	
	return [budget_spent, integrity_difference, pr_difference]
