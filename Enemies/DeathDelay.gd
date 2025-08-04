extends Timer
class_name DeathDelay

const ERR_MSG_LOW_DELAY: String = "ERROR :: DeathDelay.gd - delay is too small"
const MIN_TIME: float = 2.0

@export var Delay: float

func _ready() -> void:
	assert(Delay >= MIN_TIME, ERR_MSG_LOW_DELAY)
	
	set_wait_time(Delay)
	set_one_shot(true)
	timeout.connect(death)

func death() -> void:
	owner.call_deferred("queue_free")
