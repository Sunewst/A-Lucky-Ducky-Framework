extends Control

signal currently_typing

var code_editor: CodeEdit

@export var default_code_completion_canadits: code_completion_resource
@export var code_completion_canadits: Array[code_completion_resource]
@export var board_info: board_resource
@export var debug_messages: bool

var compile_arguments: Array[String]
var upload_arguments: Array[String]

var ino_file_path: String = 'res://Alterna/Alterna.ino'

var thread: Thread

var arduino_file: FileAccess

var _past_line: int
var _lines_added: int = 0


var _ignore_keywords: Array[String] = [
	"{",
	"}",
	"#include ",
	"case ",
	"switch ",
	"for ",
	"if ",
	"while ",
	"else if ",
	"default ",
	"int ",
	"default:",
	"Serial.begin",
]


func _ready() -> void:
	compile_arguments = ['compile', '--fqbn', board_info.board_FQBN, 'Alterna']
	upload_arguments = ['upload', '-p', SerialController.portName, '--fqbn', board_info.board_FQBN, 'Alterna']
	
	code_editor = %CodeEdit
	
	#code_editor.add_gutter()
	#code_editor.set_gutter_type(2, TextEdit.GUTTER_TYPE_STRING)
	#code_editor.set_line_gutter_text(2, 2, 'A')
	#code_editor.set_gutter_clickable(2, true)
	#code_editor.set_gutter_draw(2, true)

	SerialController.SerialDataReceived.connect(_on_simple_serial_controller_serial_data_received)

	thread = Thread.new()
	
	
	code_editor.code_completion_enabled = false
	code_editor.text_changed.connect(code_request_code_completion)


func _on_simple_serial_controller_serial_data_received(data: String) -> void:
	
	if data.begins_with('$'):
		var _current_line: int = data.get_slice('$', 1).to_int()
		code_editor.set_line_background_color(_past_line - _lines_added - 1, Color(0,0,0,0))

		_lines_added = data.get_slice('$', 2).to_int()
		
		code_editor.set_line_background_color(_current_line - _lines_added - 1, Color(0,0.6,0,0.3))
		_past_line = _current_line

func _thread_function(cli_arguments: Array[String]):
	var path
	
	if cli_arguments[0].contains('upload'):
		cli_arguments[2] = SerialController.portName
		SerialController._ClosePort()
		
	if OS.get_name().contains("mac"):
		print("Using MacOS")
		path = ProjectSettings.globalize_path("res://arduino-cli")

	else:
		print("Using Windows")
		path = ProjectSettings.globalize_path("res://arduino-cli.exe")

	var output: Array[String] = []
	OS.execute(path, cli_arguments, output, true, false)
	
	print(output[0])
	if output[0].contains("Error"):
		_highlight_errors(output[0])
	if cli_arguments[0].contains('upload'):
		SerialController._OpenPort()


func _compile_code(userCode: CodeEdit, cli_arguments: Array[String]):
	var compiled_code = CodeEdit.new()
	var compiled_line_count: int
	var current_line: String
	var lines_added: int = 0

	for line in range (code_editor.get_line_count()):
		print('Clearing line ', line)
		code_editor.set_line_background_color(line, Color(0,0,0,0))
	
	for i in range(userCode.get_line_count()):
		current_line = userCode.get_line(i)
		compiled_line_count = compiled_code.get_line_count()
		if check_for_validity(current_line):
			if debug_messages:
				print("Valid " + str(i + 1) + ": " + str(current_line))
			compiled_code.insert_line_at(compiled_line_count - 1, current_line)
			lines_added += 1
			compiled_code.insert_line_at(compiled_line_count - 1, "Serial.println(\"$" + str(compiled_line_count + 1) + "$" + str(lines_added) + "\");")
		else:
			if debug_messages:
				print("Not Valid: " + str(i + 1) + ": " + str(current_line))
			compiled_code.insert_line_at(compiled_code.get_line_count() - 1, current_line)
		
	print("Your compiled code is ready")
	var arduino_file = FileAccess.open(ino_file_path, FileAccess.WRITE)

	arduino_file.store_string(compiled_code.get_text())
	create_thread(cli_arguments)
	compiled_code.queue_free()

func check_for_validity(line: String) -> bool:
	line = line.get_slice("//", 0).strip_edges()
	for ignore_keyword in _ignore_keywords:
		if line.begins_with(ignore_keyword) or line.ends_with(ignore_keyword) or line.is_empty():
			return false
	return true

func create_thread(cli_arguments: Array[String]) -> void:
	if not thread.is_alive():
		thread.wait_to_finish()
	else:
		return
	
	thread = Thread.new()
	thread.start(_thread_function.bind(cli_arguments))

func _exit_tree() -> void:
	print(thread.is_alive())
	thread.wait_to_finish()



func _on_compile_pressed() -> void:
	_compile_code(code_editor, compile_arguments)

func _on_upload_pressed() -> void:
	_compile_code(code_editor, upload_arguments)

func _on_code_edit_focus_entered() -> void:
	emit_signal("currently_typing", true)


func _on_code_edit_focus_exited() -> void:
	emit_signal("currently_typing", false)
	


func code_request_code_completion():
	for canadit in code_completion_canadits[0].code_completion_canadits:
		code_editor.add_code_completion_option(CodeEdit.KIND_FUNCTION, canadit, canadit)

	code_editor.update_code_completion_options(true)


func _highlight_errors(cli_output: String):
	
	var cli_output_array: PackedStringArray = cli_output.split("\n", true)
	var cli_error
	var cli_line_error

	for cli_line: String in cli_output_array:
		if cli_line.contains('error'):
			cli_error = cli_line.substr(cli_line.find(':'))
			if OS.get_name().contains('mac'):
				cli_line_error = cli_error.get_slice(':', 1).to_int()
			else:
				cli_line_error = cli_error.get_slice(':', 2).to_int()
			code_editor.set_line_background_color.call_deferred(cli_line_error - _total_lines_added(cli_line_error) - 1, Color(1,0,0,0.3))
	printerr("Failed to compile!")



func _total_lines_added(error_line: int) -> int:
	arduino_file = FileAccess.open(ino_file_path, FileAccess.READ)
	var compiled_code: PackedStringArray = arduino_file.get_as_text().split("\n")
	var total_added_lines: int = 0
	
	for i in error_line:
		if compiled_code[i].contains('Serial.println(\"$'):
			total_added_lines += 1
		
	print(total_added_lines, ' current count')

	return total_added_lines
