extends Node3D


func _ready() -> void:
	ArduinoCli.execute_arduino_app_cli(['hello'])
