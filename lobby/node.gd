extends Node

func connect_finished(target, method):
	get_node("panel").connect("lobby_finished", target, method, [], CONNECT_DEFERRED)

func _ready():
	pass
