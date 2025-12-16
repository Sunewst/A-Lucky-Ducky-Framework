extends Panel

@onready var neopixel_count: Label = $DebugBar/NeopixelStrip/Count
@onready var selected_point: Label = $DebugBar/SelectedPoint/PointNumber


func _ready() -> void:
	SignalController.neopixel_count_updated.connect(updated_neopixel_count)
	SignalController.new_selected_point.connect(updated_selected_point)

func updated_neopixel_count(new_neopixel_count):
	neopixel_count.set_text(str(new_neopixel_count))


func updated_selected_point(new_point):
	selected_point.set_text(str(new_point))
