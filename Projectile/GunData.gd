extends Resource
class_name GunData

"""
needs Spread and Offset
"""

enum FiringPatterns {NIL = -1, SINGLE = 0, RADIAL = 1, PARALLEL = 2}

@export var FiringPattern: FiringPatterns
@export var Shots: int
@export var FireRate: float
@export var PoolSize: int
@export var HeatRange: Vector2
@export var Spread: float = -1.0
@export var Offset: float = -1.0
@export var ShotData: ProjectileData
@export var PlayerGunVisual: Texture

func copy_data(data: GunData) -> void:
	FiringPattern = data.FiringPattern
	Shots = data.Shots
	FireRate = data.FireRate
	PoolSize = data.PoolSize
	HeatRange = data.HeatRange
	Spread = data.Spread
	Offset = data.Offset
	ShotData = data.ShotData
	PlayerGunVisual = data.PlayerGunVisual
