extends Node

# NETWORK DATA
# Port Tip: Check the web for available ports that is not preoccupied by other important services
# Port Tip #2: If you are the server; you may want to open it (NAT, Firewall)

var _fsm

# GAMEDATA
var _game_name # Name of the game
var _players = {} # Dictionary containing player names and their ID
var _player_name # Your own player name
var _server_name # Server name

# SIGNALS to Main Menu (GUI)
signal connection_success()
signal connection_fail()
signal refresh_lobby()
signal server_ended()
signal server_error()

func end_game():
	pass

# Returns a list of players (lobby)
func get_player_list():
	return _players.values()

# Returns your name
func get_player_name():
	return _player_name

func host_game(name, port):
	if (validate_port(port) == null):
		return false
		
	if (name == ""):
		name = Constants.DEFAULT_SERVER_NAME
	
	# Store own player name
	_server_name = name
	_player_name = configuration_user.name
	
	# Initializing the network as client
	var host = _create_host()
	host.create_server(port, Constants.MAX_PLAYERS) # Max 6 players can be connected
	get_tree().set_network_peer(host)
	
	return true

func join_game(ip_address, port):
	if (validate_address(ip_address) == null):
		return false
	if (validate_port(port) == null):
		return false
	
	# Store own player name
	_player_name = configuration_user.name
	
	# Initializing the network as server
	var host = _create_host()
	host.create_client(ip_address, port)
	get_tree().set_network_peer(host)
	
	return true

# Register yourself directly ingame
remote func register_in_game():
	if (!_is_in_game() || !_can_join_in_game()):
		return
	
	rpc("register_new_player", get_tree().get_network_unique_id(), _player_name)
	register_new_player(get_tree().get_network_unique_id(), _player_name)

# Register myself with other players at lobby
remote func register_at_lobby():
	if (_is_in_game()):
		return
		
	rpc("register_player", get_tree().get_network_unique_id(), _player_name)
	emit_signal("connection_success") # Sends command to gui & will send player to lobby

# Register the player and jump ingame
remote func register_new_player(id, name):
	# This runs only once from server
	if (get_tree().is_network_server()):
		# Send info about server to new player
		rpc_id(id, "register_new_player", 1, _player_name) 
		
		# Send the new player info about the other players
		for peer_id in _players:
			rpc_id(id, "register_new_player", peer_id, _players[peer_id]) 
	
	# Add new player to your player list
	_players[id] = name
	
	register_new_player_ext(id, name)

# Register player the ol' fashioned way and refresh lobby
remote func register_player(id, name):
	# If I am the server (not run on clients)
	if (get_tree().is_network_server()):
		rpc_id(id, "register_player", 1, _player_name) # Send info about server to new player
		
		# For each player, send the new guy info of all players (from server)
		for peer_id in _players:
			rpc_id(id, "register_player", peer_id, _players[peer_id]) # Send the new player info about others
			rpc_id(peer_id, "register_player", id, name) # Send others info about the new player
	
	_players[id] = name # update player list

	# Notify lobby (GUI) about changes
	emit_signal("refresh_lobby")
	
func remove_player(id):
	pass

func start_game():
	pass

# Quits the game, will automatically tell the server you disconnected; neat.
func quit_game():
	end_game()
	_close_connection()
	_players.clear()

# Unregister a player, whether he is in lobby or ingame
remote func unregister_player(id):
	# If the game is running
	if (_is_in_game()):
		# Remove player from game
		remove_player(id)
		_players.erase(id)
	
	# Remove from lobby
	_players.erase(id)
	emit_signal("refresh_lobby")

# Server receives this from players that have just connected
remote func user_ready(id, _player_name):
	# Only the server can run this!
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
		rpc_id(id, "register_at_lobby")
	
func validate_address(address, error):
	if (not address.is_valid_ip_address()):
		if (error != null):
			error.set_text(tr("LOBBY_MESSAGE_ADDRESS_INVALID"))
		return null
		
	return address
	
func validate_port(port, error):
	if (not port.is_valid_integer()):
		if (error != null):
			error.set_text(tr("LOBBY_MESSAGE_PORT_INVALID"))
		return null
		
	var portN = port.to_int();
	if (portN < 1024 || portN > 65535):
		if (error != null):
			error.set_text(tr("LOBBY_MESSAGE_PORT_INVALID_RANGE"))
		return null
		
	return portN

# Could not connect to server (client)
func _connection_failed():
	get_tree().set_network_peer(null)
	emit_signal("connection_fail")

# Client connected with you (can be both server or client)
func _network_peer_connected(id):
	pass

# Client disconnected from you
func _network_peer_disconnected(id):
	# If I am server, send a signal to inform that an player disconnected
	if (!get_tree().is_network_server()):
		return
	
	unregister_player(id)
	rpc("unregister_player", id)

# Successfully connected to server (client)
func _connected_to_server():
	# Send signal to server that we are ready to be assigned;
	# Either to lobby or ingame
	rpc_id(1, "user_ready", get_tree().get_network_unique_id(), _player_name)

# Server disconnected (client)
func _server_disconnected():
	quit_game()
	emit_signal("server_ended")

func _can_join_in_game():
	return true
	
func _close_connetion():
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

func _ready():
	# Networking signals (high level networking)
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

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
	
