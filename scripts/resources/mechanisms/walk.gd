class_name Walk extends IMechanism


const WALK_SOURCE_ID: int = 1
const WALK_TIME: float = 0.5
const WALK_ATLAS_POTENTIAL: Vector2i = Vector2i(0, 0)
const WALK_ATLAS_SELECTED: Vector2i = Vector2i(1, 0)
const WALK_ATLAS_UP: Vector2i = Vector2i(2, 0)
const WALK_ATLAS_RIGHT: Vector2i = Vector2i(3, 0)
const WALK_ATLAS_DOWN: Vector2i = Vector2i(4, 0)
const WALK_ATLAS_LEFT: Vector2i = Vector2i(5, 0)


var _squish_sound: AudioStream = preload("res://sounds/swampfoot.tres")


func is_enabled(play: Play, ug: UnitGraphic) -> bool:
	return _generate_walk_paths(play, ug, 1).keys().size() > 1


# Human considerations
func does_support_human() -> bool:
	return true


func _generate_walk_paths(play: Play, ug: UnitGraphic, max_dist: int) -> Dictionary[Vector2i, Array]:
	var terrain_layer: TileMapLayer = play.get_terrain_layer()
	var ug_map_loc: Vector2i = terrain_layer.local_to_map(ug.position)
	var walk_path: Dictionary[Vector2i, Array] = {}
	#var closest_squared_dist_to_mouse: float = INF
	#var closest_map_loc_to_mouse: Vector2i = Vector2i.MIN
	#var closest_map_loc_delta_to_mouse: Vector2
	walk_path[ug_map_loc] = [0, []]
	for distance: int in range(0, max_dist):
		for map_loc: Vector2i in walk_path.keys():
			var map_loc_dist: int = walk_path[map_loc][0]
			if map_loc_dist == distance:
				var map_loc_path: Array = walk_path[map_loc][1]
				for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]:
					var step_dest: Vector2i = d + map_loc
					if terrain_layer.get_cell_source_id(step_dest) == -1:
						continue
					if play.has_wall(step_dest):
						continue
					#var step_coord: int = play.map_to_coord(step_dest)
					var child_at: Node = play._get_child_at(step_dest)
					if child_at != null:
						if child_at is MapObjectGraphic:
							if (child_at as MapObjectGraphic).blocks_walk():
								continue
						elif child_at is UnitGraphic:
							if child_at != ug and not child_at.is_dead():
								continue
					var step_cost: int = map_loc_dist + 1
					if play._get_terrain_type(step_dest) == Play.TerrainType.SWAMP:
						step_cost += 1
					if walk_path.has(step_dest):
						if walk_path[step_dest][0] <= step_cost:
							continue
					var new_path: Array = map_loc_path.duplicate()
					new_path.append(map_loc)
					walk_path[step_dest] = [step_cost, new_path]
	return walk_path


var _play: Play
var _ug: UnitGraphic
var _ability: Ability
func on_select(play: Play, ug: UnitGraphic, ability: Ability) -> void:
	_play = play
	_ug = ug
	_ability = ability


func on_unselect() -> void:
	_play = null
	_ug = null
	_ability = null


