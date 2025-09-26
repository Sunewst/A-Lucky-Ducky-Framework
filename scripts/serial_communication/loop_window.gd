class_name LoopWindow extends Window

const LOOP_SCENE: PackedScene = preload("res://scenes/loop_scene.tscn")

static func display_new_loop_window():
	var new_loop_window: LoopWindow = LOOP_SCENE.instantiate()
	return new_loop_window
