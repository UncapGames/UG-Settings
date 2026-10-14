@tool
class_name UgPluginSettings
extends RefCounted
## A helper for managing plugin settings.
## To use this, create a named class for your plugin's settings and call
## [member initialize_setting] for each setting during the class's [method _static_init] method.

var _settings_prefix: String


## [param settings_prefix] - The prefix for the plugin's setting keys (e.g "uncap_games_log/")
func _init(settings_prefix: String) -> void:
	self._settings_prefix = settings_prefix


## Registers or initializes a project setting.[br]
## [br]
## [param key] - The key for the setting (will be prefixed with [member settings_prefix]).[br]
## [param default_value] - The default value for the setting.[br]
## [param config] - Dictionary of property info for the setting.[br]
## [param use_prefix] - Whether to use a prefix for the setting.[br]
## [br]
## [b]NOTE[/b]: [code]usage[/code] key is ignored and will trigger a warning if passed,
## check [method ProjectSettings.set_as_basic] or [method ProjectSettings.set_as_internal].
## [codeblock]
## @shape: {
##   "type": int # TYPE_* (e.g. TYPE_STRING),
##   "hint": int # PROPERTY_HINT_* (e.g. PROPERTY_HINT_ENUM),
##   "hint_string": String # The hint string for the property (e.g. "None,One,Two,Three"),
## }
## [/codeblock]
func initialize_setting(
	key: String, default_value: Variant, config: Dictionary, use_prefix := true
) -> void:
	var property_info := config.duplicate()

	var property_name: String
	if use_prefix:
		property_name = "%s/%s" % [_settings_prefix, key]
	else:
		property_name = key

	property_info.name = property_name

	if not ProjectSettings.has_setting(property_name):
		ProjectSettings.set_setting(property_name, default_value)

	# We call this every time, because in some scenarios not doing so resets hints
	# after reloading the project
	ProjectSettings.set_initial_value(property_name, default_value)
	ProjectSettings.add_property_info(property_info)


func get_setting(key: String, use_prefix := true) -> Variant:
	if use_prefix:
		return ProjectSettings.get_setting_with_override("%s/%s" % [_settings_prefix, key])
	return ProjectSettings.get_setting_with_override(key)


func has_setting(key: String, use_prefix := true) -> bool:
	if use_prefix:
		return ProjectSettings.has_setting("%s/%s" % [_settings_prefix, key])
	return ProjectSettings.has_setting(key)


func set_setting(key: String, value: Variant, use_prefix := true):
	if use_prefix:
		ProjectSettings.set_setting("%s/%s" % [_settings_prefix, key], value)
		return
	ProjectSettings.set_setting(key, value)
