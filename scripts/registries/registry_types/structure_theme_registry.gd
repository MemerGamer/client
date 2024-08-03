class_name StructureThemeRegistry
extends RegistryBase

const DEFAULT_THEMES: Array[Dictionary] = [
	{"id": "openchamp:fallback"},
	{
		"id": "openchamp:red",
		"banner_albedo": "#ef0000ff",
		"crystal_albedo": "#e30000ff",
		"crystal_emission": "#ad0000ff"
	},
	{
		"id": "openchamp:blue",
		"banner_albedo": "#485dffff",
		"crystal_albedo": "#5345ffff",
		"crystal_emission": "#181effff"
	},
]

var _internal_values: Dictionary = {}


func _init():
	_json_type = "structure_theme"


func contains(_theme: String) -> bool:
	return _internal_values.has(_theme)


func get_element(_theme: String):
	return _internal_values[_theme]


func assure_validity():
	for _unit in _internal_values.values():
		if not _unit.is_valid(self):
			print("Structure_theme (%s): Invalid Structure_theme." % _unit.get_id())
			_internal_values.erase(_unit.get_id().to_string())

	return true


func load_from_json(_json: Dictionary) -> bool:
	var new_theme = StructureColorTheme.from_dict(_json, self)
	if not new_theme:
		return false

	var theme_id_str: String = new_theme.get_id().to_string()
	_internal_values[theme_id_str] = new_theme

	return true
