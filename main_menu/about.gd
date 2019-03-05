extends Control

signal about_finished()

const line_break = "\n"
const tab = "\t"

var _fsm
var _info
var _tree
var _tree_label
var _tree_all
var _license_all = ""

func _on_button_ok_pressed():
	emit_signal("about_finished")

func _on_tree_license_third_party_item_selected():
	_tree_label.clear()
	
	var selected = _tree.get_selected()
	if (selected == null):
		return
	
	print(selected.get_text(0))
	
	if (selected == _tree_all):
		_tree_label.add_text(_license_all)
		return
	
	var license
	for i in _info.license_thirdparty:
		license = _info.license_thirdparty[i]
		if (selected != license.node):
			continue
		
		_tree_label.clear()
		_tree_label.add_text(license.output)

func _generate_output(license):
	var output = license.Name + line_break
	if (license.Url != null && license.Url != ""):
		output += tab + tr("MAIN_ABOUT_LICENSE_THIRD_PARTY_REPOSITORY") + ": " + license.Url + line_break
	if (license.License != null && license.License != ""):
		if (output.length() > 0):
			output += line_break
		output += license.License + "\n"
	if (license.Type != null && license.Type != ""):
		if (output.length() > 0):
			output += line_break
		output += tab + tr("MAIN_ABOUT_LICENSE_THIRD_PARTY_LICENSE") + ": " + license.Type
	return output

#### State
func _on_state_changed(state_from, state_to, args):
	_fsm._print_state(state_from, state_to, args)

func _ready():
	_fsm = state.new()
	_fsm.initialize(self)
	
	_info = load("res://info.gd")
	
	var tabs = find_node("tabs")
	tabs.set_tab_title(0, tr("MAIN_ABOUT_TEAM"))
	tabs.set_tab_title(1, tr("MAIN_ABOUT_LICENSE"))
	tabs.set_tab_title(2, tr("MAIN_ABOUT_LICENSE_THIRD_PARTY"))
	
	find_node("label_version").set_text("somsoneone")
	find_node("label_copyright").add_text("sdfsdf\n")
	find_node("label_copyright").add_text("werwer")
	
	find_node("label_license").set_text(_info.license)
	
	var description = tr("MAIN_ABOUT_LICENSE_THIRD_PARTY_DESCRIPTION")
	description = description % [tr("TITLE"), tr("TITLE")]
	find_node("label_license_third_party_description").add_text(description)
	
	_tree_label = find_node("label_license_third_party")
	_tree = find_node("tree_license_third_party")
	
	var tree_root = _tree.create_item()
	tree_root.set_text(0, 'none')
	_tree.set_hide_root(true)
	
	_tree_all = _tree.create_item()
	_tree_all.set_text(0, tr('MAIN_ABOUT_LICENSE_THIRD_PARTY_ALL'))
	var tree_components = _tree.create_item()
	tree_components.set_text(0, tr('MAIN_ABOUT_LICENSE_THIRD_PARTY_COMPONENTS'))
	
	_license_all = ""
	var license
	var child
	for i in _info.license_thirdparty:
		license = _info.license_thirdparty[i]
		child = _tree.create_item(tree_components)
		child.set_text(0, license.Name)
		license["node"] = child
		
		license["output"] = _generate_output(license)
		_license_all += license["output"]
		_license_all += line_break + line_break
	
	var output = ""
	var group
	var members
	var member
	for i in _info.team:
		output += tr("MAIN_ABOUT_TEAM_" + i) + line_break + line_break
		group = _info.team[i]
		if (group == null):
			continue
		members = group.Members
		if (members == null):
			continue
		for j in members:
			member = members[j]
			output += tab + member.Name + line_break
		
		output += line_break + line_break
		
	find_node("label_team").set_text(output)
	
	find_node("button_ok").set_text(tr("BUTTON_OK"))

class state extends "res://fsm/base_fsm.gd":
	
	func _initialize(parent):
		._initialize(parent)
		set_name("main_menu about")
		
		connect_state_changed(parent, "_on_state_changed")
