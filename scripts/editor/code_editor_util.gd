class_name EditorHelper extends Node

const CONTROL_STRUCTUERS: Array[String] = [
	"if",
	"else if",
	"while",
	"for",
]


const DATA_TYPES: Array[String] = [
	"int ",
	"float ",
	"void ", #Not really a data type
]

const OPERATORS: Array[String] = [
	"=="
]


static func find_total_occurrences(text: String, editor: CodeEdit) -> Array[Vector2i]:
	var _occurences_locations: Array[Vector2i]
	var _current_line_location: Vector2i = Vector2i(0, 0)
	var _occurence: Vector2i

	for i in editor.get_line_count():
		_occurence = editor.search(text, 2, _current_line_location.y + 1, 0)
		var _current_line: String = remove_comments(editor.get_line(_occurence.y))

		if _occurence.y != -1 and _occurence not in _occurences_locations and not _current_line.is_empty():
			_occurences_locations.append(_occurence)
			_current_line_location = _occurence
		else:
			break
	return _occurences_locations


static func get_loop_location(editor: CodeEdit) -> Vector2i:
	var location: Array[Vector2i] = find_total_occurrences("void loop()", editor)
	if not location.is_empty():
		return location[0]
	else:
		return Vector2i(-1, -1)


static func get_setup_location(editor: CodeEdit) -> Vector2i:
	var location: Array[Vector2i] = find_total_occurrences("void setup()", editor)
	if not location.is_empty():
		return location[0]
	else:
		return Vector2i(-1, -1)

## @deprecated These find functions are inefficient and need to be redone
static func find_total_data_types(editor: CodeEdit) -> Array[Vector2i]:
	var _potential_data_types: Array[Vector2i]
	var _occurences_locations: Array[Vector2i]

	for data_type in DATA_TYPES:
		_potential_data_types.append_array(find_total_occurrences(data_type, editor))

	for occurence in _potential_data_types:
		var current_line: String = editor.get_line(occurence.y)
		if not current_line.contains("("):
			_occurences_locations.append(occurence)

	return _occurences_locations


static func find_total_functions(editor: CodeEdit) -> Array[Vector2i]:
	var _occurences_locations: Array[Vector2i]
	var _potential_functions: Array[Vector2i]

	for data_type in DATA_TYPES:
		_potential_functions.append_array(find_total_occurrences(data_type, editor))

	for data_type in _potential_functions:
		var current_line: String = editor.get_line(data_type.y)

		if current_line.contains("(") and not current_line.contains("loop()") and not current_line.contains("setup()"):
			_occurences_locations.append(data_type)

	return _occurences_locations


static func find_total_operations(editor: CodeEdit) -> Array[Vector2i]:
	var _occurences_locations: Array[Vector2i]
	var _potential_operators: Array[Vector2i]
	
	_potential_operators.append_array(find_total_occurrences("=", editor))
	for operator in _potential_operators:
		var current_line: String = editor.get_line(operator.y)

		for data_type in DATA_TYPES:
			if current_line.contains(data_type):
				break
			_occurences_locations.append(operator)
			break

	return _occurences_locations


static func find_total_control_statements(editor: CodeEdit) -> Array[Vector2i]:
	var _occurences_locations: Array[Vector2i]

	for control_structure in CONTROL_STRUCTUERS:
		_occurences_locations.append_array(find_total_occurrences(control_structure, editor))

	return _occurences_locations


static func contains_array(string: String, array: Array[String]):
	for index in array:
		if string.contains(index):
			return true

	return false


static func remove_comments(line_string: String) -> String:
	return line_string.get_slice("//", 0).strip_edges()
