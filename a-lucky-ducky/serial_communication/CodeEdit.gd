extends CodeEdit
var _past_line: int
var thread: Thread
var _ignore_keywords = [
	"{",
	"}",
	"#include",
	"case",
	"switch",
	"for",
	"if",
	"while",
	"else if",
	"default",
	"//"
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
		

func _thread_function():
	var args = ['board', 'list']
	var path
	if OS.get_name().contains("mac"):
		print("Using MacOS")
		#path = ProjectSettings.globalize_path("res//arduino-cli")
		path = "/Users/sunewst/Documents/GitHub/A-Lucky-Ducky-Framework/a-lucky-ducky/arduino-cli"
	else:
		path = "C:\\Users\\boccs\\OneDrive\\Documents\\GitHub\\A-Lucky-Ducky-Framework\\a-lucky-ducky\\arduino-cli.exe"
		print("Using Windows")
	var blocking = false
	var output = []
	OS.execute(path, args, output, false, false)
	print(output)


func _compile_code(userCode: CodeEdit):
	for i in range(userCode.get_line_count()):
		userCode
		var _currentLine = userCode.get_line(i)
		if _check_for_validity(_currentLine):
			print("Valid: " + str(_currentLine))
		else:
			print("Not Valid: " + str(_currentLine))
		

func _check_for_validity(line: String, ):
	for ignore_keyword in _ignore_keywords:
		if line.contains(ignore_keyword) or line == "":
			return false
	return true
