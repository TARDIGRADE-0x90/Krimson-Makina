extends Resource
class_name ProjectileData

enum CollisionTypes {NIL = 0, PLAYER = CollisionBits.PLAYER_PROJECTILE_BIT, ENEMY = CollisionBits.ENEMY_PROJECTILE_BIT}

@export var ShotVisual: Texture
@export var CollisionData: RectangleShape2D
@export var CollisionType: CollisionTypes
@export var Lifetime: float
@export var Speed: float
@export var BaseDamage: float

func copy_data(data: ProjectileData) -> void:
	ShotVisual = data.ShotVisual
	CollisionData = data.CollisionData
	CollisionType = data.CollisionType
	Lifetime = data.Lifetime
	Speed = data.Speed
	BaseDamage = data.BaseDamage
