class_name Projectile
extends Node3D

const GPUTrailShader = preload("res://addons/gpu_trail/shaders/trail.gdshader")
const GPUTrailDrawPassShader = preload("res://addons/gpu_trail/shaders/trail_draw_pass.gdshader")
const GPUTrailTexture = preload("res://addons/gpu_trail/defaults/texture.tres")
const GPUTrailCurve = preload("res://addons/gpu_trail/defaults/curve.tres")
const GPUTrailScript = preload("res://addons/gpu_trail/GPUTrail3D.gd")

var is_crit: bool = false
var speed: float = 80.0
var damage_type: Unit.DamageType = Unit.DamageType.PHYSICAL
var damage_src: Unit.SourceType = Unit.SourceType.ITEM_EFFECT
var scaling_calc = null

var target: Unit
var caster: Unit

var model: String = "openchamp:particles/arrow"
var model_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
var model_rotation: Vector3 = Vector3(0.0, 0.0, 0.0)

var on_hit_function: Callable

var sfx_player := AudioStreamPlayer3D.new()
var launch_sfx: String


static func from_dict(projectile_config: Dictionary) -> Projectile:
	if not projectile_config:
		print("Projectile config not set.")
		return null

	var new_projectile = Projectile.new()

	var caster_path := projectile_config["caster_entity_name"] as String
	new_projectile.caster = Config.get_node(NodePath(caster_path)) as Unit

	var target_entity_path := projectile_config["target_entity_name"] as String
	new_projectile.target = Config.get_node(NodePath(target_entity_path)) as Unit

	var spawn_offset = projectile_config["spawn_offset"] as Vector3
	spawn_offset = spawn_offset.rotated(Vector3(0, 1, 0), new_projectile.caster.rotation.y)

	new_projectile.position = new_projectile.caster.server_position + spawn_offset

	new_projectile.model = projectile_config["model"]
	new_projectile.model_scale = projectile_config["model_scale"]
	new_projectile.model_rotation = projectile_config["model_rotation"]
	new_projectile.speed = projectile_config["speed"]
	new_projectile.damage_type = projectile_config["damage_type"]

	var scaling_funcs = ScalingsBuilder.build_scaling_function(str(projectile_config["scaling"]))
	if scaling_funcs == null:
		print("Could not create Projectile from dictionary. Could not build scaling function.")
		print("projectile_config dict: " + str(projectile_config))
		new_projectile.scaling_calc = null
	else:
		new_projectile.scaling_calc = scaling_funcs[0]

	new_projectile.launch_sfx = JsonHelper.get_optional_string(projectile_config, "launch_sfx", "")

	new_projectile.damage_src = (
		JsonHelper.get_optional_enum(
			projectile_config, "source_type", Unit.PARSE_SOURCE_TYPE, Unit.DamageType.PHYSICAL
		)
		as Unit.SourceType
	)

	new_projectile.is_crit = new_projectile.caster.should_crit()

	return new_projectile


func _create_model():
	# load the model
	var model_instance = load("model://" + model)
	if not model_instance:
		print("Failed to load model: " + model)
		return

	var model_node = model_instance.instantiate()
	if not model_node:
		print("Failed to instance model: " + model)
		return

	model_node.scale = model_scale
	model_node.rotation_degrees = model_rotation
	model_node.name = "model_projectile"
	add_child(model_node)

	# Add multiplayer synchronization
	var multiplayer_config := SceneReplicationConfig.new()
	multiplayer_config.add_property("../model_projectile:rotation")
	multiplayer_config.add_property("../model_projectile:position")

	var multiplayer_sync := MultiplayerSynchronizer.new()
	multiplayer_sync.replication_config = multiplayer_config
	multiplayer_sync.name = "multiplayer_sync"
	model_node.add_child(multiplayer_sync)

	# add the GPU trail
	var trail_process_material := ShaderMaterial.new()
	trail_process_material.shader = GPUTrailShader

	var trail_curve := GPUTrailCurve
	var trail_ramp := GPUTrailTexture

	var trail_draw_pass_1_material := ShaderMaterial.new()
	trail_draw_pass_1_material.shader = GPUTrailDrawPassShader
	trail_draw_pass_1_material.set_shader_parameter(
		"emmission_transform",
		Projection(
			Vector4(1, 0, 0, 0), Vector4(0, 1, 0, 0), Vector4(0, 0, 1, 0), Vector4(0, 0, 0, 1)
		)
	)
	trail_draw_pass_1_material.set_shader_parameter("color_ramp", trail_ramp)
	trail_draw_pass_1_material.set_shader_parameter("curve", trail_curve)
	trail_draw_pass_1_material.set_shader_parameter("flags", 40)

	var trail_draw_pass_1 := QuadMesh.new()
	trail_draw_pass_1.material = trail_draw_pass_1_material

	var trail := GPUTrail3D.new()
	trail.set_defaults()

	trail.name = "GPU_trail"
	trail.transform = Transform3D(
		Vector3(1, 0, 0),
		Vector3(0, 0.1, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, 0.984896),
	)

	trail.length = 15
	trail.amount_ratio = 1.0

	trail.process_material = trail_process_material
	trail.draw_pass_1 = trail_draw_pass_1
	trail.color_ramp = trail_ramp
	trail.curve = trail_curve

	model_node.add_child(trail)


func _ready():
	_create_model()

	if not Config.is_dedicated_server and launch_sfx != "":
		var launch_sound := load("audio://" + launch_sfx)
		if not launch_sound:
			print("error loading launch sound")
		else:
			sfx_player.name = "ProjectileSFXPlayer"
			sfx_player.bus = "EntitySfx"
			sfx_player.stream = launch_sound
			add_child(sfx_player)
			sfx_player.play()

	if not multiplayer.is_server():
		return

	if not target or not caster:
		queue_free()
		return


func _process(delta):
	if not multiplayer.is_server():
		return

	if not target:
		queue_free()
		return

	if not caster:
		queue_free()
		return

	if not target.is_alive:
		queue_free()
		return

	var target_pos = target.global_position
	var target_head = target_pos + Vector3.UP
	var step_distance = speed * delta

	# If the distance between the projectile and the target is less than the step distance,
	# the projectile has hit
	var has_hit: bool = global_position.distance_to(target_head) < step_distance

	# If the projectile has hit, deal damage and destroy the projectile
	if has_hit:
		if on_hit_function:
			on_hit_function.call(caster, target, is_crit, damage_type)
		else:
			_handle_auto_attack_hit(caster, target, is_crit, damage_type)

		queue_free()
		return

	# projectile hasn't hit, move it
	print(target_pos)
	print(global_position)
	print(global_position.distance_to(target_pos))

	var dir = global_position.direction_to(target_head)
	global_position += dir * step_distance
	look_at(target_head)


func _handle_auto_attack_hit(_caster, _target, _is_crit, _damage_type):
	if multiplayer.is_server():
		var damage: float
		if scaling_calc:
			damage = scaling_calc.call(_caster, _target)
		else:
			damage = -1

		caster.attack_connected.emit(_caster, _target, _is_crit, damage, _damage_type, damage_src)
