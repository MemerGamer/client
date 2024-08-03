class_name ItemRegistry
extends RegistryBase

@export var highest_item_tier: int = -1

var _internal_values: Dictionary = {}


func _init():
	_json_type = "item"


func contains(_item: String) -> bool:
	return _internal_values.has(_item)


func get_element(_item: String):
	if not contains(_item):
		print("Item (%s): Item not found in item registry." % _item)
		return null

	return _internal_values[_item]


func get_all_where(condition: Callable) -> Array[Item]:
	var item_list: Array[Item] = []
	var all_items = _internal_values.values()
	for _item in all_items:
		if condition.call(_item):
			item_list.append(_item)

	return item_list


func get_all_in_tier(searched_tier: int) -> Array[Item]:
	if searched_tier > highest_item_tier:
		return []

	return get_all_where(func(_item: Item) -> bool: return _item.item_tier == searched_tier)


func assure_validity():
	var item_names = _internal_values.keys()
	for item_name in item_names:
		var item: Item = _internal_values[item_name]
		if not item.is_valid(self):
			print("Item (%s): Invalid item." % item_name)
			_internal_values.erase(item_name)

		if item.item_tier > highest_item_tier:
			highest_item_tier = item.item_tier


func load_from_json(_json: Dictionary) -> bool:
	if not can_load_from_json(_json):
		print("Wrong JSON type.")
		return false

	if not _json.has("data"):
		print("Item: No data object provided.")
		return false

	var raw_json_data = _json["data"] as Dictionary
	if raw_json_data == null:
		print("Item: Data object is not a dictionary.")
		return false

	if not raw_json_data.has("id"):
		print("Item: No name provided.")
		return false

	var item_id_str := str(raw_json_data["id"])
	var item_id := Identifier.from_string(item_id_str)

	if contains(item_id_str):
		print("Item (%s): Item already exists in item registry." % item_id_str)
		return false

	if not raw_json_data.has("texture"):
		print("Item (%s): No texture provided." % item_id_str)
		return false

	var texture_id := Identifier.for_resource("texture://" + str(raw_json_data["texture"]))

	if not raw_json_data.has("recipe"):
		print("Item (%s): No recipe provided." % item_id_str)
		return false

	if not raw_json_data["recipe"].has("gold_cost"):
		print("Item (%s): No gold cost provided." % item_id_str)
		return false

	var gold_cost := int(raw_json_data["recipe"]["gold_cost"])
	var components: Array[String] = []

	if raw_json_data["recipe"].has("components"):
		var comps = raw_json_data["recipe"]["components"]
		if not (comps is Array):
			print("Item (%s): Components must be an array." % item_id_str)
			return false

		for comp in comps:
			components.append(str(comp))

	if not raw_json_data.has("stats"):
		print("Item (%s): No stats provided." % item_id_str)
		return false

	var raw_stats = raw_json_data["stats"]
	if not (raw_stats is Dictionary):
		print("Item (%s): Stats must be a dictionary." % item_id_str)
		return false

	var stats = StatCollection.from_dict(raw_stats)

	var loaded_effects: Array[ActionEffect] = []
	if raw_json_data.has("effects"):
		var raw_effects = raw_json_data["effects"]

		if not (raw_effects is Array):
			print("Item (%s): Effects must be an array." % item_id_str)
			return false

		for raw_effect in raw_effects:
			var effect = ActionEffect.from_dict(raw_effect)
			if effect == null:
				print("Item (%s): Could not load effect." % item_id_str)
				return false

			loaded_effects.append(effect)

	var new_item = Item.new(item_id, texture_id, gold_cost, components, stats)
	new_item.effects = loaded_effects

	_internal_values[item_id_str] = new_item

	return true
