class_name Play extends StateMachineState

func _ready() -> void:
	%TileMapLayer.clear()
	#var noise: FastNoiseLite = FastNoiseLite.new()
	#noise.noise_type = FastNoiseLite.TYPE_SIMPLEX # FastNoiseLite.TYPE_PERLIN
	#noise.frequency = 16.45
	var max_x: int = 60
	var max_y: int = 40
	var m: Dictionary[int, bool] = {}
	for x in range(0, max_x):
		for y in range(0, max_y):
			m[x * max_y + y] = randi() % 2 == 0
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
						elif m[fx * max_y + fy]:
							c = c + 1
				if x == 0 or y == 0 or x == max_x - 1 or y == max_y - 1:
					n[x * max_y + y] = true
				elif c > 4:
					n[x * max_y + y] = true
				elif c == 4 and m[x * max_y + y]:
					n[x * max_y + y] = true
				else:
					n[x * max_y + y] = false
		m = n
	var two_points: Array[Vector2i] = _find_two_rooms(m, max_x, max_y)
	while not two_points.is_empty():
		_connect_two_points(m, max_x, max_y, two_points[0], two_points[1])
		two_points = _find_two_rooms(m, max_x, max_y)
	for x in range(0, max_x):
		for y in range(0, max_y):
			var source_id: int = 0 if m[x * max_y + y] else 1
			var loc: Vector2i = Vector2i(x, y)
			#if loc.x == 0 or loc.y == 0 or loc.x == max_x - 1 or loc.y == max_y - 1:
			#	source_id = 0
			if source_id == 1:
				var atlas: Vector2i = Vector2i(0, 0)
				%TileMapLayer.set_cell(loc, 0, atlas)
			else:
				var atlas: Vector2i = Vector2i(randi() % 3, 0)
				%TileMapLayer.set_cell(loc, 1, atlas)
	var a_spot: Vector2i = _find_a_spot(m, max_x, max_y)
	var start_spot: Vector2i = _find_farthest_spot([a_spot], m, max_x, max_y)
	%TileMapLayer.set_cell(start_spot, 4, Vector2i.ZERO)
	var goal_spot: Vector2i = _find_farthest_spot([start_spot], m, max_x, max_y)
	%TileMapLayer.set_cell(goal_spot, 3, Vector2i.ZERO)
	var path: Array[Vector2i] = []
	for p: Vector2i in _get_path(m, max_x, max_y, start_spot, goal_spot):
		path.append(p)
		#if p != start_spot and p != goal_spot:
			#%TileMapLayer.set_cell(p, 2, Vector2i.ZERO)
	var treasure_spot_a: Vector2i = _find_farthest_spot(path, m, max_x, max_y)
	%TileMapLayer.set_cell(treasure_spot_a, 5, Vector2i.ZERO)
	path.append(treasure_spot_a)
	var treasure_spot_b: Vector2i = _find_farthest_spot(path, m, max_x, max_y)
	%TileMapLayer.set_cell(treasure_spot_b, 5, Vector2i.ZERO)


func _find_farthest_spot(from: Array[Vector2i], walls: Dictionary[int, bool], max_x: int, max_y: int) -> Vector2i:
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
			if not walls[up] and not dist.has(up):
				dist[up] = max_dist + 1
				if not _has_wall_neighbors(up, walls, max_x, max_y):
					possible_locs.append(up)
				completed = false
			var down: int = coord + 1
			if not walls[down] and not dist.has(down):
				dist[down] = max_dist + 1
				if not _has_wall_neighbors(down, walls, max_x, max_y):
					possible_locs.append(down)
				completed = false
			var left: int = coord - max_y
			if not walls[left] and not dist.has(left):
				dist[left] = max_dist + 1
				if not _has_wall_neighbors(left, walls, max_x, max_y):
					possible_locs.append(left)
				completed = false
			var right: int = coord + max_y
			if not walls[right] and not dist.has(right):
				dist[right] = max_dist + 1
				if not _has_wall_neighbors(right, walls, max_x, max_y):
					possible_locs.append(right)
				completed = false
		if completed == false:
			max_dist += 1
			if not possible_locs.is_empty():
				final_locs = possible_locs
	var coord: int = final_locs[randi() % final_locs.size()]
	return Vector2i(int(coord / float(max_y)), coord % max_y)


