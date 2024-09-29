class_name UnitAbilityCast
extends State

var target
var ability: Ability


func enter(entity: Unit, args = null):
	if not args:
		print("Ability args are missing")
		entity.advance_state()
		return

	var arg_list := args as Array
	if not arg_list:
		print("Ability args are not an array")
		entity.advance_state()
		return

	var ability_name := arg_list[0] as String
	var target = arg_list[1]

	ability = entity.abilities.get(ability_name) as Ability
	if not ability:
		print("Invalid ability name")
		entity.advance_state()
		return

	modify(entity, target)


func modify(entity: Unit, args):
	match ability.get_ability_type():
		ActionEffect.AbilityType.PASSIVE:
			print("Cannot cast passive ability: " + ability.name)
			entity.advance_state()
			return

		ActionEffect.AbilityType.AUTO_TARGETED:
			target = null

		ActionEffect.AbilityType.FIXED_TARGETED:
			if not args:
				print("No target entity provided")
				entity.advance_state()
				return

			var other_unit := args as Unit
			if not other_unit:
				print("No target doesn't seem to be a unit")
				entity.advance_state()
				return

			if not other_unit.is_alive:
				print("Target is dead, going back to idle state")
				entity.advance_state()
				return

			target = other_unit

		ActionEffect.AbilityType.DIRECTION_TARGETED:
			if not args:
				print("No target direction provided")
				entity.advance_state()
				return

			var target_direction := args as Vector3
			if not target_direction:
				print("Target direction is invalid")
				entity.advance_state()
				return

			target = target_direction

	ability.try_activate(target)


func exit(_entity: Unit):
	pass


func update_tick_server(entity: Unit, _delta):
	var current_state := ability.try_activate(target) as ActionEffect.ActivationState

	if (
		current_state == ActionEffect.ActivationState.NONE
		or current_state == ActionEffect.ActivationState.COOLDOWN
	):
		entity.advance_state()
		return
