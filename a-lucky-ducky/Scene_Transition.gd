extends Control

signal on_transition_finished

@onready var rect = $PixelTransition
@onready var animation_player = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)


func _on_animation_finished(anim_name):
	if anim_name == "fade_out":
		on_transition_finished.emit()
		animation_player.play("fade_in")
		
	elif anim_name:
		rect.visible = false

func transition():
	rect.visible = true
	animation_player.play("fade_out")
