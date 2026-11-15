extends RichTextLabel

## Keeps the mission clock running while Ares I orbits Mars.
## It ticks at a fraction of the normal Earth-Mars transit rate.

const TRANSIT_SECONDS: float = 101.8
const FALLBACK_DAYS: int = 200

@export var rate_factor: float = 0.6
@export var win_day: int = 500
@export var win_label_path: NodePath = NodePath("../WinLabel")

var _day: float = 0.0
var _days_per_second: float = 0.0
var _last_shown_day: int = -1
var _won: bool = false
var _win_label: CanvasItem = null


func _ready() -> void:
	Engine.set_meta("ares1_phase", "orbit")
	var total_days: int = int(Engine.get_meta("ares1_total_days", FALLBACK_DAYS))
	_day = float(maxi(total_days, 0))
	_days_per_second = maxf(float(total_days), 1.0) / TRANSIT_SECONDS * rate_factor
	_win_label = get_node_or_null(win_label_path) as CanvasItem
	if _win_label:
		_win_label.visible = false
	_update_label()


func _process(delta: float) -> void:
	_day += delta * _days_per_second
	_update_label()
	_check_win()


func _check_win() -> void:
	if _won or _day < float(win_day):
		return
	# Unresolved crises are recorded by the alert system.
	if bool(Engine.get_meta("ares1_crisis_problems", false)):
		return
	_won = true
	Engine.set_meta("ares1_won", true)
	if _win_label:
		_win_label.visible = true


func _update_label() -> void:
	var day: int = int(floor(_day))
	Engine.set_meta("ares1_current_day", day)
	if day == _last_shown_day:
		return
	_last_shown_day = day
	text = "%s\nMission Day %d" % [MissionCalendar.format_day(day), day]

