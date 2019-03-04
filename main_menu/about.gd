extends Control

signal about_finished()

func _on_button_ok_pressed():
	emit_signal("about_finished")

func _ready():
	
	find_node("button_ok").set_text(tr("BUTTON_OK"))
