extends CharacterBody2D
class_name Striker

const BLAST_MARK_PATH: String = "res://BlastMark.tscn"
const BLAST_MARK: PackedScene = preload(BLAST_MARK_PATH)

const BASE_HEALTH: float = 150.0

const ROTATION_RATE: int = 175

const MOVE_TIME_RANGE := Vector2(1.4, 3.0)

const BASE_SPEED: float = 800

const UNCALIBRATION_DEBUFF: float = 0.25

const DEATH_DELAY: float = 5.0

@export var MachineTitle: String

@export var MoveBound: Vector4

@onready var _AggroCast: AggroCast = $AggroCast
@onready var _AggroBound: AggroBound = $AggroBound
@onready var _DeathDelay: DeathDelay = $DeathDelay
@onready var _Shootable: Shootable = $Shootable
@onready var _Meleeable: Meleeable = $Meleeable
@onready var _HitFlashHandler: HitFlashHandler = $HitFlashHandler
@onready var _UncalibrationUI: UncalibrationUI = $UncalibrationUI
#@onready var _MoveBoundCast: MoveBoundCast = $MoveBoundCast
@onready var DualSabots: ProjectileManager = $DualSabots
@onready var Firerate: Timer = $Firerate
@onready var MoveTime: Timer = $MoveTime

@onready var FullBody: Node2D = $FullBody
@onready var Head: Sprite2D = $FullBody/Head
@onready var Body: Sprite2D = $FullBody/Body
@onready var Base: Sprite2D = $FullBody/Base
@onready var Muzzle: Marker2D = $FullBody/Body/Muzzle

var health: float = BASE_HEALTH

var aim_target: Vector2
var move_target: Vector2
var move_angle: float
var rotation_rate: float = ROTATION_RATE
var speed: float

var aggroed: bool = false
var uncalibrated: bool = false
var destroyed: bool = false

func _ready() -> void:
	initialize_firerate()
	initialize_move_time()
	
	set_velocity(Vector2(0, 0)) #is still on start
	speed = BASE_SPEED
	
	set_rotation_degrees(randi_range(0, 360))
	
	_AggroBound.global_position = global_position #safeguard
	_HitFlashHandler.assign_sprites([FullBody])
	_Meleeable.melee_detected.connect(read_damage)
	_Shootable.shot_detected.connect(read_damage)
	_UncalibrationUI.triggered.connect(uncalibrate)
	_UncalibrationUI.cleared.connect(recalibrate)
	
	Events.execution_initiated.connect(prepare_to_die)
	Events.execution_struck.connect(execute)

func _physics_process(delta: float) -> void:
	if Global.current_level.player_loaded:
		update_aim_target(Global.player_position)
	
	#rotation -= 4 * delta
	if aggroed:
		smooth_to_target(delta)
		
		if MoveTime.is_stopped():
			shift_move_angle()
		
		if Firerate.is_stopped():
			fire()
	
	move_and_slide()

func _process(delta: float) -> void:
	_UncalibrationUI.update_target_bound()
	
	if !aggroed: #big condition that runs until player vec is in aggro bound
		_AggroBound.set_aggro_target(Global.player_position)
		_AggroBound.update_bound()
		
		if _AggroBound.is_aggroed() && _AggroCast.is_aggroed(): 
			_AggroBound.stop()
			aggroed = true

func shift_move_angle() -> void:
	var global_move_bound = Vector4(
		global_position.x + MoveBound.x,
		global_position.x + MoveBound.y,
		global_position.y + MoveBound.z,
		global_position.y + MoveBound.w
	)
	
	var new_move_target := Vector2(randi_range(global_move_bound.x, global_move_bound.y), randi_range(global_move_bound.z, global_move_bound.w))
	
	move_angle = get_angle_to(new_move_target)
	Base.set_rotation(move_angle)
	set_velocity(Vector2.from_angle(move_angle) * speed)
	
	MoveTime.set_wait_time(randf_range(MOVE_TIME_RANGE.x, MOVE_TIME_RANGE.y))
	MoveTime.start()

func initialize_firerate() -> void:
	Firerate.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	Firerate.set_wait_time(DualSabots.get_gun().FireRate)
	Firerate.set_one_shot(true)

func initialize_move_time() -> void:
	MoveTime.set_wait_time(randf_range(MOVE_TIME_RANGE.x, MOVE_TIME_RANGE.y))
	MoveTime.set_one_shot(true)
	MoveTime.timeout.connect(shift_move_angle)

func update_aim_target(target: Vector2) -> void:
	aim_target = target
	_AggroCast.set_aggro_target(target)

func smooth_to_target(delta: float) -> void:
	if uncalibrated: rotation_rate = ROTATION_RATE * UNCALIBRATION_DEBUFF
	else: rotation_rate = ROTATION_RATE
	
	Body.rotation_degrees += rotation_rate * delta * signi(rad_to_deg(Body.get_angle_to(aim_target)))
	Head.rotation_degrees += rotation_rate * delta * signi(rad_to_deg(Head.get_angle_to(aim_target)))

func fire() -> void:
	DualSabots.fire(Muzzle.global_position, Muzzle.global_rotation)
	Firerate.start()

func uncalibrate() -> void:
	speed *= UNCALIBRATION_DEBUFF

func recalibrate() -> void:
	uncalibrated = false #clear debuff
	speed = BASE_SPEED

var crit_query: float = 0.0
func read_damage(amount: float, crit: float = 0.0) -> void:
	if !aggroed:
		aggroed = true
	
	health -= amount
	
	if health <= 0:
		destroy()
		return
	
	crit_query = randf()
	
	if crit_query <= crit:
		uncalibrated = true
		_UncalibrationUI.trigger()
	
	_HitFlashHandler.trigger_flash()
	Events.new_target_hit.emit(MachineTitle, health, BASE_HEALTH)

func prepare_to_die(body_arg: Node2D) -> void:
	if self != body_arg:
		return
	else:
		CollisionBits.set_mask_and_layer(self, CollisionBits.PLAYER_PROJECTILE_BIT, false)
		CollisionBits.set_mask_and_layer(self, CollisionBits.PLAYER_SWORD_BIT, false)
		_UncalibrationUI.close()
		set_physics_process(false)

func execute(body_arg: Node2D) -> void:
	if self != body_arg:
		return
	else:
		destroy()

func destroy() -> void:
	if !destroyed:
		destroyed = true
		
		set_physics_process(false)
		set_visible(false)
		
		Events.target_destroyed.emit()
		
		var blast_mark: Sprite2D = BLAST_MARK.instantiate()
		Global.current_level.call_deferred("add_child", blast_mark)
		blast_mark.set_rotation_degrees(randi_range(0, 360))
		blast_mark.global_position = global_position
		
		CollisionBits.set_mask_and_layer(self, CollisionBits.DEFAULT_BIT, false)
		CollisionBits.set_mask_and_layer(self, CollisionBits.PLAYER_PROJECTILE_BIT, false)
		CollisionBits.set_mask_and_layer(self, CollisionBits.PLAYER_SWORD_BIT, false)
		
		_DeathDelay.start()