func update(mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
	var walk_path: Dictionary[Vector2i, Array] = _generate_walk_paths(_play, _ug, _ability.ability_range)
	var ability_layer: TileMapLayer = _play.get_ability_layer()

	#var vector_to_mouse: Vector2 = mouse_local_pos - terrain_layer.map_to_local(step_dest) 
	#var dist_squared_from_mouse: float = vector_to_mouse.length_squared()

	var closest_squared_dist_to_mouse: float = INF
	var closest_map_loc_to_mouse: Vector2i
	var closest_map_loc_delta_to_mouse: Vector2
	for map_loc: Vector2i in walk_path.keys():
		var key_pos: Vector2 = ability_layer.map_to_local(map_loc)
		var dist_squared_from_mouse: float = key_pos.distance_squared_to(mouse_local_pos)
		if dist_squared_from_mouse < closest_squared_dist_to_mouse:
			closest_map_loc_to_mouse = map_loc
			closest_map_loc_delta_to_mouse = mouse_local_pos - key_pos
			closest_squared_dist_to_mouse = dist_squared_from_mouse
	ability_layer.clear()
	for loc: Vector2i in walk_path.keys():
		ability_layer.set_cell(loc, WALK_SOURCE_ID, WALK_ATLAS_POTENTIAL)
	if closest_map_loc_to_mouse != Vector2i.MIN:
		var mouse_path: Array = walk_path[closest_map_loc_to_mouse][1]
		for loc: Vector2i in mouse_path:
			ability_layer.set_cell(loc, WALK_SOURCE_ID, WALK_ATLAS_SELECTED)
		var norm: Vector2 = closest_map_loc_delta_to_mouse.normalized()
		var max_dot: float = -100.0
		var best_atlas: Vector2i = Vector2i.MIN
		var final_facing: Vector2i = Vector2i.MIN
		for d_tupple in [[Vector2i.UP, WALK_ATLAS_UP], [Vector2i.RIGHT, WALK_ATLAS_RIGHT], [Vector2i.DOWN, WALK_ATLAS_DOWN], [Vector2i.LEFT, WALK_ATLAS_LEFT]]:
			var dot: float = Vector2(d_tupple[0]).dot(norm)
			if dot > max_dot:
				max_dot = dot
				best_atlas = d_tupple[1]
				final_facing = d_tupple[0]
		if best_atlas != Vector2i.MIN:
			ability_layer.set_cell(closest_map_loc_to_mouse, WALK_SOURCE_ID, best_atlas)
		if mouse_pressed:
			_play.reduce_action_points(_ability.ap_cost)
			var full_path: Array = mouse_path.duplicate()
			if full_path.is_empty():
				full_path.append(closest_map_loc_to_mouse)
			elif full_path[full_path.size() - 1] != closest_map_loc_to_mouse:
				full_path.append(closest_map_loc_to_mouse)
			_play.add_animation_command(Callable(_frog_walk_animation_command).bind(full_path, final_facing))
			var final_position: Vector2 = ability_layer.map_to_local(closest_map_loc_to_mouse)
			_play.add_animation_command(Callable(_play, "_move_camera_animation_command").bind(final_position, 0.4))
			_play.await_command()


func _frog_walk_animation_command(ac: AnimationCommand, path: Array, final_facing: Vector2i) -> void:
	_ug.start_hop_animation(true)
	var playing_path_sound: bool = false
	var tween: Tween = _ug.create_tween()
	var ability_layer: TileMapLayer = _play.get_ability_layer()
	for i in range(1, path.size()):
		var leaving_spot: Vector2i = path[i - 1]
		var terrain_type: Play.TerrainType = _play._get_terrain_type(leaving_spot)
		match terrain_type:
			Play.TerrainType.DIRT:
				if not playing_path_sound:
					playing_path_sound = true
					tween.tween_callback(Callable(_ug, "play_sound").bind(_ability.activation_sound))
			Play.TerrainType.SWAMP:
				playing_path_sound = false
				tween.tween_callback(Callable(_ug, "play_sound").bind(_squish_sound))
			_:
				print("Frog at %s on unknown terrain: %s" % [leaving_spot, Play.TerrainType.keys()[terrain_type]])
		var arriving_spot: Vector2i = path[i]
		var arriving_pos: Vector2 = ability_layer.map_to_local(arriving_spot)
		var facing = arriving_spot - leaving_spot
		tween.tween_callback(Callable(_play, "_update_current_unit_facing").bind(facing))
		tween.tween_callback(Callable(_play, "_update_fog_of_war"))
		tween.tween_property(_ug, "position", arriving_pos, WALK_TIME) # / (path.size() - 1.0))
	tween.tween_callback(Callable(ability_layer, "clear"))
	var final_pos: Vector2 = ability_layer.map_to_local(path.back())
	tween.tween_property(_ug, "position", final_pos, 0.0)
	tween.tween_callback(Callable(_ug, "start_idle_animation"))
	tween.tween_callback(Callable(_play, "_update_current_unit_facing").bind(final_facing))
	tween.tween_callback(Callable(_play, "_update_fog_of_war"))
	_play.queue_finish(ac, tween)


# Foe considerations
func does_support_artificial_opponent() -> bool:
	return false


func get_priority() -> int:
	return 60


func invoke() -> void:
	assert(false, "Not supported for moths")
