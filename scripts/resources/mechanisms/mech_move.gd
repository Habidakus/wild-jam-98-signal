class_name Walk extends IMechanism


@export var _is_flying: bool = false


const MOVE_SOURCE_ID: int = 1
const MOVE_TIME: float = 0.5
const MOVE_ATLAS_POTENTIAL: Vector2i = Vector2i(0, 0)
const MOVE_ATLAS_SELECTED: Vector2i = Vector2i(1, 0)
const MOVE_ATLAS_UP: Vector2i = Vector2i(2, 0)
const MOVE_ATLAS_RIGHT: Vector2i = Vector2i(3, 0)
const MOVE_ATLAS_DOWN: Vector2i = Vector2i(4, 0)
const MOVE_ATLAS_LEFT: Vector2i = Vector2i(5, 0)


var _squish_sound: AudioStream = preload("res://sounds/swampfoot.tres")
var _play: Play
var _ug: UnitGraphic
var _ability: Ability
var _can_enter_light: bool = true


func setup(play: Play, ug: UnitGraphic, ability: Ability) -> void:
	_play = play
	_ug = ug
	_ability = ability
	_can_enter_light = ug.can_enter_light()


func is_enabled() -> bool:
	return _generate_move_paths(_play, _ug, 1).keys().size() > 1


func does_support_human() -> bool:
	return true


enum BlockageType { NONE, BLOCKS, JUST_CANT_STOP_HERE }
func _get_node_blockage_type(node: Node) -> BlockageType:
	if node == null or node == _ug:
		return BlockageType.NONE
	if node is UnitGraphic:
		if node.is_dead():
			return BlockageType.JUST_CANT_STOP_HERE
		else:
			return BlockageType.BLOCKS
	if node is MapObjectGraphic:
		var mog: MapObjectGraphic = (node as MapObjectGraphic)
		if mog.blocks_fly():
			return BlockageType.BLOCKS
		if mog.blocks_walk():
			if _is_flying:
				return BlockageType.JUST_CANT_STOP_HERE
			else:
				return BlockageType.BLOCKS
	return BlockageType.NONE


func _generate_move_paths(play: Play, ug: UnitGraphic, max_dist: int) -> Dictionary[Vector2i, Array]:
	var terrain_layer: TileMapLayer = play.get_terrain_layer()
	var ug_map_loc: Vector2i = terrain_layer.local_to_map(ug.position)
	var move_path: Dictionary[Vector2i, Array] = {}
	move_path[ug_map_loc] = [0, [], false]
	for distance: int in range(0, max_dist):
		for map_loc: Vector2i in move_path.keys():
			var map_loc_dist: int = move_path[map_loc][0]
			if map_loc_dist == distance:
				var map_loc_path: Array = move_path[map_loc][1]
				for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]:
					var step_dest: Vector2i = d + map_loc
					if terrain_layer.get_cell_source_id(step_dest) == -1:
						continue
					if play.has_wall(step_dest):
						continue
					if not _can_enter_light and play._is_map_loc_in_light(step_dest):
						continue
					var blockage_type: BlockageType = _get_node_blockage_type(play._get_child_at(step_dest))
					if blockage_type == BlockageType.BLOCKS:
						continue
					var cant_stop_here: bool = blockage_type == BlockageType.JUST_CANT_STOP_HERE
					var step_cost: int = map_loc_dist + 1
					if play._get_terrain_type(step_dest) == Play.TerrainType.SWAMP:
						if not _is_flying:
							step_cost += 1
					if move_path.has(step_dest):
						if move_path[step_dest][0] <= step_cost:
							continue
					var new_path: Array = map_loc_path.duplicate()
					new_path.append(map_loc)
					move_path[step_dest] = [step_cost, new_path, cant_stop_here]
	return move_path


func on_select() -> void:
	pass


func on_unselect() -> void:
	pass


