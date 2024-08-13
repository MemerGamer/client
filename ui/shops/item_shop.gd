extends Control

@onready var item_lists_container: BoxContainer = $ScrollContainer/ItemListsContainer

var player_instance: Node

var hover_sound_player : AudioStreamPlayer
var click_sound_player : AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var hover_sound := load("audio://openchamp:sfx/hover_button_1")
	if not hover_sound:
		print("error loading hover sound")
		return
	
	hover_sound_player = AudioStreamPlayer.new()
	hover_sound_player.name = "UIHoverSoundPlayer"
	hover_sound_player.stream = hover_sound
	hover_sound_player.bus = "MenuSfx"
	
	add_child(hover_sound_player)
	
	var click_sound := load("audio://openchamp:sfx/button_press_1")
	
	click_sound_player = AudioStreamPlayer.new()
	click_sound_player.name = "UIClickSoundPlayer"
	click_sound_player.stream = click_sound
	click_sound_player.bus = "MenuSfx"
	
	add_child(click_sound_player)
	
	
	var item_tiers: int = RegistryManager.items().highest_item_tier
	print("Item tiers in shop: %d" % item_tiers)

	if item_tiers < 0:
		print("no valid item in registry, can't show shop")
		return

	for item_tier in range(item_tiers + 1):
		var all_in_tier: Array[Item] = RegistryManager.items().get_all_in_tier(item_tier)

		if all_in_tier.is_empty():
			continue

		item_lists_container.add_child(HSeparator.new())
		var tier_label = Label.new()
		tier_label.name = "Item_tier_label_%d" % item_tier
		tier_label.text = "Tier %d" % item_tier
		item_lists_container.add_child(tier_label)

		item_lists_container.add_child(HSeparator.new())

		var _item_tier_box = FlowContainer.new()
		_item_tier_box.name = "Item_tier_flow_%d" % item_tier

		for _item in all_in_tier:
			var texture_resource = _item.get_texture_resource()
			var raw_texture_path = AssetIndexer.get_asset_path(texture_resource)
			var item_texture = load(raw_texture_path)
			if item_texture == null:
				print(
					(
						"Item (%s): Texture (%s) not found. Tried loading (%s)"
						% [_item.id.to_string(), texture_resource.to_string(), raw_texture_path]
					)
				)
				continue

			var item_image := TextureRect.new()
			item_image.texture = item_texture
			item_image.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
			item_image.stretch_mode = TextureRect.STRETCH_SCALE
			item_image.tooltip_text = _item.get_tooltip_string()

			var item_container := AspectRatioContainer.new()
			item_container.size = Vector2(64, 64)
			item_container.custom_minimum_size = Vector2(64, 64)
			item_container.mouse_filter = Control.MOUSE_FILTER_STOP

			var item_id_str = _item.get_id().to_string()
			item_container.name = item_id_str
			item_container.gui_input.connect(
				func asset_callback(input_event): try_purchase_item(input_event, item_id_str)
			)

			item_container.add_child(item_image)
			item_container.mouse_entered.connect(func(): hover_sound_player.play())

			_item_tier_box.add_child(item_container)

		item_lists_container.add_child(_item_tier_box)

		if item_tier != item_tiers:
			item_lists_container.add_child(HSeparator.new())

	item_lists_container.add_child(HSeparator.new())
	item_lists_container.add_spacer(false)

	hide()


func try_purchase_item(input_event, item_name: String) -> void:
	if not (input_event is InputEventMouseButton):
		return

	if input_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not input_event.is_pressed():
		return
	
	click_sound_player.play()

	var item = RegistryManager.items().get_element(item_name) as Item
	if item == null:
		print("Item (%s) not found in registry." % item_name)
		return

	print("Request purchase of item (%s) from server" % item_name)
	player_instance.try_purchasing_item(item_name)


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("player_open_shop"):
		return

	if visible:
		hide()
		Config.in_focued_menu = false
	else:
		# make sure we aren't already in a different menu
		if Config.in_focued_menu:
			return

		show()
		Config.in_focued_menu = true
