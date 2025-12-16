extends Node3D

@export var debug_leds: PackedColorArray

@onready var code_edit_node: CodeEdit
@onready var neopixel_script: GDScript = GDScript.new()
@onready var fastled_engine = find_child("FastLEDDisplay")
@onready var fastled_node_instance: Node


func _ready() -> void:
	if find_child("CodeEdit") != null:
		code_edit_node = find_child("CodeEdit") # Not a permenent solution but works for now

	get_tree().get_root().files_dropped.connect(_model_added)


func _compile_fastled() -> void:
	var _converted_code: String = FastLEDParser.parse_code(code_edit_node)

	neopixel_script.source_code = _converted_code
	_create_fastled_instance(neopixel_script)

	print('Running FastLED GDScript')


func _create_fastled_instance(script: GDScript):
	if fastled_node_instance == null:
		fastled_node_instance = Node.new()
	else:
		fastled_node_instance.free()
		fastled_node_instance = Node.new()

	add_child(fastled_node_instance)
	script.reload()

	fastled_node_instance.set_script(script)


func _model_added(model):
	var _model_path: String = model[0]
	var _gltf_document_load: GLTFDocument = GLTFDocument.new()
	var _gltf_state_load: GLTFState = GLTFState.new()
	var _error

	if _model_path.get_extension() == 'gltf': 
		_error = _gltf_document_load.append_from_file(model[0], _gltf_state_load)
	else:
		print('Incorrect file type')
		return

	if _error == OK:
		var _gltf_scene_root_node = _gltf_document_load.generate_scene(_gltf_state_load)
		var _gltf_mesh_nodes = _gltf_scene_root_node.find_children('', 'MeshInstance3D')

		for mesh: MeshInstance3D in _gltf_mesh_nodes:
			mesh.create_trimesh_collision()

		add_child(_gltf_scene_root_node)
		print('Model added')
	else:
		printerr('Failed to load model', _error)
