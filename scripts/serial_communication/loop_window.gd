class_name LoopWindow extends Window

const LOOP_SCENE: PackedScene = preload("res://scenes/loop_scene.tscn")

static var window_exists = false

func _ready() -> void:
	self.connect("close_requested", close_window)

func close_window():
	queue_free()

static func display_new_loop_window():
	var new_loop_window: LoopWindow = LOOP_SCENE.instantiate()
	window_exists = true
	return new_loop_window
