extends "res://networking/base.gd"

func end_game():
	.end_game()

# Register the player and jump ingame
func register_new_player_ext(id, name):
	pass

func start_game():
	.start_game()

func _is_in_game():
	return false