extends Control

signal currently_typing
signal board_changed
signal line_edited

@onready var code_editor: CodeEdit = %CodeEdit
@onready var current_board: String = boards_info[1].board_FQBN

@export var default_code_completion_canadits: code_completion_resource
@export var code_completion_canadits: Array[code_completion_resource]
@export var boards_info: Array[board_resource]

@export var debug_messages: bool

const INO_USER_PATH: String = 'user://Nest//Nest.ino'
var ino_file_path: String = ProjectSettings.globalize_path(INO_USER_PATH)

var compile_arguments: Array[String]
var upload_arguments: Array[String]

var thread: Thread

var _past_line: int
var _lines_added: int = 0
var _compiled_line_count: int

var code_editor_menu

var board_menu = PopupMenu.new()

var _text_timer: Timer

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

var _unique_highlighting_keywords: Dictionary = {
	"delay": [Callable(self, "delay_highlighting")],
}


func _ready() -> void:
	compile_arguments = ['compile', '--fqbn', current_board, ino_file_path]
	upload_arguments = ['upload', '-p', SerialController.portName, '--fqbn', current_board, ino_file_path]

	code_editor_menu = code_editor.get_menu()

	for i in boards_info.size():
		board_menu.add_item(boards_info[i].board_FQBN)

	code_editor_menu.add_submenu_node_item("Boards", board_menu)

	board_menu.id_pressed.connect(_on_board_clicked)
	SerialController.SerialDataReceived.connect(_on_serial_data_received)

	code_editor.add_gutter(2)
	code_editor.set_gutter_type(2, TextEdit.GUTTER_TYPE_STRING)

	thread = Thread.new()

	_text_timer = Timer.new()
	_text_timer.set_one_shot(true)
	_text_timer.set_wait_time(1.0)
	add_child(_text_timer)

	code_editor.code_completion_enabled = false
	code_editor.text_changed.connect(code_request_code_completion)

	_text_timer.timeout.connect(user_finished_typing)

	mark_loop()


func _on_serial_data_received(data: String) -> void:
	if data.begins_with('$'):
		var serial_slices: PackedStringArray = data.split("$", false)
		if data.count("$") >= 2:
			_unique_highlighting_keywords[serial_slices[1]][0].call(serial_slices[0].to_int())
		else:
			var _current_line: int = serial_slices[0].to_int()
			code_editor.set_line_background_color(_past_line - _lines_added - 1, Color(0, 0, 0, 0))

			_lines_added = _total_lines_added(_current_line)

			code_editor.set_line_background_color(_current_line - _lines_added - 1, Color(0, 0.6, 0, 0.3))
			_past_line = _current_line


func _compile_code(userCode: CodeEdit, cli_arguments: Array[String]):
	var _compiled_code = CodeEdit.new()
	var _current_line: String
	var _arduino_file: FileAccess = FileAccess.open(INO_USER_PATH, FileAccess.WRITE)

	if not DirAccess.dir_exists_absolute("user://Nest"):
		DirAccess.make_dir_absolute("user://Nest")

	for line in range(code_editor.get_line_count()):
		code_editor.set_line_background_color(line, Color(0, 0, 0, 0))

	for i in range(userCode.get_line_count()):
		_current_line = userCode.get_line(i)
		_compiled_line_count = _compiled_code.get_line_count()
		var highlight_keyword: String = check_for_validity(_current_line)

		if not highlight_keyword.is_empty():
			if debug_messages:
				print("Valid " + str(i + 1) + ": " + str(_current_line))
			_compiled_code.insert_line_at(_compiled_line_count - 1, _current_line)
			_compiled_code.insert_line_at(_compiled_line_count - 1, highlight_keyword)

		else:
			if debug_messages:
				print("Not Valid: " + str(i + 1) + ": " + str(_current_line))
			_compiled_code.insert_line_at(_compiled_code.get_line_count() - 1, _current_line)

	print("Your compiled code is ready")

	_arduino_file.store_string(_compiled_code.get_text())
	create_thread(cli_arguments)

	_compiled_code.queue_free()


func create_thread(cli_arguments: Array[String]) -> void:
	if not thread.is_alive():
		thread.wait_to_finish()
	else:
		return

	thread = Thread.new()
	thread.start(_thread_function.bind(cli_arguments))


func _thread_function(cli_arguments: Array[String]) -> void:
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


