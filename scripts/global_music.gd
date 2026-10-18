class_name Music extends Node

static var _music_player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
static var _base_db: float = -10.0
static var _min_db: float = -40.0

func _ready() -> void:
	var stream: AudioStream = load("res://sounds/music/caffeine_creek_band-i-caint-keep-still-832.mp3")
	_music_player.stream = stream
	#_base_db = _music_player.volume_db
	_music_player.volume_db = _min_db
	get_tree().current_scene.add_child(_music_player)
	_music_player.play()
	fade_in()


static func fade_in() -> void:
	var tween: Tween = _music_player.create_tween()
	tween.tween_property(_music_player, "volume_db", _base_db, 1.5).set_ease(Tween.EASE_OUT)


static func fade_out() -> void:
	var tween: Tween = _music_player.create_tween()
	tween.tween_property(_music_player, "volume_db", _min_db, 2.5).set_ease(Tween.EASE_OUT)
