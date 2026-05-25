class_name MirrorChallengeManager
extends RefCounted

const LINEUP_SNAPSHOT_MANAGER_SCRIPT: Script = preload("res://scripts/lineup_snapshot_manager.gd")

const ENCOUNTER_TYPE_BOSS: String = "BOSS"
const BOSS_ROUND_INTERVAL: int = 10
const MIRROR_COLUMN_COUNT: int = 15
const INVALID_CELL: Vector2i = Vector2i(-1, -1)

var snapshot_manager: Variant = LINEUP_SNAPSHOT_MANAGER_SCRIPT.new()
var selected_snapshots_by_round: Dictionary = {}
var mirror_encounters_by_round: Dictionary = {}


func prepare_challenge(max_round: int) -> void:
	selected_snapshots_by_round.clear()
	mirror_encounters_by_round.clear()

	var snapshots: Array[Dictionary] = snapshot_manager.load_all_snapshots()
	var boss_rounds: Array[int] = _get_boss_rounds(max_round)
	for boss_round: int in boss_rounds:
		var snapshot: Dictionary = _pick_snapshot_for_round(snapshots, boss_round)
		if snapshot.is_empty():
			continue

		selected_snapshots_by_round[boss_round] = snapshot.duplicate(true)
		mirror_encounters_by_round[boss_round] = _build_mirror_encounter(boss_round, snapshot)


func clear_challenge() -> void:
	selected_snapshots_by_round.clear()
	mirror_encounters_by_round.clear()


func has_mirror_for_round(round_number: int) -> bool:
	return mirror_encounters_by_round.has(round_number)


func get_mirror_encounters() -> Dictionary:
	var encounters: Dictionary = {}
	for round_value: Variant in mirror_encounters_by_round.keys():
		encounters[int(round_value)] = (mirror_encounters_by_round[round_value] as Dictionary).duplicate(true)

	return encounters


func get_relic_ids_for_round(round_number: int) -> Array[String]:
	var relic_ids: Array[String] = []
	var snapshot: Dictionary = selected_snapshots_by_round.get(round_number, {}) as Dictionary
	if snapshot.is_empty():
		return relic_ids

	for relic_value: Variant in _get_array(snapshot, "relics"):
		if not (relic_value is Dictionary):
			continue

		var relic_id: String = str((relic_value as Dictionary).get("relic_id", ""))
		if relic_id != "":
			relic_ids.append(relic_id)

	return relic_ids


func get_snapshot_gold_for_round(round_number: int) -> int:
	var snapshot: Dictionary = selected_snapshots_by_round.get(round_number, {}) as Dictionary
	if snapshot.is_empty():
		return 0

	var run_data: Dictionary = _get_dictionary(snapshot, "run")
	return maxi(0, int(run_data.get("gold", 0)))


func build_locked_preview_text(max_round: int) -> String:
	var lines: Array[String] = []
	lines.append("[b]镜像挑战[/b]")
	lines.append("本局 Boss 镜像已锁定。")

	for boss_round: int in _get_boss_rounds(max_round):
		if not selected_snapshots_by_round.has(boss_round):
			lines.append("第 " + str(boss_round) + " 波：暂无历史快照，使用原 Boss")
			continue

		var snapshot: Dictionary = selected_snapshots_by_round[boss_round] as Dictionary
		lines.append("第 " + str(boss_round) + " 波：" + _get_snapshot_unit_summary(snapshot))
		var relic_summary: String = _get_snapshot_relic_summary(snapshot)
		if relic_summary != "":
			lines.append("遗物：" + relic_summary)

	return _join_lines(lines)


