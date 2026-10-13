class_name Ability extends Resource

enum AbilityTarget { UNDEFINED, SELF, ALLY, FOE }
enum AbilityMechanism { UNDEFINED, DAMAGE, PULL, WALK, HOP, FLY, ILLUMINATE, DIE_IN_LIGHT, STUN_IN_LIGHT }

@export var ability_name: String
@export var ap_cost: int = 1
@export var ability_description: String
@export var activation_sound: AudioStream
@export var target: AbilityTarget = AbilityTarget.FOE
@export var ability_range: int = 1
@export var mechanism: AbilityMechanism = AbilityMechanism.UNDEFINED
@export var always_on: bool = false
@export var angle: float = -1
