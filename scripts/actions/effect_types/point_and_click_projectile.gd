class_name PointAndClickProjectile
extends ActiveActionEffect

var projectile_config: Dictionary


func init_from_dict(_dict: Dictionary, _is_ability: bool = false) -> bool:
	if not super(_dict):
		print("Could not create PointAndClickProjectile base class.")
		return false

	if not _dict.has("projectile"):
		print("Missing projectile config in PointAndClickProjectile.")
		return false

	var raw_projectile_config = _dict["projectile"] as Dictionary
	if not raw_projectile_config:
		print("Could not create PointAndClickProjectile. Projectile config is invalid.")
		return false

	var new_projectile_config = {}
	new_projectile_config["model"] = str(raw_projectile_config["model"])
	new_projectile_config["speed"] = float(raw_projectile_config["speed"])
	new_projectile_config["model_scale"] = JsonHelper.get_vector3(
		raw_projectile_config, "model_scale", Vector3(1.0, 1.0, 1.0)
	)
	new_projectile_config["model_rotation"] = JsonHelper.get_vector3(
		raw_projectile_config, "model_rotation", Vector3(0.0, 0.0, 0.0)
	)
	new_projectile_config["spawn_offset"] = JsonHelper.get_vector3(
		raw_projectile_config, "spawn_offset", Vector3(0.0, 0.0, 0.0)
	)
	new_projectile_config["damage_type"] = JsonHelper.get_optional_enum(
		raw_projectile_config, "damage_type", Unit.PARSE_DAMAGE_TYPE, Unit.DamageType.PHYSICAL
	)

	projectile_config = new_projectile_config

	return true


func get_copy(new_effect: ActionEffect = null) -> ActionEffect:
	if new_effect == null:
		new_effect = PointAndClickProjectile.new()

	new_effect = super(new_effect)

	new_effect.projectile_config = JsonHelper.dict_deep_copy(projectile_config)

	return new_effect


# TODO: Implement range visualization


func start_preview_cast(_caster: Unit) -> void:
	print("Not implemented. Needs to be implemented in the subclass.")


func stop_preview_cast(_caster: Unit) -> void:
	print("Not implemented. Needs to be implemented in the subclass.")


func _start_channeling(caster: Unit, target) -> bool:
	_activation_state = ActivationState.READY

	var target_unit = target as Unit
	if not target_unit:
		print("Could not start channeling effect. Target is not a unit.")
		return false

	if not caster:
		print("Could not start channeling effect. Caster is null.")
		return false

	if caster.team == target_unit.team or target_unit.team == 0:
		print("Could not start channeling effect. Caster and target are in the same team.")
		return false

	if use_attack_range:
		casting_range = caster.current_stats.attack_range

	if caster.server_position.distance_to(target_unit.server_position) > casting_range * 0.01:
		print("Could not start channeling effect. Target is out of range.")
		return false

	return super(caster, target)


func _finish_channeling(caster: Unit, target) -> void:
	var target_unit = target as Unit
	if not target_unit:
		print("Could not start active effect. Target is not a unit.")
		return

	if not caster:
		print("Could not start active effect. Caster is null.")
		return

	if caster.team == target_unit.team:
		print("Could not start active effect. Caster and target are in the same team.")
		return

	if target_unit.team == 0:
		print("Could not start active effect. Target is neutral.")
		return

	projectile_config["target_entity"] = target_unit
	caster.projectile_spawner.spawn(projectile_config)

	super(caster, target)
