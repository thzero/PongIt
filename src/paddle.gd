extends Area2D

const SIDE = preload("res://side.gd")

export var side = SIDE.left

var motion = 0
var _paddle_speed = 0;

#synchronize position and speed to the other peers
slave func set_position_and_motion(p_position, p_motion):
	position = p_position
	motion = p_motion

func _process(delta):
	var which = get_name()
		
	if (is_network_master()):		
		motion = 0
		if (Input.is_action_pressed("move_up")):
			motion -= 1
		elif (Input.is_action_pressed("move_down")):
			motion += 1

		#motion *= Constants.DEFAULT_PADDLE_SPEED
		motion *= _paddle_speed
	
	#using unreliable to make sure position is updated as fast as possible, even if one of the calls is dropped
	rpc_unreliable("set_position_and_motion", position, motion)
	
	translate(Vector2(0, motion * delta))
	
	# set screen limits
	var pos = position
	if (pos.y < 0):
		position = Vector2(pos.x, 0) 
	elif (pos.y > get_viewport_rect().size.y):
		position = Vector2(pos.x, get_viewport_rect().size.y)

func _on_paddle_area_entered(area):
	if (area.get_name() != "ball"):
		return
	
	#area.bounce(side)
	if (is_network_master()):
		area.rpc("bounce", side, randf()) #random for new direction generated on each peer

func _ready():
	_paddle_speed = get_parent().PADDLE_SPEED
	
	# by default, all nodes in server inherit from master
	# while all nodes in clients inherit from slave
	if (get_tree().is_network_server()):
		# if in the server, give control of player 2 to the other peer, 
		# this function is tree recursive by default
		get_node("right").set_network_master(get_tree().get_network_connected_peers()[0])
	else:
		# if in the client, give control of player 2 to itself, 
		# this function is tree recursive by default
		get_node("right").set_network_master(get_tree().get_network_unique_id())
	
	# TODO: set the side for each paddle, already set in scene so may not be necessary
	get_node("left").side = SIDE.left
	get_node("right").side = SIDE.right
	
	print("unique id: ", get_tree().get_network_unique_id())

