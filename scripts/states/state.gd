extends Node
class_name State

signal change


func enter(entity, args = null):
	pass


func exit(entity):
	pass


func modify(entity, args):
	pass


func update(entity, _delta):
	# Client Tick, variable based on framerate
	if multiplayer.is_server():
		return


func update_tick_client(entity, delta):
	# Client tick, 60 Hz
	if multiplayer.is_server():
		return

	# Client only
	if entity.global_position.distance_to(entity.server_position) < 0.1:
		entity.global_position = entity.server_position
	else:
		var lrp = delta * 16
		entity.global_position = entity.global_position.lerp(entity.server_position, lrp)


func update_tick_server(entity, _delta):
	# Server Tick, 60 Hz
	if not multiplayer.is_server():
		return
