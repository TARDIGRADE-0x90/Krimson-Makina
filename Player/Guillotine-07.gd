extends CharacterBody2D
class_name Player

enum TILT_STATES {NONE, LEFT, RIGHT}
enum MOVEMENT_STATES {HOVER, FOCUS, RUSH}

const SPEED_DICT: Dictionary = {
	MOVEMENT_STATES.HOVER: 1200,
	MOVEMENT_STATES.FOCUS: 800,
	MOVEMENT_STATES.RUSH: 3000
}

const ZERO_VECTOR = Vector2(0, 0)
const FOCUS_CAMERA_PUSH: int = 640
const DEFAULT_PUSH: int = 480

const RUSH_TIME: float = 0.5
const RUSH_TIME_FACTOR: int = 100
const BLADE_SHIFT_FACTOR: float = 2.4
const HEAD_SHIFT_FACTOR: float = 0.8
const BODY_SHIFT_FACTOR: float = 0.4

const SLASH_TIME: float = 0.3
const THRUST_TIME: float = 0.4
const MINIGUN_FIRERATE: float = 0.075

const DEFAULT_CHOKE: float = 1.0
const FOCUS_CHOKE: float = 0.4

const BLADE_START = Vector2(0, 256)
const BLADE_SLASH_REST = Vector2(0, -256)
const BLADE_T_X_DEFAULT = Vector2(1, 0)
const BLADE_ROTATE_ANGLE: float = (PI * 0.06)
const BLADE_ROTATE_DEGREE: float = 0.2
const THRUST_X_OFFSET: int = 256
const THRUST_TIME_FACTOR: int = 22
const THRUST_PUSH: int = 200

const AUXILLARY_START = Vector2(64, -64)
const AUXILLARY_AIM_BOUND = Vector2(100, 0)

const Z_BLADE: int = 1
const Z_AUXILLARY: int = 1
const Z_WINGS: int = 0
const Z_BODY: int = 2
const Z_HEAD: int = 3

@export var ACCELERATION: float = 0.2;
@export var PlayerCamera: MainCamera

@onready var RushTimer: Timer = $RushTimer
@onready var SlashTimer: Timer = $SlashTimer
@onready var ThrustTimer: Timer = $ThrustTimer
@onready var AuxillaryCooldown: Timer = $AuxillaryCooldown

@onready var FullBody: Node2D = $FullBody
@onready var Wings: Sprite2D = $FullBody/Wings
@onready var Body: Sprite2D  = $FullBody/Body
@onready var Head: Sprite2D  = $FullBody/Head
@onready var Blade: Node2D = $Blade
@onready var Auxillary: Node2D = $Auxillary
@onready var CannonPoint: Marker2D = $Auxillary/CannonPoint

@onready var PlayerGun: ProjectileManager = $Auxillary/PlayerGun

var current_speed: int = 0
var current_direction = Vector2(0,0)

var cursor = Vector2(0,0)

var input_x: int = 0
var input_y: int = 0

var move_state_stack: Array
var move_state: int = MOVEMENT_STATES.HOVER

var blade_direction: int = 1
var blade_position: Vector2 = BLADE_START

var auxillary_firerate: float

var primary_held: bool = false
var auxillary_held: bool = false
var focus_held: bool = false
var dash_held: bool = false

var aim_choke: float = 1.0

func _ready() -> void:
	Global.player = self
	
	initialize_z_ordering()
	
	Blade.position = BLADE_START
	Auxillary.position = AUXILLARY_START
	
	move_state_stack.append(MOVEMENT_STATES.HOVER) #default speed in the movement queue VERY IMPORTANT
	current_speed = SPEED_DICT[MOVEMENT_STATES.HOVER]
	
	auxillary_firerate = MINIGUN_FIRERATE
	
	initialize_rush_timer()
	initialize_slash_timer()
	initialize_thrust_timer()
	initialize_auxillary_cooldown()

func _physics_process(delta: float) -> void:
	Global.player_position = global_position
	
	cursor = get_global_mouse_position()
	
	if not move_state == MOVEMENT_STATES.FOCUS:
		look_at(cursor)
	
	handle_looking()
	
	update_direction()
	update_velocity()
	
	if not RushTimer.is_stopped():
		animate_rush()
	
	if not SlashTimer.is_stopped():
		animate_slash()
	
	if not ThrustTimer.is_stopped():
		animate_thrust()
	
	if move_state == MOVEMENT_STATES.RUSH:
		handle_rush()
	
	if auxillary_held and AuxillaryCooldown.is_stopped():
		fire_auxillary()

