extends Node2D

signal game_ended()
signal game_started()

func end_game():
	emit_signal("game_ended")

func start_game():
	emit_signal("game_started")

func _ready():
	randomize()
