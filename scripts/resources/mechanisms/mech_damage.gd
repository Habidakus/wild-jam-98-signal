class_name Damage extends IMechanism


@export var face_away_from_target: bool = false


var _play: Play
var _ug: UnitGraphic
var _ability: Ability
#var _target_potential_scene: PackedScene = preload("res://scenes/potential_target.tscn")


func setup(play: Play, ug: UnitGraphic, ability: Ability) -> void:
	_play = play
	_ug = ug
	_ability = ability


func _get_all_targets() -> Array[UnitGraphic]:
	var ret_val: Array[UnitGraphic] = []
	var terrain_layer: TileMapLayer = _play.get_terrain_layer()
	var ug_map_loc: Vector2i = terrain_layer.local_to_map(_ug.position)
	for foe: UnitGraphic in _play.get_all_units():
		if foe.is_dead():
			continue
		if foe._unit_stats.unit_side == _ug._unit_stats.unit_side:
			continue
		var foe_map_loc: Vector2i = terrain_layer.local_to_map(foe.position)
		if not _play._try_get_path(ug_map_loc, foe_map_loc, _ability.ability_range, Play.PathLogic.DIRECT_FIRE, [foe], false).is_empty():
			ret_val.append(foe)
	return ret_val


func is_enabled() -> bool:
	return not _get_all_targets().is_empty()


# Human considerations
func does_support_human() -> bool:
	return true


func on_select() -> void:
	pass


func on_unselect() -> void:
	pass


func update(mouse_pressed: bool, mouse_local_pos: Vector2) -> void:
	var ability_layer: TileMapLayer = _play.get_ability_layer()
	ability_layer.clear()
	var targets: Array[UnitGraphic] = _get_all_targets()
	if targets.is_empty():
		return
	var target_instance: Control = _play.get_charge_reticle()
	target_instance.show()
	var ug_map_loc: Vector2i = ability_layer.local_to_map(_ug.position)
	var closest_foe_to_mouse: UnitGraphic
	var closest_dist_squared: float = INF
	for target: UnitGraphic in targets:
		var dist_squared: float = target.position.distance_squared_to(mouse_local_pos)
		if dist_squared < closest_dist_squared:
			closest_dist_squared = dist_squared
			closest_foe_to_mouse = target
	target_instance.position = closest_foe_to_mouse.position
	target_instance.hide_label()
	if not mouse_pressed:
		return
	_play.reduce_action_points(_ability.ap_cost)
	var target_map_loc: Vector2i = ability_layer.local_to_map(closest_foe_to_mouse.position)
	_play.add_animation_command(_light_attacker_animation_command.bind(ug_map_loc, target_map_loc))
	_ug.start_attack_animation()
	_play.add_animation_command(Callable(_play, "_kill_animation_command").bind(_ug, closest_foe_to_mouse, _ability))
	_play.await_command()


# Foe considerations
func does_support_artificial_opponent() -> bool:
	return true


func get_priority() -> int:
	return 100


func _light_attacker_animation_command(ac: AnimationCommand, attacker: Vector2i, defender: Vector2i) -> void:
	var tween: Tween = _ug.create_tween()
	var locations: Array[Vector2i] = [attacker, defender]
	tween.tween_callback(Callable(_play, "_update_fog_of_war").bind(locations))
	var facing: Vector2i = defender - attacker
	if face_away_from_target:
		facing = facing * -1
	tween.tween_callback(Callable(_play, "_update_current_unit_facing").bind(facing))
	_play.queue_finish(ac, tween)


func try_invoke() -> bool:
	var target: UnitGraphic = null
	for frog: UnitGraphic in _get_all_targets():
		if target == null:
			target = frog
		elif frog._unit_stats.action_points == 1:
			# Target the king if available
			target = frog
	if target == null:
		return false
	var terrain_layer: TileMapLayer = _play.get_terrain_layer()
	var ug_map_loc: Vector2i = terrain_layer.local_to_map(_ug.position)
	var target_map_loc: Vector2i = terrain_layer.local_to_map(target.position)
	_play.reduce_action_points(_ability.ap_cost)
	_play.add_animation_command(_light_attacker_animation_command.bind(ug_map_loc, target_map_loc))
	_ug.start_attack_animation()
	_play.add_animation_command(Callable(_play, "_kill_animation_command").bind(_ug, target, _ability))
	_play.await_command()
	return true
