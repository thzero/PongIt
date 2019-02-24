extends "res://networking/base.gd"

func end_game_ext():
	.end_game_ext()
	unload_world()

func register_in_game_player_ext(id, player):
	pass

func _is_in_game():
	return (_world != null) && (has_node(_world.get_path()))

func start_game_ext():
	.start_game_ext()
	
	var world = load("res://game/pong.tscn").instance()
	load_world(world)
	
func unregister_player_ext(id):
	.unregister_player_ext(id)
