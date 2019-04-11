extends Node

signal rtt_update()

var _gamestate = null

var _accumulator = 0
var _interval = Constants.PING_DELAY #healthCheckInterval

var _rtt = 0
var _moving_rtt_average = 0
var _moving_rtt_average_frame = []
var _moving_frame_size = Constants.PING_RTT_SAMPLE

remote func ping_query(id, delta, rtt, moving_rtt_average):
	print("ping: " + str(delta) + "rtt: " + str(rtt) + " rtt_average: " + str(moving_rtt_average))
	rpc_id(id, "ping_receive", OS.get_ticks_msec())

remote func ping_receive(ticks_msec):
	_rtt = OS.get_ticks_msec() - ticks_msec;
	
	_moving_rtt_average_frame.push_back(_rtt);
	if (_moving_rtt_average_frame.size() > _moving_frame_size):
		_moving_rtt_average_frame.pop_front()
	
	var average = 0
	for rtt_average_frame in _moving_rtt_average_frame:
		average += rtt_average_frame
	
	_moving_rtt_average = average / _moving_rtt_average_frame.length
	
	emit_signal("rtt_update", { "rtt": rtt, "rtt_average": _moving_rtt_average })
	
	print("rtt: " + str(_rtt) + " rtt_average: " + str(_moving_rtt_average))

func initialize(gamestate):
	_gamestate = gamestate

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
	if (_accumulator > Constants.PING_DELAY):
		_accumulator = 0
		var id = _gamestate.get_player_id()
		rpc_id(1, "ping_query", id, _accumulator, _rtt, _moving_rtt_average)
