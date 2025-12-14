extends Node3D

@export var debug_leds: PackedColorArray

@onready var code_edit_node: CodeEdit
@onready var fastled_engine = %Neopixels.find_child("FastLEDDisplay")


func _ready() -> void:
	get_tree().get_root().files_dropped.connect(_model_added)

	if not find_child("CodeEdit") == null:
		code_edit_node = find_child("CodeEdit") # Not a permenent solution but works for now

	debug_leds.resize(10)
	fastled_engine.addLeds(debug_leds)


func _compile_fastled() -> void:
	var converted_code = FastLEDParser.parse_code(code_edit_node)

	converted_code.reload()
	$FastLEDInstance.set_script(converted_code)
	print($FastLEDInstance.get_script().source_code)

	print('Running FastLED GDScript file')


func _model_added(model):
	var model_path: String = model[0]
	
	if not model_path.get_extension() == 'gltf': 
		print('Incorrect file type')
		return

	var gltf_document_load = GLTFDocument.new()
	var gltf_state_load = GLTFState.new()
	var error = gltf_document_load.append_from_file(model[0], gltf_state_load)

	if error == OK:
		var gltf_scene_root_node = gltf_document_load.generate_scene(gltf_state_load)
		add_child(gltf_scene_root_node)
		print('Model added')
	else:
		printerr('Failed to load model', error)
