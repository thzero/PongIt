extends Node

var _stopped
var _accumulator_movement = 0
var _inputs = []

func _process(delta):
	if (!is_network_master()):
		return
	
#	_process_send(delta)
	
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
	
#	_apply_input(delta)