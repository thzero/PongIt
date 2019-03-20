extends Node

# 0 : File didn't open
# 1 : File open
enum { LOAD_ERROR_COULDNT_OPEN, SAVE_ERROR_COULDNT_SAVE, LOAD_SUCCESS }

var config = ConfigFile.new()

func save():
	if (_settings() == null):
		return SAVE_ERROR_COULDNT_SAVE
	
	for section in _settings().keys():
		for key in _settings()[section]:
			config.set_value(section, key, _settings()[section][key])
	
	config.save(_settings_path())

func _apply():
	pass

func _clone():
	var temp = {}
	for section in _settings().keys():
		temp[section] = {}
		for key in _settings()[section]:
			temp[section][key] = _settings()[section][key]
	return temp

func _load():
	if (_settings() == null):
		return LOAD_ERROR_COULDNT_OPEN
	
	# Check for error if true exist the function else parse the file and load the config settings into Settings
	var error = config.load(_settings_path())
	if (error != OK):
		print("Error loading the settings. Error code: %s" % error)
		return LOAD_ERROR_COULDNT_OPEN
	
	var temp = _clone()
	for section in temp.keys():
		for key in temp[section]:
			var val = config.get_value(section, key)
			if (val != null):
				temp[section][key] = val
	
	if (_validate(temp)):
		_update(temp)
	
	return LOAD_SUCCESS

func _settings():
	return null
	
func _settings_path():
	return null

func _update(temp):
	pass
	
func _validate(temp):
	return true

func _ready():
	# Check if settings exist if not create a new one with the default Settings
	if (_load() == LOAD_ERROR_COULDNT_OPEN):
		save()
	
	_apply()
