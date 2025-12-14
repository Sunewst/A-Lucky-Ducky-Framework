extends Node3D

@export var debug_leds: PackedColorArray

@onready var code_edit_node: CodeEdit
@onready var fastled_engine = %Neopixels.find_child("FastLEDDisplay")


func _ready() -> void:
	if not find_child("CodeEdit") == null:
		code_edit_node = find_child("CodeEdit") # Not a permenent solution but works for now

	debug_leds.resize(10)
	fastled_engine.addLeds(debug_leds)


func _compile_fastled() -> void:
	var converted_code = FastLEDParser.parse_code(code_edit_node)

	converted_code.reload()
	$FastLEDInstance.set_script(converted_code)
	print($FastLEDInstance.get_script().source_code)
