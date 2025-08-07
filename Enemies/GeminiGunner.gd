extends CharacterBody2D
class_name GeminiGunner

const BLAST_MARK: PackedScene = preload(FilePaths.BLAST_MARK)
const GUN_DROP: PackedScene = preload(FilePaths.DROPPED_GUN)

const DROP_CHANCE: float = 0.2

const BASE_HEALTH: float = 75.0

const BASE_SPIN_RATE: int = 140
const DAMAGE_SPIN_BUFF: float = 2.0
const DAMAGE_FIRERATE_BUFF: float = 0.005
const DAMAGE_SPEED_BUFF: float = 2

const BOUNCE_RANGE := Vector2(PI * 0.5, PI * 1.25)

const SPEED_ROAMING: int = 200
const SPEED_AGGRO: int = 600
const SPEED_DEBUFF: float = 0.25

@export var MachineTitle: String

@onready var _UncalibrationUI: UncalibrationUI = $UncalibrationUI
@onready var _AggroBound: AggroBound = $AggroBound
@onready var _Shootable: Shootable = $Shootable
@onready var _Meleeable: Meleeable = $Meleeable
@onready var _HitFlashHandler: HitFlashHandler = $HitFlashHandler
@onready var _DeathDelay: DeathDelay = $DeathDelay
@onready var GammaGun: ProjectileManager = $GammaGun
@onready var Firerate: Timer = $Firerate

@onready var FullBody: Node2D = $FullBody

@onready var Gun1: Sprite2D = $FullBody/TopGun
@onready var Gun2: Sprite2D = $FullBody/BottomGun
@onready var Core: Sprite2D = $FullBody/Core

@onready var MuzzleTop = $FullBody/MuzzleTop
@onready var MuzzleBottom = $FullBody/MuzzleBottom

var target: Vector2
var health: float = BASE_HEALTH

var last_wall_normal: Vector2
var move_angle: float
var speed: float
var bonus_speed: float
var spin_rate: int = BASE_SPIN_RATE

var aggroed: bool = false
var uncalibrated: bool = false
var destroyed: bool = false

func _ready() -> void:
	speed = SPEED_ROAMING
	
	initialize_firerate()
	set_rotation_degrees(randi_range(0, 360))
	set_velocity(Vector2.from_angle(rotation) * (speed + bonus_speed))
	
	_AggroBound.global_position = global_position #safeguard
	
	_HitFlashHandler.assign_sprites([FullBody])
	_Meleeable.melee_detected.connect(read_damage)
	_Shootable.shot_detected.connect(read_damage)
	_UncalibrationUI.triggered.connect(uncalibrate)
	_UncalibrationUI.cleared.connect(recalibrate)
	
	
	GammaGun.flag_collision_override(ProjectileData.CollisionTypes.ENEMY)
	
	Events.execution_initiated.connect(prepare_to_die)
	Events.execution_struck.connect(execute)

func _physics_process(delta: float) -> void:
	if aggroed:
		spin_guns(delta)
		
		if Firerate.is_stopped():
			fire()
	
	if (last_wall_normal != get_wall_normal()):
		last_wall_normal = get_wall_normal()
		set_rotation(-get_angle_to(last_wall_normal))
		set_velocity(Vector2.from_angle(rotation + randf_range(BOUNCE_RANGE.y, BOUNCE_RANGE.x)) * (speed + bonus_speed))
	
	move_and_slide()

func _process(delta: float) -> void:
	_UncalibrationUI.update_target_bound()
	
	if !aggroed: #big condition that runs until player vec is in aggro bound
		_AggroBound.set_aggro_target(Global.player_position)
		_AggroBound.update_bound()
		
		if _AggroBound.is_aggroed(): 
			speed = SPEED_AGGRO
			set_velocity(Vector2.from_angle(rotation) * (speed + bonus_speed))
			_AggroBound.stop()
			aggroed = true

func initialize_firerate() -> void:
	Firerate.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	Firerate.set_wait_time(GammaGun.get_gun().FireRate)
	Firerate.set_one_shot(true)

var incoming_spin_rate: float
func spin_guns(delta: float) -> void:
	incoming_spin_rate = spin_rate
	if uncalibrated: incoming_spin_rate *= SPEED_DEBUFF
	
	FullBody.rotation_degrees += (incoming_spin_rate * delta)

func fire() -> void:
	GammaGun.fire(MuzzleTop.global_position, MuzzleTop.global_rotation + (PI * 0.5))
	GammaGun.fire(MuzzleBottom.global_position, MuzzleBottom.global_rotation + (PI * 0.5))
	
	Firerate.start()

func uncalibrate() -> void:
	speed *= SPEED_DEBUFF

func recalibrate() -> void:
	uncalibrated = false
	speed = SPEED_AGGRO

var crit_query: float = 0.0
func read_damage(amount: float, crit: float = 0.0) -> void:
	if !aggroed:
		aggroed = true
	
	health -= amount
	spin_rate += (amount * DAMAGE_SPIN_BUFF)
	bonus_speed += (amount * DAMAGE_SPEED_BUFF)
	
	Firerate.set_wait_time(Firerate.wait_time - DAMAGE_FIRERATE_BUFF)
	
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

func generate_blast_mark() -> void:
	var blast_mark: Sprite2D = BLAST_MARK.instantiate()
	Global.current_level.call_deferred("add_child", blast_mark)
	blast_mark.set_rotation_degrees(randi_range(0, 360))
	blast_mark.global_position = global_position

func generate_gun_drop(chance: float = 1.0) -> void:
	var chance_query: float = randf()
	
	if chance_query <= chance:
		var dropped_gun: DroppedGun = GUN_DROP.instantiate()
		Global.current_level.call_deferred("add_child", dropped_gun)
		dropped_gun.global_position = global_position
		dropped_gun.drop(global_position, GammaGun.get_gun())

func destroy() -> void:
	if !destroyed:
		destroyed = true
		
		set_physics_process(false)
		set_visible(false)
		
		Events.target_destroyed.emit()
		
		generate_blast_mark()
		generate_gun_drop(DROP_CHANCE)
		
		CollisionBits.set_mask_and_layer(self, CollisionBits.DEFAULT_BIT, false)
		CollisionBits.set_mask_and_layer(self, CollisionBits.PLAYER_PROJECTILE_BIT, false)
		CollisionBits.set_mask_and_layer(self, CollisionBits.PLAYER_SWORD_BIT, false)
		
		_DeathDelay.start()
