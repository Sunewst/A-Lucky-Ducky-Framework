extends Node3D

@export var material: Material

@onready var board_model_scene: Node = preload("res://graphics/models/rp2040_trinkey/rp2040_trinkey.tscn").instantiate()

@onready var stemma_port: MeshInstance3D = board_model_scene.find_child("stemma0")

@onready var dynamic_parts: Resource = preload("res://resources/boards/rp2040_trinkey.tres")
@onready var board_collision_shapes = board_model_scene.find_children("StaticBody3D")

@onready var code_editor_node: CodeEdit = find_child("CodeEdit")

var part_hovered: bool


func _ready() -> void:
	add_child(board_model_scene)
	
	for collision_shape in board_collision_shapes:
		collision_shape.mouse_entered.connect(_on_static_body_3d_mouse_entered)
		collision_shape.mouse_exited.connect(_on_static_body_3d_mouse_exited)
	
	code_editor_node.symbol_hovered.connect(_on_symbol_hovered)
	code_editor_node.focus_entered.connect(_on_text_hovered)



func _on_symbol_hovered(symbol: String, line: int, collumn: int):
	match symbol:
		"stemma0":
			part_hovered = true
			stemma_port.material_overlay = material
			

func _on_text_hovered():
	if part_hovered:
		stemma_port.material_overlay = null
		part_hovered = false
		
func _focus_entered():
	print("Hovered")

func _on_static_body_3d_mouse_entered() -> void:
	stemma_port.material_overlay = material


func _on_static_body_3d_mouse_exited() -> void:
	stemma_port.material_overlay = null
	

func _on_code_editor_board_changed(new_board) -> void:
	pass
