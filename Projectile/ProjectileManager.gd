extends Node2D
class_name ProjectileManager

"""
note that 
"""
enum MULTIFIRE_TYPE {NONE, RADIAL}

const PROJECTILE_PATH: String = "res://Projectile/Projectile.tscn"
const PROJECTILE: PackedScene = preload(PROJECTILE_PATH)

const SPREAD_MIN: float = 0.05
const SPREAD_MAX: float = 1.5

@export var ShotData: ProjectileData
@export var MaxPool: int

var level_ref: Node
var current_shot: Projectile #bad practice? maybe
var shot_pool: Array[Projectile]
var shot_index: int = 0

func _ready() -> void:
	level_ref = owner.owner #this is ass lol
	initialize_projectiles()

func initialize_projectiles() -> void:
	for i in range(MaxPool):
		var projectile = PROJECTILE.instantiate()
		projectile.ShotData = ShotData
		
		level_ref.call_deferred("add_child", projectile)
		
		shot_pool.append(projectile)

func fire(angle: float = 0, start: Vector2 = global_position) -> void:
	current_shot = shot_pool[shot_index]
	
	if not current_shot.active:
		current_shot.global_position = start
		current_shot.set_rotation(angle)
		current_shot.trigger(Vector2.from_angle(angle) * ShotData.Speed)
		shot_index = (shot_index + 1) % shot_pool.size()

func multifire_radial(shots: int, spread: float, angle: float = 0, start: Vector2 = global_position) -> void:
	var deviation: float = 0.0
	var organized_shots: Array[int] = Global.mirrored_half(shots)
	spread = clamp(spread, SPREAD_MIN, SPREAD_MAX)
	
	for i in (organized_shots):
		if (shot_index + i) >= shot_pool.size():
			shot_index = 0 # NOTE - ERROR POTENTIAL HERE, ENSURE THAT SHOTS IS WITHIN THE POOL SIZE
		
		current_shot = shot_pool[shot_index]
		deviation = ( ( float(organized_shots[i]) * PI  / float(shots)) ) * spread
		
		if not current_shot.active:
			current_shot.global_position = start
			current_shot.set_rotation(angle + deviation)
			current_shot.trigger( Vector2.from_angle(angle + deviation) * ShotData.Speed)
			shot_index = (shot_index + 1) % shot_pool.size()
