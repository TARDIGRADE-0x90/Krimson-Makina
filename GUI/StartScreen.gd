extends Control

@onready var StartButton: Button = $MenuButtonMargin/MenuButtons/StartButton
@onready var GuideButton: Button  = $MenuButtonMargin/MenuButtons/GuideButton
@onready var ExitButton: Button  = $MenuButtonMargin/MenuButtons/ExitButton
@onready var DemoUI: Control = $DemoUI
@onready var ReturnButton: Button = $DemoUI/ReturnButton

# Called when the node enters the scene tree for the first time.
func _ready():
	DemoUI.set_visible(false)
	StartButton.pressed.connect(start_game)
	GuideButton.pressed.connect(display_guide)
	ReturnButton.pressed.connect(hide_guide)
	ExitButton.pressed.connect(exit_game)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_game() -> void:
	Events.game_state_changed.emit(Global.GAME_STATES.GAME_LOOP)

func display_guide() -> void:
	DemoUI.set_visible(true)

func hide_guide() -> void:
	DemoUI.set_visible(false)

func exit_game() -> void:
	get_tree().quit() # probably add some other safeguards as well
