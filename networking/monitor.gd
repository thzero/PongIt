extends Node

signal rtt_update()

var _gamestate = null

var _accumulator = 0
var _interval = Constants.PING_DELAY

var _fps = 0
var _moving_fps_average = 0
var _moving_fps_average_frame = []
var _moving_frame_size_fps = Constants.PING_SAMPLE_FPS

var _rtt = 0
var _moving_rtt_average = 0
var _moving_rtt_average_frame = []
var _moving_frame_size_rtt = Constants.PING_SAMPLE_RTT

remote func ping_query(delta, id, ticks_msec, rtt, moving_rtt_average, fps, moving_fps_average):
	print("server ping: " + str(delta) + " player: " + str(id) + " ticks_msec: " + str(ticks_msec) + 
		" rtt: " + str(rtt) + " moving_rtt_average: " + str(moving_rtt_average)+ 
		" fps: " + str(fps) + " moving_fps_average: " + str(moving_fps_average))
	# TODO: Add to player...
	rpc_id(id, "ping_receive", ticks_msec)

remote func ping_receive(ticks_msec):
	_gather_rtt(ticks_msec)
	emit_signal("rtt_update", _emit_package())

func initialize(gamestate):
	_gamestate = gamestate

func _emit_package():
	return { "rtt": _rtt, "rtt_average": _moving_rtt_average, "fps": _fps }

func _gather_fps():
	_fps = Engine.get_frames_per_second()
	
	_moving_fps_average_frame.push_back(_fps)
	if (_moving_fps_average_frame.size() > _moving_frame_size_fps):
		_moving_fps_average_frame.pop_front()
	
	var fps_average = 0
	for fps_average_frame in _moving_fps_average_frame:
		fps_average += fps_average_frame
	
	print("client fps_average: " + str(fps_average))
	
	if (_moving_fps_average_frame.size() > 0):
		_moving_fps_average = fps_average / _moving_fps_average_frame.size()
	else:
		_moving_fps_average = fps_average
	
	print("client moving_fps_average: " + str(_moving_fps_average))
	
func _gather_rtt(ticks_msec):
	var current_ticks_msec = OS.get_ticks_msec()
	_rtt = current_ticks_msec - ticks_msec
	
	print("client ticks_msec: " + str(ticks_msec) + " current_ticks_msec: " + str(current_ticks_msec), " rtt: " + str(_rtt))
	
	_moving_rtt_average_frame.push_back(_rtt)
	if (_moving_rtt_average_frame.size() > _moving_frame_size_rtt):
		_moving_rtt_average_frame.pop_front()
	
	var rtt_average = 0
	for rtt_average_frame in _moving_rtt_average_frame:
		rtt_average += rtt_average_frame
	
	print("client rtt_average: " + str(rtt_average))
	
	if (_moving_rtt_average_frame.size() > 0):
		_moving_rtt_average = rtt_average / _moving_rtt_average_frame.size()
	else:
		_moving_rtt_average = rtt_average
	
	print("client moving_rtt_average: " + str(_moving_rtt_average))

func process(delta):
	if (!Constants.PING_ENABLED):
		return
	
	if (Constants.PING_DELAY <= 0):
		return
	
	if (!get_tree().has_network_peer()):
		return
	
	if (_gamestate.get_player_id() == 1):
		return
	
	_accumulator += delta
	if (_accumulator < _interval):
		return
	
	_gather_fps()
	
	# Send from client to server with the current ticks
	var ticks_msec = OS.get_ticks_msec()
	print("client accumulator: " + str(_accumulator), " ticks_msec: " + str(ticks_msec), " fps: " + str(_fps))
	_accumulator = 0
	
	var id = _gamestate.get_player_id()
	rpc_id(1, "ping_query", _accumulator, id, ticks_msec, _rtt, _moving_rtt_average, _fps, _moving_fps_average)
