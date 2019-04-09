extends Node

# NETWORK DATA
# Port Tip: Check the web for available ports that is not preoccupied by other important services
# Port Tip #2: If you are the server; you may want to open it (NAT, Firewall)

var _fsm
var _handler_chat
var _handler_monitor
var _handler_player_selector
var _handler_print = preload("res://utility/print.gd").new()
var _handler_validator

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
	if (_handler_chat == null):
		return
	
	_handler_chat.message(get_tree().get_network_unique_id(), message, type, args)
	
func chat_message_emit(player_from, message, type, args):
	emit_signal("chat_message", player_from, message, type, args)
	
func chat_message_send(id, message, type, args, id_to):
	if (args != null):
		args = inst2dict(args)
	
	if (id_to != null):
		rpc_id(id_to, "chat_send", id, message, type, args)
		return
	
	rpc("chat_send", id, message, type, args)

sync func chat_send(from, message, type, args):
	var player_from = get_player_by_id(from)
	args = null if args == null else dict2inst(args)
	
	_print("chat_message", { "chat_type": type, "player": player_from, "message": message } )
	chat_message_emit(player_from, message, type, args)
	
func chat_types():
	if (_handler_chat == null):
		return null
	
	return _handler_chat.CHAT_TYPES

func end_game():
	_print("end_game", null)
	_ready_players_reset()
	end_game_ext()
	emit_signal("game_ended")

func end_game_announce(by_id):
	_print("end_game_announce", { "by_id": by_id })
	if (get_tree().is_network_server()):
		_print("end_game_announce_server", { "by_id": by_id })
		
		# Server sends out the announcement to each player that the game ended
		by_id = 1 if by_id == null else by_id
		for peer_id in _players:
			_print("end_game_announce_player_server_call_client", { "peer_id": peer_id, "by_id": by_id })
			rpc_id(peer_id, "end_game_announce_player", by_id)
		
		end_game()
		return
	
	_print("end_game_announce_request", null)
	# Non-server player requests the server to end the game
	rpc_id(1, "end_game_announce_request", get_tree().get_network_unique_id())

remote func end_game_announce_player(by_id):
	_print("end_game_announce_player", { "by_id": by_id })
	# Call end_game on the non-server player
	end_game()
	
# TODO: probably need to flag that the game has ended, so if someone trips 
# it simulateously we only take the first user's input
# player requesting game has ended
remote func end_game_announce_request(by_id):
	_print("end_game_announce_request", { "by_id": by_id })
	if (!get_tree().is_network_server()):
		return
	
	# server to send out announcement that the game has ended
	_print("end_game_announce_request_server", { "by_id": by_id })
	end_game_announce(by_id)

func end_game_ext():
	pass

func get_player_list(values):
	if (values):
		return _players.values()
		
	return _players

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
	if (_handler_player_selector == null):
		return null
	
	return _handler_player_selector.get_player(selector)

func host_game(name, port, address):
	if (_handler_validator.validate_port(port, null) == null):
		return false
	
	name = Constants.DEFAULT_SERVER_NAME if name == "" else name
	
	_server_name = name
	_player = preload("res://networking/player.gd").new()
	_player.name = ConfigurationUser.Settings.User.Name
	_player.ready = false
	
	_print("host_game", null)
	
	# Initializing the network as client
	var host = _create_host()
	
	if (address != null):
		host.set_bind_ip(address)
	
	var err = host.create_server(port, Constants.MAX_PLAYERS)
	if (err != OK):
		_print("Can't host, address in use.", null)
		return false
	
	get_tree().set_network_peer(host)
	
	return true

func join_game(ip_address, port):
	if (_handler_validator.validate_address(ip_address, null) == null):
		return false
	
	if (_handler_validator.validate_port(port, null) == null):
		return false
	
	_player = preload("res://networking/player.gd").new()
	_player.name = ConfigurationUser.Settings.User.Name
	_player.ready = false
	
	_print("join_game", null)
	
	# Initializing the network as server
	var host = _create_host()
	var err = host.create_client(ip_address, port)
	if (err != OK):
		_print("Can't join, address not available.", null)
		return false
	get_tree().set_network_peer(host)
	
	return true

# Quits the game, will automatically tell the server you disconnected; neat.
func quit_game():
	_print("quit_game", null)
	end_game_ext()
	_close_connection()
	_players.clear()

# Call it locally as well as calling it remotely
sync func ready_player(id, player):
	var temp = dict2inst(player)
	if (_players.has(id)):
		var playerT = get_player_by_id(id)
		if (playerT != null):
			playerT.ready = player.ready
	
	emit_signal("refresh_lobby")
	
	if (get_tree().is_network_server()):
		_ready_players_check()

func ready_player_request(ready):
	_player.ready = ready
	_print("ready_player", { "ready": ready })
	rpc("ready_player", get_tree().get_network_unique_id(), inst2dict(_player))

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
			if (playerT == null):
				continue
			
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
			playerT = get_player_by_id(peer_id)
			if (playerT == null):
				continue
			
			rpc_id(id, "register_in_lobby_player", peer_id, inst2dict(playerT)) # Send the new player info about others
			rpc_id(peer_id, "register_in_lobby_player", player) # Send others info about the new player
	
	temp = dict2inst(player)
	_set_player(id, temp)

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

func validator():
	return _handler_validator

