class_name UnitData
extends Object

enum AggroType {
	# Doesn't attack.
	PASSIVE,
	# Attacks when attacked.
	NEUTRAL,
	# Attacks anything not on its team.
	AGGRESSIVE,
}

const PARSE_AGGRO_TYPE = {
	"passive": AggroType.PASSIVE,
	"neutral": AggroType.NEUTRAL,
	"aggressive": AggroType.AGGRESSIVE,
}

const UnitScript = preload("res://scripts/unit_types/unit.gd")

var stats = StatCollection.new()
var stat_growth = StatCollection.new()
var windup_fraction: float = 0.1

var id: Identifier
var model_id: Identifier
var icon_id: Identifier

var projectile_config: Dictionary

var tags: Array[String] = []

var is_character: bool = false

var kill_exp: int = 0
var kill_gold: int = 0

var exp_per_second: float = 0.0
var gold_per_second: float = 0.0

var spawn_exp: int = 0
var spawn_gold: int = 0

var aggro_type: AggroType
var aggro_distance: float = 1.0
var deaggro_distance: float = 3.0


static func from_dict(_json: Dictionary, _registry: RegistryBase):
	if not _registry:
		print("UnitData: No registry provided.")
		return false

	if not _registry.can_load_from_json(_json):
		print("Wrong JSON type.")
		return false

	if not _json.has("data"):
		print("Unit: No data object provided.")
		return false

	var raw_json_data = _json["data"] as Dictionary
	if raw_json_data == null:
		print("Unit: Data object is not a dictionary.")
		return false

	if not raw_json_data.has("id"):
		print("Unit: No name provided.")
		return false

	var new_unit_id_str := str(raw_json_data["id"])
	var new_unit_id := Identifier.from_string(new_unit_id_str)

	if _registry.contains(new_unit_id_str):
		print("Unit (%s): Unit already exists in unit registry." % new_unit_id_str)
		return false

	var new_unit_is_character := JsonHelper.get_optional_bool(raw_json_data, "is_character", false)

	var new_unit_model_id = null
	if raw_json_data.has("model"):
		var raw_model_id = raw_json_data["model"]
		if not (raw_model_id is String):
			print("Unit (%s): model must be a string." % new_unit_id_str)
			return false

		new_unit_model_id = Identifier.for_resource("unit://" + raw_model_id)
	else:
		if new_unit_is_character:
			new_unit_model_id = Identifier.for_resource(
				"unit://" + new_unit_id.get_group() + ":characters/" + new_unit_id.get_name()
			)
		else:
			new_unit_model_id = Identifier.for_resource("unit://" + new_unit_id_str)

	var new_unit_icon_id = null
	if raw_json_data.has("icon"):
		var raw_icon_id = raw_json_data["icon"]
		if not (raw_icon_id is String):
			print("Unit (%s): icon must be a string." % new_unit_id_str)
			return false

		new_unit_icon_id = Identifier.for_resource("texture://" + raw_icon_id)
	else:
		if new_unit_is_character:
			new_unit_icon_id = Identifier.for_resource(
				(
					"texture://"
					+ new_unit_id.get_group()
					+ ":units/characters/"
					+ new_unit_id.get_name()
					+ "/icon"
				)
			)
		else:
			new_unit_icon_id = Identifier.for_resource(
				(
					"texture://"
					+ new_unit_id.get_group()
					+ ":units/"
					+ new_unit_id.get_name()
					+ "/icon"
				)
			)

	var new_unit = UnitData.new(new_unit_id, new_unit_model_id, new_unit_icon_id)

	var raw_stats = raw_json_data["base_stats"]
	if not (raw_stats is Dictionary):
		print("Unit (%s): base_stats must be a dictionary." % new_unit_id_str)
		return false

	new_unit.stats = StatCollection.from_dict(raw_stats)

	var raw_stat_growth = raw_json_data["stat_growth"]
	if not (raw_stat_growth is Dictionary):
		print("Unit (%s): stat_growth must be a dictionary." % new_unit_id_str)
		return false

	new_unit.stat_growth = StatCollection.from_dict(raw_stat_growth)

	if raw_json_data.has("tags"):
		var raw_tags = raw_json_data["tags"]
		if not (raw_tags is Array):
			print("Unit (%s): tags must be an array." % new_unit_id_str)
			return false

		for tag in raw_tags:
			if not (tag is String):
				print("Unit (%s): tag must be a string, got %s." % [new_unit_id_str, str(tag)])
				continue

			new_unit.tags.append(tag)

	new_unit.is_character = new_unit_is_character

	new_unit.kill_exp = JsonHelper.get_optional_int(raw_json_data, "kill_exp", 0)
	new_unit.kill_gold = JsonHelper.get_optional_int(raw_json_data, "kill_gold", 0)
	new_unit.exp_per_second = JsonHelper.get_optional_number(raw_json_data, "exp_per_second", 0.0)
	new_unit.gold_per_second = JsonHelper.get_optional_number(raw_json_data, "gold_per_second", 0.0)
	new_unit.spawn_exp = JsonHelper.get_optional_int(raw_json_data, "spawn_exp", 0)
	new_unit.spawn_gold = JsonHelper.get_optional_int(raw_json_data, "spawn_gold", 0)

	if raw_json_data.has("attack_projectile"):
		var new_projectile_config = {}
		var raw_projectile_config = raw_json_data["attack_projectile"]
		if raw_projectile_config is Dictionary:
			new_projectile_config["model"] = str(raw_projectile_config["model"])
			new_projectile_config["speed"] = float(raw_projectile_config["speed"])
			new_projectile_config["model_scale"] = JsonHelper.get_vector3(
				raw_projectile_config, "model_scale", Vector3(1.0, 1.0, 1.0)
			)
			new_projectile_config["model_rotation"] = JsonHelper.get_vector3(
				raw_projectile_config, "model_rotation", Vector3(0.0, 0.0, 0.0)
			)
			new_projectile_config["spawn_offset"] = JsonHelper.get_vector3(
				raw_projectile_config, "spawn_offset", Vector3(0.0, 0.0, 0.0)
			)
			new_projectile_config["damage_type"] = JsonHelper.get_optional_enum(
				raw_projectile_config,
				"damage_type",
				Unit.PARSE_DAMAGE_TYPE,
				Unit.DamageType.PHYSICAL
			)

			new_unit.projectile_config = new_projectile_config

	new_unit.windup_fraction = JsonHelper.get_optional_number(raw_json_data, "windup_fraction", 0.1)

	new_unit.aggro_type = JsonHelper.get_optional_enum(
		raw_json_data, "aggro_type", PARSE_AGGRO_TYPE, AggroType.PASSIVE
	)
	new_unit.aggro_distance = JsonHelper.get_optional_number(raw_json_data, "aggro_distance", 1.0)
	new_unit.deaggro_distance = JsonHelper.get_optional_number(
		raw_json_data, "deaggro_distance", 3.0
	)

	return new_unit