func build_current_round_preview_text(round_number: int) -> String:
	if not selected_snapshots_by_round.has(round_number):
		return ""

	var snapshot: Dictionary = selected_snapshots_by_round[round_number] as Dictionary
	var lines: Array[String] = []
	lines.append("[b]镜像阵容[/b]")
	lines.append(_get_snapshot_unit_summary(snapshot))
	var global_effects: Dictionary = _get_dictionary(snapshot, "global_effects")
	lines.append("生命倍率 x" + _format_multiplier(float(global_effects.get("player_hp_multiplier", 1.0))) \
		+ " / 攻击倍率 x" + _format_multiplier(float(global_effects.get("player_attack_multiplier", 1.0))))
	var relic_summary: String = _get_snapshot_relic_summary(snapshot)
	if relic_summary != "":
		lines.append("遗物：" + relic_summary)

	return _join_lines(lines)


func _build_mirror_encounter(round_number: int, snapshot: Dictionary) -> Dictionary:
	var enemy_units: Array[Dictionary] = _build_mirror_enemy_units(snapshot)
	var global_effects: Dictionary = _get_dictionary(snapshot, "global_effects")
	return {
		"encounter_id": "mirror_round_" + str(round_number) + "_" + str(snapshot.get("snapshot_id", "")),
		"encounter_name": "镜像挑战：" + str(round_number) + " 波通关阵容",
		"encounter_type": ENCOUNTER_TYPE_BOSS,
		"enemy_hp_multiplier": 1.0,
		"enemy_attack_multiplier": 1.0,
		"enemy_defense_bonus": 0,
		"enemy_mana_regen_multiplier": 1.0,
		"enemy_count": enemy_units.size(),
		"enemy_units": enemy_units,
		"is_mirror_challenge": true,
		"mirror_snapshot_id": str(snapshot.get("snapshot_id", "")),
		"mirror_source_round": _get_snapshot_round(snapshot),
		"mirror_global_effects": global_effects,
		"mirror_relics": _get_array(snapshot, "relics"),
	}


func _build_mirror_enemy_units(snapshot: Dictionary) -> Array[Dictionary]:
	var enemy_units: Array[Dictionary] = []
	var units: Dictionary = _get_dictionary(snapshot, "units")
	var active_units: Array = _get_array(units, "active")
	var global_effects: Dictionary = _get_dictionary(snapshot, "global_effects")
	var hp_multiplier: float = float(global_effects.get("player_hp_multiplier", 1.0))
	var attack_multiplier: float = float(global_effects.get("player_attack_multiplier", 1.0))
	var occupied_cells: Array[Vector2i] = []

	for index: int in range(active_units.size()):
		var unit_value: Variant = active_units[index]
		if not (unit_value is Dictionary):
			continue

		var unit_snapshot: Dictionary = unit_value as Dictionary
		var unit_id: String = str(unit_snapshot.get("unit_id", ""))
		if unit_id == "":
			continue

		var star: int = clampi(int(unit_snapshot.get("star", 1)), 1, 3)
		var enemy_cell: Vector2i = _get_mirrored_cell(unit_snapshot, occupied_cells)
		var display_name: String = "镜像：" + str(unit_snapshot.get("display_name", unit_id)) + " " + _get_star_text(star)
		enemy_units.append({
			"unit_id": unit_id,
			"resource_path": str(unit_snapshot.get("resource_path", "")),
			"display_name": display_name,
			"base_display_name": str(unit_snapshot.get("display_name", unit_id)),
			"position": Vector2.ZERO,
			"cell": enemy_cell,
			"star": star,
			"is_boss": false,
			"is_mirror_unit": true,
			"hp_multiplier": hp_multiplier,
			"attack_multiplier": attack_multiplier,
			"defense_bonus": 0,
			"mana_regen_multiplier": 1.0,
		})

	return enemy_units


