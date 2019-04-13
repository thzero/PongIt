extends Reference

const CHAT_TYPES = preload("res://chat/types.gd")

var _gamestate
var _handler_print = preload("res://utility/print.gd").new()

func message(id, message, type, args):
	if ((type == CHAT_TYPES.Whisper) && (typeof(args) == TYPE_INT)):
		var player_from = _gamestate.get_player_by_id(args)
		_gamestate.chat_message_emit(_gamestate.get_player(), message, CHAT_TYPES.Whisper, { "player_to" : player_from, "id_from" : id })
		_gamestate.chat_message_send(id, message, CHAT_TYPES.Whisper, null, args)
		return
	
	if (type == CHAT_TYPES.General):
		_gamestate.chat_message_send(id, message, CHAT_TYPES.General, null, null)
		return
	
	if (type == CHAT_TYPES.PrePackaged):
		_gamestate.chat_message_send(id, message, CHAT_TYPES.PrePackaged, args, null)
		return
	
	_gamestate.chat_message_send(id, message, type, args, null)

func initialize(gamestate):
	_gamestate = gamestate

func _print(method, args):
	if (_handler_print == null):
		return
	
	_handler_print.output(method, args)