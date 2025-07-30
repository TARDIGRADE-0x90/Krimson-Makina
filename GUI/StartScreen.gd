extends Control

@onready var StartButton: Button = $MenuButtonMargin/MenuButtons/StartButton
@onready var OptionsButton: Button  = $MenuButtonMargin/MenuButtons/OptionsButton
@onready var ExitButton: Button  = $MenuButtonMargin/MenuButtons/ExitButton

# Called when the node enters the scene tree for the first time.
func _ready():
	StartButton.pressed.connect(start_game)
	OptionsButton.pressed.connect(display_options)
	ExitButton.pressed.connect(exit_game)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_game() -> void:
	Events.game_state_changed.emit(Global.GAME_STATES.GAME_LOOP)

func display_options() -> void:
	print("options")

func exit_game() -> void:
	get_tree().quit() # probably add some other safeguards as well
