class_name Play extends StateMachineState


enum PlayState {
	UNDEFINED,
	SETUP_COMMAND,
	AWAITING_COMMAND_SELECTION,
	AWAITING_COMMAND_CONFIGURATION,
	ANIMATING_COMMAND,
	TRANSITION_TO_DEFEAT,
	TRANSITION_TO_VICTORY
}


var _play_state: PlayState = PlayState.UNDEFINED
var _seen_cells: Dictionary[int,bool] = {}
var _walls: Dictionary[int, bool] = {}
var _max_x: int = 70
var _max_y: int = 40
var _start_spot: Vector2i = Vector2i.MIN
var _end_spot: Vector2i = Vector2i.MIN
var _unit_list: Array[Array] = []
var _fog_of_war_source_id: int = 0
var _import_terrain: TileMapLayer
var _heroes: Array[Unit]
var _victory_state: String
var _target_instance: Control
var _selected_ability: Ability
var _ap_remaining: int
var _await_mouse_release: bool = false
var _camera_tween: Tween
var _mothman_resource = preload("res://data/units/mothman.tres")
var _target_scene: PackedScene = preload("res://scenes/target.tscn")
var target_potential_scene: PackedScene = preload("res://scenes/potential_target.tscn")
var _terrain_children: Array[Node] = []
var _squish_sound: AudioStream = preload("res://sounds/swampfoot.tres")
var _ap_textures: Dictionary[Vector2i, Resource] = {
	Vector2i(1, 0): preload("res://art/temp/AP/AP10.png"),
	Vector2i(2, 0): preload("res://art/temp/AP/AP20.png"),
	Vector2i(2, 1): preload("res://art/temp/AP/AP21.png"),
	Vector2i(3, 0): preload("res://art/temp/AP/AP30.png"),
	Vector2i(3, 1): preload("res://art/temp/AP/AP31.png"),
	Vector2i(3, 2): preload("res://art/temp/AP/AP32.png"),
}


const STANDARD_ZOOM: Vector2 = Vector2.ONE * 1.25
const CROAK_ZOOM: Vector2 = Vector2.ONE * 0.7
const DEATH_TIME: float = 0.25
const TURN_TIME: float = 0.5
const HOP_TIME: float = 0.5
const CHARGE_TIME: float = 0.33
const HOP_SOURCE_ID: int = 0
const HOP_ATLAS_SELECTED: Vector2i = Vector2i(1, 0)
const HOP_ATLAS_POTENTIAL: Vector2i = Vector2i(0, 0)
const WALK_SOURCE_ID: int = 1
const WALK_TIME: float = 0.5
const WALK_ATLAS_POTENTIAL: Vector2i = Vector2i(0, 0)
const WALK_ATLAS_SELECTED: Vector2i = Vector2i(1, 0)
const WALK_ATLAS_UP: Vector2i = Vector2i(2, 0)
const WALK_ATLAS_RIGHT: Vector2i = Vector2i(3, 0)
const WALK_ATLAS_DOWN: Vector2i = Vector2i(4, 0)
const WALK_ATLAS_LEFT: Vector2i = Vector2i(5, 0)


#const _footstep_time: float = 0.66

func exit_state(next_state: StateMachineState) -> void:
	%Camera2D.position = size / 2.0
	%PlayerControlls.hide()
	Music.fade_in()
	for entry: Array in _unit_list:
		entry[0].queue_free()
	_unit_list = []
	for node: Node2D in _terrain_children:
		node.queue_free()
	_terrain_children = []
	super.exit_state(next_state)


func set_level(tml: TileMapLayer) -> void:
	_import_terrain = tml


func set_heroes(heroes: Array[Unit]) -> void:
	_heroes = heroes


func set_victory(victory_state: String) -> void:
	_victory_state = victory_state


func enter_state() -> void:
	super.enter_state()
	%Camera2D.position = size / 2.0
	%PlayerControlls.show()
	%TerrainLayer.clear()
	Music.fade_out()
	
	_seen_cells.clear()
	_walls.clear()
	_start_spot = Vector2i.MIN
	_end_spot = Vector2i.MIN
	_unit_list = []
	_fog_of_war_source_id = 0

	#var noise: FastNoiseLite = FastNoiseLite.new()
	#noise.noise_type = FastNoiseLite.TYPE_SIMPLEX # FastNoiseLite.TYPE_PERLIN
	#noise.frequency = 16.45
	#for x in range(0, _max_x):
		#for y in range(0, _max_y):
			#_walls[x * _max_y + y] = randi() % 2 == 0
	#for i in range(0, 8):
		#var n: Dictionary[int, bool] = {}
		#for x in range(0, _max_x):
			#for y in range(0, _max_y):
				#var c: int = 0
				#for dx in range(-1, 2):
					#var fx: int = x + dx
					#for dy in range(-1, 2):
						#var fy: int = y + dy
						#if dx == 0 and dy == 0:
							#pass
						#elif fx < 0 or fy < 0 or fx >= _max_x or fy >= _max_y:
							#c = c + 1
						#elif _walls[fx * _max_y + fy]:
							#c = c + 1
				#if x == 0 or y == 0 or x == _max_x - 1 or y == _max_y - 1:
					#n[x * _max_y + y] = true
				#elif c > 4:
					#n[x * _max_y + y] = true
				#elif c == 4 and _walls[x * _max_y + y]:
					#n[x * _max_y + y] = true
				#else:
					#n[x * _max_y + y] = false
		#_walls = n
	#var two_points: Array[Vector2i] = _find_two_rooms()
	#while not two_points.is_empty():
		#_connect_two_points(two_points[0], two_points[1])
		#two_points = _find_two_rooms()
	#for x in range(0, _max_x):
		#for y in range(0, _max_y):
			#var source_id: int = 0 if _walls[x * _max_y + y] else 1
			#var loc: Vector2i = Vector2i(x, y)
			##if loc.x == 0 or loc.y == 0 or loc.x == _max_x - 1 or loc.y == _max_y - 1:
			##	source_id = 0
			#if source_id == 1:
				#var atlas: Vector2i = Vector2i(0, 0)
				#%TerrainLayer.set_cell(loc, 0, atlas)
			#else:
				#var atlas: Vector2i = Vector2i(randi() % 3, 0)
				#%TerrainLayer.set_cell(loc, 1, atlas)
	
	################################
	#var import_terrain_ps: PackedScene = load("res://maps/levels/1_defendfrogvillage.tscn")
	#var import_terrain_ps: PackedScene = load("res://maps/levels/3_elitebattle.tscn")
	#var import_terrain: TileMapLayer = import_terrain_ps.instantiate()
	(%TerrainLayer as TileMapLayer).clear()
	(%TerrainLayer as TileMapLayer).tile_set = _import_terrain.tile_set
	(%FogOfWarLayer as TileMapLayer).tile_set.tile_size = _import_terrain.tile_set.tile_size
	if _import_terrain.tile_set.tile_size.x == 16:
		_fog_of_war_source_id = 0
	elif _import_terrain.tile_set.tile_size.x == 32:
		_fog_of_war_source_id = 1
	#(%FogOfWarLayer as TileMapLayer).tile_set.get_source(0).texture_region_size = import_terrain.tile_set.tile_size
	(%AbilityLayer as TileMapLayer).tile_set.tile_size = _import_terrain.tile_set.tile_size
	_walls.clear()
	for cell_loc: Vector2i in _import_terrain.get_used_cells():
		var source_id: int = _import_terrain.get_cell_source_id(cell_loc)
		var atlas_coords: Vector2i = _import_terrain.get_cell_atlas_coords(cell_loc)
		var alternative_tile: int = _import_terrain.get_cell_alternative_tile(cell_loc)
		(%TerrainLayer as TileMapLayer).set_cell(cell_loc, source_id, atlas_coords, alternative_tile)
	var map_rect: Rect2i = (%TerrainLayer as TileMapLayer).get_used_rect()
	for x in range(map_rect.position.x - 5, map_rect.position.x + map_rect.size.x + 7):
		for y in range(map_rect.position.y - 5, map_rect.position.y + map_rect.size.y + 7):
			_walls[x * _max_y + y] = false
	for child: Node in _import_terrain.get_children():
		var map_loc: Vector2i = _import_terrain.local_to_map(child.position)
		var new_child = child.duplicate()
		if new_child is MapObjectGraphic:
			if (new_child as MapObjectGraphic).blocks_fly():
				var map_coord = map_loc.x * _max_y + map_loc.y
				_walls[map_coord] = true
		_place_object(new_child, map_loc)
		_terrain_children.append(new_child)
	################################
	
	_start_spot = Vector2i.ZERO
	_end_spot = Vector2i.ZERO
	var loot_locs: Array[Vector2i]
	for child: Node in %TerrainLayer.get_children():
		if child.has_meta("marker"):
			var marker: String = child.get_meta("marker")
			if marker == "start":
				_start_spot = %TerrainLayer.local_to_map(child.position)
				child.hide()
			elif marker == "end":
				_end_spot = %TerrainLayer.local_to_map(child.position)
				child.hide()
			elif marker == "loot":
				loot_locs.append(%TerrainLayer.local_to_map(child.position))
				child.hide()
			else:
				print("UNKNOWN marker in map: %s" % [marker])
	
	if _start_spot == Vector2i.ZERO:
		var a_spot: Vector2i = _find_a_spot()
		_start_spot = _find_farthest_spot([a_spot])
		var start_marker_scene: PackedScene = load("res://maps/objects/start_marker.tscn")
		var start_marker_instance: Node2D = start_marker_scene.instantiate()
		_place_object(start_marker_instance, _start_spot)
		_terrain_children.append(start_marker_instance)
		start_marker_instance.hide()

	var facing: Vector2i = Vector2i.RIGHT
	for frogman_resource in _heroes:
		_add_unit(frogman_resource, _find_unoccupied_space_near(_start_spot), facing)
		facing = Vector2i(- facing.y, facing.x) # rotate 90 degrees
	_play_state = PlayState.SETUP_COMMAND
	
	if _end_spot == Vector2i.ZERO:
		_end_spot = _find_farthest_spot([_start_spot])
		var end_marker: PackedScene = load("res://maps/objects/end_marker.tscn")
		var end_marker_instance: Node2D = end_marker.instantiate() as Node2D
		_place_object(end_marker_instance, _end_spot)
		_terrain_children.append(end_marker_instance)

	if loot_locs.is_empty():
		var path: Array[Vector2i] = []
		for p: Vector2i in _get_path(_start_spot, _end_spot):
			path.append(p)
		for i in range(0, 4):
			var spawn_spot: Vector2i = _find_farthest_spot(path)
			_add_mothman_near(spawn_spot)
			path.append(spawn_spot)
	else:
		for spawn_spot: Vector2i in loot_locs:
			_add_mothman_near(spawn_spot)
	
	_update_fog_of_war()


