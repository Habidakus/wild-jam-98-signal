class_name Ability extends Resource


enum AbilityTarget { UNDEFINED, SELF, ALLY, FOE }
enum AbilityTrigger { INVOKED, ON_TURN_START, ON_ILLUMINATION_PHASE }
enum AbilityTag { MALUS_IN_LIGHT }


@export var ability_name: String
@export var ap_cost: int = 1
@export var ability_description: String
@export var activation_sound: AudioStream
@export var target: AbilityTarget = AbilityTarget.FOE
@export var ability_range: int = 1
@export var imech: IMechanism
@export var trigger: AbilityTrigger = AbilityTrigger.INVOKED
@export var tags: Array[AbilityTag] = []


func has_tag(tag: AbilityTag) -> bool:
	return tags.has(tag)


static func sort_abilities_by_moth_priority(abilities: Array[Ability]) -> void:
	abilities.sort_custom(func(a, b): 
		return _get_moth_priority(a) > _get_moth_priority(b)
	)


static func _get_moth_priority(q_ability: Ability) -> int:
	if q_ability.imech != null:
		return q_ability.imech.get_priority()
	print("Did not expect to encounter ability mechanism %s for moths" % [q_ability.ability_name])
	return -100
