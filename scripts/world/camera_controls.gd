extends Node3D

@export_range (2.0, 20, 1) var rotation_speed: float = 2.0
@export_range (1.0, 30, 2) var movement_speed: float = 6.0

@export var current_rotation: float = 0
@export var camera_rotation_speed: float = 0.5
@export var camera_rotation_amount: float = 1

@export var camera_max_zoom_in: int = 1
@export var camera_max_zoom_out: int = 50

@export var snap := true

@onready var cam = %Camera3D
@onready var params = PhysicsRayQueryParameters3D.new()

var camera_animation_running: bool = true
var in_focus: bool = true

var _mouse_location

func _ready() -> void:
	SignalController.editor_in_focus.connect(_on_code_editor_currently_typing)


func _process(delta: float) -> void:
	if Input.is_action_pressed("move_camera_left") and in_focus == true:
		#rotation.y += rotation_speed * delta
		cam.position.x -= movement_speed * delta

	if Input.is_action_pressed("move_camera_right") and in_focus == true:
		#rotation.y -= rotation_speed * delta
		cam.position.x += movement_speed * delta

	if Input.is_action_pressed("move_camera_up") and in_focus == true:
		#rotation.x += rotation_speed * delta
		cam.position.y += movement_speed * delta
		
	if Input.is_action_pressed("move_camera_down") and in_focus == true:
		#rotation.x -= rotation_speed * delta
		cam.position.y -= movement_speed * delta


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_camera_right") and in_focus:
		_rotate_camera(camera_rotation_amount)
	
	if event.is_action_pressed("rotate_camera_left") and in_focus:
		_rotate_camera(-camera_rotation_amount)

	if event.is_action_pressed("zoom_in") and in_focus:
		if not cam.size <= camera_max_zoom_in:
			cam.size -= 1

	if event.is_action_pressed("zoom_out") and in_focus:
		if not cam.size >= camera_max_zoom_out:
			cam.size += 1

	if event is InputEventMouseMotion:
		_mouse_location = event.position

	if event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_get_mouse_click_location(_mouse_location)


func _rotate_camera(direction: float):
	var tween: Tween
	camera_animation_running = false

	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	current_rotation += direction

	tween.tween_property(self, "rotation:y", current_rotation, camera_rotation_speed)
	
	#camera_animation_running = tween.is_running()


func _on_code_edit_focus_entered() -> void:
	if not in_focus:
		in_focus = true
		


func _on_code_edit_focus_exited() -> void:
	if in_focus:
		in_focus = false


func _on_code_editor_currently_typing(status: bool) -> void:
	if status:
		in_focus = false
	else:
		in_focus = true


func _get_mouse_click_location(mouse: Vector2):
	var _world_space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var _start: Vector3 = cam.project_ray_origin(mouse)
	var _end: Vector3 = cam.project_position(mouse, 100)
	var _mouse_data: Dictionary
	
	params.from = _start
	params.to = _end

	_mouse_data = _world_space.intersect_ray(params)

	if not _mouse_data.is_empty():
		SignalController.model_clicked.emit(_mouse_data['position'])
