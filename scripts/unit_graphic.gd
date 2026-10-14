class_name UnitGraphic extends Area2D


var _unit_stats: Unit


func set_unit(stats: Unit, show_facing_element: bool) -> void:
	_unit_stats = stats
	if show_facing_element:
		%FacingIcon.show()
	else:
		%FacingIcon.hide()
	if _unit_stats.sprite_frames != null:
		%AnimatedSprite2D.sprite_frames = _unit_stats.sprite_frames
		%AnimatedSprite2D.show()
		%AnimatedSprite2D.play()
		%AnimatedSprite2D.animation = "default"
		%UnitIcon.hide()
	elif _unit_stats.texture != null:
		%AnimatedSprite2D.hide()
		%UnitIcon.texture = _unit_stats.texture
		%UnitIcon.show()
	else:
		print("ERROR: No animated sprite or unit icon for %s" % [stats.resource_name])


func set_facing(facing: Vector2i) -> void:
	if facing == Vector2i.UP:
		%FacingIcon.rotation_degrees = 0
	elif facing == Vector2i.DOWN:
		%FacingIcon.rotation_degrees = 180
	elif facing == Vector2i.RIGHT:
		%FacingIcon.rotation_degrees = 90
		%UnitIcon.flip_h = true
		%AnimatedSprite2D.flip_h = true
	elif facing == Vector2i.LEFT:
		%FacingIcon.rotation_degrees = 270
		%UnitIcon.flip_h = false
		%AnimatedSprite2D.flip_h = false
	else:
		print("ERROR: Bad facing %s for %s" % [str(facing), _unit_stats.unit_name])


func get_abilities() -> Array[Ability]:
	return _unit_stats.abilities


func get_illumination_ability() -> Ability:
	for ability: Ability in _unit_stats.abilities:
		if ability.mechanism == Ability.AbilityMechanism.ILLUMINATE:
			return ability
	return null
