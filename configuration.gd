extends "res://base/config.gd"

# Declaring String that content Paths, if your lazy
const User_directory = "user://"
const Res_directory = "res://"
const Settings_Path = Res_directory + "settings.ini"

# Default Settings
var Settings = {
	"Display": 
	{
		"Height": 900,
		"Width": 1600,
		"Fullscreen": false,
		"Vsync": true
	},
	"Audio":
	{
		"Muted": false,
		"Music": 100,
		"General": 100,
		"SoundEffects": 100
	}
}

func update_settings(display, audio):
	Settings.Display.Height = display.height
	Settings.Display.Width = display.width
	Settings.Display.FullScreen = display.fullscreen
	Settings.Display.Vsync = display.vsync
	
	if (audio != null):
		Settings.Audio.General = audio.general
		Settings.Audio.Music = audio.music
		Settings.Audio.SoundEffects = audio.soundeffects
		Settings.Audio.Muted = audio.muted
	
	save()
	_apply()

func _apply():
	# Check out the documentation about :
	# OS class : http://docs.godotengine.org/en/3.0/classes/class_os.html
	# Engine class : http://docs.godotengine.org/en/3.0/classes/class_engine.html
	# for this case i only use OS to change the resolution,fullscreen and Vsync 
	OS.window_size = Vector2(Settings.Display.Width, Settings.Display.Height)
	OS.window_fullscreen = Settings.Display.Fullscreen
	OS.vsync_enabled = Settings.Display.Vsync

func _settings():
	return Settings
	
func _settings_path():
	return Settings_Path

func _update(temp):
	Settings = temp

func _ready():
	# Check if settings exist if not create a new one with the default Settings
	if (_load() == LOAD_ERROR_COULDNT_OPEN):
		save()
	
	_apply()
