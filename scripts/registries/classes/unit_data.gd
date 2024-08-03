extends Object
class_name UnitData

enum AggroType {
	# Doesn't attack.
	PASSIVE,
	# Attacks when attacked.
	NEUTRAL,
	# Attacks anything not on its team.
	AGGRESSIVE,
}

const PareAggroType = {
	"passive": AggroType.PASSIVE,
	"neutral": AggroType.NEUTRAL,
	"aggressive": AggroType.AGGRESSIVE,
}

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

	var _json_data = _json["data"] as Dictionary
	if _json_data == null:
		print("Unit: Data object is not a dictionary.")
		return false

	if not _json_data.has("id"):
		print("Unit: No name provided.")
		return false

	var _unit_id_str := str(_json_data["id"])
	var _unit_id := Identifier.from_string(_unit_id_str)

	if _registry.contains(_unit_id_str):
		print("Unit (%s): Unit already exists in unit registry." % _unit_id_str)
		return false

	var _is_character := JsonHelper.get_optional_bool(_json_data, "is_character", false)

	var _unit_model_id = null
	if _json_data.has("model"):
		var raw_model_id = _json_data["model"]
		if not (raw_model_id is String):
			print("Unit (%s): model must be a string." % _unit_id_str)
			return false

		_unit_model_id = Identifier.for_resource("unit://" + raw_model_id)
	else:
		if _is_character:
			_unit_model_id = Identifier.for_resource(
				"unit://" + _unit_id.get_group() + ":characters/" + _unit_id.get_name()
			)
		else:
			_unit_model_id = Identifier.for_resource("unit://" + _unit_id_str)

	var _unit_icon_id = null
	if _json_data.has("icon"):
		var raw_icon_id = _json_data["icon"]
		if not (raw_icon_id is String):
			print("Unit (%s): icon must be a string." % _unit_id_str)
			return false

		_unit_icon_id = Identifier.for_resource("texture://" + raw_icon_id)
	else:
		if _is_character:
			_unit_icon_id = Identifier.for_resource(
				(
					"texture://"
					+ _unit_id.get_group()
					+ ":units/characters/"
					+ _unit_id.get_name()
					+ "/icon"
				)
			)
		else:
			_unit_icon_id = Identifier.for_resource(
				"texture://" + _unit_id.get_group() + ":units/" + _unit_id.get_name() + "/icon"
			)

	var new_unit = UnitData.new(_unit_id, _unit_model_id, _unit_icon_id)

	var raw_stats = _json_data["base_stats"]
	if not (raw_stats is Dictionary):
		print("Unit (%s): base_stats must be a dictionary." % _unit_id_str)
		return false

	new_unit.stats = StatCollection.from_dict(raw_stats)

	var raw_stat_growth = _json_data["stat_growth"]
	if not (raw_stat_growth is Dictionary):
		print("Unit (%s): stat_growth must be a dictionary." % _unit_id_str)
		return false

	new_unit.stat_growth = StatCollection.from_dict(raw_stat_growth)

	if _json_data.has("tags"):
		var raw_tags = _json_data["tags"]
		if not (raw_tags is Array):
			print("Unit (%s): tags must be an array." % _unit_id_str)
			return false

		for tag in raw_tags:
			if not (tag is String):
				print("Unit (%s): tag must be a string, got %s." % [_unit_id_str, str(tag)])
				continue

			new_unit.tags.append(tag)

	new_unit.is_character = _is_character

	new_unit.kill_exp = JsonHelper.get_optional_int(_json_data, "kill_exp", 0)
	new_unit.kill_gold = JsonHelper.get_optional_int(_json_data, "kill_gold", 0)
	new_unit.exp_per_second = JsonHelper.get_optional_number(_json_data, "exp_per_second", 0.0)
	new_unit.gold_per_second = JsonHelper.get_optional_number(_json_data, "gold_per_second", 0.0)
	new_unit.spawn_exp = JsonHelper.get_optional_int(_json_data, "spawn_exp", 0)
	new_unit.spawn_gold = JsonHelper.get_optional_int(_json_data, "spawn_gold", 0)

	if _json_data.has("attack_projectile"):
		var _projectile_config = {}
		var raw_projectile_config = _json_data["attack_projectile"]
		if raw_projectile_config is Dictionary:
			_projectile_config["model"] = str(raw_projectile_config["model"])
			_projectile_config["speed"] = float(raw_projectile_config["speed"])
			_projectile_config["model_scale"] = JsonHelper.get_vector3(
				raw_projectile_config, "model_scale", Vector3(1.0, 1.0, 1.0)
			)
			_projectile_config["model_rotation"] = JsonHelper.get_vector3(
				raw_projectile_config, "model_rotation", Vector3(0.0, 0.0, 0.0)
			)
			_projectile_config["spawn_offset"] = JsonHelper.get_vector3(
				raw_projectile_config, "spawn_offset", Vector3(0.0, 0.0, 0.0)
			)
			_projectile_config["damage_type"] = JsonHelper.get_optional_enum(
				raw_projectile_config, "damage_type", Unit.ParseDamageType, Unit.DamageType.PHYSICAL
			)

			new_unit.projectile_config = _projectile_config

	new_unit.windup_fraction = JsonHelper.get_optional_number(_json_data, "windup_fraction", 0.1)

	new_unit.aggro_type = JsonHelper.get_optional_enum(
		_json_data, "aggro_type", PareAggroType, AggroType.PASSIVE
	)
	new_unit.aggro_distance = JsonHelper.get_optional_number(_json_data, "aggro_distance", 1.0)
	new_unit.deaggro_distance = JsonHelper.get_optional_number(_json_data, "deaggro_distance", 3.0)

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

	var _unit = model_scene.instantiate()
	if _unit == null:
		print("Character (%s): Failed to instantiate model." % id.to_string())
		return null

	_unit.name = spawn_args["name"]
	_unit.team = spawn_args["team"]
	_unit.position = spawn_args["position"]
	_unit.projectile_config = projectile_config

	_unit.server_position = _unit.position

	_unit.maximum_stats = stats.get_copy()
	_unit.current_stats = stats.get_copy()
	_unit.per_level_stats = stat_growth.get_copy()
	_unit.unit_id = id.to_string()
	_unit.windup_fraction = windup_fraction

	_unit.dropped_exp = kill_exp
	_unit.dropped_gold = kill_gold

	_unit.exp_per_second = exp_per_second
	_unit.gold_per_second = gold_per_second

	_unit.passive_item_slots = JsonHelper.get_optional_int(spawn_args, "passive_item_slots", 0)

	_unit.index = JsonHelper.get_optional_int(spawn_args, "index", 0)

	if spawn_args.has("level"):
		var level_increment = int(spawn_args["level"]) - _unit.level
		if level_increment > 0:
			_unit.level_up(level_increment)

	if spawn_exp > 0:
		_unit.give_exp(spawn_exp)

	if spawn_gold > 0:
		_unit.give_gold(spawn_gold)

	# check if the unit should be spawned as a character
	# if no value is provided use the one in the unit data
	var spawn_character = JsonHelper.get_optional_bool(spawn_args, "is_character", is_character)

	if spawn_character:
		# set the character's script and set all the values
		#character.set_script("res://classes/character.gd")

		_unit.nametag = spawn_args["nametag"]
		_unit.id = spawn_args["id"]
		_unit.has_mana = true
		_unit.player_controlled = true
	else:
		var unit_controller = NPC_Controller.new()
		unit_controller.name = "NPC_Controller"
		unit_controller.aggro_type = aggro_type
		unit_controller.aggro_distance = aggro_distance
		unit_controller.deaggro_distance = deaggro_distance
		unit_controller.controlled_unit = _unit

		_unit.add_child(unit_controller)

	return _unit


func _init(
	_id: Identifier,
	_model_id: Identifier,
	_icon_id: Identifier,
):
	id = _id
	model_id = _model_id
	icon_id = _icon_id
