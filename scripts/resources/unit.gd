class_name Unit extends Resource

enum UnitSide { UNDEFINED, FROG, MOTH }

@export var unit_name: String
@export var texture: Texture2D
@export var sprite_frames: SpriteFrames
@export var unit_description: String
@export var action_points: int = 1
@export var unit_side: UnitSide = UnitSide.UNDEFINED
@export var hit_points: int = 1
@export var abilities: Array[Ability] = []
