extends Reference

const CHAT_TYPES = preload("res://chat/types.gd")

var _history = []
var _history_current = 0
var _regex

func history():
	if ((_history_current < 0) || (_history_current >= _history.size())):
		return ""
	
	return _history[_history_current]

func handle(player, message, type, args, text):
	if ((player == null) || (text == null)):
		return
	
	var name = player.name;
	if (player == Gamestate.get_player()):
		name = tr("CHAT_YOU")
	
	if (type == Gamestate.chat_types().General):
		_message_general(name, message, text)
		return
	
	if (type == Gamestate.chat_types().PrePackaged):	
		_message_pre_packaged(name, message, args, text)
		return
	
	if (type == Gamestate.chat_types().Whisper):
		_message_whisper(name, message, args, text)
		return
		
	_message_handle_other(player, message, type, args, text)

func increment(direction):
	if (direction):
		_history_current += 1
	else:
		_history_current -= 1
	
	if (_history_current >= _history.size()):
		_history_current = 0
	
	if (_history_current < 0):
		_history_current = _history.size() - 1
	
	return _history_current

func message(message):
	var regexM = _regex.get("message")
	var result = regexM.search(message)
	if (result == null):
		return FAILED
	
	var type = Gamestate.chat_types().General
	var args = null
	
	_history.push_front(message)
	if (_history.size() >= Constants.CHAT_HISTORY_LENGTH):
		_history.resize(Constants.CHAT_HISTORY_LENGTH)
	_reset_history()
	
	var command = result.get_string("command")
	var selector = result.get_string("selector")
	message = result.get_string("message")
	
	var valid = true
	var regexC = _regex.get("command_whisper")
	result = regexC.search(command)
	if (result != null):
		if ((selector == null) || (selector == "")):
			return FAILED
		var resultS = Gamestate.get_player_by_selector(selector)
		if (resultS != null):
			type = Gamestate.chat_types().Whisper
			args = resultS.id
		else:
			valid = false
	
	if (!valid):
		return FAILED
	
	Gamestate.chat(message, type, args)

func _message_general(name, message, text):
	if (text == null):
		return
	
	text.add_text(name + " " + tr("CHAT_GENERAL_ACTION") + " \"" + message + "\"\n")

func _message_handle_other(player, message, type, args, text):
	pass

func _message_pre_packaged(name, message, args, text):
	if (text == null):
		return
	
	# TODO: Pre-packaged!
	pass

func _message_whisper(name, message, args, text):
	if (text == null):
		return
	
	var action = tr("CHAT_WHISPER_ACTION")
	var output = ""
	if ((args!= null) && (args.id_from == Gamestate.get_player_id())):
		var player = '' if args.player_to == null else args.player_to.name
		output = tr("CHAT_MESSAGE_SELF") % [ tr("CHAT_YOU"), action, message, player ]
	else:
		output = tr("CHAT_MESSAGE") % [ name, action, message, ]
	
	#text.add_text(name + " " + action + " \"" + message + "\"" + other + "\n")
	text.add_text(output + "\n")

func _reset_history():
	_history_current = -1

func _init():
	_regex = regExLib.new()

class regExLib extends "res://utility/regExLib.gd":
	func _initialize():
		._initialize()
		var selector = Constants.REGEX_PLAYER_NAME
		_add_pattern_single("message", "(\\/(?<command>\\w+) (?<selector>" + selector + "+) )?(?<message>.+)")
		_add_pattern_single("command_whisper", "msg|w")
