extends MapFeature
class_name PlayerSpawnerFeature

var team: int

var respawn_enabled: bool = true
var respawn_time: float = 30
var respawn_time_growth_level: float = 5
var respawn_time_growth_time: float = 0.1


func _init():
	feature_type = "player_spawn"


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

	var spawn_behaviour: Dictionary = feature_data["spawn_behaviour"]
	if spawn_behaviour.has("respawn_enabled"):
		respawn_enabled = bool(spawn_behaviour["respawn_enabled"])

	if spawn_behaviour.has("respawn_time"):
		respawn_time = float(spawn_behaviour["respawn_time"])

	if spawn_behaviour.has("respawn_time_growth_level"):
		respawn_time_growth_level = float(spawn_behaviour["respawn_time_growth_level"])

	if spawn_behaviour.has("respawn_time_growth_time"):
		respawn_time_growth_time = float(spawn_behaviour["respawn_time_growth_time"])

	position = _get_position(name, parent, feature_data)
	if position == null:
		print("Failed to get position")
		return false

	parent.player_spawns[str(team)] = self

	return true


func get_respawn_time(level: int, game_time: float) -> float:
	return (
		respawn_time + (level * respawn_time_growth_level) + (game_time * respawn_time_growth_time)
	)


func get_spawn_position(index: int = 0) -> Vector3:
	var rand = RandomNumberGenerator.new()
	rand.seed = int(index)

	var x = rand.randf_range(0, 5)
	var z = rand.randf_range(0, 5)

	return position + Vector3(x, 0, z)
