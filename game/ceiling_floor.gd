extends Area2D

func _on_area_entered(area):
	if area.get_name() != "ball":
		return
	
	if (!get_tree().is_network_server()):
		return
	
	area.rpc("bounce_side")
