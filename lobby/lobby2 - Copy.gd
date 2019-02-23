extends Node

signal lobby_finished()

var _fsm

#### Containers
onready var menu_container = get_node("menu_container")
onready var join_container = get_node("join_container")
onready var host_container = get_node("host_container")
onready var lobby_container = get_node("lobby_container")

#### Gamestate

func _on_connection_fail():
	# Display error telling the user that the server cannot be connected
	join_container.find_node("label_error").set_text("Cannot connect to server, try again or use another IP address")
	
	# Enable continue button again
	join_container.find_node("button_connect").set_disabled(false)

func _on_connection_success():
	join_container.hide()
	lobby_container.show()

# Handles what to happen after server ends
func _on_server_ended():
	lobby_container.hide()
	join_container.hide()
	join_container.find_node("button_connect").set_disabled(false)
	menu_container.show()
	
	Gamestate.end_game()

func _on_server_error():
	print("_on_server_error: Unknown error")

#### Events

# ALL - Cancel (from any container)
func _on_button_cancel_pressed():
	menu_container.show()
	join_container.hide() 
	join_container.find_node("label_error").set_text("")
	host_container.hide()
	host_container.find_node("label_error").set_text("")

# MAIN MENU - Quit Game
func _on_button_exit_pressed():
	emit_signal("lobby_finished")

# MAIN MENU - Host Game
# Opens up the 'Choose a nickname' window
func _on_button_host_pressed():
	menu_container.hide()
	host_container.show()

# MAIN MENU - Join Game
# Opens up the 'Connect to Server' window
func _on_button_join_pressed():
	menu_container.hide()
	join_container.show() 

# HOST CONTAINER - Continue (from choosing a nickname)
# Opens the server for connectivity from clients
func _on_host_button_continue_pressed():
	# Check if nickname is valid
	var server_name = host_container.find_node("text_server_name").get_text()
	if (server_name == ""):
		host_container.find_node("label_error").set_text("Server name cannot be empty.")
		return
	
	var port = Gamestate.validate_address(join_container.find_node("text_port").get_text(), join_container.find_node("label_error"))
	if (port == null):
		return
	
	# Clear error (if any)
	host_container.find_node("label_error").set_text("")
	
	# Establish network
	if (Gamestate.host_game(server_name, port)):
		return
	
	# Refresh Player List (with your own name)
	_refresh_lobby()
	
	# Toggle to Lobby
	host_container.hide()
	lobby_container.show()
	lobby_container.find_node("button_start").set_disabled(false)

# JOIN CONTAINER - Connect
# Attempts to connect to the server
# If successful, continue to Lobby or jump in-game (if running)
func _on_join_button_connect_pressed():
	# Check entered IP address for errors
	var ip_address = Gamestate.validate_address(join_container.find_node("text_ip_address").get_text(), join_container.find_node("label_error"))
	if (ip_address == null):
		return
	
	var port = Gamestate.validate_port(join_container.find_node("text_port").get_text(), join_container.find_node("label_error"))
	if (port == null):
		return
	
	# Clear error (if any)
	join_container.find_node("label_error").set_text("")
	
	# Connect to server
	if (Gamestate.join_game(ip_address, port)):
		return
	
	# While we are attempting to connect, disable button for 'continue'
	join_container.find_node("button_connect").set_disabled(true)

# LOBBY CONTAINER - Starts the Game
func _on_lobby_button_start_pressed():
	Gamestate.start_game()

# LOBBY CONTAINER - Cancel Lobby
# (The only time you are already connected from main menu)
func _on_lobby_button_cancel_pressed():
	# Toggle containers
	lobby_container.hide()
	menu_container.show()
	
	# Disconnect networking
	Gamestate.quit_game()
	
	# Enable buttons
	join_container.find_node("button_connect").set_disabled(false)

func _on_lobby_refresh():
	_refresh_lobby()

# Refresh Lobby's player list
# This is run after we have gotten updates from the server regarding new players
func _refresh_lobby():
	# Get the latest list of players from gamestate
	var player_list = Gamestate.get_player_list()
	player_list.sort()
	
	# Add the updated player_list to the itemlist
	var itemlist = lobby_container.find_node("itemlist_players")
	itemlist.clear()
	itemlist.add_item(Gamestate.get_player_name() + " (" + tr("LOBBY_YOU").to_upper() + ")")
	
	# Add every other player to the list
	for player in player_list:
		itemlist.add_item(player)
	
	# If you are not the server, we disable the 'start game' button
	if (!get_tree().is_network_server()):
		lobby_container.find_node("button_start").set_disabled(true)

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
	_fsm.init()
	_fsm.connect_state_changed(self, "_on_state_changed")
	_fsm.set_state_disconnected()
	
	# Set default nicknames on host/join
	host_container.find_node("text_server_name").set_text(Constants.DEFAULT_SERVER_NAME)
	host_container.find_node("text_port").set_text(str(Constants.DEFAULT_SERVER_PORT))
	join_container.find_node("text_ip_address").set_text(Constants.DEFAULT_SERVER_ADDRESS)
	join_container.find_node("text_port").set_text(str(Constants.DEFAULT_SERVER_PORT))
	
	# Setup Network Signaling between Gamestate and Game UI
	Gamestate.connect("refresh_lobby", self, "_on_lobby_refresh")
	Gamestate.connect("server_ended", self, "_on_server_ended")
	Gamestate.connect("server_error", self, "_on_server_error")
	Gamestate.connect("connection_success", self, "_on_connection_success")
	Gamestate.connect("connection_fail", self, "_on_connection_fail")

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

