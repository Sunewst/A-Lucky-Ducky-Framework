# For now, the neopixel genarator is a tool, meaning in only runs in the engine editor.
# Due to that, the code is really ugly until its converted to a normal script
@tool

extends Node3D

@export var distance_between = 0.11:
	set(value):
		distance_between = value
		path_changed = true


@export var path: Path3D

var path_changed: bool
var selected_curve_point: int = 0


func _ready() -> void:
	path.curve_changed.connect(_on_curve_changed)


func _process(_delta: float) -> void:
	if path_changed:
		_update_muiltimesh()
		path_changed = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.as_text().contains('Ctrl+'):
		var new_point = event.as_text().to_int()
		selected_curve_point = new_point - 1
		SignalController.new_selected_point.emit(new_point)


func _update_muiltimesh():
	var path_length: float = path.curve.get_baked_length()
	var count = floor(path_length / distance_between)
	var mm: MultiMesh
	var neopixel: MultiMesh

	$Neopixel.material_override = $MeshInstance3D.get_active_material(0)
	
	mm = $Strip.multimesh
	neopixel = $Neopixel.multimesh

	mm.instance_count = count
	neopixel.instance_count = count
	#SignalController.neopixel_count_updated.emit(count)

	var offset = distance_between / 2.0
	
	for i in range(0, count):
		var curve_distance = offset + distance_between * i
		var object_position = path.curve.sample_baked(curve_distance, true)
		var neopixel_position = path.curve.sample_baked(curve_distance, true)
		
		var object_basis = Basis()
		var neopixel_basis = Basis()
		

		var up = path.curve.sample_baked_up_vector(curve_distance, true)
		var forward = object_position.direction_to(path.curve.sample_baked(curve_distance + 0.1, true))

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


func _model_clicked(location: Vector3) -> void:
	var current_curve: Curve3D = path.get_curve()
	current_curve.set_point_position(selected_curve_point, location)
