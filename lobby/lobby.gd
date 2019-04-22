extends Node

signal lobby_finished()

var _fsm
var _chat
var _button_start_disabled = true

var _addresses = {}
var _address_selected = null

onready var _menu_container = get_node("menu_container")
onready var _host_container = get_node("menu_container/Panel/vbox_container/host_container")
onready var _join_container = get_node("menu_container/Panel/vbox_container/join_container")
onready var _lobby_container = get_node("lobby_container")

func close_lobby():
	_fsm.set_state_none()

func open_menu():
	_fsm.set_state_menu()

func open_lobby():
	_fsm.set_state_lobby()

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
	_fsm.set_state_lobby()

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
	_fsm.set_state_none()
	
	# Disconnect networking
	Gamestate.quit_game()
	
	emit_signal("lobby_finished")

# MAIN MENU
func _on_button_host_pressed():
	_fsm.menu().set_state_host()

# MAIN MENU
func _on_button_join_pressed():
	_fsm.menu().set_state_join()

# HOST CONTAINER - Continue (from choosing a nickname)
# Opens the server for connectivity from clients
func _on_host_button_continue_pressed():
	var values = _validate_host()
	if (values == null):
		return
	
	if (!Gamestate.host_game(values.server_name, values.port, values.ip_address)):
		_set_error("host", tr("LOBBY_MESSAGE_SERVER_ALREADY_IN_USE"))
		return
	
	ConfigurationUser.Settings.User.Host.Name = values.server_name
	ConfigurationUser.Settings.User.Host.IpAddress = values.ip_address
	ConfigurationUser.Settings.User.Host.Port = values.port
	ConfigurationUser.save()
	
	_button_start_disabled = true
	_fsm.set_state_lobby()
	_refresh_lobby()

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
	
	if (!Gamestate.join_game(values.ip_address, values.port)):
		_set_error("host", tr("LOBBY_MESSAGE_JOIN_FAILED"))
		return
	
	ConfigurationUser.Settings.User.Join.IpAddress = values.ip_address
	ConfigurationUser.Settings.User.Join.Port = values.port
	ConfigurationUser.save()
	
	# While we are attempting to connect, disable button for 'continue'
	_fsm.menu().set_state_join()

func _on_join_text_ip_address_focus_exited():
	_validate_join()
		
func _on_join_text_port_focus_exited():
	_validate_join()
	
# LOBBY CONTAINER - Starts the Game
func _on_lobby_button_start_pressed():
	_fsm.set_state_in_game()
	
	Gamestate.start_game()

# LOBBY CONTAINER - Cancel Lobby
# (The only time you are already connected from main menu)
func _on_lobby_button_cancel_pressed():
	_fsm.set_state_menu()
	
	# Disconnect networking
	Gamestate.quit_game()

func _on_lobby_line_chat_input(scancode):
	var index = 0
	if (scancode == KEY_UP):
		index = _chat.increment(true)
	elif (scancode == KEY_DOWN):
		index = _chat.increment(false)
		
	var message = _chat.history()
	var text_chat = _lobby_container.find_node("line_chat")
	text_chat.clear()
	if (message != null):
		text_chat.set_text(message)

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
	if (!get_tree().is_network_server()):
		return
	
	_button_start_disabled = false
	_lobby_container.find_node("button_start").set_disabled(false)

func _on_refresh_lobby_start_disabled():
	if (!get_tree().is_network_server()):
		return
	
	_button_start_disabled = true
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
		_lobby_container.find_node("button_start").set_disabled(_button_start_disabled)

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
	
func _validate_host():
	_disable_button("host", "button_continue", true)
	
	var server_name = Gamestate.validator().validate_server_name(_host_container.find_node("text_server_name").get_text(), _get_error("host"))
	if (server_name == null):
		return null
	
	var port = Gamestate.validator().validate_port(_host_container.find_node("text_port").get_text(), _get_error("host"))
	if (port == null):
		return null
	
	var ip_address = null
	if (_address_selected != null):
		for address in _address_selected.addresses:
			# TODO: need to know if using V4 or V6
			if (address.type == IP.TYPE_IPV4):
				ip_address = address.address
				break
	
	if (ip_address != null):
		ip_address = Gamestate.validator().validate_address(ip_address, _get_error("host"))
		if (ip_address == null):
			return null
	
	_fsm.menu().set_state_host_ready()
	
	return { "server_name": server_name, "port": port, "ip_address": ip_address }
	
