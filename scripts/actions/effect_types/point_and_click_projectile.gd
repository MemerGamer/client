class_name PointAndClickProjectile
extends ActiveActionEffect

var casting_range: float = 0.0
var projectile_config: Dictionary


func init_from_dict(_dict: Dictionary, _is_ability: bool = false) -> bool:
	if not super(_dict):
		print("Could not create PointAndClickProjectile base class.")
		return false

	if not _dict.has("projectile"):
		print("Missing projectile config in PointAndClickProjectile.")
		return false

	projectile_config = _dict["projectile"] as Dictionary
	if not projectile_config:
		print("Could not create PointAndClickProjectile. Projectile config is invalid.")
		return false

	casting_range = JsonHelper.get_optional_number(_dict, "casting_range", 0.0)

	return true


# TODO: Implement range visualization


func start_preview_cast(_caster: Unit) -> void:
	print("Not implemented. Needs to be implemented in the subclass.")


func stop_preview_cast(_caster: Unit) -> void:
	print("Not implemented. Needs to be implemented in the subclass.")


func _start_channeling(caster: Unit, target) -> void:
	_activation_state = ActivationState.READY

	var target_unit = target as Unit
	if not target_unit:
		print("Could not start channeling effect. Target is not a unit.")
		return

	if not caster:
		print("Could not start channeling effect. Caster is null.")
		return

	if caster.team == target_unit.team:
		print("Could not start channeling effect. Caster and target are in the same team.")
		return

	if target_unit.team == 0:
		print("Could not start channeling effect. Target is neutral.")
		return

	if caster.server_position.distance_to(target_unit.server_position) > casting_range:
		print("Could not start channeling effect. Target is out of range.")
		return

	super(caster, target)


func _start_active(caster: Unit, target) -> void:
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
