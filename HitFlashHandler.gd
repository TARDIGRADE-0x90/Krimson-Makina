extends Node
class_name HitFlashHandler

const ERR_INVALID_TYPE: String = "ERROR :: HitFlashHandler.gd - attempting to append non-texturable node"
const ERR_SHADER_NIL: String = "ERROR :: HitFlashHandler.gd - attempting to access unset material"
const FLASH_PARAMETER: String = "flash_modifier"

@export var Duration: float
@export var FlashTimer: Timer

var sprites: Array[Sprite2D]
var shaders_present: bool = false
var flash_tweak: float = 1.0

func _ready() -> void:
	initialize_flash_timer()

func _process(delta) -> void:
	if not FlashTimer.is_stopped():
		flash_sprites()

func assign_sprites(args: Array[Sprite2D]) -> void:
	for i in range(args.size()):
		assert(is_instance_of(args[i], Sprite2D), ERR_INVALID_TYPE)
		sprites.append(args[i])
		
		if !has_shader_material(args[i]):
			shaders_present = has_shader_material(args[i])
			continue #don't continue next line if even one sprite lacks material
		else:
			shaders_present = has_shader_material(args[i])
	

func initialize_flash_timer() -> void:
	FlashTimer.set_wait_time(Duration)
	FlashTimer.set_one_shot(true)
	FlashTimer.timeout.connect(clear_flash)

func trigger_flash() -> void:
	flash_tweak = 1.0
	FlashTimer.start()

func flash_sprites() -> void:
	update_flash_tweak()
	flash_tweak = sin(FlashTimer.time_left * PI * -0.25) * 5

func clear_flash() -> void:
	flash_tweak = 0
	update_flash_tweak()

func update_flash_tweak() -> void:
	if sprites: #confirm sprites exist
		for i in range(sprites.size()):
			if shaders_present:
				sprites[i].material.set_shader_parameter(FLASH_PARAMETER, flash_tweak)

func has_shader_material(sprite: Sprite2D) -> bool:
	if sprite.material: #confirm a material has been set
		if is_instance_of(sprite.material, ShaderMaterial):
			shaders_present = true
			return true
	
	print(ERR_SHADER_NIL)
	return false
