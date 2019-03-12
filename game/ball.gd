extends RigidBody2D

const SIDES = preload("res://game/sides.gd")
const wall_class = preload("res://game/wall.gd")

var _direction = Vector2(-1, 0)
var _stopped = false

var _ball_speed = 0

var _initial_pos
var _collision_shape

sync func game_finished():
	_stopped = true

sync func reset(side):
	print('reset ball!! ' + str(side))
	
	show()
	
#	set_mode(RigidBody.MODE_RIGID)
	_collision_shape.disabled = false
	
	var direction = Vector2(-1, 0) if side == SIDES.left else Vector2(1, 0)
	var impulse = direction * _ball_speed * 2
	apply_impulse(Vector2(0, 0), impulse)

func _reset(state):
	linear_velocity = Vector2(0, 0)
	angular_velocity = 0

	var t = state.get_transform()
	t.origin.x = _initial_pos.x
	t.origin.y = _initial_pos.y
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
