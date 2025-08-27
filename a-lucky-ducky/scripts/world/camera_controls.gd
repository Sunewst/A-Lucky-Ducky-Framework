extends Node3D

var _cam
var _rightVec: Vector3
var _forwardVec: Vector3

@export_range (2.0, 20, 1) var rotation_speed: float = 2.0
@export_range (1.0, 30, 2) var movement_speed: float = 6.0
@export var current_rotation: float = 0
@export var camera_rotation_speed: float = 0.5
@export var camera_rotation_amount: float = 1

@export var snap := true
@onready var _prev_rotation := global_rotation
@onready var _snap_space := global_transform

var camera_animation_running: bool = true
var _in_focus: bool = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	_cam = %Camera3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.is_action_pressed("left") and _in_focus == true:
		#rotation.y += rotation_speed * delta
		_cam.position.x -= movement_speed * delta
	if Input.is_action_pressed("right") and _in_focus == true:
		#rotation.y -= rotation_speed * delta
		_cam.position.x += movement_speed * delta

		
	if Input.is_action_pressed("up") and _in_focus == true:
		#rotation.x += rotation_speed * delta
		_cam.position.y += movement_speed * delta
		

	if Input.is_action_pressed("down") and _in_focus == true:
		#rotation.x -= rotation_speed * delta
		_cam.position.y -= movement_speed * delta

	if Input.is_action_just_pressed("arrow_right") and _in_focus:
		_rotate_camera(camera_rotation_amount)


	if Input.is_action_just_pressed("arrow_left") and _in_focus:
		_rotate_camera(-camera_rotation_amount)
		
	if Input.is_action_just_pressed("scroll_up") and _in_focus:
		_cam.size -= 1
		
	if Input.is_action_just_pressed("scroll_down") and _in_focus:
		_cam.size += 1
	

func _rotate_camera(direction: float):
	camera_animation_running = false
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	current_rotation += direction
	tween.tween_property(self, "rotation:y", current_rotation, camera_rotation_speed)
	
	#camera_animation_running = tween.is_running()
	


func _on_code_edit_focus_entered() -> void:
	if _in_focus == true:
		_in_focus = false
		


func _on_code_edit_focus_exited() -> void:
	if _in_focus == false:
		_in_focus= true


func _on_code_editor_currently_typing(status: bool) -> void:
	if status:
		_in_focus = false
	else:
		_in_focus = true
	
