extends RichTextLabel


func _ready() -> void:
	SerialController.SerialDataReceived.connect(_serial_info_received)
	ArduinoCli.compiling_finished.connect(_compiling_finished)
	

func _serial_info_received(data: String):
	if not data.contains("$"):
		add_text(data)


func _compiling_finished(cli_output: String, _successful: bool):
	add_text(cli_output)
