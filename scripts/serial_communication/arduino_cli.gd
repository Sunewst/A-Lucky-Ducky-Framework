extends Node

signal compiling_finished
signal uploading_finished

var thread: Thread 

func _ready() -> void:
	thread = Thread.new()


func execute_arduino_cli(cli_arguments):
	if not thread.is_alive():
		thread.wait_to_finish()
	else:
		return
	
	thread = Thread.new()
	thread.start(_arduino_cli_execute.bind(cli_arguments))


func _arduino_cli_execute(cli_arguments: Array[String]) -> Array[String]:
	var path: String
	var output: Array[String] = []

	if cli_arguments[0].contains('upload'):
		cli_arguments[2] = SerialController.portName
		SerialController._ClosePort()

	if OS.get_name().contains("mac"):
		path = ProjectSettings.globalize_path("res://cli/arduino-cli")
	else:
		path = ProjectSettings.globalize_path("res://cli/arduino-cli.exe")

	OS.execute(path, cli_arguments, output, true, false)
	print(output[0])

	return output

func _exit_tree() -> void:
	thread.wait_to_finish()
