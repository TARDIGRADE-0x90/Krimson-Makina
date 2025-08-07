extends RayCast2D
class_name MoveBoundCast

"""
ray cast that performs shuttered checks in 8 cardinal directions to determine 
a min/max bound for movement

horrible dogshit that induces a notable ~8 frame drop upon bound creation - this
process has been shuttered to mitigate the chance of this occuring between multiple
casts on the same frame
"""

const MAX_STEPS: int = 8
const MARGIN: int = 64 #use this whenever a query is pushed with collision detected, as a buffer

const EMPTY_BOUND := Vector4(0, 0, 0, 0)

@export var Magnitude: float
@export var TickCap: int
@export var IntervalRange: Vector2i

var active: bool = false

var cast_ticks: int = 0
var tick_interval = Vector2i()

var center_point: Vector2
var move_bound: Vector4 = EMPTY_BOUND
var point_queries: Array[Vector2]
var current_step: int = 0
var query_index: int = 0

var x_max: float
var x_min: float
var y_max: float
var y_min: float

func _ready() -> void:
	set_rotation(0) #safeguard
	target_position.x = Magnitude
	target_position.y = 0
	tick_interval = randi_range(IntervalRange.x, IntervalRange.y)
	
	x_max = center_point.x
	y_max = center_point.y
	x_min = center_point.x
	y_min = center_point.y

func _process(delta) -> void:
	if active:
		update_cast_ticks()

func update_cast_ticks() -> void:
	cast_ticks = (cast_ticks + 1) % TickCap
	
	if cast_ticks % tick_interval == 0:
		scan()

#var temp_vec: Vector2
func scan() -> void:
	if move_bound != EMPTY_BOUND: #this assumes move_bound is fixed for each MoveBoundCast
		return 
	
	if current_step < MAX_STEPS:
		print(target_position)
		
		if is_colliding(): #scan 
			var point := get_collision_point() #readability var award
			point_queries.append(point - Vector2(point.x - (MARGIN * sign(point.x)), point.y - (MARGIN * sign(point.y)) ))
		else:
			point_queries.append(Vector2(global_position.x + target_position.x, global_position.y + target_position.y))
		
		#temp_vec.x = target_position.x
		#temp_vec.y = target_position.y
		
		#force rotate the relative-based target position
		target_position.x = (target_position.x * cos( rotation )) - (target_position.y * sin( rotation ))
		target_position.y = (target_position.x * sin( rotation )) + (target_position.y * cos( rotation ))
		
		rotation -= PI * 0.25
		current_step += 1
	else:
		establish_move_bound()

"""
unsurprisingly, putting this in a for loop causes a bit of lag;
later, figure out how to spread it over frames like with scan
"""
func establish_move_bound() -> void: #everything here is strictly under the assumption it rotates COUNTER CLOCKWISE
	if point_queries.size() < MAX_STEPS:
		return
	
	if query_index < MAX_STEPS:
		match(query_index):
			0:
				x_max = point_queries[query_index].x
			1:
				if point_queries[query_index].x < x_max: x_max = point_queries[query_index].x
				y_min = point_queries[query_index].y
			2:
				if point_queries[query_index].y > y_min: y_min = point_queries[query_index].y
			3:
				x_min = point_queries[query_index].x
				if point_queries[query_index].y > y_min: y_min = point_queries[query_index].y
			4:
				if point_queries[query_index].x > x_min: x_min = point_queries[query_index].x
			5:
				y_max = point_queries[query_index].y
				if point_queries[query_index].x > x_min: x_min = point_queries[query_index].x
			6:
				if point_queries[query_index].y < y_max: y_max = point_queries[query_index].y
			7:
				if point_queries[query_index].y < y_max: y_max = point_queries[query_index].y
				if point_queries[query_index].x < x_max: x_max = point_queries[query_index].x
		
		query_index += 1
	
	else:
		move_bound.x = x_min
		move_bound.y = x_max
		move_bound.z = y_min
		move_bound.w = y_max
		
		print("finished with bound %s " % move_bound)
		active = false

func activate() -> void:
	if !active:
		active = true
