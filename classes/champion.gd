extends Unit
class_name Champion

@export var server_position:Vector3

@export var nametag : String

@export var max_mana: float = 100.0
@onready var current_mana: float = max_mana
@export var mana_regen: float = 5


@rpc("authority", "call_local")
func change_state(new, args):
	$StateMachine.change_state(new, args);
