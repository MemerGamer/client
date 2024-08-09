## This class is used to store all the stats of a unit.
## All stats are stored as integers to prevent floating point errors.
class_name StatCollection
extends Object

## The actual health value of the unit.
@export var health: int = 0
## The amount of health the unit regenerates per 5 seconds.
@export var health_regen: int = 0

## The actual mana value of the unit.
@export var mana: int = 0
## The amount of mana the unit regenerates per 5 seconds.
@export var mana_regen: int = 0

## The physical damage reduction of the unit.
@export var armor: int = 0
## The magic damage reduction of the unit.
@export var magic_resist: int = 0

## The amount of flat armor penetration the unit has.
@export var armor_pen_flat: int = 0
## The amount of percentage armor penetration the unit has. (0 - 100)
@export var armor_pen_percent: int = 0

## The amount of flat magic penetration the unit has.
@export var magic_pen_flat: int = 0
## The amount of percentage magic penetration the unit has. (0 - 100)
@export var magic_pen_percent: int = 0

## The amount of physical damage the unit deals.
@export var attack_damage: int = 0
## The attack speed of the unit.
## Because of we need to use int for everything to prevent floating point errors,
## the attack speed is stored as 100 times the expected float value.
## This means that values below 100 are less than 1 attack per second,
## and values above 100 are more than 1 attack per second.
## Every 100 points is 1 attack per second.
@export var attack_speed: int = 0
## The attack range of the unit in centimeters.
## 100 centimeters is 1 meter for those now fluent in the metric system.
@export var attack_range: int = 0
## The chance of the unit to deal a critical strike in percentage (0 - 100).
@export var attack_crit_chance: int = 0
## The amount of bonus damage the unit deals on a critical strike in percentage (> 0)
@export var attack_crit_damage: int = 0

## The amount of ability power the unit has.
## Ability power is used to increase the damage of abilities that scale with ability power.
@export var ability_power: int = 0
## The amount of ability haste the unit has.
## Ability haste is used to reduce the cooldown of abilities.
## Every 100 points of ability haste allow the unit to cast the ability one more time per stock cooldown.
## For example, if an ability has a stock cooldown of 10 seconds and the unit has 100 ability haste,
## the ability will be available every 5 seconds, if the unit has 200 ability haste, the ability will be available every 3.33 seconds.
@export var ability_haste: int = 0

## The percentage of post-mitigation damage dealt by the unit that is returned as healing (0-100).
## To calculate the actual percentage the omnivamp value is added to the physical, magic and true vamp values depending on the damage type.
@export var omnivamp: int = 0
## The percentage of post-mitigation physical damage dealt by the unit that is returned as healing (0-100).
@export var physical_vamp: int = 0
## The percentage of post-mitigation magic damage dealt by the unit that is returned as healing (0-100).
@export var magic_vamp: int = 0
## The percentage of post-mitigation true damage dealt by the unit that is returned as healing (0-100).
@export var true_vamp: int = 0

## The movement speed of the unit in centimeters per second.
@export var movement_speed: int = 0


