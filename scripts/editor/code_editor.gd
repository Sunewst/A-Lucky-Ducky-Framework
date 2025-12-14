class_name CodeEditor extends CodeEdit

@onready var current_board: String = boards_info[3].board_FQBN
@onready var code_edit_node: CodeEdit = %CodeEdit

@export_group("Boards")
@export var code_completion_candidates: Array[code_completion_resource]
@export var boards_info: Array[board_resource]
@export var arduino_libraries: Array[library_resource]

@export_group("Debug")
@export var debug_validity_messages: bool # If true, print out whether or not a line is 'Valid' 
@export var debug_highlights: bool # If true, highlight when each line is executed
@export var saving_enabled: bool = false

const GUTTER: int = 2 # Main gutter
const INO_USER_PATH: String = 'user://Nest//Nest.ino' # The godot path to the .ino file

var ino_global_path: String = ProjectSettings.globalize_path(INO_USER_PATH) # The global path to the .ino file

var board_save_data: Dictionary


var compile_arguments: Array[String] # Main compile arguments used in the arduino-cli
var upload_arguments: Array[String] # Main upload arguments used in the arduino-cli

var _past_line: int
var _lines_added: int = 0
var _compiled_line_count: int
var _libraries_added: PackedStringArray

var code_editor_menu

var board_menu = PopupMenu.new()

var _text_timer: Timer

const IGNORE_KEYWORDS: Array[String] = [
	"{",
	"}",
	"#include ",
	"case",
	"switch",
	"for",
	"if",
	"unsigned",
	"while",
	"else if",
	"default ",
	"int ",
	"default:",
	"Serial.begin",
]


var _unique_highlighting_keywords: Dictionary = {
	"delay": [Callable(self, "delay_highlighting")],
}


func _ready() -> void:
	if not _load_save_data() == null:
		print('Loaded save')
		board_save_data = _load_save_data()
	else:
		printerr('Save data failed to load')

	compile_arguments = ['compile', '--fqbn', current_board, ino_global_path]
	upload_arguments = ['upload', '-p', SerialController._GetPort(), '--fqbn', current_board, ino_global_path]

	code_editor_menu = get_menu()

	for board in boards_info:
		board_menu.add_item(board.board_FQBN)

	code_editor_menu.add_submenu_node_item("Boards", board_menu)

	board_menu.id_pressed.connect(_on_board_clicked)
	SerialController.SerialDataReceived.connect(_on_serial_data_received)
	ArduinoCli.compiling_finished.connect(_compiling_finished)

	SignalController.load.connect(load_data)
	SignalController.save.connect(save_data)

	_add_main_gutter()

	_text_timer = Timer.new()
	_text_timer.set_one_shot(true)
	_text_timer.set_wait_time(1.0)
	add_child(_text_timer)

	code_completion_enabled = false

	text_changed.connect(code_request_code_completion)
	_text_timer.timeout.connect(finished_typing)


func _on_serial_data_received(data: String) -> void:
	if data.begins_with('$'):
		var serial_slices: PackedStringArray = data.split("$", false)
		if data.count("$") >= 2:
			_unique_highlighting_keywords[serial_slices[1]][0].call(serial_slices[0].to_int())
		else:
			var _current_line: int = serial_slices[0].to_int()
			set_line_background_color(_past_line - _lines_added - 1, Color(0, 0, 0, 0))

			_lines_added = _total_lines_added(_current_line)

			set_line_background_color(_current_line - _lines_added - 1, Color(0, 0.6, 0, 0.3))
			_past_line = _current_line


