extends Node3D

@export var debug_leds: PackedColorArray

@onready var code_edit_node: CodeEdit
@onready var fastled_engine = %FastLEDEngine


func _ready() -> void:
	if not find_child("CodeEdit") == null:
		code_edit_node = find_child("CodeEdit") # Not a permenent solution but works for now
		
	

func _compile_fastled() -> void:
	#print(FastLEDParser.parse_code(code_edit_node))
	fastled_engine.addLeds(debug_leds)
	fastled_engine.show()
