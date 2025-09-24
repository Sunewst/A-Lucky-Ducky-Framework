class_name PopupHover extends Control

const POPUP_SCENE: PackedScene = preload("res://scenes/popup_hover.tscn")


static func create_new_popup():
	var new_popup: PopupHover = POPUP_SCENE.instantiate()
	return new_popup
