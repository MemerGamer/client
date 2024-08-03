## The base class for all units in the game.
## This class contains all the basic functionality that all units share.
## It also sets up the scene of any unit.
## This script is not supposed to be extended.
## Instances should be created from the spawn functions in the spawner classes.
class_name Unit
extends CharacterBody3D


## The types of damage that can be dealt.
enum DamageType {
	## True damage is not reduced by any resistance.
	TRUE = 0,
	## Physical damage is reduced by armor.
	PHYSICAL = 1,
	## Magical damage is reduced by magic resist.
	MAGICAL = 2,
}

## A dictionary that maps strings to the DamageType enum.
## This can be used in combination with JsonHelper.get_optional_enum
## to parse damage types from JSON.
const ParseDamageType : Dictionary = {
	"true": DamageType.TRUE,
	"physical": DamageType.PHYSICAL,
	"magical": DamageType.MAGICAL,
}

# Signals

## Emitted when the unit dies.
## This signal is used to clean up the unit and give rewards.
signal died ()

## Emitted every time the current stats of the unit change.
## This signal is used to update the UI elements.
## The signal does not contain any arguments and they have to be fetched from the unit itself.
signal current_stats_changed ()

## Emitted when the unit gets healed.
## This signal is used to trigger extra healing effects.
signal healed (caster: Unit, target: Unit, amount: float)

## Gets emitted on the caster when the windup of an attack is finished.
## Use this to spwan extra projectiles or apply effects to the caster.
signal windup_finished (caster: Unit, target: Unit)

## Gets emitted on the caster when the attack projectile hit the target or the melee attack landed.
## Use this to apply effects to the target or the caster.
## On hit damage effects should use this signal to apply additinal damage effects.
signal attack_connected (caster: Unit, target: Unit, is_crit: bool, damage_type: DamageType)

## Gets emitted on the caster after the target damage calculation has been done.
## This signal is used to trigger post hit effects like healing or lifesteal.
## Note that shielded damage is not included in the damage amount.
signal actual_damage_dealt (caster: Unit, target: Unit, is_crit: bool, damage_type: DamageType, damage: int)

## Each of these effects is a function that takes the caster, the target, the damage type, and the damage amount.
## They should return the remaining damage after the effect has been applied.
## The effects are applied in the order they are added to the array.
## The remaining damage is then subject to the regular damage calculation.
var _hit_reduction_effects : Array[Callable] = []

# constant unit variables
@export var id: int
@export var team: int
@export var index: int = 0
@export var nametag: String
@export var player_controlled: bool = false
@export var is_structure: bool = false
@export var unit_id : String = ""

# Stats:
var current_stats: StatCollection
var maximum_stats: StatCollection
var base_stats: StatCollection

var per_level_stats: StatCollection

var has_mana: bool = false

var current_shielding: int = 0

var turn_speed: float = 15.0
var windup_fraction: float = 0.1

var level : int = 1
var level_exp : int = 0
var required_exp : int = 100
var dropped_exp : int = 0
var exp_per_second: float = 0

var overheal : bool = false
var max_overheal : int = 0

var current_gold : int = 0
var dropped_gold : int = 0
var gold_per_second : float = 0

var is_alive : bool = true

var kills : int = 0
var deaths : int = 0
var assists : int = 0

var minion_kills: int = 0

var passive_item_slots : int = 2
var active_item_slots : int = 4

var item_list : Array[Item] = []
var item_slots_active : Array[Item] = []
var item_slots_passive : Array[Item] = []

var items_changed : bool = false

# Each bit of cc_state represents a different type of crowd control.
var cc_state: int = 0
var effect_array: Array[UnitEffect] = []

var target_entity: Node = null
var server_position

var nav_agent : NavigationAgent3D

var map : Node = null
var projectile_config : Dictionary
var projectile_spawner : MultiplayerSpawner

var attack_range_visualizer : MeshInstance3D

var action_effects : Node

