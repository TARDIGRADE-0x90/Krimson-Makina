extends CharacterBody2D
class_name Player

"""
TO DO:
	- Create Options UI and input rebinding ASAP
	
	- Begin streamlining the creation of enemies, spawn structures, turrets, etc.
	
	- Before worrying about background texture, first draft up the level layout itself,
		then go over it with whatever visuals needed (how to do this? idk - One Giant Image
		is a worst case fix but there ought to be a better way to break it into pieces)
"""

enum MOVEMENT_STATES {HOVER, FOCUS, RUSH}

const SPEED_DICT: Dictionary = {
	MOVEMENT_STATES.HOVER: 1200,
	MOVEMENT_STATES.FOCUS: 800,
	MOVEMENT_STATES.RUSH: 3000
}

const ZERO_VECTOR = Vector2(0, 0)

const VIEW_MARGIN_FOCUS: int = 720
const VIEW_MARGIN_DEFAULT: int = 480
const VIEW_MARGIN_EXECUTION: int = 240

const RUSH_TIME: float = 0.5
const SLASH_TIME: float = 0.3
const THRUST_TIME: float = 0.4
const EXECUTION_TIME: float = 0.8

const MINIGUN_POOL_SIZE: int = 80
const MINIGUN_FIRERATE: float = 0.075
const MINIGUN_HEAT_RANGE = Vector2(1.5, 2.8)

const EXECUTION_RUSH_TIME_FACTOR: int = 120
const RUSH_TIME_FACTOR: int = 100
const HEAD_SHIFT_FACTOR: float = 1.8
const BODY_SHIFT_FACTOR: float = 1.2

const CORE_HEAT_INITIAL_MAX: float = 200.0

const RUSH_HEAT_DEFAULT: float = 25.0
const WEAPON_HEAT_MAX: float = 140.0
const WEAPON_COOL_RATE: float = 44 #multiplied against delta
const WEAPON_COOL_RATE_FOCUSED: float = 26 #multiplied against delta
const OVERHEAT_DAMAGE: float = 4 #multiplied against delta

const EXECUTION_COOLING: float = 20.0

const DEFAULT_CHOKE: float = 1.0
const FOCUS_CHOKE: float = 0.4

const BLADE_START = Vector2(0, 256)
const BLADE_SLASH_REST = Vector2(0, -256)
const BLADE_T_X_DEFAULT = Vector2(1, 0)

const SLASH_ANGLE: float = (PI * 0.06)
const SLASH_DEGREE: float = 0.2

const THRUST_X_OFFSET: int = 256
const THRUST_TIME_FACTOR: int = 22
const THRUST_PUSH: int = 200

const EXECUTION_ANGLE: float = (PI * 0.12)
const EXECUTION_DEGREE: float = 0.8
const EXECUTION_X_OFFSET: int = 128
const EXECUTION_TIME_FACTOR: int = 24
const EXECUTION_PUSH: int = 340

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
@onready var ExecutionTimer: Timer = $ExecutionTimer
@onready var AuxillaryCooldown: Timer = $AuxillaryCooldown

@onready var FullBody: Node2D = $FullBody
@onready var Wings: Sprite2D = $FullBody/Wings
@onready var Body: Sprite2D  = $FullBody/Body
@onready var Head: Sprite2D  = $FullBody/Head
@onready var Blade: Node2D = $Blade
@onready var AuxillaryAnchor: Node2D = $AuxillaryAnchor
@onready var CannonPoint: Marker2D = $AuxillaryAnchor/CannonPoint

@onready var PlayerGun: ProjectileManager = $AuxillaryAnchor/PlayerGun

var current_speed: int = 0
var current_direction = Vector2(0,0)

var cursor = Vector2(0,0)

var input_x: int = 0
var input_y: int = 0

var move_state_stack: Array
var move_state: int = MOVEMENT_STATES.HOVER

var blade_direction: int = 1
var blade_position: Vector2 = BLADE_START

var auxillary_held: bool = false
var focus_held: bool = false

