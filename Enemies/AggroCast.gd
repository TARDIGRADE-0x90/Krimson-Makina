extends RayCast2D
class_name AggroCast

@export var CastMagnitude: float
@export var AggroWidth: int 
@export var AggroHeight: int 
@export var AggroTarget: Vector2
@export var AggroBody: Node
@export var TickCap: int
@export var IntervalRange: Vector2

var aggro_cast_ticks: int = 0

var aggro_bound = Vector4() ## Cannot be initialized before ready method - global_position does not get overrided by export values
var aggro_interval = Vector2()

var aggroed: bool = false

func _ready() -> void:
	global_position = owner.global_position #safeguard, in case you somehow move it in editor
	target_position.x = CastMagnitude
	target_position.y = 0
	aggro_interval = randi_range(IntervalRange.x, IntervalRange.y)
	
	update_aggro_bound()

func _physics_process(delta) -> void:
	if not aggroed: #when aggroed, disable 
		update_aggro_cast_ticks()

func update_aggro_cast_ticks() -> void:
	aggro_cast_ticks = (aggro_cast_ticks + 1) % TickCap
	
	if aggro_cast_ticks % aggro_interval == 0:
		update_aggro_cast()

func update_aggro_bound() -> void: #can be left in ready for static enemies; place in update for moving enemies
	aggro_bound = Vector4(
	(-AggroWidth * 0.5) + global_position.x, #x1 x2 y1 y2 format
	(AggroWidth * 0.5)  + global_position.x, 
	(-AggroHeight * 0.5) + global_position.y, 
	(AggroHeight * 0.5) + global_position.y)

func update_aggro_cast() -> void:
	look_at(Global.player_position)
	
	if get_collider(): #for this game enemies will only target player, so no other steps are needed for type checking
		if (is_instance_of(get_collider(), Player)):
			set_aggroed(true)

func set_aggro_target(new_target: Vector2) -> void:
	AggroTarget = new_target

func set_aggro_body(body: Node) -> void:
	AggroBody = body

func set_aggroed(value: bool) -> void:
	aggroed = value

func is_aggroed() -> bool:
	return aggroed
