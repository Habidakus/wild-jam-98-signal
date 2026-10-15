class_name UnitGraphic extends Area2D


var _unit_stats: Unit
var _hop_frame_count: int = 0


func set_unit(stats: Unit, show_facing_element: bool) -> void:
	_unit_stats = stats
	if show_facing_element:
		%FacingIcon.show()
	else:
		%FacingIcon.hide()
	if _unit_stats.sprite_frames != null:
		%AnimatedSprite2D.sprite_frames = _unit_stats.sprite_frames
		%AnimatedSprite2D.show()
		%AnimatedSprite2D.animation = "default"
		%AnimatedSprite2D.play()
		_hop_frame_count = %AnimatedSprite2D.sprite_frames.get_frame_count(&"hop")
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


func play_sound(sound: AudioStream) -> void:
	%AudioStreamPlayer2D.stream = sound
	%AudioStreamPlayer2D.play()


func stop_sound() -> void:
	%AudioStreamPlayer2D.stop()


func start_idle_animation() -> void:
	%AnimatedSprite2D.play("default")


func start_hop_animation(animate: bool) -> void:
	if _hop_frame_count == 0:
		return
	%AnimatedSprite2D.animation = "hop"
	if animate:
		%AnimatedSprite2D.play()
	else:
		%AnimatedSprite2D.frame = 0


func set_hop_animation_frame(fraction: float) -> void:
	if _hop_frame_count == 0:
		return
	var frame: int = int(float(_hop_frame_count) * clamp(fraction, 0.0, 0.9999))
	%AnimatedSprite2D.frame = frame


func get_abilities() -> Array[Ability]:
	return _unit_stats.abilities


func get_ability(mechanism: Ability.AbilityMechanism) -> Ability:
	for ability: Ability in _unit_stats.abilities:
		if ability.mechanism == mechanism:
			return ability
	return null
