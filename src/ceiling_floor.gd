extends Area2D

export var y_direction = 1

func _on_area_entered(area):
	if area.get_name() != "ball":
		return
	
	#area.bounce_side()
	if (get_tree().is_network_server()):
		area.rpc("bounce_side")
	