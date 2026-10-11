class_name Play extends StateMachineState

var _seen_cells: Dictionary[int,bool] = {}
var _walls: Dictionary[int, bool] = {}
var max_x: int = 60
var max_y: int = 40
var _start_spot: Vector2i = Vector2i.MIN
var _end_spot: Vector2i = Vector2i.MIN
var _party_spot: Vector2i = Vector2i.MIN
var _party_walking_towards_end: bool = true


func _ready() -> void:
	%TerrainLayer.clear()
	#var noise: FastNoiseLite = FastNoiseLite.new()
	#noise.noise_type = FastNoiseLite.TYPE_SIMPLEX # FastNoiseLite.TYPE_PERLIN
	#noise.frequency = 16.45
	for x in range(0, max_x):
		for y in range(0, max_y):
			_walls[x * max_y + y] = randi() % 2 == 0
	for i in range(0, 8):
		var n: Dictionary[int, bool] = {}
		for x in range(0, max_x):
			for y in range(0, max_y):
				var c: int = 0
				for dx in range(-1, 2):
					var fx: int = x + dx
					for dy in range(-1, 2):
						var fy: int = y + dy
						if dx == 0 and dy == 0:
							pass
						elif fx < 0 or fy < 0 or fx >= max_x or fy >= max_y:
							c = c + 1
						elif _walls[fx * max_y + fy]:
							c = c + 1
				if x == 0 or y == 0 or x == max_x - 1 or y == max_y - 1:
					n[x * max_y + y] = true
				elif c > 4:
					n[x * max_y + y] = true
				elif c == 4 and _walls[x * max_y + y]:
					n[x * max_y + y] = true
				else:
					n[x * max_y + y] = false
		_walls = n
	var two_points: Array[Vector2i] = _find_two_rooms()
	while not two_points.is_empty():
		_connect_two_points(two_points[0], two_points[1])
		two_points = _find_two_rooms()
	for x in range(0, max_x):
		for y in range(0, max_y):
			var source_id: int = 0 if _walls[x * max_y + y] else 1
			var loc: Vector2i = Vector2i(x, y)
			#if loc.x == 0 or loc.y == 0 or loc.x == max_x - 1 or loc.y == max_y - 1:
			#	source_id = 0
			if source_id == 1:
				var atlas: Vector2i = Vector2i(0, 0)
				%TerrainLayer.set_cell(loc, 0, atlas)
			else:
				var atlas: Vector2i = Vector2i(randi() % 3, 0)
				%TerrainLayer.set_cell(loc, 1, atlas)
	var a_spot: Vector2i = _find_a_spot()
	_start_spot = _find_farthest_spot([a_spot])
	_party_spot = _start_spot
	var start_marker: PackedScene = load("res://scenes/markers/start_marker.tscn")
	_place_object(start_marker.instantiate() as Node2D, _start_spot)
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


const _footstep_time: float = 0.5
var _footstep: float = _footstep_time
func _process(delta: float) -> void:
	_footstep -= delta
	if _footstep >= 0.0:
		return
	_footstep += _footstep_time
		
	var path;
	if _party_walking_towards_end:
		if _party_spot == _end_spot:
			_party_walking_towards_end = false
			return
		path = _get_path(_party_spot, _end_spot)
	else:
		if _party_spot == _start_spot:
			_party_walking_towards_end = true
			return
		path = _get_path(_party_spot, _start_spot)
		
	if Vector2i(path[0]) == _party_spot:
		_party_spot = Vector2i(path[1])
	else:
		_party_spot = Vector2i(path[0])
	_update_fog_of_war()


func _update_fog_of_war() -> void:
	%FogOfWarLayer.clear()
	var light_cones: Dictionary[int, int] = _generate_light_cones(_party_spot)
	for x in range(0, max_x):
		for y in range(0, max_y):
			var coord: int = x * max_y + y
			if light_cones.has(coord):
				_seen_cells[coord] = true
				var dist: int = light_cones[coord]
				if dist <= 3:
					pass
				elif dist <= 6:
					%FogOfWarLayer.set_cell(Vector2i(x, y), 0, Vector2i(0,0)) # one sixth
				elif dist <= 9:
					%FogOfWarLayer.set_cell(Vector2i(x, y), 0, Vector2i(1,0)) # one third
				elif dist <= 12:
					%FogOfWarLayer.set_cell(Vector2i(x, y), 0, Vector2i(2,0)) # one half
			elif _seen_cells.has(coord):
				%FogOfWarLayer.set_cell(Vector2i(x, y), 0, Vector2i(3,0)) # five sixths
			else:
				%FogOfWarLayer.set_cell(Vector2i(x, y), 0, Vector2i(4,0)) # full


