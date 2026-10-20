class_name AnimationStack extends Object

var _command: AnimationCommand = null
var _command_stack: Array[AnimationCommand] = []



func add_command(callable: Callable) -> void:
	_command_stack.append(AnimationCommand.from_callable(callable))


func complete_command(cmd: AnimationCommand) -> void:
	assert(cmd == _command)
	_command = null


## Returns true if still running
func update() -> bool:
	if _command:
		return true
		
	if _command_stack.is_empty():
		return false
	
	_command = _command_stack.pop_front()
	_command.start()
	return true
