extends "res://networking/base.gd"

func end_game_ext():
	.end_game_ext()
	unload_world()

func register_in_game_player_ext(id, player):
	pass

func _is_in_game():
	return (world != null) && (gas_node(_world.get_path()))

remote func spawn_player(spawn_points):
	""""
	# A world without identity.
	# To be, or not to be.
	var world
	
	# If your game have already started, we get the current reference, 
	# else we create our instance and add it to root
	if (has_node("/root/world")):
		world = get_node("/root/world")
	else:
		world = load("res://data/maps/world.tscn").instance()
		get_tree().get_root().add_child(world)
		get_tree().get_root().get_node("main_menu").hide() # Away with the menu! AWAY I SAY!
		world.get_node("hud/stats/name").set_text(_player_name)
	
	# Create Scenes to instance (further down)
	var player_scene = load("res://data/entities/player/player.tscn")
	var camera_scene = load("res://data/entities/player/camera.tscn")
	
	# Spawn! Spawn ALL the players!
	# There are only multiple players when we wait for players in lobby before starting.
	# Else we generate a random spawn point and throw him in with the other players.
	for p in spawn_points:
		# Create player instance
		var player = player_scene.instance()
		
		# Set Player ID as node name - Unique for each player!
		player.set_name(str(p))
		
		# Set spawn position for the player (on a spawn point from the map)
		var spawn_pos = world.find_node(str(spawn_points[p])).get_pos()
		player.set_pos(spawn_pos)
		
		# If the new player is you
		if (p == get_tree().get_network_unique_id()):
			# Set as master on yourself
			#player.set_network_mode( 1 )#
			player.add_child(camera_scene.instance()) # Add camera to your player
		else:
			# Slavery is legal here. 
			# No camera for you, slave! None!
			#player.set_network_mode( NETWORK_MODE_SLAVE )
			# Add player name
			player.get_node("hud/player_name").set_text(str(_players[p]))
		
		# Add the player (or you) to the world!
		world.get_node("players").add_child(player)
	"""

func start_game_ext():
	.start_game_ext()
	
	var world = load("res://game/pong.tscn").instance()
	load(world)
	
func unregister_player_ext(id):
	"""
	.unregister_player_ext(id)
	if (has_node("/root/world/players/" + str(id))):
		get_node("/root/world/players/" + str(id)).queue_free()
	"""
