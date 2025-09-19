extends MeshInstance3D
var cubeMaterial


func _on_simple_serial_controller_serial_data_received(data: String) -> void:
	get_surface_override_material(0).albedo_color = Color(0, 1, 1)



func _on_simple_serial_controller_serial_error(error: String) -> void:
	get_surface_override_material(0).albedo_color = Color(1, 0, 0)
	print(error)
