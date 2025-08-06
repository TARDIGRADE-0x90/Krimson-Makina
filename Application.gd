extends Node
class_name Application

var current_scene: Variant
var next_scene: Variant
var game_state: int = -1

func _ready():
	Events.game_state_changed.connect(change_game_state)
	Events.game_state_changed.emit(Global.GAME_STATES.START_SCREEN)

func change_game_state(state: int) -> void:
	get_tree().paused = true
	
	game_state = state
	match game_state:
		Global.GAME_STATES.GAME_LOOP: 
			load_scene(FilePaths.RED_LEVEL)
		Global.GAME_STATES.START_SCREEN: 
			load_scene(FilePaths.START_SCREEN)
		_:
			print("Invalid gameplay state (SceneManager.gd, change_game_state())")
	
	get_tree().paused = false

func load_scene(path: String) -> void:
	flush_current_tree(self)
	
	next_scene = load(path).instantiate()
	call_deferred("add_child", next_scene)
	
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	
	current_scene = next_scene


func flush_current_tree(root: Variant) -> void:
	for game_scene in root.get_children():
		game_scene.queue_free()
