extends Node

signal lobby_finished()

var _fsm
var _level

#### Network callbacks from SceneTree
	
# only for clients (not server)	
func _connection_failed():
	_set_status(tr("LOBBY_MESSAGE_CANT_CONNECT"), false)
	
	get_tree().set_network_peer(null) #remove peer
	
	_fsm.set_state_disconnected()

# only for clients (not server)
func _connected_to_server():
	print("connected to server.")
	_fsm.set_state_connected()

func _network_peer_connected(id):
	print("peer " + str(id) + " connected.")
	
	# A player connected, start the game!
	_level = load("res://game/pong.tscn").instance()
		# connect deferred so we can safely erase it from the callback
	_level.connect("game_finished", self, "_end_game", [], CONNECT_DEFERRED)
	
	get_tree().get_root().add_child(_level)
	_get_panel().hide()
	
	_fsm.set_state_in_game()

func _network_peer_disconnected(id):
	print("peer " + str(id) + " discconnected.")
	_fsm.set_state_disconnected()
	
	if (get_tree().is_network_server()):
		_end_game(tr("NETWORK_MESSAGE_DISCONNECTED_CLIENT"))
		return
	
	_end_game(tr("NETWORK_MESSAGE_DISCONNECTED_SERVER"))

# only for clients (not server)
func _server_disconnected():
	print("server discconnected.")
	_fsm.set_state_disconnected()
	
	_end_game(tr("NETWORK_MESSAGE_DISCONNECTED_SERVER"))

func _on_button_cancel_pressed():
	_close_connetion()
	
	_set_status(tr("LOBBY_MESSAGE_CANCELLED"), true)
	_fsm.set_state_disconnected()

func _on_button_exit_pressed():
	_close_connetion()
	
	_set_status(tr("LOBBY_MESSAGE_EXITING"), true)
	_fsm.set_state_disconnected()
	emit_signal("lobby_finished")

func _on_button_host_pressed():
	var port = _get_port()
	if (port == null):
		_set_status(tr("LOBBY_MESSAGE_PORT_INVALID"), false)
		return
		
	var ip = _get_address()
	if (ip == null):
		_set_status(tr("LOBBY_MESSAGE_ADDRESS_INVALID"), false)
		return
	
	var host = _create_host()
	
	print("start server.")
	
	# max: 1 peer, since it's a 2 players game
	var err = host.create_server(port, 1)
	if (err != OK):
		# is another server running?
		_set_status(tr("NETWORK_MESSAGE_CANT_HOST"), false)
		return
		
	_set_status(tr("LOBBY_MESSAGE_CONNECTING"), true)
	get_tree().set_network_peer(host)
	get_tree().set_meta("network_peer", host)
	
	_fsm.set_state_waiting()

func _on_button_join_pressed():
	var port = _get_port()
	if (port == null):
		_set_status(tr("LOBBY_MESSAGE_PORT_INVALID"), false)
		return
		
	var ip = _get_address()
	if (ip == null):
		_set_status(tr("LOBBY_MESSAGE_ADDRESS_INVALID"), false)
		return
	
	_set_status(tr("LOBBY_MESSAGE_CONNECTING"), true)
	
	var host = _create_host()
	
	print("start client.")
	host.create_client(ip, port)
	get_tree().set_network_peer(host)
	get_tree().set_meta("network_peer", host)
	
	_fsm.set_state_waiting()

#### Network helpers

func _create_host():
	var host = NetworkedMultiplayerENet.new()
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	return host
	
func _close_connetion():
	if (get_tree().is_network_server()):
		var host = get_tree().get_meta("network_peer")
		if (host != null):
			host.close_connection() 
	get_tree().set_network_peer(null)

func _end_game(with_error = ""):
	if ((_level != null) && has_node(_level.get_path())):
		# remove level
		# erase immediately, otherwise network might show errors (this is why we connected deferred above)
		get_node(_level.get_path()).free()
		_get_panel().show()
	
	# remove peer
	get_tree().set_network_peer(null)
	
	_fsm.set_state_disconnected()
	
	_set_status(with_error, false)

func _get_address():
	var ip = _get_line_address().get_text()
	if (not ip.is_valid_ip_address()):
		_set_status(tr("LOBBY_MESSAGE_ADDRESS_INVALID"), false)
		return null
		
	return ip
	
func _get_port():
	var port = _get_line_port().get_text()
	if (not port.is_valid_integer()):
		_set_status(tr("LOBBY_MESSAGE_PORT_INVALID"), false)
		return null
		
	var portN = port.to_int();
	if (portN < 1024 || portN > 65535):
		_set_status(tr("LOBBY_MESSAGE_PORT_INVALID_RANGE"), false)
		return null
		
	return portN
	
