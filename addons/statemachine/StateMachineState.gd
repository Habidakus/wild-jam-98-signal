class_name StateMachineState extends Control
## Base class that all state machine states should implement.

## Any object that needs to know when a particular state is entered can listen for this signal
signal state_enter
## Any object that needs to know when a particular state is left can listen for this signal
signal state_exit

## If a state needs to call into their own state machine, this is a handy reference that can
## be used; most commonly for the [code]our_state_machine.switch_state("NewState")[/code] invocation.
var our_state_machine : StateMachine
var _active_process_mode : ProcessMode
var _on_complete_callback : Callable

## When the parent [StateMachine] registers each state (which happens in the [method StateMachine._ready] function)
## it calls into the state's [method init_state] function. Your own extensions of StateMachineState
## can implement their own version of init_state(), just be sure to call [code]super.init_state(state_machine)[/code] within your own implementation.
func init_state(state_machine: StateMachine) -> void:
	_active_process_mode = self.process_mode
	our_state_machine = state_machine
	self.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	self.hide()

## When your state is started up, the [method enter_state] function will be called. Be sure to also invoke the parent function with [code]super.enter_state()[/code]
func enter_state() -> void:
	self.process_mode = _active_process_mode
	self.show()
	state_enter.emit()

func _set_completion_call(callback_on_exit_complete : Callable) -> void:
	_on_complete_callback = callback_on_exit_complete

## When your state has been told to shutdown, because we are transitioning to another state, this
## function will be called. If you implement your own version of [method exit_state] then you must,
## at some point, invoke [code]super.exit_state(next_method)[/code] because the next state cannot
## start until base class's exit_state() is invoked. However, you can make use if this if you need
## to perform some cleanup, or fade out a schene, or perform some exit code... delaying until done
## and only then calling [code]super.exit_state(next_method)[/code]
func exit_state(_next_state: StateMachineState) -> void:
	self.process_mode = ProcessMode.PROCESS_MODE_DISABLED
	self.hide()
	state_exit.emit()
	_on_complete_callback.call()
