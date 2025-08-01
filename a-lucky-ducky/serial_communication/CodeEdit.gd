extends CodeEdit
var _past_line: int

func _ready() -> void:
	set_line_background_color(10, Color(1,1,1))
	set_line_background_color(10, Color(0,0,0,0))	



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
