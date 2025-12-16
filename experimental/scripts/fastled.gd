class_name FastLEDController extends Node

@onready var pond_node: Node3D = owner

var leds_array: Array[PackedColorArray]

var fastled_engine: Node3D
var neopixel_muiltimesh: MultiMesh


func _ready() -> void:
	if pond_node.find_child("NeopixelGenerator") != null:
		fastled_engine = pond_node.find_child("NeopixelGenerator")
		neopixel_muiltimesh = fastled_engine.find_child("Neopixel").multimesh


func show():
	for neopixel in leds_array[0].size():
		neopixel_muiltimesh.set_instance_custom_data(neopixel, leds_array[0][neopixel])


func addLeds(targetArray: PackedColorArray, totalLeds: int):
	leds_array.clear() # In the future when more than one strip can be added, this should be removed
	targetArray.resize(totalLeds)

	leds_array.append(targetArray)


func _print_leds():
	print(leds_array)
