class_name FastLEDMethods

# This implementation using GDScript but for the future, it should be in C#

static func fill_solid(targetArray: PackedColorArray, numToFill: int, color: Color):
	for i in numToFill:
		targetArray[i] = color
