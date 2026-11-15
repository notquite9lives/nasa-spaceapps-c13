extends Node

@export var alerts_json_mission_1 := "res://data/alerts_mission1.json"
@export var alerts_json_mission_2_stage_1 := "res://data/alerts_mission2_stage1"
@export var alerts_json_mission_2_stage_2 := "res://data/alerts_mission2_stage2"

## Chance (per in-game day) that a crisis alert fires.
@export_range(0.0, 1.0, 0.001) var daily_crisis_chance: float = 0.03
## Guarantee that at least one crisis happens during the Earth-Mars transit,
## even if the daily rolls miss for the whole trip.
@export var guarantee_transit_crisis: bool = true
## Fraction of the transit by which the guaranteed crisis must have fired.
@export_range(0.05, 0.95, 0.01) var transit_crisis_deadline: float = 0.7
## Alert set used by the daily crisis roll.
@export var daily_mission: int = 1
@export var daily_stage: int = 1
## Range of real-time seconds the player has to answer an alert.
@export var min_response_time: int = 10
@export var max_response_time: int = 15

@onready var alert_timer = $AlertTimer

var ALERT_OBJECT = preload("res://scenes/alert.tscn")

var budget_spent = 0
var integrity_difference = 0
var pr_difference = 0

var _last_seen_day: int = -1
var _alert_in_progress: bool = false
var _transit_crisis_pending: bool = false
var _transit_crisis_day: int = -1
var _active_alert: Node2D = null

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
	# Alerts must keep receiving input and running their timer while the
	# rest of the mission is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# The mission clocks publish the current day through Engine metadata.
	_last_seen_day = int(Engine.get_meta("ares1_current_day", -1))
	_schedule_transit_crisis()


func _schedule_transit_crisis() -> void:
	if not guarantee_transit_crisis:
		return
	if String(Engine.get_meta("ares1_phase", "")) != "transit":
		return
	var total_days: int = int(Engine.get_meta("ares1_total_days", 0))
	if total_days <= 1:
		return
	var latest_day: int = maxi(2, int(float(total_days) * transit_crisis_deadline))
	_transit_crisis_day = randi_range(2, latest_day)
	_transit_crisis_pending = true


func _process(_delta: float) -> void:
	_keep_alert_centered()

	var current_day: int = int(Engine.get_meta("ares1_current_day", _last_seen_day))
	if current_day <= _last_seen_day:
		return

	var first_sync: bool = _last_seen_day < 0
	_last_seen_day = current_day

	# Don't roll on the frame we first connect to the clock, and never
	# stack a second alert on top of one that is already open.
	if first_sync or _alert_in_progress:
		return

	# Guaranteed transit crisis: keeps the Earth-Mars cruise from being risk-free.
	if _transit_crisis_pending and current_day >= _transit_crisis_day:
		_trigger_daily_crisis()
		return

	if randf() < daily_crisis_chance:
		_trigger_daily_crisis()


func _keep_alert_centered() -> void:
	if not is_instance_valid(_active_alert):
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		_active_alert.global_position = camera.get_screen_center_position()


func _trigger_daily_crisis() -> void:
	# Any crisis satisfies the transit guarantee.
	_transit_crisis_pending = false
	_alert_in_progress = true
	await spawn_alert(
		daily_mission,
		daily_stage,
		randi_range(min_response_time, max_response_time)
	)
	_alert_in_progress = false


func mark_crisis_problem() -> void:
	Engine.set_meta("ares1_crisis_problems", true)

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
		
	# The transit camera is far from the world origin, so anchor the alert at
	# the center of the current view instead of at world (0, 0).
	var previous_camera: Camera2D = get_viewport().get_camera_2d()
	var alert_camera: Camera2D = buttons.get_node_or_null("Camera2D")
	if alert_camera:
		alert_camera.enabled = false
	add_child(buttons)
	if previous_camera:
		buttons.global_position = previous_camera.get_screen_center_position()
	else:
		var viewport_half: Vector2 = get_viewport().get_visible_rect().size * 0.5
		buttons.global_position = get_viewport().get_canvas_transform().affine_inverse() * viewport_half
	_active_alert = buttons
	
	# Freeze the mission (ship, clocks, orbits) until the crisis is resolved.
	var tree := get_tree()
	var was_paused := tree.paused
	tree.paused = true
	
	# Drive the on-screen countdown so the player can see the time limit.
	var progress_bar: ProgressBar = buttons.get_node_or_null("Control/ProgressBar")
	var time_label: Label = buttons.get_node_or_null("Control/ProgressBar/Label")
	if progress_bar:
		progress_bar.max_value = float(time)
		progress_bar.value = float(time)
	if time_label:
		time_label.text = "%.1fs" % float(time)
	var countdown_update := func(value: float) -> void:
		if is_instance_valid(progress_bar):
			progress_bar.value = value
		if is_instance_valid(time_label):
			time_label.text = "%.1fs" % value
	var countdown: Tween = buttons.create_tween()
	countdown.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	countdown.tween_method(countdown_update, float(time), 0.0, float(time))
	
	alert_timer.one_shot = true
	alert_timer.wait_time = time
	
	var on_timeout = func():
		mark_crisis_problem()
		choice_made.emit(0, 0, 0)
	alert_timer.timeout.connect(on_timeout, CONNECT_ONE_SHOT)
	alert_timer.start()
	
	temp = await choice_made
	
	alert_timer.stop()
	if alert_timer.timeout.is_connected(on_timeout):
		alert_timer.timeout.disconnect(on_timeout)
		
	budget_spent += temp[0]
	integrity_difference += temp[1]
	pr_difference += temp[2]
	
	if is_instance_valid(previous_camera):
		previous_camera.make_current()
		
	_active_alert = null
	buttons.queue_free()
	tree.paused = was_paused
		
	print("Alert resolved")
	
	return [budget_spent, integrity_difference, pr_difference]