func _unhandled_input(event : InputEvent) -> void:
	parse_input_movement(event)
	parse_input_attack(event)
	#parse_input_camera_tilt(event)

func initialize_rush_timer() -> void:
	RushTimer.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	RushTimer.set_wait_time(RUSH_TIME)
	RushTimer.set_one_shot(true)
	RushTimer.timeout.connect(clear_rush)

func initialize_slash_timer() -> void:
	SlashTimer.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	SlashTimer.set_wait_time(SLASH_TIME)
	SlashTimer.set_one_shot(true)
	SlashTimer.timeout.connect(reset_blade)

func initialize_thrust_timer() -> void:
	ThrustTimer.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	ThrustTimer.set_wait_time(THRUST_TIME)
	ThrustTimer.set_one_shot(true)
	ThrustTimer.timeout.connect(reset_blade)

func initialize_auxillary_cooldown() -> void:
	AuxillaryCooldown.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	AuxillaryCooldown.set_wait_time(auxillary_firerate)
	AuxillaryCooldown.set_one_shot(true)

func initialize_z_ordering() -> void:
	Head.z_index = Z_HEAD
	Body.z_index = Z_BODY
	Wings.z_index = Z_WINGS
	Blade.z_index = Z_BLADE
	Auxillary.z_index = Z_AUXILLARY

func look_at_with_bound(obj: Node2D, target: Vector2, bound: Vector2) -> void:
	var localized_target = to_local(target)
	
	if localized_target.x < bound.x:
		return #prevent rotation after a certain point
	else:
		obj.rotate(obj.get_angle_to(target))

func update_velocity() -> void:
	velocity = lerp(velocity, current_direction * current_speed, ACCELERATION)
	move_and_slide()

func update_direction() -> void:
	if move_state != MOVEMENT_STATES.RUSH:
		input_x = int(Input.is_action_pressed(Inputs.MOVE_RIGHT)) - int(Input.is_action_pressed(Inputs.MOVE_LEFT));
		input_y = int(Input.is_action_pressed(Inputs.MOVE_DOWN)) - int(Input.is_action_pressed(Inputs.MOVE_UP));
		
		current_direction = Vector2(input_x, input_y).normalized()
	else:
		current_direction = ZERO_VECTOR 
	
	"""
	match move_state: #tank controls do not fit at all for this kind of gameplay but i'm leaving it for posterity
		MOVEMENT_STATES.HOVER: #standard movement
			input_x = int(Input.is_action_pressed(Inputs.MOVE_RIGHT)) - int(Input.is_action_pressed(Inputs.MOVE_LEFT));
			input_y = int(Input.is_action_pressed(Inputs.MOVE_DOWN)) - int(Input.is_action_pressed(Inputs.MOVE_UP));
			
			current_direction = Vector2(input_x, input_y).normalized()
		
		MOVEMENT_STATES.FOCUS: #tank controls
			input_x = int(Input.is_action_pressed(Inputs.MOVE_RIGHT)) - int(Input.is_action_pressed(Inputs.MOVE_LEFT));
			input_y = int(Input.is_action_pressed(Inputs.MOVE_DOWN)) - int(Input.is_action_pressed(Inputs.MOVE_UP));
			
			rotation += (input_x * get_physics_process_delta_time())
			current_direction = Vector2(cos(rotation), sin(rotation)).normalized() * -input_y
		
		MOVEMENT_STATES.RUSH: #guided by cursor
			current_direction = ZERO_VECTOR 
	"""

func parse_input_movement(event: InputEvent) -> void:
	if event.is_action_pressed(Inputs.RUSH) and RushTimer.is_stopped():
		move_state = MOVEMENT_STATES.RUSH
		current_speed = SPEED_DICT[move_state]
		RushTimer.start()
	
	if event.is_action_pressed(Inputs.FOCUS):
		if not move_state_stack.has(MOVEMENT_STATES.FOCUS): #queue it, if it isn't already (safeguard)
			move_state_stack.append(MOVEMENT_STATES.FOCUS) 
		
		if RushTimer.is_stopped():
			move_state = MOVEMENT_STATES.FOCUS
			current_speed = SPEED_DICT[move_state]
	
	if event.is_action_released(Inputs.FOCUS):
		move_state_stack.erase(MOVEMENT_STATES.FOCUS) #dequeue it if present
		
		if RushTimer.is_stopped():
			move_state = MOVEMENT_STATES.HOVER
			current_speed = SPEED_DICT[move_state]

