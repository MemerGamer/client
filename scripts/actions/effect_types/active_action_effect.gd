class_name ActiveActionEffect
extends ActionEffect

var in_casting_preview: bool = false

var channel_time: float = 0.0
var active_time: float = 0.0
var cooldown_time: float = 0.0

var channeling_timer := Timer.new()
var active_timer := Timer.new()
var cooldown_timer := Timer.new()

var _current_haste: float = 0.0


func init_from_dict(_dict: Dictionary) -> bool:
	if not _dict.has("cooldown"):
		print(
			"Could not create ActiveActionEffect from dictionary. Dictionary is missing required keys."
		)
		return false

	cooldown_time = float(_dict["cooldown"])
	channel_time = JsonHelper.get_optional_number(_dict, "channel_time", 0.0)
	active_time = JsonHelper.get_optional_number(_dict, "active_time", 0.0)

	return true


func start_preview_cast(_caster: Unit) -> void:
	print("Not implemented. Needs to be implemented in the subclass.")


func stop_preview_cast(_caster: Unit) -> void:
	print("Not implemented. Needs to be implemented in the subclass.")


func activate(caster: Unit, target) -> bool:
	match _activation_state:
		ActivationState.NONE:
			print("Could not activate ability. Ability has no activation state.")
			return false

		ActivationState.COOLDOWN, ActivationState.CHANNELING, ActivationState.ACTIVE:
			return false

		ActivationState.READY:
			_start_targeting(caster)
			return true

		ActivationState.TARGETING:
			_finish_targeting(caster, target)
			return true

		_:
			print("Could not activate ability. Unknown activation state.")
			return false


func _start_targeting(caster: Unit) -> void:
	_activation_state = ActivationState.TARGETING
	if _ability_type == AbilityType.AUTO_TARGETED:
		_finish_targeting(caster, null)


func _finish_targeting(caster: Unit, target) -> void:
	_start_channeling(caster, target)


func _start_channeling(caster: Unit, target) -> void:
	_activation_state = ActivationState.CHANNELING
	channeling_timer.timeout.connect(func(): _finish_channeling(caster, target))
	channeling_timer.start()


func _finish_channeling(caster: Unit, target) -> void:
	_activation_state = ActivationState.ACTIVE
	_start_active(caster, target)


func _start_active(caster: Unit, _target) -> void:
	_activation_state = ActivationState.ACTIVE
	active_timer.timeout.connect(func(): _finish_active(caster, _target))
	active_timer.start()


func _finish_active(caster: Unit, _target) -> void:
	_current_haste = float(caster.current_stats.ability_haste)
	_start_cooldown()


func _start_cooldown() -> void:
	_activation_state = ActivationState.COOLDOWN
	var ability_rate: float = 1.0 + _current_haste / 100.0

	cooldown_timer.set_wait_time(cooldown_time / ability_rate)
	cooldown_timer.start()


func _on_cooldown_finished() -> void:
	_activation_state = ActivationState.READY


func connect_to_unit(_unit: Unit) -> void:
	_unit.current_stats_changed.connect(_update_haste)


func disconnect_from_unit(_unit: Unit) -> void:
	_unit.current_stats_changed.disconnect(_update_haste)


func _update_haste(_old_stats: StatCollection, new_stats: StatCollection) -> void:
	_current_haste = float(new_stats.ability_haste)


func _ready() -> void:
	cooldown_timer.set_wait_time(cooldown_time)
	cooldown_timer.name = "Cooldown Timer"
	cooldown_timer.set_one_shot(true)
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(cooldown_timer)

	active_timer.set_wait_time(active_time)
	active_timer.name = "Active Timer"
	active_timer.set_one_shot(true)
	add_child(active_timer)

	channeling_timer.set_wait_time(channel_time)
	channeling_timer.name = "Channeling Timer"
	channeling_timer.set_one_shot(true)
	add_child(channeling_timer)
