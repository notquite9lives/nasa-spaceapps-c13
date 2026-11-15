extends RichTextLabel

## Displays mission elapsed time during the Ares I Earth-Mars transit.
## The total cruise length is randomized between 6 and 9 months.

const START_X: float = -370.0
const END_X: float = 2685.0
const MIN_DAYS: int = 182
const MAX_DAYS: int = 274

@export var target_path: NodePath = NodePath("../../Ares1")
@export var refresh_interval: float = 0.05

var total_days: int = 0

var _target: Node2D = null
var _elapsed: float = 0.0
var _last_day: int = -1


func _ready() -> void:
	Engine.set_meta("ares1_phase", "transit")
	total_days = randi_range(MIN_DAYS, MAX_DAYS)
	Engine.set_meta("ares1_total_days", total_days)
	Engine.set_meta("ares1_start_date", MissionCalendar.format_day(0))
	Engine.set_meta("ares1_arrival_date", MissionCalendar.format_day(total_days))
	Engine.set_meta("ares1_crisis_problems", false)
	Engine.set_meta("ares1_won", false)
	_target = get_node_or_null(target_path) as Node2D
	_update_label(0)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < refresh_interval:
		return
	_elapsed = 0.0
	_update_label(_current_day())


func _current_day() -> int:
	if _target == null:
		return 0
	var span: float = END_X - START_X
	var progress: float = clampf((_target.position.x - START_X) / span, 0.0, 1.0)
	return int(round(progress * float(total_days)))


func _update_label(day: int) -> void:
	Engine.set_meta("ares1_current_day", day)
	if day == _last_day:
		return
	_last_day = day
	text = "%s\nMission Day %d / %d" % [MissionCalendar.format_day(day), day, total_days]
