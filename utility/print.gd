extends Reference

const IS_DEBUG = true

func output(method, args):
	if (!IS_DEBUG):
		return
	
	var output = ""
	if (args != null):
		var value = null
		for key in args.keys():
			value = args[key]
			value = ("(null)" if value == null else value)
			output += " " + key + ": " + str(value)
	
	print(method + ": " + output)
