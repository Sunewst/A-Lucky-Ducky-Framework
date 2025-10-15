extends Node

signal compiling_finished
#signal uploading_finished

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


func _arduino_cli_execute(cli_arguments: Array[String]):
	var _path: String
	var _output: Array[String] = []

	if OS.get_name().contains("mac"):
		_path = ProjectSettings.globalize_path("res://cli/arduino-cli")
	else:
		_path = ProjectSettings.globalize_path("res://cli/arduino-cli.exe")

	OS.execute(_path, cli_arguments, _output, true, false)

	if _output[0].contains("Error"):
		call_deferred("emit_signal", "compiling_finished", _output[0], false)
	else:
		call_deferred("emit_signal", "compiling_finished", _output[0], true)



func _exit_tree() -> void:
	thread.wait_to_finish()
