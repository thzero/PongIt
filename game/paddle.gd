extends RigidBody2D

const enums = preload("res://game/enums.gd")
const MOVE_SPEED = 100

export var side = enums.SIDES.left

var _initial_pos
var _collision_shape
var _speed = 0;
var _stopped = true;

sync func game_finished():
	reset(true)

func reset(value):
	_stopped = value

#synchronize position and speed to the other peers
#slave func set_position_and_motion(p_position, p_motion):
#	position = p_position
#	motion = p_motion

func _reset(state):
	linear_velocity = Vector2(0, 0)
	angular_velocity = 0
	
	var t = state.get_transform()
	t.origin.x = _initial_pos.x
	t.origin.y = _initial_pos.y
	state.set_transform(t)

func _integrate_forces(state):
	if (_stopped):
		_reset(state)
		return

func _process(delta):
	if (!is_network_master()):
		return
	
	if (_stopped):
		return
	
	var velocity = Vector2(0, 0)
	var action1 = Input.is_action_pressed("move_up")
	var action2 = Input.is_action_pressed("move_down")
	if (action1):
		velocity = Vector2(0, -1 * MOVE_SPEED)
	elif (action2):
		velocity = Vector2(0, MOVE_SPEED)
	
	if (!(action1 || action2)):
		return
	
	apply_impulse(Vector2(0,0), velocity * _speed)
	
	# using unreliable to make sure position is updated as fast as possible, 
	# even if one of the calls is dropped
	#rpc_unreliable("set_position_and_motion", position, motion)

#	translate(Vector2(0, motion * delta))

func _ready():
	_speed = get_parent().PADDLE_SPEED
	_collision_shape = find_node('collision')
	_initial_pos = get_global_transform().origin

