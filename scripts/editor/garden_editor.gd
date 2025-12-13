extends Control

func _ready() -> void:
	SignalController.show_editor.connect(show_editor)
	SignalController.hide_editor.connect(hide_editor)

func show_editor():
	show()


func hide_editor():
	hide()
