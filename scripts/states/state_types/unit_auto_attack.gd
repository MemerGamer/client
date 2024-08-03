extends State
class_name unit_auto_attack

var windup_timer: Timer
var cooldown_timer: Timer
var target_unit: Unit


func enter(entity: Unit, _args = null):
	# Configure Timers
	windup_timer = entity.get_node("Abilities/AutoAttack/AAWindup")
	cooldown_timer = entity.get_node("Abilities/AutoAttack/AACooldown")

	# Subscribe to timer timeout
	windup_timer.timeout.connect(func(): do_attack(entity))

	modify(entity, _args)


func modify(entity: Unit, _args = null):
	if _args == null:
		print("No target entity provided")
		return

	var _unit = _args as Unit
	if not _unit:
		print("No target doesn't seem to be a unit")
		return

	target_unit = _unit

	if target_unit != entity.target_entity:
		entity.target_entity = target_unit

	if not target_unit.is_alive:
		print("Target is dead, going back to idle state")
		entity.advance_state()
		return


func exit(_entity: Unit):
	for conn in windup_timer.timeout.get_connections():
		windup_timer.timeout.disconnect(conn["callable"])


func update_tick_server(entity: Unit, delta):
	entity.nav_agent.target_position = entity.global_position

	if not entity.target_entity:
		entity.advance_state()
		return

	if not entity.target_entity.is_alive:
		entity.advance_state()
		return

	if (
		entity.target_entity.global_position.distance_to(entity.global_position)
		< (entity.current_stats.attack_range * 0.01)
	):
		start_windup(entity)
		return

	if not windup_timer.is_stopped():
		return

	entity.nav_agent.target_position = entity.target_entity.global_position
	entity.move_on_path(delta)


func start_windup(entity):
	if not entity.can_attack():
		return
	if not windup_timer.is_stopped():
		return
	if not cooldown_timer.is_stopped():
		return

	var attack_time = float(100.0 / entity.current_stats.attack_speed)
	windup_timer.wait_time = attack_time * entity.windup_fraction
	cooldown_timer.wait_time = attack_time * (1.0 - entity.windup_fraction)

	windup_timer.start()


func do_attack(entity):
	if not entity.can_attack():
		return

	entity.windup_finished.emit(entity, entity.target_entity)
	cooldown_timer.start()
