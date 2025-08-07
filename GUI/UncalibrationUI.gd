extends Control
class_name UncalibrationUI

signal triggered
signal cleared

const WINDOW: float = 5.0
const TARGET_THRESHOLD: int = 128

@export var BoxSize: int
@export var Body: Node2D

@onready var UncalibrationWindow: Timer = $UncalibrationWindow
@onready var TimeLeft: Label = $TimeLeft
@onready var ExecutionIcon = $ExecutionIcon

var active: bool = false
var primed: bool = false
var target_bound: Vector4

func _ready() -> void:
	init_box_size()
	init_uncalibration_window()
	ExecutionIcon.set_visible(false)
	set_visible(false)

func _physics_process(delta) -> void:
	if active:
		if Global.is_vector_in_bound(get_global_mouse_position(), target_bound):
			
			if !primed: ## spaghetti warning
				Events.execution_ready.emit(Body)
			primed = true
			
			ExecutionIcon.set_visible(true)
		else:
			
			if primed: ## spaghetti warning
				Events.execution_unready.emit()
			primed = false
			
			ExecutionIcon.set_visible(false)
		
		TimeLeft.set_text("%2.1f" % UncalibrationWindow.time_left)

func init_box_size() -> void:
	size.x = BoxSize
	size.y = BoxSize
	position.x -= BoxSize * 0.5
	position.y -= BoxSize * 0.5
	pivot_offset.x += BoxSize * 0.5
	pivot_offset.y += BoxSize * 0.5
	
	ExecutionIcon.position = pivot_offset
	target_bound = Vector4(
		ExecutionIcon.global_position.x - TARGET_THRESHOLD,
		ExecutionIcon.global_position.x + TARGET_THRESHOLD,
		ExecutionIcon.global_position.y - TARGET_THRESHOLD, 
		ExecutionIcon.global_position.y + TARGET_THRESHOLD )

func update_target_bound() -> void:
	target_bound = Vector4(
		ExecutionIcon.global_position.x - TARGET_THRESHOLD,
		ExecutionIcon.global_position.x + TARGET_THRESHOLD,
		ExecutionIcon.global_position.y - TARGET_THRESHOLD, 
		ExecutionIcon.global_position.y + TARGET_THRESHOLD )

func init_uncalibration_window() -> void:
	UncalibrationWindow.set_timer_process_callback(Timer.TIMER_PROCESS_PHYSICS)
	UncalibrationWindow.set_wait_time(WINDOW)
	UncalibrationWindow.set_one_shot(true)
	UncalibrationWindow.timeout.connect(reset)

func trigger() -> void:
	active = true
	set_visible(true)
	UncalibrationWindow.start()
	triggered.emit()
	Events.enemy_uncalibrated.emit()

func reset() -> void:
	cleared.emit()
	active = false
	set_visible(false)

func close() -> void:
	set_visible(false)
	set_process(false)
	set_physics_process(false)
