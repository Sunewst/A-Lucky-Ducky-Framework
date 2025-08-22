extends CodeEdit

@export var debug_messages: bool
@export var compile_arguments: Array[String]
@export var upload_arguments: Array[String]

var thread: Thread
var semaphore: Semaphore
var exit_loop: bool

var _past_line: int

var _ignore_keywords: Array[Variant] = [
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
	"Serial",
	"begin"
]


func _ready() -> void:
	SerialController.SerialDataReceived.connect(_on_simple_serial_controller_serial_data_received)

	semaphore = Semaphore.new()
	exit_loop = false
	thread = Thread.new()
	
func _on_simple_serial_controller_serial_data_received(data: String) -> void:
	
	if data.begins_with('$'):
		var _current_line: int = data.get_slice('$', 1).to_int()
		var _lines_added: int = data.get_slice('$', 2).to_int()

		set_line_background_color(_past_line - _lines_added, Color(0,0,0,0))
		print(str(_past_line - _lines_added) + ": Removeing Highlighting")
		set_line_background_color(_current_line - _lines_added - 1, Color(0,0.6,0,0.3))
		print(str(_current_line - _lines_added - 1) + ": Highlighting")
		_past_line = _current_line
		

func _thread_function(cli_arguments: Array[String]):
	var path
	if cli_arguments[0].contains('upload'):
		SerialController._ClosePort()
	if OS.get_name().contains("mac"):
		print("Using MacOS")
		path = ProjectSettings.globalize_path("res://arduino-cli")

	else:
		print("Using Windows")
		path = ProjectSettings.globalize_path("res://arduino-cli.exe")

	var output: Array[Variant] = []
	OS.execute(path, cli_arguments, output, false, false)
	
	print(output)
	if cli_arguments[0].contains('upload'):
		SerialController._OpenPort()


func _compile_code(userCode: CodeEdit, cli_arguments: Array[String]):
	var compiled_code = CodeEdit.new()
	var compiled_line_count: int
	var current_line: String
	var lines_added: int = 0


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
	
	var arduino_file = FileAccess.open("res://Alterna/Alterna.ino", FileAccess.WRITE)
	
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



func _on_button_pressed() -> void:
	_compile_code($".", compile_arguments)

func _on_button_pressed2() -> void:
	_compile_code($".", upload_arguments)
