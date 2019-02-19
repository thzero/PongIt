extends Node2D

var _accumulator = 0

signal game_finished()

sync func end_game():
	emit_signal("game_finished")
	
remote func ping(delta):
	#print("ping " + str(delta))
	pass

func _process(delta):
	_accumulator += delta
	if (_accumulator > 1):
		rpc_unreliable("ping", _accumulator)
		_accumulator = 0
	
func _ready():
	randomize()
	print("unique id: ", get_tree().get_network_unique_id())