var rushing: bool = false
var slashing: bool = false
var thrusting: bool = false
var executing: bool = false
var execution_point: Vector2 = ZERO_VECTOR

var core_heat_max: float = CORE_HEAT_INITIAL_MAX
var core_heat: float = CORE_HEAT_INITIAL_MAX

var weapon_heat_range: Vector2 = MINIGUN_HEAT_RANGE
var weapon_heat_max: float = WEAPON_HEAT_MAX
var weapon_heat: float = 0

var auxillary_pool_size: int = MINIGUN_POOL_SIZE
var auxillary_firerate: float
var aim_choke: float = 1.0

var rush_heat: float = RUSH_HEAT_DEFAULT

var overheated: bool = false

func _ready() -> void:
	Global.player = self
	
	CollisionBits.set_layer(self, CollisionBits.ENEMY_PROJECTILE_BIT, true)
	
	initialize_z_ordering()
	
	move_state_stack.append(MOVEMENT_STATES.HOVER) #default speed in the movement queue VERY IMPORTANT
	current_speed = SPEED_DICT[MOVEMENT_STATES.HOVER]
	
	Blade.position = BLADE_START
	AuxillaryAnchor.position = AUXILLARY_START
	auxillary_firerate = MINIGUN_FIRERATE
	PlayerGun.MaxPool = auxillary_pool_size
	
	initialize_rush_timer()
	initialize_slash_timer()
	initialize_thrust_timer()
	initialize_execution_timer()
	initialize_auxillary_cooldown()
	
	Events.weapon_heat_updated.connect(check_heat)

func _physics_process(delta: float) -> void:
	Global.player_position = global_position
	
	cursor = get_global_mouse_position()
	
	if move_state != MOVEMENT_STATES.FOCUS and !executing:
		look_at(cursor)
	
	handle_looking()
	
	update_direction()
	update_velocity()
	
	if slashing:
		animate_slash()
	
	if thrusting:
		animate_thrust()
	
	if move_state == MOVEMENT_STATES.RUSH:
		handle_rush()
	
	if auxillary_held and AuxillaryCooldown.is_stopped() and !executing:
		fire_auxillary()
	
	if !auxillary_held:
		cool_weapon()
	
	if executing:
		handle_execution()
	
	if overheated:
		tick_overheat_damage()

func _unhandled_input(event : InputEvent) -> void:
	parse_input_movement(event)
	parse_input_attack(event)
	parse_input_execution(event)

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

func initialize_execution_timer() -> void:
	ExecutionTimer.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	ExecutionTimer.set_wait_time(EXECUTION_TIME)
	ExecutionTimer.set_one_shot(true)
	ExecutionTimer.timeout.connect(clear_execution)

func initialize_auxillary_cooldown() -> void:
	AuxillaryCooldown.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	AuxillaryCooldown.set_wait_time(auxillary_firerate)
	AuxillaryCooldown.set_one_shot(true)

func initialize_z_ordering() -> void:
	Head.z_index = Z_HEAD
	Body.z_index = Z_BODY
	Wings.z_index = Z_WINGS
	Blade.z_index = Z_BLADE
	AuxillaryAnchor.z_index = Z_AUXILLARY

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
	if move_state != MOVEMENT_STATES.RUSH and !executing:
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
	if event.is_action_pressed(Inputs.RUSH) and move_state != MOVEMENT_STATES.RUSH:
		move_state = MOVEMENT_STATES.RUSH
		current_speed = SPEED_DICT[move_state]
		trigger_rush()
	
	if event.is_action_pressed(Inputs.FOCUS):
		if !move_state_stack.has(MOVEMENT_STATES.FOCUS): #queue it, if it isn't already (safeguard)
			move_state_stack.append(MOVEMENT_STATES.FOCUS) 
		
		if move_state != MOVEMENT_STATES.RUSH:
			move_state = MOVEMENT_STATES.FOCUS
			current_speed = SPEED_DICT[move_state]
	
	if event.is_action_released(Inputs.FOCUS):
		move_state_stack.erase(MOVEMENT_STATES.FOCUS) #dequeue it if present
		
		if move_state != MOVEMENT_STATES.RUSH:
			move_state = MOVEMENT_STATES.HOVER
			current_speed = SPEED_DICT[move_state]

