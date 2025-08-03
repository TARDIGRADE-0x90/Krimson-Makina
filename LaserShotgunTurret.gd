extends StaticBody2D
class_name LaserShotgunTurret

const AIM_TIME: float = 1.0
const AIM_DAMP: float = 0.5

const ROTATION_RATE: int = 65

const SHOTS: int = 7
const SPREAD: float = 0.8
const GUN_COOLDOWN: float = 1.4

@onready var Base: Sprite2D = $FullBody/Base
@onready var Cannon: Sprite2D = $FullBody/Cannon
@onready var Muzzle: Marker2D = $FullBody/Cannon/Muzzle
@onready var GunCooldown: Timer = $GunCooldown
@onready var LaserShotgun: ProjectileManager = $LaserShotgun
@onready var ShootDetect: Shootable = $Shootable
@onready var MeleeDetect: Meleeable = $Meleeable
@onready var FlashHandler: HitFlashHandler = $HitFlashHandler

var target: Vector2

func _ready() -> void:
	initialize_gun_cooldown()
	FlashHandler.assign_sprites([Base, Cannon])
	
	MeleeDetect.melee_detected.connect(read_damage)
	ShootDetect.owner_shot.connect(read_damage)

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
	LaserShotgun.multifire_radial(SHOTS, SPREAD, Muzzle.global_rotation, Muzzle.global_position)
	GunCooldown.start()

func read_damage() -> void:
	FlashHandler.trigger_flash()
	#set_physics_process(false)
	#set_visible(false)
