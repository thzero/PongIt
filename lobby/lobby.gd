extends Node

signal lobby_finished()

var _fsm
var _chat
var _button_start = false
var _history_current = 0

onready var _menu_container = get_node("menu_container")
onready var _host_container = get_node("menu_container/Panel/vbox_container/host_container")
onready var _join_container = get_node("menu_container/Panel/vbox_container/join_container")
onready var _lobby_container = get_node("lobby_container")

func close_lobby():
	_menu_container.hide()
	_join_container.hide()
	_host_container.hide()
	_lobby_container.hide()
	_clear_error("join")
	_clear_error("host")

func open_menu():
	_menu_container.hide()
	_join_container.hide()
	_host_container.hide()
	_lobby_container.hide()
	_clear_error("join")
	_clear_error("host")
	_menu_container.show()
	_show_host()

func open_lobby():
	_menu_container.hide()
	_join_container.hide()
	_host_container.hide()
	_lobby_container.show()

#### Gamestate

func _on_chat_message(player_from, message, type, args):
	if (_chat == null):
		return

	var text = _lobby_container.find_node("text_chat")
	if (text == null):
		return
	
	_chat.handle(player_from, message, type, args, text)

func _on_connection_fail():
	# Display error telling the user that the server cannot be connected
	_join_container.find_node("label_error").set_text("Cannot connect to server, try again or use another IP address")
	
	# Enable continue button again
	_join_container.find_node("button_connect").set_disabled(false)

func _on_connection_success():
	_join_container.hide()
	_lobby_container.show()

# Handles what to happen after game ends
func _on_game_ended():
	open_lobby()

# Handles what to happen after game starts
func _on_game_started():
	close_lobby()

# Handles what to happen after server ends
func _on_server_ended():
	open_menu()

func _on_server_error():
	print("_on_server_error: Unknown error")

#### Events

# ALL - Cancel (from any container)
func _on_button_cancel_pressed():
	_menu_container.hide()
	_join_container.hide()
	_host_container.hide()
	_lobby_container.hide()
	emit_signal("lobby_finished")

# MAIN MENU
func _on_button_host_pressed():
	_show_host()

# MAIN MENU
func _on_button_join_pressed():
	_show_join()

# HOST CONTAINER - Continue (from choosing a nickname)
# Opens the server for connectivity from clients
func _on_host_button_continue_pressed():
	var values = _validate_host()
	if (values == null):
		return
	
	if (!Gamestate.host_game(values.server_name, values.port)):
		return
	
	_refresh_lobby()
	
	_host_container.hide()
	_lobby_container.show()
	
	_button_start = false
	_lobby_container.find_node("button_start").set_disabled(_button_start)

func _on_host_text_server_name_focus_exited():
	_validate_host()
		
func _on_host_text_port_focus_exited():
	_validate_host()

func _on_itemlist_players_ready_item_selected(index):
	var itemlist_ready = _lobby_container.find_node("itemlist_players_ready")
	var ready = itemlist_ready.get_item_text(index)
	var temp = (ready == "Ready")
	Gamestate.ready_player_request(!temp)

# JOIN CONTAINER - Connect
# Attempts to connect to the server
# If successful, continue to Lobby or jump in-game (if running)
func _on_join_button_connect_pressed():
	var values = _validate_join()
	if (values == null):
		return
	
	if (Gamestate.join_game(values.ip_address, values.port)):
		return
	
	# While we are attempting to connect, disable button for 'continue'
	_join_container.find_node("button_connect").set_disabled(true)

func _on_join_text_ip_address_focus_exited():
	_validate_join()
		
func _on_join_text_port_focus_exited():
	_validate_join()
	
# LOBBY CONTAINER - Starts the Game
func _on_lobby_button_start_pressed():
	Gamestate.start_game()

# LOBBY CONTAINER - Cancel Lobby
# (The only time you are already connected from main menu)
func _on_lobby_button_cancel_pressed():
	# Toggle containers
	_lobby_container.hide()
	_menu_container.show()
	
	# Disconnect networking
	Gamestate.quit_game()
	
	# Enable buttons
	_join_container.find_node("button_connect").set_disabled(false)

func _on_lobby_line_chat_input(scancode):
	var index = 0
	if (scancode == KEY_UP):
		index = _chat.increment(true)
	elif (scancode == KEY_DOWN):
		index = _chat.increment(false)
		
	var message = _chat.history()
	var text_chat = _lobby_container.find_node("line_chat")
	if (message != null):
		text_chat.set_text(message)
	else:
		text_chat.clear()

func _on_lobby_button_chat_pressed():
	_on_lobby_chat(null)
	
func _on_lobby_chat(message):
	var text_chat = _lobby_container.find_node("line_chat")
	
	if (message == null):
		message = text_chat.get_text()
		
	if (message == ""):
		return
	
	_chat.message(message)
	
	text_chat.clear()

func _on_lobby_line_chat_text_entered(message):
	_on_lobby_chat(message)

func _on_refresh_lobby():
	_refresh_lobby()
	
func _on_refresh_lobby_start_enabled():
	if (get_tree().is_network_server()):
		_button_start = false
		_lobby_container.find_node("button_start").set_disabled(false)

func _on_refresh_lobby_start_disabled():
	if (get_tree().is_network_server()):
		_button_start = true
		_lobby_container.find_node("button_start").set_disabled(true)
	
func _clear_error(type):
	_set_error(type, "")
	
func _disable_button(type, name, disabled):
	var container
	if (type == "host"):
		container = _host_container
	elif (type == "join"):
		container = _join_container
	elif (type == "lobby"):
		container = _lobby_container
	
	var button = container.find_node(name)
	if (button == null):
		return
	
	button.disabled = disabled
	
