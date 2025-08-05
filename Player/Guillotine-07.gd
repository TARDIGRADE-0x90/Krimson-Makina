extends CharacterBody2D
class_name Player

"""
TO DO:
	- Uncalibrated ping at top center of player UI, ficker when an enemy becomes uncalibrated
	
	- Create Options UI and input rebinding ASAP
	
	- Execution:
		Boss or otherwise more significant enemies are immune to Uncalibration
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
const THRUST_TIME: float = 0.2
const EXECUTION_TIME: float = 0.8

const BLADE_BASE_CRIT: float = 0.05
const GUN_BASE_CRIT: float = 0.02
const CRIT_MOD_DEFAULT: float = 10.0
const CRIT_MOD_FOCUS: float = 10.25
const CRIT_MOD_RUSH: float = 10.5
const CRIT_MOD_EXECUTING: float = 12.0

const BLADE_BASE_DAMAGE: float = 25.0
const THRUST_DAMAGE_MODIFIER: float = 0.8
const RUSH_DAMAGE_MODIFIER: float = 1.2

const EXECUTION_RUSH_TIME_FACTOR: int = 120
const RUSH_TIME_FACTOR: int = 100
const HEAD_SHIFT_FACTOR: float = 1.8
const BODY_SHIFT_FACTOR: float = 1.2

const CORE_HEAT_INITIAL_MAX: float = 200.0

const RUSH_HEAT_DEFAULT: float = 35.0
const HIT_HEAT: float = 40.0

const AUXILIARY_HEAT_MAX: float = 150.0
const AUXILIARY_COOL_RATE: float = 45 #multiplied against delta
const AUXILIARY_COOL_RATE_FOCUSED: float = 24 #multiplied against delta
const AUXILIARY_EMERGENCY_COOLING: float = 2.0 #multiplies against cool rate when heat exceeds a threshold

const OVERHEAT_EMERGENCY_THRESHOLD: float = 1.75
const OVERHEAT_DAMAGE_RATE: float = 4 #multiplied against delta

const EXECUTION_CORE_HEAL: float = 0.5

const AIM_CHOKE_DEFAULT: float = 1.0
const AIM_CHOKE_FOCUS: float = 0.4
const AIM_CHOKE_RUSH: float = 1.5

const BLADE_SCALE := Vector2(1.2, 1.2)
const BLADE_START := Vector2(0, 320)
const BLADE_SLASH_REST := Vector2(0, -320)
const BLADE_T_X_DEFAULT := Vector2(1, 0)

const SLASH_ANGLE: float = (PI * 0.06)
const SLASH_DEGREE: float = 0.2

const THRUST_X_OFFSET: int = 320
const THRUST_TIME_FACTOR: int = 22
const THRUST_PUSH: int = 200

const EXECUTION_ANGLE: float = (PI * 0.12)
const EXECUTION_DEGREE: float = 0.8
const EXECUTION_X_OFFSET: int = 128
const EXECUTION_TIME_FACTOR: int = 24
const EXECUTION_PUSH: int = 260

const GUN_START := Vector2(0, -64)
const FOCUS_AIM_BOUND := Vector2(100, 0)

const Z_BLADE: int = 1
const Z_GUN: int = 1
const Z_WINGS: int = 0
const Z_BODY: int = 2
const Z_HEAD: int = 3

@export var ACCELERATION: float = 0.2;

@onready var RushTimer: Timer = $RushTimer
@onready var SlashTimer: Timer = $SlashTimer
@onready var ThrustTimer: Timer = $ThrustTimer
@onready var ExecutionTimer: Timer = $ExecutionTimer
@onready var GunCooldown: Timer = $GunCooldown

@onready var Hurtbox: Area2D = $Hurtbox
@onready var FullBody: Node2D = $FullBody
@onready var Wings: Sprite2D = $FullBody/Wings
@onready var Body: Sprite2D  = $FullBody/Body
@onready var Head: Sprite2D  = $FullBody/Head
@onready var Blade: Area2D = $Blade
@onready var GunAnchor: Node2D = $GunAnchor
@onready var CannonPoint: Marker2D = $GunAnchor/CannonPoint
@onready var PlayerGun: ProjectileManager = $GunAnchor/PlayerGun

@onready var FlashHandler: HitFlashHandler = $FlashHandler
@onready var ShotDetector: Shootable = $ShotDetector

var current_speed: int = 0
var current_direction = Vector2(0,0)

var cursor = Vector2(0,0)

var input_x: int = 0
var input_y: int = 0

var move_state_stack: Array
var move_state: int = MOVEMENT_STATES.HOVER

var blade_direction: int = 1
var blade_position: Vector2 = BLADE_START
var blade_damage: float = BLADE_BASE_DAMAGE

var crit_modifier: float = 1.0
var shot_dmg_mod: float = 1.0

var gun_held: bool = false
var focus_held: bool = false

var rushing: bool = false
var slashing: bool = false
var thrusting: bool = false

var can_execute: bool = false
var executing: bool = false
var execution_point: Vector2 = ZERO_VECTOR
var execution_body: Node2D

var core_heat_max: float = CORE_HEAT_INITIAL_MAX
var core_heat: float = CORE_HEAT_INITIAL_MAX

var auxiliary_heat_max: float = AUXILIARY_HEAT_MAX
var auxiliary_heat: float = 0

var gun_heat_range: Vector2
var gun_firerate: float
var aim_choke: float = 1.0

var rush_heat: float = RUSH_HEAT_DEFAULT

var overheated: bool = false

func _ready() -> void:
	Global.player = self
	
	CollisionBits.set_layer(self, CollisionBits.ENEMY_PROJECTILE_BIT, false) # override what ShotDetector does (spaghetti btw)
	CollisionBits.set_layer(Hurtbox, CollisionBits.ENEMY_PROJECTILE_BIT, true)
	CollisionBits.set_mask(Blade, CollisionBits.PLAYER_SWORD_BIT, true)
	
	initialize_z_ordering()
	FlashHandler.assign_sprites([Head, Body, Wings])
	
	move_state_stack.append(MOVEMENT_STATES.HOVER) #default speed in the movement queue VERY IMPORTANT
	current_speed = SPEED_DICT[MOVEMENT_STATES.HOVER]
	
	Blade.scale = BLADE_SCALE
	Blade.position = BLADE_START
	GunAnchor.position = GUN_START
	
	gun_heat_range = PlayerGun.get_gun().HeatRange
	gun_firerate = PlayerGun.get_gun().FireRate
	
	PlayerGun.flag_collision_override(ProjectileData.CollisionTypes.PLAYER)
	
	initialize_rush_timer()
	initialize_slash_timer()
	initialize_thrust_timer()
	initialize_execution_timer()
	initialize_gun_cooldown()
	
	Events.execution_ready.connect(prime_execution)
	Events.execution_unready.connect(func(): can_execute = false)
	Events.weapon_heat_updated.connect(check_heat)
	ShotDetector.shot_detected.connect(read_damage)

func _physics_process(delta: float) -> void:
	Global.player_position = global_position
	
	cursor = get_global_mouse_position()
	
	if move_state != MOVEMENT_STATES.FOCUS and !executing:
		look_at(cursor)
	
	handle_looking()
	handle_aim_choke()
	handle_crit_modifier()
	
	update_direction()
	update_velocity()
	
	if slashing || thrusting || executing:
		check_blade_collision()
	
	if slashing:
		animate_slash()
	
	if thrusting:
		animate_thrust()
	
	if move_state == MOVEMENT_STATES.RUSH:
		handle_rush()
	
	if gun_held and GunCooldown.is_stopped() and !executing:
		fire_gun()
	
	if !gun_held:
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

func initialize_gun_cooldown() -> void:
	GunCooldown.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	GunCooldown.set_wait_time(gun_firerate)
	GunCooldown.set_one_shot(true)

func initialize_z_ordering() -> void:
	Head.z_index = Z_HEAD
	Body.z_index = Z_BODY
	Wings.z_index = Z_WINGS
	Blade.z_index = Z_BLADE
	GunAnchor.z_index = Z_GUN

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
	if executing || move_state == MOVEMENT_STATES.RUSH:
		current_direction = ZERO_VECTOR
		return
	
	input_x = int(Input.is_action_pressed(Inputs.MOVE_RIGHT)) - int(Input.is_action_pressed(Inputs.MOVE_LEFT));
	input_y = int(Input.is_action_pressed(Inputs.MOVE_DOWN)) - int(Input.is_action_pressed(Inputs.MOVE_UP));
	
	current_direction = Vector2(input_x, input_y).normalized()
	
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
		gun_held = true
	
	if event.is_action_released(Inputs.AUXILLARY):
		gun_held = false

func parse_input_execution(event: InputEvent) -> void:
	#do later - add conditional for execution_ready, true if cursor is within a "Vulnerable" vec2 by vec2 bound
	if event.is_action_pressed(Inputs.EXECUTE) and !executing and can_execute:
		trigger_execution()

func handle_looking() -> void: #remember that this method, as it is now, is literally running every frame
	if move_state == MOVEMENT_STATES.FOCUS and !executing:
		look_at_with_bound(GunAnchor, cursor, FOCUS_AIM_BOUND)
		look_at_with_bound(Head, cursor, FOCUS_AIM_BOUND)
		
		if Global.active_camera:
			Global.active_camera.set_focused(true)
			Global.active_camera.set_current_target(global_position + Vector2.from_angle(rotation).normalized() * VIEW_MARGIN_FOCUS)
			Global.active_camera.tilt_to_angle(Head.rotation)
	
	elif executing:
		set_rotation(global_position.angle_to_point(execution_point))
		GunAnchor.set_rotation(0)
		Head.set_rotation(0)
		
		Global.active_camera.set_focused(false)
		Global.active_camera.snap_to_target(global_position + Vector2.from_angle(rotation).normalized() * VIEW_MARGIN_EXECUTION)

	else:
		GunAnchor.set_rotation(0)
		Head.set_rotation(0)
		
		if Global.active_camera:
			Global.active_camera.set_focused(false)
			Global.active_camera.set_current_target(global_position + Vector2.from_angle(rotation).normalized() * VIEW_MARGIN_DEFAULT)
			Global.active_camera.tilt_to_angle(0)

func handle_crit_modifier() -> void:
	if executing:
		crit_modifier = CRIT_MOD_EXECUTING
	else:
		match move_state:
			MOVEMENT_STATES.HOVER:
				crit_modifier = CRIT_MOD_DEFAULT
			MOVEMENT_STATES.FOCUS:
				crit_modifier = CRIT_MOD_FOCUS
			MOVEMENT_STATES.RUSH:
				crit_modifier = CRIT_MOD_RUSH

func handle_aim_choke() -> void:
	match move_state:
		MOVEMENT_STATES.HOVER:
			aim_choke = AIM_CHOKE_DEFAULT
		MOVEMENT_STATES.FOCUS:
			aim_choke = AIM_CHOKE_FOCUS
		MOVEMENT_STATES.RUSH:
			aim_choke = AIM_CHOKE_RUSH

func trigger_slash() -> void:
	melee_hits.clear() ## ABYSMAL DOGSHIT WARNING ##
	blade_damage = BLADE_BASE_DAMAGE
	if rushing:
		blade_damage *= RUSH_DAMAGE_MODIFIER
	
	blade_direction *= -1
	SlashTimer.start()
	slashing = true

func animate_slash() -> void:
	Blade.transform.origin = Blade.transform.origin.rotated(SLASH_ANGLE * blade_direction)
	Blade.rotation += SLASH_DEGREE * blade_direction

func trigger_thrust() -> void:
	melee_hits.clear() ## ABYSMAL DOGSHIT WARNING ##
	blade_damage = BLADE_BASE_DAMAGE * THRUST_DAMAGE_MODIFIER
	if rushing:
		blade_damage *= RUSH_DAMAGE_MODIFIER
	
	Blade.transform.origin.y = Head.rotation #center the blade
	Blade.set_rotation(Head.rotation + (-PI * 0.5)) 
	
	ThrustTimer.start()
	thrusting = true

func animate_thrust() -> void:
	Blade.translate(Vector2.from_angle(Blade.rotation + (PI * 0.5) ) * THRUST_PUSH * sin(ThrustTimer.time_left * THRUST_TIME_FACTOR))

var melee_hits: Array[Meleeable] #very very dumb but I'm doing this anyway
func check_blade_collision() -> void:
	if Blade.has_overlapping_bodies():
		for i in range(Blade.get_overlapping_bodies().size()):
			var melee_body: CollisionObject2D = Blade.get_overlapping_bodies()[i]
			var melee_detector: Meleeable
			
			if melee_body.has_meta(Global.META_MELEEABLE_REF):
				melee_detector = melee_body.get_meta(Global.META_MELEEABLE_REF)
				if !melee_hits.has(melee_detector):
					melee_detector.melee_detected.emit(blade_damage, BLADE_BASE_CRIT * crit_modifier)
					melee_hits.append(melee_detector)

func center_blade() -> void:
	Blade.transform.origin.y = Head.rotation #center the blade
	Blade.set_rotation(PI * 0.5 * -blade_direction)

func clear_melee_hits() -> void:
	for i in range(melee_hits.size()):
		melee_hits[i].melee_cleared.emit()

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
	
	Blade.position = blade_position
	blade_damage = BLADE_BASE_DAMAGE #then multiply by any ongoing modifiers after
	clear_melee_hits()

func prime_execution(target: Vector2, target_body: Node2D) -> void:
	can_execute = true
	execution_body = target_body
	execution_point = target

func trigger_execution() -> void:
	melee_hits.clear() ## ABYSMAL DOGSHIT WARNING ##
	
	Events.execution_initiated.emit(execution_body)
	
	blade_damage = BLADE_BASE_DAMAGE
	
	executing = true
	
	if move_state == MOVEMENT_STATES.RUSH:
		RushTimer.stop()
		clear_rush()
	
	if slashing:
		SlashTimer.stop()
	
	if thrusting:
		ThrustTimer.stop()
	
	reset_blade() #safeguard
	
	ExecutionTimer.start()

var execution_thrusted: bool = false

func animate_execution_strike() -> void: #spin into a thrust
	if ExecutionTimer.time_left >= EXECUTION_TIME * 0.5:
		Blade.transform.origin = Blade.transform.origin.rotated(EXECUTION_ANGLE * blade_direction)
		Blade.rotation += EXECUTION_DEGREE * blade_direction
	else:
		
		if !execution_thrusted: ## spaghetti warning
			Events.execution_struck.emit(execution_body)
			execution_thrusted = true
		
		Blade.transform.origin.y = Head.rotation #center the blade
		Blade.set_rotation(Head.rotation + (-PI * 0.5)) 
		Blade.transform.origin.x = EXECUTION_X_OFFSET - sin(ExecutionTimer.time_left * EXECUTION_TIME_FACTOR) * EXECUTION_PUSH

func animate_execution_movement() -> void: #animate the launch toward an enemy
	Wings.position.x = -( (ExecutionTimer.time_left * 0.5) * EXECUTION_RUSH_TIME_FACTOR)
	Head.position.x = ( (ExecutionTimer.time_left * 0.5) * EXECUTION_RUSH_TIME_FACTOR * HEAD_SHIFT_FACTOR)
	Body.position.x = ( (ExecutionTimer.time_left * 0.5) * EXECUTION_RUSH_TIME_FACTOR * BODY_SHIFT_FACTOR)
	GunAnchor.position.x = GUN_START.x + ( (ExecutionTimer.time_left * 0.5) * EXECUTION_RUSH_TIME_FACTOR)

func handle_execution() -> void:
	global_position.x = Global.interpolate_value(global_position.x, execution_point.x, 0.3, 0.5)
	global_position.y = Global.interpolate_value(global_position.y, execution_point.y, 0.3, 0.5)
	
	animate_execution_strike()
	animate_execution_movement()

func clear_execution() -> void:
	execution_thrusted = false
	executing = false
	
	reset_blade()
	
	core_heat = min(core_heat_max, core_heat + (core_heat_max * EXECUTION_CORE_HEAL))
	auxiliary_heat = 0
	Events.weapon_heat_updated.emit(auxiliary_heat)

func trigger_rush() -> void:
	rushing = true
	auxiliary_heat += rush_heat
	Events.weapon_heat_updated.emit(auxiliary_heat)
	RushTimer.start()

func animate_rush() -> void:
	Wings.position.x = -(RushTimer.time_left * RUSH_TIME_FACTOR)
	Head.position.x = (RushTimer.time_left * RUSH_TIME_FACTOR * HEAD_SHIFT_FACTOR)
	Body.position.x = (RushTimer.time_left * RUSH_TIME_FACTOR * BODY_SHIFT_FACTOR)
	GunAnchor.position.x = GUN_START.x + (RushTimer.time_left * RUSH_TIME_FACTOR)

func handle_rush() -> void:
	velocity = Vector2(cos(rotation), sin(rotation)).normalized() * current_speed
	animate_rush()

func clear_rush() -> void: #reset movement and chassis part positioning
	rushing = false
	move_state = move_state_stack.back()
	current_speed = SPEED_DICT[move_state]
	
	Wings.position.x = 0
	Body.position.x = 0
	Head.position.x = 0
	GunAnchor.position.x = GUN_START.x 

"""
do later -
figure out some equation for heat generation with relation to number of shots,
preferrably reduced by some factor
"""
func fire_gun() -> void:
	GunCooldown.start()
	
	var heat: float = randf_range(gun_heat_range.x, gun_heat_range.y) 
	
	if PlayerGun.get_gun().Shots > 1:
		heat = heat + (PlayerGun.get_gun().Shots * 0.75)
	
	if PlayerGun.get_gun().Spread >= 0:
		PlayerGun.get_gun().Spread *= aim_choke
	
	PlayerGun.fire(CannonPoint.global_position, GunAnchor.global_rotation, shot_dmg_mod, GUN_BASE_CRIT * crit_modifier)
	
	auxiliary_heat += heat
	Events.weapon_heat_updated.emit(auxiliary_heat)

var cooling: float = 1.0
func cool_weapon() -> void:
	if auxiliary_heat >= auxiliary_heat_max * OVERHEAT_EMERGENCY_THRESHOLD:
		cooling = AUXILIARY_EMERGENCY_COOLING
	else:
		cooling = 1.0
	
	if move_state == MOVEMENT_STATES.FOCUS:
		auxiliary_heat = max(0, auxiliary_heat - AUXILIARY_COOL_RATE_FOCUSED * cooling * get_physics_process_delta_time())
	else:
		auxiliary_heat = max(0, auxiliary_heat - AUXILIARY_COOL_RATE * cooling * get_physics_process_delta_time())
	
	Events.weapon_heat_updated.emit(auxiliary_heat)

func check_heat(value: float) -> void:
	if value >= auxiliary_heat_max:
		overheated = true
		Events.core_overheated.emit()
	else:
		overheated = false

func read_damage(amount: float, crit: float = 0.0) -> void:
	if not executing: #invincible during execution
		core_heat -= amount
		
		auxiliary_heat += HIT_HEAT
		Events.weapon_heat_updated.emit(auxiliary_heat)
		
		FlashHandler.trigger_flash()

func tick_overheat_damage() -> void:
	core_heat -= OVERHEAT_DAMAGE_RATE * get_physics_process_delta_time()
