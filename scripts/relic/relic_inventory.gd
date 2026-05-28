class_name RelicInventory
extends RefCounted


const DEBUG_LOG_SCRIPT: Script = preload("res://scripts/debug_log.gd")

var _relics: Array[Resource] = []


func clear() -> void:
	_relics.clear()


func add_relic(relic_data: Resource, get_unique_key_func: Callable, get_debug_name_func: Callable) -> bool:
	if relic_data == null:
		return false

	if has_relic(relic_data, get_unique_key_func):
		DEBUG_LOG_SCRIPT.info("Relic already owned: " + _call_string(get_debug_name_func, relic_data))
		return false

	_relics.append(relic_data)
	DEBUG_LOG_SCRIPT.info("Added relic: " + _call_string(get_debug_name_func, relic_data))
	return true


func has_relic(relic_data: Resource, get_unique_key_func: Callable) -> bool:
	var relic_key: String = _call_string(get_unique_key_func, relic_data)
	if relic_key == "":
		return false

	for owned_relic in _relics:
		if owned_relic != null and _call_string(get_unique_key_func, owned_relic) == relic_key:
			return true

	return false


func has_relic_id(relic_id: String, get_relic_id_func: Callable) -> bool:
	return get_relic_by_id(relic_id, get_relic_id_func) != null


func get_relic_by_id(relic_id: String, get_relic_id_func: Callable) -> Resource:
	if relic_id == "":
		return null

	for relic_data in _relics:
		if relic_data != null and _call_string(get_relic_id_func, relic_data) == relic_id:
			return relic_data

	return null


func get_all_relics() -> Array[Resource]:
	var relics: Array[Resource] = []
	for relic_data in _relics:
		if relic_data != null:
			relics.append(relic_data)

	return relics


func is_empty() -> bool:
	return _relics.is_empty()


func print_relics(get_debug_name_func: Callable) -> void:
	if _relics.is_empty():
		DEBUG_LOG_SCRIPT.info("Player relics: none")
		return

	var relic_texts: Array[String] = []
	for relic_data in _relics:
		if relic_data != null:
			relic_texts.append(_call_string(get_debug_name_func, relic_data))

	var relic_list_text: String = ""
	for index: int in range(relic_texts.size()):
		if index > 0:
			relic_list_text += ", "
		relic_list_text += relic_texts[index]

	DEBUG_LOG_SCRIPT.info("Player relics: " + relic_list_text)


func _call_string(function: Callable, value: Resource) -> String:
	if function.is_null():
		return ""

	return str(function.call(value))
