extends StaticBody2D

const enums = preload("res://game/enums.gd")

export var side = enums.SIDES.left

func is_scoreable():
	return ((side == enums.SIDES.left) || (side == enums.SIDES.right))