class_name StateMachineState_PressAnyKey extends StateMachineState
## Simple control state that will stay up until the user hits a key or clicks a mouse

## This is the next control state that we should transition to after the user hits a key
@export var next_state : StateMachineState
## If positive then the page will automatically transition in this many seconds, regardless of key press
@export var time_out_in_seconds : float = -1

## If we want to fade this page in, set this to true
@export var fade_in : bool = false
## If we want to fade this page out on transition to the next page, set this to true
@export var fade_out : bool = false
## Dictates how many seconds the page will spend both fading in and fading out
@export var fade_time : float = 1.5

var _countdown : float = 0
var _leave_tween : Tween = null

func _process(delta: float) -> void:
	if time_out_in_seconds > 0:
		_countdown += delta
		if _countdown > time_out_in_seconds:
			our_state_machine.switch_state(next_state.name)

func _input(event : InputEvent) -> void:
	_handle_event(event)

func _unhandled_input(event : InputEvent) -> void:
	_handle_event(event)

func _handle_event(event : InputEvent) -> void:
	# We process on "released" instead of pressed because otherwise immediately
	# switching screens could still have the mouse being pressed on some other
	# screen's button.
	if process_mode == ProcessMode.PROCESS_MODE_DISABLED:
		return
		
	if _leave_tween == null:
		if event.is_released():
			if event is InputEventKey:
				our_state_machine.switch_state(next_state.name)
			if event is InputEventMouseButton:
				our_state_machine.switch_state(next_state.name)

func exit_state(next_state: StateMachineState) -> void:
	if !fade_out:
		super.exit_state(next_state)
		return
	
	if _leave_tween != null && _leave_tween.is_running():
		return

	_leave_tween = get_tree().create_tween()
	self.modulate = Color(Color.WHITE, 1)
	var destination_color : Color = Color(Color.WHITE, 0)
	_leave_tween.tween_property(self, "modulate", destination_color, fade_time)
	var when_finished_callback : Callable = Callable(self, "_on_leave_tween_finished")
	_leave_tween.tween_callback(when_finished_callback.bind(next_state))

func _on_leave_tween_finished(next_state: StateMachineState) -> void:
	super.exit_state(next_state)
	_leave_tween = null

func enter_state() -> void:
	super.enter_state()
	_countdown = 0
	_leave_tween = null
	if fade_in:
		self.modulate = Color(Color.WHITE, 0)
		var tween : Tween = get_tree().create_tween()
		var destination_color : Color = Color(Color.WHITE, 1)
		tween.tween_property(self, "modulate", destination_color, fade_time)
	
