extends Node
class_name ProjectileManager

"""
note that 
(wtf was I going to put here?)

do later - create destructible projectiles like large missiles, debris, shrapnel, etc.
"""

enum MULTIFIRE_TYPE {NONE, RADIAL, PARALLEL} #make export var later

const ERR_SHOTS_LOW: String = "ERROR :: ProjectileManager.gd - multifire modes require >1 shots"
const ERR_SPREAD_NIL: String = "ERROR :: ProjectileManager.gd - spread data must be greater than 0"
const ERR_OFFSET_NIL: String = "ERROR :: ProjectileManager.gd - offset data must be greater than 0"

const PROJECTILE_PATH: String = "res://Projectile/Projectile.tscn"
const PROJECTILE: PackedScene = preload(PROJECTILE_PATH)

const SPREAD_MIN: float = 0.05
const SPREAD_MAX: float = 1.5

const OFFSET_MIN: float = 30.0
const OFFSET_MAX: float = 500.0

@export var ShotData: ProjectileData
@export var GunInfo: GunData

var shot_data_copy: ProjectileData = ProjectileData.new()
var gun_data_copy: GunData = GunData.new()
var current_shot: Projectile #bad practice? maybe
var shot_pool: Array[Projectile]
var pool_index: int = 0

var override_type: int = 0

func _ready() -> void:
	shot_data_copy.copy_data(ShotData)
	gun_data_copy.copy_data(GunInfo)
	
	initialize_projectiles()

func initialize_projectiles() -> void:
	for i in range(gun_data_copy.PoolSize):
		var projectile = PROJECTILE.instantiate()
		projectile.ShotData = shot_data_copy
		
		if override_type > 0:
			projectile.ShotData.CollisionType = override_type
		
		Global.current_level.call_deferred("add_child", projectile)
		
		shot_pool.append(projectile)

func flag_collision_override(type: int) -> void:
	shot_data_copy.CollisionType = type

func fire(start: Vector2, angle: float) -> void:
	match gun_data_copy.FiringPattern:
		GunData.FiringPatterns.NIL:
			print("ProjectileManger.gd :: NIL firing pattern for some reason")
		
		GunData.FiringPatterns.SINGLE:
			fire_single(start, angle)
		
		GunData.FiringPatterns.RADIAL:
			assert(gun_data_copy.Shots > 1, ERR_SHOTS_LOW)
			assert(gun_data_copy.Spread >= 0, ERR_SPREAD_NIL)
			multifire_radial(start, angle, gun_data_copy.Shots, gun_data_copy.Spread)
		
		GunData.FiringPatterns.PARALLEL:
			assert(gun_data_copy.Shots > 1, ERR_SHOTS_LOW)
			assert(gun_data_copy.Offset >= 0, ERR_OFFSET_NIL)
			multifire_parallel(start, angle, gun_data_copy.Shots, gun_data_copy.Offset)

func fire_single(start: Vector2, angle: float) -> void:
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

func get_gun() -> GunData:
	return gun_data_copy
