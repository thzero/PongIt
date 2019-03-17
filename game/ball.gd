extends Area2D

const enums = preload("res://game/enums.gd")

var _direction = Vector2(-1, 0)
var _speed = 0
var _stopped = false

var _ball_bounce = 0
var _ball_speed = 0
var _bounce = 0

onready var _initial_pos = self.position
	
sync func bounce_paddle(side, random):
	if (!((side == enums.SIDES.left) || (side == enums.SIDES.right))):
		return
	
	#using sync because both players can make it bounce
	_speed *= _ball_bounce

	print("bounce_paddle - side: " + str(side) + " random: " + str(random), " direction: " + str(_direction))
	if (side == enums.SIDES.left):		
		_direction.x = abs(_direction.x)
	elif (side == enums.SIDES.right):
		_direction.x = -abs(_direction.x)
	print("bounce_paddle - side: " + str(side) + " random: " + str(random), " direction: " + str(_direction))
	
	_direction.y = random * 2.0 - 1
	_direction = _direction.normalized()
	print("bounce_paddle - side: " + str(side) + " random: " + str(random), " direction: " + str(_direction))

sync func bounce_side(side):
	if (!((side == enums.SIDES.top) || (side == enums.SIDES.bottom))):
		return
	
	#using sync because both players can make it bounce
	_speed *= _ball_bounce
	
	print("bounce_side - side: " + str(side) + " direction: " + str(_direction))
	_direction.y = -_direction.y
	print("bounce_side - side: " + str(side) + " direction: " + str(_direction))
	_direction = _direction.normalized()
	print("bounce_side - side: " + str(side) + " direction: " + str(_direction))
	
sync func game_finished():
	_stopped = true

sync func reset(side):
	position = _initial_pos
	if (side == enums.SIDES.left):
		_direction = Vector2(-1, 0)
	elif (side == enums.SIDES.right):
		_direction = Vector2( 1, 0)

	_speed = _ball_speed

func _process(delta):
	if (_stopped):
		return
		
	#if (get_tree().is_network_server()):
	#	var position = _direction * _speed * delta
		
	# ball will move normally for both players
	# even if it's sightly out of sync between them
	# so each player sees the motion as smooth and not jerky
	translate(_direction * _speed * delta) 

func _ready():
	_ball_bounce = get_parent().BALL_BOUNCE
	_ball_speed = get_parent().BALL_SPEED
	_speed = _ball_speed

