extends Area2D

const enums = preload("res://game/enums.gd")

export var side = enums.SIDES.left

func _on_wall_area_entered(area):
	if area.get_name() != "ball":
		return

	if (!get_tree().is_network_server()):
		return
	
	_wall_floor_ceiling(area)
	_wall_left_right(area)

func _wall_floor_ceiling(area):
	if (!((side == enums.SIDES.top) || (side == enums.SIDES.bottom))):
		return
	
	area.rpc("bounce_side", side)
	
func _wall_left_right(area):
	if (!((side == enums.SIDES.left) || (side == enums.SIDES.right))):
		return
	
	area.rpc("reset", side)
	get_parent().rpc("score", side)