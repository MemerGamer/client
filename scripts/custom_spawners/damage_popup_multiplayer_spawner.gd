class_name DamagePopupMultiplayerSpawner
extends MultiplayerSpawner

const DmgPopupScene = preload("res://scenes/effects/damage_popup.tscn")


func _spawn_damage_popup(args):
	var spawn_args = args as Dictionary

	if not spawn_args:
		print("Error damage popup spawn args could now be parsed as dict!")
		return null

	var new_popup = DmgPopupScene.instantiate()
	new_popup.spawn_position = spawn_args["position"] as Vector3
	new_popup.damage_value = int(spawn_args["value"])
	new_popup.damage_type = spawn_args["type"]

	return new_popup


func _ready() -> void:
	var damage_popup_node = Node.new()
	damage_popup_node.name = "DamagePopups"
	add_child(damage_popup_node)

	spawn_path = NodePath("DamagePopups")
	spawn_limit = 999
	spawn_function = _spawn_damage_popup
