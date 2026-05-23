class_name StatsManager
extends RefCounted

var unit_stat_snapshots: Dictionary = {}
var unit_order: Array[int] = []
var battle_start_time: float = 0.0
var battle_duration: float = 0.0
var has_battle_timer: bool = false


func clear() -> void:
	unit_stat_snapshots.clear()
	unit_order.clear()
	battle_start_time = 0.0
	battle_duration = 0.0
	has_battle_timer = false


func start_battle_timer() -> void:
	battle_start_time = 0.0
	battle_duration = 0.0
	has_battle_timer = true


func advance_battle_timer(delta: float) -> void:
	if not has_battle_timer:
		return

	battle_duration += maxf(delta, 0.0)


func finish_battle_timer() -> void:
	if not has_battle_timer:
		return

	has_battle_timer = false


func register_unit(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	var unit_id: int = int(unit.unit_id)
	if not unit_order.has(unit_id):
		unit_order.append(unit_id)

	if not unit_stat_snapshots.has(unit_id):
		unit_stat_snapshots[unit_id] = _create_empty_snapshot(unit)
	else:
		_update_unit_identity(unit)


func start_unit_battle(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["damage_dealt"] = 0
	snapshot["damage_taken"] = 0
	snapshot["healing_done"] = 0
	snapshot["shield_given"] = 0
	snapshot["mana_restored"] = 0.0
	snapshot["kill_count"] = 0
	snapshot["attack_count"] = 0
	snapshot["survival_time"] = 0.0
	snapshot["is_alive_at_end"] = false
	snapshot["battle_start_time"] = battle_duration
	snapshot["has_started_battle"] = true
	snapshot["shield"] = unit.shield
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func record_attack(unit: Variant) -> int:
	if not _is_valid_unit(unit):
		return 0

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["attack_count"] = int(snapshot["attack_count"]) + 1
	unit_stat_snapshots[int(unit.unit_id)] = snapshot
	return int(snapshot["attack_count"])


func record_damage_dealt(unit: Variant, amount: int) -> void:
	if not _is_valid_unit(unit) or amount <= 0:
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["damage_dealt"] = int(snapshot["damage_dealt"]) + amount
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func record_damage_taken(unit: Variant, amount: int) -> void:
	if not _is_valid_unit(unit) or amount <= 0:
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["damage_taken"] = int(snapshot["damage_taken"]) + amount
	snapshot["shield"] = unit.shield
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func record_healing_done(unit: Variant, amount: int) -> void:
	if not _is_valid_unit(unit) or amount <= 0:
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["healing_done"] = int(snapshot["healing_done"]) + amount
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func record_shield_given(unit: Variant, amount: int) -> void:
	if not _is_valid_unit(unit) or amount <= 0:
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["shield_given"] = int(snapshot["shield_given"]) + amount
	snapshot["shield"] = unit.shield
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func record_mana_restored(unit: Variant, amount: float) -> void:
	if not _is_valid_unit(unit) or amount <= 0.0:
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["mana_restored"] = float(snapshot["mana_restored"]) + amount
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func record_kill(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["kill_count"] = int(snapshot["kill_count"]) + 1
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func record_death(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	if bool(snapshot["has_started_battle"]):
		snapshot["survival_time"] = maxf(battle_duration - float(snapshot["battle_start_time"]), 0.0)
	snapshot["is_alive_at_end"] = false
	snapshot["shield"] = unit.shield
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func finish_unit_battle(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	if bool(snapshot["has_started_battle"]) and unit.is_alive:
		snapshot["survival_time"] = maxf(battle_duration - float(snapshot["battle_start_time"]), 0.0)
	snapshot["is_alive_at_end"] = unit.is_alive
	snapshot["shield"] = unit.shield
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func capture_unit_snapshot(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	register_unit(unit)
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["display_name"] = unit.display_name
	snapshot["team_id"] = unit.team_id
	snapshot["unit_type"] = unit.unit_type
	snapshot["shield"] = unit.shield
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func get_unit_snapshot(unit: Variant) -> Dictionary:
	if not _is_valid_unit(unit):
		return {}

	register_unit(unit)
	return unit_stat_snapshots[int(unit.unit_id)] as Dictionary


func get_all_unit_stats() -> Array[Dictionary]:
	var stats: Array[Dictionary] = []

	for unit_id: int in unit_order:
		if unit_stat_snapshots.has(unit_id):
			stats.append(unit_stat_snapshots[unit_id] as Dictionary)

	return stats


func build_statistics_text(result_text: String, relic_damage_dealt: int) -> String:
	var stats: Array[Dictionary] = get_all_unit_stats()
	var display_result_text: String = _format_result_text(result_text)
	if stats.is_empty():
		return display_result_text

	var top_damage: Dictionary = _find_top_stat(stats, "damage_dealt")
	var top_taken: Dictionary = _find_top_stat(stats, "damage_taken")
	var top_healing: Dictionary = _find_top_stat(stats, "healing_done")
	var top_shield: Dictionary = _find_top_stat(stats, "shield_given")
	var top_mana: Dictionary = _find_top_stat(stats, "mana_restored")
	var top_kills: Dictionary = _find_top_stat(stats, "kill_count")
	var text: String = display_result_text + "\n\n"

	text += "战斗时间：" + _format_float(battle_duration) + " 秒\n\n"
	text += "MVP：\n"
	text += "最高伤害：" + _format_top_stat(top_damage, "damage_dealt") + "\n"
	text += "最高承伤：" + _format_top_stat(top_taken, "damage_taken") + "\n"
	text += "最高治疗：" + _format_top_stat(top_healing, "healing_done") + "\n"
	text += "最高护盾：" + _format_top_stat(top_shield, "shield_given") + "\n"
	text += "最高回蓝：" + _format_top_stat(top_mana, "mana_restored") + "\n"
	text += "最多击杀：" + _format_top_stat(top_kills, "kill_count") + "\n\n"
	text += "遗物伤害：" + str(relic_damage_dealt) + "\n\n"
	text += "单位统计：\n"

	for stat: Dictionary in stats:
		text += _format_unit_stat(stat) + "\n"

	return text


func _create_empty_snapshot(unit: Variant) -> Dictionary:
	return {
		"unit_id": unit.unit_id,
		"display_name": unit.display_name,
		"team_id": unit.team_id,
		"unit_type": unit.unit_type,
		"shield": unit.shield,
		"damage_dealt": 0,
		"damage_taken": 0,
		"healing_done": 0,
		"shield_given": 0,
		"mana_restored": 0.0,
		"kill_count": 0,
		"attack_count": 0,
		"survival_time": 0.0,
		"is_alive_at_end": false,
		"battle_start_time": 0.0,
		"has_started_battle": false,
	}


func _update_unit_identity(unit: Variant) -> void:
	var snapshot: Dictionary = unit_stat_snapshots[int(unit.unit_id)] as Dictionary
	snapshot["display_name"] = unit.display_name
	snapshot["team_id"] = unit.team_id
	snapshot["unit_type"] = unit.unit_type
	unit_stat_snapshots[int(unit.unit_id)] = snapshot


func _find_top_stat(stats: Array[Dictionary], stat_key: String) -> Dictionary:
	var top_stat: Dictionary = {}
	var top_value: float = -1.0

	for stat: Dictionary in stats:
		var value: float = float(stat[stat_key])
		if value > top_value:
			top_stat = stat
			top_value = value

	return top_stat


func _format_top_stat(stat: Dictionary, stat_key: String) -> String:
	if stat.is_empty():
		return "-"

	return str(stat["display_name"]) + " - " + _format_stat_value(stat, stat_key)


func _format_unit_stat(stat: Dictionary) -> String:
	var alive_text: String = "存活" if bool(stat["is_alive_at_end"]) else "死亡"
	var survival_text: String = "%0.1f" % float(stat["survival_time"])
	var text: String = str(stat["display_name"])

	text += "：伤害 " + str(stat["damage_dealt"])
	text += " / 承伤 " + str(stat["damage_taken"])
	text += " / 治疗 " + str(stat["healing_done"])
	text += " / 护盾 " + str(stat["shield_given"])
	text += " / 回蓝 " + _format_float(float(stat["mana_restored"]))
	text += " / 击杀 " + str(stat["kill_count"])
	text += " / 攻击 " + str(stat["attack_count"])
	text += " / 存活 " + survival_text + "秒"
	text += " / " + alive_text
	return text


func _format_result_text(result_text: String) -> String:
	match result_text:
		"Left Team Wins":
			return "战斗胜利"
		"Right Team Wins":
			return "战斗失败"
		"Draw":
			return "平局"
		_:
			return result_text


func _format_stat_value(stat: Dictionary, stat_key: String) -> String:
	if stat_key == "mana_restored":
		return _format_float(float(stat[stat_key]))

	return str(stat[stat_key])


func _format_float(value: float) -> String:
	return "%0.1f" % value


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)
