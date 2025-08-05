extends CodeEdit

@export var debug_messages: bool

var thread: Thread

var _past_line: int
var _ignore_keywords = [
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
]


func _ready() -> void:
	#print(OS.get_name())
	#if OS.get_name() == "Windows":
	thread = Thread.new()
	thread.start(_thread_function.bind())
	_compile_code($".")


func _process(delta: float) -> void:
	pass

func _on_simple_serial_controller_serial_data_received(data: String) -> void:
	var _current_line: int = data.get_slice('$', 1).to_int()
	print("Current:" + str(_current_line))
	if data.begins_with('$'):
		set_line_background_color(_past_line - 1, Color(0,0,0,0))
		set_line_background_color(_current_line - 1, Color(0,0.6,0,0.3))
		_past_line = _current_line
	if data.begins_with('()'):
		pass
		#set_line_background_color(data.get_slice('', 1).to_int(), Color(0,0.6,0,0.3))
		

func _thread_function(_compiled_code: String):
	var args = ['board', 'list']
	var path
	if OS.get_name().contains("mac"):
		print("Using MacOS")
		path = "/Users/sunewst/Documents/GitHub/A-Lucky-Ducky-Framework/a-lucky-ducky/arduino-cli"
	else:
		path = "C:\\Users\\boccs\\OneDrive\\Documents\\GitHub\\A-Lucky-Ducky-Framework\\a-lucky-ducky\\arduino-cli.exe"
		print("Using Windows")
	var blocking = false
	var output = []
	OS.execute(path, args, output, false, false)
	print(output)


func _compile_code(userCode: CodeEdit):
	var _compiled_code = CodeEdit.new()
	var _current_line_count: int
	for i in range(userCode.get_line_count()):
		var _current_line: String = userCode.get_line(i)
		_current_line_count = _compiled_code.get_line_count()
		if _check_for_validity(_current_line):
			if debug_messages:
				print("Valid " + str(i + 1) + ": " + str(_current_line))
			_compiled_code.insert_line_at(_current_line_count - 1, _current_line)
			_compiled_code.insert_line_at(_current_line_count - 2, "Serial.println('$" + str(_current_line_count + 1) + "');")
			#FileAccess.open("res://hello_world.ino",FileAccess.WRITE)
		else:
			if debug_messages:
				print("Not Valid: " + str(_current_line))
			_compiled_code.insert_line_at(_compiled_code.get_line_count() - 1, _current_line)
	print("Your compiled code is ready")
	#_thread_function(_compiled_code.get_text())
	#set_text(_compiled_code.get_text())
		

func _check_for_validity(line: String):
	line = line.get_slice("//", 0).strip_edges()
	for ignore_keyword in _ignore_keywords:
		if line.begins_with(ignore_keyword) or line.ends_with(ignore_keyword) or line.is_empty():
			return false
	return true
