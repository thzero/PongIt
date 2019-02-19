extends Node

# Declaring String that content Paths, if your lazy
const User_directory = "user://"
const Res_directory = "res://"
const Settings_Path = Res_directory + "settings.ini"

# 0 : File didn't open
# 1 : File open
enum { LOAD_ERROR_COULDNT_OPEN, LOAD_SUCCESS }

var config = ConfigFile.new()

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
	
	_save()
	_apply()

func _apply():
	# Check out the documentation about :
	# OS class : http://docs.godotengine.org/en/3.0/classes/class_os.html
	# Engine class : http://docs.godotengine.org/en/3.0/classes/class_engine.html
	# for this case i only use OS to change the resolution,fullscreen and Vsync 
	OS.window_size = Vector2(Settings.Display.Width, Settings.Display.Height)
	OS.window_fullscreen = Settings.Display.Fullscreen
	OS.vsync_enabled = Settings.Display.Vsync

func _load():
	# Check for error if true exist the function else parse the file and load the config settings into Settings
	var error = config.load(Settings_Path)
	if (error != OK):
		print("Error loading the settings. Error code: %s" % error)
		return LOAD_ERROR_COULDNT_OPEN
	
	for section in Settings.keys():
		for key in Settings[section]:
			var val = config.get_value(section, key)
			Settings[section][key] = val
	
	return LOAD_SUCCESS

func _save():
	for section in Settings.keys():
		for key in Settings[section]:
			config.set_value(section, key, Settings[section][key])
	
	config.save(Settings_Path)

func _ready():
	# Check if settings exist if not create a new one with the default Settings
	if (_load() == LOAD_ERROR_COULDNT_OPEN):
		_save()
	
	_apply()
