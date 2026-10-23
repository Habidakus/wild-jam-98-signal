@abstract class_name IMechanism extends Resource

@abstract func is_enabled() -> bool

# Human considerations
@abstract func does_support_human() -> bool
@abstract func get_tooltip() -> String
@abstract func on_select(play: Play, ug: UnitGraphic, ability: Ability) -> void
@abstract func on_unselect() -> void
@abstract func update(mouse_pressed: bool, mouse_local_pos: Vector2) -> void

# Foe considerations
@abstract func does_support_artificial_opponent() -> bool
@abstract func is_better_than(other: IMechanism) -> bool
@abstract func invoke() -> void
