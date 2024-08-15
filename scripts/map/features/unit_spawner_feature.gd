class_name UnitSpawnerFeature
extends MapFeature

# serialized data stats
var team: int

var unit_type: String = ""
var unit_level: int = 1
var unit_level_growth: int = 1
var unit_level_growth_time: float = 0

var initial_cooldown: float = 30
var wave_interval: float = 60
var wave_size: int = 1
var wave_growth: int = 1

var require_clear: bool = false

# current spawner values
var current_wave: int = 0
var current_unit_count: int = 0

var spawned_units: Node
var spawn_timer: Timer
var unit_multiplayer_spawner: MultiplayerSpawner


func _init():
	feature_type = "unit_spawn"


func spawn(feature_data: Dictionary, parent: Node) -> bool:
	if not feature_data.has("name"):
		print("Spawn is missing name")
		return false

	name = feature_data["name"]
	feature_name = name

	if not feature_data.has("team"):
		print("Spawn is missing team")
		return false
	team = int(feature_data["team"])

	if not feature_data.has("spawn_behaviour"):
		print("Spawn is missing spawn_behaviour")
		return false

	var spawn_behaviour := feature_data["spawn_behaviour"] as Dictionary

	if not spawn_behaviour.has("unit_type"):
		print("Spawn is missing unit_type")
		return false

	unit_type = str(spawn_behaviour["unit_type"])
	var unit_type_id = Identifier.from_string(unit_type)
	if not unit_type_id.is_valid():
		print("Failed to get unit type")
		return false

	unit_level = JsonHelper.get_optional_int(spawn_behaviour, "unit_level", unit_level)
	unit_level_growth = JsonHelper.get_optional_int(
		spawn_behaviour, "unit_level_growth", unit_level_growth
	)

	unit_level_growth_time = JsonHelper.get_optional_number(
		spawn_behaviour, "unit_level_growth_time", unit_level_growth_time
	)
	initial_cooldown = JsonHelper.get_optional_number(
		spawn_behaviour, "initial_cooldown", initial_cooldown
	)
	wave_interval = JsonHelper.get_optional_number(spawn_behaviour, "wave_interval", wave_interval)

	wave_size = JsonHelper.get_optional_int(spawn_behaviour, "wave_size", wave_size)
	wave_growth = JsonHelper.get_optional_int(spawn_behaviour, "wave_growth", wave_growth)

	require_clear = JsonHelper.get_optional_bool(spawn_behaviour, "require_clear", require_clear)

	position = _get_position(name, parent, feature_data)
	if position == null:
		print("Failed to get position")
		return false

	#parent.player_spawns[str(team)] = self

	spawned_units = Node.new()
	spawned_units.name = "SpawnedUnits"
	add_child(spawned_units)

	unit_multiplayer_spawner = MultiplayerSpawner.new()
	unit_multiplayer_spawner.name = "UnitMultiplayerSpawner"
	unit_multiplayer_spawner.spawn_limit = 999
	unit_multiplayer_spawner.spawn_function = _multiplayer_spawn_unit
	unit_multiplayer_spawner.spawn_path = NodePath("../SpawnedUnits")
	add_child(unit_multiplayer_spawner)

	spawn_timer = Timer.new()
	spawn_timer.name = "SpawnTimer"
	spawn_timer.wait_time = initial_cooldown
	spawn_timer.one_shot = true
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_spawn_wave)
	add_child(spawn_timer)

	return true


func _get_unit_level(wave_index: int, game_time: float) -> int:
	return unit_level + (unit_level_growth * wave_index) + int(unit_level_growth_time * game_time)


func _get_wave_cooldown() -> float:
	return wave_interval


func _get_wave_size(wave_number: int, _game_time: float) -> int:
	return wave_size + (wave_growth * wave_number)


func _on_unit_death(unit_name: String):
	var unit: Unit = null
	for _unit in spawned_units.get_children():
		if _unit.name == unit_name:
			unit = _unit as Unit
			break

	if not unit:
		print("Failed to get unit: " + unit_name)
		return

	spawned_units.remove_child(unit)
	unit.queue_free()

	current_unit_count -= 1

	if not require_clear:
		return

	if current_unit_count == 0:
		var next_cd = _get_wave_cooldown()
		print("Next wave in " + str(next_cd) + " seconds")
		spawn_timer.wait_time = next_cd
		spawn_timer.start()


func _spawn_wave():
	var spawn_time: float = map.time_elapsed

	var next_wave_size := _get_wave_size(current_wave, spawn_time)
	print("Spawning wave of " + str(next_wave_size) + " units")

	for i in range(next_wave_size):
		var spawn_args = {
			"unitType": unit_type,
			"name": name + "_wave_" + str(current_wave) + "_unit_" + str(i),
			"team": team,
			"index": i,
			"position": position,
			"level": _get_unit_level(current_wave, spawn_time),
		}

		get_tree().create_timer(i * 0.5).timeout.connect(
			unit_multiplayer_spawner.spawn.bind(spawn_args)
		)

	current_wave += 1

	if not require_clear:
		var next_cd := _get_wave_cooldown()
		print("Next wave in " + str(next_cd) + " seconds")
		spawn_timer.wait_time = next_cd
		spawn_timer.start()


func _multiplayer_spawn_unit(data: Dictionary):
	if data == null:
		print("Spawn data is null")
		return null

	if not data.has("unitType"):
		print("Spawn is missing type")
		return null

	var new_unit_data = RegistryManager.units().get_element(data["unitType"])
	if new_unit_data == null:
		print("Failed to get unit data")
		return

	var unit_name := data["name"] as String
	var new_unit := new_unit_data.spawn(data) as Unit
	if not new_unit:
		print("Something went wrong spawning unit: " + unit_name)
		return null

	new_unit.died.connect(_on_unit_death.bind(unit_name))

	if map == null:
		print("Map is null not setting it in spawner")
		return new_unit

	new_unit.map = map
	current_unit_count += 1
	return new_unit
