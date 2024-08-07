class_name Ability
extends Node

var _display_id: Identifier
var _texture_id: Identifier

var _can_levelup: bool = false
var _level: int = 0
var _ability_levels: Array[ActionEffect] = []
var _current_effect: ActionEffect = null

var _connected_unit: Unit = null


static func from_dict(_dict: Dictionary) -> Ability:
	if not _dict.has("display_id"):
		print("Could not create action effect from dictionary. Dictionary has no display_id key.")
		return null

	var ability_instance := Ability.new()

	ability_instance._display_id = Identifier.from_string(str(_dict["display_id"]))
	if not ability_instance._display_id.is_valid():
		print("Could not create ability from dictionary. Could not load data.")
		return null

	ability_instance._texture_id = Identifier.for_resource("texture://" + str(_dict["texture_id"]))

	var has_upgrades := JsonHelper.get_optional_bool(_dict, "has_upgrades", false)
	ability_instance._can_levelup = has_upgrades

	var base_values := _dict["base_values"] as Dictionary
	if base_values == null:
		print("Could not create ability from dictionary. Could not load data.")
		return null

	if not has_upgrades:
		var ability_effect := ActionEffect.from_dict(base_values)
		if ability_effect == null:
			print("Could not create ability from dictionary. Could not load data.")
			return null

		ability_instance._ability_levels.append(ability_effect)
		ability_instance._current_effect = ability_effect

		return ability_instance

	var ability_levels := _dict["ability_data"] as Array
	if ability_levels == null:
		print("Could not create ability from dictionary. Could not load data.")
		return null

	for ability_level in ability_levels:
		var ability_data := ability_level as Dictionary
		if ability_data == null:
			print("Could not create ability from dictionary. Could not load data.")
			return null

		ability_data.merge(base_values, true)

		var ability_effect := ActionEffect.from_dict(ability_data)
		if ability_effect == null:
			print("Could not create ability from dictionary. Could not load data.")
			return null

		ability_instance._ability_levels.append(ability_effect)

	if not _dict.has("display_id"):
		print("Could not create action effect from dictionary. Dictionary has no display_id key.")
		return null

	return ability_instance


func get_copy() -> Ability:
	var new_ability := Ability.new()
	new_ability._display_id = _display_id
	new_ability._texture_id = _texture_id
	new_ability._can_levelup = _can_levelup
	new_ability._level = _level
	for _ability_level in _ability_levels:
		new_ability._ability_levels.append(_ability_level.get_copy())

	if _current_effect != null:
		var ability_index := _ability_levels.find(_current_effect)
		new_ability._current_effect = new_ability._ability_levels[ability_index]

	return new_ability


func get_level() -> int:
	return _level


func try_activate() -> bool:
	if _current_effect == null:
		print("Could not activate ability. Ability has no effect.")
		return false

	var activatanle_effect := _current_effect as ActiveActionEffect
	if activatanle_effect == null:
		print("Could not activate ability. Ability is not an active ability.")
		return false

	return activatanle_effect.activate(_connected_unit, null)


func _ready() -> void:
	var parent_node: Node = self
	while _connected_unit == null:
		parent_node = parent_node.get_parent()
		_connected_unit = parent_node as Unit

	var abilites_node := _connected_unit.get_node("Abilities")
	if abilites_node == null:
		print("Could not connect ability to unit. Unit has no abilities node.")
		return

	abilites_node.add_child(self)

	if _current_effect != null:
		_current_effect.connect_to_unit(_connected_unit)


func upgrade():
	if not _can_levelup:
		print("Could not upgrade ability. Ability has no upgrades.")
		return

	if _level >= _ability_levels.size():
		print("Could not upgrade ability. Ability is already at max level.")
		return

	if _current_effect != null:
		_current_effect.disconnect_from_unit(_connected_unit)
		_current_effect = null

	_current_effect = _ability_levels[_level]
	_level += 1

	_current_effect.connect_to_unit(_connected_unit)
