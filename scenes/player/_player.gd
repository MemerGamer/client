extends Node3D

const MoveMarker := preload("res://scenes/effects/move_marker.tscn")

var cur_zoom: int
#@onready var attack_move_cast: ShapeCast3D = $AttackMoveCast
var server_listener: Node

var camera_target_position := Vector3.ZERO
var initial_mouse_position := Vector2.ZERO
var is_middle_mouse_dragging := false
var is_right_mouse_dragging := false
var is_left_mouse_dragging := false
var character: Unit
var attack_collider: Area3D
var current_ability_name: String = ""

var last_movement_gamepad = true

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

@onready var marker = MoveMarker.instantiate()
#@export var player := 1:
#set(id):
#player = id
#$MultiplayerSynchronizer.set_multiplayer_authority(id)


func _ready():
	add_child(marker)

	# For now close game when server dies
	multiplayer.server_disconnected.connect(get_tree().quit)
	spring_arm.spring_length = Config.camera_settings.max_zoom
	Config.camera_property_changed.connect(_on_camera_setting_changed)

	center_camera.call_deferred(multiplayer.get_unique_id())

	if server_listener == null:
		server_listener = get_parent()
		while !server_listener.is_in_group("Map"):
			server_listener = server_listener.get_parent()

	# set up the attack collider
	var attack_coll_shape = CapsuleShape3D.new()
	attack_coll_shape.radius = 10

	var attack_collision_shape = CollisionShape3D.new()
	attack_collision_shape.shape = attack_coll_shape

	attack_collider = Area3D.new()
	attack_collider.name = "AttackCollider"
	attack_collider.add_child(attack_collision_shape)

	add_child(attack_collider)
	attack_collider = get_node("AttackCollider")


func _input(event):
	if Config.is_dedicated_server:
		return

	if Config.in_focued_menu:
		return

	if event is InputEventMouseButton:
		last_movement_gamepad = false

		# Right click to move
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Start dragging
			player_mouse_action(event, not is_right_mouse_dragging)  # For single clicks

			is_right_mouse_dragging = event.is_pressed()

		# if event.button_index == MOUSE_BUTTON_MIDDLE:
		# 	if event.pressed:
		# 		initial_mouse_position = event.position
		# 		is_middle_mouse_dragging = true
		# 	else:
		# 		is_middle_mouse_dragging = false

		# Stop dragging if mouse is released
		if not event.is_pressed():
			is_middle_mouse_dragging = false
			is_right_mouse_dragging = false

		return

	if event is InputEventMouseMotion:
		if is_right_mouse_dragging:
			player_mouse_action(event, false)
			return

	if event is InputEventJoypadButton:
		last_movement_gamepad = true


func get_target_position(pid: int) -> Vector3:
	var champ = get_character(pid)
	if champ:
		return champ.position
	return Vector3.ZERO


func player_mouse_action(event, play_marker: bool = false):
	var from = camera.project_ray_origin(event.position)
	var to = from + camera.project_ray_normal(event.position) * 1000

	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(params)
	if !result:
		return

	# Move
	if result.collider.is_in_group("Ground"):
		_player_action_move(result.position, play_marker)


func _get_nearest_target(center: Vector3, target_range: int, target_mode = null) -> Unit:
	var targeted_unit = target_mode as Unit
	if targeted_unit:
		print("Attacking " + targeted_unit.name)
		return targeted_unit

	var target_players = true
	var target_minions = true
	var target_structures = true

	if target_mode != null:
		match str(target_mode):
			"players_only":
				target_minions = false
				target_structures = false
			"minions_only":
				target_players = false
				target_structures = false
			"structures_only":
				target_players = false
				target_minions = false

	var closest_unit = null
	var closest_distance = 1000000
	var target_distance = target_range * 0.01

	attack_collider.get_child(0).shape.radius = target_distance
	attack_collider.global_transform.origin = character.server_position

	var bodies = attack_collider.get_overlapping_bodies()
	for body in bodies:
		var unit = body as Unit
		if unit == null:
			continue
		if unit == character:
			continue
		if unit.team == character.team:
			continue
		if not unit.is_alive:
			continue

		if unit.player_controlled and not target_players:
			continue
		if not unit.player_controlled and not target_minions:
			continue
		if unit.is_structure and not target_structures:
			continue

		if unit.global_position.distance_to(character.global_position) > (target_distance):
			continue

		var distance = unit.global_position.distance_to(center)
		if distance > closest_distance:
			continue

		closest_unit = unit
		closest_distance = distance

	return closest_unit


