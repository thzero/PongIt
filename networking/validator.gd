extends Reference

var _gamestate
var _handler_print = preload("res://utility/print.gd").new()

func validate_address(address, error):
	if (error != null):
		error.set_text("")
	
	if (not address.is_valid_ip_address()):
		if (error != null):
			error.set_text(tr("LOBBY_MESSAGE_ADDRESS_INVALID"))
		return null
	
	return address

func validate_port(port, error):
	if (error != null):
		error.set_text("")
	
	var portN
	if (typeof(port) != TYPE_INT):
		if (typeof(port) == TYPE_STRING):
			if (not port.is_valid_integer()):
				if (error != null):
					error.set_text(tr("LOBBY_MESSAGE_PORT_INVALID"))
				return null
			else:
				portN = port.to_int();
		else:
			if (error != null):
				error.set_text(tr("LOBBY_MESSAGE_PORT_INVALID"))
			return null
	else:
		portN = port
		
	if (portN < 1024 || portN > 65535):
		if (error != null):
			error.set_text(tr("LOBBY_MESSAGE_PORT_INVALID_RANGE"))
		return null
		
	return portN

func validate_server_name(name, error):
	if (error != null):
		error.set_text("")
	
	if (name == ""):
		if (error != null):
			error.set_text(tr("LOBBY_MESSAGE_SERVER_NAME_INVALID"))
		return null
	
	return name

func initialize(gamestate):
	_gamestate = gamestate

func _print(method, args):
	if (_handler_print == null):
		return
