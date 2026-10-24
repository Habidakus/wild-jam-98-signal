class_name Charge extends IMechanism

var _play: Play
var _ug: UnitGraphic
var _ability: Ability
var _target_potential_scene: PackedScene = preload("res://scenes/potential_target.tscn")


func setup(play: Play, ug: UnitGraphic, ability: Ability) -> void:
	_play = play
	_ug = ug
	_ability = ability


func is_enabled() -> bool:
	return true


func does_support_human() -> bool:
	return true


func on_select() -> void:
	pass


func on_unselect() -> void:
	pass


func update(mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
	var ability_layer: TileMapLayer = _play.get_ability_layer()
	ability_layer.clear()
	var closest_target_dist_to_mouse: float = INF
	var closest_foe_to_mouse: UnitGraphic
	var path_to_foe: Array[Vector2i]
	var ug_map_loc: Vector2i = ability_layer.local_to_map(_ug.position)
	for foe_ug: UnitGraphic in _play.get_all_units():
		if foe_ug.is_dead() or foe_ug._unit_stats.unit_side == _ug._unit_stats.unit_side:
			continue
		var foe_map_loc: Vector2i = ability_layer.local_to_map(foe_ug.position)
		if abs(foe_map_loc.x - ug_map_loc.x) + abs(foe_map_loc.y - ug_map_loc.y) > _ability.ability_range:
			continue
		var path: Array[Vector2i] = _play._try_get_path(ug_map_loc, foe_map_loc, _ability.ability_range, Play.PathLogic.DIRECT_RUN, [foe_ug], false)
		if path.is_empty():
			continue
		var vector_to_mouse: Vector2 = mouse_local_pos - foe_ug.position
		var dist_squared_from_mouse: float = vector_to_mouse.length_squared()
		if dist_squared_from_mouse < closest_target_dist_to_mouse:
			closest_foe_to_mouse = foe_ug
			closest_target_dist_to_mouse = dist_squared_from_mouse
			path_to_foe = path
	var target_instance: Control = _play.get_charge_reticle()
	var facing: Vector2i = _play.get_current_unit_facing()
	target_instance.show()
	var terrain_layer: TileMapLayer = _play.get_terrain_layer()
	if closest_foe_to_mouse == null:
		target_instance.position = ability_layer.map_to_local(ug_map_loc + facing * _ability.ability_range)
		target_instance.show_label()
		if not mouse_pressed:
			return
		for x in range(ug_map_loc.x - _ability.ability_range, ug_map_loc.x + _ability.ability_range + 1):
			for y in range(ug_map_loc.y - _ability.ability_range, ug_map_loc.y + _ability.ability_range + 1):
				if abs(x - ug_map_loc.x) + abs(y - ug_map_loc.y) > _ability.ability_range:
					continue
				var ping_map_loc: Vector2i = Vector2i(x, y)
				if _play.has_wall(ping_map_loc):
					continue
				if terrain_layer.get_cell_source_id(ping_map_loc) < 0:
					continue
				var o: Node = _play._get_child_at(ping_map_loc)
				if o != null:
					if (o is MapObjectGraphic):
						if (o as MapObjectGraphic).blocks_walk():
							continue
					elif (o is UnitGraphic):
						continue
				var path: Array[Vector2i] = _play._try_get_path(ug_map_loc, ping_map_loc, _ability.ability_range, Play.PathLogic.DIRECT_RUN, [], false)
				if path.is_empty():
					continue
				var potential_target: Sprite2D = _target_potential_scene.instantiate()
				potential_target.position = ability_layer.map_to_local(ping_map_loc)
				ability_layer.add_child(potential_target)
		return
	target_instance.position = closest_foe_to_mouse.position
	target_instance.hide_label()
	if path_to_foe[0] != ug_map_loc:
		path_to_foe.insert(0, ug_map_loc)
	if path_to_foe.size() > 1:
		var final_facing: Vector2i = path_to_foe[path_to_foe.size() - 1] - path_to_foe[path_to_foe.size() - 2]
		target_instance.set_facing(final_facing)
	if not mouse_pressed:
		return
	_play.add_animation_command(Callable(_play, "_move_camera_animation_command").bind(closest_foe_to_mouse.position, 0.1))
	_play.add_animation_command(Callable(_frog_charge_animation_command).bind(closest_foe_to_mouse, path_to_foe))
	_play._kill(closest_foe_to_mouse)
	_play.reduce_action_points(-1)
	_play.await_command()


func _frog_charge_animation_command(ac: AnimationCommand, target: UnitGraphic, path_frog_to_moth: Array[Vector2i]) -> void:
	var tween: Tween = _ug.create_tween()
	var terrain_layer: TileMapLayer = _play.get_terrain_layer()
	for i in range(1, path_frog_to_moth.size()):
		var leaving_spot: Vector2i = path_frog_to_moth[i - 1]
		var arriving_spot: Vector2i = path_frog_to_moth[i]
		var arriving_pos: Vector2 = terrain_layer.map_to_local(arriving_spot)
		var facing = arriving_spot - leaving_spot
		tween.tween_callback(Callable(self, "_update_current_unit_facing").bind(facing))
		tween.tween_callback(Callable(self, "_update_fog_of_war"))
		tween.tween_property(_ug, "position", arriving_pos, Play.CHARGE_TIME / (path_frog_to_moth.size() - 1.0))
	tween.tween_property(_ug, "position", target.position, 0.0)
	tween.tween_callback(Callable(_ug, "start_idle_animation"))
	tween.tween_callback(Callable(self, "_update_fog_of_war"))
	_play.queue_finish(ac, tween)


func does_support_artificial_opponent() -> bool:
	return false


func get_priority() -> int:
	return 90


func try_invoke() -> bool:
	assert(false, "Not supported for moths")
	return false
