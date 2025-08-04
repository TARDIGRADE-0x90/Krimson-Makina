@tool

extends StaticBody2D
class_name Wall

@export var PolygonData: PackedVector2Array

@onready var Visual = $WallVisual
@onready var Outline = $WallOutline

func _ready() -> void:
	
	if PolygonData:
		Visual.polygon = PolygonData
	
	if not Engine.is_editor_hint():
		var coll := CollisionPolygon2D.new()
		coll.polygon = Visual.polygon
		#coll.build_mode = coll.BUILD_SEGMENTS
		add_child(coll)
		
		CollisionBits.set_layer(self, CollisionBits.PLAYER_PROJECTILE_BIT, true)
		CollisionBits.set_layer(self, CollisionBits.ENEMY_PROJECTILE_BIT, true)

func _process(delta) -> void:
	if Engine.is_editor_hint() and Visual.polygon:
		var points := PackedVector2Array(Visual.polygon)
		points.append(Visual.polygon[0])
		Outline.points = points
