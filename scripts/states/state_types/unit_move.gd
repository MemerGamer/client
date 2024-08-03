extends State
class_name unit_move


func enter(entity: Unit, args = null):
	modify(entity, args)


func update_tick_server(entity: Unit, delta):
	# Server Only
	super(entity, delta)

	if entity.move_on_path(delta):
		entity.advance_state()


func modify(entity: Unit, args):
	var target_pos = args as Vector3
	if not target_pos:
		print("No target position provided or not a Vector3")
		entity.advance_state()
		return

	# Update Target Position
	entity.nav_agent.target_position = target_pos
