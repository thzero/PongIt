extends Node

# Declaring String that content Paths, if your lazy
const User_directory = "user://"
const Res_directory = "res://"
const Settings_Path = Res_directory + "user.ini"

# 0 : File didn't open
# 1 : File open
enum { LOAD_ERROR_COULDNT_OPEN, LOAD_SUCCESS }

var config = ConfigFile.new()

# Default Settings
var Settings = {
	"User": 
	{
		"Name": ""
	}
}

func update_settings(user):
	Settings.User.Name = user.name
	_save()

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