func parse_input_attack(event: InputEvent) -> void:
	if event.is_action_pressed(Inputs.PRIMARY) and !slashing and !thrusting and !executing:
		if Input.is_action_pressed(Inputs.FOCUS):
			trigger_thrust()
			return
		
		trigger_slash()
	
	if event.is_action_pressed(Inputs.AUXILLARY):
		auxillary_held = true
	
	if event.is_action_released(Inputs.AUXILLARY):
		auxillary_held = false

func parse_input_execution(event: InputEvent) -> void:
	#do later - add conditional for execution_ready, true if player is within a "Vulnerable" area2d
	if event.is_action_pressed(Inputs.EXECUTE) and !executing:
		trigger_execution()

func handle_looking() -> void: #remember that this method, as it is now, is literally running every frame
	if move_state == MOVEMENT_STATES.FOCUS and !executing:
		aim_choke = FOCUS_CHOKE 
		look_at_with_bound(AuxillaryAnchor, cursor, AUXILLARY_AIM_BOUND)
		look_at_with_bound(Head, cursor, AUXILLARY_AIM_BOUND)
		
		if Global.active_camera:
			Global.active_camera.set_focused(true)
			Global.active_camera.set_current_target(global_position + Vector2.from_angle(rotation).normalized() * VIEW_MARGIN_FOCUS)
			Global.active_camera.tilt_to_angle(Head.rotation)
	
	elif executing:
		set_rotation(global_position.angle_to_point(execution_point))
		AuxillaryAnchor.set_rotation(0)
		Head.set_rotation(0)
		
		Global.active_camera.set_focused(false)
		Global.active_camera.snap_to_target(global_position + Vector2.from_angle(rotation).normalized() * VIEW_MARGIN_EXECUTION)
		#Global.active_camera.tilt_to_angle(0)

	else:
		aim_choke = DEFAULT_CHOKE
		AuxillaryAnchor.set_rotation(0)
		Head.set_rotation(0)
		
		if Global.active_camera:
			Global.active_camera.set_focused(false)
			Global.active_camera.set_current_target(global_position + Vector2.from_angle(rotation).normalized() * VIEW_MARGIN_DEFAULT)
			Global.active_camera.tilt_to_angle(0)

func trigger_slash() -> void:
	blade_direction *= -1
	SlashTimer.start()
	slashing = true

func animate_slash() -> void:
	Blade.transform.origin = Blade.transform.origin.rotated(SLASH_ANGLE * blade_direction)
	Blade.rotation += SLASH_DEGREE * blade_direction

func trigger_thrust() -> void:
	center_blade()
	ThrustTimer.start()
	thrusting = true

func animate_thrust() -> void:
	Blade.transform.origin.x = THRUST_X_OFFSET - sin(ThrustTimer.time_left * THRUST_TIME_FACTOR) * THRUST_PUSH

func center_blade() -> void:
	Blade.transform.origin.y = Head.rotation #center the blade
	Blade.set_rotation(PI * 0.5 * -blade_direction)

func reset_blade() -> void:
	slashing = false
	thrusting = false
	
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

func trigger_execution() -> void:
	executing = true
	
	if move_state == MOVEMENT_STATES.RUSH:
		RushTimer.stop()
		clear_rush()
	
	reset_blade() #safeguard
	
	execution_point = cursor
	ExecutionTimer.start()

func animate_execution_strike() -> void: #spin into a thrust
	if ExecutionTimer.time_left >= EXECUTION_TIME * 0.5:
		Blade.transform.origin = Blade.transform.origin.rotated(EXECUTION_ANGLE * blade_direction)
		Blade.rotation += EXECUTION_DEGREE * blade_direction
	else:
		center_blade()
		Blade.transform.origin.x = EXECUTION_X_OFFSET - sin(ExecutionTimer.time_left * EXECUTION_TIME_FACTOR) * EXECUTION_PUSH