func _show_ability_indicator(ability_name: String):
	# make the attack range visable for a bit
	if not Config.show_all_attack_ranges:
		var attack_ability := character.get_node("Abilities/" + ability_name) as Ability
		if attack_ability:
			var attack_effect = attack_ability._current_effect as ActiveActionEffect
			if attack_effect:
				attack_effect.start_preview_cast(character)


func _hide_ability_inidicator(ability_name: String):
	# make the attack range visable for a bit
	if not Config.show_all_attack_ranges:
		var attack_ability := character.get_node("Abilities/" + ability_name) as Ability
		if attack_ability:
			var attack_effect = attack_ability._current_effect as ActiveActionEffect
			if attack_effect:
				attack_effect.stop_preview_cast(character)


func _player_action_move(target_pos: Vector3, update_marker: bool = false):
	if update_marker:
		_play_move_marker(target_pos, false)

	target_pos.y += 1
	server_listener.rpc_id(get_multiplayer_authority(), "move_to", target_pos)


func _play_move_marker(marker_position: Vector3, attack_move: bool = false):
	marker.global_position = marker_position
	marker.attack_move = attack_move
	marker.play()


func center_camera(playerid):
	camera_target_position = get_target_position(playerid)


func _process(delta):
	if Config.is_dedicated_server:
		return

	if Config.in_focued_menu:
		return

	# If you want to see the gamepad info, uncomment the line below
	# This might help yu find out why input actions are not triggered
	#_print_gamepad_info()

	# Handle the gamepad and touch movement inputs
	var movement_delta: Vector2 = Input.get_vector(
		"character_move_left",
		"character_move_right",
		"character_move_up",
		"character_move_down",
		Config.gamepad_deadzone
	)

	if not movement_delta.is_zero_approx():
		last_movement_gamepad = true
		var movement_delta3 = (
			Vector3(movement_delta.x, 0, movement_delta.y)
			* character.current_stats.movement_speed
			* delta
		)
		var target_position = movement_delta3 + character.global_position
		_player_action_move(target_position)
	else:
		if last_movement_gamepad and character.get_current_state_name() == "Moving":
			_player_action_move(character.global_position)

	# handle all the camera-related input
	camera_movement_handler()

	# check input for ability uses
	detect_ability_use()

	# update the camera position using lerp
	position = position.lerp(camera_target_position, delta * Config.camera_settings.cam_speed)


func _print_gamepad_info():
	var gamepads = Input.get_connected_joypads()
	for gamepad in gamepads:
		print(
			(
				"Gamepad: %d, l2: %f, r2: %f, lx: %f, ly: %f, rx: %f, ry: %f"
				% [
					gamepad,
					Input.get_joy_axis(gamepad, JOY_AXIS_TRIGGER_LEFT),
					Input.get_joy_axis(gamepad, JOY_AXIS_TRIGGER_RIGHT),
					Input.get_joy_axis(gamepad, JOY_AXIS_LEFT_X),
					Input.get_joy_axis(gamepad, JOY_AXIS_LEFT_Y),
					Input.get_joy_axis(gamepad, JOY_AXIS_RIGHT_X),
					Input.get_joy_axis(gamepad, JOY_AXIS_RIGHT_Y),
				]
			)
		)


