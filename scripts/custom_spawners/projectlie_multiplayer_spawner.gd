class_name ProjectileMultiplayerSpawner
extends MultiplayerSpawner


func _ready() -> void:
	# set up projectile spawning
	var projectiles_node = Node.new()
	projectiles_node.name = "Projectiles"
	add_child(projectiles_node)

	spawn_limit = 999
	spawn_path = NodePath("Projectiles")
	spawn_function = Projectile.from_dict
