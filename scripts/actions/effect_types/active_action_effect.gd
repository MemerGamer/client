class_name ActiveActionEffect
extends ActionEffect

var attack_speed_scaled: bool = false
var windup_ratio: float = 0.2

var in_casting_preview: bool = false
var casting_range: float = 0.0
var use_attack_range: bool = false

var channel_time: float = 0.0
var active_time: float = 0.0
var cooldown_time: float = 0.0

var channeling_timer := Timer.new()
var active_timer := Timer.new()
var cooldown_timer := Timer.new()

var _current_haste: float = 0.0


func init_from_dict(_dict: Dictionary, _is_ability: bool = false) -> bool:
	attack_speed_scaled = JsonHelper.get_optional_bool(_dict, "as_scaled", false)
	windup_ratio = JsonHelper.get_optional_number(_dict, "windup_ratio", 0.0)

	if not attack_speed_scaled:
		if not _dict.has("cooldown"):
			print(
				"Could not create ActiveActionEffect from dictionary. Dictionary is missing required keys."
			)
			return false

	use_attack_range = JsonHelper.get_optional_bool(_dict, "use_attack_range", false)
	casting_range = JsonHelper.get_optional_number(_dict, "casting_range", 0.0)

	cooldown_time = JsonHelper.get_optional_number(_dict, "cooldown", 0.0)
	channel_time = JsonHelper.get_optional_number(_dict, "channel_time", 0.0)
	active_time = JsonHelper.get_optional_number(_dict, "active_time", 0.0)

	_activation_state = ActivationState.READY

	return true


func get_copy(new_effect: ActionEffect = null) -> ActionEffect:
	if new_effect == null:
		new_effect = ActiveActionEffect.new()

	new_effect = super(new_effect)

	new_effect.attack_speed_scaled = attack_speed_scaled
	new_effect.windup_ratio = windup_ratio

	new_effect.in_casting_preview = in_casting_preview
	new_effect.casting_range = casting_range
	new_effect.use_attack_range = use_attack_range

	new_effect.channel_time = channel_time
	new_effect.active_time = active_time
	new_effect.cooldown_time = cooldown_time

	return new_effect


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
			return _start_targeting(caster)

		ActivationState.TARGETING:
			return _finish_targeting(caster, target)

		_:
			print("Could not activate ability. Unknown activation state.")
			return false


func _start_targeting(caster: Unit) -> bool:
	_activation_state = ActivationState.TARGETING
	if _ability_type == AbilityType.AUTO_TARGETED:
		return _finish_targeting(caster, null)

	return true


func _finish_targeting(caster: Unit, target) -> bool:
	return _start_channeling(caster, target)


func _start_channeling(caster: Unit, target) -> bool:
	_activation_state = ActivationState.CHANNELING

	if attack_speed_scaled:
		var attack_time = float(100.0 / caster.current_stats.attack_speed)
		channeling_timer.set_wait_time(attack_time * windup_ratio)
		cooldown_timer.set_wait_time(attack_time * (1.0 - windup_ratio))

	channeling_timer.timeout.connect(func(): _finish_channeling(caster, target))
	channeling_timer.start()
	return true


func _finish_channeling(caster: Unit, target) -> void:
	var target_unit = target as Unit
	if target_unit:
		caster.targeted_cast_finished.emit(caster, target_unit, _effect_source)

	_start_active(caster, target)


func _start_active(caster: Unit, _target) -> void:
	if active_time <= 0.001:
		_finish_active(caster, _target)
		return

	_activation_state = ActivationState.ACTIVE
	active_timer.timeout.connect(func(): _finish_active(caster, _target))
	active_timer.start()


func _finish_active(caster: Unit, _target) -> void:
	_current_haste = float(caster.current_stats.ability_haste)
	_start_cooldown()


func _start_cooldown() -> void:
	_activation_state = ActivationState.COOLDOWN

	if not attack_speed_scaled:
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
	if cooldown_time > 0.0:
		cooldown_timer.set_wait_time(cooldown_time)
	cooldown_timer.name = "Cooldown Timer"
	cooldown_timer.set_one_shot(true)
	cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(cooldown_timer)

	if active_time > 0.0:
		active_timer.set_wait_time(active_time)
	active_timer.name = "Active Timer"
	active_timer.set_one_shot(true)
	add_child(active_timer)

	if channel_time > 0.0:
		channeling_timer.set_wait_time(channel_time)
	channeling_timer.name = "Channeling Timer"
	channeling_timer.set_one_shot(true)
	add_child(channeling_timer)
