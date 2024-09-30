extends Control

@onready var ConfirmBtn = $SplitContainer/PanelContainer2/GridContainer/ConfirmBtn
@onready var ExitBtn = $SplitContainer/PanelContainer2/GridContainer/ExitBtn

# display setting element
@onready
var fullscreen_toggle = $SplitContainer/PanelContainer/TabContainer/SETTINGS_TAB_DISPLAY/FullscreenToggleBtn

# camera setting elements
@onready
var cam_speed_slider = $SplitContainer/PanelContainer/TabContainer/SETTINGS_TAB_CAMERA/cam_speed_slider
@onready
var edge_margin_slider = $SplitContainer/PanelContainer/TabContainer/SETTINGS_TAB_CAMERA/edge_margin_slider
@onready
var max_zoom_slider = $SplitContainer/PanelContainer/TabContainer/SETTINGS_TAB_CAMERA/max_zoom_slider
@onready
var cam_centered_toggle = $SplitContainer/PanelContainer/TabContainer/SETTINGS_TAB_CAMERA/CamCenteredToggleBtn
@onready
var cam_pan_sesitivity_slider = $SplitContainer/PanelContainer/TabContainer/SETTINGS_TAB_CAMERA/cam_pan_sesitivity_slider


func _ready():
	hide()

	ExitBtn.pressed.connect(_on_game_close_pressed)
	ConfirmBtn.pressed.connect(_on_confirm_changes)


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("player_pause"):
		return

	# TODO: figure out why esc has to be pressed twice to close the settings menu

	if is_visible_in_tree():
		hide()
		Config.in_focued_menu = false
	else:
		# make sure we aren't already in a different menu
		if Config.in_focued_menu:
			return

		show()
		display_settings_values()
		ConfirmBtn.grab_focus.call_deferred()
		Config.in_focued_menu = true
		queue_redraw()


func display_settings_values():
	fullscreen_toggle.button_pressed = Config.graphics_settings.is_fullscreen

	cam_speed_slider.value = Config.camera_settings.cam_speed
	cam_pan_sesitivity_slider.value = Config.camera_settings.cam_pan_sensitivity
	edge_margin_slider.value = Config.camera_settings.edge_margin
	max_zoom_slider.value = Config.camera_settings.max_zoom
	max_zoom_slider.min_value = Config.camera_settings.min_zoom + 1
	cam_centered_toggle.button_pressed = Config.camera_settings.is_cam_centered


func _on_game_close_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func _on_confirm_changes():
	# camera settings
	var new_camera_settings = CameraSettings.new()

	new_camera_settings.is_cam_centered = cam_centered_toggle.button_pressed
	new_camera_settings.cam_speed = cam_speed_slider.value
	new_camera_settings.edge_margin = edge_margin_slider.value
	new_camera_settings.max_zoom = max_zoom_slider.value
	new_camera_settings.cam_pan_sensitivity = cam_pan_sesitivity_slider.value

	Config.change_camera_settings(new_camera_settings)

	# graphics settings
	var new_graphics_settings = GraphicsSettings.new()

	new_graphics_settings.is_fullscreen = fullscreen_toggle.button_pressed

	Config.change_graphics_settings(new_graphics_settings)

	# hide the settings menu
	Config.in_focued_menu = false
	hide()
