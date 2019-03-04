extends Control

signal about_finished()

var _fsm
var _info

func _on_button_ok_pressed():
	emit_signal("about_finished")
	
#### State
func _on_state_changed(state_from, state_to, args):
	_fsm._print_state(state_from, state_to, args)

func _ready():
	_fsm = state.new()
	_fsm.initialize(self)
	
	_info = load("res://about.gd")
	
	var tabs = find_node("tabs")
	tabs.set_tab_title(0, tr("MAIN_ABOUT_AUTHORS"))
	tabs.set_tab_title(1, tr("MAIN_ABOUT_LICENSE"))
	tabs.set_tab_title(2, tr("MAIN_ABOUT_LICENSE_THIRD_PARTY"))
	
	find_node("label_version").set_text("somsoneone")
	find_node("label_copyright").add_text("sdfsdf\n")
	find_node("label_copyright").add_text("werwer")
	
	find_node("label_authors").set_text("sdfsdfsdf")
	find_node("label_license").set_text(_info.license)
	
	find_node("button_ok").set_text(tr("BUTTON_OK"))

class state extends "res://fsm/base_fsm.gd":
	
	func _initialize(parent):
		._initialize(parent)
		set_name("main_menu about")
		
		connect_state_changed(parent, "_on_state_changed")
