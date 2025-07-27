extends Node3D

var _cam
var _rightVec: Vector3
var _forwardVec: Vector3

@export var rotation_speed: float = 2.0
@export var movement_speed: float = 6.0
@export var current_rotation: float = 0
@export var camera_rotation_speed: float = 0.5
@export var camera_rotation_amount: float = 1

var camera_animation_running: bool = true





# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_cam = %Camera3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("Left"):
		#rotation.y += rotation_speed * delta
		position.x -= movement_speed * delta
	if Input.is_action_pressed("Right"):
		#rotation.y -= rotation_speed * delta
		position.x += movement_speed * delta

		
	if Input.is_action_pressed("Up"):
		#rotation.x += rotation_speed * delta
		position.y += movement_speed * delta
		print(global_position)
		

	if Input.is_action_pressed("Down"):
		#rotation.x -= rotation_speed * delta
		position.y -= movement_speed * delta

	if Input.is_action_just_pressed("Arrow_right"):
		_rotate_camera(camera_rotation_amount)


	if Input.is_action_just_pressed("Arrow_left"):
		_rotate_camera(-camera_rotation_amount)

func _rotate_camera(direction: float):
	camera_animation_running = false
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	current_rotation += direction
	tween.tween_property(self, "rotation:y", current_rotation, camera_rotation_speed)
	
	#camera_animation_running = tween.is_running()
	
	
func _getMoveVectors():
	var offset: Vector3 = _cam.global_position - global_position
	_rightVec = _cam.transform
