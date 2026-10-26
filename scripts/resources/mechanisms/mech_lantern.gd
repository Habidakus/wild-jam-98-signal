class_name Lantern extends IMechanism


var _play: Play
var _ug: UnitGraphic
var _ability: Ability


func setup(play: Play, ug: UnitGraphic, ability: Ability) -> void:
	_play = play
	_ug = ug
	_ability = ability


func is_enabled() -> bool:
	return true


func does_support_human() -> bool:
	return true


func on_select() -> void:
	assert(false, "should never be invoked")


func on_unselect() -> void:
	assert(false, "should never be invoked")


func update(_mouse_pressed: bool, _mouse_local_pos: Vector2) -> void:
	assert(false, "should never be invoked")


# Foe considerations
func does_support_artificial_opponent() -> bool:
	return false


func get_priority() -> int:
	return 111


func try_invoke() -> bool:
	if _ability.trigger == Ability.AbilityTrigger.INVOKED:
		_play.reduce_action_points(_ability.ap_cost)

	var fog_layer: TileMapLayer = _play.get_fog_of_war_layer()
	var ug_map_loc: Vector2i = fog_layer.local_to_map(_ug.position)
	var unit_facing: Vector2i = _play.get_unit_facing(_ug)
	_generate_light_cones(ug_map_loc, unit_facing)
	return true


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


func _generate_light_cones(map_loc: Vector2i, facing: Vector2i) -> void:
	var tmp_map: Dictionary[Vector2i, int] = {}
	tmp_map[map_loc] = 0
	_play.update_light_level(map_loc, 0)
	for current_dist in range(0, _ability.ability_range):
		var next_light_float_strength: float = (1.0 + float(current_dist)) / float(_ability.ability_range)
		for t_map_loc: Vector2i in tmp_map.keys():
			if tmp_map[t_map_loc] != current_dist:
				continue
			if _play.has_wall(t_map_loc):
				continue
			for fx in range(t_map_loc.x-1, t_map_loc.x+2):
				for fy in range(t_map_loc.y-1, t_map_loc.y+2):
					var f_map_loc: Vector2i = Vector2i(fx, fy)
					if tmp_map.has(f_map_loc):
						continue
					tmp_map[f_map_loc] = current_dist + 1
					if _is_in_cell_in_forward_arc(map_loc, facing, f_map_loc):
						_play.update_light_level(f_map_loc, next_light_float_strength)
