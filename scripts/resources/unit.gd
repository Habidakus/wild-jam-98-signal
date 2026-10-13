class_name Unit extends Resource

enum UnitSide { UNDEFINED, FROG, MOTH }

@export var unit_name: String
@export var texture: Texture2D
@export var sprite_frames: SpriteFrames
@export var unit_description: String
@export var action_points: int = 1
@export var unit_side: UnitSide = UnitSide.UNDEFINED
@export var lose_ap_in_light: bool = false
## If -1 then no damage will ever be taken from light exposure, otherwise when the number of lights shining on the unit equals or exceeds [b]light_damage_threshold[/b] the unit will take damage.
@export var light_damage_threshold: int = -1
@export var hit_points: int = 1
@export var abilities: Array[Ability] = []
