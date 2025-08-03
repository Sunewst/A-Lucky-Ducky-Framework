extends CodeEdit
var _past_line: int
var thread: Thread


func _ready() -> void:
	pass
	#print(OS.get_name())
	#if OS.get_name() == "Windows":
	#thread = Thread.new()
	#thread.start(_thread_function.bind())


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
	if OS.get_name() == "MacOS":
		#path = ProjectSettings.globalize_path("res//arduino-cli")
		path = "/Users/sunewst/Documents/GitHub/A-Lucky-Ducky-Framework/a-lucky-ducky/arduino-cli"
	else:
		path = "C:\\Users\\boccs\\OneDrive\\Documents\\GitHub\\A-Lucky-Ducky-Framework\\a-lucky-ducky\\arduino-cli.exe"
	var blocking = false
	var output = []
	OS.execute(path, args, output, false, false)
	print(output)
