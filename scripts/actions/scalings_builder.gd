class_name ScalingsBuilder


static func build_scaling_function(scalings_spec: String):
	if scalings_spec == "":
		return null

	var tokens = scalings_spec.split(" ")

	var base_value = float(tokens[0])

	var base_scaling = func(_caster, _target) -> float: return base_value
	var base_display = func(_caster) -> String: return str(base_value)

	return hanlde_tokens(base_scaling, base_display, tokens.slice(1))


static func hanlde_tokens(value: Callable, display_func: Callable, remaining_tokens):
	if remaining_tokens.is_empty():
		return [value, display_func]

	if remaining_tokens.size() < 3:
		print("Not enough tokens to handle")
		return null

	var next_operator = remaining_tokens[0]
	var next_func = _get_next_scaled_stat(remaining_tokens.slice(1))

	if next_func == null:
		return null

	var next_operand = next_func[0]
	var next_display = next_func[1]

	var next_value
	var display_string
	match next_operator:
		"+":
			next_value = _add_functions(value, next_operand)
			display_string = "%s + %s"
		"-":
			next_value = _sub_functions(value, next_operand)
			display_string = "%s - %s"
		"*", "X", "x":
			next_value = _mul_functions(value, next_operand)
			display_string = "%s * %s"
		"/":
			next_value = _div_functions(value, next_operand)
			display_string = "%s / %s"
		_:
			print("Invalid operator")
			return null

	var next_display_func = _get_final_display_str.bind(display_string, display_func, next_display)
	return hanlde_tokens(next_value, next_display_func, remaining_tokens.slice(3))


static func _get_final_display_str(
	_caster, display_string: String, display_fun1: Callable, display_fun2
) -> String:
	return display_string % [display_fun1.call(_caster), display_fun2.call(_caster)]


static func _get_next_scaled_stat(tokens):
	if tokens.size() < 2:
		print("Not enough tokens to get next scaled stat")
		return null

	var next_scaling_value = float(tokens[0])
	var next_scaling_stat = str(tokens[1])

	var stat_spec = next_scaling_stat.split(".")

	if stat_spec.size() < 2:
		print("Invalid stat spec")
		return null

	var actor = null
	match stat_spec[0]:
		"c", "caster":
			actor = "caster"
		"t", "target":
			actor = "target"
		_:
			print("Invalid actor")
			return null

	var stat_set = null
	var stat_func = null
	var display_func = null

	match stat_spec[1]:
		"l", "lvl", "level":
			display_func = _get_level_translation(actor, next_scaling_value)
			stat_func = _get_final_level.bind(actor == "target", next_scaling_value)

			return [stat_func, display_func]
		"m", "max":
			stat_set = "max"
		"c", "curr", "current":
			stat_set = "current"
		"miss", "missing":
			stat_set = "missing"
		"b", "base":
			stat_set = "base"
		"bonus":
			stat_set = "bonus"
		_:
			print("Invalid stat set")
			return null

	if stat_spec.size() < 3:
		print("Invalid stat spec, no stat name found")
		return null

	var stat_name = StatCollection.get_full_stat_name(stat_spec[2])
	var stat_getter = StatCollection.get_stat_getter(stat_name)
	var final_stat_getter = create_unit_stat_getter_func(stat_set, stat_getter)

	display_func = _get_stat_translation(
		actor, stat_set, stat_name, next_scaling_value, final_stat_getter
	)
	stat_func = _get_final_stat.bind(actor == "target", next_scaling_value, final_stat_getter)

	return [stat_func, display_func]


static func _get_final_level(
	_caster, _target, get_target: bool, next_scaling_value: float
) -> float:
	var unit = _caster
	if get_target:
		unit = _target

	if unit == null:
		return 0.0

	return next_scaling_value * unit.level


static func _get_final_stat(
	_caster, _target, get_target: bool, next_scaling_value: float, final_stat_getter: Callable
) -> float:
	var unit = _caster
	if get_target:
		unit = _target

	if unit == null:
		return 0.0

	return next_scaling_value * final_stat_getter.call(unit)


