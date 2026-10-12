class_name UnitGraphic extends Area2D


var _unit_stats: Unit


func _ready() -> void:
	%FacingIcon.hide()


func set_unit(stats: Unit) -> void:
	_unit_stats = stats
	%UnitIcon.texture = _unit_stats.texture


func set_facing(facing: Vector2i) -> void:
	if facing == Vector2i.UP:
		%FacingIcon.rotation_degrees = 0
		%FacingIcon.show()
	elif facing == Vector2i.DOWN:
		%FacingIcon.rotation_degrees = 180
		%FacingIcon.show()
	elif facing == Vector2i.RIGHT:
		%FacingIcon.rotation_degrees = 90
		%FacingIcon.show()
	elif facing == Vector2i.LEFT:
		%FacingIcon.rotation_degrees = 270
		%FacingIcon.show()
	else:
		%FacingIcon.hide()