func detect_ability_use() -> void:
	var pid = multiplayer.get_unique_id()
	var curr_char := get_character(pid) as Unit
	if curr_char == null:
		return

	var last_target_pos: Vector3 = curr_char.global_position

	var cast_is_casting: bool = Input.is_action_pressed("player_layout_switch_cast", true)
	var cast_is_upgrade: bool = Input.is_action_pressed("player_layout_switch_upgrade", true)

	if not last_movement_gamepad:
		last_target_pos = camera.project_ray_origin(get_viewport().get_mouse_position())
		cast_is_casting = not cast_is_upgrade

	var check_ability_cast = cast_is_casting or cast_is_upgrade
	var check_basic_attack_cast = (not check_ability_cast) or (not last_movement_gamepad)

	var ability: Ability
	var ability_name: String

	if check_basic_attack_cast:
		if Input.is_action_pressed("player_attack_closest"):
			ability_name = "basic_attack"

	if check_ability_cast:
		if Input.is_action_pressed("player_ability1"):
			ability_name = "ability_1"

		if Input.is_action_pressed("player_ability2"):
			ability_name = "ability_2"

		if Input.is_action_pressed("player_ability3"):
			ability_name = "ability_3"

		if Input.is_action_pressed("player_ability4"):
			ability_name = "ability_4"

	var cast_finalized = false
	if ability_name != current_ability_name:
		if current_ability_name != "":
			_hide_ability_inidicator(current_ability_name)

		if ability_name != "":
			_show_ability_indicator(ability_name)
			current_ability_name = ability_name
		else:
			cast_finalized = true
			ability_name = current_ability_name
			current_ability_name = ""

	if ability_name == "":
		return

	if cast_is_upgrade:
		if cast_finalized:
			if curr_char.ability_upgrade_points <= 0:
				print("Not enough ability points to upgrade ability: " + ability_name)
				return

			print("Request ability upgrade: " + ability_name)
			server_listener.rpc_id(get_multiplayer_authority(), "upgrade_ability", ability_name)

		return

	ability = curr_char.get_node("Abilities/" + ability_name) as Ability
	if ability == null:
		print("Ability not found: " + ability_name)
		return

	var ability_state := ability.get_activation_state()
	if (
		ability_state == ActionEffect.ActivationState.NONE
		or ability_state == ActionEffect.ActivationState.COOLDOWN
	):
		print("Ability is not ready to be cast.")
		return

	var closest_unit: Unit = _get_nearest_target(last_target_pos, ability.get_cast_range(), null)
	if closest_unit:
		_play_move_marker(closest_unit.global_position, true)

	if cast_finalized:
		var target_param = null
		match ability.get_ability_type():
			ActionEffect.AbilityType.AUTO_TARGETED:
				pass
			ActionEffect.AbilityType.FIXED_TARGETED:
				if not closest_unit:
					return

				target_param = closest_unit
			ActionEffect.AbilityType.DIRECTION_TARGETED:
				if not closest_unit:
					return

				var target_direction: Vector3 = last_target_pos.direction_to(
					closest_unit.global_position
				)
				target_param = target_direction
			_:  # Unknown ability type or passive ability
				print("Ability cannot be cast or unknown ability type.")
				return

		server_listener.rpc_id(
			get_multiplayer_authority(), "cast_ability", ability_name, target_param
		)


