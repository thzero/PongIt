extends Control

var _fsm
var _audio
var _display

signal settings_finished()

func open():
	_fsm.set_state_clean()
	show()

func _check_resolution():
	var string_splitter = null
	# Get the count of the all the resolution in the items OptionButton 
	var NB = get_node("label_video/options_resolutions").get_item_count()
	for i in NB:
		# Get the String in resolution that split in half e.g : 800x600 become two string :
		# String 0 : 800
		# String 1 : 600
		string_splitter = get_node("label_video/options_resolutions").get_item_text(i)
		string_splitter = string_splitter.split("x")
		# Check if the two string are matching the display in the Settings than select in the OptionMenu
		if string_splitter[1] == String(Configuration.Settings.Display.Height) && string_splitter[0] == String(Configuration.Settings.Display.Width):
			get_node("label_video/options_resolutions").select(i)

func _load_settings():
	get_node("label_video/checkbox_fullscreen").pressed = Configuration.Settings.Display.Fullscreen
	get_node("label_video/checkbox_vsync").pressed = Configuration.Settings.Display.Vsync
	
	get_node("label_audio/checkbox_muted").pressed = Configuration.Settings.Audio.Muted
	get_node("label_audio/slider_general").value = Configuration.Settings.Audio.General
	get_node("label_audio/slider_music").value = Configuration.Settings.Audio.Music
	get_node("label_audio/slider_sound_effects").value = Configuration.Settings.Audio.SoundEffects
	
	_display.height = Configuration.Settings.Display.Height
	_display.width = Configuration.Settings.Display.Width
	_display.vsync = Configuration.Settings.Display.Vsync
	_display.fullscreen = Configuration.Settings.Display.Fullscreen
	
	_audio.general = Configuration.Settings.Audio.General
	_audio.music = Configuration.Settings.Audio.Music
	_audio.muted = Configuration.Settings.Audio.Muted
	_audio.soundeffects - Configuration.Settings.Audio.SoundEffects
	
	_check_resolution()
	
func _save_settings():
	Configuration.update_settings(_display, _audio)
	_fsm.set_state_clean()

func _on_button_apply_pressed():
	_save_settings()
	_load_settings()
	_fsm.set_state_applied()

func _on_button_cancel_pressed():
	_load_settings()
	_fsm.set_state_clean()
	emit_signal("settings_finished")

func _on_button_ok_pressed():
	_save_settings()
	_load_settings()
	_fsm.set_state_clean()
	emit_signal("settings_finished")

func _on_button_save_pressed():
	Configuration.update_settings(_display, _audio)
	_fsm.set_state_clean()
	emit_signal("settings_finished")

func _on_checkbox_fullscreen_toggled(button_pressed):
	_display.fullscreen = button_pressed
	_fsm.set_state_dirty()

func _on_checkbox_muted_toggled(button_pressed):
	_audio.muted = button_pressed
	_fsm.set_state_dirty()

func _on_checkbox_vsync_toggled(button_pressed):
	_display.vsync = button_pressed
	_fsm.set_state_dirty()

# Get the resolution from the OptionMenu than load it into the Display variable
func _on_options_resolutions_item_selected(ID):
	var string_splitter = null
	string_splitter = get_node("label_video/options_resolutions").get_item_text(ID)
	string_splitter = string_splitter.split("x")
	_display.height = string_splitter[1]
	_display.width = string_splitter[0]
	_fsm.set_state_dirty()

func _on_slider_general_value_changed(value):
	_audio.general = value
	_fsm.set_state_dirty()

func _on_slider_music_value_changed(value):
	_audio.music = value
	_fsm.set_state_dirty()

func _on_slider_sound_effects_value_changed(value):
	_audio.soundeffects = value
	_fsm.set_state_dirty()

#### State
func _on_state_changed(state_from, state_to, args):
	_fsm._print_state(state_from, state_to, args)
	if (state_to == _fsm.Dirty):
		find_node("button_apply").set_disabled(false)
		find_node("button_cancel").set_disabled(false)
		find_node("button_ok").set_disabled(false)
	elif (state_to == _fsm.Applied):
		find_node("button_apply").set_disabled(true)
		find_node("button_cancel").set_disabled(true)
		find_node("button_ok").set_disabled(false)
	else:
		find_node("button_apply").set_disabled(true)
		find_node("button_cancel").set_disabled(false)
		find_node("button_ok").set_disabled(true)

func _ready():
	_audio = preload("res://main_menu/audio.gd").new()
	_display = preload("res://main_menu/display.gd").new()
	
	_fsm = state.new()
	_fsm.initialize(self)
	
	_load_settings()
	
	_fsm.set_state_clean()
	
	find_node("button_apply").set_text(tr("MAIN_MENU_SETTINGS_BUTTON_APPLY"))
	find_node("button_cancel").set_text(tr("BUTTON_CANCEL"))
	find_node("button_ok").set_text(tr("BUTTON_OK"))

class state extends "res://fsm/menu_fsm.gd":
	
	func _initialize(parent):
		._initialize(parent)
		set_name("main_menu settings")
		
		connect_state_changed(parent, "_on_state_changed")
