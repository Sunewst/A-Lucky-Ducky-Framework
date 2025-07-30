extends MeshInstance3D
var cubeMaterial

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_simple_serial_controller_serial_data_received(data: String) -> void:
	get_surface_override_material(0).albedo_color = Color(0, 1, 1)
	print("Data received")


func _on_simple_serial_controller_serial_error(error: String) -> void:
	get_surface_override_material(0).albedo_color = Color(1, 0, 0)
