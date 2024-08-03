extends Node3D

@onready var particles: GPUParticles3D = $GPUParticles3D
@onready var mesh: MeshInstance3D = $Marker
@onready var anim_player: AnimationPlayer = $AnimationPlayer

var attack_move: bool


func _ready():
	hide()

	particles.one_shot = true
	anim_player.current_animation = "shrink_ring"
	anim_player.animation_finished.connect(stop)


func play():
	anim_player.stop()
	var meshmaterial: StandardMaterial3D = mesh.get_active_material(0)

	if attack_move:
		meshmaterial.albedo_color = Color(255, 0, 0)
		anim_player.speed_scale = 2
	else:
		meshmaterial.albedo_color = Color(0, 255, 0)
		anim_player.speed_scale = 1

	show()
	anim_player.play()


func stop(_anim_name):
	print("move marker animation finished")
	hide()
