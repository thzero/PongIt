extends RigidBody2D

const SIDES = preload("res://game/sides.gd")

var _direction = Vector2(-1, 0)
var _stopped = false

var _ball_speed = 0

#onready var _initial_pos = self.position
var _initial_pos
var _collision_shape

#sync func bounce_paddle(side, random):
#	if (!((side == SIDES.left) || (side == SIDES.right))):
#		return
#
#	#using sync because both players can make it bounce
#	_speed *= _ball_bounce
#
#	print("bounce_paddle - side: " + str(side) + " random: " + str(random), " direction: " + str(_direction))
#	if (side == SIDES.left):		
#		_direction.x = abs(_direction.x)
#	elif (side == SIDES.right):
#		_direction.x = -abs(_direction.x)
#	print("bounce_paddle - side: " + str(side) + " random: " + str(random), " direction: " + str(_direction))
#
#	_direction.y = random * 2.0 - 1
#	_direction = _direction.normalized()
#	print("bounce_paddle - side: " + str(side) + " random: " + str(random), " direction: " + str(_direction))
#
#sync func bounce_side(side):
#	if (!((side == SIDES.top) || (side == SIDES.bottom))):
#		return
#
#	#using sync because both players can make it bounce
#	_speed *= _ball_bounce
#
#	print("bounce_side - side: " + str(side) + " direction: " + str(_direction))
#	_direction.y = -_direction.y
#	print("bounce_side - side: " + str(side) + " direction: " + str(_direction))
#	_direction = _direction.normalized()
#	print("bounce_side - side: " + str(side) + " direction: " + str(_direction))

sync func game_finished():
	_stopped = true

sync func reset(side):
	print('reset ball!! ' + str(side))
	
	_direction = Vector2(-1, 0) if side == SIDES.left else Vector2(1, 0)
	
	show()
	
#	set_mode(RigidBody.MODE_RIGID)
	_collision_shape.disabled = false
	
	var impulse = direction * _ball_speed * 2
	apply_impulse(Vector2(0, 0), impulse)

#func _process(delta):
#	if (_stopped):
#		return
#
#	#if (get_tree().is_network_server()):
#	#	var position = _direction * _speed * delta
#
#	# ball will move normally for both players
#	# even if it's sightly out of sync between them
#	# so each player sees the motion as smooth and not jerky
#	translate(_direction * _speed * delta)

func _reset(state):
	linear_velocity = Vector2(0, 0)
	angular_velocity = 0

	var t = state.get_transform()
	t.origin.x = initial_pos.x
	t.origin.y = initial_pos.y
	state.set_transform(t)

func _integrate_forces(state):
	var lv = state.get_linear_velocity()
	var step = state.get_step()
	
	if (_stopped):
		_reset(state)
		return
#
	for i in range(state.get_contact_count()):
		var cc = state.get_contact_collider_object(i)
		var dp = state.get_contact_local_normal(i)
		
		if !cc:
			return
			
		if !(cc is wall_class):
			return
		
		_collision_shape.disabled = true
		hide()
		
		_reset(state)
		
#		if (cc.wall_side == 0):
#			print('score for left')
#			direction = Vector2(1, 0)
#		elif (cc.wall_side == 1):
#			print('score for right')
#			direction = Vector2(-1, 0)
		
#		reset()
		get_parent().rpc("score", cc.wall_side)

func _ready():
	_ball_speed = get_parent().BALL_SPEED
	_initial_pos = get_global_transform().origin
	_collision_shape = find_node('collision')
