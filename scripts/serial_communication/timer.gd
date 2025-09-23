class_name TimerDisplay extends Control

const TIMER_SCENE: PackedScene = preload("res://scenes/timer.tscn")

var time_left: float

@onready var timer: Timer = %Timer
@onready var timer_label: Label = %TimerDisplayLabel
func _ready() -> void:
	timer.timeout.connect(timer_finished)
	timer.set_wait_time(time_left)

func _process(_delta: float) -> void:
	timer_label.text = str("%.1f" % timer.get_time_left())


func timer_finished():
	queue_free()

static func create_new_timer(time_start_amount: float, _timer_position):
	var new_timer: TimerDisplay = TIMER_SCENE.instantiate()
	new_timer.time_left = time_start_amount

	return new_timer
