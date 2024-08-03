extends Node

@export var _map: Node

@onready var player_icon = $CharacterUI/PortraitBorder/Portrait
@onready var money_count = $GameStats/Money
@onready var kda_display = $GameStats/KDA
@onready var cs_display = $GameStats/CS

@onready var hp_bar = $CharacterUI/HealthMana/HealthBar
@onready var mana_bar = $CharacterUI/HealthMana/ManaBar

@onready var player_display = $CharacterUI/Level
@onready var player_level_number = $CharacterUI/Level/LevelNumber

@onready var spells_container = $CharacterUI/Items/HBoxContainer/SpellsPanel/SpellsContainer
@onready var active_items_container = $CharacterUI/Items/HBoxContainer/ActiveItemPanel/ActiveItemGrid
@onready
var passive_items_container = $CharacterUI/Items/HBoxContainer/PassiveItemPanel/PassiveItemGrid

const item_box_scene = preload("res://ui/player_stats/item_box_base.tscn")
const item_icon_size = Vector2(24, 24)

var _character

var waiting_for_character = false
var first_draw_iteration = true


func _ready() -> void:
	if Config.is_dedicated_server:
		return

	if _map == null:
		print("map not set")
		return

	# Todo get the current player and set the icons to the
	# the ones for the actual character of the current player
	call_deferred("_set_icons")


func _process(_delta: float) -> void:
	if Config.is_dedicated_server:
		return

	if waiting_for_character:
		return

	if _character == null:
		call_deferred("_set_icons")
		return

	money_count.text = str(_character.current_gold)
	kda_display.text = (
		str(_character.kills) + "/" + str(_character.deaths) + "/" + str(_character.assists)
	)
	cs_display.text = str(_character.minion_kills)

	hp_bar.value = _character.current_stats.health
	hp_bar.max_value = _character.maximum_stats.health

	mana_bar.value = _character.current_stats.mana
	mana_bar.max_value = _character.maximum_stats.mana

	player_level_number.text = str(_character.level)
	player_display.tooltip_text = (
		"XP: " + str(_character.level_exp) + "/" + str(_character.required_exp)
	)

	if _character.items_changed or first_draw_iteration:
		_character.items_changed = false
		first_draw_iteration = false
		_update_items()


func _update_items():
	var passive_item_icons = passive_items_container.get_children()
	for item in passive_item_icons:
		passive_items_container.remove_child(item)
		item.queue_free()

	for index in range(_character.passive_item_slots):
		var item_box: Node = null
		if index < _character.item_slots_passive.size():
			var item = _character.item_slots_passive[index] as Item
			var icon = _get_item_texture(item)
			if icon != null:
				item_box = _create_item_box(icon, item.get_tooltip_string(_character), "")

		if item_box == null:
			item_box = _create_item_box(null, "", "")
			if item_box == null:
				print("Failed to create item box")
				continue

		passive_items_container.add_child(item_box)

	pass


func _get_item_texture(item: Item = null) -> Texture2D:
	if item == null:
		return null

	var icon_id = item.get_texture_resource() as Identifier
	if icon_id == null or not icon_id.is_valid():
		return null

	var icon_path = AssetIndexer.get_asset_path(icon_id)
	if icon_path == "":
		return null

	var icon = load(icon_path)
	if icon == null:
		return null

	return icon


func _create_item_box(icon: Texture2D, tooltip: String, text: String):
	var item_box = item_box_scene.instantiate()
	if item_box == null:
		print("Failed to instantiate item box")
		return null

	var item_box_bg = item_box.get_node("AspectBox/Background")
	if item_box_bg == null:
		print("Failed to get item box bg")
		return item_box

	if icon != null:
		var item_box_icon = TextureRect.new()
		item_box_icon.texture = icon
		item_box_icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
		item_box_icon.stretch_mode = TextureRect.STRETCH_SCALE
		item_box_icon.custom_minimum_size = item_icon_size

		if tooltip != "":
			item_box_icon.tooltip_text = tooltip
			item_box_icon.mouse_filter = Control.MOUSE_FILTER_PASS

		item_box_bg.add_child(item_box_icon)

	if text != "":
		var item_box_label = RichTextLabel.new()
		item_box_label.text = text
		item_box_bg.add_child(item_box_label)

	return item_box


func _set_icons():
	if waiting_for_character:
		return

	waiting_for_character = true

	while _character == null:
		var _char = _map.get_character(multiplayer.get_unique_id())
		if typeof(_char) == TYPE_BOOL:
			print("Character not found")
		elif _char != null:
			_character = _char
			break

		print("Character not found")

	var player_icon_id = RegistryManager.units().get_element(_character.unit_id).get_icon_id()
	if player_icon_id == null:
		print("Icon not found")
		return

	var _player_icon = load(player_icon_id.get_resource_id())
	if _player_icon == null:
		print("Icon not loaded")
		return

	player_icon.texture = _player_icon

	if _character.has_mana:
		mana_bar.show()
	else:
		mana_bar.hide()

	player_display.mouse_filter = Control.MOUSE_FILTER_STOP

	waiting_for_character = false
