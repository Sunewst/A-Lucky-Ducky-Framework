extends Node

signal compiling_finished
#signal uploading_finished


@onready var thread: Thread = Thread.new()


func execute_arduino_cli(cli_arguments):
	if not thread.is_alive():
		thread.wait_to_finish()
	else:
		return
	
	thread = Thread.new()
	thread.start(_arduino_cli_execute.bind(cli_arguments))


func execute_arduino_app_cli(cli_arguments: Array[String]):
	if not thread.is_alive():
		thread.wait_to_finish()
	else:
		return
	
	thread = Thread.new()
	thread.start(_arduino_app_cli_execute.bind(cli_arguments))


func _arduino_cli_execute(cli_arguments: Array[String]):
	var _path: String
	var _output: Array[String] = []

	## @experimental
	if cli_arguments.has("upload"):
		SerialController.call_deferred("_ClosePort")
		print("Uploading...")

	if OS.get_name().contains("mac"):
		_path = ProjectSettings.globalize_path("res://cli/arduino-cli")
	else:
		_path = ProjectSettings.globalize_path("res://cli/arduino-cli.exe")

	OS.execute(_path, cli_arguments, _output, true, false)
	
	## @experimental
	if cli_arguments.has("upload"):
		SerialController.call_deferred("_OpenPort")

	if _output[0].contains("Error"):
		call_deferred("emit_signal", "compiling_finished", _output[0], false)
	else:
		call_deferred("emit_signal", "compiling_finished", _output[0], true)


func _arduino_app_cli_execute(cli_arguments: Array[String]):
	var _path: String
	var _output: Array[String] = []
	var _process
	var _process_io: FileAccess
	
	_process = OS.execute_with_pipe('echo', cli_arguments)
	_process_io = _process['stdio']

	while _process_io.is_open() and _process_io.get_error() == OK:
		print(_process_io.get_line())


func _exit_tree() -> void:
	thread.wait_to_finish()
