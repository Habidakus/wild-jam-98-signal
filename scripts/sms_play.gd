class_name Play extends StateMachineState


enum PlayState { UNDEFINED, SETUP_COMMAND, AWAITING_COMMAND, ANIMATING_COMMAND }


var _play_state: PlayState = PlayState.UNDEFINED
var _seen_cells: Dictionary[int,bool] = {}
var _walls: Dictionary[int, bool] = {}
var _max_x: int = 70
var _max_y: int = 40
var _start_spot: Vector2i = Vector2i.MIN
var _end_spot: Vector2i = Vector2i.MIN
var _unit_list: Array[Array] = []


#const _footstep_time: float = 0.66


func enter_state() -> void:
	super.enter_state()
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
	var a_spot: Vector2i = _find_a_spot()
	_start_spot = _find_farthest_spot([a_spot])
	var start_marker_scene: PackedScene = load("res://scenes/markers/start_marker.tscn")
	var start_marker_instance: Node2D = start_marker_scene.instantiate()
	_place_object(start_marker_instance, _start_spot)
	start_marker_instance.hide()

	var facing: Vector2i = Vector2i.RIGHT
	for frogman_resource in [load("res://data/units/explorefrog.tres"), load("res://data/units/speedfrog.tres"), load("res://data/units/unicornfrog.tres")]:
		_add_unit(frogman_resource, _find_unoccupied_space_near(_start_spot), facing)
		facing = Vector2i(- facing.y, facing.x) # rotate 90 degrees
	_play_state = PlayState.SETUP_COMMAND
	
	_end_spot = _find_farthest_spot([_start_spot])
	var end_marker: PackedScene = load("res://scenes/markers/end_marker.tscn")
	_place_object(end_marker.instantiate() as Node2D, _end_spot)
	var path: Array[Vector2i] = []
	for p: Vector2i in _get_path(_start_spot, _end_spot):
		path.append(p)
	var treasure_spot_a: Vector2i = _find_farthest_spot(path)
	var loot_marker: PackedScene = load("res://scenes/markers/loot_marker.tscn")
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
	_unit_list.append([unit_graphic, facing, randf()])
	_unit_list.sort_custom(func(a, b): return a[2] < b[2])


func _process(delta: float) -> void:
	#[unit_graphic, facing, initiative]
	var current_entry: Array = _unit_list[0]
	match _play_state:
		PlayState.SETUP_COMMAND:
			_process_setup_command(delta, current_entry[0], current_entry[1])
		PlayState.AWAITING_COMMAND:
			_process_awaiting_command(delta, current_entry[0], current_entry[1])
		PlayState.ANIMATING_COMMAND:
			_process_animating_command(delta, current_entry[0], current_entry[1])
		_:
			assert(false, "Bad Play State: %s" % [_play_state])


func _process_animating_command(_delta: float, _ug: UnitGraphic, _facing: Vector2i) -> void:
	%PlayerControlls.hide()


func _clear_ability_bar() -> void:
	for child: Node in %PlayerControlls.get_children():
		if child.has_meta("ability_order"):
			%PlayerControlls.remove_child(child)
			child.queue_free()


func _add_ability_to_bar(ability: Ability) -> void:
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
	%PlayerControlls.add_child(button)
	%PlayerControlls.move_child(button, max_order + 1)


func _process_setup_command(_delta: float, ug: UnitGraphic, _facing: Vector2i) -> void:
	%PlayerControlls.show()
	_clear_ability_bar()
	for ability: Ability in ug.get_abilities():
		if ability.always_on == true:
			continue
		_add_ability_to_bar(ability)
	_play_state = PlayState.AWAITING_COMMAND


func _process_awaiting_command(_delta: float, _ug: UnitGraphic, _facing: Vector2i) -> void:
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
		var illumination: Ability = unit_graphic.get_illumination_ability()
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
