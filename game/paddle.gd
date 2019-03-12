extends RigidBody2D

const SIDES = preload("res://game/sides.gd")

export var side = SIDES.left

var _paddle_speed = 0;

#synchronize position and speed to the other peers
#slave func set_position_and_motion(p_position, p_motion):
#	position = p_position
#	motion = p_motion

func _process(delta):
	var velocity = Vector2(0, 0)
#	if (is_network_master()):
	if (Input.is_action_pressed("move_up")):
		velocity = Vector2(0, -1 * MOVE_SPEED)
	elif (Input.is_action_pressed("move_down")):
		velocity = Vector2(0, MOVE_SPEED)

	apply_impulse(Vector2(0,0), velocity * 500)

	# using unreliable to make sure position is updated as fast as possible, 
	# even if one of the calls is dropped
	#rpc_unreliable("set_position_and_motion", position, motion)

#	translate(Vector2(0, motion * delta))

#	# set screen limits
#	var pos = position
#	if (pos.y < 0):
#		position = Vector2(pos.x, 0) 
#	elif (pos.y > get_viewport_rect().size.y):
#		position = Vector2(pos.x, get_viewport_rect().size.y)

#func _on_paddle_area_entered(area):
#	if (area.get_name() != "ball"):
#		return
#
#	if (!is_network_master()):
#		return
#
#	var rand = randf()
#	print("side: " + str(side) + " rand: " + str(rand))
#	area.rpc("bounce_paddle", side, rand) #random for new direction generated on each peer

func _ready():
	_paddle_speed = get_parent().PADDLE_SPEED

