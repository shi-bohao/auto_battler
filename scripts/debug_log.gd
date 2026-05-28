class_name DebugLog
extends RefCounted

const COMBAT_LOG_SETTING: String = "auto_battler/debug/combat_log_enabled"
const INFO_LOG_SETTING: String = "auto_battler/debug/info_log_enabled"


static func combat(message: Variant) -> void:
	if _is_enabled(COMBAT_LOG_SETTING):
		print(str(message))


static func info(message: Variant) -> void:
	if _is_enabled(INFO_LOG_SETTING):
		print(str(message))


static func _is_enabled(setting_name: String) -> bool:
	return bool(ProjectSettings.get_setting(setting_name, false))