func _add_mothman_near(loc: Vector2i) -> void:
	_add_unit(_mothman_resource, _find_unoccupied_space_near(loc), Vector2i.MIN)


func _find_unoccupied_space_near(spot: Vector2i) -> Vector2i:
	var checked_spots: Dictionary[Vector2i, int] = {}
	checked_spots[spot] = 0
	var distance: int = 0
	while true:
		for check: Vector2i in checked_spots.keys():
			if checked_spots[check] != distance:
				continue
			if _any_children_at(check):
				for neighbor_spot: Vector2i in [spot + Vector2i.UP, spot + Vector2i.DOWN, spot + Vector2i.RIGHT, spot + Vector2i.LEFT]:
					if _walls[neighbor_spot.x * _max_y + neighbor_spot.y]:
						continue
					if checked_spots.has(neighbor_spot):
						continue
					checked_spots[neighbor_spot] = distance + 1
			else:
				return check
		distance += 1
	return spot


func _get_child_at(spot: Vector2i) -> Node:
	for child: Node in %TerrainLayer.get_children():
		if %TerrainLayer.local_to_map(child.position) == spot:
			return child
	return null


func _any_children_at(spot: Vector2i) -> bool:
	for child: Node in %TerrainLayer.get_children():
		if %TerrainLayer.local_to_map(child.position) == spot:
			return true
	return false


func _ready() -> void:
	pass


func _add_unit(unit: Unit, spot: Vector2i, facing: Vector2i) -> void:
	var unit_scene: PackedScene = load("res://scenes/units/unit_graphic.tscn")
	var unit_graphic: UnitGraphic = unit_scene.instantiate()
	unit_graphic.set_unit(unit, facing.length() == 1)
	_place_object(unit_graphic, spot)
	unit_graphic.set_facing(facing)
	#unit_graphic.z_index = 100
	_unit_list.append([unit_graphic, facing, randf()])
	_unit_list.sort_custom(func(a, b): return a[2] < b[2])


func _get_current_unit_graphic() -> UnitGraphic:
	return _unit_list[0][0]


func _update_current_unit_facing(dir: Vector2) -> void:
	var max_dot_value: float = -5.0
	for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]:
		var ddot: float = Vector2(d).dot(dir)
		if ddot > max_dot_value:
			max_dot_value = ddot
			_unit_list[0][1] = d
	_get_current_unit_graphic().set_facing(_unit_list[0][1])


func _process(delta: float) -> void:
	#[unit_graphic, facing, initiative]
	var current_entry: Array = _unit_list[0]
	match _play_state:
		PlayState.SETUP_COMMAND:
			_process_setup_command(delta, current_entry[0], current_entry[1])
		PlayState.AWAITING_COMMAND_SELECTION:
			_process_awaiting_command_selection(delta, current_entry[0], current_entry[1])
		PlayState.AWAITING_COMMAND_CONFIGURATION:
			_process_awaiting_command_configuration(delta, current_entry[0], current_entry[1])
		PlayState.ANIMATING_COMMAND:
			_process_animating_command(delta, current_entry[0], current_entry[1])
		PlayState.TRANSITION_TO_DEFEAT:
			pass
		PlayState.TRANSITION_TO_VICTORY:
			pass
		_:
			assert(false, "Bad Play State: %s" % [_play_state])


func _advance_to_next_unit() -> void:
	var f = _unit_list.pop_front()
	_unit_list.append(f)
	var only_alive: Array[Array] = []
	for entry in _unit_list:
		if entry[0].is_dead():
			entry[0].queue_free()
		else:
			only_alive.append(entry)
	_unit_list = only_alive
	_play_state = PlayState.SETUP_COMMAND


func _process_animating_command(_delta: float, ug: UnitGraphic, _facing: Vector2i) -> void:
	%PlayerControlls.hide()
	if _animation_stack.update():
		return
	ug.stop_sound()
	if _ap_remaining <= 0:
		_advance_to_next_unit()
	else:
		%APRemaining.texture = _ap_textures[Vector2i(ug._unit_stats.action_points, ug._unit_stats.action_points - _ap_remaining)]
		_play_state = PlayState.AWAITING_COMMAND_SELECTION


func _clear_ability_bar() -> void:
	for child: Node in %PlayerControlls.get_children():
		if child.has_meta("ability_order"):
			%PlayerControlls.remove_child(child)
			child.queue_free()


