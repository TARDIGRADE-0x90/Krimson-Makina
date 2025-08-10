extends Node
class_name FontExportOverride

const ERR_OWNER_NOT_CONTROL: String = "ERROR :: FontExportOverride - owner is not a control node derivative"

@export var FontOverride: Font

var parent: Control #done to assert its type
var _Font: Font

func _ready() -> void:
	assert(is_instance_of(get_parent(), Control), ERR_OWNER_NOT_CONTROL)
	parent = get_parent()
	
	match Global.export_type:
		Global.EXPORT_TYPES.LINUX:
			parent.remove_theme_font_override("font")
		
		Global.EXPORT_TYPES.WEB:
			parent.remove_theme_font_override("font")
