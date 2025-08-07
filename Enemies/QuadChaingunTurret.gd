extends StaticBody2D
class_name QuadChaingunTurret

const BLAST_MARK_PATH: String = "res://BlastMark.tscn"
const BLAST_MARK: PackedScene = preload(BLAST_MARK_PATH)

const BASE_HEALTH: float = 100.0

const AIM_TIME: float = 1.0
const AIM_DAMP: float = 0.5

const ROTATION_RATE: int = 120
const ROTATION_DEBUFF: float = 0.25

const BURST_COUNT: int = 6
const BURST_DELAY: float = 1.2

@export var MachineTitle: String

@onready var _UncalibrationUI: UncalibrationUI = $UncalibrationUI
@onready var _AggroCast: AggroCast = $AggroCast
@onready var Base: Sprite2D = $FullBody/Base
@onready var Barrels: Sprite2D = $FullBody/Barrels
@onready var Muzzle: Marker2D = $FullBody/Barrels/Muzzle
@onready var Destruction: DeathDelay = $Destruction
@onready var Firerate: Timer = $Firerate
@onready var BurstDelay: Timer = $BurstDelay

@onready var QuadChaingun: ProjectileManager = $QuadChaingun
@onready var ShootDetect: Shootable = $Shootable
@onready var MeleeDetect: Meleeable = $Meleeable
@onready var FlashHandler: HitFlashHandler = $HitFlashHandler

var target: Vector2
var health: float = BASE_HEALTH
var rotation_rate: float = ROTATION_RATE
var aggroed: bool = false
var uncalibrated: bool = false
var destroyed: bool = false
var burst_step: int = 0

func _ready() -> void:
	Barrels.rotation_degrees = randi_range(0, 360)
	
	initialize_firerate()
	initialize_burst_delay()
	FlashHandler.assign_sprites([Base, Barrels])
	
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
		
		if Firerate.is_stopped() and BurstDelay.is_stopped():
			fire_cannon()

func initialize_firerate() -> void:
	Firerate.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	Firerate.set_wait_time(QuadChaingun.get_gun().FireRate)
	Firerate.set_one_shot(true)

func initialize_burst_delay() -> void:
	BurstDelay.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	BurstDelay.set_wait_time(BURST_DELAY)
	BurstDelay.set_one_shot(true)

func update_target(newTarget: Vector2) -> void:
	target = newTarget

func smooth_to_target(delta: float) -> void:
	if uncalibrated: rotation_rate = ROTATION_RATE * ROTATION_DEBUFF
	else: rotation_rate = ROTATION_RATE
	
	Barrels.rotation_degrees += rotation_rate * delta * signi(rad_to_deg(Barrels.get_angle_to(target)))

func fire_cannon() -> void:
	burst_step += 1
	QuadChaingun.fire(Muzzle.global_position, Muzzle.global_rotation)
	Firerate.start()
	
	if burst_step >= BURST_COUNT:
		burst_step = 0
		BurstDelay.start()

var crit_query: float = 0.000
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
