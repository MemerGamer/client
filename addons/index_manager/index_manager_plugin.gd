@tool
extends EditorPlugin

var dock_scene = preload("res://addons/index_manager/index_manager_dock.tscn")
var dock


func _enter_tree():
	# Initialization of the plugin goes here.
	# Load the dock scene and instantiate it.
	dock = dock_scene.instantiate()
	add_control_to_bottom_panel(dock, "IndexManagerDock").show()


func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_control_from_bottom_panel(dock)
	# Erase the control from the memory.
	dock.free()
