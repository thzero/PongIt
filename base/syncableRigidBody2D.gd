extends RigidBody2D

const ALPHA = 0.1
const EPSILON = 0.0005
const STATE_EXPIRATION_TIME = 1.0 / 20.0
const SEND_RATE = 1.0 / 10
const DELAY = 1.0 / 3

var _packets = []
var _packet = null
var _packet_timer = 0

var _accumulator = 0

var _last_packet_received = null
var _last_packet_sent = null

var _seq = 0

puppet func send_packet(packet):
	_packet = packet
	_packet_timer = 0
	_packets.push_back(packet)
	
func _at_rest():
	if (_last_packet_sent == null):
		return false
	
	var at_rest = (_last_packet_sent.position == position)
	at_rest = at_rest && (_last_packet_sent.angular_velocity == angular_velocity)
	at_rest = at_rest && (_last_packet_sent.linear_velocity == linear_velocity)
	return at_rest

func _create_packet():
	return {}
	
func _init_packet(packet):
	packet.position = position
	packet.rotation = rotation
	
	packet.at_rest = _at_rest()
	
	if (!packet.at_rest):
		packet.angular_velocity = angular_velocity
		packet.linear_velocity = linear_velocity

func _integrate_forces_transform(state, packet):
	var transform = state.get_transform()
	var pos = _lerp_pos(transform.get_origin(), _packet.position, 1.0 - ALPHA)
	var rot = _slerp_rot(transform.get_rotation(), _packet.rotation, ALPHA)
	var x_axis = Vector2(cos(rot), -sin(rot))
	var y_axis = Vector2(sin(rot), cos(rot))
	state.set_transform(Transform2D(x_axis, y_axis, pos))
	
	var angular_velocity_temp = Vector2(0, 0)
	var linear_velocity_temp = Vector2(0, 0)
	if (!packet.at_rest):
		angular_velocity_temp = packet.angular_velocity
		linear_velocity_temp = packet.linear_velocity
	
	angular_velocity = angular_velocity_temp
	linear_velocity = linear_velocity_temp

func _integrate_forces_update(state):
	if (is_network_master()):
		return
	
	if ((_packet == null)): # || (_packet_timer > STATE_EXPIRATION_TIME)):
		return
		
	_packet_timer += state.get_step()
	
	if (_last_packet_received != null):
		if (_packet.seq < _last_packet_received.seq):
			return
	
	_last_packet_received = _packet
	
	_integrate_forces_transform(state, _packet)

# Lerp vector
func _lerp_pos(v1, v2, alpha):
#	https://en.wikipedia.org/wiki/Linear_interpolation
	return v1 * alpha + v2 * (1.0 - alpha)

func _network_delay():
	# TODO: determine network delay
	return 50

func _process_send(delta):
	if (!is_network_master()):
		return
	
	var duration = _send_rate()
	if (_accumulator < duration):
		_accumulator += delta
		return
	
	_accumulator = 0
	
	if (_last_packet_sent != null):
		var at_rest = _at_rest()
		if (at_rest):
			return
	
	var packet = _create_packet()
	packet.seq = _seq
	_seq += 1
	if (_seq > 10000):
		_seq = 0
	_init_packet(packet)
	
#	using unreliable to make sure position is updated as fast as possible, 
#	even if one of the calls is dropped
	rpc_unreliable("send_packet", packet)
	
	_last_packet_sent = packet

func _send_rate():
	return SEND_RATE #network_fps.get_value()

# Spherically linear interpolation of rotation
func _slerp_rot(r1, r2, alpha):
	var v1 = Vector2(cos(r1), sin(r1))
	var v2 = Vector2(cos(r2), sin(r2))
	var v = _slerp(v1, v2, alpha)
	return atan2(v.y, v.x)

# Spherical linear interpolation of two 2D vectors
func _slerp(v1, v2, alpha):
	var cos_angle = clamp(v1.dot(v2), -1.0, 1.0)
	
	if (cos_angle > 1.0 - EPSILON):
		return _lerp_pos(v1, v2, alpha).normalized()
	
	var angle = acos(cos_angle)
	var angle_alpha = angle * alpha
	var v3 = (v2 - (cos_angle * v1)).normalized()
	return v1 * cos(angle_alpha) + v3 * sin(angle_alpha)

func _integrate_forces_post(state):
	pass

func _integrate_forces_pre(state):
	pass

func _integrate_forces(state):
	_integrate_forces_pre(state)
	
	if (!is_network_master()):
		_integrate_forces_update(state)
	
	_integrate_forces_post(state)

func _physics_process_post(delta):
	pass

func _physics_process_pre(delta):
	pass

func _physics_process(delta):
	_physics_process_pre(delta)
	
	if (is_network_master()):
		_process_send(delta)
	
	_physics_process_post(delta)
