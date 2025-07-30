extends Camera2D
class_name MainCamera

const DEFAULT_ZOOM: float = 0.4
const FOCUS_ZOOM: float = 0.3

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
	if not focused:
		zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)
	else:
		zoom = Vector2(FOCUS_ZOOM, FOCUS_ZOOM)
	
	anchor_to_target(current_target)

func _process(delta) -> void:
	pass

func ease_to_cursor() -> void:
	pass

func anchor_to_target(target: Vector2 = Global.player_position) -> void:
	global_position.x = Global.interpolate_value(global_position.x, target.x, PUSH_TIME, PUSH_DAMP)
	global_position.y = Global.interpolate_value(global_position.y, target.y, PUSH_TIME, PUSH_DAMP)

func tilt_camera(tilt_state: int) -> void:
	pass

func tilt_to_angle(target_angle: float) -> void:
	rotation = Global.interpolate_value(rotation, target_angle, TILT_TIME, TILT_DAMP)
	#global_position.x = Global.interpolate_value(global_position.x, global_position.x + 100 * cos(target_angle), TILT_TIME, TILT_DAMP)
	##global_position.y = Global.interpolate_value(global_position.y, global_position.y + 100 * sin(target_angle), TILT_TIME, TILT_DAMP)
	#global_position = global_position + Vector2(64 * cos(target_angle), 64 * sin(target_angle))

func set_current_target(target: Vector2) -> void:
	current_target = target

func set_focused(toggle: bool) -> void:
	focused = toggle
