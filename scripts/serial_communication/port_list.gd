extends OptionButton

var currentPorts

func _on_pressed() -> void:
	clear()
	currentPorts = SerialController._GetAllPorts()
	for i in currentPorts.size():
		add_item(currentPorts[i])


func _on_item_selected(index: int) -> void:
	SerialController._setConnectedPort(get_item_text(index))