func _add_ability_to_bar(ability: Ability, ability_index: int) -> void:
	var max_order: int = -1
	for child: Node in %PlayerControlls.get_children():
		if child.has_meta("ability_order"):
			var ao: int = child.get_meta("ability_order")
			if ao > max_order:
				max_order = ao

	if max_order != -1:
		var control: Control = Control.new()
		control.custom_minimum_size.x = 12
		control.set_meta("ability_order", max_order + 1)
		%PlayerControlls.add_child(control) 
		%PlayerControlls.move_child(control, max_order + 1)
		max_order += 1

	var button: Button = Button.new()
	button.text = ability.ability_name
	button.set_meta("ability_order", max_order + 1)
	button.set_meta("ability_index", ability_index)
	button.button_up.connect(_on_ability_selected.bind(ability))
	%PlayerControlls.add_child(button)
	%PlayerControlls.move_child(button, max_order + 1)


func _on_ability_selected(ability: Ability) -> void:
	%AbilityLayer.clear()
	_selected_ability = ability
	_play_state = PlayState.AWAITING_COMMAND_CONFIGURATION
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_await_mouse_release = true


func _on_pass() -> void:
	%AbilityLayer.clear()
	_selected_ability = null
	_ap_remaining = 0
	_play_state = PlayState.ANIMATING_COMMAND


func _lose() -> void:
	_play_state = PlayState.TRANSITION_TO_DEFEAT
	var end_tween: Tween = create_tween()
	end_tween.tween_interval(2.0)
	end_tween.tween_callback(Callable(Music, "fade_in"))
	end_tween.tween_callback(Callable(our_state_machine, "switch_state").bind("SMS_Defeat"))


func _win() -> void:
	_play_state = PlayState.TRANSITION_TO_VICTORY
	var end_tween: Tween = create_tween()
	end_tween.tween_interval(2.0)
	end_tween.tween_callback(Callable(Music, "fade_in"))
	end_tween.tween_callback(Callable(our_state_machine, "switch_state").bind(_victory_state))


func _apply_death(target: UnitGraphic) -> void:
	target.set_dead()
	if target.is_king():
		_lose()
	else:
		var moth_count: int = 0
		var frog_count: int = 0
		for entry: Array in _unit_list:
			var ug: UnitGraphic = entry[0]
			if ug.is_dead():
				continue
			if ug._unit_stats.unit_side == Unit.UnitSide.FROG:
				frog_count += 1
			elif ug._unit_stats.unit_side == Unit.UnitSide.MOTH:
				moth_count += 1
		if moth_count == 0:
			_win()
		elif frog_count == 0:
			_lose()


#func _frog_kill(target: UnitGraphic) -> void:
	#_apply_death(target)


var _animation_stack: AnimationStack = AnimationStack.new()
func _kill(target: UnitGraphic) -> void:
	%AbilityLayer.clear()
	_animation_stack.add_command(Callable(_kill_animation_command).bind(_get_current_unit_graphic(), target, _selected_ability))


