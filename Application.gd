extends Node
class_name Application

var current_scene: Variant
var next_scene: Variant
var game_state: int = -1

func _init() -> void:
	Global.export_type = Global.EXPORT_TYPES.WEB

func _ready() -> void:
	Events.game_state_changed.connect(change_game_state)
	Events.game_state_changed.emit(Global.GAME_STATES.START_SCREEN)

func change_game_state(state: int) -> void:
	get_tree().paused = true
	
	game_state = state
	match game_state:
		Global.GAME_STATES.GAME_LOOP:
			match Global.level_index:
				Global.LEVEL_KEYS.JADE_I:
					Music.set_current_track(FilePaths.MUSIC_JADE)
					load_scene(FilePaths.LEVEL_JADE_I)
				Global.LEVEL_KEYS.JADE_II:
					Music.set_current_track(FilePaths.MUSIC_JADE)
					load_scene(FilePaths.LEVEL_JADE_II)
				Global.LEVEL_KEYS.JADE_III:
					Music.set_current_track(FilePaths.MUSIC_JADE)
					load_scene(FilePaths.LEVEL_JADE_III)
				Global.LEVEL_KEYS.GOLD_I:
					Music.set_current_track(FilePaths.MUSIC_GOLD)
					load_scene(FilePaths.LEVEL_GOLD_I)
				Global.LEVEL_KEYS.GOLD_II:
					Music.set_current_track(FilePaths.MUSIC_GOLD)
					load_scene(FilePaths.LEVEL_GOLD_II)
				Global.LEVEL_KEYS.GOLD_III:
					Music.set_current_track(FilePaths.MUSIC_GOLD)
					load_scene(FilePaths.LEVEL_GOLD_III)
				Global.LEVEL_KEYS.RUBY_I:
					Music.set_current_track(FilePaths.MUSIC_RUBY)
					load_scene(FilePaths.LEVEL_RUBY_I)
		
		Global.GAME_STATES.START_SCREEN: 
			load_scene(FilePaths.START_SCREEN)
			Music.set_current_track(FilePaths.MUSIC_IDLE)
		_:
			print("Invalid gameplay state (SceneManager.gd, change_game_state())")
	
	get_tree().paused = false

func load_scene(path: String, hide_tree: bool = false) -> void:
	
	if hide_tree:
		hide_current_tree(self)
	else:
		flush_current_tree(self)
	
	next_scene = load(path).instantiate()
	call_deferred("add_child", next_scene)
	
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	
	current_scene = next_scene

func flush_current_tree(root: Variant, preserve_player: bool = false) -> void:
	for game_scene in root.get_children():
		game_scene.queue_free()

func hide_current_tree(root: Variant) -> void:
	pass