func _has_wall_neighbors(coord: int, walls: Dictionary[int, bool], _max_x: int, max_y: int) -> bool:
	if walls[coord - 1]:
		return true
	if walls[coord + 1]:
		return true
	if walls[coord - max_y]:
		return true
	if walls[coord + max_y]:
		return true
	return false


func _find_a_spot(walls: Dictionary[int, bool], max_x: int, max_y: int) -> Vector2i:
	var ret_val: Vector2i = Vector2i.MIN
	var seen: int = 0
	for x in range(2, max_x - 2):
		for y in range(2, max_y - 2):
			var i: int = x * max_y + y
			if walls[i]:
				continue
			if _has_wall_neighbors(i, walls, max_x, max_y):
				continue
			seen += 1
			if seen < 2 or (randi() % seen) == 1:
				ret_val = Vector2i(x, y)
	return ret_val


func _find_two_rooms(walls: Dictionary[int, bool], max_x: int, max_y: int) -> Array[Vector2i]:
	var room_id: int = 1
	var rooms: Dictionary[int, int] = {}
	for x in range(1, max_x - 1):
		for y in range(1, max_y - 1):
			if not walls[x * max_y + y]:
				rooms[x * max_y + y] = room_id
				room_id += 1
	var found_one: bool = true
	while found_one:
		found_one = false
		for x in range(1, max_x - 2):
			for y in range(1, max_y - 2):
				var i: int = x * max_y + y
				if walls[i]:
					continue
				var ri: int = rooms[i]
				var j: int = x * max_y + y + 1
				if not walls[j]:
					var rj: int = rooms[j]
					if ri < rj:
						rooms[j] = ri
						found_one = true
					elif ri != rj:
						rooms[i] = rj
						found_one = true
				var k: int = (x + 1) * max_y + y
				if not walls[k]:
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
			if walls[i]:
				continue
			if first_found < 0:
				first_found = rooms[i]
				ret_val.append(Vector2i(x, y))
			elif first_found != rooms[i]:
				ret_val.append(Vector2i(x, y))
				return ret_val
	return []

func _connect_two_points(walls: Dictionary[int, bool], max_x: int, max_y: int, start: Vector2i, end: Vector2i) -> void:
	_clear_rocks(walls, max_x, max_y, _get_path(walls, max_x, max_y, start, end))


func _get_path(walls: Dictionary[int, bool], max_x: int, max_y: int, start: Vector2i, end: Vector2i) -> PackedVector2Array:
	var astar: AStarGrid2D = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, max_x, max_y)
	astar.update()
	for x in range(0, max_x):
		for y in range(0, max_y):
			var loc: Vector2i = Vector2i(x, y)
			if walls[x * max_y + y]:
				astar.set_point_weight_scale(loc, 50.0)
			else:
				astar.set_point_weight_scale(loc, 1.0)
	return astar.get_point_path(start, end)


func _clear_rocks(walls: Dictionary[int, bool], max_x: int, max_y: int, path: PackedVector2Array):
	for loc: Vector2i in path:
		_nuke_around(loc, walls, max_x, max_y)


func _nuke_around(loc: Vector2i, walls: Dictionary[int, bool], _max_x: int, max_y: int) -> void:
	walls[loc.x * max_y + loc.y] = false
	walls[loc.x * max_y + loc.y + 1] = false
	walls[loc.x * max_y + loc.y - 1] = false
	walls[(loc.x + 1) * max_y + loc.y] = false
	walls[(loc.x - 1) * max_y + loc.y] = false
