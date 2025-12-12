class_name FastLED extends Node

@onready var pond_node: Node3D = get_parent()

var leds_array: Array[PackedColorArray]

var fastled_engine: Node3D
var muiltimesh: MultiMesh


func _ready() -> void:
	if not pond_node.find_child("NeopixelGenerator") == null:
		print("Found node!")
		fastled_engine = pond_node.find_child("NeopixelGenerator")
		muiltimesh = fastled_engine.find_child("Neopixel").multimesh


func show():
	muiltimesh.set_instance_custom_data(10, Color(0.0, 0.612, 0.769, 1.0))


func addLeds(targetArray: PackedColorArray):
	leds_array.append(targetArray)


func _print_leds():
	print(leds_array)
