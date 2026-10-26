class_name Suicide extends IMechanism


@export var _triggered_in_light: bool = true


var _play: Play
var _ug: UnitGraphic
var _ability: Ability


func setup(play: Play, ug: UnitGraphic, ability: Ability) -> void:
	_play = play
	_ug = ug
	_ability = ability


func is_enabled() -> bool:
	if not _triggered_in_light:
		assert(false, "Only currently supported if triggered in light")
	var terrain_layer: TileMapLayer = _play.get_terrain_layer()
	return _play._is_map_loc_in_light(terrain_layer.local_to_map(_ug.position))


func does_support_human() -> bool:
	return false


func on_select() -> void:
	assert(false, "should never be invoked")


func on_unselect() -> void:
	assert(false, "should never be invoked")


func update(_mouse_pressed: bool, _mouse_local_pos: Vector2) -> void:
	assert(false, "should never be invoked")


# Foe considerations
func does_support_artificial_opponent() -> bool:
	return true


func get_priority() -> int:
	return 110


func try_invoke() -> bool:
	if not is_enabled():
		return false
	
	_play.reduce_action_points(-1)
	_play.add_animation_command(Callable(_play, "_kill_animation_command").bind(_ug, _ug, _ability))
	_play.await_command()

	return true