#### Node helpers

func _get_button_cancel():
	return get_node("panel/button_cancel")
func _get_button_exit():
	return get_node("panel/button_exit")
func _get_button_host():
	return get_node("panel/button_host")
func _get_button_join():
	return get_node("panel/button_join")
func _get_label_status():
	return get_node("panel/label_status")
func _get_label_status_fail():
	return get_node("panel/label_status_fail")
func _get_label_status_ok():
	return get_node("panel/label_status_ok")
func _get_line_address():
	return get_node("panel/line_address")
func _get_line_port():
	return get_node("panel/line_port")
func _get_panel():
	return get_node("panel")

func _set_status(text, isok):
	if (isok):
		_get_label_status_ok().set_text(text)
		_get_label_status_fail().set_text("")
		return

	_get_label_status_ok().set_text("")
	_get_label_status_fail().set_text(text)
	
#### State
func _on_state_changed(state_from, state_to, args):
	print("switched to state: ", state_to)
	if (state_to == _fsm.Disconnected):
		_get_button_cancel().set_disabled(true)
		_get_button_exit().set_disabled(false)
		_get_button_host().set_disabled(false)
		_get_button_join().set_disabled(false)
		
		_get_label_status().set("custom_colors/font_color", Color(1,0,0))
		_get_label_status().set_text(tr("LOBBY_STATUS_DISCONNECTED"))
		_set_status("", false)
	elif (state_to == _fsm.Connected):
		_get_button_cancel().set_disabled(true)
		_get_button_exit().set_disabled(false)
		_get_button_host().set_disabled(false)
		_get_button_join().set_disabled(false)
		
		_get_label_status().set("custom_colors/font_color", Color(0,1,0))
		_get_label_status().set_text(tr("LOBBY_STATUS_CONNECTED"))
		_set_status("", false)
	elif (state_to == _fsm.InGame):
		_get_button_cancel().set_disabled(true)
		_get_button_exit().set_disabled(true)
		_get_button_host().set_disabled(true)
		_get_button_join().set_disabled(true)
		
		_get_label_status().set("custom_colors/font_color", Color(0,0,1))
		_get_label_status().set_text(tr("LOBBY_STATUS_IN_GAME"))
		_set_status("", false)
	else:
		_get_button_cancel().set_disabled(false)
		_get_button_exit().set_disabled(true)
		_get_button_host().set_disabled(true)
		_get_button_join().set_disabled(true)
		
		_get_label_status().set("custom_colors/font_color", Color(0,1,0))
		if (get_tree().is_network_server()):
			_get_label_status().set_text(tr("LOBBY_STATUS_WAITING"))
		else:
			_get_label_status().set_text(tr("LOBBY_STATUS_WAITING_SERVER"))
		_set_status("", false)

func _ready():
	_fsm = state.new()
	_fsm.init()
	_fsm.connect_state_changed(self, "_on_state_changed")
	_fsm.set_state_disconnected()
	
	# connect all the callbacks related to networking
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_network_peer_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("connection_failed", self, "_connection_failed")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	_get_line_address().set_text(Constants.DEFAULT_SERVER_ADDRESS)
	_get_line_port().set_text(str(Constants.DEFAULT_SERVER_PORT))
	
	# Dumb - issues with size of label
	_get_button_cancel().set_text(tr("LOBBY_BUTTON_CANCEL"))
	_get_button_exit().set_text(tr("LOBBY_BUTTON_EXIT"))
	_get_button_host().set_text(tr("LOBBY_BUTTON_HOST"))
	_get_button_join().set_text(tr("LOBBY_BUTTON_JOIN"))

class state extends "res://fsm/base_fsm.gd":

	const Connected = "connected"
	const Disconnected = "disconnected"
	const InGame = "in_game"
	const Waiting = "waiting"
	
	func init():
		add_state(Connected)
		add_state(Disconnected)
		add_state(InGame)
		add_state(Waiting)
		
	func is_state_connected():
		return is_state(Connected)
		
	func is_state_disconnected():
		return is_state(Disconnected)
		
	func is_state_in_game():
		return is_state(InGame)
		
	func is_state_waiting():
		return is_state(Waiting)
	
	func set_state_connected():
		set_state(Connected)
		
	func set_state_disconnected():
		set_state(Disconnected)
		
	func set_state_in_game():
		set_state(InGame)
		
	func set_state_waiting():
		set_state(Waiting)

