extends Node
class_name Shootable

signal owner_shot

const ERR_NON_COLLIDABLE_PARENT: String = "ERROR [Shootable.gd] :: Parent not collidable"
 
func _ready() -> void:
	assert(is_instance_of(owner, CollisionObject2D), ERR_NON_COLLIDABLE_PARENT)
	CollisionBits.set_layer(owner, CollisionBits.PLAYER_PROJECTILE_BIT, true)
	owner_shot.connect(read_shot)

func read_shot() -> void:
	print("%s was shot " % owner)
