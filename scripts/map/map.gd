class_name MapNode
extends Node

enum EndCondition {
	TEAM_ELIMINATION,
	STRUCTURE_DESTRUCTION,
}

const PlayerController = preload("res://scenes/player/_player.tscn")

const PlayerDesktopHud = preload("res://ui/game_ui.tscn")
const PlayerDesktopSettings = preload("res://ui/settings_menu/settings_menu.tscn")
const PlayerItemShop = preload("res://ui/shops/item_shop.tscn")

@export var map_configuration: Dictionary = {}

@export var connected_players: Array

@export var map_features: Node
@export var player_spawns = {}

@export var time_elapsed: float = 0

var characters = {}
var player_cooldowns = {}
var end_conditions = []

var last_player_index = 0

var player_passive_item_slots = 2

var damage_popup_spawner := DamagePopupMultiplayerSpawner.new()
var character_spawner := CharacterMultiplayerSpawner.new()


func _ready():
	_load_config()
	_setup_nodes()

	# TODO: make sure all clients have the map fully loaded before
	# continueing here. For now we just do a 1 seconds delay.
	await get_tree().create_timer(1).timeout

	if not Config.is_dedicated_server:
		client_setup()

	if not multiplayer.is_server():
		return

	for player in connected_players:
		var spawn_args = {}

		spawn_args["name"] = str(player["peer_id"])
		spawn_args["character"] = player["character"]
		spawn_args["id"] = player["peer_id"]
		spawn_args["nametag"] = player["name"]
		spawn_args["index"] = last_player_index
		spawn_args["team"] = player["team"]
		spawn_args["position"] = player_spawns[str(player["team"])].position
		spawn_args["passive_item_slots"] = player_passive_item_slots

		last_player_index += 1

		var new_char = $CharacterSpawner.spawn(spawn_args)
		new_char.look_at(Vector3(0, 0, 0))
		characters[player["peer_id"]] = new_char


func _physics_process(delta):
	time_elapsed += delta


func _setup_nodes():
	character_spawner.name = "CharacterSpawner"
	character_spawner.map_death_func = on_player_death
	add_child(character_spawner)

	var abilities_node = Node.new()
	abilities_node.name = "Abilities"
	add_child(abilities_node)

	damage_popup_spawner.name = "DamagePopupSpawner"
	add_child(damage_popup_spawner)


func _load_config():
	player_passive_item_slots = int(map_configuration["player_passive_item_slots"])

	# unlike the other nodes the map features node is not created in the _setup_nodes function
	# this is needed because all features are added to this node and we need to load the
	# map configuration before we can set up most of the nodes
	var map_features_node = Node.new()
	map_features_node.name = "MapFeatures"
	add_child(map_features_node)
	map_features = get_node("MapFeatures")

	# Load the map configuration
	if not map_configuration.has("end_conditions"):
		print("Map config is missing end conditions")
		return

	var raw_end_conditions = map_configuration["end_conditions"]
	for condition in raw_end_conditions:
		if not condition.has("type"):
			print("End condition is missing type")
			continue

		var type = condition["type"]
		match type:
			"team_elimination":
				if not condition.has("team"):
					print("Team elimination condition is missing team")
					continue
				end_conditions.append(
					{"type": EndCondition.TEAM_ELIMINATION, "team": condition["team"]}
				)
			"structure_destruction":
				if not condition.has("structure"):
					print("Structure destruction condition is missing structure")
					continue
				end_conditions.append(
					{
						"type": EndCondition.STRUCTURE_DESTRUCTION,
						"structure_name": condition["structure_name"],
						"loosing_team": condition["loosing_team"]
					}
				)
			_:
				print("Unknown end condition type: " + type)

	if not map_configuration.has("features"):
		print("Map config is missing features")
		return

	var features = map_configuration["features"]
	for feature in features:
		MapFeature.spawn_feature(feature, self)


func client_setup():
	# Add the player into the world
	# The player rig will ask the server for their character
	var player_rig = PlayerController.instantiate()
	add_child(player_rig)

	# instantiate and add all the UI components
	add_child(PlayerDesktopSettings.instantiate())

	var hud = PlayerDesktopHud.instantiate()
	hud._map = self
	add_child(hud)

	var item_shop = PlayerItemShop.instantiate()
	item_shop.player_instance = player_rig
	add_child(item_shop)


func on_unit_damaged(unit: Unit, damage: int, damage_type: Unit.DamageType):
	var damage_popup_args = {"position": unit.server_position, "value": damage, "type": damage_type}
	damage_popup_spawner.spawn(damage_popup_args)


