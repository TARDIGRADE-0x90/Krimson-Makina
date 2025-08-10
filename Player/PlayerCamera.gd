extends Camera2D
class_name MainCamera

"""
do later;
remove any "offset" when camera is not focused; apply it when camera is focused
"""

const DEFAULT_ZOOM: float = 0.3
const FOCUS_ZOOM: float = 0.25

const TILT_TIME: float = 0.25
const TILT_DAMP: float = 0.2

const PUSH_TIME: float = 0.2
const PUSH_DAMP: float = 1.2

var focused: bool = false
var current_target = Vector2(0, 0)

func _ready():
	Global.active_camera = self
	zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)

func _physics_process(delta) -> void:
	if focused:
		zoom = Vector2(FOCUS_ZOOM, FOCUS_ZOOM)
	else:
		zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)
	
	smooth_to_target(current_target)

func _process(delta) -> void:
	pass

func snap_to_target(target: Vector2) -> void:
	global_position = target

func smooth_to_target(target: Vector2 = Global.player_position) -> void:
	global_position = Global.interpolate_vector(global_position, target, PUSH_TIME, PUSH_DAMP)

func tilt_to_angle(target_angle: float) -> void:
	rotation = Global.interpolate_value(rotation, target_angle, TILT_TIME, TILT_DAMP)

func set_current_target(target: Vector2) -> void:
	current_target = target

func set_focused(toggle: bool) -> void:
	focused = toggle
