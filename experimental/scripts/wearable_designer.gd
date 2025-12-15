extends Node3D

@export var debug_leds: PackedColorArray

@onready var code_edit_node: CodeEdit
@onready var neopixel_script: GDScript = GDScript.new()
@onready var fastled_engine = %Neopixels.find_child("FastLEDDisplay")


func _ready() -> void:
	get_tree().get_root().files_dropped.connect(_model_added)

	if not find_child("CodeEdit") == null:
		code_edit_node = find_child("CodeEdit") # Not a permenent solution but works for now

	debug_leds.resize(10)
	fastled_engine.addLeds(debug_leds)


func _compile_fastled() -> void:
	var converted_code: String = FastLEDParser.parse_code(code_edit_node)

	neopixel_script.source_code = converted_code
	neopixel_script.reload()
	$FastLEDInstance.set_script(neopixel_script)

	print($FastLEDInstance.get_script().source_code)
	print('Running FastLED GDScript')


func _model_added(model):
	var model_path: String = model[0]
	var gltf_document_load: GLTFDocument = GLTFDocument.new()
	var gltf_state_load: GLTFState = GLTFState.new()
	var error

	if model_path.get_extension() == 'gltf': 
		error = gltf_document_load.append_from_file(model[0], gltf_state_load)
	else:
		print('Incorrect file type')
		return

	if error == OK:
		var gltf_scene_root_node = gltf_document_load.generate_scene(gltf_state_load)
		var gltf_mesh_nodes = gltf_scene_root_node.find_children('', 'MeshInstance3D')

		for mesh: MeshInstance3D in gltf_mesh_nodes:
			mesh.create_trimesh_collision()

		add_child(gltf_scene_root_node)
		print('Model added')
	else:
		printerr('Failed to load model', error)
