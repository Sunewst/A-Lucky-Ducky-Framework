class_name Duck extends Node3D

const DUCK_SCENE: PackedScene = preload("res://scenes/garden_scenes/duck.tscn")

@export var material: Material
@export var current_board: board_resource

#@onready var stemma_port: MeshInstance3D = board_model_scene.find_child("stemma0")

@onready var dynamic_parts: Resource = preload("res://resources/boards/ESP32-C6_Feather.tres")
@onready var code_edtior: = $CodeEditor
@onready var code_edit_node: CodeEdit = find_child("CodeEdit")

var part_hovered: bool

var popup: PopupHover

var board_model_scene: Node
var board_collision_shapes


func _ready() -> void:
	add_board(current_board)

	popup = PopupHover.create_new_popup()
	popup.visible = false
	add_child(popup)

	#code_editor_node.symbol_hovered.connect(_on_symbol_hovered)
	#code_editor_node.focus_entered.connect(_on_text_hovered)
	#code_edtior.finished_editing.connect(_text_changed)
	SignalController.finished_typing.connect(_text_changed)
	SerialController.SerialDataReceived.connect(_on_serial_data_received)
	


func add_board(board: board_resource):
	board_model_scene = load(board.board_model).instantiate()
	
	board_collision_shapes = board_model_scene.find_children("StaticBody3D")
	add_child(board_model_scene)

	for collision_shape in board_collision_shapes:
		collision_shape.mouse_entered.connect(_on_static_body_3d_mouse_entered.bind(collision_shape.get_parent()))
		collision_shape.mouse_exited.connect(_on_static_body_3d_mouse_exited.bind(collision_shape.get_parent()))


#func _on_symbol_hovered(symbol: String, line: int, collumn: int):
	#match symbol:
		#"stemma0":
			#part_hovered = true
			#stemma_port.material_overlay = material


func _on_serial_data_received(data: String) -> void:
	if data.contains("$p"):
		var _data_value = data.get_slice("$", 2)
		popup.find_child("Label").text = _data_value


#func _on_text_hovered():
	#if part_hovered:
		#stemma_port.material_overlay = null
		#part_hovered = false


func _text_changed():
	pass


func _on_static_body_3d_mouse_entered(mesh: MeshInstance3D) -> void:
	popup.visible = true
	mesh.material_overlay = material
	popup.get_child(0).set_position(get_viewport().get_mouse_position())


func _on_static_body_3d_mouse_exited(mesh: MeshInstance3D) -> void:
	mesh.material_overlay = null
	popup.visible = false


func _on_code_editor_board_changed(board: board_resource) -> void:
	for collision_shape in board_collision_shapes:
		collision_shape.mouse_entered.disconnect(_on_static_body_3d_mouse_entered.bind(collision_shape.get_parent()))
		collision_shape.mouse_exited.disconnect(_on_static_body_3d_mouse_exited.bind(collision_shape.get_parent()))
	
	remove_child(board_model_scene)
	add_board(board)


static func create_new_duck(_board_name: String):
	var new_duck_scene: Duck = DUCK_SCENE.instantiate()
	return new_duck_scene