# Preloaded scripts and scenes
const state_machine_script = preload("res://scripts/states/_state_machine.gd")
const state_idle_script = preload("res://scripts/states/state_types/unit_idle.gd")
const state_move_script = preload("res://scripts/states/state_types/unit_move.gd")
const state_auto_attack_script = preload("res://scripts/states/state_types/unit_auto_attack.gd")

const healthbar_scene = preload("res://ui/player_stats/healthbar.tscn")


func _init():
	if base_stats == null:
		base_stats = StatCollection.from_dict({
			"health": 640,
			"health_regen": 35,

			"mana": 280,
			"mana_regen": 7,
			
			"armor": 26,
			"magic_resist": 30,

			"attack_range": 300,
			"attack_damage": 60,
			"attack_speed": 75,

			"movement_speed": 100,
		} as Dictionary)
	
	if maximum_stats == null:
		maximum_stats = base_stats.get_copy()

	if current_stats == null:
		current_stats = maximum_stats.get_copy()

	if per_level_stats == null:
		per_level_stats = StatCollection.new()

	required_exp = get_exp_for_levelup(level + 1)


func _ready():
	if map == null:
		map = get_tree().root.get_node("Startup/Map").get_child(0) as MapNode
	
	_setup_scene_elements()
	_setup_default_signals()
	current_stats_changed.emit()


