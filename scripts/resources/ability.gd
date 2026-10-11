class_name Ability extends Resource

enum AbilityTarget { UNDEFINED, SELF, ALLY, FOE }
enum AbilityMechanism { UNDEFINED, DAMAGE, PULL, WALK, HOP, FLY, LANTERN }

@export var ability_name: String
@export var ap_cost: int = 1
@export var ability_description: String
@export var target: AbilityTarget = AbilityTarget.FOE
@export var range: int = 1
@export var mechanism: AbilityMechanism = AbilityMechanism.UNDEFINED
@export var always_on: bool = false
@export var angle: float = -1