func _compile_code(user_code: CodeEdit, cli_arguments: Array[String]):
	var _compiled_code = CodeEdit.new()
	var _current_line: String
	var _arduino_file: FileAccess = FileAccess.open(INO_USER_PATH, FileAccess.WRITE)

	if not DirAccess.dir_exists_absolute("user://Nest"):
		DirAccess.make_dir_absolute("user://Nest")

	for line in range(get_line_count()):
		set_line_background_color(line, Color(0, 0, 0, 0))

	for i in range(user_code.get_line_count()):
		_current_line = user_code.get_line(i)
		_compiled_line_count = _compiled_code.get_line_count()
		var highlight_keyword: String = check_for_validity(_current_line)

		if not highlight_keyword.is_empty():
			if debug_validity_messages:
				print("Valid " + str(i + 1) + ": " + str(_current_line))
			_compiled_code.insert_line_at(_compiled_line_count - 1, _current_line)
			_compiled_code.insert_line_at(_compiled_line_count - 1, highlight_keyword)
		else:
			if debug_validity_messages:
				print("Not Valid " + str(i + 1) + ": " + str(_current_line))
			_compiled_code.insert_line_at(_compiled_code.get_line_count() - 1, _current_line)
	
	for library in _libraries_added:
		var _library_update_function: String
		var _library_print: String
		var _loop_start_location: Vector2i = EditorHelper.get_loop_location(_compiled_code)

		for available_library in arduino_libraries:
			if available_library.library_name.contains(library):
				var _library_location: Array[Vector2i] = EditorHelper.find_total_occurrences(available_library.library_name, code_edit_node)
				var _library_initialization_var: String
				var _library_function: String
				var _initialization_location = search(available_library.library_name.get_slice(".", 0), 2, _library_location[0].y + 1, 0)

				_library_update_function = available_library.library_update_function
				_library_initialization_var = get_line(_initialization_location.y).get_slice(" ", 1).replace(";", "")

				_library_function = str(_library_initialization_var + "." + _library_update_function)
				_library_print = "Serial.println(\"\\n$p$\" + %s);" % [_library_function]

				_compiled_code.insert_line_at(_loop_start_location.y + 1, _library_print)
				_loop_start_location.y += 1

	_arduino_file.store_string(_compiled_code.get_text())
	ArduinoCli.execute_arduino_cli(cli_arguments)

	_compiled_code.queue_free()


func _compiling_finished(cli_output: String, successful: bool):
	if successful:
		print(cli_output)
	else:
		print(cli_output)
		_highlight_errors(cli_output)


func check_for_validity(line: String) -> String:
	var _print_highlight: String = "Serial.println(\"\\n$%s$%s$%s\");" 

	line = line.get_slice("//", 0).strip_edges()

	for ignore_keyword in IGNORE_KEYWORDS:
		if line.begins_with(ignore_keyword) or line.ends_with(ignore_keyword) or line.is_empty():
			return ""

	for unique_highlighting_keyword in _unique_highlighting_keywords.keys():
		if line.contains(unique_highlighting_keyword):
			_print_highlight = _print_highlight % [_compiled_line_count + 1, unique_highlighting_keyword, line.to_int()]
			return _print_highlight

	if debug_highlights:
		return "Serial.println(\"\\n$%s\");" % [_compiled_line_count + 1]
	else:
		return ""


func _on_compile_pressed() -> void:
	_compile_code(code_edit_node, compile_arguments)


func _on_upload_pressed() -> void:
	upload_arguments[2] = SerialController._GetPort()
	_compile_code(code_edit_node, upload_arguments)


func _on_code_edit_focus_entered() -> void:
	SignalController.editor_in_focus.emit(true)


func _on_code_edit_focus_exited() -> void:
	SignalController.editor_in_focus.emit(false)


func code_request_code_completion() -> void:
	for candidates_resource in code_completion_candidates:
		for candidate in candidates_resource.available_completion_candidates:
			add_code_completion_option(CodeEdit.KIND_FUNCTION, candidate, candidate)

	if is_in_string(get_caret_line(), get_caret_column()) == -1:
		update_code_completion_options(true)


func _highlight_errors(cli_output: String) -> void:
	var _cli_output_array: PackedStringArray = cli_output.split("\n", true)
	var _cli_error
	var _cli_line_error

	for cli_line: String in _cli_output_array:
		if cli_line.contains('error'):
			_cli_error = cli_line.substr(cli_line.find(':'))
			if OS.get_name().contains('mac'):
				_cli_line_error = _cli_error.get_slice(':', 1).to_int()
			else:
				_cli_line_error = _cli_error.get_slice(':', 2).to_int()
			set_line_background_color(_cli_line_error - _total_lines_added(_cli_line_error) - 1, Color(1, 0, 0, 0.3))

	printerr("Failed to compile, see errors")


