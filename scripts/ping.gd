class_name Ping extends Control

func _ready() -> void:
	$AudioStreamPlayer2D.play()
	$AnimatedSprite2D.play()
	$AnimatedSprite2D.animation_looped.connect(_looped)

func _looped() -> void:
	$AnimatedSprite2D.stop()

func _process(_delta: float) -> void:
	if $AudioStreamPlayer2D.playing:
		return
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
