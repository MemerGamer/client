extends Node3D

@export var color: String = "openchamp:fallback"

@onready var main_crystal = $Main_Cristal
@onready var tower_base = $Tower
@onready var banners = $Banners


func _ready():
	set_color(color)


func set_color(new_color: String):
	self.color = new_color
	if not RegistryManager.structure_themes().contains(new_color):
		print("Invalid color theme: " + new_color)
		return

	var theme = RegistryManager.structure_themes().get_element(new_color)

	main_crystal.albedo_color = theme.crystal_albedo
	main_crystal.emission = theme.crystal_emission
	tower_base.surface_material_override[0].albedo_color = theme.banner_albedo
	banners.surface_material_override[0].albedo_color = theme.banner_albedo
