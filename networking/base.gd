extends Node

# NETWORK DATA
# Port Tip: Check the web for available ports that is not preoccupied by other important services
# Port Tip #2: If you are the server; you may want to open it (NAT, Firewall)

var _accumulator = 0
var _fsm

const CHAT_TYPES = preload("res://chat/types.gd")

# GAMEDATA
var _game_name # Name of the game
var _players = {} # Dictionary containing player names and their ID
var _player
var _server_name
var _world

# SIGNALS to Main Menu (GUI)
signal chat_message()
signal connection_success()
signal connection_fail()
signal game_ended()
signal game_started()
signal refresh_lobby()
signal refresh_lobby_start_disabled()
signal refresh_lobby_start_enabled()
signal server_ended()
signal server_error()

func chat(message, type, args):
	if ((type == CHAT_TYPES.Whisper) && (typeof(args) == TYPE_INT)):
		var player_from = get_player_by_id(args)
		emit_signal("chat_message", Gamestate.get_player(), message, CHAT_TYPES.Whisper, { "player" : player_from, "id" : get_tree().get_network_unique_id() })
		rpc_id(args, "chat_send", get_tree().get_network_unique_id(), message, CHAT_TYPES.Whisper, null)
		return
	
	if (type == CHAT_TYPES.General):
		rpc("chat_send", get_tree().get_network_unique_id(), message, CHAT_TYPES.General, null)
		return
	
	if (type == CHAT_TYPES.PrePackaged):
		rpc("chat_send", get_tree().get_network_unique_id(), message, CHAT_TYPES.PrePackaged, inst2dict(args))
		return
	
	rpc("chat_send", get_tree().get_network_unique_id(), message, type, inst2dict(args))

sync func chat_send(from, message, type, args):
	var player_from = get_player_by_id(from)
	if (args != null):
		args = dict2inst(args)
	emit_signal("chat_message", player_from, message, CHAT_TYPES.General, args)

func end_game():
	end_game_ext()
	emit_signal("game_ended")

func end_game_announce(by_id):
	if (get_tree().is_network_server()):
		# Server sends out the announcement to each player that the game ended
		if (by_id == null):
			by_id = 1
		for peer_id in _players:
			rpc_id(peer_id, "end_game_announce_player", by_id)
		
		end_game()
	else:
		# Non-server player requests the server to end the game
		rpc_id(1, "end_game_announce_request", get_tree().get_network_unique_id())

remote func end_game_announce_player(by_id):
	# Call end_game on the non-server player
	end_game()
	
# TODO: probably need to flag that the game has ended, so if someone trips 
# it simulateously we only take the first user's input
# player requesting game has ended
remote func end_game_announce_request(by_id):
	if (!get_tree().is_network_server()):
		return
	
	# server to send out announcement that the game has ended
	end_game_announce(by_id)

func end_game_ext():
	pass

func get_player_list():
	return _players.values()

func get_player():
	return _player

func get_player_id():
	return get_tree().get_network_unique_id()

func get_player_by_id(id):
	if (id == get_tree().get_network_unique_id()):
		return _player
	
	if (_players.has(id)):
		return _players[id]
	
	return null
	
func get_player_by_selector(selector):
	if ((selector == null) || (selector == "")):
		return null
	
	var player_id = ""
	var playerT = null
	for peer_id in _players:
		player_id = peer_id
		playerT  = get_player_by_id(peer_id)
		# TODO
		if ((playerT != null) && (playerT.name.to_lower() == selector.to_lower())):
			break
	
	if (playerT != null):
		return { "player" : playerT, "id": player_id }
		
	return null

func host_game(name, port):
	if (validate_port(port, null) == null):
		return false
		
	if (name == ""):
		name = Constants.DEFAULT_SERVER_NAME
	
	_server_name = name
	_player = preload("res://networking/player.gd").new()
	_player.name = ConfigurationUser.Settings.User.Name
	_player.ready = false
	
	# Initializing the network as client
	var host = _create_host()
#	var doh = get_tree().get_multiplayer()
	host.create_server(port, Constants.MAX_PLAYERS)
	get_tree().set_network_peer(host)
	
	return true

func join_game(ip_address, port):
	if (validate_address(ip_address, null) == null):
		return false
	if (validate_port(port, null) == null):
		return false
	
	_player = preload("res://networking/player.gd").new()
	_player.name = ConfigurationUser.Settings.User.Name
	_player.ready = false
	
	# Initializing the network as server
	var host = _create_host()
	host.create_client(ip_address, port)
	get_tree().set_network_peer(host)
	
	return true

func load_world(world):
	if (world == null):
		return
	
	_world = world
	get_tree().get_root().add_child(_world)
	_world.connect("game_ended", self, "_on_game_ended")
	
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
		var playerT = get_player_by_id(id)
		if (playerT != null):
			playerT.ready = player.ready

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
		
		var playerT
		# Send the new player info about the other players
		for peer_id in _players:
			playerT  = get_player_by_id(peer_id)
			if (playerT != null):
				rpc_id(id, "register_in_game_player", peer_id, inst2dict(playerT))
	
	temp = dict2inst(player)
	_set_player(id, player)
	
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
		
		var playerT
		# For each player, send the new guy info of all players (from server)
		for peer_id in _players:
			playerT = get_by_player_id(peer_id)
			if (playerT != null):
				rpc_id(id, "register_in_lobby_player", peer_id, inst2dict(playerT)) # Send the new player info about others
			rpc_id(peer_id, "register_in_lobby_player", player) # Send others info about the new player
	
	temp = dict2inst(player)
	_set_player(id, temp)

	# Notify lobby (GUI) about changes
	emit_signal("refresh_lobby")

func start_game():
	if (!get_tree().is_network_server()):
		return
		
	rpc("start_game_player", 1)
	
	start_game_ext()
	emit_signal("game_started")

func start_game_ext():
	pass

remote func start_game_player(id):
	if (get_tree().is_network_server()):
		for peer_id in _players:
			rpc_id(peer_id, "start_game_player")
	
	start_game_ext()
	emit_signal("game_started")

func unload_world():
	if (_world == null):
		return
	
	get_node(_world.get_path()).queue_free()

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
	
	var playerT
	for peer_id in _players:
		playerT = get_player_by_id(peer_id)
		if (playerT != null):
			ready = ready && playerT.ready
			if (playerT.ready):
				count += 1
	
	if ((count >= Constants.MIN_PLAYERS) && ready):
		emit_signal("refresh_lobby_start_enabled")
	else:
		emit_signal("refresh_lobby_start_disabled")

func _set_player(id, player):
	_players[id] = player;
	
#### Events

# Could not connect to server (client)
func _on_connection_failed():
	get_tree().set_network_peer(null)
	emit_signal("connection_fail")

func _on_game_ended():
	end_game_announce(get_tree().get_network_unique_id())

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
	if (!Constants.PING_ENABLED):
		return
	
	if (Constants.PING_DELAY <= 0):
		return
	
	if (!get_tree().has_network_peer()):
		return
	
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
	
