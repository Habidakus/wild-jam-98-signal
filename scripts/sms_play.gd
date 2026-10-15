class_name Play extends StateMachineState


enum PlayState { UNDEFINED, SETUP_COMMAND, AWAITING_COMMAND_SELECTION, AWAITING_COMMAND_CONFIGURATION, ANIMATING_COMMAND }


var _play_state: PlayState = PlayState.UNDEFINED
var _seen_cells: Dictionary[int,bool] = {}
var _walls: Dictionary[int, bool] = {}
var _max_x: int = 70
var _max_y: int = 40
var _start_spot: Vector2i = Vector2i.MIN
var _end_spot: Vector2i = Vector2i.MIN
var _unit_list: Array[Array] = []

const TURN_TIME: float = 0.5
const HOP_TIME: float = 0.5
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


func enter_state() -> void:
	super.enter_state()
	%Camera2D.position = size / 2.0
	%PlayerControlls.show()
	%TerrainLayer.clear()
	#var noise: FastNoiseLite = FastNoiseLite.new()
	#noise.noise_type = FastNoiseLite.TYPE_SIMPLEX # FastNoiseLite.TYPE_PERLIN
	#noise.frequency = 16.45
	for x in range(0, _max_x):
		for y in range(0, _max_y):
			_walls[x * _max_y + y] = randi() % 2 == 0
	for i in range(0, 8):
		var n: Dictionary[int, bool] = {}
		for x in range(0, _max_x):
			for y in range(0, _max_y):
				var c: int = 0
				for dx in range(-1, 2):
					var fx: int = x + dx
					for dy in range(-1, 2):
						var fy: int = y + dy
						if dx == 0 and dy == 0:
							pass
						elif fx < 0 or fy < 0 or fx >= _max_x or fy >= _max_y:
							c = c + 1
						elif _walls[fx * _max_y + fy]:
							c = c + 1
				if x == 0 or y == 0 or x == _max_x - 1 or y == _max_y - 1:
					n[x * _max_y + y] = true
				elif c > 4:
					n[x * _max_y + y] = true
				elif c == 4 and _walls[x * _max_y + y]:
					n[x * _max_y + y] = true
				else:
					n[x * _max_y + y] = false
		_walls = n
	var two_points: Array[Vector2i] = _find_two_rooms()
	while not two_points.is_empty():
		_connect_two_points(two_points[0], two_points[1])
		two_points = _find_two_rooms()
	for x in range(0, _max_x):
		for y in range(0, _max_y):
			var source_id: int = 0 if _walls[x * _max_y + y] else 1
			var loc: Vector2i = Vector2i(x, y)
			#if loc.x == 0 or loc.y == 0 or loc.x == _max_x - 1 or loc.y == _max_y - 1:
			#	source_id = 0
			if source_id == 1:
				var atlas: Vector2i = Vector2i(0, 0)
				%TerrainLayer.set_cell(loc, 0, atlas)
			else:
				var atlas: Vector2i = Vector2i(randi() % 3, 0)
				%TerrainLayer.set_cell(loc, 1, atlas)
	
	################################
	#var import_terrain_ps: PackedScene = load("res://maps/levels/0_tutorial.tscn")
	#var import_terrain: TileMapLayer = import_terrain_ps.instantiate()
	#(%TerrainLayer as TileMapLayer).clear()
	#(%TerrainLayer as TileMapLayer).tile_set = import_terrain.tile_set
	#for cell_loc: Vector2i in import_terrain.get_used_cells():
		#var source_id: int = import_terrain.get_cell_source_id(cell_loc)
		#var atlas_coords: Vector2i = import_terrain.get_cell_atlas_coords(cell_loc)
		#var alternative_tile: int = import_terrain.get_cell_alternative_tile(cell_loc)
		#(%TerrainLayer as TileMapLayer).set_cell(cell_loc, source_id, atlas_coords, alternative_tile)
	#for child: Node in import_terrain.get_children():
		#var map_loc: Vector2i = import_terrain.local_to_map(child.position)
		#var new_child = child.duplicate()
		#_place_object(new_child, map_loc)
	################################
	
	_start_spot = Vector2i.ZERO
	_end_spot = Vector2i.ZERO
	var has_loot: bool = false
	for child: Node in %TerrainLayer.get_children():
		if child.has_meta("marker"):
			var marker: String = child.get_meta("marker")
			if marker == "start":
				_start_spot = %TerrainLayer.local_to_map(child.position)
				child.hide()
			elif marker == "end":
				_end_spot = %TerrainLayer.local_to_map(child.position)
			elif marker == "loot":
				has_loot = true
			else:
				print("UNKNOWN marker in map: %s" % [marker])
	
	if _start_spot == Vector2i.ZERO:
		var a_spot: Vector2i = _find_a_spot()
		_start_spot = _find_farthest_spot([a_spot])
		var start_marker_scene: PackedScene = load("res://maps/objects/start_marker.tscn")
		var start_marker_instance: Node2D = start_marker_scene.instantiate()
		_place_object(start_marker_instance, _start_spot)
		start_marker_instance.hide()

	var facing: Vector2i = Vector2i.RIGHT
	for frogman_resource in [load("res://data/units/explorefrog.tres"), load("res://data/units/speedfrog.tres"), load("res://data/units/unicornfrog.tres")]:
		_add_unit(frogman_resource, _find_unoccupied_space_near(_start_spot), facing)
		facing = Vector2i(- facing.y, facing.x) # rotate 90 degrees
	_play_state = PlayState.SETUP_COMMAND
	
	if _end_spot == Vector2i.ZERO:
		_end_spot = _find_farthest_spot([_start_spot])
		var end_marker: PackedScene = load("res://maps/objects/end_marker.tscn")
		_place_object(end_marker.instantiate() as Node2D, _end_spot)
	
	if not has_loot:
		var path: Array[Vector2i] = []
		for p: Vector2i in _get_path(_start_spot, _end_spot):
			path.append(p)
		var treasure_spot_a: Vector2i = _find_farthest_spot(path)
		var loot_marker: PackedScene = load("res://maps/objects/loot_marker.tscn")
		_place_object(loot_marker.instantiate() as Node2D, treasure_spot_a)
		path.append(treasure_spot_a)
		var treasure_spot_b: Vector2i = _find_farthest_spot(path)
		_place_object(loot_marker.instantiate() as Node2D, treasure_spot_b)
	
	_update_fog_of_war()


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
	unit_graphic.set_unit(unit, true)
	_place_object(unit_graphic, spot)
	unit_graphic.set_facing(facing)
	unit_graphic.z_index = 100
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
		_:
			assert(false, "Bad Play State: %s" % [_play_state])


