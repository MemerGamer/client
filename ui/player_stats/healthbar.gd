extends ProgressBar

var camera: Camera3D


func _ready():
	camera = get_viewport().get_camera_3d()
	show_percentage = false
	hide()


func _process(_delta):
	var parent: CharacterBody3D = get_parent()
	if value > 0 && parent.is_visible_in_tree():
		# TODO: only show health of the lowest tier structure within a given lane
		show()

		if camera:
			var screen_pos = camera.unproject_position(parent.position)
			var bar_pos = Vector2(screen_pos.x - 0.5 * size.x, screen_pos.y - 50)
			# Adjust the offset (e.g., -50) to position the health bar above the player
			# You might need to tweak this value based on your game's camera settings
			set_position(bar_pos)
	else:
		hide()


func update_healthbar(unit: Unit):
	value = unit.current_stats.health
	max_value = unit.maximum_stats.health
