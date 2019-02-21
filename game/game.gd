extends Node2D

signal game_ended()

func end_game():
	emit_signal("game_ended")
	
func _ready():
	randomize()
	print("unique id: ", get_tree().get_network_unique_id())