func camera_movement_handler() -> void:
	# don't move the cam while changing the settings since that is annoying af
	if Config.in_focued_menu:
		return

	# Zoom
	if Input.is_action_just_pressed("player_zoomin"):
		if spring_arm.spring_length > Config.camera_settings.min_zoom:
			spring_arm.spring_length -= 1
	if Input.is_action_just_pressed("player_zoomout"):
		if spring_arm.spring_length < Config.camera_settings.max_zoom:
			spring_arm.spring_length += 1

	# Recenter - Tap
	if Input.is_action_pressed("player_camera_recenter"):
		camera_target_position = get_target_position(multiplayer.get_unique_id())

	# Recenter - Toggle
	if Input.is_action_just_pressed("player_camera_recenter_toggle"):
		Config.camera_settings.is_cam_centered = (!Config.camera_settings.is_cam_centered)

	# If centered, blindly follow the character
	if Config.camera_settings.is_cam_centered:
		camera_target_position = get_target_position(multiplayer.get_unique_id())
		return

	#ignore the input if this window is not even focused
	if not get_window().has_focus():
		return

	# Get Mouse Coords on screen
	var current_mouse_position = get_viewport().get_mouse_position()
	var size = get_viewport().get_visible_rect().size
	var cam_delta = Vector2(0, 0)
	var edge_margin = Config.camera_settings.edge_margin

	# Check if there is a collision at the mouse position
	if not get_viewport().get_visible_rect().has_point(
		get_viewport().get_final_transform() * current_mouse_position
	):
		return

	# Edge Panning
	if current_mouse_position.x <= edge_margin:
		cam_delta.x -= 1
	elif current_mouse_position.x >= size.x - edge_margin:
		cam_delta.x += 1

	if current_mouse_position.y <= edge_margin:
		cam_delta.y -= 1
	elif current_mouse_position.y >= size.y - edge_margin:
		cam_delta.y += 1

	# Keyboard input
	cam_delta = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")

	# Middle mouse dragging
	if is_middle_mouse_dragging:
		var mouse_delta = current_mouse_position - initial_mouse_position
		cam_delta += (
			Vector2(mouse_delta.x, mouse_delta.y) * Config.camera_settings.cam_pan_sensitivity
		)

	# Apply camera movement
	if not cam_delta.is_zero_approx():
		camera_target_position += Vector3(cam_delta.x, 0, cam_delta.y)


func get_character(pid: int) -> Node:
	if character == null:
		var champs = $"../CharacterSpawner/Characters".get_children()
		for child in champs:
			if child.name == str(pid):
				character = child
				return child
		return null

	return character


func try_purchasing_item(item_name: String) -> bool:
	# Before requesting it form the server try to purchase it locally.
	# The checks can be quite expensive to do.
	# Because of this we do them on the client side first and only relay
	# the requests to the server that should be possible.
	# The server will then do the same checks again to make sure the client
	# didn't cheat.
	# This should reduce the server load and reduce the chance of causing the
	# server to lag.
	var item = RegistryManager.items().get_element(item_name) as Item
	if item == null:
		print("Item (%s) not found in registry." % item_name)
		return false

	var purchase_result = item.try_purchase(character.item_list)
	var total_cost = purchase_result["cost"]
	if total_cost > character.current_gold:
		var display_strings = item.get_desctiption_strings(character)
		print(
			(
				tr("ITEM:NOT_ENOUGH_GOLD")
				% [total_cost - character.current_gold, display_strings["name"]]
			)
		)
		return false

	var new_inventory = purchase_result["owned_items"] as Array[Item]
	new_inventory.append(item)

	var active_items = 0
	for _item in new_inventory:
		if _item.is_active:
			active_items += 1

	if active_items > character.active_item_slots:
		var display_strings = item.get_desctiption_strings(character)
		print(tr("ITEM:NOT_ENOUGH_ACTIVE_SLOTS") % display_strings["name"])
		return false

	var new_item_count = new_inventory.size()
	if new_item_count > character.passive_item_slots + character.active_item_slots:
		var display_strings = item.get_desctiption_strings(character)
		print(tr("ITEM:NOT_ENOUGH_SLOTS") % display_strings["name"])
		return false

	# If it is possible to actually purchase the item, request it from the server
	server_listener.rpc_id(get_multiplayer_authority(), "try_purchase_item", item_name)
	return true


func _on_camera_setting_changed():
	spring_arm.spring_length = clamp(
		spring_arm.spring_length, Config.camera_settings.min_zoom, Config.camera_settings.max_zoom
	)
