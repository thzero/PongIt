extends Node

signal rtt_update()

var _gamestate = null

var _accumulator = 0
var _interval = Constants.PING_DELAY #healthCheckInterval

var _query_id_counter = 0;
var _rtt_queries = {};

var _moving_rtt_average = 0;
var _moving_rtt_average_frame = [];
var _moving_fps_average_size = Constants.PRING_RTT_SAMPLE

master func ping_query(id, _query_id, delta):
	#print("ping " + str(delta))
	rpc_id(id, "ping_receive", _query_id)

remote func ping_receive(query_id):
	var rtt = OS.get_ticks_msec() - _rtt_queries[query_id];
	
	_moving_rtt_average_frame.push(rtt);
	if (_moving_rtt_average_frame.length > _moving_fps_average_size):
		_moving_rtt_average_frame.shift()
		
	var average = 0
	for rtt_average_frame in _moving_rtt_average_frame:
		average += rtt_average_frame
	
	_moving_rtt_average = average / _moving_rtt_average_frame.length
	
	emit_signal("rtt_update", { "rtt": rtt, "rtt_average": _moving_rtt_average })

func initialize(gamestate):
	_gamestate = gamestate

func process(delta):
	if (!Constants.PING_ENABLED):
		return
	
	if (Constants.PING_DELAY <= 0):
		return
	
	_accumulator += delta
	if (_accumulator > Constants.PING_DELAY):
		_accumulator = 0
		var id = _gamestate.get_player_id()
		_rtt_queries[_query_id_counter] = OS.get_ticks_msec()
		rpc_id(1, "ping_query", id, _query_id_counter, _accumulator)
		_query_id_counter += 1
