class_name LeaderOrder extends IMechanism


var _play: Play
var _ug: UnitGraphic
var _ability: Ability


func setup(play: Play, ug: UnitGraphic, ability: Ability) -> void:
	_play = play
	_ug = ug
	_ability = ability


func is_enabled() -> bool:
	return not _get_subbordinates().is_empty()


func does_support_human() -> bool:
	return true


func _get_subbordinates() -> Array[UnitGraphic]:
	var ret_val: Array[UnitGraphic] = []
	for ally: UnitGraphic in _play.get_all_units():
		if ally.is_dead():
			continue
		if ally == _ug:
			continue
		if ally._unit_stats.unit_side != _ug._unit_stats.unit_side:
			continue
		ret_val.append(ally)
	return ret_val


func update(mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
	var ability_layer: TileMapLayer = _play.get_ability_layer()
	ability_layer.clear()
	var best_dist: float = INF
	var best_map_loc: Vector2i = Vector2i.MIN
	var best_dir: Vector2i
	var best_ally: UnitGraphic
	for ally: UnitGraphic in _get_subbordinates():
		var map_loc: Vector2i = ability_layer.local_to_map(ally.position)
		for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]:
			if _play.get_unit_facing(ally) == dir:
				continue
			var offset_pos: Vector2 = ability_layer.map_to_local(dir + map_loc)
			var delta_pos: Vector2 = offset_pos - ally.position
			# We don't do .5 in case two allies are standing right next to each other
			var target_pos: Vector2 = ally.position + delta_pos * 0.475
			var dist_mouse_to_target_squared: float = mouse_local_pos.distance_squared_to(target_pos)
			if dist_mouse_to_target_squared < best_dist:
				best_dist = dist_mouse_to_target_squared
				best_dir = dir
				best_ally = ally
				best_map_loc = map_loc
	if best_dist == INF:
		return
	Walk.apply_movement_dir_cell(ability_layer, best_map_loc, best_dir)
	if mouse_pressed:
		_play.reduce_action_points(_ability.ap_cost)
		_play.add_animation_command(Callable(_turn_unit).bind(best_ally, best_dir))
		_play.await_command()


func _turn_unit(ac: AnimationCommand, ally: UnitGraphic, facing: Vector2i) -> void:
	var tween: Tween = _ug.create_tween()
	tween.tween_callback(Callable(_ug, "play_sound").bind(_ability.activation_sound))
	tween.tween_callback(Callable(_play, "_update_unit_facing").bind(ally, facing))
	tween.tween_callback(Callable(_play, "_update_fog_of_war"))
	_play.queue_finish(ac, tween)


func on_select() -> void:
	pass


func on_unselect() -> void:
	pass


# Foe considerations
func does_support_artificial_opponent() -> bool:
	return false


func get_priority() -> int:
	return 0


func try_invoke() -> bool:
	assert(false, "Not supported for moths")
	return false
