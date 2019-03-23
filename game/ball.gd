extends "res://base/syncableRigidBody2D.gd"

const enums = preload("res://game/enums.gd")
const wall_class = preload("res://game/wall.gd")

var _collision_shape
var _direction = Vector2(-1, 0)
var _initial_pos
var _speed = 0
var _stopped = false

sync func game_finished():
	reset(true)

sync func launch(side):
	reset(false)
	show()
	call_deferred('_enable_collision', true)
	
	if (!get_tree().is_network_server()):
		return
	
	var direction = Vector2(-1, 0) if side == enums.SIDES.left else Vector2(1, 0)
	var impulse = direction * _speed * 2
	apply_impulse(Vector2(0, 0), impulse)

func reset(value):
	_stopped = value

func _enable_collision(value):
	_collision_shape.disabled = !value

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
	
	if (!get_tree().is_network_server()):
		_integrate_forces_transform(state)
		return
	
	for i in range(state.get_contact_count()):
		var cc = state.get_contact_collider_object(i)
		var dp = state.get_contact_local_normal(i)
		
		if !cc:
			return
			
		if !(cc is wall_class):
			return
		
		call_deferred('_enable_collision', false)
		hide()
		_reset(state)
		
		get_parent().rpc("score", cc.side)

func _physics_process(delta):
	if (!get_tree().is_network_server()):
		return
	
	_process_send(delta)

func _ready():
	_speed = get_parent().BALL_SPEED
	_collision_shape = find_node('collision')
	_initial_pos = get_global_transform().origin
