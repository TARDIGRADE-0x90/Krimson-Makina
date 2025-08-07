extends StaticBody2D
class_name PlasmaTrigunTurret

const BLAST_MARK_PATH: String = "res://BlastMark.tscn"
const BLAST_MARK: PackedScene = preload(BLAST_MARK_PATH)

const BASE_HEALTH: float = 100.0

const AIM_TIME: float = 1.0
const AIM_DAMP: float = 0.5

const ROTATION_RATE: int = 100
const ROTATION_DEBUFF: float = 0.25

@export var MachineTitle: String

@onready var _UncalibrationUI: UncalibrationUI = $UncalibrationUI
@onready var _AggroCast: AggroCast = $AggroCast
@onready var Base: Sprite2D = $FullBody/Base
@onready var Guns: Sprite2D = $FullBody/Guns
@onready var Destruction: DeathDelay = $Destruction
@onready var Firerate: Timer = $Firerate
@onready var PlasmaGun: ProjectileManager = $PlasmaGun
@onready var ShootDetect: Shootable = $Shootable
@onready var MeleeDetect: Meleeable = $Meleeable
@onready var FlashHandler: HitFlashHandler = $FlashHandler

var target: Vector2
var health: float = BASE_HEALTH
var rotation_rate: float = ROTATION_RATE
var aggroed: bool = false
var uncalibrated: bool = false
var destroyed: bool = false
var cannon_index: int = 0

func _ready() -> void:
	Guns.rotation_degrees = randi_range(0, 360)
	
	initialize_firerate()
	
	FlashHandler.assign_sprites([Base, Guns])
	MeleeDetect.melee_detected.connect(read_damage)
	ShootDetect.shot_detected.connect(read_damage)
	_UncalibrationUI.cleared.connect(func(): uncalibrated = false)
	
	Events.execution_initiated.connect(prepare_to_die)
	Events.execution_struck.connect(execute)

func _physics_process(delta: float) -> void:
	if Global.current_level.player_loaded:
		update_target(Global.player_position)
	
	if _AggroCast.is_aggroed():
		smooth_to_target(delta)
		
		if Firerate.is_stopped():
			fire_cannons()

func initialize_firerate() -> void:
	Firerate.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	Firerate.set_wait_time(PlasmaGun.get_gun().FireRate)
	Firerate.set_one_shot(true)

func update_target(newTarget: Vector2) -> void:
	target = newTarget
	_AggroCast.set_aggro_target(target)

func smooth_to_target(delta: float) -> void:
	if uncalibrated: rotation_rate = ROTATION_RATE * ROTATION_DEBUFF
	else: rotation_rate = ROTATION_RATE
	
	Guns.rotation_degrees += rotation_rate * delta * signi(rad_to_deg(Guns.get_angle_to(target)))

func fire_cannons() -> void:
	var current_cannon_point: Marker2D = Guns.get_children()[cannon_index]
	PlasmaGun.fire(current_cannon_point.global_position, current_cannon_point.global_rotation)
	
	cannon_index = (cannon_index + 1) % Guns.get_child_count()
	
	Firerate.start()

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
	
	FlashHandler.trigger_flash()
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
		
		Destruction.start()
