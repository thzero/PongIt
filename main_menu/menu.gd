extends Control

var _fsm
var _user
var _lobby
var _regExLib

func _end_lobby():
	if ((_lobby != null) && has_node(_lobby.get_path())):
		# remove scene
		## erase immediately, otherwise network might show errors (this is why we connected deferred above)
		#get_node(_lobby.get_path()).free()
		get_node(_lobby.get_path()).queue_free()
		show()
	
	_lobby = null

func _load_settings():
	get_node("panel/line_name").text = ConfigurationUser.Settings.User.Name
	
	_user.name = ConfigurationUser.Settings.User.Name

func _on_button_exit_pressed():
	get_tree().quit()

func _on_button_ok_pressed():
	if (_validate_name(_user.name)):
		_fsm.set_state_complete()
		ConfigurationUser.update_settings(_user)
		return

func _on_button_mutiplayer_pressed():
	_lobby = load(Constants.PATH_LOBBY).instance()
	_lobby.connect("lobby_finished", self, "_end_lobby")
	get_tree().get_root().add_child(_lobby)
	_lobby.open_menu()
	hide()

func _on_button_settings_pressed():
	get_node("settings").open()

func _on_button_start_pressed():
	#_lobby = load("res://lobby.tscn").instance()
	## connect deferred so we can safely erase it from the callback
	#_lobby.connect("lobby_finished", self, "_end_lobby", [], CONNECT_DEFERRED)
	#get_tree().get_root().add_child(_lobby)
	#hide()
	pass

func _on_line_name_text_changed(new_text):
	var text = get_node("panel/line_name").get_text()
	if (text == _user.name):
		return
	
	if (_validate_name(text)):
		_user.name = text
		_fsm.set_state_dirty()
		return
	
	_fsm.set_state_empty()

func _validate_name(name):
	var regex = _regExLib.get("name")
	return regex.search(name) != null
#	return (name.length() > 3)

#### State
func _on_state_changed(state_from, state_to, args):
	print("switched to state: ", state_to)
	if (state_to == _fsm.Complete):
		get_node("panel/button_ok").set_disabled(true)
		get_node("panel/button_start").set_disabled(false)
		get_node("panel/button_mutiplayer").set_disabled(false)
	elif (state_to == _fsm.Dirty):
		get_node("panel/button_ok").set_disabled(false)
		get_node("panel/button_start").set_disabled(true)
		get_node("panel/button_mutiplayer").set_disabled(true)
	else:
		get_node("panel/button_ok").set_disabled(true)
		get_node("panel/button_start").set_disabled(true)
		get_node("panel/button_mutiplayer").set_disabled(true)

func _ready():
	_regExLib = regExLib.new()
	_user = load("res://user.gd").new()
	
	_fsm = state.new()
	_fsm.init()
	_fsm.connect_state_changed(self, "_on_state_changed")
	_fsm.set_state_empty()
	
	_load_settings()
	
	if (_validate_name(_user.name)):
		_fsm.set_state_complete()
		
	get_node("panel/line_name").connect("text_changed", self, "_on_line_name_text_changed")
	
	OS.window_position = (OS.get_screen_size() * 0.5 - OS.window_size * 0.5)
	
	# Dumb - issues with size of label
	get_node("panel/button_ok").set_text(tr("MAIN_MENU_BUTTON_OK"))
	
	get_node("panel/label_version").set_text(tr("MAIN_MENU_VERSION") + " " + Constants.VERSION)

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

class regExLib extends "res://utility/regExLib.gd":
	func _init():
		._init()
		_add_pattern_single("name", Constants.REGEX_PLAYER_NAME + Constants.REGEX_PLAYER_NAME_LENGTH)
