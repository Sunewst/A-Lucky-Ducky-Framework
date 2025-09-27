extends RichTextLabel


func _ready() -> void:
	SerialController.SerialDataReceived.connect(_serial_info_received)
	

func _serial_info_received(data: String):
	if not data.contains("$"):
		add_text(data)
