extends Area2D

const SIDE = preload("res://side.gd")

var _direction = Vector2(-1, 0)
var _speed = 0
var _stopped = false

var _ball_bounce = 0
var _ball_speed = 0
var _bounce = 0

onready var initial_pos = self.position

func reset():
	position = initial_pos
	_speed = _ball_speed
	_direction = Vector2(-1, 0)

sync func stop():
	_stopped = true

func _process(delta):
	# ball will move normally for both players
	# even if it's sightly out of sync between them
	# so each player sees the motion as smooth and not jerky
	if (not _stopped):
		translate(_direction * _speed * delta) 
	
sync func bounce(side, random):
	#using sync because both players can make it bounce
	_speed *= _ball_bounce
	
	if (side == SIDE.left):		
		_direction.x = abs(_direction.x)
	else:
		_direction.x = -abs(_direction.x)
	
	_direction.y = random * 2.0 - 1
	_direction = _direction.normalized()

sync func bounce_side():
	#using sync because both players can make it bounce
	_speed *= _ball_bounce
	
	_direction.y = abs(_direction.y)
	_direction = _direction.normalized()

func _ready():
	_ball_bounce = get_parent().BALL_BOUNCE
	_ball_speed = get_parent().BALL_SPEED
	_speed = _ball_speed

