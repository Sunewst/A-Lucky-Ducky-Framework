class_name FastLED extends Node

static var leds_array: Array[PackedColorArray]


static func addLeds(targetArray: PackedColorArray):
	leds_array.append(targetArray)


static func _print_leds():
	print(leds_array)
