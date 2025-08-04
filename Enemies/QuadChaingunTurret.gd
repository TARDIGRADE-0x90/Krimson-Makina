extends StaticBody2D
class_name QuadChaingunTurret

const BLAST_MARK_PATH: String = "res://BlastMark.tscn"
const BLAST_MARK: PackedScene = preload(BLAST_MARK_PATH)

const BASE_HEALTH: float = 100.0

const AIM_TIME: float = 1.0
const AIM_DAMP: float = 0.5

const ROTATION_RATE: int = 120

const SHOTS: int = 4
const OFFSET: float = 120.0
const FIRERATE: float = 0.05
const BURST_COUNT: int = 6
const BURST_DELAY: float = 1.2

const DEATH_DELAY: float = 5.0

@export var MachineTitle: String

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
var destroyed: bool = false
var burst_step: int = 0

func _ready() -> void:
	initialize_firerate()
	initialize_burst_delay()
	FlashHandler.assign_sprites([Base, Barrels])
	
	MeleeDetect.melee_detected.connect(read_damage)
	ShootDetect.shot_detected.connect(read_damage)

func _physics_process(delta) -> void:
	if Global.player:
		update_target(Global.player_position)
	
	smooth_to_target(delta)
	
	if Firerate.is_stopped() and BurstDelay.is_stopped():
		fire_cannon()

func initialize_firerate() -> void:
	Firerate.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	Firerate.set_wait_time(FIRERATE)
	Firerate.set_one_shot(true)

func initialize_burst_delay() -> void:
	BurstDelay.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	BurstDelay.set_wait_time(BURST_DELAY)
	BurstDelay.set_one_shot(true)

func update_target(newTarget: Vector2) -> void:
	target = newTarget

func smooth_to_target(delta: float) -> void:
	Barrels.rotation_degrees += ROTATION_RATE * delta * signi(rad_to_deg(Barrels.get_angle_to(target)))

func fire_cannon() -> void:
	burst_step += 1
	QuadChaingun.multifire_parallel(Muzzle.global_position, Muzzle.global_rotation, SHOTS, OFFSET)
	Firerate.start()
	
	if burst_step >= BURST_COUNT:
		burst_step = 0
		BurstDelay.start()

func read_damage(amount: float) -> void:
	health -= amount
	
	if health <= 0:
		destroy()
		return
	
	FlashHandler.trigger_flash()
	Events.new_target_hit.emit(MachineTitle, health, BASE_HEALTH)

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
