extends Reference

const CHAT_TYPES = preload("res://chat/types.gd")

var _gamestate
var _handler_print = preload("res://utility/print.gd").new()

func message(id, message, type, args):
	if ((type == CHAT_TYPES.Whisper) && (typeof(args) == TYPE_INT)):
		var player_from = _gamestate.get_player_by_id(args)
		_gamestate.chat_message_emit(_gamestate.get_player(), message, CHAT_TYPES.Whisper, { "player" : player_from, "id" : get_tree().get_network_unique_id() })
		#rpc_id(args, "chat_send", get_tree().get_network_unique_id(), message, CHAT_TYPES.Whisper, null)
		_gamestate.chat_message_send(id, message, CHAT_TYPES.Whisper, null, args)
		return
	
	if (type == CHAT_TYPES.General):
		#rpc("chat_send", get_tree().get_network_unique_id(), message, CHAT_TYPES.General, null)
		_gamestate.chat_message_send(id, message, CHAT_TYPES.General, null, null)
		return
	
	if (type == CHAT_TYPES.PrePackaged):
		#rpc("chat_send", get_tree().get_network_unique_id(), message, CHAT_TYPES.PrePackaged, inst2dict(args))
		_gamestate.chat_message_send(id, message, CHAT_TYPES.PrePackaged, args, null)
		return
	
	#rpc("chat_send", get_tree().get_network_unique_id(), message, type, inst2dict(args))
	_gamestate.chat_message_send(id, message, type, args, null)
	
func initialize(gamestate):
	_gamestate = gamestate

func _print(method, args):
	if (_handler_print == null):
		return
	
	_handler_print.output(method, args)