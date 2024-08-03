extends Node3D
class_name Projectile

var is_crit: bool = false
var speed: float = 80.0
var damage_type: Unit.DamageType = Unit.DamageType.PHYSICAL

var target: Node = null
var caster: Node = null

var model: String = "openchamp:particles/arrow"
var model_scale: Vector3 = Vector3(1.0, 1.0, 1.0)
var model_rotation: Vector3 = Vector3(0.0, 0.0, 0.0)

const gpu_trail_shader = preload("res://addons/gpu_trail/shaders/trail.gdshader")
const gpu_trail_draw_pass_shader = preload(
	"res://addons/gpu_trail/shaders/trail_draw_pass.gdshader"
)
const gpu_trail_texture = preload("res://addons/gpu_trail/defaults/texture.tres")
const gpu_trail_curve = preload("res://addons/gpu_trail/defaults/curve.tres")
const gpu_trail_script = preload("res://addons/gpu_trail/GPUTrail3D.gd")


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
	var multiplayer_config = SceneReplicationConfig.new()
	multiplayer_config.add_property("../model_projectile:rotation")
	multiplayer_config.add_property("../model_projectile:position")

	var multiplayer_sync = MultiplayerSynchronizer.new()
	multiplayer_sync.replication_config = multiplayer_config
	multiplayer_sync.name = "multiplayer_sync"
	model_node.add_child(multiplayer_sync)

	# add the GPU trail
	var trail_process_material = ShaderMaterial.new()
	trail_process_material.shader = gpu_trail_shader

	var trail_curve = gpu_trail_curve
	var trail_ramp = gpu_trail_texture

	var trail_draw_pass_1_material = ShaderMaterial.new()
	trail_draw_pass_1_material.shader = gpu_trail_draw_pass_shader
	trail_draw_pass_1_material.set_shader_parameter(
		"emmission_transform",
		Projection(
			Vector4(1, 0, 0, 0), Vector4(0, 1, 0, 0), Vector4(0, 0, 1, 0), Vector4(0, 0, 0, 1)
		)
	)
	trail_draw_pass_1_material.set_shader_parameter("color_ramp", trail_ramp)
	trail_draw_pass_1_material.set_shader_parameter("curve", trail_curve)
	trail_draw_pass_1_material.set_shader_parameter("flags", 40)

	var trail_draw_pass_1 = QuadMesh.new()
	trail_draw_pass_1.material = trail_draw_pass_1_material

	var trail = GPUParticles3D.new()
	trail.name = "GPU_trail"
	trail.transform = Transform3D(
		Vector3(1, 0, 0),
		Vector3(0, 0.1, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, 0.984896),
	)

	trail.amount = 100
	trail.lifetime = 100.0
	trail.explosiveness = 1.0
	trail.fixed_fps = 0
	trail.process_material = trail_process_material
	trail.draw_pass_1 = trail_draw_pass_1
	trail.script = gpu_trail_script
	trail.color_ramp = trail_ramp
	trail.curve = trail_curve
	model_node.add_child(trail)


func _ready():
	_create_model()

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

	# If the distance between the projectile and the target is less than the step distance, the projectile has hit
	var has_hit: bool = global_position.distance_to(target_head) < step_distance

	# If the projectile has hit, deal damage and destroy the projectile
	if has_hit:
		if multiplayer.is_server():
			caster.attack_connected.emit(caster, target, is_crit, damage_type)

		queue_free()
		return

	# projectile hasn't hit, move it
	print(target_pos)
	print(global_position)
	print(global_position.distance_to(target_pos))

	var dir = (target_head - global_position).normalized()
	global_position += dir * step_distance
	look_at(target_head)