func check_for_validity(line: String) -> String:
	var print_highlight: String = "Serial.println(\"\\n$%s$%s$%s\");"

	line = line.get_slice("//", 0).strip_edges()
	for ignore_keyword in _ignore_keywords:
		if line.begins_with(ignore_keyword) or line.ends_with(ignore_keyword) or line.is_empty():
			return ""

	for unique_highlighting_keyword in _unique_highlighting_keywords.keys():
		if line.contains(unique_highlighting_keyword):
			print_highlight = print_highlight % [_compiled_line_count + 1, unique_highlighting_keyword, line.to_int()]
			return print_highlight

	return "Serial.println(\"\\n$%s);" % [_compiled_line_count + 1]


func _on_compile_pressed() -> void:
	_compile_code(code_editor, compile_arguments)


func _on_upload_pressed() -> void:
	_compile_code(code_editor, upload_arguments)


func _on_code_edit_focus_entered() -> void:
	emit_signal("currently_typing", true)


func _on_code_edit_focus_exited() -> void:
	emit_signal("currently_typing", false)


func code_request_code_completion() -> void:
	for canadit in code_completion_canadits[0].code_completion_canadits:
		code_editor.add_code_completion_option(CodeEdit.KIND_FUNCTION, canadit, canadit)

	code_editor.update_code_completion_options(true)


func _highlight_errors(cli_output: String) -> void:
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
			code_editor.set_line_background_color.call_deferred(cli_line_error - _total_lines_added(cli_line_error) - 1, Color(1, 0, 0, 0.3))
	printerr("Failed to compile!")


func delay_highlighting(line: int) -> void:
	code_editor.set_line_background_color(line, Color(0.78, 0.718, 0.02, 0.125))
	add_child(TimerDisplay.create_new_timer(5, 8))


func _total_lines_added(last_line: int) -> int:
	var arduino_file: FileAccess = FileAccess.open(INO_USER_PATH, FileAccess.READ)
	var compiled_code: PackedStringArray = arduino_file.get_as_text().split("\n")
	var total_added_lines: int = 0

	for i in last_line:
		if compiled_code[i].contains('Serial.println(\"\\n$'):
			total_added_lines += 1

	return total_added_lines


func _on_board_clicked(id: int) -> void:
	current_board = board_menu.get_item_text(id)

	compile_arguments[2] = current_board
	upload_arguments[4] = current_board

	board_changed.emit(current_board)

	print("Changed board to ", current_board)


func find_total_occurrences(text: String) -> Array[Vector2i]:
	var _occurences_locations: Array[Vector2i]
	var _current_line: Vector2i = Vector2i(0, 0)
	var _occurence

	for i in code_editor.get_line_count():
		_occurence = code_editor.search(text, 2, _current_line.y + 1, 0)

		if _occurence.y != -1 and _occurence not in _occurences_locations:
			_occurences_locations.append(_occurence)
			_current_line = _occurence
		else:
			break
	return _occurences_locations


func mark_loop() -> void:
	var loop_start_location: Vector2i = code_editor.search("Void loop()", 2, 0, 0)

	code_editor.set_line_gutter_text(loop_start_location[1], 2, 'L')
	code_editor.set_line_gutter_clickable(loop_start_location[1], 2, true)
	code_editor.set_line_gutter_item_color(loop_start_location[1], 2, Color(0.909, 0.189, 0.475, 1.0))


func mark_libraries():
	var library_locations: Array[Vector2i] = find_total_occurrences("#include ")

	for location in library_locations:
		code_editor.set_line_gutter_text(location.y, 2, '#')
		code_editor.set_line_gutter_item_color(location.y, 2, Color(0.232, 0.73, 0.207, 1.0))


func _on_code_edit_gutter_clicked(line: int, gutter: int) -> void:
	print("Gutter ", gutter, " Line: ", line)

	if code_editor.is_line_gutter_clickable(line, gutter) and not LoopWindow.window_exists:
		print("Gutter clickable!")
		add_child(LoopWindow.display_new_loop_window())


func _on_code_edit_text_changed() -> void:
	_text_timer.start()


func user_finished_typing() -> void:
	emit_signal("line_edited")
	mark_libraries()
	mark_loop()
	code_editor.set_gutter_draw(2, true)


func _exit_tree() -> void:
	thread.wait_to_finish()
