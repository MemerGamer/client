class_name ConfigGroupBase
extends Node

var config_type = "base"


func _init(_config: ConfigFile = null) -> void:
	if _config == null:
		return


func save(_config: ConfigFile) -> void:
	pass


func copy() -> ConfigGroupBase:
	return null


func differs(other: ConfigGroupBase) -> bool:
	if other == null:
		return true

	return false