func on_player_death(player_id: int):
	# get the character that died
	var character = characters.get(player_id)
	var team = character.team

	# Check if the game has ended
	var team_alive = false
	var team_elimination = false
	for condition in end_conditions:
		if condition["type"] != EndCondition.TEAM_ELIMINATION:
			continue

		if team != condition["team"]:
			continue

		team_elimination = true
		for _char in characters.values():
			if _char.name == str(player_id):
				continue

			if _char.team != team:
				continue

			if not _char.is_alive:
				continue

			team_alive = true
			break

	# End the game if a team has been eliminated
	if team_elimination and not team_alive:
		print("Team " + str(team) + " has been eliminated")
		return

	# get the respawn timer and respawn the player once it's done
	var respawn_time = player_spawns[str(team)].get_respawn_time(character.level, time_elapsed)
	get_tree().create_timer(respawn_time).timeout.connect(func(): respawn(character))


@rpc("any_peer")
func client_ready():
	print(connected_players)
	print(multiplayer.get_remote_sender_id())


@rpc("any_peer")
func register_player():
	var peer_id = multiplayer.get_remote_sender_id()
	# TODO: implement player registering


@rpc("any_peer", "call_local")
func try_purchase_item(item_name):
	var peer_id = multiplayer.get_remote_sender_id()
	print("Player " + str(peer_id) + " is trying to purchase item: " + str(item_name))

	var character = get_character(peer_id)

	var item = RegistryManager.items().get_element(item_name) as Item
	if not item:
		print("Failed to find item: " + str(item_name))
		return

	var tried_purchase: Dictionary = item.try_purchase(character.item_list)
	var purchase_cost = tried_purchase["cost"]
	if character.current_gold < purchase_cost:
		print(
			(
				"Missing %d gold to purchase item: %s"
				% [purchase_cost - character.current_gold, item_name]
			)
		)
		return

	var new_inventory = tried_purchase["owned_items"] as Array[Item]
	new_inventory.append(item)

	var active_items = 0
	for _item in new_inventory:
		if _item.is_active:
			active_items += 1

	if active_items > character.active_item_slots:
		var display_strings = item.get_desctiption_strings(character)
		print("Not enough active slots to buy item %s" % display_strings["name"])
		return

	var new_item_count = new_inventory.size()
	var max_slots = character.passive_item_slots + character.active_item_slots
	if new_item_count > max_slots:
		var display_strings = item.get_desctiption_strings(character)
		print(
			(
				tr("Not enough inventory slots to buy item %s, max %i, would be %i")
				% [display_strings["name"], max_slots, new_item_count]
			)
		)
		return

	print("Purchasing item: " + str(item_name))
	character.purchase_item(item, purchase_cost, new_inventory)


@rpc("any_peer", "call_local")
func move_to(pos: Vector3):
	var character = get_character(multiplayer.get_remote_sender_id())
	character.change_state.rpc("Moving", pos)


@rpc("any_peer", "call_local")
func upgrade_ability(ability_name: String):
	var character = get_character(multiplayer.get_remote_sender_id())
	if not character:
		print("Failed to find character")
		return

	if character.ability_upgrade_points <= 0:
		print("Not enough ability points to upgrade ability: " + ability_name)
		return

	if not character.abilities.has(ability_name):
		print("Character does not have ability: " + ability_name)
		return

	var ability = character.abilities[ability_name] as Ability
	if not ability:
		print("Failed to find ability: " + ability_name)
		return

	if not ability.upgrade():
		print("Failed to upgrade ability: " + ability_name)
		return

	character.ability_upgrade_points -= 1
	character.upgrade_ability.rpc(ability_name)


@rpc("any_peer", "call_local")
func cast_ability(ability_name, target_param):
	var character := get_character(multiplayer.get_remote_sender_id()) as Unit
	if not character:
		print("Failed to find character")
		return

	if not character.abilities.has(ability_name):
		print("Character does not have ability: " + ability_name)
		return

	var ability = character.abilities[ability_name] as Ability
	if not ability:
		print("Failed to find ability: " + ability_name)
		return

	if ability.get_ability_type() == ActionEffect.AbilityType.PASSIVE:
		print("Cannot cast passive ability: " + ability_name)
		return

	var ability_state := ability.get_activation_state() as ActionEffect.ActivationState
	if (
		ability_state == ActionEffect.ActivationState.NONE
		or ability_state == ActionEffect.ActivationState.COOLDOWN
	):
		return

	character.change_state("Casting", [ability_name, target_param])


@rpc("any_peer", "call_local")
func respawn(character: Unit):
	var spawner = player_spawns[str(character.team)]

	character.server_position = spawner.get_spawn_position(character.index)
	character.position = character.server_position

	character.current_stats = character.maximum_stats
	character.is_dead = false
	character.show()
	character.rpc_id(character.pid, "respawn")


func free_ability(cooldown: float, peer_id: int, ab_id: int) -> void:
	await get_tree().create_timer(cooldown).timeout
	player_cooldowns[peer_id][ab_id] = 0


func get_character(id: int):
	var character = characters.get(id)
	if not character:
		print_debug("Failed to find character")
		return false

	return character
