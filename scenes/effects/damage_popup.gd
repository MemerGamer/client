class_name DamagePopup
extends Node2D

@onready var label: RichTextLabel = $LabelNode/Label
@onready var label_container: Node2D = $LabelNode
@onready var ap: AnimationPlayer = $AnimationPlayer

var camera: Camera3D
var damage_value: int
var damage_type: Unit.DamageType
var spawn_position: Vector3

var damage_type_colors = {
	Unit.DamageType.TRUE: Color.WHITE,
	Unit.DamageType.PHYSICAL: Color.BROWN,
	Unit.DamageType.MAGICAL: Color.PURPLE,
}

const random_offset = 20


func _ready():
	if Config.is_dedicated_server:
		queue_free()
		return

	call_deferred("play")


func play():
	camera = get_viewport().get_camera_3d()

	if not camera:
		print("Couldn't get camera")
		remove()
		return

	if not spawn_position:
		print("No spawn position set for damage popup")
		remove()
		return

	if not damage_value:
		print("No damage value set for damage popup")
		remove()
		return

	var start_pos = camera.unproject_position(spawn_position)
	start_pos += Vector2(
		randi_range(-random_offset, random_offset), randi_range(-random_offset, random_offset)
	)
	var length = ap.get_animation("pop_up").length
	var end_pos = start_pos + Vector2(0, -20)
	var tween = get_tree().create_tween()

	label.text = ""
	label.push_context()

	if damage_type_colors.has(damage_type):
		label.push_color(damage_type_colors[damage_type])

	label.push_outline_color(Color.BLACK)
	label.push_outline_size(4)

	label.append_text("[center]" + str(damage_value) + "[/center]")
	label.pop_context()

	ap.play("pop_up")

	tween.tween_property(label_container, "position", end_pos, length).from(start_pos)


func remove() -> void:
	ap.stop()
	queue_free()
