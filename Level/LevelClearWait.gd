extends Timer
class_name LevelClearWait

@export var Delay: float

func _ready():
	set_wait_time(Delay)
	set_one_shot(true)
