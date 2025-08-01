extends Node

const DEFAULT_BIT: int = 1
const PLAYER_PROJECTILE_BIT: int = 2
const ENEMY_PROJECTILE_BIT: int = 3

func set_mask_and_layer(area: CollisionObject2D, bit: int, value: bool) -> void:
	area.set_collision_mask_value(bit, value)
	area.set_collision_layer_value(bit, value)

func set_mask(area: CollisionObject2D, bit: int, value: bool) -> void:
	area.set_collision_mask_value(bit, value)

func set_layer(area: CollisionObject2D, bit: int, value: bool) -> void:
	area.set_collision_layer_value(bit, value)
