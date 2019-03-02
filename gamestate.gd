extends "res://networking/base.gd"

func end_game_ext():
	.end_game_ext()
	_unload_world()

func register_in_game_player_ext(id, player):
	pass

func start_game_ext():
	.start_game_ext()
	
	var world = load("res://game/pong.tscn").instance()
	_load_world(world)
	
func unregister_player_ext(id):
	.unregister_player_ext(id)
