extends Node

# NETWORK DATA
# Port Tip: Check the web for available ports that is not preoccupied by other important services
# Port Tip #2: If you are the server; you may want to open it (NAT, Firewall)

var _accumulator = 0
var _fsm

# GAMEDATA
var _game_name # Name of the game
var _players = {} # Dictionary containing player names and their ID
var _player
var _server_name
var _world

# SIGNALS to Main Menu (GUI)
signal connection_success()
signal connection_fail()
signal game_ended()
signal game_started()
signal refresh_lobby()
signal refresh_lobby_start_disabled()
signal refresh_lobby_start_enabled()
signal server_ended()
signal server_error()

func end_game():
	end_game_ext()
	emit_signal("game_ended")
	
remote func end_game_announce(id):
	if (!get_tree().is_network_server()):
		return
	
	rpc_id(id, "end_game_announce_player", 1)
	
	for peer_id in _players:
		rpc_id(peer_id, "end_game_announce_player")

remote func end_game_announce_player():
	end_game()

func load_world(world):
	_world = world
	get_tree().get_root().add_child(_world)
	_world.connect("game_ended", self, "_on_game_ended")

func unload_world():
	get_node(_world.get_path()).queue_free()

func end_game_ext():
	pass

func get_player_list():
	return _players.values()

func get_player():
	return _player

func host_game(name, port):
	if (validate_port(port, null) == null):
		return false
		
	if (name == ""):
		name = Constants.DEFAULT_SERVER_NAME
	
	_server_name = name
	_player = preload("res://networking/player.gd").new()
	_player.name = configuration_user.Settings.User.Name
	_player.ready = false
	
	# Initializing the network as client
	var host = _create_host()
	host.create_server(port, Constants.MAX_PLAYERS)
	get_tree().set_network_peer(host)
	
	return true

func join_game(ip_address, port):
	if (validate_address(ip_address, null) == null):
		return false
	if (validate_port(port, null) == null):
		return false
	
	_player = preload("res://networking/player.gd").new()
	_player.name = configuration_user.Settings.User.Name
	_player.ready = false
	
	# Initializing the network as server
	var host = _create_host()
	host.create_client(ip_address, port)
	get_tree().set_network_peer(host)
	
	return true
	
remote func ping(delta):
	#print("ping " + str(delta))
	pass

# Quits the game, will automatically tell the server you disconnected; neat.
func quit_game():
	end_game()
	_close_connection()
	_players.clear()
	emit_signal("server_ended")
	
func ready_player_request(ready):
	_player.ready = ready
	rpc("ready_player", get_tree().get_network_unique_id(), inst2dict(_player))

# Call it locally as well as calling it remotely
sync func ready_player(id, player):
	var temp = dict2inst(player)
	if (_players.has(id)):
		_players[id].ready = player.ready

	# Notify lobby (GUI) about changes
	emit_signal("refresh_lobby")
	
	if (get_tree().is_network_server()):
		_ready_players()

# Register yourself directly ingame
remote func register_in_game():
	if (!_is_in_game() || !_can_join_in_game()):
		return
	
	rpc("register_in_game_player", get_tree().get_network_unique_id(), inst2dict(_player))
	
	emit_signal("connection_success") # Sends command to gui

# Register the player and jump ingame
remote func register_in_game_player(id, player):
	var temp = inst2dict(_player)
	
	if (get_tree().is_network_server()):
		# Send info about server to new player
		rpc_id(id, "register_in_game_player", 1, temp)
		
		# Send the new player info about the other players
		for peer_id in _players:
			rpc_id(id, "register_in_game_player", peer_id, inst2dict(_players[peer_id]))
	
	temp = dict2inst(player)
	_players[id] = player
	
	register_in_game_player_ext(id, player)
	
func register_in_game_player_ext(id, player):
	pass

# Register myself with other players at lobby
remote func register_in_lobby():
	if (_is_in_game()):
		return
		
	rpc("register_in_lobby_player", get_tree().get_network_unique_id(), inst2dict(_player))
	
	emit_signal("connection_success") # Sends command to gui 

remote func register_in_lobby_player(id, player):
	var temp = inst2dict(_player)
	
	if (get_tree().is_network_server()):
		rpc_id(id, "register_in_lobby_player", 1, temp) # Send info about server to new player
		
		# For each player, send the new guy info of all players (from server)
		for peer_id in _players:
			rpc_id(id, "register_in_lobby_player", peer_id, inst2dict(_players[peer_id])) # Send the new player info about others
			rpc_id(peer_id, "register_in_lobby_player", player) # Send others info about the new player
	
	temp = dict2inst(player)
	_players[id] = temp

	# Notify lobby (GUI) about changes
	emit_signal("refresh_lobby")

