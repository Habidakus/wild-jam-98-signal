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


func set_facing(facing: Vector2i) -> void:
	match facing:
		Vector2i.UP:
			%Sprite2D.rotation_degrees = 0
		Vector2i.RIGHT:
			%Sprite2D.rotation_degrees = 90
		Vector2i.DOWN:
			%Sprite2D.rotation_degrees = 180
		Vector2i.LEFT:
			%Sprite2D.rotation_degrees = 270
		_:
			assert(false, "UNKNOWN ROTATION FOR TARGETTING")


func _start_rotate() -> void:
	_rotate_tween = create_tween()
	_rotate_tween.tween_property(self, "rotation_degrees", randf() * 20.0 - 10.0, 1.0 + randf() * 2.0)


func _start_alpha() -> void:
	_alpha_tween = create_tween()
	_alpha_tween.tween_property(self, "modulate:a", 0.4 + randf() * .6, 0.5 + randf() * 1.0)


func hide_label() -> void:
	%Label.hide()
	%Sprite2D.show()
	_keep_alive = 0.2
	

func show_label() -> void:
	%Label.show()
	%Sprite2D.hide()
	_keep_alive = 0.2
