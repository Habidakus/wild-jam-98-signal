class_name AnimationCommand extends RefCounted


var _callable: Callable


static func from_callable(callable: Callable) -> AnimationCommand:
	var ret_val: AnimationCommand = AnimationCommand.new()
	ret_val._callable = callable
	return ret_val


func queue_finish(tween: Tween, animation_stack: AnimationStack) -> void:
	tween.tween_callback(Callable(animation_stack, "complete_command").bind(self))


func start() -> void:
	_callable.call(self)
