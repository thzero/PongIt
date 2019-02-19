extends "base_fsm.gd"

const Applied = "applied"
const Clean = "clean"
const Dirty = "dirty"

func init():
	add_state(Applied)
	add_state(Clean)
	add_state(Dirty)
		
func is_state_applied():
	return is_state(Applied)
	
func is_state_clean():
	return is_state(Clean)
	
func is_state_dirty():
	return is_state(Dirty)

func set_state_applied():
	set_state(Applied)

func set_state_clean():
	set_state(Clean)
	
func set_state_dirty():
	set_state(Dirty)