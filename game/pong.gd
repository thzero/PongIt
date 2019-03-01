extends "res://game/game.gd"

const SIDES = preload("res://game/sides.gd")

export var SCORE_TO_WIN = 2 #10
export var BALL_BOUNCE = 1.1
export var BALL_SPEED = 100
export var PADDLE_SPEED = 150

var score_left = 0
var score_right = 0

sync func finished(left, right, winner):
	update_score(left, right)
	
	if (winner == SIDES.left):
		get_node("winner_left").show()
	elif (winner == SIDES.right):
		get_node("winner_right").show()
	
	get_node("button_exit").show()

master func score(side):
	if (!get_tree().is_network_server()):
		return
	
	if (side == SIDES.left):
		score_left += 1
	elif (side == SIDES.right):
		score_right += 1
		
	var game_ended = false
	var winner = SIDES.left
	
	if (score_left == SCORE_TO_WIN):
		game_ended = true
		winner = SIDES.left
	elif (score_right == SCORE_TO_WIN):
		game_ended = true
		winner = SIDES.right
		
	if (game_ended):
		get_node("ball").rpc("game_finished")
		rpc("finished", score_left, score_right, winner)
		return
		
	rpc("update_score", score_left, score_right)

sync func update_score(left, right):
	get_node("score_left").set_text(str(left))
	get_node("score_right").set_text(str(right))

func _on_button_exit_pressed():
	end_game()

func _ready():
	._ready()
	
	var left = get_node("left")
	var right = get_node("right")
	
	# by default, all nodes in server inherit from master
	# while all nodes in clients inherit from slave
	if (get_tree().is_network_server()):		
		# if in the server, give control of player 2 to the other peer, 
		# this function is tree recursive by default
		right.set_network_master(get_tree().get_network_connected_peers()[0])
	else:
		# if in the client, give control of player 2 to itself, 
		# this function is tree recursive by default
		right.set_network_master(get_tree().get_network_unique_id())
	
	get_node("winner_left").hide()
	get_node("winner_right").hide()
	
	update_score(0, 0)
