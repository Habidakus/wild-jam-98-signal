class_name RibbitRadar extends IMechanism


const SONAR_SPEED: float = 320.0


var ping_scene: PackedScene = preload("res://scenes/ping.tscn")
var _play: Play
var _ug: UnitGraphic
var _ability: Ability


func setup(play: Play, ug: UnitGraphic, ability: Ability) -> void:
	_play = play
	_ug = ug
	_ability = ability


func is_enabled(_play: Play, _ug: UnitGraphic) -> bool:
	return true


func does_support_human() -> bool:
	return true


func update(_mouse_pressed: bool, _mouse_local_pos: Vector2) -> void:
	assert(false, "Should not be invoked")


func on_select() -> void:
	var ability_layer: TileMapLayer = _play.get_ability_layer()
	ability_layer.clear()
	_play.reduce_action_points(_ability.ap_cost)
	_play.add_animation_command(Callable(_ribbit_animation_command).bind(_play, _ug, _ability))
	_play.await_command() # _play_state = PlayState.ANIMATING_COMMAND


func _ribbit_animation_command(ac: AnimationCommand, play: Play, source: UnitGraphic, ability: Ability) -> void:
	source.play_sound(ability.activation_sound)
	var max_delay: float = 0
	for entity_ug: UnitGraphic in play.get_all_units():
		if entity_ug.is_dead():
			continue
		if entity_ug._unit_stats.unit_side != Unit.UnitSide.MOTH:
			continue
		var dist: float = (source.position - entity_ug.position).length()
		var delay: float = dist / SONAR_SPEED
		var radar_tween: Tween = source.create_tween()
		radar_tween.tween_interval(delay)
		radar_tween.tween_callback(_create_ping.bind(entity_ug.position, play.get_ability_layer()))
		if delay > max_delay:
			max_delay = delay
	var zoom_tween: Tween = source.create_tween()
	var camera: Camera2D = play.get_camera() # %Camera2D
	zoom_tween.tween_property(camera, "zoom", play.CROAK_ZOOM, 1.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if max_delay > 1.8 + 0.8:
		zoom_tween.tween_interval(max_delay - (1.8 + 0.8))
	zoom_tween.tween_property(camera, "zoom", play.STANDARD_ZOOM, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	play.queue_finish(ac, zoom_tween) # ac.queue_finish(zoom_tween, _animation_stack)


func _create_ping(pos: Vector2, ability_layer: TileMapLayer) -> void:
	var ping: Control = ping_scene.instantiate()
	ping.position = pos
	ability_layer.add_child(ping)


func on_unselect() -> void:
	pass


# Foe considerations
func does_support_artificial_opponent() -> bool:
	return false


func get_priority() -> int:
	return 0


func invoke() -> void:
	assert(false, "Should not be invoked")
