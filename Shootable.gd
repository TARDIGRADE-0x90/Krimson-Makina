extends Node
class_name Shootable

signal shot_detected(shot_damage: float)

@export var CollisionType: ProjectileData.CollisionTypes
@export var Collider: CollisionObject2D

func _ready() -> void:
	CollisionBits.set_layer(Collider, CollisionType, true)
	Collider.set_meta(Global.META_SHOOTABLE_REF, self)
	shot_detected.connect(read_shot)

func read_shot(amount: float) -> void:
	pass
