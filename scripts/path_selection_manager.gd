class_name PathSelectionManager
extends RefCounted

const NODE_NORMAL: String = "NORMAL"
const NODE_ELITE: String = "ELITE"
const NODE_MERCHANT: String = "MERCHANT"
const NODE_TRAINING: String = "TRAINING"
const NODE_EVENT: String = "EVENT"
const NODE_TREASURE: String = "TREASURE"

const CANDIDATE_COUNT: int = 3
const PROTECTION_ROUNDS: int = 2
const ELITE_MIN_ROUND: int = 5

const COOLDOWN_MERCHANT: int = 2
const COOLDOWN_TRAINING: int = 2
const COOLDOWN_TREASURE: int = 2
const COOLDOWN_EVENT: int = 1

const WEIGHT_NORMAL: int = 5
const WEIGHT_ELITE: int = 2
const WEIGHT_MERCHANT: int = 2
const WEIGHT_TRAINING: int = 2
const WEIGHT_EVENT: int = 2
const WEIGHT_TREASURE: int = 1

const DISPLAY_NAMES: Dictionary = {
	NODE_NORMAL: "普通战斗",
	NODE_ELITE: "精英战斗",
	NODE_MERCHANT: "商人",
	NODE_TRAINING: "训练场",
	NODE_EVENT: "随机事件",
	NODE_TREASURE: "宝箱",
}

const DESCRIPTIONS: Dictionary = {
	NODE_NORMAL: "与普通敌人战斗，获得金币和奖励。",
	NODE_ELITE: "挑战精英敌人，获得丰厚奖励。",
	NODE_MERCHANT: "拜访商人，购买遗物、强化和人口。",
	NODE_TRAINING: "限时击杀木桩，每个木桩掉落随机奖励。",
	NODE_EVENT: "遭遇随机事件，做出选择。",
	NODE_TREASURE: "打开宝箱，获得一件遗物。",
}

const RARITY_HINTS: Dictionary = {
	NODE_NORMAL: "COMMON",
	NODE_ELITE: "RARE",
	NODE_MERCHANT: "FINE",
	NODE_TRAINING: "FINE",
	NODE_EVENT: "EPIC",
	NODE_TREASURE: "RARE",
}

var encounter_generator: RefCounted = null


func generate_candidates(current_round: int, path_history: Array[String]) -> Array[Dictionary]:
	if current_round <= PROTECTION_ROUNDS:
		return _generate_protection_candidates(current_round)

	var pool: Array[Dictionary] = _build_weighted_pool(current_round, path_history)
	var candidates: Array[Dictionary] = []
	var used_types: Array[String] = []
	var has_combat: bool = false

	for i in range(CANDIDATE_COUNT):
		var picked: Dictionary = _pick_from_pool(pool, used_types)
		if picked.is_empty():
			picked = _create_candidate(NODE_NORMAL, current_round)
		candidates.append(picked)
		used_types.append(picked["node_type"])
		if picked["node_type"] == NODE_NORMAL or picked["node_type"] == NODE_ELITE:
			has_combat = true
		pool = _remove_type_from_pool(pool, picked["node_type"])

	if not has_combat:
		var replace_index: int = randi() % CANDIDATE_COUNT
		while candidates[replace_index]["node_type"] == NODE_ELITE or candidates[replace_index]["node_type"] == NODE_NORMAL:
			replace_index = randi() % CANDIDATE_COUNT
		candidates[replace_index] = _create_candidate(NODE_NORMAL, current_round)

	return candidates

func _generate_protection_candidates(current_round: int) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for i in range(CANDIDATE_COUNT):
		candidates.append(_create_candidate(NODE_NORMAL, current_round))
	return candidates


func _build_weighted_pool(current_round: int, path_history: Array[String]) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	pool.append({"type": NODE_NORMAL, "weight": WEIGHT_NORMAL})

	if current_round >= ELITE_MIN_ROUND:
		pool.append({"type": NODE_ELITE, "weight": WEIGHT_ELITE})

	if not _is_on_cooldown(NODE_MERCHANT, path_history, COOLDOWN_MERCHANT):
		pool.append({"type": NODE_MERCHANT, "weight": WEIGHT_MERCHANT})

	if not _is_on_cooldown(NODE_TRAINING, path_history, COOLDOWN_TRAINING):
		pool.append({"type": NODE_TRAINING, "weight": WEIGHT_TRAINING})

	if not _is_on_cooldown(NODE_EVENT, path_history, COOLDOWN_EVENT):
		pool.append({"type": NODE_EVENT, "weight": WEIGHT_EVENT})

	if not _is_on_cooldown(NODE_TREASURE, path_history, COOLDOWN_TREASURE):
		pool.append({"type": NODE_TREASURE, "weight": WEIGHT_TREASURE})

	return pool


func _is_on_cooldown(node_type: String, path_history: Array[String], cooldown: int) -> bool:
	var history_size: int = path_history.size()
	var check_count: int = mini(cooldown, history_size)
	for i in range(check_count):
		if path_history[history_size - 1 - i] == node_type:
			return true
	return false


func _pick_from_pool(pool: Array[Dictionary], used_types: Array[String]) -> Dictionary:
	var available: Array[Dictionary] = []
	var total_weight: int = 0
	for entry in pool:
		if entry["type"] in used_types:
			continue
		available.append(entry)
		total_weight += int(entry["weight"])

	if available.is_empty() or total_weight <= 0:
		return {}

	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for entry in available:
		cumulative += int(entry["weight"])
		if roll < cumulative:
			return _create_candidate_from_pool_entry(entry)

	return _create_candidate_from_pool_entry(available[available.size() - 1])


func _create_candidate_from_pool_entry(entry: Dictionary) -> Dictionary:
	return _create_candidate(entry["type"], 0)


func _remove_type_from_pool(pool: Array[Dictionary], node_type: String) -> Array[Dictionary]:
	if node_type == NODE_NORMAL or node_type == NODE_ELITE:
		return pool
	var filtered: Array[Dictionary] = []
	for entry in pool:
		if entry["type"] != node_type:
			filtered.append(entry)
	return filtered


func _create_candidate(node_type: String, _current_round: int) -> Dictionary:
	return {
		"node_type": node_type,
		"display_name": DISPLAY_NAMES.get(node_type, node_type),
		"description": DESCRIPTIONS.get(node_type, ""),
		"rarity_hint": RARITY_HINTS.get(node_type, "COMMON"),
		"encounter_data": {},
		"preview_enemies": "",
		"event_id": "",
	}