func _setup_scene_elements():
	# setting up the multiplayer synchronization
	var replication_config = SceneReplicationConfig.new()

	replication_config.add_property(NodePath(".:rotation"))
	replication_config.property_set_spawn(NodePath(".:rotation"), true)
	replication_config.property_set_replication_mode(NodePath(".:rotation"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

	replication_config.add_property(NodePath(".:id"))
	replication_config.property_set_spawn(NodePath(".:id"), true)
	replication_config.property_set_replication_mode(NodePath(".:id"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

	replication_config.add_property(NodePath(".:maximum_stats"))
	replication_config.property_set_spawn(NodePath(".:maximum_stats"), true)
	replication_config.property_set_replication_mode(NodePath(".:maximum_stats"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

	replication_config.add_property(NodePath(".:current_stats"))
	replication_config.property_set_spawn(NodePath(".:current_stats"), true)
	replication_config.property_set_replication_mode(NodePath(".:current_stats"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)

	replication_config.add_property(NodePath(".:server_position"))
	replication_config.property_set_spawn(NodePath(".:server_position"), true)
	replication_config.property_set_replication_mode(NodePath(".:server_position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	
	var multiplayer_synchronizer = MultiplayerSynchronizer.new()
	multiplayer_synchronizer.set_replication_config(replication_config)
	multiplayer_synchronizer.name = "MultiplayerSynchronizer"
	add_child(multiplayer_synchronizer)

	# setting up the state machine
	var state_machine_node = Node.new()
	state_machine_node.name = "StateMachine"
	state_machine_node.set_script(state_machine_script)

	if Config.show_all_state_changes:
		state_machine_node.print_state_changes = true
	else:
		state_machine_node.print_state_changes = player_controlled

	var state_idle_node = Node.new()
	state_idle_node.name = "Idle"
	state_idle_node.set_script(state_idle_script)
	state_machine_node.add_child(state_idle_node)

	var state_move_node = Node.new()
	state_move_node.name = "Moving"
	state_move_node.set_script(state_move_script)
	state_machine_node.add_child(state_move_node)

	var state_auto_attack_node = Node.new()
	state_auto_attack_node.name = "Attacking"
	state_auto_attack_node.set_script(state_auto_attack_script)
	state_machine_node.add_child(state_auto_attack_node)

	state_machine_node.initial_state = state_idle_node
	add_child(state_machine_node)

	# set up the abilities
	var abilities_node = Node.new()
	abilities_node.name = "Abilities"

	var auto_attack_node = Node.new()
	auto_attack_node.name = "AutoAttack"

	var aa_windup_node = Timer.new()
	aa_windup_node.name = "AAWindup"
	aa_windup_node.one_shot = true
	aa_windup_node.process_callback = Timer.TIMER_PROCESS_PHYSICS
	auto_attack_node.add_child(aa_windup_node)

	var aa_cooldown_node = Timer.new()
	aa_cooldown_node.name = "AACooldown"
	aa_cooldown_node.one_shot = true
	aa_cooldown_node.process_callback = Timer.TIMER_PROCESS_PHYSICS
	auto_attack_node.add_child(aa_cooldown_node)

	abilities_node.add_child(auto_attack_node)
	add_child(abilities_node)

	# set up projectile spawning
	var projectiles_node = Node.new()
	projectiles_node.name = "Projectiles"
	add_child(projectiles_node)

	var projectile_spawner_node = MultiplayerSpawner.new()
	projectile_spawner_node.name = "ProjectileSpawner"
	projectile_spawner_node.spawn_limit = 999
	projectile_spawner_node.spawn_path = NodePath("../Projectiles")
	projectile_spawner_node.spawn_function = spawn_projectile
	add_child(projectile_spawner_node)
	projectile_spawner = get_node("ProjectileSpawner")

	# set up the action effects
	var action_effects_node = Node.new()
	action_effects_node.name = "ActionEffects"
	add_child(action_effects_node)
	action_effects = get_node("ActionEffects")

	# set up the navitation agent
	var _nav_agent = NavigationAgent3D.new()
	_nav_agent.name = "NavigationAgent3D"
	add_child(_nav_agent)
	nav_agent = get_node("NavigationAgent3D")

	# set up the healthbar
	var healthbar_node = healthbar_scene.instantiate()
	healthbar_node.name = "Healthbar"
	add_child(healthbar_node)
	healthbar_node._update_healthbar(self)
	current_stats_changed.connect(func (): healthbar_node._update_healthbar(self))

	# set up the attack range visualizer
	var attack_range_mesh = TorusMesh.new()
	attack_range_mesh.inner_radius = current_stats.attack_range * 0.0099
	attack_range_mesh.outer_radius = current_stats.attack_range * 0.01

	attack_range_visualizer = MeshInstance3D.new()
	attack_range_visualizer.name = "AttackRangeVisualizer"
	attack_range_visualizer.mesh = attack_range_mesh
	attack_range_visualizer.transparency = 0.8
	attack_range_visualizer.cast_shadow = GeometryInstance3D.ShadowCastingSetting.SHADOW_CASTING_SETTING_OFF

	add_child(attack_range_visualizer)
	attack_range_visualizer = get_node("AttackRangeVisualizer")

	if not Config.show_all_attack_ranges:
		attack_range_visualizer.hide()

	# set up the timer for passive healing and mana regen
	var passive_heal_timer := Timer.new()
	passive_heal_timer.name = "PassiveHealTimer"
	passive_heal_timer.one_shot = false
	passive_heal_timer.autostart = true
	passive_heal_timer.wait_time = 5.0
	passive_heal_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	passive_heal_timer.timeout.connect(_passive_regen_handler)
	add_child(passive_heal_timer)


func _setup_default_signals():

	# update the attack range visualizer when the stats change
	current_stats_changed.connect(func ():
		attack_range_visualizer.mesh.inner_radius = current_stats.attack_range * 0.0099
		attack_range_visualizer.mesh.outer_radius = current_stats.attack_range * 0.01
	)

	# Do a basic attack when the windup is finished
	# In cases the character is ranged spawn a projectile
	# Otherwise just deal the damage directly
	if projectile_config:
		windup_finished.connect(func (caster, target):
			if caster != self: return
			if target != target_entity: return

			projectile_spawner.spawn()
		)
	else:
		windup_finished.connect(func (caster, target):
			if caster != self: return
			if target != target_entity: return

			attack_connected.emit(self, target, should_crit(), DamageType.PHYSICAL)
		)

	# Deal the damage when the attack hits
	attack_connected.connect(_attack_connected)

	# Handle life steal after actual damage has been dealt
	actual_damage_dealt.connect(_damage_actually_dealt)

	# Handle healing effects being applied
	healed.connect(_healed_handler)


func spawn_projectile(_args):
	if not projectile_config:
		print("Projectile config not set.")
		return null
	
	var _projectile = Projectile.new()

	var spawn_offset = projectile_config["spawn_offset"] as Vector3
	spawn_offset = spawn_offset.rotated(Vector3(0, 1, 0), rotation.y)

	_projectile.caster = self
	_projectile.position = server_position + spawn_offset
	_projectile.target = target_entity

	_projectile.model = projectile_config["model"]
	_projectile.model_scale = projectile_config["model_scale"]
	_projectile.model_rotation = projectile_config["model_rotation"]
	_projectile.speed = projectile_config["speed"]
	_projectile.damage_type = projectile_config["damage_type"]

	_projectile.is_crit = should_crit()

	return _projectile


# Stats related things
func level_up(times: int = 1):
	base_stats.add(per_level_stats, times)
	maximum_stats.add(per_level_stats, times)
	current_stats.add(per_level_stats, times)

	if player_controlled:
		print("Level up!")
	
	current_stats_changed.emit()
	
	level += times
	required_exp = get_exp_for_levelup(level + 1)


func give_exp(amount: int):
	level_exp += amount
	
	while level_exp >= required_exp:
		level_exp -= required_exp
		level_up()


func reward_exp_on_death(murderer = null):
	var exp_reward_shape = CylinderShape3D.new()
	# set the radius in which all units will be rewarded experience
	exp_reward_shape.radius = 100.0

	var exp_reward_collision = CollisionShape3D.new()
	exp_reward_collision.shape = exp_reward_shape

	var exp_reward_collider = Area3D.new()
	exp_reward_collider.name = "ExpRewardCollider"
	exp_reward_collider.add_child(exp_reward_collision)
	add_child(exp_reward_collider)

	var rewarded_units : Array[Unit] = []
	if murderer != null:
		rewarded_units.append(murderer)

	var bodies = exp_reward_collider.get_overlapping_bodies()
	for body in bodies:
		var _unit = body as Unit
		if _unit == null: continue
		if _unit.team == team: continue
		if not _unit.is_alive: continue
		if _unit == murderer: continue
		
		rewarded_units.append(_unit)
	
	exp_reward_collider.queue_free()
	
	if rewarded_units.size() == 0:
		return

	var unit_share_factor = 1.0 + 3.0 * log(float(rewarded_units.size()))
	var per_unit_exp = int(dropped_exp / unit_share_factor)
	var per_unit_gold = int(dropped_gold / unit_share_factor)

	if player_controlled:
		for _unit in rewarded_units:
			if _unit == murderer:
				_unit.kills += 1
			else:
				_unit.assists += 1
	else:
		murderer.minion_kills += 1

	if rewarded_units.size() == 1:
		murderer.give_exp(per_unit_exp)
		murderer.give_gold(per_unit_gold)
	else:
		for _unit in rewarded_units:
			_unit.give_exp(per_unit_exp)

			# the murderer gets more gold than everyone else
			if _unit == murderer:
				_unit.give_gold(int(per_unit_gold * 1.5))
			else:
				_unit.give_gold(per_unit_gold)


## This function returns the amount of experience required to level up.
## The returned value is the difference in exp needed to level up from
## _level-1 to _level.
## At the moment, the exp required to level up is 100 * _level.
static func get_exp_for_levelup(_level: int) -> int:
	return 100 * _level


# Gold related things
func give_gold(amount: int):
	current_gold += amount


func purchase_item(_item: Item, gold_cost: int, new_inventory: Array[Item]):
	# make sure the old inventory is disconnected
	for item in item_list:
		var item_effects = item.effects
		for effect in item_effects:
			effect.disconnect_from_unit(self)
			action_effects.remove_child(effect)
	

	# set the inventory to the new one and connect all effects
	item_list = new_inventory

	for effect in _item.effects:
		effect.connect_to_unit(self)
		action_effects.add_child(effect)

	# clear the list of active and passice slots and repopulate them
	item_slots_active.clear()
	item_slots_passive.clear()

	for item in item_list:
		if item.is_active:
			item_slots_active.append(item)
		else:
			if item_slots_passive.size() < passive_item_slots:
				item_slots_passive.append(item)
			else:
				item_slots_active.append(item)
	
	# actually update the gold and the stats
	current_gold -= gold_cost
	
	maximum_stats.add(_item.get_stats())
	current_stats.add(_item.get_stats())

	current_stats_changed.emit()

	# mark the ui to be updated
	items_changed = true


# Movement
func update_target_location(target_location: Vector3):
	print("Target Location Updated");
	target_entity = null
	nav_agent.target_position = target_location


## Combat
func take_damage(caster: Unit, is_crit: bool, damage_type: DamageType, damage_amount: int):
	if not can_take_damage(): return

	# apply all damage reduction effects
	var remaning_damage = damage_amount
	for effect_call in _hit_reduction_effects:
		remaning_damage = effect_call.call(caster, self, is_crit, damage_type, remaning_damage)

	# get the correct resistance type depending on the damage type
	# for true damage, the resistance is 0
	var effective_resistance = 1.0
	if damage_type == DamageType.PHYSICAL:
		effective_resistance = current_stats.armor
		effective_resistance *= (1.0 - caster.current_stats.armor_pen_percent / 100.0)
		effective_resistance -= caster.current_stats.armor_pen_flat
		effective_resistance = max(0.0, effective_resistance / 100.0) + 1.0
	elif damage_type == DamageType.MAGICAL:
		effective_resistance = current_stats.magic_resist
		effective_resistance *= (1.0 - caster.current_stats.magic_pen_percent / 100.0)
		effective_resistance -= caster.current_stats.magic_pen_flat
		effective_resistance = max(0.0, effective_resistance / 100.0) + 1.0

	# calculate the remaining damage after resistance
	remaning_damage /= effective_resistance
	var actual_damage = int(remaning_damage)

	# handle shielding
	if current_shielding > 0:
		current_shielding -= actual_damage

		# if the damage is more than the shielding we need to perform the remaining damage calculation
		if current_shielding <= 0:
			actual_damage = -current_shielding
			current_shielding = 0

	# If the damage that need to be dealt is more that 0, we need to update the health
	# and notify the caster that the damage was dealt.
	if actual_damage > 0:
		current_stats.health -= actual_damage
		caster.actual_damage_dealt.emit(caster, self, is_crit, damage_type, actual_damage)
	
		if map != null:
			# notify the map that damage was dealt
			# This spawns the damage popup on all clients
			map.on_unit_damaged(self, actual_damage, damage_type)
	
	# If the health is 0 or less, the unit dies and we register the caster as the murderer.
	if current_stats.health <= 0:
		current_stats.health = 0
		die(caster)

	# This simply updates all UI elements with the latest stats
	current_stats_changed.emit()


func should_crit() -> bool:
	if current_stats.attack_crit_chance <= 0: return false
	if current_stats.attack_crit_chance >= 100: return true

	var rand = RandomNumberGenerator.new()
	rand.seed = int(map.time_elapsed*60)
	return rand.randi_range(0, 100) < current_stats.attack_crit_chance


func die(murderer = null):
	is_alive = false

	reward_exp_on_death(murderer)
	died.emit()

	if team > 0:
		deaths += 1


func move_on_path(delta: float) -> bool:
	## return true if target position was reached, false otherwise

	if nav_agent.is_navigation_finished(): return true
	if not can_move(): return false

	server_position = global_position
	nav_agent.target_desired_distance = 0.025
	nav_agent.simplify_path = true

	var target_location = nav_agent.get_next_path_position()
	var direction = target_location - global_position
	var actual_speed = current_stats.movement_speed / 100.0
	
	nav_agent.velocity = direction.normalized() * actual_speed
	velocity = direction.normalized() * actual_speed

	rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), turn_speed * delta)

	move_and_slide()

	return false


func trigger_ability(_index: int):
	if not can_cast(): return
	
	# check if the ability exists
	var abilities_node = get_node("Abilities")
	if abilities_node == null:
		print("Abilities node not found.")
		return

	if _index >= abilities_node.get_child_count():
		print("Ability (%s) larger than the amount of known abilities (%s)." % [str(_index), str(abilities_node.get_child_count())])
		return

	var ability_node = get_node("Abilities").get_child(_index)
	if ability_node == null:
		print("Ability not found (%s)." % str(_index))
		return


func apply_effect(effect: UnitEffect):
	effect_array.append(effect)
	add_child(effect)
	recalculate_cc_state()


func _on_cc_end(effect: UnitEffect):
	effect_array.erase(effect)
	effect.end()
	recalculate_cc_state()


func recalculate_cc_state() -> int:
	var new_state := 0
	for effect in effect_array:
		new_state = new_state | effect.cc_mask
	cc_state = new_state
	return new_state


func can_move() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_MOVEMENT == 0


func can_cast_movement() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_CAST_MOBILITY == 0


func can_attack() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_ATTACK == 0


func can_cast() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_CAST == 0


func can_change_target() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_TARGET == 0


func can_take_damage() -> bool:
	return cc_state & CCTypesRegistry.CC_MASK_TAKE_DAMAGE == 0


func _passive_regen_handler():
	if not is_alive: return

	# first we regen the mana
	if current_stats.mana_regen > 0:
		current_stats.mana += current_stats.mana_regen
		if current_stats.mana > maximum_stats.mana:
			current_stats.mana = maximum_stats.mana
	
	if current_stats.health_regen:
		# then we emit the healed signal with the amount of health regen
		# This is used to trigger extra healing effects.
		# The healed signal will also trigger the current_stats_changed signal
		# which will update the UI elements.
		healed.emit(self, self, current_stats.health_regen)
	else:
		current_stats_changed.emit()


func _attack_connected(caster, target, is_crit, damage_type):
	if caster != self: return

	var damage = current_stats.attack_damage
	if is_crit: damage *= (100 + current_stats.attack_crit_damage) * 0.01

	target.take_damage(caster, is_crit, damage_type, damage)


func _damage_actually_dealt(caster: Unit, _target: Unit, _is_crit: bool, damage_type: DamageType, damage: int):
	if caster != self: return

	var total_vamp : int = current_stats.omnivamp
	if damage_type == DamageType.PHYSICAL: total_vamp += current_stats.physical_vamp
	if damage_type == DamageType.MAGICAL: total_vamp += current_stats.magic_vamp
	if damage_type == DamageType.TRUE: total_vamp += current_stats.true_vamp

	total_vamp = clampi(total_vamp, 0, 100)

	if total_vamp > 0:
		var heal_amount = int(damage * total_vamp * 0.01)
		self.healed.emit(self, self, heal_amount)


func _healed_handler(_caster: Unit, target: Unit, amount: float):
	if target != self: return

	current_stats.health += int(amount)

	if current_stats.health >= maximum_stats.health: 
		if overheal:
			var extra_health = current_stats.health - maximum_stats.health
			current_shielding = clampi(current_shielding + extra_health, 0, max_overheal)
		
		current_stats.health = maximum_stats.health
	
	current_stats_changed.emit()


func get_current_state_name() -> String:
	var curr_state = $StateMachine.current_state
	if curr_state == null: return ""
	return curr_state.name


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args)


@rpc("authority", "call_local")
func queue_state_change(new, args):
	$StateMachine.queue_state(new, args)


@rpc("authority", "call_local")
func advance_state():
	$StateMachine.advance_state()