# Unregister a player, whether he is in lobby or ingame
remote func unregister_player(id):
	if (_is_in_game()):
		# Remove player from game
		unregister_player_ext(id)
		_players.erase(id)
	
	# Remove from lobby
	_players.erase(id)
	emit_signal("refresh_lobby")
	
func unregister_player_ext(id):
	pass

func start_game():
	start_game_ext()
	emit_signal("game_started")
	pass

func start_game_ext():
	pass

# Server receives this from players that have just connected
remote func user_connected(id):
	if (!get_tree().is_network_server()):
		return

	# If we are ingame, add player to session, else send to lobby	
	if (_is_in_game()):
		if (_can_join_in_game()):
			rpc_id(id, "register_in_game")
		else:
			# TODO: Need to handle this
			print('fail')
	else:
		rpc_id(id, "register_in_lobby")

func validate_address(address, error):
	if (error != null):
		error.set_text("")
	
	if (not address.is_valid_ip_address()):
		if (error != null):
			error.set_text(tr("LOBBY_MESSAGE_ADDRESS_INVALID"))
		return null
	
	return address

func validate_port(port, error):
	if (error != null):
		error.set_text("")
	
	var portN
	if (typeof(port) != TYPE_INT):
		if (typeof(port) == TYPE_STRING):
			if (not port.is_valid_integer()):
				if (error != null):
					error.set_text(tr("LOBBY_MESSAGE_PORT_INVALID"))
				return null
			else:
				portN = port.to_int();
		else:
			if (error != null):
				error.set_text(tr("LOBBY_MESSAGE_PORT_INVALID"))
			return null
	else:
		portN = port
		
	if (portN < 1024 || portN > 65535):
		if (error != null):
			error.set_text(tr("LOBBY_MESSAGE_PORT_INVALID_RANGE"))
		return null
		
	return portN

func _can_join_in_game():
	return true
	
func _close_connection():
	if (get_tree().is_network_server()):
		var host = get_tree().get_meta("network_peer")
		if (host != null):
			host.close_connection() 
	get_tree().set_network_peer(null)

func _create_host():
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	get_tree().set_meta("network_peer", host)
	return host
		
func _is_in_game():
	return false
	
func _ready_players():
	var ready = _player.ready
	var count = 0
	if (_player.ready):
		count += 1
	for peer_id in _players:
		ready = ready && _players[peer_id].ready
		if (_players[peer_id].ready):
			count += 1
	
	if ((count >= Constants.MIN_PLAYERS) && ready):
		emit_signal("refresh_lobby_start_enabled")
	else:
		emit_signal("refresh_lobby_start_disabled")
		
#### Events

# Could not connect to server (client)
func _on_connection_failed():
	get_tree().set_network_peer(null)
	emit_signal("connection_fail")

func _on_game_ended():
	rpc_id(1, "end_game_announce", get_tree().get_network_unique_id())

# Client connected with you (can be both server or client)
func _on_network_peer_connected(id):
	pass

# Client disconnected from you
func _on_network_peer_disconnected(id):
	# If I am server, send a signal to inform that an player disconnected
	if (!get_tree().is_network_server()):
		return
	
	unregister_player(id)
	rpc("unregister_player", id)

# Successfully connected to server (client)
func _on_connected_to_server():
	# Record the player's id.
	_player.id = get_tree().get_network_unique_id()
	# Send signal to server that we are ready to be assigned;
	rpc_id(1, "user_connected", get_tree().get_network_unique_id())

# Server disconnected (client)
func _on_server_disconnected():
	quit_game()

func _ready():
	# Networking signals (high level networking)
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _process(delta):
	if (Constants.PING_ENABLED):
		_accumulator += delta
		if (_accumulator > Constants.PING_DELAY):
			rpc_unreliable("ping", _accumulator)
			_accumulator = 0

class state extends "res://fsm/menu_fsm.gd":
	const Complete = "complete"
	const Empty = "empty"
	
	func init():
		.init()
		add_state(Complete)
		add_state(Empty)
		
	func is_state_complete():
		return is_state(Complete)
		
	func is_state_empty():
		return is_state(Empty)
	
	func set_state_complete():
		set_state(Complete)
		
	func set_state_empty():
		set_state(Empty)
	
