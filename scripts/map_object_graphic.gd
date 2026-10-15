class_name MapObjectGraphic extends Node2D


enum MapObsticleType { UNDEFINED, COMPLETE_BLOCKER, HALF_HEIGHT, SEE_THROUGH_BLOCKER }


@export var _obsticle_type: MapObsticleType = MapObsticleType.UNDEFINED
@export var _possible_textures: Array[Texture2D]


func _ready() -> void:
	if _possible_textures.is_empty():
		return
	if _possible_textures.size() == 1:
		%Sprite.texture = _possible_textures[0]
	else:
		%Sprite.texture = _possible_textures[randi() % _possible_textures.size()]
	%Sprite.flip_h = randi() % 2 == 1


func blocks_hop() -> bool:
	return _obsticle_type == MapObsticleType.COMPLETE_BLOCKER or _obsticle_type == MapObsticleType.SEE_THROUGH_BLOCKER


func blocks_fly() -> bool:
	return _obsticle_type == MapObsticleType.COMPLETE_BLOCKER or _obsticle_type == MapObsticleType.SEE_THROUGH_BLOCKER


func blocks_walk() -> bool:
	return true
