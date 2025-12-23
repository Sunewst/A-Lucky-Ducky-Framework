@tool
class_name SaveDebug extends Node

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() and event.is_action_pressed("debug_delete_save"):
		pass
