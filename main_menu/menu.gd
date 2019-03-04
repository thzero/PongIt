extends Control

var _fsm
var _user
var _lobby
var _regExLib

onready var _about_container = get_node("about_container")
onready var _main_container = get_node("main_container")
onready var _settings_container = get_node("settings_container")

func _initialize_lobby():
	return load(Constants.PATH_LOBBY).instance()

func _load_settings():
	_main_container.find_node("line_name").text = ConfigurationUser.Settings.User.Name
	
	_user.name = ConfigurationUser.Settings.User.Name

func _on_button_about_pressed():
	_fsm.set_state_about()

func _on_button_exit_pressed():
	get_tree().quit()

func _on_button_ok_pressed():
	if (_validate_name(_user.name)):
		_fsm.user_name().set_state_complete()
		ConfigurationUser.update_settings(_user)
		return

func _on_button_mutiplayer_pressed():
	_lobby = _initialize_lobby()
	_lobby.connect("lobby_finished", self, "_on_end_lobby")
	get_tree().get_root().add_child(_lobby)
	_lobby.open_menu()
	_fsm.set_state_lobby()

func _on_button_settings_pressed():
	_fsm.set_state_settings()

func _on_button_start_pressed():
	#_lobby = load("res://lobby.tscn").instance()
	## connect deferred so we can safely erase it from the callback
	#_lobby.connect("lobby_finished", self, "_end_lobby", [], CONNECT_DEFERRED)
	#get_tree().get_root().add_child(_lobby)
	#hide()
	pass

func _on_end_about():
	_fsm.set_state_main()

func _on_end_lobby():
	if (_lobby != null): 
		if (has_node(_lobby.get_path())):
			get_node(_lobby.get_path()).queue_free()
		_lobby = null
	
	_fsm.set_state_main()

func _on_end_settings():
	_fsm.set_state_main()

func _on_line_name_text_changed(new_text):
	var text = _main_container.find_node("line_name").get_text()
	if (text == _user.name):
		return
	
	if (_validate_name(text)):
		_user.name = text
		_fsm.user_name().set_state_dirty()
		return
	
	_fsm.user_name().set_state_empty()

func _validate_name(name):
	var regex = _regExLib.get("name")
	return regex.search(name) != null

#### State
func _on_state_changed(state_from, state_to, args):
	_fsm._print_state(state_from, state_to, args)
	if (state_to == _fsm.About):
		show()
		_about_container.show()
		_main_container.hide()
		_settings_container.hide()
		return
	
	if (state_to == _fsm.Lobby):
		hide()
		return
	
	if (state_to == _fsm.Settings):
		show()
		_about_container.hide()
		_main_container.hide()
		_settings_container.show()
		return
	
	show()
	_about_container.hide()
	_main_container.show()
	_settings_container.hide()

func _on_state_user_name_changed(state_from, state_to, args):
	_fsm.user_name()._print_state(state_from, state_to, args)
	if (state_to == _fsm.user_name().Complete):
		_main_container.find_node("button_ok").set_disabled(true)
		_main_container.find_node("button_start").set_disabled(false)
		_main_container.find_node("button_mutiplayer").set_disabled(false)
	elif (state_to == _fsm.user_name().Dirty):
		_main_container.find_node("button_ok").set_disabled(false)
		_main_container.find_node("button_start").set_disabled(true)
		_main_container.find_node("button_mutiplayer").set_disabled(true)
	else:
		_main_container.find_node("button_ok").set_disabled(true)
		_main_container.find_node("button_start").set_disabled(true)
		_main_container.find_node("button_mutiplayer").set_disabled(true)

func _ready():
	_regExLib = regExLib.new()
	_user = load("res://user.gd").new()
	
	_fsm = state.new()
	_fsm.initialize(self)
	_fsm.set_state_main()
	
	_load_settings()
	if (_validate_name(_user.name)):
		_fsm.user_name().set_state_complete()
	
	_about_container.connect("about_finished", self, "_on_end_about")
	_settings_container.connect("settings_finished", self, "_on_end_settings")
	_main_container.find_node("line_name").connect("text_changed", self, "_on_line_name_text_changed")
	
	# Dumb - issues with size of label
	_main_container.find_node("button_ok").set_text(tr("MAIN_MENU_BUTTON_OK"))
	
	_main_container.find_node("label_version").set_text(tr("MAIN_MENU_VERSION") + " " + Constants.VERSION)
	
	OS.window_position = (OS.get_screen_size() * 0.5 - OS.window_size * 0.5)

class state_user_name extends "res://fsm/menu_fsm.gd":
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
		set_name("main_menu_user_name")
		
		add_state(Complete)
		add_state(Empty)
		
		connect_state_changed(parent, "_on_state_user_name_changed")

class state extends "res://fsm/menu_fsm.gd":
	const About = "about"
	const Lobby = "lobby"
	const Main = "main"
	const Settings = "settings"
	
	var _fsm
	
	func user_name():
		return _fsm
	
	func is_state_about():
		return is_state(About)
		
	func is_state_lobby():
		return is_state(Lobby)
		
	func is_state_main():
		return is_state(Main)
		
	func is_state_settings():
		return is_state(Settings)
	
	func set_state_about():
		set_state(About)
	
	func set_state_lobby():
		set_state(Lobby)
	
	func set_state_main():
		set_state(Main)
	
	func set_state_settings():
		set_state(Settings)
	
	func _initialize(parent):
		._initialize(parent)
		set_name("main_menu menu")
		
		add_state(About)
		add_state(Lobby)
		add_state(Main)
		add_state(Settings)
		
		connect_state_changed(parent, "_on_state_changed")
		
		_fsm = state_user_name.new()
		_fsm.initialize(parent)
	#	_fsm.connect_state_changed(self, "_on_state_user_name_changed")
		_fsm.set_state_empty()

class regExLib extends "res://utility/regExLib.gd":
	func _initialize():
		._initialize()
		_add_pattern_single("name", Constants.REGEX_PLAYER_NAME + Constants.REGEX_PLAYER_NAME_LENGTH)
