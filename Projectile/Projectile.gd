extends Area2D
class_name Projectile

const NO_TARGET = Vector2(0, 0)

@export var ShotData: ProjectileData
@export var Sprite: Sprite2D
@export var Collider: CollisionShape2D
@export var ShotLifetime: Timer
@export var Velocity: Vector2

var damage: float = 0.0
var active: bool = false

func _ready() -> void:
	if ShotData:
		set_data()
	
	CollisionBits.set_mask(self, CollisionBits.DEFAULT_BIT, false) #additional collision assigned in Setdata
	
	body_entered.connect(collide)
	area_entered.connect(collide)
	
	set_presence(false)

func _physics_process(delta) -> void:
	if active:
		translate(Velocity)

func set_data(data: ProjectileData = ShotData) -> void:
	initialize_sprite(data)
	initialize_collider(data)
	initialize_lifetime(data)
	CollisionBits.set_mask(self, ShotData.CollisionType, true)
	damage = ShotData.BaseDamage

func initialize_sprite(data: ProjectileData = ShotData) -> void:
	Sprite.set_texture(data.ShotVisual)

func initialize_collider(data: ProjectileData = ShotData) -> void:
	Collider.set_shape(data.CollisionData)

func initialize_lifetime(data: ProjectileData = ShotData) -> void:
	ShotLifetime.set_wait_time(data.Lifetime)
	ShotLifetime.set_one_shot(true)
	ShotLifetime.timeout.connect(expire)

func trigger(target: Vector2, damage_modifier: float = 1.0) -> void:
	active = true
	damage *= damage_modifier
	set_presence(true)
	ShotLifetime.start()
	Velocity = target

func set_presence(value: bool) -> void:
	set_process(value)
	set_physics_process(value)
	set_visible(value)

func collide(obj: CollisionObject2D) -> void:
	if active:
		
		if obj.has_meta(Global.META_SHOOTABLE_REF) and damage > 0:
			obj.get_meta(Global.META_SHOOTABLE_REF).shot_detected.emit(damage)
		
		explode()

func explode() -> void:
	"""
	do visual VFX
	"""
	expire()

func expire() -> void:
	active = false
	Velocity = NO_TARGET
	set_presence(false)
