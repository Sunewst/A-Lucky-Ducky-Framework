# For now, the neopixel genarator is a tool, meaning in only runs in the engine editor.
# Due to that, the code is really ugly until its converted to a normal script


@tool
extends Path3D

var path_changed: bool

@export var distance_between = 1.0:
	set(value):
		distance_between = value
		path_changed = true


func _process(_delta: float) -> void:
	if path_changed:
		_update_muiltimesh()
		path_changed = false


func _update_muiltimesh():
	var path_length: float = curve.get_baked_length()
	var count = floor(path_length / distance_between)
	var mm: MultiMesh
	var neopixel: MultiMesh

	$Neopixel.material_override = $MeshInstance3D.get_active_material(0)

	mm = $Strip.multimesh
	neopixel = $Neopixel.multimesh

	mm.instance_count = count
	neopixel.instance_count = count

	var offset = distance_between / 2.0
	neopixel.set_instance_custom_data(10, Color(0.0, 0.612, 0.769, 1.0))
	
	for i in range(0, count):
		var curve_distance = offset + distance_between * i
		var object_position = curve.sample_baked(curve_distance, true)
		var neopixel_position = curve.sample_baked(curve_distance, true)
		
		var object_basis = Basis()
		var neopixel_basis = Basis()
		

		var up = curve.sample_baked_up_vector(curve_distance, true)
		var forward = object_position.direction_to(curve.sample_baked(curve_distance + 0.1, true))

		object_basis.y = up
		object_basis.x = forward.cross(up).normalized()
		object_basis.z = -forward
		
		neopixel_basis.y = up
		neopixel_basis.x = forward.cross(up).normalized()
		neopixel_basis.z = -forward
	
		var object_transform = Transform3D(object_basis, object_position)
		var neopixel_transform = Transform3D(neopixel_basis, neopixel_position)

		mm.set_instance_transform(i, object_transform)
		neopixel.set_instance_transform(i, neopixel_transform)


func _on_curve_changed() -> void:
	path_changed = true
