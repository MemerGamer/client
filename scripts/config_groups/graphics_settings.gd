class_name GraphicsSettings
extends ConfigGroupBase

@export var is_fullscreen: bool = true


func _init(_config: ConfigFile = null) -> void:
	config_type = "graphics"
	if _config == null:
		return

	is_fullscreen = _config.get_value(config_type, "fullscreen", true)


func save(_config: ConfigFile) -> void:
	_config.set_value(config_type, "fullscreen", is_fullscreen)


func copy() -> GraphicsSettings:
	var copied_group = GraphicsSettings.new()

	copied_group.is_fullscreen = is_fullscreen

	return copied_group


func differs(other: ConfigGroupBase) -> bool:
	if super(other):
		return true

	if other.config_type != config_type:
		return false

	var other_graphics_settings := other as GraphicsSettings
	if other_graphics_settings == null:
		return false

	return is_fullscreen != other_graphics_settings.is_fullscreen