func parse_input_attack(event: InputEvent) -> void:
	if event.is_action_pressed(Inputs.PRIMARY) and SlashTimer.is_stopped() and ThrustTimer.is_stopped():
		if Input.is_action_pressed(Inputs.FOCUS):
			ThrustTimer.start()
			return
		
		blade_direction *= -1
		SlashTimer.start()
	
	if event.is_action_pressed(Inputs.AUXILLARY):
		auxillary_held = true
	
	if event.is_action_released(Inputs.AUXILLARY):
		auxillary_held = false

func animate_rush() -> void:
	Wings.position.x = -(RushTimer.time_left * RUSH_TIME_FACTOR)
	Head.position.x = (RushTimer.time_left * RUSH_TIME_FACTOR)
	Body.position.x = (RushTimer.time_left * RUSH_TIME_FACTOR * BODY_SHIFT_FACTOR)
	Auxillary.position.x = AUXILLARY_START.x + (RushTimer.time_left * RUSH_TIME_FACTOR)

func animate_slash() -> void:
	Blade.transform.origin = Blade.transform.origin.rotated(BLADE_ROTATE_ANGLE * blade_direction)
	Blade.rotation += BLADE_ROTATE_DEGREE * blade_direction

func animate_thrust() -> void:
	center_blade()
	Blade.transform.origin.x = THRUST_X_OFFSET - sin(ThrustTimer.time_left * THRUST_TIME_FACTOR) * THRUST_PUSH

func handle_rush() -> void:
	velocity = Vector2(cos(rotation), sin(rotation)).normalized() * current_speed

func clear_rush() -> void: #reset movement and chassis part positioning
	move_state = move_state_stack.back()
	current_speed = SPEED_DICT[move_state]
	
	Wings.position.x = 0
	Head.position.x = 0
	Auxillary.position.x = AUXILLARY_START.x 

func center_blade() -> void:
	Blade.transform.origin.y = Head.rotation #center the blade
	Blade.set_rotation(PI * 0.5 * -blade_direction)

func reset_blade() -> void:
	match blade_direction:
		1: 
			blade_position = BLADE_START
			Blade.rotation_degrees = 0
		-1: 
			blade_position = BLADE_SLASH_REST
			Blade.rotation_degrees = 180
		_:
			print("Error in Guillotine-07 : why is there another direction")
	
	Blade.transform.x = BLADE_T_X_DEFAULT
	Blade.transform.y.x = 0
	Blade.transform.y.y = blade_direction
	Blade.position = blade_position

func handle_looking() -> void: #remember that this method, as it is now, is literally running every frame
	if move_state == MOVEMENT_STATES.FOCUS:
		aim_choke = FOCUS_CHOKE 
		look_at_with_bound(Auxillary, cursor, AUXILLARY_AIM_BOUND)
		look_at_with_bound(Head, cursor, AUXILLARY_AIM_BOUND)
		
		if Global.active_camera:
			Global.active_camera.set_focused(true)
			Global.active_camera.set_current_target(global_position + Vector2.from_angle(rotation).normalized() * FOCUS_CAMERA_PUSH)
			Global.active_camera.tilt_to_angle(Head.rotation)
	else:
		aim_choke = DEFAULT_CHOKE
		Auxillary.set_rotation(0)
		Head.set_rotation(0)
		
		if Global.active_camera:
			Global.active_camera.set_focused(false)
			Global.active_camera.set_current_target(global_position + Vector2.from_angle(rotation).normalized() * DEFAULT_PUSH)
			Global.active_camera.tilt_to_angle(0)

func fire_auxillary() -> void:
	var shots: int = 8
	var spread: float = 0.8 * aim_choke
	var shot_angle: float = Auxillary.global_rotation
	var shot_speed: float = 100
	var shot_start = CannonPoint.global_position
	
	AuxillaryCooldown.start()
	#PlayerGun.fire(shot_speed, shot_angle, shot_start)
	PlayerGun.multifire(shots, spread, shot_speed, shot_angle, shot_start)

