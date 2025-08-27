extends OptionButton

func _on_pressed() -> void:
	clear()
	var currentPorts = SerialController._GetAllPorts()
	for i in currentPorts.size():
		add_item(currentPorts[i])


func _on_item_selected(index: int) -> void:
	SerialController._setConnectedPort(get_item_text(index))
