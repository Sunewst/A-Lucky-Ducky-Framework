class_name BoardProperties extends Window

const BOARD_PROPERTIES_SCENE: PackedScene = preload("res://core/scenes/code_editor/board_properties_menu.tscn")


func _ready() -> void:
	self.connect("close_requested", close_window)


func close_window():
	hide()


static func display_new_properties_window():
	var new_properties_window: BoardProperties = BOARD_PROPERTIES_SCENE.instantiate()
	return new_properties_window
