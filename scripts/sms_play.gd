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
				
			
	# TODO: Need to count unique "rooms" and then use the AStarGrid2D below to
	#       blast connective walls between the rooms

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
	print("%s %s" % [start, end])
		 
	var astar: AStarGrid2D = AStarGrid2D.new()
	#astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.region = Rect2i(0, 0, max_x, max_y)
	astar.update()
	for x in range(0, max_x):
		for y in range(0, max_y):
			var loc: Vector2i = Vector2i(x, y)
			if walls[x * max_y + y]:
				astar.set_point_weight_scale(loc, 50.0)
				#var source_f = noise.get_noise_2d(float(x) / float(max_x), float(y) / float(max_y))
				#var v: float = (source_f + 2.0) * 2
				#astar.set_point_weight_scale(loc, v)
			else:
				astar.set_point_weight_scale(loc, 1.0)
	_clear_rocks(walls, max_x, max_y, astar.get_point_path(start, end))
	#var mid_point_1: Vector2i = _clear_rocks(astar, Vector2i(3, 3), Vector2i(max_x - 4, max_y - 4))
	#var mid_point_2: Vector2i = _clear_rocks(astar, Vector2i(max_x - 4, 3), Vector2i(3, max_y - 4))
	#_clear_rocks(astar, mid_point_1, mid_point_2)
	#var mid_point_3: Vector2i = _clear_rocks(astar, Vector2i(3, 3), Vector2i(3, max_y - 4))
	#var mid_point_4: Vector2i = _clear_rocks(astar, Vector2i(max_x - 4, max_y - 4), Vector2i(3, max_y - 4))
	#_clear_rocks(astar, mid_point_3, mid_point_4)


func _clear_rocks(walls: Dictionary[int, bool], max_x: int, max_y: int, path: PackedVector2Array):
	for loc: Vector2i in path:
		_nuke_around(loc, walls, max_x, max_y)


func _nuke_around(loc: Vector2i, walls: Dictionary[int, bool], max_x: int, max_y: int) -> void:
	walls[loc.x * max_y + loc.y] = false
	walls[loc.x * max_y + loc.y + 1] = false
	walls[loc.x * max_y + loc.y - 1] = false
	walls[(loc.x + 1) * max_y + loc.y] = false
	walls[(loc.x - 1) * max_y + loc.y] = false
	
