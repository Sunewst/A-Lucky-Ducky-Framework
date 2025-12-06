extends Control


func _ready() -> void:
	print($MarginContainer/VBoxContainer/Label.size)
	$MarginContainer/VBoxContainer/Label.set_size(Vector2(1000, 1000))
	print($MarginContainer/VBoxContainer/Label.size)
