@tool
class_name UgPluginSettings
extends RefCounted
## A helper for managing plugin settings.
## To use this, create a named class for your plugin's settings and call
## [member initialize_setting] for each setting during the class's [method _static_init] method.

const DEFAULT_SETTINGS_PATH: String = "Plugins"

const DEFAULT_SETTINGS_CATEGORY: String = "General"

const SETTINGS_PATH_OVERRIDE_SYMBOL: StringName = &"SETTINGS_PATH"

# TODO @sphynx-owner: programmatically generate
const PROPERTY_LIST: Dictionary[String, bool] = {
	"settings_path": true,
	"settings_properties": true,
	"_setter_gate": true,
}

static var initialized_settings: Dictionary[GDScript, Dictionary]

var settings_path: String = DEFAULT_SETTINGS_PATH

# @shape: {[property_name: String]: [category_name: String]}
var settings_properties: Dictionary[String, String]

var _setter_gate: bool = false


func _init() -> void:
	var script: GDScript = get_script()
	
	if script == UgPluginSettings:
		return
	
	if !initialized_settings.has(script):
		initialized_settings[script] = {
			"settings_path": DEFAULT_SETTINGS_PATH,
			"settings_properties": {} as Dictionary[String, String]
		} as Dictionary[String, Variant]
		
		var constant_map: Dictionary = script.get_script_constant_map()
		
		if constant_map.has(SETTINGS_PATH_OVERRIDE_SYMBOL):
			initialized_settings[script].settings_path = constant_map[SETTINGS_PATH_OVERRIDE_SYMBOL]
		
		var property_list: Array[Dictionary] = script.get_script_property_list()
		
		var current_category: String = DEFAULT_SETTINGS_CATEGORY
		
		for property in property_list:
			if PROPERTY_LIST.has(property.name) or !(property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
				# HACK @sphynx-owner: there are procedurally generated categories to separate properties
				# between inheriting classes, and those would all end with .gd? I am not sure about inner classes.
				if property.usage & PROPERTY_USAGE_CATEGORY and !property.name.ends_with(".gd"):
					current_category = property.name
				
				continue
			
			initialized_settings[script].settings_properties[property.name] = current_category
			
			var property_name: String = "%s/%s/%s" % [
				initialized_settings[script].settings_path,
				initialized_settings[script].settings_properties[property.name],
				property.name
			]
			
			var property_info: Dictionary = {
				"name": property_name,
				"type": property.type,
				"hint": property.hint,
				"hint_string": property.hint_string,
			}
			
			var default_value: Variant = script.get_property_default_value(property.name)
			
			if not ProjectSettings.has_setting(property_name):
				ProjectSettings.set_setting(property_name, default_value)
			
			# We call this every time, because in some scenarios not doing so resets hints
			# after reloading the project
			ProjectSettings.add_property_info(property_info)
			ProjectSettings.set_initial_value(property_name, default_value)
	
	settings_path = initialized_settings[script].settings_path
	
	settings_properties = initialized_settings[script].settings_properties
	
	for property in settings_properties:
		var setting_name: String = _get_setting_name(property)
		
		if not ProjectSettings.has_setting(setting_name):
			push_error("missing project setting ", setting_name)
		
		set(property, ProjectSettings.get_setting(setting_name))
	
	ProjectSettings.settings_changed.connect(_on_project_settings_changed)


func get_setting(key: String) -> Variant:
	return ProjectSettings.get_setting_with_override(_get_setting_name(key))


func has_setting(key: String) -> bool:
	return ProjectSettings.has_setting(_get_setting_name(key))


func _property_set(key: String, value: Variant):
	if _setter_gate:
		return
	
	ProjectSettings.set_setting(_get_setting_name(key), value)
	
	# NOTE @sphynx-owner: I am refraining from implementing a save blocker feature due to the fact
	# that if any other settings are being set and need to be saved, all settings will be saved together.
	if Engine.is_editor_hint():
		ProjectSettings.save()


func _get_setting_name(key: String) -> String:
	return "%s/%s/%s" % [settings_path, settings_properties[key], key]


func _on_project_settings_changed():
	for property in settings_properties:
		if !has_setting(property):
			push_error("setting ", _get_setting_name(property), " is missing from project setting")
			return
		
		var value: Variant = get_setting(property)
		
		if get(property) != value:
			_setter_gate = true
			
			set(property, value)
			
			_setter_gate = false
