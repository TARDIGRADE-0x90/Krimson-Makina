extends Node

const MUSIC_BOOST: float = 90
const MUSIC_DECREMENT: float = 95

var music_player: AudioStreamPlayer
var current_track: AudioStream
var stopping: bool = false

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	set_process_mode(PROCESS_MODE_ALWAYS)
	add_child(music_player)

func set_current_track(path: String) -> void:
	if stopping:
		await(end_current_track)
	
	var track = load(path)
	if current_track != track:
		end_current_track()
		current_track = track
		music_player.set_stream(track)
		music_player.set_volume_db((MUSIC_BOOST) - MUSIC_DECREMENT)
		music_player.play()
	
func end_current_track() -> void:
	stopping = true
	current_track = null
	music_player.stop()
	stopping = false
	return

func mute_track() -> void:
	music_player.stop()

func unmute_track() -> void:
	music_player.play()