func _validate_join():
	_disable_button("join", "button_connect", true)
	
	var ip_address = Gamestate.validator().validate_address(_join_container.find_node("text_ip_address").get_text(), _get_error("join"))
	if (ip_address == null):
		return null
	
	var port = Gamestate.validator().validate_port(_join_container.find_node("text_port").get_text(), _get_error("join"))
	if (port == null):
		return null
	
	_fsm.menu().set_state_join_ready()
	
	return { "ip_address": ip_address, "port": port }

func _on_option_addresses_item_selected(ID):
	_address_selected = null
	var label_meta = _host_container.find_node("label_address_meta")
	label_meta.set_text("")
	
	if (ID < 0):
		return
	
	var addresses = _host_container.find_node("option_addresses")
	var address = addresses.get_item_metadata(ID)
	if (address == null):
		return
		
	_address_selected = address
	
	var text = ""
	for item in address.addresses:
		if (item.type == IP.TYPE_ANY):
			break
		
		if (item.type == IP.TYPE_IPV4):
			if (text != ""):
				text += "\n"
			text += "v4: " + item.address
		if (item.type == IP.TYPE_IPV6):
			if (text != ""):
				text += "\n"
			text += "v6: " + item.address
	
	label_meta.set_text(text)

func _on_state_changed(state_from, state_to, args):
	_fsm._print_state(state_from, state_to, args)
	if (state_to ==  _fsm.InGame):
		return
		
	if (state_to == _fsm.Lobby):
		if (get_tree().is_network_server()):
			_button_start_disabled = true
			_lobby_container.find_node("button_start").set_disabled(_button_start_disabled)
		
		_menu_container.hide()
		_host_container.hide()
		_join_container.hide()
		_lobby_container.show()
		return
		
	if (state_to == _fsm.Menu):
		_menu_container.show()
		_host_container.hide()
		_join_container.hide()
		_lobby_container.hide()
		_clear_error("join")
		_clear_error("host")
		if (_fsm.menu().is_state_join() || _fsm.menu().is_state_join_ready()):
			_fsm.menu().set_state_join()
			return
		_fsm.menu().set_state_host()
		return
	
	_menu_container.hide()
	_host_container.hide()
	_join_container.hide()
	_lobby_container.hide()
	_fsm.menu().set_state_none()

func _on_state_lobby_changed(state_from, state_to, args):
	_fsm.lobby()._print_state(state_from, state_to, args)

func _on_state_menu_changed(state_from, state_to, args):
	_fsm.menu()._print_state(state_from, state_to, args)
	if (state_to == _fsm.menu().Host):
		var user = ConfigurationUser.Settings.User
		if ((user.Host != null) && (user.Host.Name != null) && (user.Host.Name != "")):
			_host_container.find_node("text_server_name").set_text(user.Host.Name)
		if ((user.Host != null) && (user.Host.Port != null)):
			_host_container.find_node("text_port").set_text(str(user.Host.Port))
		
		var addresses = _host_container.find_node("option_addresses")

		var ipAddressSelected = null
		if ((user.Host != null) && (user.Host.IpAddress != null) && (user.Host.IpAddress != "")):
			ipAddressSelected = user.Host.IpAddress
		
		var index = 0
		var selected_index = 0
		var address = null
		for key in _addresses:
			address = _addresses[key]
			for temp in address.addresses:
				if (temp.address == ipAddressSelected):
					selected_index = index
					break
			index += 1
		
		addresses.select(selected_index)
		_on_option_addresses_item_selected(selected_index)
		
		_menu_container.show()
		_join_container.hide()
		_host_container.show()
		_lobby_container.hide()
		_menu_container.find_node("button_host").disabled = true
		_menu_container.find_node("button_join").disabled = false
		_clear_error("host")
		_disable_button("host", "button_continue", true)
		_validate_host()
		return
	
	if (state_to ==  _fsm.menu().Host_Ready):
		_disable_button("host", "button_continue", false)
		_clear_error("host")
		return
	
	if (state_to == _fsm.menu().Join):
		var user = ConfigurationUser.Settings.User
		if ((user.Join != null) && (user.Join.IpAddress != null) && (user.Join.IpAddress != "")):
			_join_container.find_node("text_ip_address").set_text(user.Join.IpAddress)
		if ((user.Join != null) && (user.Join.Port != null)):
			_join_container.find_node("text_port").set_text(str(user.Join.Port))
		
		_menu_container.show()
		_host_container.hide()
		_join_container.show()
		_lobby_container.hide()
		_menu_container.find_node("button_host").disabled = false
		_menu_container.find_node("button_join").disabled = true
		_clear_error("join")
		_disable_button("join", "button_connect", true)
		_validate_join()
		return
	
	if (state_to ==  _fsm.menu().Join_Ready):
		_clear_error("join")
		_disable_button("join", "button_connect", false)
		return
	
	_host_container.hide()
	_join_container.hide()
	_clear_error("host")
	_clear_error("join")

