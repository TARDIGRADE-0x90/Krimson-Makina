extends StaticBody2D
class_name PlasmaTrigunTurret

const AIM_TIME: float = 1.0
const AIM_DAMP: float = 0.5

const AIM_INTERVAL: int = 20
const ROTATION_RATE: int = 100

const GUN_COOLDOWN: float = 0.25

@onready var Guns: Sprite2D = $FullBody/Guns
@onready var GunCooldown: Timer = $GunCooldown
@onready var PlasmaGun: ProjectileManager = $PlasmaGun

var target: Vector2
var cannon_index: int = 0
#var ticks: int = 1

var firing: bool = true

func _ready() -> void:
	initialize_firing_cooldown()

func initialize_firing_cooldown() -> void:
	GunCooldown.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	GunCooldown.set_wait_time(GUN_COOLDOWN)
	GunCooldown.set_one_shot(true)

func _physics_process(delta) -> void:
	#ticks += 1
	
	if Global.player:
	#	if ticks % AIM_INTERVAL == 0:
		update_target(Global.player_position)
	
	smooth_to_target(delta)
	
	if GunCooldown.is_stopped():
		fire_cannons()

func update_target(newTarget: Vector2) -> void:
	target = newTarget

func smooth_to_target(delta: float) -> void:
	Guns.rotation_degrees += ROTATION_RATE * delta * signi(rad_to_deg(Guns.get_angle_to(target)))

func fire_cannons() -> void:
	var current_cannon_point: Marker2D = Guns.get_children()[cannon_index]
	PlasmaGun.fire(current_cannon_point.global_rotation, current_cannon_point.global_position)
	
	cannon_index = (cannon_index + 1) % Guns.get_child_count()
	
	GunCooldown.start()
