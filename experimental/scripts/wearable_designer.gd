extends Node3D

@onready var code_edit_node: CodeEdit
@onready var fastled_node: Node = %FastledEngine

var leds: PackedColorArray = [Color(0,0,0)]

func _ready() -> void:
	if not find_child("CodeEdit") == null:
		code_edit_node = find_child("CodeEdit") # Not a permenent solution but works for now
		
	

func _compile_fastled() -> void:
	print(FastLEDParser.parse_code(code_edit_node))
