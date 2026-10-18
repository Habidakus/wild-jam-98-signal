extends StateMachineState


func _on_button_play_button_up() -> void:
	our_state_machine.switch_state("SMS_Prologue_1")


func _on_button_credits_button_up() -> void:
	our_state_machine.switch_state("SMS_Credits")


func _on_button_quit_button_up() -> void:
	get_tree().quit()
