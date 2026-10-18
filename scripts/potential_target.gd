class_name PotentialTarget extends Sprite2D


var _time_to_live: float = 1.0


func _process(delta: float) -> void:
	if _time_to_live > 0:
		_time_to_live -= delta
		if _time_to_live <= 0:
			var tween: Tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.2)
			tween.tween_callback(queue_free)
