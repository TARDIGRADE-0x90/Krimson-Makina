extends Node

const ERR_TIMEOUT_METHOD_INVALID: String = "Error in Global.gd: timeout_method invalid"

enum GAME_STATES {START_SCREEN, GAME_LOOP}

const META_SHOOTABLE_REF: String = "shot_detection_reference"

const MELEE_DETECTOR: String = "Meleeable"
const SHOOT_DETECTOR: String = "Shootable"

var active_camera: MainCamera
var player: Player
var player_position = Vector2(0, 0) #allows for initialization even as the player is not loaded in yet

func _ready() -> void:
	pass

#Makes node a child of another given node (preferrably the root scene)
func add_child_to_owner(child: Variant, node: Variant) -> void: 
	node.add_child(child)
	child.set_owner(node)

func add_child_to_node_deferred(child: Variant, node: Variant) -> void:
	node.call_deferred("add_child", child)
	child.set_owner(node)

func interpolate_value(start: float, end: float, time: float, damp: float = 1.0) -> float:
	start = start + (end - start) * time * damp #interpolation = A + (B - A) * t
	return start

func interpolate_vector(start_vector: Vector2, end_vector: Vector2, time: float, damp: float = 1.0) -> Vector2:
	start_vector.x = interpolate_value(start_vector.x, end_vector.x, time, damp)
	start_vector.y = interpolate_value(start_vector.y, end_vector.y, time, damp)
	
	return start_vector

func mirrored_half(size: int) -> Array[int]: #O(n) 
	var max: int = floor(size * 0.5)
	var output: Array[int]
	var count = -max
	
	for i in range(size):
		output.append(count)
		count += 1
	
	return output
