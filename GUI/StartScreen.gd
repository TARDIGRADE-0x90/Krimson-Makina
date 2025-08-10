extends Control
class_name StartScreen

@onready var StartButton: Button = $MenuButtonMargin/MenuButtons/StartButton
@onready var GuideButton: Button  = $MenuButtonMargin/MenuButtons/GuideButton
@onready var ExitButton: Button  = $MenuButtonMargin/MenuButtons/ExitButton
@onready var DemoUI: Control = $DemoUI
@onready var ReturnButton: Button = $DemoUI/ReturnButton

"""
do later -
> make guide screen a bit longer to better elaborate on how the game plays
"""

func _ready():
	DemoUI.set_visible(false)
	StartButton.pressed.connect(start_game)
	GuideButton.pressed.connect(display_guide)
	ReturnButton.pressed.connect(hide_guide)
	ExitButton.pressed.connect(exit_game)

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
