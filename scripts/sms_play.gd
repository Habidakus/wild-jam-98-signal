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
				if c > 4:
					n[x * max_y + y] = true
				elif c == 4 and m[x * max_y + y]:
					n[x * max_y + y] = true
				else:
					n[x * max_y + y] = false
		m = n
	var atlas: Vector2i = Vector2i(0, 0)
	for x in range(1, max_x - 1):
		for y in range(1, max_y - 1):
			var source_id: int = 0 if m[x * max_y + y] else 1
			if source_id == 1:
				var loc: Vector2i = Vector2i(x, y)
				%TileMapLayer.set_cell(loc, source_id, atlas)
			
	# TODO: Need to count unique "rooms" and then use the AStarGrid2D below to
	#       blast connective walls between the rooms
	
	pass
		 
	#var astar: AStarGrid2D = AStarGrid2D.new()
	#astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	#astar.region = Rect2i(0, 0, max_x, max_y)
	#astar.update()
	#for x in range(0, max_x):
		#for y in range(0, max_y):
			#var loc: Vector2i = Vector2i(x, y)
			#if x < 2 or y < 2 or x > max_x - 3 or y > max_y - 3:
				#astar.set_point_weight_scale(loc, 100.0)
			#else:
				#var source_f = noise.get_noise_2d(float(x) / float(max_x), float(y) / float(max_y))
				#var v: float = (source_f + 2.0) * 2
				#astar.set_point_weight_scale(loc, v)
	#var mid_point_1: Vector2i = _clear_rocks(astar, Vector2i(3, 3), Vector2i(max_x - 4, max_y - 4))
	#var mid_point_2: Vector2i = _clear_rocks(astar, Vector2i(max_x - 4, 3), Vector2i(3, max_y - 4))
	#_clear_rocks(astar, mid_point_1, mid_point_2)
	#var mid_point_3: Vector2i = _clear_rocks(astar, Vector2i(3, 3), Vector2i(3, max_y - 4))
	#var mid_point_4: Vector2i = _clear_rocks(astar, Vector2i(max_x - 4, max_y - 4), Vector2i(3, max_y - 4))
	#_clear_rocks(astar, mid_point_3, mid_point_4)


func _clear_rocks(astar: AStarGrid2D, start: Vector2i, end: Vector2i) -> Vector2i:
	var path = astar.get_point_path(start, end)
	for loc: Vector2i in path:
		_nuke_around(loc)
	var mid_point: int = int(path.size() / 3.0)
	return path[mid_point]


func _nuke_around(loc: Vector2i) -> void:
	var atlas: Vector2i = Vector2i(0, 0)
	var source_id: int = 0
	%TileMapLayer.set_cell(loc, source_id, atlas)
	%TileMapLayer.set_cell(loc + Vector2i.DOWN, source_id, atlas)
	%TileMapLayer.set_cell(loc + Vector2i.UP, source_id, atlas)
	%TileMapLayer.set_cell(loc + Vector2i.LEFT, source_id, atlas)
	%TileMapLayer.set_cell(loc + Vector2i.RIGHT, source_id, atlas)
	
