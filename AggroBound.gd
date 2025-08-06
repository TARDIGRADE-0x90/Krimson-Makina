extends Node2D
class_name AggroBound

@export var AggroWidth: int 
@export var AggroHeight: int 

var bound := Vector4() ## Cannot be initialized before ready method - global_position does not get overrided by export values
var aggro_target: Vector2
var aggroed: bool = false

func update_bound() -> void: #can be left in ready for static enemies; place in update for moving enemies
	bound = Vector4(
	(-AggroWidth * 0.5) + global_position.x, #x1 x2 y1 y2 format
	(AggroWidth * 0.5)  + global_position.x, 
	(-AggroHeight * 0.5) + global_position.y, 
	(AggroHeight * 0.5) + global_position.y)

func set_aggro_target(new_target: Vector2) -> void:
	aggro_target = new_target

func is_aggroed() -> bool:
	return Global.is_vector_in_bound(aggro_target, bound)

func stop() -> void: #probably not necessary but putting it in here regardless
	set_process(false)
	set_physics_process(false)