func _kill_animation_command(ac: AnimationCommand, _killer: UnitGraphic, target: UnitGraphic, ability: Ability) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(%Camera2D, "position", target.position, 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	var delay: float = DEATH_TIME
	if ability != null:
		if ability.activation_sound != null:
			tween.tween_callback(Callable(target, "play_sound").bind(ability.activation_sound))
			delay += ability.activation_sound.get_length()
	tween.tween_interval(delay)
	tween.tween_callback(_apply_death.bind(target))
	ac.queue_finish(tween, _animation_stack)
	_selected_ability = null
	if target == _get_current_unit_graphic():
		_ap_remaining = 0
	_play_state = PlayState.ANIMATING_COMMAND


func _die() -> void:
	_kill(_get_current_unit_graphic())


func _on_center() -> void:
	var current_global_pos: Vector2 = %Camera2D.global_position
	var local_pos: Vector2 = _get_current_unit_graphic().position
	var dest_global_pos: Vector2 = %TerrainLayer.to_global(local_pos)
	if _camera_tween != null && _camera_tween.is_running():
		_camera_tween.stop()
	_camera_tween = create_tween()
	var delta_global_pos: Vector2 = dest_global_pos - current_global_pos
	var first_global_pos: Vector2 = current_global_pos + delta_global_pos / 3.0
	var second_global_pos: Vector2 = current_global_pos + 2.0 * delta_global_pos / 3.0
	var third_global_pos: Vector2 = dest_global_pos
	
	_camera_tween.tween_property(%Camera2D, "zoom", CROAK_ZOOM, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_camera_tween.parallel()
	_camera_tween.tween_property(%Camera2D, "global_position", first_global_pos, 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	_camera_tween.tween_property(%Camera2D, "global_position", second_global_pos, 0.20)
	
	_camera_tween.tween_property(%Camera2D, "zoom", STANDARD_ZOOM, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_camera_tween.parallel()
	_camera_tween.tween_property(%Camera2D, "global_position", third_global_pos, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _process_setup_command(_delta: float, ug: UnitGraphic, _facing: Vector2i) -> void:
	_selected_ability = null
	_ap_remaining = ug._unit_stats.action_points
	%UnitImage.texture = ug._unit_stats.texture
	%UnitName.text = ug._unit_stats.unit_name
	%APRemaining.texture = _ap_textures[Vector2i(_ap_remaining, 0)]
	var stun_in_light: Ability = ug.get_ability(Ability.AbilityMechanism.STUN_IN_LIGHT)
	var die_in_light: Ability = ug.get_ability(Ability.AbilityMechanism.DIE_IN_LIGHT)
	if stun_in_light != null or die_in_light != null:
		if _is_map_loc_in_light(%TerrainLayer.local_to_map(ug.position)):
			if die_in_light != null:
				_selected_ability = die_in_light
				_die()
				return
			elif stun_in_light != null:
				_selected_ability = stun_in_light
				ug.play_sound(stun_in_light.activation_sound)
				_on_pass()
				return
			else:
				print("huh?")
	
	var abilities: Array[Ability] = []
	for ability: Ability in ug.get_abilities():
		if not ability.always_on:
			abilities. append(ability)
	if ug._unit_stats.unit_side == Unit.UnitSide.FROG:
		_on_center()
		%PlayerControlls.show()
		_clear_ability_bar()
		for ability_index: int in range(0, abilities.size()):
			_add_ability_to_bar(abilities[ability_index], ability_index)
		_play_state = PlayState.AWAITING_COMMAND_SELECTION
	else:
		_pick_moth_ability(abilities)


func _pick_moth_ability(abilities: Array[Ability]) -> void:
	Ability.sort_abilities_by_moth_priority(abilities)
	for ability: Ability in abilities:
		if _try_do_moth_ability(ability):
			return
	_on_pass()


func _get_all_units_of_a_side(filter_side: Unit.UnitSide) -> Array[UnitGraphic]:
	var ret_val: Array[UnitGraphic] = []
	for entry: Array in _unit_list:
		var ug: UnitGraphic = entry[0]
		if ug._unit_stats.unit_side == filter_side:
			ret_val.append(ug)
	return ret_val


enum PathLogic { UNDEFINED, DIRECT_FIRE, DIRECT_RUN, DIRECT_FLY }
func _try_get_path(start: Vector2i, end: Vector2i, path_range: int, path_logic: PathLogic, ignore_nodes: Array[Node], avoid_light: bool) -> Array[Vector2i]:
	match path_logic:
		PathLogic.DIRECT_FIRE:
			return _try_get_path_direct_fire(start, end, path_range, ignore_nodes, avoid_light)
		PathLogic.DIRECT_RUN:
			return _try_get_path_direct_travel(start, end, path_range, ignore_nodes, avoid_light, false)
		PathLogic.DIRECT_FLY:
			return _try_get_path_direct_travel(start, end, path_range, ignore_nodes, avoid_light, true)
	print("Unknown PathLogic in _try_get_path(%s)" % [PathLogic.keys()[path_logic]])
	return []


func _is_map_loc_in_light(map_loc: Vector2i) -> bool:
	return %FogOfWarLayer.get_cell_atlas_coords(map_loc).x < 3
func _is_map_loc_completely_dark(map_loc: Vector2i) -> bool:
	return %FogOfWarLayer.get_cell_atlas_coords(map_loc).x == 4


func _try_get_path_direct_travel(start: Vector2i, end: Vector2i, search_range: int, ignore_nodes: Array[Node], avoid_light: bool, fly: bool) -> Array[Vector2i]:
	var visited: Dictionary[Vector2i, Array] = {}
	visited[start] = []
	for dist: int in range(0, search_range):
		for map_loc: Vector2i in visited.keys():
			if visited[map_loc].size() != dist:
				continue
			for dir: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var next_loc: Vector2i = dir + map_loc
				if next_loc == end:
					var ret_val: Array[Vector2i] = []
					for step: Vector2i in visited[map_loc]:
						ret_val.append(step)
					ret_val.append(next_loc)
					return ret_val
				if visited.has(next_loc):
					continue
				if (%TerrainLayer as TileMapLayer).get_cell_source_id(next_loc) < 0:
					continue
				var next_coord: int = next_loc.x * _max_y + next_loc.y
				if not _walls.has(next_coord) or _walls[next_coord]:
					continue
				if avoid_light:
					if _is_map_loc_in_light(next_loc):
						continue
				var o: Node = _get_child_at(next_loc)
				if o != null:
					if not ignore_nodes.has(o):
						if (o is MapObjectGraphic):
							if fly and (o as MapObjectGraphic).blocks_fly():
								continue
							elif not fly and (o as MapObjectGraphic).blocks_walk():
								continue
						elif (o is UnitGraphic):
							continue
				var next_path: Array[Vector2i] = []
				for step: Vector2i in visited[map_loc]:
					next_path.append(step)
				next_path.append(next_loc)
				visited[next_loc] = next_path
	return []


func _try_get_path_direct_fire(start: Vector2i, end: Vector2i, path_range: int, ignore_nodes: Array[Node], avoid_light: bool) -> Array[Vector2i]:
	var ret_val: Array[Vector2i] = []
	for map_loc: Vector2i in _calculate_bresenham_path(start, end):
		if map_loc == start:
			continue
		if map_loc == end:
			if ret_val.size() <= path_range:
				ret_val.append(end)
				return ret_val
			else:
				return []
		var map_coord: int = map_loc.x * _max_y + map_loc.y
		if _walls[map_coord]:
			return []
		if avoid_light:
			if _is_map_loc_in_light(map_loc):
				return []
		var o: Node = _get_child_at(map_loc)
		if o != null:
			if not ignore_nodes.has(o):
				if (o is MapObjectGraphic):
					if (o as MapObjectGraphic).blocks_fly():
						return []
				elif (o is UnitGraphic):
					return []
		if ret_val.size() <= path_range:
			ret_val.append(map_loc)
		else:
			return []
	if ret_val.size() <= path_range:
		return ret_val
	else:
		return []


func _calculate_bresenham_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var ret_val: Array[Vector2i] = []
	var dx: int = abs(end.x - start.x)
	var dy: int = abs(end.y - start.y)
	var sx: int = 1 if start.x < end.x else -1
	var sy: int = 1 if start.y < end.y else -1
	var e1: int = dx - dy
	while start != end:
		var e2: int = 2 * e1
		var changed: bool = false
		if e2 > -dy:
			e1 -= dy
			start += Vector2i(sx, 0)
			changed = true
		if e2 < dx:
			e1 += dx
			start += Vector2i(0, sy)
			changed = true
		if changed:
			ret_val.append(start)
	return ret_val


func _try_do_moth_ability(ability: Ability) -> bool:
	_selected_ability = ability
	var moth: UnitGraphic = _get_current_unit_graphic()
	var moth_map_loc: Vector2i = %TerrainLayer.local_to_map(moth.position)
	var all_frogs: Array[UnitGraphic] = _get_all_units_of_a_side(Unit.UnitSide.FROG)
	match ability.mechanism:
		Ability.AbilityMechanism.DAMAGE:
			for frog: UnitGraphic in all_frogs:
				var frog_map_loc: Vector2i = %TerrainLayer.local_to_map(frog.position)
				if not _try_get_path(moth_map_loc, frog_map_loc, ability.ability_range, PathLogic.DIRECT_FIRE, [frog], false).is_empty():
					_play_state = PlayState.ANIMATING_COMMAND
					moth.start_attack_animation()
					_ap_remaining -= _selected_ability.ap_cost
					_kill(frog)
					return true
			return false
		Ability.AbilityMechanism.CHARGE:
			return _try_do_moth_charge(ability, moth_map_loc, all_frogs, false)
		Ability.AbilityMechanism.CHARGE_WITH_FLY:
			return _try_do_moth_charge(ability, moth_map_loc, all_frogs, true)
		Ability.AbilityMechanism.FLY:
			return _try_do_moth_move(ability, moth_map_loc, all_frogs, true)
		Ability.AbilityMechanism.WALK:
			return _try_do_moth_move(ability, moth_map_loc, all_frogs, false)
		#Ability.AbilityMechanism.PULL:
		#Ability.AbilityMechanism.HOP:
		#Ability.AbilityMechanism.RIBBIT_RADAR:
		#Ability.AbilityMechanism.ILLUMINATE:
		#Ability.AbilityMechanism.STUN_IN_LIGHT:
		#Ability.AbilityMechanism.DIE_IN_LIGHT:
	print("Artificial opponent doesn't know how to perform %s mechanisms for moths" % [Ability.AbilityMechanism.keys()[ability.mechanism]])
	return false


func _try_do_moth_move(ability: Ability, moth_map_loc: Vector2i, all_frogs: Array[UnitGraphic], fly: bool) -> bool:
	# First try an all dark path to frogs
	var best_path: Array[Vector2i] = []
	for frog: UnitGraphic in all_frogs:
		var frog_map_loc: Vector2i = %TerrainLayer.local_to_map(frog.position)
		var max_path_len: int = 100 if best_path.is_empty() else best_path.size()
		var path: Array[Vector2i] = _try_get_path_direct_travel(moth_map_loc, frog_map_loc, max_path_len, [], true, fly)
		if not path.is_empty():
			if best_path.is_empty() or path.size() < best_path.size():
				best_path = path
	if not best_path.is_empty():
		_move_moth_along_path_stopping_at_light(ability.ability_range, best_path)
		return true
	for frog: UnitGraphic in all_frogs:
		var frog_map_loc: Vector2i = %TerrainLayer.local_to_map(frog.position)
		var max_path_len: int = 100 if best_path.is_empty() else best_path.size()
		var path: Array[Vector2i] = _try_get_path_direct_travel(moth_map_loc, frog_map_loc, max_path_len, [], false, fly)
		if not path.is_empty():
			if best_path.is_empty() or path.size() < best_path.size():
				best_path = path
	if not best_path.is_empty():
		_move_moth_along_path_stopping_at_light(ability.ability_range, best_path)
		return true
	return false


func _move_moth_along_path_stopping_at_light(ability_range: int, path: Array[Vector2i]) -> void:
	_play_state = PlayState.ANIMATING_COMMAND
	_ap_remaining -= _selected_ability.ap_cost
	var dark_path: Array[Vector2i] = []
	for map_loc: Vector2i in path:
		if _is_map_loc_in_light(map_loc):
			break
		dark_path.append(map_loc)
		ability_range -= 1
		if ability_range <= 0:
			break
	_animation_stack.add_command(Callable(_moth_move_animation_command).bind(_selected_ability.activation_sound, dark_path))


func _try_do_moth_charge(ability: Ability, moth_map_loc: Vector2i, all_frogs: Array[UnitGraphic], fly: bool) -> bool:
	for frog: UnitGraphic in all_frogs:
		var frog_map_loc: Vector2i = %TerrainLayer.local_to_map(frog.position)
		var path_logic: PathLogic = PathLogic.DIRECT_FLY if fly else PathLogic.DIRECT_RUN
		var path: Array[Vector2i] = _try_get_path(moth_map_loc, frog_map_loc, ability.ability_range, path_logic, [frog], true)
		if not path.is_empty():
			_update_fog_of_war(path)
			_play_state = PlayState.ANIMATING_COMMAND
			_ap_remaining -= _selected_ability.ap_cost
			_animation_stack.add_command(Callable(_moth_move_animation_command).bind(null, path))
			_kill(frog)
			return true
	return false


func _process_awaiting_command_configuration(_delta: float, ug: UnitGraphic, facing: Vector2i) -> void:
	%PlayerControlls.show()
	var mouse_pressed: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if _await_mouse_release:
		if not mouse_pressed:
			_await_mouse_release = false
		else:
			mouse_pressed = false
	if mouse_pressed:
		var hover_control: Control = get_viewport().gui_get_hovered_control()
		if hover_control != self and hover_control != _target_instance and hover_control != %Background:
			# Don't intercept mouse presses over valid buttons
			mouse_pressed = false
	if _selected_ability == null:
		print("Why is selected ability null?")
		return
	var mouse_local_pos: Vector2 = %TerrainLayer.get_local_mouse_position()
	match _selected_ability.mechanism:
		Ability.AbilityMechanism.HOP:
			_process_awaiting_hop_command(ug, facing, mouse_pressed, mouse_local_pos)
		Ability.AbilityMechanism.WALK:
			_process_awaiting_walk_command(ug, facing, mouse_pressed, mouse_local_pos)
		Ability.AbilityMechanism.RIBBIT_RADAR:
			_process_awaiting_ribbit_command(ug)
		Ability.AbilityMechanism.CHARGE:
			_process_awaiting_charge_command(ug, facing, mouse_pressed, mouse_local_pos)
	_update_fog_of_war()
	

func _process_awaiting_charge_command(ug: UnitGraphic, facing: Vector2i, mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
	%AbilityLayer.clear()
	if _target_instance == null:
		_target_instance = _target_scene.instantiate()
		%AbilityLayer.add_child(_target_instance)
	var closest_target_dist_to_mouse: float = INF
	var closest_foe_to_mouse: UnitGraphic
	var path_to_foe: Array[Vector2i]
	var ug_map_loc: Vector2i = %AbilityLayer.local_to_map(ug.position)
	for foe_entry: Array in _unit_list:
		var foe_ug: UnitGraphic = foe_entry[0]
		if foe_ug.is_dead() or foe_ug._unit_stats.unit_side == ug._unit_stats.unit_side:
			continue
		var foe_map_loc: Vector2i = %AbilityLayer.local_to_map(foe_ug.position)
		if abs(foe_map_loc.x - ug_map_loc.x) + abs(foe_map_loc.y - ug_map_loc.y) > _selected_ability.ability_range:
			continue
		var path: Array[Vector2i] = _try_get_path(ug_map_loc, foe_map_loc, _selected_ability.ability_range, PathLogic.DIRECT_RUN, [foe_ug], false)
		if path.is_empty():
			continue
		var vector_to_mouse: Vector2 = mouse_local_pos - foe_ug.position
		var dist_squared_from_mouse: float = vector_to_mouse.length_squared()
		if dist_squared_from_mouse < closest_target_dist_to_mouse:
			closest_foe_to_mouse = foe_ug
			closest_target_dist_to_mouse = dist_squared_from_mouse
			path_to_foe = path
	_target_instance.show()
	if closest_foe_to_mouse == null:
		_target_instance.position = %AbilityLayer.map_to_local(ug_map_loc + facing * _selected_ability.ability_range)
		_target_instance.show_label()
		if not mouse_pressed:
			return
		for x in range(ug_map_loc.x - _selected_ability.ability_range, ug_map_loc.x + _selected_ability.ability_range + 1):
			for y in range(ug_map_loc.y - _selected_ability.ability_range, ug_map_loc.y + _selected_ability.ability_range + 1):
				if abs(x - ug_map_loc.x) + abs(y - ug_map_loc.y) > _selected_ability.ability_range:
					continue
				var ping_coord: int = x * _max_y + y
				if not _walls.has(ping_coord) or _walls[ping_coord]:
					continue
				var ping_map_loc: Vector2i = Vector2i(x, y)
				if (%TerrainLayer as TileMapLayer).get_cell_source_id(ping_map_loc) < 0:
					continue
				var o: Node = _get_child_at(ping_map_loc)
				if o != null:
					if (o is MapObjectGraphic):
						if (o as MapObjectGraphic).blocks_walk():
							continue
					elif (o is UnitGraphic):
						continue
				var path: Array[Vector2i] = _try_get_path(ug_map_loc, ping_map_loc, _selected_ability.ability_range, PathLogic.DIRECT_RUN, [], false)
				if path.is_empty():
					continue
				var potential_target: Sprite2D = target_potential_scene.instantiate()
				potential_target.position = %AbilityLayer.map_to_local(ping_map_loc)
				%AbilityLayer.add_child(potential_target)
		return
	_target_instance.position = closest_foe_to_mouse.position
	_target_instance.hide_label()
	if path_to_foe[0] != ug_map_loc:
		path_to_foe.insert(0, ug_map_loc)
	if path_to_foe.size() > 1:
		var final_facing: Vector2i = path_to_foe[path_to_foe.size() - 1] - path_to_foe[path_to_foe.size() - 2]
		_target_instance.set_facing(final_facing)
	if not mouse_pressed:
		return
	_animation_stack.add_command(Callable(_move_camera_animation_command).bind(closest_foe_to_mouse.position, 0.1))
	_animation_stack.add_command(Callable(_frog_charge_animation_command).bind(closest_foe_to_mouse, path_to_foe))
	_kill(closest_foe_to_mouse)
	#_ap_remaining -= _selected_ability.ap_cost
	_ap_remaining = 0
	_play_state = PlayState.ANIMATING_COMMAND


func _move_camera_animation_command(ac: AnimationCommand, pos: Vector2, duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(%Camera2D, "position", pos, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	ac.queue_finish(tween, _animation_stack)


func _moth_move_animation_command(ac: AnimationCommand, sound: AudioStream, path: Array[Vector2i]) -> void:
	var moth_ug: UnitGraphic = _get_current_unit_graphic()
	var tween: Tween = create_tween()
	var duration: float = 0 # CHARGE_TIME
	
	for map_loc: Vector2i in path:
		if not _is_map_loc_completely_dark(map_loc):
			duration += CHARGE_TIME
	if sound != null:
		duration = max(sound.get_length(), duration)
		tween.tween_callback(Callable(moth_ug, "play_sound").bind(sound))
	for i in range(1, path.size()):
		var leaving_spot: Vector2i = path[i - 1]
		var arriving_spot: Vector2i = path[i]
		var arriving_pos: Vector2 = %TerrainLayer.map_to_local(arriving_spot)
		var d: float = 0.0
		if not _is_map_loc_completely_dark(arriving_spot) or not _is_map_loc_completely_dark(leaving_spot):
			d = duration / (path.size() - 1.0)
		tween.tween_property(moth_ug, "position", arriving_pos, d)
	var final_pos: Vector2 = %TerrainLayer.map_to_local(path.back())
	tween.tween_property(moth_ug, "position", final_pos, 0.0)
	tween.tween_callback(Callable(moth_ug, "start_idle_animation"))
	tween.tween_callback(Callable(self, "_update_fog_of_war"))
	ac.queue_finish(tween, _animation_stack)


func _frog_hop_animation_command(ac: AnimationCommand, destination: Vector2) -> void:
	var frog_ug: UnitGraphic = _get_current_unit_graphic()
	var tween: Tween = create_tween()
	tween.tween_callback(Callable(%AbilityLayer, "clear"))
	tween.tween_property(frog_ug, "position", destination, HOP_TIME)
	tween.parallel()
	tween.tween_method(Callable(frog_ug, "set_hop_animation_frame"), 0.0, 1.0, HOP_TIME)
	tween.tween_callback(Callable(frog_ug, "start_idle_animation"))
	tween.tween_callback(_update_fog_of_war)
	_move_camera_animation_command(ac, destination, 0.1) # will clean up AnimationCommand for us


func _frog_charge_animation_command(ac: AnimationCommand, target: UnitGraphic, path_frog_to_moth: Array[Vector2i]) -> void:
	var frog_ug: UnitGraphic = _get_current_unit_graphic()
	var tween: Tween = create_tween()
	for i in range(1, path_frog_to_moth.size()):
		var leaving_spot: Vector2i = path_frog_to_moth[i - 1]
		var arriving_spot: Vector2i = path_frog_to_moth[i]
		var arriving_pos: Vector2 = %TerrainLayer.map_to_local(arriving_spot)
		var facing = arriving_spot - leaving_spot
		tween.tween_callback(Callable(self, "_update_current_unit_facing").bind(facing))
		tween.tween_callback(Callable(self, "_update_fog_of_war"))
		tween.tween_property(frog_ug, "position", arriving_pos, CHARGE_TIME / (path_frog_to_moth.size() - 1.0))
	tween.tween_property(frog_ug, "position", target.position, 0.0)
	tween.tween_callback(Callable(frog_ug, "start_idle_animation"))
	tween.tween_callback(Callable(self, "_update_fog_of_war"))
	ac.queue_finish(tween, _animation_stack)


enum TerrainType { UNKNOWN, DIRT, SWAMP }
func _get_terrain_type(map_loc: Vector2i) -> TerrainType:
	var tile_data: TileData = %TerrainLayer.get_cell_tile_data(map_loc)
	if tile_data == null:
		return TerrainType.UNKNOWN
	if tile_data.terrain_set != 0:
		return TerrainType.UNKNOWN
	if tile_data.terrain == 1:
		return TerrainType.DIRT
	if tile_data.terrain == 0:
		return TerrainType.SWAMP
	return TerrainType.UNKNOWN


func _frog_walk_animation_command(ac: AnimationCommand, path: Array, final_facing: Vector2i) -> void:
	var frog_ug: UnitGraphic = _get_current_unit_graphic()
	frog_ug.start_hop_animation(true)
	var playing_path_sound: bool = false
	var tween: Tween = create_tween()
	for i in range(1, path.size()):
		var leaving_spot: Vector2i = path[i - 1]
		match _get_terrain_type(leaving_spot):
			TerrainType.DIRT:
				if not playing_path_sound:
					playing_path_sound = true
					tween.tween_callback(Callable(frog_ug, "play_sound").bind(_selected_ability.activation_sound))
			TerrainType.SWAMP:
				playing_path_sound = false
				tween.tween_callback(Callable(frog_ug, "play_sound").bind(_squish_sound))
			_:
				print("Frog at %s on unknown terrain: %s" % [leaving_spot, TerrainType.keys()[_get_terrain_type(leaving_spot)]])
		var arriving_spot: Vector2i = path[i]
		var arriving_pos: Vector2 = %TerrainLayer.map_to_local(arriving_spot)
		var facing = arriving_spot - leaving_spot
		tween.tween_callback(Callable(self, "_update_current_unit_facing").bind(facing))
		tween.tween_callback(Callable(self, "_update_fog_of_war"))
		tween.tween_property(frog_ug, "position", arriving_pos, WALK_TIME) # / (path.size() - 1.0))
	tween.tween_callback(Callable(%AbilityLayer, "clear"))
	var final_pos: Vector2 = %TerrainLayer.map_to_local(path.back())
	tween.tween_property(frog_ug, "position", final_pos, 0.0)
	tween.tween_callback(Callable(frog_ug, "start_idle_animation"))
	tween.tween_callback(Callable(self, "_update_current_unit_facing").bind(final_facing))
	tween.tween_callback(Callable(self, "_update_fog_of_war"))
	ac.queue_finish(tween, _animation_stack)


var ping_scene: PackedScene = preload("res://scenes/ping.tscn")
func _process_awaiting_ribbit_command(ug: UnitGraphic) -> void:
	%AbilityLayer.clear()
	_ap_remaining -= _selected_ability.ap_cost
	_animation_stack.add_command(Callable(_ribbit_animation_command).bind(ug))
	_play_state = PlayState.ANIMATING_COMMAND


const SONAR_SPEED: float = 320.0
func _ribbit_animation_command(ac: AnimationCommand, source: UnitGraphic) -> void:
	source.play_sound(_selected_ability.activation_sound)
	var max_delay: float = 0
	for entity: Array in _unit_list:
		var entity_ug: UnitGraphic = entity[0]
		if entity_ug.is_dead():
			continue
		if entity_ug._unit_stats.unit_side != Unit.UnitSide.MOTH:
			continue
		var dist: float = (source.position - entity_ug.position).length()
		var delay: float = dist / SONAR_SPEED
		var radar_tween: Tween = create_tween()
		radar_tween.tween_interval(delay)
		radar_tween.tween_callback(_create_ping.bind(entity_ug.position))
		if delay > max_delay:
			max_delay = delay
	var zoom_tween: Tween = create_tween()
	zoom_tween.tween_property(%Camera2D, "zoom", CROAK_ZOOM, 1.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	if max_delay > 1.8 + 0.8:
		zoom_tween.tween_interval(max_delay - (1.8 + 0.8))
	zoom_tween.tween_property(%Camera2D, "zoom", STANDARD_ZOOM, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	ac.queue_finish(zoom_tween, _animation_stack)


func _create_ping(pos: Vector2) -> void:
	var ping: Control = ping_scene.instantiate()
	ping.position = pos
	%AbilityLayer.add_child(ping)


func _process_awaiting_walk_command(ug: UnitGraphic, _facing: Vector2i, mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
	var ug_map_loc: Vector2i = %TerrainLayer.local_to_map(ug.position)
	var walk_path: Dictionary[Vector2i, Array] = {}
	var closest_squared_dist_to_mouse: float = INF
	var closest_map_loc_to_mouse: Vector2i = Vector2i.MIN
	var closest_map_loc_delta_to_mouse: Vector2
	walk_path[ug_map_loc] = [0, []]
	for distance: int in range(0, _selected_ability.ability_range):
		for map_loc: Vector2i in walk_path.keys():
			var map_loc_dist: int = walk_path[map_loc][0]
			if map_loc_dist == distance:
				var map_loc_path: Array = walk_path[map_loc][1]
				for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]:
					var step_dest: Vector2i = d + map_loc
					if %TerrainLayer.get_cell_source_id(step_dest) == -1:
						continue
					var step_coord: int = step_dest.x * _max_y + step_dest.y
					if _walls[step_coord]:
						continue
					var child_at: Node = _get_child_at(step_dest)
					if child_at != null:
						if child_at is MapObjectGraphic:
							if (child_at as MapObjectGraphic).blocks_walk():
								continue
						elif child_at is UnitGraphic:
							if child_at != ug and not child_at.is_dead():
								continue
					var step_cost: int = map_loc_dist + 1
					if _get_terrain_type(step_dest) == TerrainType.SWAMP:
						step_cost += 1
					if walk_path.has(step_dest):
						if walk_path[step_dest][0] <= step_cost:
							continue
					var new_path: Array = map_loc_path.duplicate()
					new_path.append(map_loc)
					walk_path[step_dest] = [step_cost, new_path]
					var vector_to_mouse: Vector2 = mouse_local_pos - %TerrainLayer.map_to_local(step_dest) 
					var dist_squared_from_mouse: float = vector_to_mouse.length_squared()
					if dist_squared_from_mouse < closest_squared_dist_to_mouse:
						closest_map_loc_to_mouse = step_dest
						closest_map_loc_delta_to_mouse = vector_to_mouse
						closest_squared_dist_to_mouse = dist_squared_from_mouse
	%AbilityLayer.clear()
	for loc: Vector2i in walk_path.keys():
		%AbilityLayer.set_cell(loc, WALK_SOURCE_ID, WALK_ATLAS_POTENTIAL)
	if closest_map_loc_to_mouse != Vector2i.MIN:
		var mouse_path: Array = walk_path[closest_map_loc_to_mouse][1]
		for loc: Vector2i in mouse_path:
			%AbilityLayer.set_cell(loc, WALK_SOURCE_ID, WALK_ATLAS_SELECTED)
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
			%AbilityLayer.set_cell(closest_map_loc_to_mouse, WALK_SOURCE_ID, best_atlas)
		if mouse_pressed:
			_ap_remaining -= _selected_ability.ap_cost
			var full_path: Array = mouse_path.duplicate()
			if full_path.is_empty():
				full_path.append(closest_map_loc_to_mouse)
			elif full_path[full_path.size() - 1] != closest_map_loc_to_mouse:
				full_path.append(closest_map_loc_to_mouse)
			_animation_stack.add_command(Callable(_frog_walk_animation_command).bind(full_path, final_facing))
			var final_position: Vector2 = %TerrainLayer.map_to_local(closest_map_loc_to_mouse)
			_animation_stack.add_command(Callable(_move_camera_animation_command).bind(final_position, 0.4))
			_play_state = PlayState.ANIMATING_COMMAND


func _process_awaiting_hop_command(ug: UnitGraphic, facing: Vector2i, mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
	var ug_map_loc: Vector2i = %TerrainLayer.local_to_map(ug.position)
	var command_potentials: Array[Vector2i]
	var closest_squared_dist_to_mouse: float = INF
	var closest_map_loc_to_mouse: Vector2i = Vector2i.MIN
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]:
		for i in range(1, _selected_ability.ability_range):
			var hop_dest: Vector2i = d * i + ug_map_loc
			if %TerrainLayer.get_cell_source_id(hop_dest) == -1:
				break
			var hop_coord: int = hop_dest.x * _max_y + hop_dest.y
			if _walls[hop_coord]:
				break
			var child_at: Node = _get_child_at(hop_dest)
			if child_at != null:
				if child_at is MapObjectGraphic:
					if (child_at as MapObjectGraphic).blocks_hop():
						break
			else:
				var vector_from_mouse: Vector2 = %TerrainLayer.map_to_local(hop_dest) - mouse_local_pos
				var dist_squared_from_mouse: float = vector_from_mouse.length_squared()
				if dist_squared_from_mouse < closest_squared_dist_to_mouse:
					closest_map_loc_to_mouse = hop_dest
					closest_squared_dist_to_mouse = dist_squared_from_mouse
				command_potentials.append(hop_dest)
	%AbilityLayer.clear()
	if closest_map_loc_to_mouse != Vector2i.MIN:
		%AbilityLayer.set_cell(closest_map_loc_to_mouse, HOP_SOURCE_ID, HOP_ATLAS_SELECTED)
		for v: Vector2i in command_potentials:
			if v != closest_map_loc_to_mouse:
				%AbilityLayer.set_cell(v, HOP_SOURCE_ID, HOP_ATLAS_POTENTIAL)
		if mouse_pressed:
			ug.start_hop_animation(false)
			_ap_remaining -= _selected_ability.ap_cost
			ug.play_sound(_selected_ability.activation_sound)
			var delta: Vector2i = (closest_map_loc_to_mouse - ug_map_loc)
			delta = delta / delta.length()
			if delta != facing:
				if delta + facing == Vector2i.ZERO:
					var mid: Vector2i = Vector2i(1, 0) if delta.x == 0 else Vector2i(0, 1)
					if randi() % 2 == 0:
						mid = mid * Vector2i(-1, -1)
					_animation_stack.add_command(Callable(_turn_frog_animation_command).bind(mid))
					_animation_stack.add_command(Callable(_turn_frog_animation_command).bind(delta))
				else:
					_animation_stack.add_command(Callable(_turn_frog_animation_command).bind(delta))
			_animation_stack.add_command(Callable(_frog_hop_animation_command).bind(%AbilityLayer.map_to_local(closest_map_loc_to_mouse)))
			_play_state = PlayState.ANIMATING_COMMAND


func _turn_frog_animation_command(ac: AnimationCommand, dir: Vector2) -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(TURN_TIME)
	tween.tween_callback(Callable(_update_current_unit_facing).bind(dir))
	tween.tween_callback(Callable(_update_fog_of_war))
	ac.queue_finish(tween, _animation_stack)


func _process_awaiting_command_selection(_delta: float, _ug: UnitGraphic, _facing: Vector2i) -> void:
	%AbilityLayer.clear()
	%PlayerControlls.show()
	_update_fog_of_war()


func _update_fog_of_war(extra_fullbright: Array[Vector2i] = []) -> void:
	%FogOfWarLayer.clear()
	var light_cones: Dictionary[int, float] = {}
	for entry: Array in _unit_list:
		var unit_graphic: UnitGraphic = entry[0] as UnitGraphic
		var illumination: Ability = unit_graphic.get_ability(Ability.AbilityMechanism.ILLUMINATE)
		if illumination != null:
			var unit_map_loc: Vector2i = %TerrainLayer.local_to_map(entry[0].position)
			var unit_light_range: int = illumination.ability_range
			var unit_facing: Vector2i = entry[1]
			_generate_light_cones(unit_map_loc, unit_light_range, unit_facing, light_cones)
		for fullbright:Vector2i in extra_fullbright:
			light_cones[fullbright.x * _max_y + fullbright.y] = 0.0
	for x in range(-1, _max_x + 1):
		for y in range(-1, _max_y + 1):
			var coord: int = x * _max_y + y
			var map_loc: Vector2i = Vector2i(x, y)
			if light_cones.has(coord):
				_seen_cells[coord] = true
				var dist: float = light_cones[coord]
				if dist <= 0.25:
					pass
				elif dist <= 0.5:
					%FogOfWarLayer.set_cell(map_loc, _fog_of_war_source_id, Vector2i(0,0)) # one sixth
				elif dist <= 0.75:
					%FogOfWarLayer.set_cell(map_loc, _fog_of_war_source_id, Vector2i(1,0)) # one third
				else:
					%FogOfWarLayer.set_cell(map_loc, _fog_of_war_source_id, Vector2i(2,0)) # one half
			elif _seen_cells.has(coord):
				%FogOfWarLayer.set_cell(map_loc, _fog_of_war_source_id, Vector2i(3,0)) # five sixths
			else:
				%FogOfWarLayer.set_cell(map_loc, _fog_of_war_source_id, Vector2i(4,0)) # full


func _is_in_cell_in_forward_arc(origin: Vector2i, facing: Vector2i, dest: Vector2i) -> bool:
	var vector_from_party_to_map_loc: Vector2i = dest - origin
	var dot: float = Vector2(vector_from_party_to_map_loc).dot(facing)
	if dot <= 0:
		return false
	var lengths_sq: float = vector_from_party_to_map_loc.length_squared() * facing.length_squared()
	#const cos_45_degree_sq: float = 0.5
	#return (dot * dot) >= (cos_45_degree_sq * lengths_sq)
	const cos_35_degree_sq: float = 0.67
	return (dot * dot) >= (cos_35_degree_sq * lengths_sq)


func _generate_light_cones(map_loc: Vector2i, light_range: int, facing: Vector2i, light_map: Dictionary[int, float]) -> void:
	var tmp_map: Dictionary[int, int] = {}
	light_map[map_loc.x * _max_y + map_loc.y] = 0
	tmp_map[map_loc.x * _max_y + map_loc.y] = 0
	
	for current_dist in range(0, light_range):
		var next_light_float_strength: float = (1.0 + float(current_dist)) / float(light_range)
		for coord: int in tmp_map.keys():
			if tmp_map[coord] != current_dist:
				continue
			if _walls[coord]:
				continue
			var x: int = int(coord / float(_max_y))
			var y: int = coord % _max_y
			for fx in range(x-1, x+2):
				for fy in range(y-1, y+2):
					var f_coord: int = fx * _max_y + fy
					if not _is_in_cell_in_forward_arc(map_loc, facing, Vector2i(fx, fy)):
						continue
					if tmp_map.has(f_coord):
						continue
					tmp_map[fx * _max_y + fy] = current_dist + 1
					if not light_map.has(f_coord):
						light_map[fx * _max_y + fy] = next_light_float_strength
					elif light_map[f_coord] > next_light_float_strength:
						light_map[fx * _max_y + fy] = next_light_float_strength


func _place_object(node: Node2D, map_loc: Vector2i) -> void:
	node.position = %TerrainLayer.map_to_local(map_loc)
	%TerrainLayer.add_child(node)


func _find_farthest_spot(from: Array[Vector2i]) -> Vector2i:
	var dist: Dictionary[int, int] = {}
	var max_dist: int = 0
	for f: Vector2i in from:
		dist[f.x * _max_y + f.y] = max_dist
	var completed: bool = false
	var final_locs: Array[int] = []
	while not completed:
		completed = true
		var possible_locs: Array[int] = []
		for coord: int in dist.keys():
			if dist[coord] != max_dist:
				continue
			var up: int = coord - 1
			if not _walls[up] and not dist.has(up) and _coord_has_source_id(up):
				dist[up] = max_dist + 1
				if not _has_wall_neighbors(up):
					possible_locs.append(up)
				completed = false
			var down: int = coord + 1
			if not _walls[down] and not dist.has(down) and _coord_has_source_id(down):
				dist[down] = max_dist + 1
				if not _has_wall_neighbors(down):
					possible_locs.append(down)
				completed = false
			var left: int = coord - _max_y
			if not _walls[left] and not dist.has(left) and _coord_has_source_id(left):
				dist[left] = max_dist + 1
				if not _has_wall_neighbors(left):
					possible_locs.append(left)
				completed = false
			var right: int = coord + _max_y
			if not _walls[right] and not dist.has(right) and _coord_has_source_id(right):
				dist[right] = max_dist + 1
				if not _has_wall_neighbors(right):
					possible_locs.append(right)
				completed = false
		if completed == false:
			max_dist += 1
			if not possible_locs.is_empty():
				final_locs = possible_locs
	var coord: int = final_locs[randi() % final_locs.size()]
	return Vector2i(int(coord / float(_max_y)), coord % _max_y)


func _coord_has_source_id(coord: int) -> bool:
	var map_loc: Vector2i = Vector2i(int(coord / float(_max_y)), coord % _max_y)
	return (%TerrainLayer as TileMapLayer).get_cell_source_id(map_loc) != -1


func _has_wall_neighbors(coord: int) -> bool:
	if _walls[coord - 1]:
		return true
	if _walls[coord + 1]:
		return true
	if _walls[coord - _max_y]:
		return true
	if _walls[coord + _max_y]:
		return true
	return false


func _find_a_spot() -> Vector2i:
	var ret_val: Vector2i = Vector2i.MIN
	var seen: int = 0
	for x in range(2, _max_x - 2):
		for y in range(2, _max_y - 2):
			var i: int = x * _max_y + y
			if _walls[i]:
				continue
			if _has_wall_neighbors(i):
				continue
			var map_loc: Vector2i = Vector2i(x, y)
			if (%TerrainLayer as TileMapLayer).get_cell_source_id(map_loc) == -1:
				continue
			seen += 1
			if seen < 2 or (randi() % seen) == 1:
				ret_val = map_loc
	return ret_val


func _find_two_rooms() -> Array[Vector2i]:
	var room_id: int = 1
	var rooms: Dictionary[int, int] = {}
	for x in range(1, _max_x - 1):
		for y in range(1, _max_y - 1):
			if not _walls[x * _max_y + y]:
				rooms[x * _max_y + y] = room_id
				room_id += 1
	var found_one: bool = true
	while found_one:
		found_one = false
		for x in range(1, _max_x - 2):
			for y in range(1, _max_y - 2):
				var i: int = x * _max_y + y
				if _walls[i]:
					continue
				var ri: int = rooms[i]
				var j: int = x * _max_y + y + 1
				if not _walls[j]:
					var rj: int = rooms[j]
					if ri < rj:
						rooms[j] = ri
						found_one = true
					elif ri != rj:
						rooms[i] = rj
						found_one = true
				var k: int = (x + 1) * _max_y + y
				if not _walls[k]:
					var rk: int = rooms[k]
					if ri < rk:
						rooms[k] = ri
						found_one = true
					elif ri != rk:
						rooms[i] = rk
						found_one = true
	var ret_val: Array[Vector2i] = []
	var first_found: int = -1
	for x in range(2, _max_x - 3):
		for y in range(2, _max_y - 3):
			var i: int = x * _max_y + y
			if _walls[i]:
				continue
			if first_found < 0:
				first_found = rooms[i]
				ret_val.append(Vector2i(x, y))
			elif first_found != rooms[i]:
				ret_val.append(Vector2i(x, y))
				return ret_val
	return []


func _connect_two_points(start: Vector2i, end: Vector2i) -> void:
	_clear_rocks(_get_path(start, end))


func _get_path(start: Vector2i, end: Vector2i) -> PackedVector2Array:
	var map_rect: Rect2i = (%TerrainLayer as TileMapLayer).get_used_rect()
	var astar: AStarGrid2D = AStarGrid2D.new()
	astar.region = map_rect
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for x in range(map_rect.position.x, map_rect.position.x + map_rect.size.x):
		for y in range(map_rect.position.y, map_rect.position.y + map_rect.size.y):
			var loc: Vector2i = Vector2i(x, y)
			if _walls[x * _max_y + y]:
				astar.set_point_weight_scale(loc, 50.0)
			else:
				astar.set_point_weight_scale(loc, 1.0)
	return astar.get_point_path(start, end)


func _clear_rocks(path: PackedVector2Array):
	for loc: Vector2i in path:
		_nuke_around(loc)


func _nuke_around(loc: Vector2i) -> void:
	_walls[loc.x * _max_y + loc.y] = false
	_walls[loc.x * _max_y + loc.y + 1] = false
	_walls[loc.x * _max_y + loc.y - 1] = false
	_walls[(loc.x + 1) * _max_y + loc.y] = false
	_walls[(loc.x - 1) * _max_y + loc.y] = false
