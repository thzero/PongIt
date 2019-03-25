extends RigidBody2D

const ALPHA = 0.1
const EPSILON = 0.0005
const SCALE_FACTOR = 25
const STATE_EXPIRATION_TIME = 1.0 / 20.0

var _packet = null
var _packet_timer = 0

var _accumulator = 0

var _last_packet = null

var _seq = 0

puppet func send_packet(packet):
	_packet = packet

func _create_packet():
	return {}
	
func _init_packet(packet):
	packet.position = position
	packet.rotation = rotation
	packet.angular_velocity = angular_velocity
	packet.linear_velocity = linear_velocity
	
func _network_delay():
	# TODO: determine network delay
	return 50

func _integrate_forces_transform(state, packet):
#	var pos = lerp_pos(transform.get_origin(), _packet.position, 1.0 - ALPHA)
#	var rot = slerp_rot(transform.get_rotation(), _packet.rotation, ALPHA)
#	var x_axis = Vector2(cos(rot), -sin(rot))
#	var y_axis = Vector2(sin(rot), cos(rot))
#	state.set_transform(Transform2D(x_axis, y_axis, pos))
	transform.origin = _packet.position

func _integrate_forces_update(state):
	if (_packet == null): # && (_packet < STATE_EXPIRATION_TIME)):
		return
	
	_packet_timer += state.get_step()
	var transform = state.get_transform()
	_integrate_forces_transform(state, _packet)
	
	linear_velocity = _packet.linear_velocity
	angular_velocity = _packet.angular_velocity
	
	state.set_transform(transform)

func _process_send(delta):
	var duration = 1.0 / 40 #network_fps.get_value()
	if (_accumulator < duration):
		_accumulator += delta
		return
	
	_accumulator = 0
	
	if (_last_packet != null):
		var at_rest = (_last_packet.position == position)
		at_rest = at_rest && (_last_packet.angular_velocity == angular_velocity)
		at_rest = at_rest && (_last_packet.linear_velocity == linear_velocity)
		if (at_rest):
			return
	
#	var packet = ["update", client.seq]
#	client.seq += 1
	var packet = _create_packet()
	packet.seq = _seq
	_seq += 1
	if (_seq > 10000):
		_seq = 0
	_init_packet(packet)
	_last_packet = packet
	
#	using unreliable to make sure position is updated as fast as possible, 
#	even if one of the calls is dropped
	rpc_unreliable("send_packet", packet)

# Lerp vector
func lerp_pos(v1, v2, alpha):
	return v1 * alpha + v2 * (1.0 - alpha)

# Spherically linear interpolation of rotation
func slerp_rot(r1, r2, alpha):
	var v1 = Vector2(cos(r1), sin(r1))
	var v2 = Vector2(cos(r2), sin(r2))
	var v = slerp(v1, v2, alpha)
	return atan2(v.y, v.x)

# Spherical linear interpolation of two 2D vectors
func slerp(v1, v2, alpha):
	var cos_angle = clamp(v1.dot(v2), -1.0, 1.0)
	
	if (cos_angle > 1.0 - EPSILON):
		return lerp_pos(v1, v2, alpha).normalized()
	
	var angle = acos(cos_angle)
	var angle_alpha = angle * alpha
	var v3 = (v2 - (cos_angle * v1)).normalized()
	return v1 * cos(angle_alpha) + v3 * sin(angle_alpha)