static func from_dict(json_data_object: Dictionary) -> StatCollection:
	var stat = StatCollection.new()

	stat.health = JsonHelper.get_optional_int(json_data_object, "health", 0)
	stat.health_regen = JsonHelper.get_optional_int(json_data_object, "health_regen", 0)

	stat.mana = JsonHelper.get_optional_int(json_data_object, "mana", 0)
	stat.mana_regen = JsonHelper.get_optional_int(json_data_object, "mana_regen", 0)

	stat.armor = JsonHelper.get_optional_int(json_data_object, "armor", 0)
	stat.magic_resist = JsonHelper.get_optional_int(json_data_object, "magic_resist", 0)

	stat.armor_pen_flat = JsonHelper.get_optional_int(json_data_object, "armor_pen_flat", 0)
	stat.armor_pen_percent = JsonHelper.get_optional_int(json_data_object, "armor_pen_percent", 0)

	stat.magic_pen_flat = JsonHelper.get_optional_int(json_data_object, "magic_pen_flat", 0)
	stat.magic_pen_percent = JsonHelper.get_optional_int(json_data_object, "magic_pen_percent", 0)

	stat.attack_damage = JsonHelper.get_optional_int(json_data_object, "attack_damage", 0)
	stat.attack_speed = JsonHelper.get_optional_int(json_data_object, "attack_speed", 0)
	stat.attack_range = JsonHelper.get_optional_int(json_data_object, "attack_range", 0)
	stat.attack_crit_chance = JsonHelper.get_optional_int(json_data_object, "attack_crit_chance", 0)
	stat.attack_crit_damage = JsonHelper.get_optional_int(json_data_object, "attack_crit_damage", 0)

	stat.ability_power = JsonHelper.get_optional_int(json_data_object, "ability_power", 0)
	stat.ability_haste = JsonHelper.get_optional_int(json_data_object, "ability_haste", 0)

	stat.omnivamp = JsonHelper.get_optional_int(json_data_object, "omnivamp", 0)
	stat.physical_vamp = JsonHelper.get_optional_int(json_data_object, "physical_vamp", 0)
	stat.magic_vamp = JsonHelper.get_optional_int(json_data_object, "magic_vamp", 0)
	stat.true_vamp = JsonHelper.get_optional_int(json_data_object, "true_vamp", 0)

	stat.movement_speed = JsonHelper.get_optional_int(json_data_object, "movement_speed", 0)

	return stat


func to_dict() -> Dictionary:
	var json_data_object = {}

	json_data_object["health"] = health
	json_data_object["health_regen"] = health_regen

	json_data_object["mana"] = mana
	json_data_object["mana_regen"] = mana_regen

	json_data_object["armor"] = armor
	json_data_object["magic_resist"] = magic_resist

	json_data_object["armor_pen_flat"] = armor_pen_flat
	json_data_object["armor_pen_percent"] = armor_pen_percent

	json_data_object["magic_pen_flat"] = magic_pen_flat
	json_data_object["magic_pen_percent"] = magic_pen_percent

	json_data_object["attack_damage"] = attack_damage
	json_data_object["attack_speed"] = attack_speed
	json_data_object["attack_range"] = attack_range
	json_data_object["attack_crit_chance"] = attack_crit_chance
	json_data_object["attack_crit_damage"] = attack_crit_damage

	json_data_object["ability_power"] = ability_power
	json_data_object["ability_haste"] = ability_haste

	json_data_object["omnivamp"] = omnivamp
	json_data_object["physical_vamp"] = physical_vamp
	json_data_object["magic_vamp"] = magic_vamp
	json_data_object["true_vamp"] = true_vamp

	json_data_object["movement_speed"] = movement_speed

	return json_data_object


func get_from_name(stat_name: String) -> int:
	match stat_name:
		"health":
			return health
		"health_regen":
			return health_regen

		"mana":
			return mana
		"mana_regen":
			return mana_regen

		"armor":
			return armor
		"magic_resist":
			return magic_resist

		"armor_pen_flat":
			return armor_pen_flat
		"armor_pen_percent":
			return armor_pen_percent

		"magic_pen_flat":
			return magic_pen_flat
		"magic_pen_percent":
			return magic_pen_percent

		"attack_damage":
			return attack_damage

		"attack_speed":
			return attack_speed
		"attack_range":
			return attack_range
		"attack_crit_chance":
			return attack_crit_chance
		"attack_crit_damage":
			return attack_crit_damage

		"ability_power":
			return ability_power
		"ability_haste":
			return ability_haste

		"omnivamp":
			return omnivamp
		"physical_vamp":
			return physical_vamp
		"magic_vamp":
			return magic_vamp
		"true_vamp":
			return true_vamp

		"movement_speed":
			return movement_speed

	print("StatCollection.get_from_abbrev: Unknown stat abbreviation: ", stat_name)
	return 0


