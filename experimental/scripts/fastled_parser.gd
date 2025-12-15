class_name FastLEDParser


static var arduino_functions: Dictionary = {
	'delay': 'await get_tree().create_timer(%s).timeout',
	'Serial.println': 'print(%s)',
	'FastLED.addLeds': 'FastLED.addLeds(%s)',
}


static func parse_code(editor: CodeEdit) -> String:
	var code_editor_node: CodeEdit = CodeEdit.new()
	var editor_components_dic = get_code_components(editor)
	var setup_location = editor_components_dic.find_key('setup')

	editor_components_dic.sort()

	for i in editor.get_line_count():
		code_editor_node.insert_line_at(i, " ")

	for editor_component_location in editor_components_dic:
		var component: String = editor_components_dic[editor_component_location].get_slice(" ", 0)
		var component_location: int = editor_component_location
		var converted_component: String
	
		match component:
			'function_initilzations':
				converted_component = _convert_function(editor, component_location)
			
			'variable_initilzations':
				converted_component = _convert_variable(editor, component_location)

			'variable_operations':
				converted_component = _convert_operator(editor, component_location)

			'control_statements':
				converted_component = _convert_control_statements(editor, component_location)

			'function_calls':
				converted_component = _convert_function_calls(editor, component_location)

			'loop':
				converted_component = 'func _process(delta: float) -> void:'
				
			'setup':
				converted_component = 'func _init() -> void:'
		
		code_editor_node.insert_line_at(component_location, converted_component)

	code_editor_node.insert_line_at(setup_location + 1, '  FastLED = get_parent().find_child("FastLEDDisplay")')

	code_editor_node.set_line(0, "extends FastLEDMethods")
	code_editor_node.insert_line_at(1, 'var FastLED')

	code_editor_node.queue_free()

	return code_editor_node.get_text()


static func _add_indents(editor: CodeEdit, line: int, text: String) -> String:
	var indented_line: String = text
	var indent_level: int = editor.get_indent_level(line)

	if indent_level > 0:
		for i in indent_level:
			indented_line = indented_line.indent(" ")

	return indented_line


static func _convert_function(editor: CodeEdit, function_location: int) -> String:
	var converted_function: String

	var current_line: String = EditorHelper.remove_comments(editor.get_line(function_location))
	var _return_type: String = current_line.get_slice(" ", 0)
	var function_name: String = current_line.get_slice(" ", 1).get_slice("(", 0)
	var function_parameters: String = current_line.get_slice("(", 1).get_slice(")", 0)
	
	for function_parameter in function_parameters.split(","):
		var variable_type = function_parameter.get_slice(" ", function_parameter.get_slice_count(" ") - 2)
		function_parameters = function_parameters.replace(variable_type, "")


	converted_function = "func %s (%s):" % [function_name, function_parameters]
	converted_function = _add_indents(editor, function_location, converted_function)

	return converted_function


static func _convert_variable(editor: CodeEdit, data_type_location: int) -> String:
	var converted_variable: String

	var current_line: String = EditorHelper.remove_comments(editor.get_line(data_type_location))
	var variable_name: String = current_line.get_slice(" ", 1).get_slice("=", 0)
	var variable_value: String = current_line.get_slice("=", 1).remove_chars(";")

	if variable_value.is_empty():
		converted_variable = "var %s;" % [variable_name]
	else:
		converted_variable = "var %s =%s" % [variable_name, variable_value]
	
	converted_variable = _add_indents(editor, data_type_location, converted_variable)

	return converted_variable


static func _convert_operator(editor: CodeEdit, operator_location: int) -> String:
	var converted_operator: String

	var current_line: String = EditorHelper.remove_comments(editor.get_line(operator_location))

	current_line = current_line.remove_chars(";")

	converted_operator = current_line
	converted_operator = _add_indents(editor, operator_location, converted_operator)

	return converted_operator


static func _convert_control_statements(editor: CodeEdit, control_location: int) -> String:
	var converted_control_statement: String

	var current_line: String = EditorHelper.remove_comments(editor.get_line(control_location))
	var line_control_statement: String = current_line.get_slice("(", 0).strip_edges()
	var control_parameters: String

	match line_control_statement:
		"if":
			control_parameters = current_line.get_slice("(", 1).get_slice(")", 0)
			converted_control_statement = "if %s:" % [control_parameters]

		"for":
			pass

		"while":
			control_parameters = current_line.get_slice("(", 1).get_slice(")", 0)
			converted_control_statement = "while %s:" % [control_parameters]

		"else":
			if current_line.contains("if"):
				control_parameters = current_line.get_slice("(", 1).get_slice(")", 0)
				converted_control_statement = "elif %s:" % [control_parameters]
			else:
				converted_control_statement = "else:"

	converted_control_statement = _add_indents(editor, control_location, converted_control_statement)
	
	return converted_control_statement


static func _convert_function_calls(editor: CodeEdit, function_call_location: int) -> String:
	var converted_function_call: String = EditorHelper.remove_comments(editor.get_line(function_call_location))

	var function_name: String = converted_function_call.get_slice('(', 0).strip_edges()
	var function_params: String = converted_function_call.get_slice('(', 1).get_slice(')', 0)

	if function_name.contains('<'):
		function_name = function_name.get_slice('<', 0)

	if function_name in arduino_functions:
		converted_function_call = arduino_functions[function_name] % [function_params]
	else:
		converted_function_call = converted_function_call.remove_chars(";")

	converted_function_call = _add_indents(editor, function_call_location, converted_function_call)

	return converted_function_call


static func get_code_components(editor: CodeEdit):
	var led_dictionary: Dictionary = {}

	led_dictionary[EditorHelper.get_loop_location(editor).y] = 'loop'
	led_dictionary[EditorHelper.get_setup_location(editor).y] = 'setup'
	led_dictionary[0] = "fastled#"

	for i in editor.get_line_count():
		var current_line: String = editor.get_line(i).remove_chars("}").strip_edges()
		var loop_location: int = EditorHelper.get_loop_location(editor).y
		var setup_location: int = EditorHelper.get_setup_location(editor).y
		
		if i == loop_location or i == setup_location or current_line.is_empty():
			pass

		elif EditorHelper.contains_array(current_line, EditorHelper.DATA_TYPES):
			if current_line.contains("(") and not current_line.contains("="):
				led_dictionary[i] = "function_initilzations %s" % [i]
			else:
				led_dictionary[i] = "variable_initilzations %s" % [i]

		elif EditorHelper.contains_array(current_line, EditorHelper.CONTROL_STRUCTUERS):
			led_dictionary[i] = "control_statements %s" % [i]
		elif current_line.contains("="):
			led_dictionary[i] = "variable_operations %s" % [i]
		else:
			led_dictionary[i] = "function_calls %s" % [i]
	
	return led_dictionary
