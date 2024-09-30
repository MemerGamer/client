extends Control

const UI_SOUND_SET: int = 2

var player_instance: Node

var hover_sound_player: AudioStreamPlayer
var buy_success_sound_player: AudioStreamPlayer
var buy_reject_sound_player: AudioStreamPlayer

var _focus_item: Control

@onready var item_lists_container: BoxContainer = $ScrollContainer/ItemListsContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var hover_sound := load("audio://openchamp:sfx/ui_%d/button_hover" % UI_SOUND_SET)
	if not hover_sound:
		print("error loading hover sound")
		return

	hover_sound_player = AudioStreamPlayer.new()
	hover_sound_player.name = "UIHoverSoundPlayer"
	hover_sound_player.stream = hover_sound
	hover_sound_player.bus = "MenuSfx"

	add_child(hover_sound_player)

	var click_sound := load("audio://openchamp:sfx/ui_%d/button_press" % UI_SOUND_SET)

	buy_success_sound_player = AudioStreamPlayer.new()
	buy_success_sound_player.name = "UIBuySuccessSoundPlayer"
	buy_success_sound_player.stream = click_sound
	buy_success_sound_player.bus = "MenuSfx"

	add_child(buy_success_sound_player)

	var reject_sound := load("audio://openchamp:sfx/ui_%d/button_reject" % UI_SOUND_SET)

	buy_reject_sound_player = AudioStreamPlayer.new()
	buy_reject_sound_player.name = "UIBuyRejectSoundPlayer"
	buy_reject_sound_player.stream = reject_sound
	buy_reject_sound_player.bus = "MenuSfx"

	add_child(buy_reject_sound_player)

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

		var item_tier_flow_box = FlowContainer.new()
		item_tier_flow_box.name = "Item_tier_flow_%d" % item_tier

		for _item in all_in_tier:
			var texture_resource = _item.get_texture_resource()
			var raw_texture_path = AssetIndexer.get_asset_path(texture_resource)
			var raw_item_texture = load(raw_texture_path) as Texture2D
			if raw_item_texture == null:
				print(
					(
						"Item (%s): Texture (%s) not found. Tried loading (%s)"
						% [_item.id.to_string(), texture_resource.to_string(), raw_texture_path]
					)
				)
				continue

			var item_texture = ImageTexture.create_from_image(raw_item_texture.get_image())
			item_texture.set_size_override(Vector2i(64, 64))

			var item_button := Button.new()
			item_button.tooltip_text = _item.get_tooltip_string()

			var item_id_str = _item.get_id().to_string()
			item_button.name = item_id_str
			item_button.pressed.connect(try_purchase_item.bind(item_id_str))

			item_button.mouse_entered.connect(func(): hover_sound_player.play())
			item_button.focus_entered.connect(func(): hover_sound_player.play())
			item_button.focus_mode = Control.FOCUS_ALL

			item_button.icon = item_texture

			item_tier_flow_box.add_child(item_button)

			if not _focus_item:
				_focus_item = item_button

		item_lists_container.add_child(item_tier_flow_box)

		if item_tier != item_tiers:
			item_lists_container.add_child(HSeparator.new())

	item_lists_container.add_child(HSeparator.new())
	item_lists_container.add_spacer(false)

	if not _focus_item:
		_focus_item = self

	hide()


func try_purchase_item(item_name: String) -> void:
	hover_sound_player.stop()

	var item = RegistryManager.items().get_element(item_name) as Item
	if item == null:
		print("Item (%s) not found in registry." % item_name)
		buy_reject_sound_player.play()
		return

	print("Request purchase of item (%s) from server" % item_name)
	if player_instance.try_purchasing_item(item_name):
		buy_success_sound_player.play()
	else:
		buy_reject_sound_player.play()


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
		_focus_item.grab_focus.call_deferred()
		Config.in_focued_menu = true
