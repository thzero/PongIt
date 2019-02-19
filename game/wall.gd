extends Area2D

const SIDES = preload("res://game/sides.gd")

export var side = SIDES.left

func _on_wall_area_entered(area):
	if area.get_name() != "ball":
		return

	if (!get_tree().is_network_server()):
		return
	
	_wall_floor_ceiling(area)
	_wall_left_right(area)

func _wall_floor_ceiling(area):
	if (!((side == SIDES.top) || (side == SIDES.bottom))):
		return
	
	area.rpc("bounce_side", side)
	
func _wall_left_right(area):
	if (!((side == SIDES.left) || (side == SIDES.right))):
		return
	
	area.rpc("reset", side)
	get_parent().rpc("score", side)