static func get_full_stat_name(abbrev_stat: String, ret_abbrev: bool = true) -> String:
	match abbrev_stat:
		"hp":
			return "health"
		"reg_hp":
			return "health_regen"

		"mp":
			return "mana"
		"reg_mp":
			return "mana_regen"

		"res_phy":
			return "armor"
		"res_mag":
			return "magic_resist"

		"pen_f_phy":
			return "armor_pen_flat"
		"pen_p_phy":
			return "armor_pen_percent"

		"pen_f_mag":
			return "magic_pen_flat"
		"pen_p_mag":
			return "magic_pen_percent"

		"dmg_phy":
			return "attack_damage"

		"atk_spd":
			return "attack_speed"
		"atk_rng":
			return "attack_range"
		"atk_crit":
			return "attack_crit_chance"
		"atk_crit_dmg":
			return "attack_crit_damage"

		"ap":
			return "ability_power"
		"ah":
			return "ability_haste"

		"vamp_all":
			return "omnivamp"
		"vamp_phy":
			return "physical_vamp"
		"vamp_mag":
			return "magic_vamp"
		"vamp_tru":
			return "true_vamp"

		"ms":
			return "movement_speed"

	print("StatCollection.get_full_stat_name: Unknown stat abbreviation: ", abbrev_stat)
	if ret_abbrev:
		return abbrev_stat

	return ""


static func get_stat_getter(stat_name: String) -> Callable:
	match stat_name:
		"health":
			return func(stats: StatCollection) -> int: return stats.health
		"health_regen":
			return func(stats: StatCollection) -> int: return stats.health_regen

		"mana":
			return func(stats: StatCollection) -> int: return stats.mana
		"mana_regen":
			return func(stats: StatCollection) -> int: return stats.mana_regen

		"armor":
			return func(stats: StatCollection) -> int: return stats.armor
		"magic_resist":
			return func(stats: StatCollection) -> int: return stats.magic_resist

		"armor_pen_flat":
			return func(stats: StatCollection) -> int: return stats.armor_pen_flat
		"armor_pen_percent":
			return func(stats: StatCollection) -> int: return stats.armor_pen_percent

		"magic_pen_flat":
			return func(stats: StatCollection) -> int: return stats.magic_pen_flat
		"magic_pen_percent":
			return func(stats: StatCollection) -> int: return stats.magic_pen_percent

		"attack_damage":
			return func(stats: StatCollection) -> int: return stats.attack_damage
		"attack_speed":
			return func(stats: StatCollection) -> int: return stats.attack_speed
		"attack_range":
			return func(stats: StatCollection) -> int: return stats.attack_range
		"attack_crit_chance":
			return func(stats: StatCollection) -> int: return stats.attack_crit_chance
		"attack_crit_damage":
			return func(stats: StatCollection) -> int: return stats.attack_crit_damage

		"ability_power":
			return func(stats: StatCollection) -> int: return stats.ability_power
		"ability_haste":
			return func(stats: StatCollection) -> int: return stats.ability_haste

		"omnivamp":
			return func(stats: StatCollection) -> int: return stats.omnivamp
		"physical_vamp":
			return func(stats: StatCollection) -> int: return stats.physical_vamp
		"magic_vamp":
			return func(stats: StatCollection) -> int: return stats.magic_vamp
		"true_vamp":
			return func(stats: StatCollection) -> int: return stats.true_vamp

		"movement_speed":
			return func(stats: StatCollection) -> int: return stats.movement_speed

	print("StatCollection.get_stat_getter: Unknown stat name: ", stat_name)
	return func(_stats: StatCollection) -> int: return 0


func get_copy() -> StatCollection:
	var stat = StatCollection.new()
	stat.add(self)
	return stat


func add(other: StatCollection, times: int = 1):
	health += other.health * times
	health_regen += other.health_regen * times

	mana += other.mana * times
	mana_regen += other.mana_regen * times

	armor += other.armor * times
	magic_resist += other.magic_resist * times

	armor_pen_flat += other.armor_pen_flat * times
	armor_pen_percent += other.armor_pen_percent * times

	magic_pen_flat += other.magic_pen_flat * times
	magic_pen_percent += other.magic_pen_percent * times

	attack_damage += other.attack_damage * times
	attack_speed += other.attack_speed * times
	attack_range += other.attack_range * times
	attack_crit_chance += other.attack_crit_chance * times
	attack_crit_damage += other.attack_crit_damage * times

	ability_power += other.ability_power * times
	ability_haste += other.ability_haste * times

	omnivamp += other.omnivamp * times
	physical_vamp += other.physical_vamp * times
	magic_vamp += other.magic_vamp * times
	true_vamp += other.true_vamp * times

	movement_speed += other.movement_speed * times


