extends Node3D

@export var material: Material

@onready var stemma_port: MeshInstance3D = find_child("stemma0")
@onready var code_editor_node: CodeEdit = find_child("CodeEdit")
@onready var stemma_port_collision: StaticBody3D = stemma_port.get_child(0)


var part_hovered: bool

func _ready() -> void:
	code_editor_node.symbol_hovered.connect(_on_symbol_hovered)
	code_editor_node.focus_entered.connect(_on_text_hovered)


	stemma_port_collision.mouse_entered.connect(_on_static_body_3d_mouse_entered)
	stemma_port_collision.mouse_exited.connect(_on_static_body_3d_mouse_exited)


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
