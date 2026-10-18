class_name TargetReticle extends Control


var _rotate_tween: Tween
var _alpha_tween: Tween
var _keep_alive: float = 0.2


func _process(delta: float) -> void:
	if _rotate_tween == null or not _rotate_tween.is_running():
		_start_rotate()
	if _alpha_tween == null or not _alpha_tween.is_running():
		_start_alpha()
	if _keep_alive > 0:
		_keep_alive -= delta
		if _keep_alive > 0:
			return
		hide()


func _start_rotate() -> void:
	_rotate_tween = create_tween()
	_rotate_tween.tween_property(self, "rotation_degrees", randf() * 30.0 - 15.0, 1.0 + randf() * 2.0)


func _start_alpha() -> void:
	_alpha_tween = create_tween()
	_alpha_tween.tween_property(self, "modulate:a", 0.5 + randf() * .5, 1.0 + randf() * 2.0)


func hide_label() -> void:
	%Label.hide()
	%Sprite2D.show()
	_keep_alive = 0.2
	

func show_label() -> void:
	%Label.show()
	%Sprite2D.hide()
	_keep_alive = 0.2