func _generate_light_cones(map_loc: Vector2i) -> Dictionary[int, int]:
	var ret_val: Dictionary[int, int] = {}
	ret_val[map_loc.x * max_y + map_loc.y] = 0
	for current_dist in range(0, 12):
		for coord: int in ret_val.keys():
			if ret_val[coord] != current_dist:
				continue
			if _walls[coord]:
				continue
			var x: int = int(coord / float(max_y))
			var y: int = coord % max_y
			for fx in range(x-1, x+2):
				for fy in range(y-1, y+2):
					var f_coord: int = fx * max_y + fy
					if ret_val.has(f_coord):
						continue
					ret_val[fx * max_y + fy] = current_dist + 1
	return ret_val


func _place_object(node: Node2D, map_loc: Vector2i) -> void:
	node.position = %TerrainLayer.map_to_local(map_loc)
	%TerrainLayer.add_child(node)


func _find_farthest_spot(from: Array[Vector2i]) -> Vector2i:
	var dist: Dictionary[int, int] = {}
	var max_dist: int = 0
	for f: Vector2i in from:
		dist[f.x * max_y + f.y] = max_dist
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
			var left: int = coord - max_y
			if not _walls[left] and not dist.has(left):
				dist[left] = max_dist + 1
				if not _has_wall_neighbors(left):
					possible_locs.append(left)
				completed = false
			var right: int = coord + max_y
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
	return Vector2i(int(coord / float(max_y)), coord % max_y)


func _has_wall_neighbors(coord: int) -> bool:
	if _walls[coord - 1]:
		return true
	if _walls[coord + 1]:
		return true
	if _walls[coord - max_y]:
		return true
	if _walls[coord + max_y]:
		return true
	return false


func _find_a_spot() -> Vector2i:
	var ret_val: Vector2i = Vector2i.MIN
	var seen: int = 0
	for x in range(2, max_x - 2):
		for y in range(2, max_y - 2):
			var i: int = x * max_y + y
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
	for x in range(1, max_x - 1):
		for y in range(1, max_y - 1):
			if not _walls[x * max_y + y]:
				rooms[x * max_y + y] = room_id
				room_id += 1
	var found_one: bool = true
	while found_one:
		found_one = false
		for x in range(1, max_x - 2):
			for y in range(1, max_y - 2):
				var i: int = x * max_y + y
				if _walls[i]:
					continue
				var ri: int = rooms[i]
				var j: int = x * max_y + y + 1
				if not _walls[j]:
					var rj: int = rooms[j]
					if ri < rj:
						rooms[j] = ri
						found_one = true
					elif ri != rj:
						rooms[i] = rj
						found_one = true
				var k: int = (x + 1) * max_y + y
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
	for x in range(2, max_x - 3):
		for y in range(2, max_y - 3):
			var i: int = x * max_y + y
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
	astar.region = Rect2i(0, 0, max_x, max_y)
	astar.update()
	for x in range(0, max_x):
		for y in range(0, max_y):
			var loc: Vector2i = Vector2i(x, y)
			if _walls[x * max_y + y]:
				astar.set_point_weight_scale(loc, 50.0)
			else:
				astar.set_point_weight_scale(loc, 1.0)
	return astar.get_point_path(start, end)


func _clear_rocks(path: PackedVector2Array):
	for loc: Vector2i in path:
		_nuke_around(loc)


func _nuke_around(loc: Vector2i) -> void:
	_walls[loc.x * max_y + loc.y] = false
	_walls[loc.x * max_y + loc.y + 1] = false
	_walls[loc.x * max_y + loc.y - 1] = false
	_walls[(loc.x + 1) * max_y + loc.y] = false
	_walls[(loc.x - 1) * max_y + loc.y] = false