func clamp_self(_min: StatCollection, _max: StatCollection):
	var new_vals: StatCollection = clamp(self, _min, _max)
	health = new_vals.health
	health_regen = new_vals.health_regen

	mana = new_vals.mana
	mana_regen = new_vals.mana_regen

	armor = new_vals.armor
	magic_resist = new_vals.magic_resist

	armor_pen_flat = new_vals.armor_pen_flat
	armor_pen_percent = new_vals.armor_pen_percent

	magic_pen_flat = new_vals.magic_pen_flat
	magic_pen_percent = new_vals.magic_pen_percent

	attack_damage = new_vals.attack_damage
	attack_speed = new_vals.attack_speed
	attack_range = new_vals.attack_range
	attack_crit_chance = new_vals.attack_crit_chance
	attack_crit_damage = new_vals.attack_crit_damage

	ability_power = new_vals.ability_power
	ability_haste = new_vals.ability_haste

	omnivamp = new_vals.omnivamp
	physical_vamp = new_vals.physical_vamp
	magic_vamp = new_vals.magic_vamp
	true_vamp = new_vals.true_vamp

	movement_speed = new_vals.movement_speed


func clamp_below(_max: StatCollection):
	clamp_self(StatCollection.new(), _max)


static func clamp(
	_stat: StatCollection, _min: StatCollection, _max: StatCollection
) -> StatCollection:
	var stat := StatCollection.new()
	stat.health = clamp(_stat.health, _min.health, _max.health)
	stat.health_regen = clamp(_stat.health_regen, _min.health_regen, _max.health_regen)

	stat.mana = clamp(_stat.mana, _min.mana, _max.mana)
	stat.mana_regen = clamp(_stat.mana_regen, _min.mana_regen, _max.mana_regen)

	stat.armor = clamp(_stat.armor, _min.armor, _max.armor)
	stat.magic_resist = clamp(_stat.magic_resist, _min.magic_resist, _max.magic_resist)

	stat.armor_pen_flat = clamp(_stat.armor_pen_flat, _min.armor_pen_flat, _max.armor_pen_flat)
	stat.armor_pen_percent = clamp(
		_stat.armor_pen_percent, _min.armor_pen_percent, _max.armor_pen_percent
	)

	stat.magic_pen_flat = clamp(_stat.magic_pen_flat, _min.magic_pen_flat, _max.magic_pen_flat)
	stat.magic_pen_percent = clamp(
		_stat.magic_pen_percent, _min.magic_pen_percent, _max.magic_pen_percent
	)

	stat.attack_damage = clamp(_stat.attack_damage, _min.attack_damage, _max.attack_damage)
	stat.attack_speed = clamp(_stat.attack_speed, _min.attack_speed, _max.attack_speed)
	stat.attack_range = clamp(_stat.attack_range, _min.attack_range, _max.attack_range)
	stat.attack_crit_chance = clamp(
		_stat.attack_crit_chance, _min.attack_crit_chance, _max.attack_crit_chance
	)
	stat.attack_crit_damage = clamp(
		_stat.attack_crit_damage, _min.attack_crit_damage, _max.attack_crit_damage
	)

	stat.ability_power = clamp(_stat.ability_power, _min.ability_power, _max.ability_power)
	stat.ability_haste = clamp(_stat.ability_haste, _min.ability_haste, _max.ability_haste)

	stat.omnivamp = clamp(_stat.omnivamp, _min.omnivamp, _max.omnivamp)
	stat.physical_vamp = clamp(_stat.physical_vamp, _min.physical_vamp, _max.physical_vamp)
	stat.magic_vamp = clamp(_stat.magic_vamp, _min.magic_vamp, _max.magic_vamp)
	stat.true_vamp = clamp(_stat.true_vamp, _min.true_vamp, _max.true_vamp)

	stat.movement_speed = clamp(_stat.movement_speed, _min.movement_speed, _max.movement_speed)

	return stat


