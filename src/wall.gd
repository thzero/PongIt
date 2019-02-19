extends Area2D

func _on_wall_area_entered( area ):
	if area.get_name() == "ball":
		#oops, ball went out of game place, reset
		area.reset()
		#if (is_network_master()):
			# only master will decide when the ball is out in the left side (it's own side)
			# this makes the game playable even if latency is high and ball is going fast
			# otherwise ball might be out in the other player's screen but not this one
			
		#	if (ball_pos.x < 0 ):
		#		get_parent().rpc("update_score", false)
		#		rpc("_reset_ball", false)
		#else:
			# only the slave will decide when the ball is out in the right side (it's own side)
			# this makes the game playable even if latency is high and ball is going fast
			# otherwise ball might be out in the other player's screen but not this one
			
		#	if (ball_pos.x > screen_size.x):
		#		get_parent().rpc("update_score", true)
		#		rpc("_reset_ball", true)
