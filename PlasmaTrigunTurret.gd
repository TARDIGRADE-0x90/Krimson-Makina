extends StaticBody2D
class_name PlasmaTrigunTurret

const BASE_HEALTH: float = 100.0

const AIM_TIME: float = 1.0
const AIM_DAMP: float = 0.5

const ROTATION_RATE: int = 100

const GUN_COOLDOWN: float = 0.25

const DEATH_DELAY: float = 5.0

@export var MachineTitle: String

@onready var Base: Sprite2D = $FullBody/Base
@onready var Guns: Sprite2D = $FullBody/Guns
@onready var Destruction: DeathDelay = $Destruction
@onready var GunCooldown: Timer = $GunCooldown
@onready var PlasmaGun: ProjectileManager = $PlasmaGun
@onready var ShootDetect: Shootable = $Shootable
@onready var MeleeDetect: Meleeable = $Meleeable
@onready var FlashHandler: HitFlashHandler = $FlashHandler

var target: Vector2
var health: float = BASE_HEALTH
var cannon_index: int = 0

func _ready() -> void:
	initialize_firing_cooldown()
	
	FlashHandler.assign_sprites([Base, Guns])
	MeleeDetect.melee_detected.connect(read_damage)
	ShootDetect.shot_detected.connect(read_damage)

func _physics_process(delta) -> void:
	if Global.player:
		update_target(Global.player_position)
	
	smooth_to_target(delta)
	
	if GunCooldown.is_stopped():
		fire_cannons()

func initialize_firing_cooldown() -> void:
	GunCooldown.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	GunCooldown.set_wait_time(GUN_COOLDOWN)
	GunCooldown.set_one_shot(true)

func update_target(newTarget: Vector2) -> void:
	target = newTarget

func smooth_to_target(delta: float) -> void:
	Guns.rotation_degrees += ROTATION_RATE * delta * signi(rad_to_deg(Guns.get_angle_to(target)))

func fire_cannons() -> void:
	var current_cannon_point: Marker2D = Guns.get_children()[cannon_index]
	PlasmaGun.fire(current_cannon_point.global_rotation, current_cannon_point.global_position)
	
	cannon_index = (cannon_index + 1) % Guns.get_child_count()
	
	GunCooldown.start()

func read_damage(amount: float) -> void:
	health -= amount
	
	if health <= 0:
		destroy()
		return
	
	FlashHandler.trigger_flash()
	Events.new_target_hit.emit(MachineTitle, health)

func destroy() -> void:
	Events.target_destroyed.emit()
	
	CollisionBits.set_mask_and_layer(self, CollisionBits.DEFAULT_BIT, false)
	CollisionBits.set_mask_and_layer(self, CollisionBits.PLAYER_PROJECTILE_BIT, false)
	CollisionBits.set_mask_and_layer(self, CollisionBits.PLAYER_SWORD_BIT, false)
	
	Destruction.start()
	
	set_physics_process(false)
	set_visible(false)
