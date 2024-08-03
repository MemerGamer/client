extends Node

@export var print_state_changes: bool = true
@export var initial_state: State

var current_state: State
var states: Dictionary = {}

var queued_states: Array = []

@onready var entity = get_parent()


func _ready():
	for state in get_children():
		if state is State:
			states[state.name] = state
			state.change.connect(change_state)

	if initial_state != null:
		initial_state.enter(entity)
		current_state = initial_state


func _process(delta):
	if not current_state:
		return
	current_state.update(entity, delta)


func _physics_process(delta):
	if not current_state:
		return
	if multiplayer.is_server():
		current_state.update_tick_server(entity, delta)
	else:
		current_state.update_tick_client(entity, delta)


func queue_state(state_name, args = null):
	queued_states.append([state_name, args])


func advance_state():
	if queued_states.size() > 0:
		var next_state = queued_states.pop_front()
		change_state(next_state[0], next_state[1])
	else:
		change_state("Idle", null)


func change_state(new_state_name, args = null):
	if not states.has(new_state_name):
		return

	var new_state = states[new_state_name]
	if current_state == new_state:
		if print_state_changes:
			print("Updating state " + new_state_name + " of " + entity.name)

		current_state.modify(entity, args)
		return

	if print_state_changes:
		print("Changing " + entity.name + " to " + new_state_name)

	if current_state != null:
		current_state.exit(entity)

	new_state.enter(entity, args)
	current_state = new_state