func _can_join_in_game():
	return true

func _clear_network_peer():
	get_tree().set_meta("network_peer", null)
	get_tree().set_network_peer(null)

func _close_connection():
	if (get_tree().is_network_server()):
		var host = _get_network_peer()
		if (host != null):
			host.close_connection()
	
	_clear_network_peer()
#	get_tree().set_network_peer(null)

func _create_host():
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	_set_network_peer(host)
	return host

func _get_network_peer():
	var peer = get_tree().get_meta("network_peer")
	return peer

func _get_world():
	return _world

func _has_world():
	return (_get_world() != null) && (has_node(_world.get_path()))

func _initialize_chat():
	return load(Constants.PATH_GAMESTATE_CHAT).new()

func _initialize_monitor():
	return load(Constants.PATH_GAMESTATE_MONITOR).new()

func _initialize_player_selector():
	return load(Constants.PATH_GAMESTATE_PLAYER_SELECTOR).new()

func _initialize_validator():
	return load(Constants.PATH_GAMESTATE_VALIDATOR).new()

func _is_in_game():
	return _has_world()

func _load_world(world):
	if (world == null):
		return
	
	_world = world
	get_tree().get_root().add_child(_world)
	_world.connect("game_ended", self, "_on_game_ended")

func _print(method, args):
	if (_handler_print == null):
		return
	
	if (args == null):
		args = {}
		
	if (_get_network_peer() == null):
		return
	
	args["id"] = str(get_tree().get_network_unique_id())
	args["server"] = str(get_tree().is_network_server())
	
	_handler_print.output(method, args)

func _ready_players_check():
	_print("_ready_players_check", null)
	
	var ready = _player.ready
	var count = 0
	if (_player.ready):
		count += 1
	
	var playerT
	for peer_id in _players:
		playerT = get_player_by_id(peer_id)
		if (playerT == null):
			continue
		
		ready = ready && playerT.ready
		if (playerT.ready):
			count += 1
	
	if ((count >= Constants.MIN_PLAYERS) && ready):
		emit_signal("refresh_lobby_start_enabled")
	else:
		emit_signal("refresh_lobby_start_disabled")

func _ready_players_reset():
	_print("_ready_players_reset", null)
	
	if (_player == null):
		return
	
	if (get_tree().is_network_server()):
		_print("_ready_players_reset_server", null)
		
		# Send server resets
		rpc("ready_player", get_tree().get_network_unique_id(), inst2dict(_player))
		
		# Send client resets
		var playerT
		for peer_id in _players:
			playerT  = get_player_by_id(peer_id)
			if (playerT == null):
				continue
			
			playerT.ready = false
			rpc("ready_player", peer_id, inst2dict(playerT))

func _set_network_peer(host):
	get_tree().set_meta("network_peer", host)

func _set_player(id, player):
	_players[id] = player;

func _unload_world():
	if (_world == null):
		return
	
	_world.hide()
	_world.disconnect("game_ended", self, "_on_game_ended")
	get_node(_world.get_path()).queue_free()
	_world = null

#### Events

# Could not connect to server (client)
func _on_connection_failed():
	_print("_on_connection_failed", null)
#	get_tree().set_network_peer(null)
	_clear_network_peer()
	emit_signal("connection_fail")

func _on_game_ended():
	_print("_on_game_ended", null)
	end_game_announce(get_tree().get_network_unique_id())

# Client connected with you (can be both server or client)
func _on_network_peer_connected(id):
	_print("_on_network_peer_connected", null)
	pass

# Client disconnected from you
func _on_network_peer_disconnected(id):
	_print("_on_network_peer_disconnected", null)
	# If I am server, send a signal to inform that an player disconnected
	if (!get_tree().is_network_server()):
		return
	
	unregister_player(id)
	rpc("unregister_player", id)

# Successfully connected to server (client)
func _on_connected_to_server():
	_print("_on_connected_to_server", null)
	# Record the player's id.
	_player.id = get_tree().get_network_unique_id()
	# Send signal to server that we are ready to be assigned;
	rpc_id(1, "user_connected", get_tree().get_network_unique_id())

# Server disconnected (client)
func _on_server_disconnected():
	_print("_on_server_disconnected", null)
	quit_game()	
	emit_signal("server_ended")

func _ready():
	_handler_chat = _initialize_chat()
	_handler_chat.initialize(self)
	_handler_player_selector = _initialize_player_selector()
	_handler_player_selector.initialize(self)
	_handler_validator = _initialize_validator()
	_handler_validator.initialize(self)
	
	_handler_monitor = _initialize_monitor()
	_handler_monitor.initialize(self)
	add_child(_handler_monitor)
	
	# Networking signals (high level networking)
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_network_peer_disconnected")
	get_tree().connect("server_disconnected", self, "_on_server_disconnected")

func _process(delta):
	_handler_monitor.process(delta)

class state extends "res://fsm/menu_fsm.gd":
	const Complete = "complete"
	const Empty = "empty"
		
	func is_state_complete():
		return is_state(Complete)
		
	func is_state_empty():
		return is_state(Empty)
	
	func set_state_complete():
		set_state(Complete)
		
	func set_state_empty():
		set_state(Empty)
	
	func _initialize(parent):
		._initialize(parent)
		add_state(Complete)
		add_state(Empty)
