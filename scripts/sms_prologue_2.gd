extends StateMachineState_PressAnyKey

var _level: PackedScene = preload("res://maps/levels/3_elitebattle.tscn")
var _heroes: Array[Unit] = [
	preload("res://data/units/kingfrog.tres"),
	preload("res://data/units/explorefrog.tres"),
	preload("res://data/units/speedfrog.tres"),
	preload("res://data/units/unicornfrog.tres"),
]

func exit_state(ns: StateMachineState) -> void:
	if ns is Play:
		var play: Play = ns as Play
		play.set_level(_level.instantiate())
		play.set_heroes(_heroes)
		play.set_victory("SMS_Victory")
	else:
		assert(false, "Why is next state not SMS_Play?")
	super.exit_state(ns)
