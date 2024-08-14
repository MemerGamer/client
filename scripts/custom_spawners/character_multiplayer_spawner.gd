class_name CharacterMultiplayerSpawner
extends MultiplayerSpawner

var map_death_func: Callable

var character_container: Node


func _spawn_character(args):
	var spawn_args = args as Dictionary

	if not spawn_args:
		print("Error character spawn args could now be parsed as dict!")
		return null

	print("loading character:" + spawn_args["character"])

	var char_data = RegistryManager.units().get_element(spawn_args["character"]) as UnitData
	if not char_data:
		print("Error character data could not be found in registry!")
		return null

	if not char_data.is_character:
		print("Error character data is not a character!")
		return null

	var new_char = char_data.spawn(spawn_args)

	if multiplayer.is_server():
		new_char.died.connect(func(): map_death_func.call(spawn_args["id"]))

	return new_char


func _ready() -> void:
	character_container = Node.new()
	character_container.name = "Characters"
	add_child(character_container)

	spawn_path = NodePath("Characters")
	spawn_limit = 50
	spawn_function = _spawn_character
