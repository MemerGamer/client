class_name CameraSettings
extends ConfigGroupBase

@export var is_cam_centered: bool = false
@export var cam_pan_sensitivity: float = 0.01
@export var cam_speed: float = 15.0
@export var edge_margin: int = 75

@export var min_zoom = 1.0
@export var max_zoom = 15.0


func _init(_config: ConfigFile = null) -> void:
	config_type = "camera"
	if _config == null:
		return

	is_cam_centered = _config.get_value(config_type, "cam_centered", false)
	cam_pan_sensitivity = _config.get_value(config_type, "cam_pan_sensitivity", 0.01)
	cam_speed = _config.get_value(config_type, "cam_speed", 15.0)
	edge_margin = _config.get_value(config_type, "edge_margin", 75)

	min_zoom = _config.get_value(config_type, "min_zoom", 1)
	max_zoom = _config.get_value(config_type, "max_zoom", 15.0)


func save(_config: ConfigFile) -> void:
	_config.set_value(config_type, "cam_centered", is_cam_centered)
	_config.set_value(config_type, "cam_pan_sensitivity", cam_pan_sensitivity)
	_config.set_value(config_type, "cam_speed", cam_speed)
	_config.set_value(config_type, "edge_margin", edge_margin)

	_config.set_value(config_type, "min_zoom", min_zoom)
	_config.set_value(config_type, "max_zoom", max_zoom)


func copy() -> CameraSettings:
	var copied_group = CameraSettings.new()
	copied_group.is_cam_centered = is_cam_centered
	copied_group.cam_pan_sensitivity = cam_pan_sensitivity
	copied_group.cam_speed = cam_speed
	copied_group.edge_margin = edge_margin

	copied_group.min_zoom = min_zoom
	copied_group.max_zoom = max_zoom

	return copied_group


func differs(other: ConfigGroupBase) -> bool:
	if super(other):
		return true

	if other.config_type != config_type:
		return false

	var other_camera_settings := other as CameraSettings
	if other_camera_settings == null:
		return false

	return (
		is_cam_centered != other_camera_settings.is_cam_centered
		or cam_pan_sensitivity != other_camera_settings.cam_pan_sensitivity
		or cam_speed != other_camera_settings.cam_speed
		or edge_margin != other_camera_settings.edge_margin
		or min_zoom != other_camera_settings.min_zoom
		or max_zoom != other_camera_settings.max_zoom
	)
