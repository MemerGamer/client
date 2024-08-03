class_name Item extends Object

var gold_cost: int = 0
var components: Array[String] = []
var item_tier: int = -1
var is_active: bool = false

var total_gold_cost: int = 0
var component_tree: Dictionary = {}

var stats = StatCollection.new()

var effects: Array[ActionEffect] = []

var id: Identifier
var texture_id: Identifier


func get_copy() -> Item:
	var new_item = Item.new(id, texture_id, gold_cost, components, stats)

	new_item.item_tier = item_tier
	new_item.total_gold_cost = total_gold_cost
	new_item.is_active = is_active
	new_item.effects = []
	for effect in effects:
		new_item.effects.append(effect.get_copy())

	# for now don't copy the component tree
	# It is very computationally expensive to copy the component tree and not used yet
	#new_item.component_tree = JsonHelper.dict_deep_copy(component_tree)

	return new_item


func get_id() -> Identifier:
	return id


func get_desctiption_strings(_caster: Unit = null) -> Dictionary:
	var item_descriptions = {}
	item_descriptions["name"] = tr("ITEM:%s:NAME" % id.to_string())
	item_descriptions["lore"] = tr("ITEM:%s:LORE" % id.to_string())
	item_descriptions["cost"] = tr("ITEM:COST_LABEL") % calculate_gold_cost()

	var stats_dict = stats.to_dict()
	var item_stat_string = ""
	for stat in stats_dict.keys():
		var stat_value = stats_dict[stat]
		if stat_value == 0:
			continue

		item_stat_string += tr("STAT:%s:NAME" % stat) + ": " + str(stats_dict[stat]) + "\n"

	item_descriptions["stats"] = item_stat_string

	var effect_string = ""
	for effect in effects:
		effect_string += effect.get_description_string(_caster) + "\n"

	item_descriptions["effects"] = effect_string

	return item_descriptions


func get_tooltip_string(_caster: Unit = null) -> String:
	var item_desctiptions = get_desctiption_strings(_caster)

	if effects.is_empty():
		return (
			"%s\n%s\n\n%s\n%s"
			% [
				item_desctiptions["name"],
				item_desctiptions["lore"],
				item_desctiptions["stats"],
				item_desctiptions["cost"]
			]
		)
	else:
		return (
			"%s\n%s\n\n%s\n%s\n%s"
			% [
				item_desctiptions["name"],
				item_desctiptions["lore"],
				item_desctiptions["stats"],
				item_desctiptions["effects"],
				item_desctiptions["cost"]
			]
		)


func get_texture_resource() -> Identifier:
	if texture_id.is_valid():
		if AssetIndexer.get_asset_path(texture_id) != "":
			return texture_id

	print("Item (%s): Texture asset not found." % id.to_string())
	return Identifier.for_resource("texture://openchamp:placeholder")


func get_stats() -> StatCollection:
	return stats


func get_combine_cost() -> int:
	return gold_cost


func calculate_gold_cost() -> int:
	if total_gold_cost > 0:
		return total_gold_cost

	var cost = gold_cost
	for component in components:
		var item = RegistryManager.items().get_element(component)
		if item == null:
			print("Item (%s): Component item not found." % component)
			continue

		cost += item.calculate_gold_cost()

	return cost


func get_component_tree() -> Dictionary:
	if total_gold_cost == 0:
		var components_trees: Array[Dictionary] = []
		total_gold_cost = gold_cost

		for component in components:
			var item = RegistryManager.items().get_element(component)
			if item == null:
				print("Item (%s): Component item not found." % component)
				continue

			components_trees.append(item.get_component_tree())
			total_gold_cost += item.calculate_gold_cost()

		component_tree["combine_cost"] = gold_cost
		component_tree["components"] = components_trees
		component_tree["resulting_item"] = id.to_string()

	return component_tree


func try_purchase(owned_items: Array[Item]) -> Dictionary:
	if owned_items == null:
		return {"cost": calculate_gold_cost(), "owned_items": owned_items}

	var shadow_inventory: Array[Item] = []
	for item in owned_items:
		shadow_inventory.append(item.get_copy())

	var remaining_cost = gold_cost
	for component in components:
		var found = false
		for shadow_item in shadow_inventory:
			if shadow_item.get_id().to_string() == component:
				shadow_inventory.erase(shadow_item)
				found = true
				break

		if not found:
			var item = RegistryManager.items().get_element(component)
			if item == null:
				print("Item (%s): Component item not found." % component)
				continue

			var tried_purchase = item.try_purchase(shadow_inventory)
			shadow_inventory = tried_purchase["owned_items"]
			remaining_cost += tried_purchase["cost"]

	return {"cost": remaining_cost, "owned_items": shadow_inventory}


func is_valid(item_registry: RegistryBase = null) -> bool:
	# This is a fast pass to avoid checking the item's components if it's already been validated
	# By default the item_tier is set to -1, so if it's not negative, it's already been validated
	if item_tier >= 0:
		return true

	if item_registry == null:
		item_registry = RegistryManager.items()

	if not id.is_valid():
		return false

	if not texture_id.is_valid():
		return false

	if gold_cost < 0:
		return false

	var highest_tier = -1
	if components.size() > 0:
		for component in components:
			if not Identifier.from_string(component).is_valid():
				return false

			if not item_registry.contains(component):
				return false

			var comp_item = item_registry.get_element(component)
			if comp_item.item_tier < 0:
				if not comp_item.is_valid(item_registry):
					return false

			if comp_item.item_tier > highest_tier:
				highest_tier = comp_item.item_tier

	get_component_tree()
	item_tier = highest_tier + 1

	return true


func _init(
	_id: Identifier,
	_texture_id: Identifier,
	_gold_cost: int,
	_components: Array[String],
	_stats: StatCollection
):
	id = _id
	texture_id = _texture_id
	gold_cost = _gold_cost
	components = _components
	stats = _stats
