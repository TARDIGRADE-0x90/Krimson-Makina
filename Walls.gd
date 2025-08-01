extends StaticBody2D
class_name Walls

func _ready():
	CollisionBits.set_layer(self, CollisionBits.PLAYER_PROJECTILE_BIT, true)
	CollisionBits.set_layer(self, CollisionBits.ENEMY_PROJECTILE_BIT, true)
