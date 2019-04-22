extends "res://base/config.gd"

# Declaring String that content Paths, if your lazy
const User_directory = "user://"
const Res_directory = "res://"
const Settings_Path = Res_directory + "user.ini"

# Default Settings
var Settings = {
	"User": 
	{
		"Name": "",
		"Host": {
			"Name": "",
			"IpAddress": "",
				"Type": 1,
			"Port": null
		},
		"Join": {
			"IpAddress": "",
			"Port": null
		}
	}
}

func _settings():
	return Settings

func _settings_path():
	return Settings_Path

func _update(temp):
	Settings = temp
