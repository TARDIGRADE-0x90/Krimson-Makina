extends Node
class_name Meleeable

signal melee_detected(melee_damage: float)
signal melee_cleared

@export var Collider: CollisionObject2D

var struck: bool = false

const ERR_NON_COLLIDABLE_PARENT: String = "ERROR [Meleeable.gd] :: Parent not collidable"

func _ready() -> void:
	assert(is_instance_of(owner, CollisionObject2D), ERR_NON_COLLIDABLE_PARENT)
	CollisionBits.set_layer(owner, CollisionBits.PLAYER_SWORD_BIT, true)
	Collider.set_meta(Global.META_MELEEABLE_REF, self)
	
	melee_detected.connect(read_melee)
	melee_cleared.connect(reset_melee_detection)

func read_melee(amount: float) -> void:
	struck = true

func reset_melee_detection() -> void:
	struck = false
