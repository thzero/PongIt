extends Spatial

signal game_ended()
signal game_started()

func init():
	var game = get_node("game")
	if (game == null):
		var viewport = get_node("Viewport")
		if (viewport == null):
			return
		
		game = load("res://game/pong.tscn").instance()
		game.set_name("game")
		viewport.add_child(game)
	
	if (game == null):
		return
		
	game.connect("game_ended", self, "_on_game_ended")
	game.connect("game_started", self, "_on_game_started")

func _init_viewport():
	# Get the viewport and clear it
	var viewport = get_node("Viewport")
	viewport.set_clear_mode(Viewport.CLEAR_MODE_ALWAYS)
	
	# Let two frames pass to make sure the vieport's is captured
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	
	# Retrieve the texture and set it to the viewport quad
	get_node("Viewport_quad").material_override.albedo_texture = viewport.get_texture()

func _on_game_ended():
	emit_signal("game_ended")

func _on_game_started():
	emit_signal("game_started")

func _ready():
	_init_viewport()
