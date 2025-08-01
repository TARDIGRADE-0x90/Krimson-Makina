extends Resource
class_name ProjectileData

enum CollisionTypes {PLAYER = CollisionBits.PLAYER_PROJECTILE_BIT, ENEMY = CollisionBits.ENEMY_PROJECTILE_BIT}

@export var ShotVisual: Texture
@export var CollisionData: RectangleShape2D
@export var CollisionType: CollisionTypes
@export var Lifetime: float
@export var Speed: float