func _advance_to_next_unit() -> void:
	var f = _unit_list.pop_front()
	_unit_list.append(f)
	_play_state = PlayState.SETUP_COMMAND


func _process_animating_command(_delta: float, ug: UnitGraphic, _facing: Vector2i) -> void:
	%PlayerControlls.hide()
	if _animation_tween != null and _animation_tween.is_running():
		return
	ug.stop_sound()
	if _ap_remaining <= 0:
		_advance_to_next_unit()
	else:
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


var _selected_ability: Ability
var _ap_remaining: int
var _await_mouse_release: bool = false
var _camera_tween: Tween
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
	
	_camera_tween.tween_property(%Camera2D, "zoom", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_camera_tween.parallel()
	_camera_tween.tween_property(%Camera2D, "global_position", first_global_pos, 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	_camera_tween.tween_property(%Camera2D, "global_position", second_global_pos, 0.20)
	
	_camera_tween.tween_property(%Camera2D, "zoom", Vector2.ONE * 2.0, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_camera_tween.parallel()
	_camera_tween.tween_property(%Camera2D, "global_position", third_global_pos, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)


func _process_setup_command(_delta: float, ug: UnitGraphic, _facing: Vector2i) -> void:
	_on_center()
	%PlayerControlls.show()
	_selected_ability = null
	_ap_remaining = ug._unit_stats.action_points
	var stun_in_light: Ability = ug.get_ability(Ability.AbilityMechanism.STUN_IN_LIGHT)
	if stun_in_light != null:
		_on_pass()
	_clear_ability_bar()
	var abilities: Array[Ability] = ug.get_abilities()
	for ability_index: int in range(0, abilities.size()):
		if abilities[ability_index].always_on == true:
			continue
		_add_ability_to_bar(abilities[ability_index], ability_index)
	_play_state = PlayState.AWAITING_COMMAND_SELECTION


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
		if hover_control != self:
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
	_update_fog_of_war()


func _process_awaiting_walk_command(ug: UnitGraphic, facing: Vector2i, mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
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
					if walk_path.has(step_dest):
						if walk_path[step_dest][0] < distance:
							continue
					var new_path: Array = map_loc_path.duplicate()
					new_path.append(map_loc)
					walk_path[step_dest] = [map_loc_dist + 1, new_path]
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
			ug.start_hop_animation(true)
			_ap_remaining -= _selected_ability.ap_cost
			ug.play_sound(_selected_ability.activation_sound)
			_animation_tween = create_tween()
			var full_path: Array = mouse_path.duplicate()
			if full_path.is_empty():
				full_path.append(closest_map_loc_to_mouse)
			elif full_path[full_path.size() - 1] != closest_map_loc_to_mouse:
				full_path.append(closest_map_loc_to_mouse)
			_animation_payload = [ug_map_loc, facing, full_path, final_facing]
			#var delta: Vector2i = (closest_map_loc_to_mouse - ug_map_loc)
			#delta = delta / delta.length()
			#if delta != facing:
				#if delta + facing == Vector2i.ZERO:
					#var mid: Vector2i = Vector2i(1, 0) if delta.x == 0 else Vector2i(0, 1)
					#if randi() % 2 == 0:
						#mid = mid * Vector2i(-1, -1)
					#_animation_tween.tween_method(_animate_turn, Vector2(facing), Vector2(mid), TURN_TIME / 2.0)
					#_animation_tween.tween_method(_animate_turn, Vector2(mid), Vector2(delta), TURN_TIME / 2.0)
				#else:
					#_animation_tween.tween_method(_animate_turn, Vector2(facing), Vector2(delta), TURN_TIME / 2.0)
			_animation_tween.tween_method(_animate_walk, 0.0, 1.0, WALK_TIME * mouse_path.size())
			_animation_tween.tween_callback(_animate_walk.bind(2.0))
			#_animation_tween.tween_callback(_animate_hop.bind(2.0))
			_play_state = PlayState.ANIMATING_COMMAND


func _animate_walk(fraction: float) -> void:
	if fraction > 1.0:
		# end of animation
		var final_facing: Vector2i = _animation_payload[3]
		_update_current_unit_facing(final_facing)
		_update_fog_of_war()
		return
	var mouse_path: Array = _animation_payload[2]
	var mps: int = mouse_path.size()
	var index: int = int(clamp(0, mps - 1, float(mps) * fraction))
	var ug: UnitGraphic = _get_current_unit_graphic()
	var current_map_loc: Vector2i = %TerrainLayer.local_to_map(ug.position)
	var map_loc: Vector2i = mouse_path[index]
	if current_map_loc != map_loc:
		var dir: Vector2i = map_loc - current_map_loc
		_update_current_unit_facing(dir)
	ug.position = %TerrainLayer.map_to_local(map_loc)
	_update_fog_of_war()


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
			_animation_tween = create_tween()
			_animation_payload = [ug.position, %AbilityLayer.map_to_local(closest_map_loc_to_mouse)]
			var delta: Vector2i = (closest_map_loc_to_mouse - ug_map_loc)
			delta = delta / delta.length()
			if delta != facing:
				if delta + facing == Vector2i.ZERO:
					var mid: Vector2i = Vector2i(1, 0) if delta.x == 0 else Vector2i(0, 1)
					if randi() % 2 == 0:
						mid = mid * Vector2i(-1, -1)
					_animation_tween.tween_method(_animate_turn, Vector2(facing), Vector2(mid), TURN_TIME / 2.0)
					_animation_tween.tween_method(_animate_turn, Vector2(mid), Vector2(delta), TURN_TIME / 2.0)
				else:
					_animation_tween.tween_method(_animate_turn, Vector2(facing), Vector2(delta), TURN_TIME / 2.0)
			_animation_tween.tween_method(_animate_hop, 0.0, 1.0, HOP_TIME)
			_animation_tween.tween_callback(_animate_hop.bind(2.0))
			_play_state = PlayState.ANIMATING_COMMAND


var _animation_tween: Tween
var _animation_payload: Array
func _animate_hop(fraction: float) -> void:
	var ug: UnitGraphic = _get_current_unit_graphic()
	if fraction <= 1.0:
		ug.position = lerp(_animation_payload[0], _animation_payload[1], fraction)
		ug.set_hop_animation_frame(fraction)
	else:
		ug.position = _animation_payload[1]
		ug.start_idle_animation()
	_update_fog_of_war()


func _animate_turn(dir: Vector2) -> void:
	_update_current_unit_facing(dir)
	_update_fog_of_war()


func _process_awaiting_command_selection(_delta: float, _ug: UnitGraphic, _facing: Vector2i) -> void:
	%AbilityLayer.clear()
	%PlayerControlls.show()
	#for entry: Array in _unit_list:
		#entry[3] -= delta
		#if entry[3] < 0:
			##entry[3] += _footstep_time
			#var unit_map_loc: Vector2i = %TerrainLayer.local_to_map(entry[0].position)
			#if unit_map_loc == entry[2]:
				#entry[2] = _find_a_spot()
			#else:
				#var path: PackedVector2Array = _get_path(unit_map_loc, entry[2])
				#var next_cell: Vector2i = path[0]
				#var cell_after_that: Vector2i = path[1]
				#if path.size() == 2:
					#if next_cell == unit_map_loc:
						#next_cell = path[1]
						#cell_after_that = (next_cell - unit_map_loc) + next_cell
				#else:
					#assert(path.size() > 2)
					#if next_cell == unit_map_loc:
						#next_cell = path[1]
						#cell_after_that = path[2]
				#entry[0].position = %TerrainLayer.map_to_local(next_cell)
				##var facing: Vector2i = cell_after_that - next_cell
				#entry[0].set_facing(facing)
				#entry[1] = facing
	_update_fog_of_war()


func _update_fog_of_war() -> void:
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
	for x in range(-5, _max_x + 5):
		for y in range(-5, _max_y + 5):
			var coord: int = x * _max_y + y
			var map_loc: Vector2i = Vector2i(x, y)
			if light_cones.has(coord):
				_seen_cells[coord] = true
				var dist: float = light_cones[coord]
				if dist <= 0.25:
					pass
				elif dist <= 0.5:
					%FogOfWarLayer.set_cell(map_loc, 0, Vector2i(0,0)) # one sixth
				elif dist <= 0.75:
					%FogOfWarLayer.set_cell(map_loc, 0, Vector2i(1,0)) # one third
				else:
					%FogOfWarLayer.set_cell(map_loc, 0, Vector2i(2,0)) # one half
			elif _seen_cells.has(coord):
				%FogOfWarLayer.set_cell(map_loc, 0, Vector2i(3,0)) # five sixths
			else:
				%FogOfWarLayer.set_cell(map_loc, 0, Vector2i(4,0)) # full


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
			if not _walls[up] and not dist.has(up):
				dist[up] = max_dist + 1
				if not _has_wall_neighbors(up):
					possible_locs.append(up)
				completed = false
			var down: int = coord + 1
			if not _walls[down] and not dist.has(down):
				dist[down] = max_dist + 1
				if not _has_wall_neighbors(down):
					possible_locs.append(down)
				completed = false
			var left: int = coord - _max_y
			if not _walls[left] and not dist.has(left):
				dist[left] = max_dist + 1
				if not _has_wall_neighbors(left):
					possible_locs.append(left)
				completed = false
			var right: int = coord + _max_y
			if not _walls[right] and not dist.has(right):
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
			seen += 1
			if seen < 2 or (randi() % seen) == 1:
				ret_val = Vector2i(x, y)
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
	var astar: AStarGrid2D = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, _max_x, _max_y)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for x in range(0, _max_x):
		for y in range(0, _max_y):
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
