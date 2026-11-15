extends Node2D

## One full probe orbit is slightly shorter than the Earth-Mars transit (101.8 s).
const TRANSIT_SECONDS: float = 101.8
const ORBIT_PERIOD_RATIO: float = 0.9

@export var orbit_speed: float = TAU / (TRANSIT_SECONDS * ORBIT_PERIOD_RATIO)
@export var phobos_orbit_speed: float = 0.15
@export var deimos_orbit_speed: float = 0.08


func _process(delta: float) -> void:
	$OrbitPivot.rotation += orbit_speed * delta
	$Mars/PhobosPivot.rotation += phobos_orbit_speed * delta
	$Mars/DeimosPivot.rotation += deimos_orbit_speed * delta
