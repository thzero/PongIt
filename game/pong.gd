extends "res://base/game.gd"

const enums = preload("res://game/enums.gd")

export var SCORE_TO_WIN = 2 #10
export var BALL_BOUNCE = 1.1
export var BALL_SPEED = 100
export var PADDLE_SPEED = 500

const COUNTDOWN_LENGTH = 5

var _timer
var _countdown = COUNTDOWN_LENGTH
var score_left = 0
var score_right = 0
var _last_scored = enums.SIDES.none
var _game_started = false

sync func finish(left, right, winner):
	get_node("ball").reset(true)
	get_node("left").reset(true)
	get_node("right").reset(true)
	
	update_score(left, right)
	
	if (winner == enums.SIDES.left):
		find_node("winner_left").show()
	elif (winner == enums.SIDES.right):
		find_node("winner_right").show()
	
	find_node("button_exit").show()

sync func reset(side):
	if (!_game_started):
		_game_started = true
		start_game()
	
	get_node("ball").reset(true)
	get_node("left").reset(true)
	get_node("right").reset(true)
	
	if (get_tree().is_network_server()):
		_timer.start()

master func score(side):
	if (!get_tree().is_network_server()):
		return
	
	if (side == enums.SIDES.left):
		score_right += 1
		_last_scored = enums.SIDES.right
	elif (side == enums.SIDES.right):
		score_left += 1
		_last_scored = enums.SIDES.left
	
	rpc("update_score", score_left, score_right)
	
	var game_ended = false
	var winner = enums.SIDES.none
	
	if (score_left == SCORE_TO_WIN):
		game_ended = true
		winner = enums.SIDES.left
	elif (score_right == SCORE_TO_WIN):
		game_ended = true
		winner = enums.SIDES.right
	
	if (game_ended):
		rpc("finish", score_left, score_right, winner)
		return
	
	_reset()

sync func start(side):
	find_node("countdown").hide()
	get_node("left").reset(false)
	get_node("right").reset(false)
	get_node("ball").launch(_last_scored)

sync func update_countdown(countdown):
	find_node("countdown").show()
	find_node("countdown").set_text(str(countdown))

sync func update_score(left, right):
	find_node("score_left").set_text(str(left))
	find_node("score_right").set_text(str(right))

func _on_button_exit_pressed():
	end_game()

func _on_timer_timeout():
	_countdown -= 1
	
	if (_countdown > 0):
		rpc("update_countdown", _countdown)
		return
	rpc("update_countdown", _countdown)
	
	_timer.stop()
	rpc("start", _last_scored)

func _reset():
	if (!get_tree().is_network_server()):
		return
	
	_last_scored = enums.SIDES.none
	_countdown = COUNTDOWN_LENGTH
	
	rpc("reset", _last_scored)

func _ready():
	._ready()
	
	var window_size = OS.get_window_size()
	
	randomize()
	
#	var t = get_transform()
#	t.x = 500
#	t.y = 500
#	set_transform(t)
	var vector = Vector2(500, 500)
#	translate (vector)
	
	var left = get_node("left")
	var right = get_node("right")
	var ball = get_node("right")
#	left.init(vector)
#	right.init(vector)
#	ball.init(vector)
	
	# by default, all nodes in server inherit from master
	if (get_tree().is_network_server()):
		# if in the server, give control of player 2 to the other peer, 
		# this function is tree recursive by default
		right.set_network_master(get_tree().get_network_connected_peers()[0])
	else:
		# if in the client, give control of player 2 to itself, 
		# this function is tree recursive by default
		right.set_network_master(get_tree().get_network_unique_id())
	
	find_node("winner_left").hide()
	find_node("winner_right").hide()
	
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
