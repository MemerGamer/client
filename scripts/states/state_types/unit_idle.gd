class_name UnitIdle
extends State


func update_tick_client(entity: Unit, delta):
	super(entity, delta)
	entity.global_position = entity.server_position
