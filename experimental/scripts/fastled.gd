class_name FastLED extends Node

@onready var pond_node: Node3D = owner

var leds_array: Array[PackedColorArray]

var fastled_engine: Node3D
var neopixel_muiltimesh: MultiMesh


func _ready() -> void:
	if not pond_node.find_child("NeopixelGenerator") == null:
		fastled_engine = pond_node.find_child("NeopixelGenerator")
		neopixel_muiltimesh = fastled_engine.find_child("Neopixel").multimesh


func show():
	for neopixel in leds_array[0].size():
		neopixel_muiltimesh.set_instance_custom_data(neopixel, leds_array[0][neopixel])


func addLeds(targetArray: PackedColorArray):
	leds_array.append(targetArray)


func _print_leds():
	print(leds_array)
