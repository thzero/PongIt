extends "res://game/game.gd"

const enums = preload("res://game/enums.gd")

export var SCORE_TO_WIN = 2 #10
export var BALL_BOUNCE = 1.1
export var BALL_SPEED = 100
export var PADDLE_SPEED = 5000

var _timer
var _countdown = 0

var score_left = 0
var score_right = 0
var _last_scored = enums.SIDES.none

sync func finished(left, right, winner):
	update_score(left, right)
	
	if (winner == enums.SIDES.left):
		get_node("winner_left").show()
	elif (winner == enums.SIDES.right):
		get_node("winner_right").show()
	
	get_node("button_exit").show()

sync func reset_ball(side):
	find_node("ball").reset(side)

master func score(side):
	if (!get_tree().is_network_server()):
		return
	
	_last_scored = side
	if (side == enums.SIDES.left):
		score_left += 1
	elif (side == enums.SIDES.right):
		score_right += 1
		
	var game_ended = false
	var winner = enums.SIDES.left
	
	if (score_left == SCORE_TO_WIN):
		game_ended = true
		winner = enums.SIDES.left
	elif (score_right == SCORE_TO_WIN):
		game_ended = true
		winner = enums.SIDES.right
	
	if (game_ended):
		get_node("ball").rpc("game_finished")
		rpc("finished", score_left, score_right, winner)
		return
		
	_reset()
		
	rpc("update_score", score_left, score_right)

sync func update_countdown(countdown):
	print('countdown ' + str(countdown))

sync func update_score(left, right):
	get_node("score_left").set_text(str(left))
	get_node("score_right").set_text(str(right))

func _on_button_exit_pressed():
	end_game()

func _on_timer_timeout():
	_countdown += 1
	
	if (_countdown < 5):
		rpc("update_countdown", _countdown)
		return
	
	_timer.stop()
	rpc("reset_ball", _last_scored)

func _reset():
	if (!get_tree().is_network_server()):
		return
	
	_last_scored = enums.SIDES.none
	_countdown = 0
	_timer.start()

func _ready():
	._ready()
	
	randomize()
	
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
	
	var rand = bool(randi() % 2)
	_last_scored = enums.SIDES.left if rand else enums.SIDES.right
	
	if (!get_tree().is_network_server()):
		return
	
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = 1
	add_child(_timer) 
	_timer.connect("timeout", self, "_on_timer_timeout") 

	_reset()
