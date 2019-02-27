extends Reference

var _patterns = {}
var _compiled = {}
var _mutex = Mutex.new()

func get(type):
	if ((type == null) || (typeof(type) != TYPE_STRING)):
		return FAILED
	
	if (type == ""):
		return FAILED
	
	if (_compiled.has(type)):
		return _compiled[type]

	_mutex.lock()
	
	if (_compiled.has(type)):
		_mutex.unlock()
		return _compiled[type]
	
	if (!_patterns.has(type)):
		_mutex.unlock()
		return FAILED

	var r = RegEx.new()
	r.compile(_patterns[type])

	if (not (r and r is RegEx)):
		_mutex.unlock()
		return FAILED
	
	_compiled[type] = r

	_mutex.unlock()
	return _compiled[type]
	
func _add_pattern(type, pattern):
	if ((type == null) || (typeof(type) != TYPE_STRING)):
		return FAILED
	
	if (type == ""):
		return FAILED
	
	if (pattern == ""):
		return FAILED
		
	_patterns[type] = pattern
	
func _add_pattern_single(type, pattern):
	_add_pattern(type, "^" + pattern + "$")

func _clear_pattern(type):
	if ((type == null) || (typeof(type) != TYPE_STRING)):
		return FAILED
	
	if (!_patterns.has(type)):
		return FAILED
		
	_patterns.erase(type)
	
func _init():
	pass