func _get_error(type):
	var container
	if (type == "host"):
		container = _host_container
	elif (type == "join"):
		container = _join_container
	elif (type == "lobby"):
		container = _lobby_container
	
	return container.find_node("label_error")

# Refresh Lobby's player list
# This is run after we have gotten updates from the server regarding new players
func _refresh_lobby():
	_lobby_container.find_node("button_start").set_disabled(true)
	
	# Get the latest list of players from gamestate
	var player_list = Gamestate.get_player_list(true)
	player_list.sort()
	
	# Add the updated player_list to the itemlist
	var itemlist = _lobby_container.find_node("itemlist_players")
	var itemlist_ready = _lobby_container.find_node("itemlist_players_ready")
	itemlist.clear()
	itemlist_ready.clear()
	
	itemlist.add_item(Gamestate.get_player().name + " (" + tr("LOBBY_YOU").to_upper() + ")")
	itemlist_ready.add_item(_refresh_lobby_ready(Gamestate.get_player().ready))
	
	# Add every other player to the list
	for player in player_list:
		itemlist.add_item(player.name)
		itemlist_ready.add_item(_refresh_lobby_ready(player.ready))
	
	# If you are the server, enable the 'start game' button
	if (get_tree().is_network_server()):
		_lobby_container.find_node("button_start").set_disabled(_button_start)

func _refresh_lobby_ready(ready):
	var state = "Unready"
	if (ready):
		state = "Ready"
	
	return state
	
func _set_error(type, message):
	var label = _get_error(type)
	if (label == null):
		return
	
	label.set_text(message)

func _show_host():
	_join_container.hide()
	_host_container.show()
	_menu_container.find_node("button_host").disabled = true
	_menu_container.find_node("button_join").disabled = false
	_validate_host()
	
func _show_join():
	_host_container.hide()
	_join_container.show()
	_menu_container.find_node("button_host").disabled = false
	_menu_container.find_node("button_join").disabled = true
	_disable_button("join", "button_connect", true)
	_validate_join()
	
func _validate_host():
	_disable_button("host", "button_continue", true)
	
	var server_name = Gamestate.validator().validate_server_name(_host_container.find_node("text_server_name").get_text(), _get_error("host"))
	if (server_name == null):
		return null
	
	var port = Gamestate.validator().validate_port(_host_container.find_node("text_port").get_text(), _get_error("host"))
	if (port == null):
		return false
	
	_disable_button("host", "button_continue", false)
	
	_clear_error("host")
	
	return { "server_name": server_name, "port": port }
	
func _validate_join():
	_disable_button("join", "button_connect", true)
	
	var ip_address = Gamestate.validator().validate_address(_join_container.find_node("text_ip_address").get_text(), _get_error("join"))
	if (ip_address == null):
		return
	
	var port = Gamestate.validator().validate_port(_host_container.find_node("text_port").get_text(), _get_error("host"))
	if (port == null):
		return false
	
	_disable_button("join", "button_connect", false)
	
	_clear_error("join")
	
	return { "ip_address": ip_address, "port": port }

func _on_state_changed(state_from, state_to, args):
	print("switched to state: ", state_to)
	"""
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
	"""

func _ready():
	_fsm = state.new()
	_fsm.initialize()
	_fsm.connect_state_changed(self, "_on_state_changed")
	_fsm.set_state_disconnected()
	
	_chat = load(Constants.PATH_CHAT).new()
	
	var text_chat = _lobby_container.find_node("line_chat")
	text_chat.connect("input", self, "_on_lobby_line_chat_input")
	
	# Set default nicknames on host/join
	_host_container.find_node("text_server_name").set_text(Constants.DEFAULT_SERVER_NAME)
	_host_container.find_node("text_port").set_text(str(Constants.DEFAULT_SERVER_PORT))
	_join_container.find_node("text_ip_address").set_text(Constants.DEFAULT_SERVER_ADDRESS)
	_join_container.find_node("text_port").set_text(str(Constants.DEFAULT_SERVER_PORT))
	
	# Setup Network Signaling between Gamestate and Game UI
	Gamestate.connect("chat_message", self, "_on_chat_message")
	Gamestate.connect("game_ended", self, "_on_game_ended")
	Gamestate.connect("game_started", self, "_on_game_started")
	Gamestate.connect("refresh_lobby", self, "_on_refresh_lobby")
	Gamestate.connect("refresh_lobby_start_enabled", self, "_on_refresh_lobby_start_enabled")
	Gamestate.connect("refresh_lobby_start_disabled", self, "_on_refresh_lobby_start_disabled")
	Gamestate.connect("server_ended", self, "_on_server_ended")
	Gamestate.connect("server_error", self, "_on_server_error")
	Gamestate.connect("connection_success", self, "_on_connection_success")
	Gamestate.connect("connection_fail", self, "_on_connection_fail")

class state extends "res://fsm/base_fsm.gd":
	
	const Host = "host"
	const InGame = "in_game"
	const Join = "join"
	const Lobby = "lobby"
	
	var _fsm_host
	var _fsm_join
	var _fsm_lobby
	
	func is_state_connected():
		return is_state(Host)
	
	func is_state_disconnected():
		return is_state(InGame)
	
	func is_state_in_game():
		return is_state(Join)
	
	func is_state_waiting():
		return is_state(Lobby)
	
	func set_state_connected():
		set_state(Host)
		
	func set_state_disconnected():
		set_state(InGame)
	
	func set_state_in_game():
		set_state(Join)
	
	func set_state_waiting():
		set_state(Lobby)
	
	func _initialize():
		._initialize()
		add_state(Host)
		add_state(InGame)
		add_state(Join)
		add_state(Lobby)