static func sum(stats: Array[StatCollection]) -> StatCollection:
	var result = StatCollection.new()
	for stat in stats:
		result.add(stat)

	return result


static func subtract(_stat: StatCollection, _sub: StatCollection) -> StatCollection:
	var stat = StatCollection.new()
	stat.health = _stat.health - _sub.health
	stat.health_regen = _stat.health_regen - _sub.health_regen

	stat.mana = _stat.mana - _sub.mana
	stat.mana_regen = _stat.mana_regen - _sub.mana_regen

	stat.armor = _stat.armor - _sub.armor
	stat.magic_resist = _stat.magic_resist - _sub.magic_resist

	stat.armor_pen_flat = _stat.armor_pen_flat - _sub.armor_pen_flat
	stat.armor_pen_percent = _stat.armor_pen_percent - _sub.armor_pen_percent

	stat.magic_pen_flat = _stat.magic_pen_flat - _sub.magic_pen_flat
	stat.magic_pen_percent = _stat.magic_pen_percent - _sub.magic_pen_percent

	stat.attack_damage = _stat.attack_damage - _sub.attack_damage
	stat.attack_speed = _stat.attack_speed - _sub.attack_speed
	stat.attack_range = _stat.attack_range - _sub.attack_range
	stat.attack_crit_chance = _stat.attack_crit_chance - _sub.attack_crit_chance
	stat.attack_crit_damage = _stat.attack_crit_damage - _sub.attack_crit_damage

	stat.ability_power = _stat.ability_power - _sub.ability_power
	stat.ability_haste = _stat.ability_haste - _sub.ability_haste

	stat.omnivamp = _stat.omnivamp - _sub.omnivamp
	stat.physical_vamp = _stat.physical_vamp - _sub.physical_vamp
	stat.magic_vamp = _stat.magic_vamp - _sub.magic_vamp
	stat.true_vamp = _stat.true_vamp - _sub.true_vamp

	stat.movement_speed = _stat.movement_speed - _sub.movement_speed

	return stat


static func max(_stat: StatCollection, _max: StatCollection) -> StatCollection:
	var stat = StatCollection.new()
	stat.health = max(_stat.health, _max.health)
	stat.health_regen = max(_stat.health_regen, _max.health_regen)

	stat.mana = max(_stat.mana, _max.mana)
	stat.mana_regen = max(_stat.mana_regen, _max.mana_regen)

	stat.armor = max(_stat.armor, _max.armor)
	stat.magic_resist = max(_stat.magic_resist, _max.magic_resist)

	stat.armor_pen_flat = max(_stat.armor_pen_flat, _max.armor_pen_flat)
	stat.armor_pen_percent = max(_stat.armor_pen_percent, _max.armor_pen_percent)

	stat.magic_pen_flat = max(_stat.magic_pen_flat, _max.magic_pen_flat)
	stat.magic_pen_percent = max(_stat.magic_pen_percent, _max.magic_pen_percent)

	stat.attack_damage = max(_stat.attack_damage, _max.attack_damage)
	stat.attack_speed = max(_stat.attack_speed, _max.attack_speed)
	stat.attack_range = max(_stat.attack_range, _max.attack_range)
	stat.attack_crit_chance = max(_stat.attack_crit_chance, _max.attack_crit_chance)
	stat.attack_crit_damage = max(_stat.attack_crit_damage, _max.attack_crit_damage)

	stat.ability_power = max(_stat.ability_power, _max.ability_power)
	stat.ability_haste = max(_stat.ability_haste, _max.ability_haste)

	stat.omnivamp = max(_stat.omnivamp, _max.omnivamp)
	stat.physical_vamp = max(_stat.physical_vamp, _max.physical_vamp)
	stat.magic_vamp = max(_stat.magic_vamp, _max.magic_vamp)
	stat.true_vamp = max(_stat.true_vamp, _max.true_vamp)

	stat.movement_speed = max(_stat.movement_speed, _max.movement_speed)

	return stat