func delay_highlighting(line: int) -> void:
	set_line_background_color(line, Color(0.78, 0.718, 0.02, 0.125))
	add_child(TimerDisplay.create_new_timer(5, 8))


func _total_lines_added(last_line: int) -> int:
	var _arduino_file: FileAccess = FileAccess.open(INO_USER_PATH, FileAccess.READ)
	var _compiled_code: PackedStringArray = _arduino_file.get_as_text().split("\n")
	var _total_added_lines: int = 0

	for i in last_line:
		if _compiled_code[i].contains('Serial.println(\"\\n$'):
			_total_added_lines += 1

	return _total_added_lines


func _on_board_clicked(id: int) -> void:
	current_board = board_menu.get_item_text(id)

	compile_arguments[2] = current_board
	upload_arguments[4] = current_board
	print("Changed board to ", current_board)

	SignalController.board_changed.emit(boards_info[id])


func mark_loop() -> void:
	var _loop_start_location: Vector2i = EditorHelper.get_loop_location(code_edit_node)

	if _loop_start_location != Vector2i(-1, -1):
		set_line_gutter_text(_loop_start_location[1], GUTTER, 'L')
		set_line_gutter_clickable(_loop_start_location[1], GUTTER, true)
		set_line_gutter_item_color(_loop_start_location[1], GUTTER, Color(0.909, 0.189, 0.475, 1.0))
	else:
		print("Failed to find loop function")


func mark_libraries():
	var _library_locations: Array[Vector2i] = EditorHelper.find_total_occurrences("#include ", code_edit_node)
	_libraries_added.clear()

	if not _library_locations.is_empty():
		for location in _library_locations:
			var library_name: String = get_line(location.y)

			set_line_gutter_text(location.y, GUTTER, '#')
			set_line_gutter_item_color(location.y, GUTTER, Color(0.232, 0.73, 0.207, 1.0))
			if library_name.contains("\""):
				_libraries_added.append(library_name.get_slice("\"", 1))
			else:
				_libraries_added.append(library_name.get_slice("<", 1).replace(">", ""))


func _add_main_gutter():
	add_gutter(GUTTER)
	set_gutter_type(GUTTER, TextEdit.GUTTER_TYPE_STRING)


func _redraw_gutter():
	remove_gutter(GUTTER)
	_add_main_gutter()


func _on_code_edit_gutter_clicked(line: int, gutter: int) -> void:
	print("Gutter ", gutter, " Line: ", line)

	if is_line_gutter_clickable(line, gutter) and not LoopWindow.window_exists:
		print("Gutter clickable")
		add_child(LoopWindow.display_new_loop_window())


func _on_code_edit_text_changed() -> void:
	_text_timer.start()


func finished_typing() -> void:
	_redraw_gutter()
	mark_libraries()
	mark_loop()
	set_gutter_draw(GUTTER, true)

	SignalController.finished_typing.emit()


func load_data(save_name: String = current_board):
	_set_board_save(save_name)


func save_data(save_name: String = current_board):
	board_save_data[save_name] = get_text()


func save():
	var _save_dict = {
	}
	_save_dict.merge(board_save_data)

	return _save_dict


func _load_save_data():
	var _board_save_file = FileAccess.open("user://save_data//board.save", FileAccess.READ)

	while _board_save_file.get_position() < _board_save_file.get_length():
		var _json_string = _board_save_file.get_line()
		var _json = JSON.new()

		var _parse_result = _json.parse(_json_string)

		if not _parse_result == OK:
			printerr("JSON Parse Error: ", _json.get_error_message(), " in ", _json_string, " at line ", _json.get_error_line())
			continue

		var _save_dict = _json.data

		return _save_dict


func _set_board_save(save_name: String):
	if board_save_data.has(save_name):
		text = board_save_data[save_name]
	else:
		print("No valid save to load")

	mark_loop()
	mark_libraries()


func _exit_tree() -> void:
	if saving_enabled:
		SaveHandler.save_board_data()