func _get_mirrored_cell(unit_snapshot: Dictionary, occupied_cells: Array[Vector2i]) -> Vector2i:
	if not bool(unit_snapshot.get("has_saved_cell", false)):
		return INVALID_CELL

	var saved_cell: Vector2i = _dictionary_to_vector2i(unit_snapshot.get("saved_cell", {}), INVALID_CELL)
	if saved_cell == INVALID_CELL:
		return INVALID_CELL

	var enemy_cell: Vector2i = Vector2i(MIRROR_COLUMN_COUNT - 1 - saved_cell.x, saved_cell.y)
	if _is_cell_in_list(enemy_cell, occupied_cells):
		return INVALID_CELL

	occupied_cells.append(enemy_cell)
	return enemy_cell


func _pick_snapshot_for_round(snapshots: Array[Dictionary], round_number: int) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for snapshot: Dictionary in snapshots:
		if _get_snapshot_round(snapshot) == round_number:
			candidates.append(snapshot)

	if candidates.is_empty():
		for snapshot: Dictionary in snapshots:
			if str(snapshot.get("source", "")) == "BOSS_VICTORY":
				candidates.append(snapshot)

	if candidates.is_empty():
		return {}

	return candidates[randi_range(0, candidates.size() - 1)].duplicate(true)


func _get_boss_rounds(max_round: int) -> Array[int]:
	var boss_rounds: Array[int] = []
	var round_number: int = BOSS_ROUND_INTERVAL
	while round_number <= max_round:
		boss_rounds.append(round_number)
		round_number += BOSS_ROUND_INTERVAL

	return boss_rounds


func _get_snapshot_round(snapshot: Dictionary) -> int:
	var run_data: Dictionary = _get_dictionary(snapshot, "run")
	return int(run_data.get("current_round", 0))


func _get_snapshot_unit_summary(snapshot: Dictionary) -> String:
	var units: Dictionary = _get_dictionary(snapshot, "units")
	var active_units: Array = _get_array(units, "active")
	if active_units.is_empty():
		return "空阵容"

	var parts: Array[String] = []
	for unit_value: Variant in active_units:
		if not (unit_value is Dictionary):
			continue

		var unit_snapshot: Dictionary = unit_value as Dictionary
		parts.append(str(unit_snapshot.get("display_name", unit_snapshot.get("unit_id", ""))) + " " + _get_star_text(int(unit_snapshot.get("star", 1))))

	return _join_text(parts, " / ")


func _get_snapshot_relic_summary(snapshot: Dictionary) -> String:
	var parts: Array[String] = []
	for relic_value: Variant in _get_array(snapshot, "relics"):
		if not (relic_value is Dictionary):
			continue

		var relic_snapshot: Dictionary = relic_value as Dictionary
		parts.append(str(relic_snapshot.get("name", relic_snapshot.get("relic_id", ""))))

	return _join_text(parts, " / ")


func _get_star_text(star: int) -> String:
	var star_text: String = ""
	for _index: int in range(clampi(star, 1, 3)):
		star_text += "*"

	return star_text


func _dictionary_to_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if not (value is Dictionary):
		return fallback

	var dictionary: Dictionary = value as Dictionary
	return Vector2i(int(dictionary.get("x", fallback.x)), int(dictionary.get("y", fallback.y)))


func _get_dictionary(dictionary: Dictionary, key: String) -> Dictionary:
	var value: Variant = dictionary.get(key, {})
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)

	return {}


func _get_array(dictionary: Dictionary, key: String) -> Array:
	var value: Variant = dictionary.get(key, [])
	if value is Array:
		return (value as Array).duplicate(true)

	return []


func _is_cell_in_list(cell: Vector2i, cells: Array[Vector2i]) -> bool:
	for existing_cell: Vector2i in cells:
		if existing_cell == cell:
			return true

	return false


func _format_multiplier(multiplier: float) -> String:
	return "%0.2f" % multiplier


func _join_lines(lines: Array[String]) -> String:
	return _join_text(lines, "\n")


func _join_text(parts: Array[String], separator: String) -> String:
	var joined_text: String = ""
	for index: int in range(parts.size()):
		if index > 0:
			joined_text += separator
		joined_text += parts[index]

	return joined_text
