class_name StructureColorTheme
extends Object

const FALLBACK_COLOR := Color(0.3, 0.3, 0.3, 1)

var theme_id: Identifier

var banner_albedo := FALLBACK_COLOR
var crystal_albedo := FALLBACK_COLOR
var crystal_emission := FALLBACK_COLOR


static func from_dict(raw_data: Dictionary, registry: RegistryBase) -> StructureColorTheme:
	if not raw_data.has("id"):
		print("StructureColorTheme: Missing id in raw_data.")
		return null

	var id_string := str(raw_data["id"])
	if registry.contains(id_string):
		print("StructureColorTheme: Duplicate id in raw_data.")
		return null

	var parsed_id = Identifier.from_string(id_string)
	if not parsed_id.is_valid():
		print("StructureColorTheme: Invalid id in raw_data.")
		return null

	var theme = StructureColorTheme.new()
	theme.theme_id = parsed_id

	theme.banner_albedo = JsonHelper.get_color_value(raw_data, "banner_albedo", FALLBACK_COLOR)
	theme.crystal_albedo = JsonHelper.get_color_value(raw_data, "crystal_albedo", FALLBACK_COLOR)
	theme.crystal_emission = JsonHelper.get_color_value(
		raw_data, "crystal_emission", FALLBACK_COLOR
	)

	return theme


func get_id() -> Identifier:
	return theme_id
