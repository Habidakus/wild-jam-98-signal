class_name Hop extends IMechanism


const TURN_TIME: float = 0.5
const HOP_TIME: float = 0.5
const HOP_SOURCE_ID: int = 0
const HOP_ATLAS_SELECTED: Vector2i = Vector2i(1, 0)
const HOP_ATLAS_POTENTIAL: Vector2i = Vector2i(0, 0)


var _play: Play
var _ug: UnitGraphic
var _ability: Ability


func setup(play: Play, ug: UnitGraphic, ability: Ability) -> void:
	_play = play
	_ug = ug
	_ability = ability


func is_enabled() -> bool:
	return true


# Human considerations
func does_support_human() -> bool:
	return not _generate_hop_locations().is_empty()


func on_select() -> void:
	pass


func on_unselect() -> void:
	pass


func _generate_hop_locations() -> Array[Vector2i]:
	var terrain_layer: TileMapLayer = _play.get_terrain_layer()
	var ug_map_loc: Vector2i = terrain_layer.local_to_map(_ug.position)
	var command_potentials: Array[Vector2i]
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]:
		for i in range(1, _ability.ability_range):
			var hop_dest: Vector2i = d * i + ug_map_loc
			if terrain_layer.get_cell_source_id(hop_dest) == -1:
				break
			if _play.has_wall(hop_dest):
				break
			var child_at: Node = _play._get_child_at(hop_dest)
			if child_at != null:
				if child_at is MapObjectGraphic:
					if (child_at as MapObjectGraphic).blocks_hop():
						break
					else:
						continue
				if child_at is UnitGraphic:
					break
			command_potentials.append(hop_dest)
	return command_potentials


func update(mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
	var command_potentials: Array[Vector2i] = _generate_hop_locations()
	var ability_layer: TileMapLayer = _play.get_ability_layer()
	ability_layer.clear()
	var closest_squared_dist_to_mouse: float = INF
	var closest_map_loc_to_mouse: Vector2i = Vector2i.MIN
	for hop_dest: Vector2i in command_potentials:
		ability_layer.set_cell(hop_dest, HOP_SOURCE_ID, HOP_ATLAS_POTENTIAL)
		var vector_from_mouse: Vector2 = ability_layer.map_to_local(hop_dest) - mouse_local_pos
		var dist_squared_from_mouse: float = vector_from_mouse.length_squared()
		if dist_squared_from_mouse < closest_squared_dist_to_mouse:
			closest_map_loc_to_mouse = hop_dest
			closest_squared_dist_to_mouse = dist_squared_from_mouse
	if closest_map_loc_to_mouse == Vector2i.MIN:
		return
	ability_layer.set_cell(closest_map_loc_to_mouse, HOP_SOURCE_ID, HOP_ATLAS_SELECTED)
	if not mouse_pressed:
		return
	_ug.start_hop_animation(false)
	_play.reduce_action_points(_ability.ap_cost)
	_ug.play_sound(_ability.activation_sound)
	var ug_map_loc: Vector2i = ability_layer.local_to_map(_ug.position)
	var ug_facing: Vector2i = _play.get_current_unit_facing()
	var delta: Vector2i = (closest_map_loc_to_mouse - ug_map_loc)
	delta = delta / delta.length()
	if delta != ug_facing:
		if delta + ug_facing == Vector2i.ZERO:
			var mid: Vector2i = Vector2i(1, 0) if delta.x == 0 else Vector2i(0, 1)
			if randi() % 2 == 0:
				mid = mid * Vector2i(-1, -1)
			_play.add_animation_command(Callable(_turn_frog_animation_command).bind(mid))
			_play.add_animation_command(Callable(_turn_frog_animation_command).bind(delta))
		else:
			_play.add_animation_command(Callable(_turn_frog_animation_command).bind(delta))
	_play.add_animation_command(Callable(_frog_hop_animation_command).bind(ability_layer.map_to_local(closest_map_loc_to_mouse)))
	_play.await_command()


func _turn_frog_animation_command(ac: AnimationCommand, dir: Vector2) -> void:
	var tween: Tween = _ug.create_tween()
	tween.tween_interval(TURN_TIME)
	tween.tween_callback(Callable(_play, "_update_current_unit_facing").bind(dir))
	tween.tween_callback(Callable(_play, "_update_fog_of_war"))
	_play.queue_finish(ac, tween)


func _frog_hop_animation_command(ac: AnimationCommand, destination: Vector2) -> void:
	var tween: Tween = _ug.create_tween()
	tween.tween_callback(Callable(_play.get_ability_layer(), "clear"))
	tween.tween_property(_ug, "position", destination, HOP_TIME)
	tween.parallel()
	tween.tween_method(Callable(_ug, "set_hop_animation_frame"), 0.0, 1.0, HOP_TIME)
	tween.tween_callback(Callable(_ug, "start_idle_animation"))
	tween.tween_callback(Callable(_play, "_update_fog_of_war"))
	_play._move_camera_animation_command(ac, destination, 0.1) # will clean up AnimationCommand for us


func does_support_artificial_opponent() -> bool:
	return false


func get_priority() -> int:
	return 50


func invoke() -> void:
	assert(false, "not implemeneted")
