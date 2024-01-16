class_name StateMachine

extends Node

@export var CURRENT_STATE: State
var states: Dictionary = {}
var player: Player

func _ready():
	set_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	set_physics_process(get_multiplayer_authority() == multiplayer.get_unique_id())
	player = get_parent()
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.transition.connect(on_child_transition)
			child.player = player
		else:
			push_warning('state machine not compatible w/ child node')	
		CURRENT_STATE.enter()
	
func _process(delta):
	CURRENT_STATE.update(delta)
	#Global.debug.add_property('Current State', CURRENT_STATE.name, 2)

func _physics_process(delta):
	CURRENT_STATE.physics_process(delta)

func on_child_transition(new_state_name: StringName) -> void:
	if not is_multiplayer_authority(): 
		return
	var new_state = states.get(new_state_name)
	if new_state != null:
		if new_state != CURRENT_STATE:
			CURRENT_STATE.exit()
			new_state.enter()
			CURRENT_STATE = new_state
		else:
			push_warning('State does not exist: ', new_state)
			
func set_state(state):
	# userlabel.text = state
	on_child_transition(state)
