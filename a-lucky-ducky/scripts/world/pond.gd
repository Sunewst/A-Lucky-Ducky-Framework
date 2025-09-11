extends Node3D

@export var material: Material
@onready var stemma_port: MeshInstance3D = find_child("stemma0")
@onready var code_editor: CodeEdit = find_child("CodeEdit")

var part_hovered: bool

func _ready() -> void:
	code_editor.symbol_hovered.connect(_on_symbol_hovered)
	code_editor.focus_entered.connect(_on_text_hovered)
	#code_editor.mouse


func _on_symbol_hovered(symbol: String, line: int, collumn: int):
	match symbol:
		"stemma0":
			part_hovered = true
			print("Hovered!")
			stemma_port.material_overlay = material
			#code_editor.release_focus()
			#print(code_editor.has_focus())
			

func _on_text_hovered():
	print("Text Hovered")
	if part_hovered:
		stemma_port.material_overlay = null
		part_hovered = false
		
func _text_hovered():
	print("Hovered")
	