func animate_execution_movement() -> void: #animate the launch toward an enemy
	Wings.position.x = -( (ExecutionTimer.time_left * 0.5) * EXECUTION_RUSH_TIME_FACTOR)
	Head.position.x = ( (ExecutionTimer.time_left * 0.5) * EXECUTION_RUSH_TIME_FACTOR * HEAD_SHIFT_FACTOR)
	Body.position.x = ( (ExecutionTimer.time_left * 0.5) * EXECUTION_RUSH_TIME_FACTOR * BODY_SHIFT_FACTOR)
	AuxillaryAnchor.position.x = AUXILLARY_START.x + ( (ExecutionTimer.time_left * 0.5) * EXECUTION_RUSH_TIME_FACTOR)

func handle_execution() -> void:
	global_position.x = Global.interpolate_value(global_position.x, execution_point.x, 0.3, 0.5)
	global_position.y = Global.interpolate_value(global_position.y, execution_point.y, 0.3, 0.5)
	
	animate_execution_strike()
	animate_execution_movement()

func clear_execution() -> void:
	executing = false
	
	reset_blade()
	
	core_heat = min(core_heat_max, core_heat + EXECUTION_COOLING)
	weapon_heat = 0
	Events.weapon_heat_updated.emit(weapon_heat)

func trigger_rush() -> void:
	weapon_heat += rush_heat
	Events.weapon_heat_updated.emit(weapon_heat)
	RushTimer.start()

func animate_rush() -> void:
	Wings.position.x = -(RushTimer.time_left * RUSH_TIME_FACTOR)
	Head.position.x = (RushTimer.time_left * RUSH_TIME_FACTOR * HEAD_SHIFT_FACTOR)
	Body.position.x = (RushTimer.time_left * RUSH_TIME_FACTOR * BODY_SHIFT_FACTOR)
	AuxillaryAnchor.position.x = AUXILLARY_START.x + (RushTimer.time_left * RUSH_TIME_FACTOR)

func handle_rush() -> void:
	velocity = Vector2(cos(rotation), sin(rotation)).normalized() * current_speed
	animate_rush()

func clear_rush() -> void: #reset movement and chassis part positioning
	move_state = move_state_stack.back()
	current_speed = SPEED_DICT[move_state]
	
	Wings.position.x = 0
	Body.position.x = 0
	Head.position.x = 0
	AuxillaryAnchor.position.x = AUXILLARY_START.x 

"""
do later -
figure out some equation for heat generation with relation to number of shots,
preferrably reduced by some factor
"""
func fire_auxillary() -> void:
	AuxillaryCooldown.start()
	
	var shots: int = 8
	var spread: float = 0.4 * aim_choke
	var shot_angle: float = AuxillaryAnchor.global_rotation
	var shot_speed: float = 100
	var shot_start = CannonPoint.global_position
	var heat: float = randf_range(weapon_heat_range.x, weapon_heat_range.y) 
	
	#heat *= (shots * 0.4) 
	#PlayerGun.multifire_radial(shots, spread, shot_speed, shot_angle, shot_start)
	PlayerGun.fire(shot_speed, shot_angle, shot_start)
	
	weapon_heat += heat
	Events.weapon_heat_updated.emit(weapon_heat)

func cool_weapon() -> void:
	if move_state == MOVEMENT_STATES.FOCUS:
		weapon_heat = max(0, weapon_heat - WEAPON_COOL_RATE_FOCUSED * get_physics_process_delta_time())
	else:
		weapon_heat = max(0, weapon_heat - WEAPON_COOL_RATE * get_physics_process_delta_time())
	
	Events.weapon_heat_updated.emit(weapon_heat)

func check_heat(value: float) -> void:
	if value >= weapon_heat_max:
		overheated = true
		Events.core_overheated.emit()
	else:
		overheated = false

func tick_overheat_damage() -> void:
	core_heat -= OVERHEAT_DAMAGE * get_physics_process_delta_time()
