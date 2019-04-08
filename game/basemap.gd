extends Spatial

signal game_ended()
signal game_started()

var _game = null
var _viewport = null
var _viewport_quad = null

func _init_game():
	assert(_viewport != null)
	
	if (!has_node("game")):
		# TODO: Maybe not needed?  Should be part of the map...
		_game = load("res://game/pong.tscn").instance()
		_game.set_name("game")
		_viewport.add_child(_game)
	else:
		_game = get_node("game")
	
	assert(_game != null)
	
	_game.connect("game_ended", self, "_on_game_ended")
	_game.connect("game_started", self, "_on_game_started")

func _init_viewport():
	# Get the viewport and clear it
	_viewport.set_clear_mode(Viewport.CLEAR_MODE_ALWAYS)
	
	# Let two frames pass to make sure the vieport's is captured
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	# Retrieve the texture and set it to the viewport quad
	_viewport_quad.material_override.albedo_texture = _viewport.get_texture()

func _on_game_ended():
	emit_signal("game_ended")

func _on_game_started():
	emit_signal("game_started")

func _ready():
	_viewport = get_node("Viewport")
	assert(_viewport != null)
	
	_viewport_quad = get_node("ViewportQuad")
	assert(_viewport_quad != null)
	
	_init_game()
	
	_init_viewport()
