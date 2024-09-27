class_name OnHitDamageEffect
extends ActionEffect

var damage: int = 0

## The scaling function for the damage.
## This function should take the caster and the target as arguments
## and return the damage value as an integer.
var scaling_calc = null
var scaling_display = null

var damage_type: Unit.DamageType = Unit.DamageType.PHYSICAL
var trigger_sources: Array = [
	Unit.SourceType.BASIC_ATTACK,
]

var can_crit: bool = false


func init_from_dict(_dict: Dictionary, _is_ability: bool = false) -> bool:
	if not super(_dict, _is_ability):
		print("Could not create OnHitDamageEffect base class.")
		return false

	if not _dict.has("damage") and not _dict.has("scaling"):
		print(
			"Could not create OnHitDamageEffect from dictionary. Dictionary is missing required keys."
		)
		return false

	damage = JsonHelper.get_optional_int(_dict, "damage", 0)

	if _dict.has("scaling"):
		var scaling_funcs = ScalingsBuilder.build_scaling_function(str(_dict["scaling"]))
		if scaling_funcs == null:
			print(
				"Could not create OnHitDamageEffect from dictionary. Could not build scaling function."
			)
			return false

		scaling_calc = scaling_funcs[0]
		scaling_display = scaling_funcs[1]

	damage_type = (
		JsonHelper.get_optional_enum(
			_dict, "damage_type", Unit.PARSE_DAMAGE_TYPE, Unit.DamageType.PHYSICAL
		)
		as Unit.DamageType
	)
	can_crit = JsonHelper.get_optional_bool(_dict, "can_crit", false)

	return true


func get_copy(new_effect: ActionEffect = null) -> ActionEffect:
	if new_effect == null:
		new_effect = OnHitDamageEffect.new()

	new_effect = super(new_effect)

	new_effect.damage = damage
	new_effect.scaling_calc = scaling_calc
	new_effect.damage_type = damage_type
	new_effect.can_crit = can_crit

	new_effect.trigger_sources = []
	for source in trigger_sources:
		new_effect.trigger_sources.append(source)

	return new_effect


func get_description_string(_caster: Unit) -> String:
	var effect_string = super(_caster) + "\n"
	var damage_type_string = Unit.PARSE_DAMAGE_TYPE.find_key(damage_type)
	var damage_type_translation = tr("DAMAGE_TYPE:" + damage_type_string + ":NAME")

	if scaling_calc != null:
		var scaling_string = scaling_display.call(_caster)
		effect_string += (
			tr("EFFECT:OnHitDamageEffect:scaled") % [scaling_string, damage_type_translation]
		)
	else:
		effect_string += tr("EFFECT:OnHitDamageEffect:flat") % [damage, damage_type_translation]

	return effect_string


func connect_to_unit(_unit: Unit) -> void:
	if scaling_calc == null:
		_unit.attack_connected.connect(self._on_attack_connected_fixed)
	else:
		_unit.attack_connected.connect(self._on_attack_connected_scaled)

	_is_loaded = true


func disconnect_from_unit(_unit: Unit) -> void:
	if scaling_calc == null:
		_unit.attack_connected.disconnect(self._on_attack_connected_fixed)
	else:
		_unit.attack_connected.disconnect(self._on_attack_connected_scaled)

	_is_loaded = false


func _on_attack_connected_fixed(
	caster: Unit,
	target: Unit,
	is_crit: bool,
	_damage_amount,
	_damage_type,
	_damage_src: Unit.SourceType
) -> void:
	if not _can_trigger_onhit(caster, target, is_crit, _damage_type, _damage_src):
		return

	target.take_damage(caster, can_crit and is_crit, damage_type, damage, _effect_source)


func _on_attack_connected_scaled(
	caster: Unit,
	target: Unit,
	is_crit: bool,
	_damage_amount,
	_damage_type,
	_damage_src: Unit.SourceType
) -> void:
	if not _can_trigger_onhit(caster, target, is_crit, _damage_type, _damage_src):
		return

	var raw_damage := int(scaling_calc.call(caster, target))

	target.take_damage(caster, can_crit and is_crit, damage_type, raw_damage, _effect_source)


func _can_trigger_onhit(
	caster: Unit, target: Unit, is_crit: bool, _damage_type, _damage_src: Unit.SourceType
) -> bool:
	if not caster:
		return false

	if not target:
		return false

	if not target.is_alive:
		return false

	if not trigger_sources.has(_damage_src):
		return false

	return true
