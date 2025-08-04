extends Node
class_name ProjectileManager

"""
note that 
(wtf was I going to put here?)

do later - create destructible projectiles like large missiles, debris, shrapnel, etc.
"""

enum MULTIFIRE_TYPE {NONE, RADIAL, PARALLEL} #make export var later

const PROJECTILE_PATH: String = "res://Projectile/Projectile.tscn"
const PROJECTILE: PackedScene = preload(PROJECTILE_PATH)

const SPREAD_MIN: float = 0.05
const SPREAD_MAX: float = 1.5

const OFFSET_MIN: float = 30.0
const OFFSET_MAX: float = 500.0

@export var ShotData: ProjectileData
@export var MaxPool: int

var current_shot: Projectile #bad practice? maybe
var shot_pool: Array[Projectile]
var pool_index: int = 0

func _ready() -> void:
	initialize_projectiles()

func initialize_projectiles() -> void:
	for i in range(MaxPool):
		var projectile = PROJECTILE.instantiate()
		projectile.ShotData = ShotData
		
		Global.current_level.call_deferred("add_child", projectile)
		
		shot_pool.append(projectile)

func fire(start: Vector2, angle: float) -> void:
	current_shot = shot_pool[pool_index]
	
	if not current_shot.active:
		current_shot.global_position = start
		current_shot.set_rotation(angle)
		current_shot.trigger(Vector2.from_angle(angle) * ShotData.Speed)
		pool_index = (pool_index + 1) % shot_pool.size()

func multifire_radial(start: Vector2, angle: float, shots: int, spread: float) -> void:
	var deviation: float = 0.0
	var organized_shots: Array[int] = Global.mirrored_half(shots)
	var even_offset: float = 0.5 if (shots % 2 == 0) else 0.0
	
	spread = clamp(spread, SPREAD_MIN, SPREAD_MAX)
	
	for i in organized_shots:
		if (pool_index + i) >= shot_pool.size():
			pool_index = 0 # NOTE - ERROR POTENTIAL HERE, ENSURE THAT SHOTS IS WITHIN THE POOL SIZE
		
		current_shot = shot_pool[pool_index]
		deviation = ( ( float(organized_shots[i] + even_offset) * PI  / float(shots)) ) * spread
		
		if not current_shot.active:
			current_shot.global_position = start
			current_shot.set_rotation(angle + deviation)
			current_shot.trigger( Vector2.from_angle(angle + deviation) * ShotData.Speed)
			pool_index = (pool_index + 1) % shot_pool.size()

func multifire_parallel(start: Vector2, angle: float, shots: int, bullet_offset: float) -> void:
	var organized_shots: Array[int] = Global.mirrored_half(shots)
	var even_offset: float = 0.5 if (shots % 2 == 0) else 0.0
	
	bullet_offset = clamp(OFFSET_MIN, bullet_offset, OFFSET_MAX)
	
	for i in organized_shots:
		if (pool_index + i) >= shot_pool.size():
			pool_index = 0 # NOTE - ERROR POTENTIAL HERE, ENSURE THAT SHOTS IS WITHIN THE POOL SIZE
		
		current_shot = shot_pool[pool_index]
		
		if not current_shot.active:
			current_shot.global_position = start + (Vector2.from_angle((angle - PI * 0.5 * 1)) * bullet_offset * (i + even_offset))
			current_shot.set_rotation(angle)
			current_shot.trigger(Vector2.from_angle(angle) * ShotData.Speed)
			pool_index = (pool_index + 1) % shot_pool.size()
