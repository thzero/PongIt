extends Node

const CHAT_TYPES = preload("res://chat/types.gd")

func message(player, message, type, args, text):
	if ((player == null) || (text == null)):
		return
	
	var name = player.name;
	if (player == Gamestate.get_player()):
		name = tr("CHAT_YOU")
	
	if (type == Gamestate.CHAT_TYPES.General):
		_message_general(name, message, text)
		return
	
	if (type == Gamestate.CHAT_TYPES.PrePackaged):	
		_message_pre_packaged(name, message, args, text)
		return
	
	if (type == Gamestate.CHAT_TYPES.Whisper):
		_message_whisper(name, message, text)
		return
		
	_message_handle_other(player, message, type, args, text)

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

func _message_whisper(name, message, text):
	if (text == null):
		return
	
	text.add_text(name + " " + tr("CHAT_WHISPER_ACTION") + " \"" + message + "\"\n")
