@tool
extends EditorPlugin

const slider_script = preload("res://addons/sliderlabel/sliderlabel.gd")
const slider_texture = preload("res://addons/sliderlabel/sliderlabel.svg")

func _enter_tree() -> void:
	add_custom_type("SliderLabel", "Label", slider_script, slider_texture)

func _exit_tree() -> void:
	remove_custom_type("SliderLabel")
