extends Control

var _fsm
var _fsm2
var _user
var _lobby
var _regExLib

func _initialize_lobby():
	return load(Constants.PATH_LOBBY).instance()

func _load_settings():
	get_node("main/line_name").text = ConfigurationUser.Settings.User.Name
	
	_user.name = ConfigurationUser.Settings.User.Name

func _on_button_about_pressed():
	_fsm.set_state_about()

func _on_button_exit_pressed():
	get_tree().quit()

func _on_button_ok_pressed():
	if (_validate_name(_user.name)):
		_fsm2.set_state_complete()
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
	var text = get_node("main/line_name").get_text()
	if (text == _user.name):
		return
	
	if (_validate_name(text)):
		_user.name = text
		_fsm2.set_state_dirty()
		return
	
	_fsm2.set_state_empty()

func _validate_name(name):
	var regex = _regExLib.get("name")
	return regex.search(name) != null

#### State
func _on_state_changed(state_from, state_to, args):
	print("switched to state: ", state_to)
	if (state_to == _fsm.About):
		show()
		get_node("about").show()
		get_node("main").hide()
		get_node("settings").hide()
	elif (state_to == _fsm.Lobby):
		hide()
	elif (state_to == _fsm.Settings):
		show()
		get_node("about").hide()
		get_node("main").hide()
		get_node("settings").show()
	else:
		show()
		get_node("about").hide()
		get_node("main").show()
		get_node("settings").hide()

func _on_state_changed2(state_from, state_to, args):
	print("switched to state: ", state_to)
	if (state_to == _fsm2.Complete):
		get_node("main/button_ok").set_disabled(true)
		get_node("main/button_start").set_disabled(false)
		get_node("main/button_mutiplayer").set_disabled(false)
	elif (state_to == _fsm2.Dirty):
		get_node("main/button_ok").set_disabled(false)
		get_node("main/button_start").set_disabled(true)
		get_node("main/button_mutiplayer").set_disabled(true)
	else:
		get_node("main/button_ok").set_disabled(true)
		get_node("main/button_start").set_disabled(true)
		get_node("main/button_mutiplayer").set_disabled(true)

func _ready():
	_regExLib = regExLib.new()
	_user = load("res://user.gd").new()
	
	_fsm = state.new()
	_fsm.initialize()
	_fsm.connect_state_changed(self, "_on_state_changed")
	_fsm.set_state_main()
	
	_fsm2 = state2.new()
	_fsm2.initialize()
	_fsm2.connect_state_changed(self, "_on_state_changed2")
	_fsm2.set_state_empty()
	
	_load_settings()
	if (_validate_name(_user.name)):
		_fsm2.set_state_complete()
	
	get_node("about").connect("about_finished", self, "_on_end_about")
	get_node("settings").connect("settings_finished", self, "_on_end_settings")
	get_node("main/line_name").connect("text_changed", self, "_on_line_name_text_changed")
	
	OS.window_position = (OS.get_screen_size() * 0.5 - OS.window_size * 0.5)
	
	# Dumb - issues with size of label
	get_node("main/button_ok").set_text(tr("MAIN_MENU_BUTTON_OK"))
	
	get_node("main/label_version").set_text(tr("MAIN_MENU_VERSION") + " " + Constants.VERSION)

class state extends "res://fsm/menu_fsm.gd":
	const About = "about"
	const Lobby = "lobby"
	const Main = "main"
	const Settings = "settings"
		
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
	
	func _initialize():
		._initialize()
		add_state(About)
		add_state(Lobby)
		add_state(Main)
		add_state(Settings)

class state2 extends "res://fsm/menu_fsm.gd":
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
	
	func _initialize():
		._initialize()
		add_state(Complete)
		add_state(Empty)

class regExLib extends "res://utility/regExLib.gd":
	func _initialize():
		._initialize()
		_add_pattern_single("name", Constants.REGEX_PLAYER_NAME + Constants.REGEX_PLAYER_NAME_LENGTH)
