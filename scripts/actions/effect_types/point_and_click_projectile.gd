class_name PointAndClickProjectile
extends ActiveActionEffect

var speed: float = 20.0
var damage_type := Unit.DamageType.PHYSICAL

var model: String
var model_scale := Vector3.ONE
var model_rotation := Vector3.ZERO
var spawn_offset := Vector3.ZERO

var launch_sfx: String = ""


func init_from_dict(_dict: Dictionary, _is_ability: bool = false) -> bool:
	if not super(_dict, _is_ability):
		print("Could not create PointAndClickProjectile base class.")
		return false

	if not _dict.has("projectile"):
		print("Missing projectile config in PointAndClickProjectile.")
		return false

	var raw_projectile_config = _dict["projectile"] as Dictionary
	if not raw_projectile_config:
		print("Could not create PointAndClickProjectile. Projectile config is invalid.")
		return false

	model = str(raw_projectile_config["model"])
	speed = JsonHelper.get_optional_number(raw_projectile_config, "speed", 20.0)
	model_scale = JsonHelper.get_vector3(
		raw_projectile_config, "model_scale", Vector3(1.0, 1.0, 1.0)
	)
	model_rotation = JsonHelper.get_vector3(
		raw_projectile_config, "model_rotation", Vector3(0.0, 0.0, 0.0)
	)
	spawn_offset = JsonHelper.get_vector3(
		raw_projectile_config, "spawn_offset", Vector3(0.0, 0.0, 0.0)
	)
	damage_type = (
		JsonHelper.get_optional_enum(
			raw_projectile_config, "damage_type", Unit.PARSE_DAMAGE_TYPE, damage_type
		)
		as Unit.DamageType
	)
	launch_sfx = JsonHelper.get_optional_string(raw_projectile_config, "launch_sfx", "")

	return true


func get_copy(new_effect: ActionEffect = null) -> ActionEffect:
	if new_effect == null:
		new_effect = PointAndClickProjectile.new()

	new_effect = super(new_effect)

	new_effect.model = model
	new_effect.speed = speed
	new_effect.model_scale = model_scale
	new_effect.model_rotation = model_rotation
	new_effect.spawn_offset = spawn_offset
	new_effect.damage_type = damage_type
	new_effect.launch_sfx = launch_sfx

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


func _finish_channeling(caster_path: NodePath, target_path: NodePath) -> void:
	var target_unit := get_node(target_path) as Unit
	if not target_unit:
		_activation_state = ActivationState.READY
		print("Could not start active effect. Target is not a unit or not longer exists.")
		return

	var caster := get_node(caster_path) as Unit
	if not caster:
		print("Could not start active effect. Caster is null.")
		return

	if caster.team == target_unit.team or target_unit.team == 0:
		_activation_state = ActivationState.READY
		print(
			"Could not start active effect. Caster and target are in the same team or the team is neutral."
		)
		return

	var projectile_config: Dictionary = {}

	projectile_config["caster_entity_name"] = caster.get_path()
	projectile_config["target_entity_name"] = target_unit.get_path()

	projectile_config["speed"] = speed
	projectile_config["damage_type"] = damage_type
	projectile_config["damage"] = caster.current_stats.attack_damage
	projectile_config["source_type"] = _effect_source

	projectile_config["model"] = model
	projectile_config["model_scale"] = model_scale
	projectile_config["model_rotation"] = model_rotation
	projectile_config["spawn_offset"] = spawn_offset

	projectile_config["launch_sfx"] = launch_sfx

	caster.projectile_spawner.spawn(projectile_config)

	super(caster_path, target_path)
