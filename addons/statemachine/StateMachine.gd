class_name StateMachine extends Node
## The manager class for a control node state machine.
##
## All states (implementing [StateMachineState]) for this state machine should live as immediate
## children of the [StateMachine] node in the tree.
##
## An example of this code being used can be found at https://github.com/Habidakus/min-max-godot-addon
## where this addon is also located.

## Indicates which [StateMachineState] instance should be the start state when the state machine starts up, 
@export var initial_state : StateMachineState = null

## A list of all registered states
var all_states : Array = []
## Which state is currently running
var current_state : StateMachineState = null

func _ready() -> void:
	for child in get_children():
		if child is StateMachineState:
			_register_state(child)
	_switch_state_internal(initial_state)

func _register_state(state: StateMachineState) -> void:
	all_states.append(state)
	state.init_state(self)

func _begin_state(state: StateMachineState) -> void:
	current_state = state
	if state != null:
		state.enter_state()

func _switch_state_internal(state: StateMachineState) -> void:
	if current_state == state:
		print("Already in state " + state.name + ", aborting state switch")
		return
	if current_state != null:
		var callback : Callable = Callable(self, "_begin_state")
		current_state._set_completion_call(callback.bind(state))
		current_state.exit_state(state)
	else:
		_begin_state(state)

## Called when the state machine should transition to another state
func switch_state(next_state_name: String) -> void:
	for state : StateMachineState in all_states:
		if state.name == next_state_name:
			_switch_state_internal(state)
			return
	assert(false, "{0} is not a valid state".format([next_state_name]))
