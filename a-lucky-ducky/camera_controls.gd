extends Node3D

@export var rotation_speed: float = 2.0
@export var current_rotation: float = 0
@export var camera_speed: float = 0.3
@export var camera_rotation_amount: float = 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("Left"):
		rotation.y += rotation_speed * delta
		
	if Input.is_action_pressed("Right"):
		rotation.y -= rotation_speed * delta
		
	if Input.is_action_pressed("Zoom_out"):
		rotation.x += rotation_speed * delta
		
	if Input.is_action_pressed("Zoom_in"):
		rotation.x -= rotation_speed * delta
		
	if Input.is_action_just_pressed("Arrow_right"):
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
		current_rotation += camera_rotation_amount
		tween.tween_property(self, "rotation:y", current_rotation, camera_speed)
		
	if Input.is_action_just_pressed("Arrow_left"):
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
		current_rotation -= camera_rotation_amount
		tween.tween_property(self, "rotation:y", current_rotation, camera_speed)	

	
	
