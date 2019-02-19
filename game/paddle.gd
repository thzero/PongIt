extends Area2D

const SIDES = preload("res://game/sides.gd")

export var side = SIDES.left

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

		motion *= _paddle_speed
	
	# using unreliable to make sure position is updated as fast as possible, 
	# even if one of the calls is dropped
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
	
	if (!is_network_master()):
		return
	
	var rand = randf()
	print("side: " + str(side) + " rand: " + str(rand))
	area.rpc("bounce_paddle", side, rand) #random for new direction generated on each peer

func _ready():
	_paddle_speed = get_parent().PADDLE_SPEED