static func create_unit_stat_getter_func(stat_set: String, stat_getter: Callable) -> Callable:
	var stat_set_getter: Callable
	match stat_set:
		"max":
			stat_set_getter = func(_unit) -> StatCollection: return _unit.maximum_stats
		"current":
			stat_set_getter = func(_unit) -> StatCollection: return _unit.current_stats
		"missing":
			stat_set_getter = _get_missing_stats
		"base":
			stat_set_getter = func(_unit) -> StatCollection: return _unit.base_stats
		"bonus":
			stat_getter = _get_bonus_stats
		_:
			print("Invalid stat set " + stat_set)
			return func(_unit) -> float: return 0.0

	return func(_unit) -> float: return stat_getter.call(stat_set_getter.call(_unit))


static func _get_missing_stats(unit) -> StatCollection:
	return StatCollection.subtract(unit.maximum_stats, unit.current_stats)


static func _get_bonus_stats(unit) -> StatCollection:
	var base_stats: StatCollection = unit.base_stats
	var current_stats: StatCollection = unit.current_stats
	var max_stats: StatCollection = unit.maximum_stats
	var highest_stats = StatCollection.max(max_stats, current_stats)
	return StatCollection.subtract(highest_stats, base_stats)


static func _get_stat_translation(
	actor: String, stat_set: String, stat_name: String, scaling_value: float, stat_getter: Callable
) -> Callable:
	return _get_final_stat_translation.bind(actor, stat_set, stat_name, scaling_value, stat_getter)


static func _get_final_stat_translation(
	_unit,
	actor: String,
	stat_set: String,
	stat_name: String,
	scaling_value: float,
	final_stat_getter: Callable
) -> String:
	var actor_trans = _tr("SCALING:ACTOR:" + actor)
	var stat_trans = _tr("STAT:" + stat_name + ":NAME")
	var set_trans = _tr("SCALING:STAT_SET:" + stat_set)

	var display_message = (
		_tr("SCALING:BY_STAT")
		% [
			scaling_value,
			actor_trans,
			set_trans,
			stat_trans,
		]
	)

	if actor != "caster":
		return display_message

	if _unit == null:
		return display_message

	var stat_value = float(final_stat_getter.call(_unit))
	display_message += (
		_tr("SCALING:VALUE_CALCULATION")
		% [
			scaling_value * stat_value,
			scaling_value,
			stat_value,
		]
	)

	return display_message


static func _get_level_translation(actor: String, scaling_value: float) -> Callable:
	return _get_final_level_translation.bind(actor, scaling_value)


static func _get_final_level_translation(_caster, actor: String, scaling_value: float) -> String:
	var actor_trans = _tr("SCALING:ACTOR:" + actor)

	var display_message = _tr("SCALING:BY_LEVEL") % [scaling_value, actor_trans]

	if actor != "caster":
		return display_message

	if _caster == null:
		return display_message

	display_message += (
		_tr("SCALING:VALUE_CALCULATION")
		% [scaling_value * _caster.level, scaling_value, _caster.level]
	)
	return display_message


static func _tr(message: String) -> String:
	return TranslationServer.translate(message)


static func _add_functions(fun1: Callable, fun2: Callable) -> Callable:
	return func(cst, tar) -> float: return fun1.call(cst, tar) + fun2.call(cst, tar)


static func _sub_functions(fun1: Callable, fun2: Callable) -> Callable:
	return func(cst, tar) -> float: return fun1.call(cst, tar) - fun2.call(cst, tar)


static func _mul_functions(fun1: Callable, fun2: Callable) -> Callable:
	return func(cst, tar) -> float: return fun1.call(cst, tar) * fun2.call(cst, tar)


static func _div_functions(fun1: Callable, fun2: Callable) -> Callable:
	return func(cst, tar) -> float: return fun1.call(cst, tar) / fun2.call(cst, tar)