func get_id() -> Identifier:
	return id


func get_model_id() -> Identifier:
	if AssetIndexer.get_asset_path(model_id) == "":
		print("Unit (%s): Model asset not found." % id.to_string())
		return Identifier.for_resource("unit://openchamp:fallback")

	return model_id


func get_icon_id() -> Identifier:
	if AssetIndexer.get_asset_path(icon_id) == "":
		print("Unit (%s): Icon asset not found." % id.to_string())
		return Identifier.for_resource("texture://openchamp:units/fallback/icon")

	return icon_id


func get_stats() -> StatCollection:
	return stats


func get_stat_growth() -> StatCollection:
	return stat_growth


func is_valid(_registry: RegistryBase = null) -> bool:
	if not id.is_valid():
		return false

	return true


func spawn(spawn_args: Dictionary):
	var model_id_str = get_model_id().get_resource_id()
	print(
		"Character (%s): Spawning character using the model: (%s)" % [id.to_string(), model_id_str]
	)

	var model_scene = load(model_id_str)
	if model_scene == null:
		print("Character (%s): Failed to load model." % id.to_string())
		return null

	var new_unit = model_scene.instantiate()
	if new_unit == null:
		print("Character (%s): Failed to instantiate model." % id.to_string())
		return null

	new_unit.set_script(UnitScript)

	new_unit.name = spawn_args["name"]
	new_unit.team = spawn_args["team"]
	new_unit.position = spawn_args["position"]
	new_unit.projectile_config = projectile_config

	new_unit.server_position = new_unit.position

	new_unit.maximum_stats = stats.get_copy()
	new_unit.current_stats = stats.get_copy()
	new_unit.per_level_stats = stat_growth.get_copy()
	new_unit.unit_id = id.to_string()
	new_unit.windup_fraction = windup_fraction

	new_unit.dropped_exp = kill_exp
	new_unit.dropped_gold = kill_gold

	new_unit.exp_per_second = exp_per_second
	new_unit.gold_per_second = gold_per_second

	new_unit.passive_item_slots = JsonHelper.get_optional_int(spawn_args, "passive_item_slots", 0)

	new_unit.index = JsonHelper.get_optional_int(spawn_args, "index", 0)

	if spawn_args.has("level"):
		var level_increment = int(spawn_args["level"]) - new_unit.level
		if level_increment > 0:
			new_unit.level_up(level_increment)

	if spawn_exp > 0:
		new_unit.give_exp(spawn_exp)

	if spawn_gold > 0:
		new_unit.give_gold(spawn_gold)

	# check if the unit should be spawned as a character
	# if no value is provided use the one in the unit data
	var spawn_character = JsonHelper.get_optional_bool(spawn_args, "is_character", is_character)

	if spawn_character:
		# set the character's script and set all the values
		#character.set_script("res://classes/character.gd")

		new_unit.nametag = spawn_args["nametag"]
		new_unit.id = spawn_args["id"]
		new_unit.has_mana = true
		new_unit.player_controlled = true
	else:
		var unit_controller = NPC_Controller.new()
		unit_controller.name = "NPC_Controller"
		unit_controller.aggro_type = aggro_type
		unit_controller.aggro_distance = aggro_distance
		unit_controller.deaggro_distance = deaggro_distance
		unit_controller.controlled_unit = new_unit

		new_unit.add_child(unit_controller)

	return new_unit


func _init(
	_id: Identifier,
	_model_id: Identifier,
	_icon_id: Identifier,
):
	id = _id
	model_id = _model_id
	icon_id = _icon_id
