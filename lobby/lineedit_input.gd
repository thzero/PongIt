extends Node

signal input()

func _input(event):
	if (!(event is InputEventKey)):
		return
	
	if (!event.is_pressed()):
		return
	
	if (event.scancode == KEY_UP):
		emit_signal("input", event.scancode)
		return
	
	if (event.scancode == KEY_DOWN):
		emit_signal("input", event.scancode)
		return
	