func update(mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
	var move_path: Dictionary[Vector2i, Array] = _generate_move_paths(_play, _ug, _ability.ability_range)
	var ability_layer: TileMapLayer = _play.get_ability_layer()
	var closest_squared_dist_to_mouse: float = INF
	var closest_map_loc_to_mouse: Vector2i
	var closest_map_loc_delta_to_mouse: Vector2
	for map_loc: Vector2i in move_path.keys():
		if move_path[map_loc][2] == true:
			continue
		var key_pos: Vector2 = ability_layer.map_to_local(map_loc)
		var dist_squared_from_mouse: float = key_pos.distance_squared_to(mouse_local_pos)
		if dist_squared_from_mouse < closest_squared_dist_to_mouse:
			closest_map_loc_to_mouse = map_loc
			closest_map_loc_delta_to_mouse = mouse_local_pos - key_pos
			closest_squared_dist_to_mouse = dist_squared_from_mouse
	ability_layer.clear()
	for loc: Vector2i in move_path.keys():
		ability_layer.set_cell(loc, MOVE_SOURCE_ID, MOVE_ATLAS_POTENTIAL)
	if closest_map_loc_to_mouse != Vector2i.MIN:
		var mouse_path: Array = move_path[closest_map_loc_to_mouse][1]
		for loc: Vector2i in mouse_path:
			ability_layer.set_cell(loc, MOVE_SOURCE_ID, MOVE_ATLAS_SELECTED)
		var norm: Vector2 = closest_map_loc_delta_to_mouse.normalized()
		var max_dot: float = -100.0
		var final_facing: Vector2i = Vector2i.MIN
		for facing: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var dot: float = Vector2(facing).dot(norm)
			if dot > max_dot:
				max_dot = dot
				final_facing = facing
		if final_facing != Vector2i.MIN:
			apply_movement_dir_cell(ability_layer, closest_map_loc_to_mouse, final_facing)
		if mouse_pressed:
			if mouse_path.is_empty():
				mouse_path.append(closest_map_loc_to_mouse)
			elif mouse_path[mouse_path.size() - 1] != closest_map_loc_to_mouse:
				mouse_path.append(closest_map_loc_to_mouse)
			_invoke(mouse_path, final_facing)
			var final_position: Vector2 = ability_layer.map_to_local(closest_map_loc_to_mouse)
			_play.add_animation_command(Callable(_play, "_move_camera_animation_command").bind(final_position, 0.4))
			_play.await_command()


static func apply_movement_dir_cell(ability_layer: TileMapLayer, map_loc: Vector2i, dir: Vector2i) -> void:
	match dir:
		Vector2i.UP:
			ability_layer.set_cell(map_loc, MOVE_SOURCE_ID, MOVE_ATLAS_UP)
		Vector2i.DOWN:
			ability_layer.set_cell(map_loc, MOVE_SOURCE_ID, MOVE_ATLAS_DOWN)
		Vector2i.RIGHT:
			ability_layer.set_cell(map_loc, MOVE_SOURCE_ID, MOVE_ATLAS_RIGHT)
		Vector2i.LEFT:
			ability_layer.set_cell(map_loc, MOVE_SOURCE_ID, MOVE_ATLAS_LEFT)
		_:
			print("Bad direction given to apply_movement_dir_cell(%s)" % [dir])


func _invoke(path: Array, final_facing: Vector2) -> void:
	_play.reduce_action_points(_ability.ap_cost)
	_play.add_animation_command(Callable(_move_animation_command).bind(path, final_facing))


func _move_animation_command(ac: AnimationCommand, path: Array, final_facing: Vector2) -> void:
	_ug.start_hop_animation(true)
	var playing_path_sound: bool = false
	var tween: Tween = _ug.create_tween()
	var ability_layer: TileMapLayer = _play.get_ability_layer()
	for i in range(1, path.size()):
		var leaving_spot: Vector2i = path[i - 1]
		if _is_flying:
			tween.tween_callback(Callable(_ug, "play_sound").bind(_ability.activation_sound))
		else:
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
		var d: float = 0.0
		if not _play._is_map_loc_completely_dark(arriving_spot) or not _play._is_map_loc_completely_dark(leaving_spot):
			d = MOVE_TIME
		tween.tween_property(_ug, "position", arriving_pos, d)
	tween.tween_callback(Callable(ability_layer, "clear"))
	var final_pos: Vector2 = ability_layer.map_to_local(path.back())
	tween.tween_property(_ug, "position", final_pos, 0.0)
	tween.tween_callback(Callable(_ug, "start_idle_animation"))
	tween.tween_callback(Callable(_play, "_update_current_unit_facing").bind(final_facing))
	tween.tween_callback(Callable(_play, "_update_fog_of_war"))
	_play.queue_finish(ac, tween)


func does_support_artificial_opponent() -> bool:
	return true


func get_priority() -> int:
	return 60


func try_invoke() -> bool:
	var terrain_layer: TileMapLayer = _play.get_terrain_layer()
	var move_path: Dictionary[Vector2i, Array] = _generate_move_paths(_play, _ug, _ability.ability_range)
	var foe_map_locs: Array[Vector2i] = []
	var foe_pos_locs: Array[Vector2] = []
	for ug: UnitGraphic in  _play.get_all_units():
		if not ug.is_dead() and ug._unit_stats.unit_side != _ug._unit_stats.unit_side:
			foe_map_locs.append(terrain_layer.local_to_map(ug.position))
			foe_pos_locs.append(ug.position)
	var best_map_loc: Vector2i = Vector2i.MIN
	var best_pos_loc: Vector2 = Vector2.INF
	var best_dist: int = 9999
	var best_path: Array = []
	for path_map_loc: Vector2i in move_path.keys():
		for foe_index: int in range(0, foe_map_locs.size()):
			var foe_map_loc: Vector2i = foe_map_locs[foe_index]
			var dist: int = abs(foe_map_loc.x - path_map_loc.x) + abs(foe_map_loc.y - path_map_loc.y)
			if dist < best_dist:
				best_dist = dist
				best_path = move_path[path_map_loc][1]
				best_map_loc = path_map_loc
				best_pos_loc = foe_pos_locs[foe_index]
	if best_map_loc == Vector2i.MIN:
		return false
	_invoke(best_path, best_pos_loc - _ug.position)
	_play.await_command()
	return true
