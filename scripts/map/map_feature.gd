extends Node3D
class_name MapFeature

var feature_type: String = ""
var feature_name: String = ""
var map: Node


static func spawn_feature(feature_data: Dictionary, parent: Node) -> bool:
	if not feature_data.has("type"):
		print("Feature is missing type")
		return false

	var feature = null
	match feature_data["type"]:
		"player_spawn":
			feature = PlayerSpawnerFeature.new()
		"unit_spawn":
			feature = UnitSpawnerFeature.new()
		_:
			print("Unknown feature type: " + feature_data["type"])
			return false

	if feature == null:
		print("Failed to create feature")
		return false

	if not feature.spawn(feature_data, parent):
		print("Failed to spawn feature")
		return false

	feature.map = parent
	parent.map_features.add_child(feature)

	return true


static func _get_child_node(node_name: String, parent: Node):
	var feature_node = null
	var feature_nodes = parent.find_children(node_name)
	for node in feature_nodes:
		if node.name == node_name:
			feature_node = node as Node3D
			if feature_node != null:
				break

	return feature_node


static func _get_position(node_name: String, parent: Node, fallback_data: Dictionary):
	var feature_node = _get_child_node(node_name, parent)
	if feature_node != null:
		var _pos := Vector3(feature_node.position)
		parent.remove_child(feature_node)
		return _pos

	var _position = Vector3(0, 0, 0)

	if fallback_data == null:
		return null

	var x = 0
	var y = 0
	var z = 0

	if fallback_data.has("x"):
		x = fallback_data["x"]

	if fallback_data.has("y"):
		y = fallback_data["y"]

	if fallback_data.has("z"):
		z = fallback_data["z"]

	_position = Vector3(x, y, z)

	return _position


func spawn(_feature_data: Dictionary, _parent: Node) -> bool:
	return false
