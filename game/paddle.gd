extends "res://base/pawnRigidBody2D.gd"

const enums = preload("res://game/enums.gd")
const MOVE_SPEED = 100

export var side = enums.SIDES.left

var _initial_pos
var _collision_shape
var _speed = 0;
var _stopped = true;

var _accumulator_movement = 0
var _inputs = []

func _create_packet():
	var packet = paddle_packet.new()
	return packet

sync func game_finished():
	reset(true)

func reset(value):
	_stopped = value

func _reset(state):
	linear_velocity = Vector2(0, 0)
	angular_velocity = 0
	
	var t = state.get_transform()
	t.origin.x = _initial_pos.x
	t.origin.y = _initial_pos.y
	state.set_transform(t)

func _integrate_forces(state):
	if (!is_network_master()):
		return
	
	if (_stopped):
		_reset(state)
		return
	
#	_integrate_forces_transform(state)

#func _physics_process(delta):
#	if (!is_network_master()):
#		return
#
##	_process_send(delta)

func _process(delta):
	if (!is_network_master()):
		return
	
	if (_stopped):
		return
	
	var action1 = Input.is_action_pressed("move_up")
	var action2 = Input.is_action_pressed("move_down")
	if (action1):
		#velocity = Vector2(0, -1 * MOVE_SPEED)
		_inputs.push_back(-1)
	elif (action2):
		#velocity = Vector2(0, MOVE_SPEED)
		_inputs.push_back(1)
	
	if (!(action1 || action2)):
		return
	
	_apply_input(delta)

func _apply_input(delta):
	# TODO
#	if (_is_player_local()):
#		var duration = 1.0 / _network_delay()
#		if (_accumulator_movement < duration):
#			_accumulator_movement += delta
#			return
#
#		_accumulator_movement = 0
		
	if (_inputs.size() == 0):
		return

	var direction = _inputs.pop_front()
	
	var velocity = Vector2(0, direction * MOVE_SPEED)
	apply_impulse(Vector2(0,0), velocity * _speed)

func _ready():
	_speed = get_parent().PADDLE_SPEED
	_collision_shape = find_node('collision')
	_initial_pos = get_global_transform().origin

class paddle_packet extends Reference:
	var position = null
	var angular_velocity = null
	var linear_velocity = null
