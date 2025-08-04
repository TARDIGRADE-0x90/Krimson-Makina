extends StaticBody2D
class_name LaserShotgunTurret

const BLAST_MARK_PATH: String = "res://BlastMark.tscn"
const BLAST_MARK: PackedScene = preload(BLAST_MARK_PATH)

const BASE_HEALTH: float = 100.0

const AIM_TIME: float = 1.0
const AIM_DAMP: float = 0.5

const ROTATION_RATE: int = 65

const SHOTS: int = 5
const SPREAD: float = 0.4
const GUN_COOLDOWN: float = 1.4

const DEATH_DELAY: float = 5.0

@export var MachineTitle: String

@onready var Base: Sprite2D = $FullBody/Base
@onready var Cannon: Sprite2D = $FullBody/Cannon
@onready var Muzzle: Marker2D = $FullBody/Cannon/Muzzle
@onready var Destruction: DeathDelay = $Destruction
@onready var GunCooldown: Timer = $GunCooldown
@onready var LaserShotgun: ProjectileManager = $LaserShotgun
@onready var ShootDetect: Shootable = $Shootable
@onready var MeleeDetect: Meleeable = $Meleeable
@onready var FlashHandler: HitFlashHandler = $HitFlashHandler

var target: Vector2
var health: float = BASE_HEALTH
var destroyed: bool = false

func _ready() -> void:
	initialize_gun_cooldown()
	FlashHandler.assign_sprites([Base, Cannon])
	
	MeleeDetect.melee_detected.connect(read_damage)
	ShootDetect.shot_detected.connect(read_damage)

func _physics_process(delta) -> void:
	if Global.player:
		update_target(Global.player_position)
	
	smooth_to_target(delta)
	
	if GunCooldown.is_stopped():
		fire_cannon()

func initialize_gun_cooldown() -> void:
	GunCooldown.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	GunCooldown.set_wait_time(GUN_COOLDOWN)
	GunCooldown.set_one_shot(true)

func update_target(newTarget: Vector2) -> void:
	target = newTarget

func smooth_to_target(delta: float) -> void:
	Cannon.rotation_degrees += ROTATION_RATE * delta * signi(rad_to_deg(Cannon.get_angle_to(target)))

func fire_cannon() -> void:
	LaserShotgun.multifire_radial(Muzzle.global_position, Muzzle.global_rotation, SHOTS, SPREAD)
	GunCooldown.start()

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
