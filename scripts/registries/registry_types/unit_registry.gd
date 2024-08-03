extends RegistryBase
class_name UnitRegistry

var _internal_values: Dictionary = {}


func _init():
	_json_type = "unit"


func contains(_item: String) -> bool:
	return _internal_values.has(_item)


func get_element(_item: String):
	return _internal_values[_item]


func assure_validity():
	for _unit in _internal_values.values():
		if not _unit.is_valid(self):
			print("Unit (%s): Invalid unit." % _unit.get_id())
			_internal_values.erase(_unit.get_id().to_string())

	return true


func load_from_json(_json: Dictionary) -> bool:
	var new_unit = UnitData.from_dict(_json, self)
	if not new_unit:
		return false

	var unit_id_str: String = new_unit.get_id().to_string()
	_internal_values[unit_id_str] = new_unit

	return true
