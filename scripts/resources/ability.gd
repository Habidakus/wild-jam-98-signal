class_name Ability extends Resource

enum AbilityTarget { UNDEFINED, SELF, ALLY, FOE }
enum AbilityMechanism { 
	UNDEFINED,
	DAMAGE,			# 0
	PULL,			# 1
	WALK,			# 3 - converted
	HOP,			# 1
	FLY,			# 1 - converted
	ILLUMINATE,		# 2
	DIE_IN_LIGHT,	# 1
	STUN_IN_LIGHT,	# 1
	RIBBIT_RADAR,	# 1 - converted
	CHARGE,			# 2 - converted
	CHARGE_WITH_FLY,# 1 - converted
}

@export var ability_name: String
@export var ap_cost: int = 1
@export var ability_description: String
@export var activation_sound: AudioStream
@export var target: AbilityTarget = AbilityTarget.FOE
@export var ability_range: int = 1
@export var mechanism: AbilityMechanism = AbilityMechanism.UNDEFINED
@export var imech: IMechanism
@export var always_on: bool = false
@export var angle: float = -1


static func sort_abilities_by_moth_priority(abilities: Array[Ability]) -> void:
	abilities.sort_custom(func(a, b): 
		return _get_moth_priority(a) > _get_moth_priority(b)
	)


static func _get_moth_priority(q_ability: Ability) -> int:
	if q_ability.imech != null:
		return q_ability.imech.get_priority()
	match q_ability.mechanism:
		AbilityMechanism.DAMAGE:
			return 100
		AbilityMechanism.CHARGE_WITH_FLY:
			return 95
		AbilityMechanism.CHARGE:
			return 90
		AbilityMechanism.PULL:
			return 80
		AbilityMechanism.FLY:
			return 70
		AbilityMechanism.WALK:
			return 60
		AbilityMechanism.HOP:
			return 50
		AbilityMechanism.RIBBIT_RADAR:
			return 0
		AbilityMechanism.ILLUMINATE:
			return -1
		AbilityMechanism.STUN_IN_LIGHT:
			return -2
		AbilityMechanism.DIE_IN_LIGHT:
			return -3
	print("Did not expect to encounter ability mechanism %s for moths" % [AbilityMechanism.keys()[q_ability.mechanism]])
	return -100
