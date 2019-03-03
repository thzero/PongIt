extends Reference

var _gamestate
var _handler_print = preload("res://utility/print.gd").new()

func get_player(selector):
	if ((selector == null) || (selector == "")):
		return null
	
	var player_id
	var playerT = null
	var players = _gamestate.get_player_list(false)
	for peer_id in players:
		player_id = peer_id
		playerT  = _gamestate.get_player_by_id(peer_id)
		# TODO
		if ((playerT != null) && (playerT.name.to_lower() == selector.to_lower())):
			break
	
	if (playerT != null):
		return { "player" : playerT, "id": player_id }
		
	return null

func initialize(gamestate):
	_gamestate = gamestate

func _print(method, args):
	if (_handler_print == null):
		return

	_handler_print.output(method, args)