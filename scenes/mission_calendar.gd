class_name MissionCalendar
extends RefCounted

## Shared mission date helpers used by every Ares I clock.

const START_DATE: String = "2030-12-31T00:00:00"
const MONTHS := [
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December",
]


static func start_unix() -> int:
	return int(Time.get_unix_time_from_datetime_string(START_DATE))


static func format_day(day: int) -> String:
	var stamp: int = start_unix() + day * 86400
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(stamp)
	return "%s %d, %d" % [MONTHS[int(date["month"]) - 1], int(date["day"]), int(date["year"])]
