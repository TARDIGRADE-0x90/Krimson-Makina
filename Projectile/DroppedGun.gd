extends Node2D
class_name DroppedGun

"""
future hypothetical priority;
replace the gun data & visual with whatever the player had equipped
"""

const BOUND_SIZE: int = 256
const HOVER_TEXT_SUFFIX: String = " :: Pick up"

@export var Visual: Sprite2D
@export var HoverLabel: Label

var _GunData := GunData.new()
var bound_size: Vector4
var gun_name: String
var hovering: bool = false
var picked_up: bool = false

func drop(location: Vector2, gun_data: GunData) -> void:
	init_bound(location)
	init_data(gun_data)

func init_bound(location: Vector2) -> void:
	bound_size = Vector4(
		location.x - BOUND_SIZE * 0.5, 
		location.x + BOUND_SIZE * 0.5, 
		location.y - BOUND_SIZE * 0.5, 
		location.y + BOUND_SIZE * 0.5, 
	)

func init_data(input_data: GunData) -> void:
	_GunData.copy_data(input_data)
	gun_name = input_data.Name
	Visual.set_texture(input_data.PlayerGunVisual)
	
	HoverLabel.set_text(gun_name)

func _process(delta: float) -> void:
	detect_player()

func detect_player() -> void:
	if Global.is_vector_in_bound(Global.player_position, bound_size):
		if !hovering:
			Events.gun_query_hovered.emit(_GunData)
			hovering = true
		
		HoverLabel.set_visible(true)
	
	else:
		if hovering:
			Events.gun_query_exited
			hovering = false
		
		HoverLabel.set_visible(false)