func _ready():
	_fsm = state.new()
	_fsm.initialize(self)
	_fsm.set_state_menu()
	
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
	
	_addresses[tr("LOBBY_ADDRESS_WILDCARD")] = { "name": tr("LOBBY_ADDRESS_WILDCARD"), "addresses": [ { "type": IP.TYPE_ANY, "address": "*" } ] }

	var interfaces = IP.get_local_interfaces()
	var temp = null
	for ip in interfaces:
		temp = { "name": ip.friendly, "addresses": ip.addresses }
#		for address in ip.addresses:
#			if (address.type == IP.TYPE_IPV4):
#				temp["v4"] = address.address
#				temp["type"] = IP.TYPE_IPV4
#			elif (address.type == IP.TYPE_IPV6):
#				temp["v6"] = address.address
#				temp["type"] = IP.TYPE_IPV6
		_addresses[ip.friendly] = temp
	
	var index = 0
	var address = null
	var addresses = _host_container.find_node("option_addresses")
	for key in _addresses:
		address = _addresses[key]
		addresses.add_item(address.name, index)
		addresses.set_item_metadata(index, address)
		index += 1

class state_lobby extends "res://fsm/base_fsm.gd":
	
	const None = "none"
	
	func is_state_none():
		return is_state(None)
	
	func set_state_none():
		set_state(None)
	
	func _initialize(parent):
		._initialize(parent)
		set_name("multiplayer_lobby")
		connect_state_changed(parent, "_on_state_lobby_changed")
		add_state(None)

class state_menu extends "res://fsm/base_fsm.gd":
	
	const Host = "host"
	const Host_Ready = "host_ready"
	const Join = "join"
	const Join_Ready = "join_ready"
	const None = "none"
	
	func is_state_host():
		return is_state(Host)
	
	func is_state_host_ready():
		return is_state(Host_Ready)
	
	func is_state_join():
		return is_state(Join)
	
	func is_state_join_ready():
		return is_state(Join_Ready)
	
	func is_state_none():
		return is_state(None)
	
	func set_state_host():
		set_state(Host)
	
	func set_state_host_ready():
		set_state(Host_Ready)
		
	func set_state_join():
		set_state(Join)
	
	func set_state_join_ready():
		set_state(Join_Ready)
	
	func set_state_none():
		set_state(None)
	
	func _initialize(parent):
		._initialize(parent)
		set_name("multiplayer_menu")
		connect_state_changed(parent, "_on_state_menu_changed")
		add_state(Host)
		add_state(Host_Ready)
		add_state(Join)
		add_state(Join_Ready)
		add_state(None)

class state extends "res://fsm/base_fsm.gd":
	
	const Host = "host"
	const InGame = "in_game"
	const Join = "join"
	const Lobby = "lobby"
	const Menu = "menu"
	const None = "none"
	
	var _fsm_lobby
	var _fsm_menu
	
	func lobby():
		return _fsm_lobby
	
	func menu():
		return _fsm_menu
	
	func is_state_host():
		return is_state(Host)
	
	func is_state_in_game():
		return is_state(InGame)
	
	func is_state_join():
		return is_state(Join)
	
	func is_state_lobby():
		return is_state(Lobby)
	
	func is_state_menu():
		return is_state(Menu)
	
	func is_state_none():
		return is_state(None)
	
	func set_state_host():
		set_state(Host)
	
	func set_state_in_game():
		set_state(InGame)
	
	func set_state_join():
		set_state(Join)
	
	func set_state_lobby():
		set_state(Lobby)
	
	func set_state_menu():
		set_state(Menu)
	
	func set_state_none():
		set_state(None)
	
	func _initialize(parent):
		._initialize(parent)
		set_name("multiplayer")
		connect_state_changed(parent, "_on_state_changed")
		add_state(Host)
		add_state(InGame)
		add_state(Join)
		add_state(Lobby)
		add_state(Menu)
		add_state(None)
		
		_fsm_lobby = state_lobby.new()
		_fsm_lobby.initialize(parent)
		_fsm_lobby.set_state_none()
		
		_fsm_menu = state_menu.new()
		_fsm_menu.initialize(parent)
		_fsm_menu.set_state_none()
