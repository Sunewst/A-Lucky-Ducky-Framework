extends Node3D

signal show_editor
signal hide_editor

@export_range(1, 20, 1) var total_boards: int = 4
@export var current_board: board_resource
@export var divider_amount: int = 5

#@onready var code_editor: CodeEditor = $CodeEditor
@onready var properties_window: BoardProperties = BoardProperties.display_new_properties_window()

var board_model_scene: Node
var boards: Array[Node3D]
var board_collision_shapes: Array[Node]

var currently_hovering: bool
var focused_mesh: String


func _ready() -> void:
	var x_muiltiplier: int = 0

	properties_window.hide()
	add_child(properties_window)

	for i in total_boards:
		var board: Node = load(current_board.board_model).instantiate()
		board.name = "Board" + str(i)
		boards.append(board)

	for board in boards:
		board.call_deferred("set_global_position", Vector3(0 + x_muiltiplier, 0, 0))
		x_muiltiplier += divider_amount
		
		board_collision_shapes = board.find_children("StaticBody3D")

		for collision_shape in board_collision_shapes:
			collision_shape.mouse_entered.connect(_on_static_body_3d_mouse_entered.bind(collision_shape.get_parent()))
			collision_shape.mouse_exited.connect(_on_static_body_3d_mouse_exited.bind(collision_shape.get_parent()))

		add_child(board)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click") and currently_hovering:
		SignalController.show_editor.emit(focused_mesh)

	if event.is_action_pressed("close_code_editor"):
		SignalController.hide_editor.emit(focused_mesh)

	if event.is_action_pressed("open_board_properties") and currently_hovering:
		print("Showing properties of board: ", focused_mesh)
		properties_window.show()
		


func _on_static_body_3d_mouse_entered(mesh: MeshInstance3D) -> void:
	currently_hovering = true
	focused_mesh = mesh.owner.name
	print("Hovering over: ", mesh.owner.name)


func _on_static_body_3d_mouse_exited(mesh: MeshInstance3D) -> void:
	currently_hovering = false
	print("No longer hovering over: ", mesh.owner.name)


func add_new_board():
	print("Adding new board!")


func save():
	var save_dict = {
		"filename" : get_scene_file_path(),
		"total_boards": total_boards,
	}

	return save_dict


func _exit_tree() -> void:
	SaveHandler.save_pond()
