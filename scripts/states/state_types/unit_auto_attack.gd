class_name UnitAutoAttack
extends State

var target_unit: Unit

var basic_attack_ability: Ability


func enter(entity: Unit, _args = null):
	basic_attack_ability = entity.get_node("Abilities/basic_attack")

	modify(entity, _args)


func modify(entity: Unit, _args = null):
	if _args == null:
		print("No target entity provided")
		return

	var other_unit = _args as Unit
	if not other_unit:
		print("No target doesn't seem to be a unit")
		return

	target_unit = other_unit

	if target_unit != entity.target_entity:
		entity.target_entity = target_unit

	if not target_unit.is_alive:
		print("Target is dead, going back to idle state")
		entity.advance_state()
		return

	basic_attack_ability.try_activate(target_unit)


func exit(_entity: Unit):
	pass


func update_tick_server(entity: Unit, delta):
	entity.nav_agent.target_position = entity.global_position

	if not target_unit:
		entity.advance_state()
		return

	if not target_unit.is_alive:
		entity.advance_state()
		return

	var should_move = (
		entity.global_position.distance_to(target_unit.global_position)
		> entity.current_stats.attack_range * 0.01
	)

	if not should_move:
		should_move = not basic_attack_ability.try_activate(target_unit)

	var current_state = basic_attack_ability._current_effect.get_activation_state()

	if should_move and current_state != ActionEffect.ActivationState.CHANNELING:
		entity.nav_agent.target_position = target_unit.global_position
		entity.move_on_path(delta)
