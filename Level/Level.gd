extends Node
class_name Level

enum LevelKeys {
	NIL = -1, 
	JADE_1 = Global.LEVEL_KEYS.JADE_I,
	JADE_2 = Global.LEVEL_KEYS.JADE_II,
	JADE_3 = Global.LEVEL_KEYS.JADE_III,
	GOLD_1 = Global.LEVEL_KEYS.GOLD_I,
	GOLD_2 = Global.LEVEL_KEYS.GOLD_II,
	GOLD_3 = Global.LEVEL_KEYS.GOLD_III,
	RUBY_1 = Global.LEVEL_KEYS.RUBY_I,
	#RUBY_2 = Global.LEVEL_KEYS.RUBY_II,
	#RUBY_3 = Global.LEVEL_KEYS.RUBY_III
}

const PLAYER: PackedScene = preload(FilePaths.PLAYER)
const PLAYER_UI: PackedScene = preload(FilePaths.PLAYER_UI)
const PLAYER_CAMERA: PackedScene = preload(FilePaths.PLAYER_CAMERA)

@export var LevelDelay: LevelClearWait
@export var LevelKey: LevelKeys
@export var PlayerSpawn: Marker2D
@export var Enemies: Node

var player: Player
#var player_scene := PackedScene.new()

var player_loaded: bool = false
var player_destroyed: bool = false

var enemy_count: int

func _init() -> void:
	Global.current_level = self

func _ready() -> void:
	""" ## attempt at persistent player - explore it in another project
	if PlayerSpawn && Global.player_ref:
		print("persistently instantiated player")
		player = (Global.player_ref).instantiate()
		add_child(player)
		player.global_position = PlayerSpawn.global_position
	else:
		print("instantiated player")
	"""
	player = PLAYER.instantiate()
	add_child(player)
	player.global_position = PlayerSpawn.global_position
	
	player_loaded = true
	enemy_count = Enemies.get_child_count()
	
	var player_ui: PlayerUI = PLAYER_UI.instantiate()
	player_ui.set_current_player_ref(player)
	add_child(player_ui)
	
	var player_camera: MainCamera = PLAYER_CAMERA.instantiate()
	add_child(player_camera)
	
	LevelDelay.timeout.connect(change_level)
	
	Events.target_destroyed.connect(update_enemy_count)
	Events.player_died.connect(func(): player_destroyed = true)
	Events.player_death_finalized.connect(restart_level)

func update_enemy_count() -> void:
	enemy_count -= 1
	
	if enemy_count <= 0:
		Events.all_clear.emit()
		LevelDelay.start()

func change_level() -> void:
	if !player_destroyed:
		Global.level_index = (Global.level_index + 1) % Global.LEVEL_KEYS.size()
		Events.game_state_changed.emit(Global.GAME_STATES.GAME_LOOP)

func restart_level() -> void:
	Events.game_state_changed.emit(Global.GAME_STATES.GAME_LOOP)
