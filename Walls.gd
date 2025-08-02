@tool

extends StaticBody2D
class_name Walls

@onready var WallVisual = $WallVisual
@onready var Outline = $Outline

func _ready() -> void:
	CollisionBits.set_layer(self, CollisionBits.PLAYER_PROJECTILE_BIT, true)
	CollisionBits.set_layer(self, CollisionBits.ENEMY_PROJECTILE_BIT, true)
	
	if not Engine.is_editor_hint():
		var coll := CollisionPolygon2D.new()
		coll.polygon = WallVisual.polygon
		add_child(coll)

func _process(delta) -> void:
	
	if Engine.is_editor_hint():
		var points := PackedVector2Array(WallVisual.polygon)
		points.append(WallVisual.polygon[0])
		Outline.points = points
