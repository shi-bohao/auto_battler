class_name RewardManager
extends RefCounted

const DEBUG_LOG_SCRIPT: Script = preload("res://scripts/debug_log.gd")
const REWARD_TYPE_STAT: String = "STAT"
const REWARD_TYPE_UNIT: String = "UNIT"
const REWARD_TYPE_RELIC: String = "RELIC"
const ENCOUNTER_TYPE_ELITE: String = "ELITE"

var relic_manager: RelicManager = null
var roster_manager: Variant = null
var run_modifier_manager: Variant = null

const REWARD_RARITY_ORDER: Array[String] = ["COMMON", "FINE", "RARE", "EPIC", "LEGENDARY"]
const REWARD_RARITY_ROLL_ORDER: Array[String] = ["LEGENDARY", "EPIC", "RARE", "FINE", "COMMON"]

const BASE_RARITY_CHANCE: Dictionary = {
	"COMMON": 70.0,
	"FINE": 20.0,
	"RARE": 9.0,
	"EPIC": 1.0,
	"LEGENDARY": 0.0,
}

const RARITY_CHANCE_PER_ROUND: Dictionary = {
	"COMMON": 0.0,
	"FINE": 5.0,
	"RARE": 2.0,
	"EPIC": 1.0,
	"LEGENDARY": 0.5,
}

const ENCOUNTER_BONUS: Dictionary = {
	"NORMAL": 0.0,
	"ELITE": 10.0,
	"BOSS": 20.0,
}


func setup(
	configured_relic_manager: RelicManager,
	configured_roster_manager: Variant,
	run_modifier_manager_value: Variant = null
) -> void:
	relic_manager = configured_relic_manager
	roster_manager = configured_roster_manager
	run_modifier_manager = run_modifier_manager_value


func roll_reward_options(reward_count: int, encounter_type: String = "", current_round: int = 1) -> Array[Dictionary]:
	var pool: Array[Dictionary] = _build_reward_pool()
	var rolled_rewards: Array[Dictionary] = []

	while not pool.is_empty() and rolled_rewards.size() < reward_count:
		var rarity: String = _roll_reward_rarity(encounter_type, current_round)
		var selected_reward: Dictionary = _pick_reward_by_rarity(pool, rarity)
		if selected_reward.is_empty():
			break
		rolled_rewards.append(selected_reward)
		_remove_reward_from_pool(pool, selected_reward)

	return rolled_rewards


func apply_reward(reward: Dictionary) -> void:
	var reward_type: String = _get_reward_type(reward)

	match reward_type:
		REWARD_TYPE_STAT:
			_apply_stat_reward(reward)
		REWARD_TYPE_UNIT:
			_apply_unit_reward(reward)
		REWARD_TYPE_RELIC:
			_apply_relic_reward(reward)
		_:
			push_warning("Unknown reward type: " + reward_type)


func _apply_stat_reward(reward: Dictionary) -> void:
	var reward_id: String = str(reward["id"])

	match reward_id:
		"STAT_MAX_HP_PERCENT_COMMON":
			_apply_max_hp_percent(0.05)
		"STAT_MAX_HP_PERCENT_FINE":
			_apply_max_hp_percent(0.10)
		"STAT_MAX_HP_PERCENT_RARE":
			_apply_max_hp_percent(0.15)
		"STAT_MAX_HP_PERCENT_EPIC":
			_apply_max_hp_percent(0.20)
		"STAT_MAX_HP_PERCENT_LEGENDARY":
			_apply_max_hp_percent(0.25)
		"STAT_ATTACK_PERCENT_COMMON":
			_apply_attack_percent(0.05)
		"STAT_ATTACK_PERCENT_FINE":
			_apply_attack_percent(0.10)
		"STAT_ATTACK_PERCENT_RARE":
			_apply_attack_percent(0.15)
		"STAT_ATTACK_PERCENT_EPIC":
			_apply_attack_percent(0.20)
		"STAT_ATTACK_PERCENT_LEGENDARY":
			_apply_attack_percent(0.25)
		"STAT_ATTACK_SPEED_PERCENT_COMMON":
			_apply_attack_speed_percent(0.05)
		"STAT_ATTACK_SPEED_PERCENT_FINE":
			_apply_attack_speed_percent(0.10)
		"STAT_ATTACK_SPEED_PERCENT_RARE":
			_apply_attack_speed_percent(0.15)
		"STAT_ATTACK_SPEED_PERCENT_EPIC":
			_apply_attack_speed_percent(0.20)
		"STAT_ATTACK_SPEED_PERCENT_LEGENDARY":
			_apply_attack_speed_percent(0.25)
		"STAT_DEFENSE_FLAT_COMMON":
			_apply_defense_flat(5)
		"STAT_DEFENSE_FLAT_FINE":
			_apply_defense_flat(10)
		"STAT_DEFENSE_FLAT_RARE":
			_apply_defense_flat(15)
		"STAT_DEFENSE_FLAT_EPIC":
			_apply_defense_flat(20)
		"STAT_DEFENSE_FLAT_LEGENDARY":
			_apply_defense_flat(25)
		"STAT_LUCK_COMMON":
			_apply_luck(5)
		"STAT_LUCK_FINE":
			_apply_luck(10)
		"STAT_LUCK_RARE":
			_apply_luck(15)
		"STAT_LUCK_EPIC":
			_apply_luck(20)
		"STAT_LUCK_LEGENDARY":
			_apply_luck(25)
		"TEAM_HP_UP":
			if roster_manager != null:
				roster_manager.apply_team_hp_bonus(0.1)
		"TEAM_ATTACK_UP":
			if roster_manager != null:
				roster_manager.apply_team_attack_bonus(0.1)
		_:
			push_warning("Unknown stat reward id: " + reward_id)


func _apply_max_hp_percent(value: float) -> void:
	if roster_manager != null and roster_manager.has_method("apply_permanent_percent_bonus"):
		roster_manager.apply_permanent_percent_bonus("max_hp", value)


func _apply_attack_percent(value: float) -> void:
	if roster_manager != null and roster_manager.has_method("apply_permanent_percent_bonus"):
		roster_manager.apply_permanent_percent_bonus("attack_damage", value)


func _apply_attack_speed_percent(value: float) -> void:
	if roster_manager != null and roster_manager.has_method("apply_attack_speed_bonus"):
		roster_manager.apply_attack_speed_bonus(value)


func _apply_defense_flat(value: int) -> void:
	if roster_manager != null and roster_manager.has_method("apply_permanent_flat_bonus"):
		roster_manager.apply_permanent_flat_bonus("defense", float(value))


func _apply_luck(value: int) -> void:
	if run_modifier_manager != null and run_modifier_manager.has_method("add_luck"):
		run_modifier_manager.add_luck(float(value))


func _apply_unit_reward(reward: Dictionary) -> void:
	var reward_id: String = str(reward["id"])
	var added_unit: bool = false

	if reward_id == "ADD_RANDOM_UNIT":
		if roster_manager != null:
			added_unit = roster_manager.add_random_unit()
	else:
		var unit_id: String = str(reward.get("unit_id", ""))
		if unit_id != "" and roster_manager != null:
			added_unit = roster_manager.add_unit_by_id(unit_id)
		elif unit_id == "":
			push_warning("Unit reward is missing unit_id: " + reward_id)

	if not added_unit:
		DEBUG_LOG_SCRIPT.info("Unit reward was not added. Roster may be full.")


func _apply_relic_reward(reward: Dictionary) -> void:
	if relic_manager == null:
		push_warning("RewardManager has no RelicManager.")
		return

	if not reward.has("relic_data"):
		push_warning("Relic reward is missing relic_data.")
		return

	var relic_data: Resource = reward["relic_data"] as Resource
	relic_manager.add_relic(relic_data)


func _get_reward_type(reward: Dictionary) -> String:
	if not reward.has("type"):
		return ""

	return str(reward["type"])


func _build_reward_pool() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []

	var stat_rewards: Array[Dictionary] = _build_stat_rewards()
	for stat_reward: Dictionary in stat_rewards:
		pool.append(stat_reward)

	if _can_offer_unit_rewards():
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_RANDOM_UNIT",
			"unit_id": "",
			"name": "获得随机单位",
			"description": "添加一个随机单位到队伍。",
			"rarity": "COMMON",
		})
		var unit_rewards: Array[Dictionary] = _build_unit_rewards()
		for unit_reward: Dictionary in unit_rewards:
			pool.append(unit_reward)

	if relic_manager != null:
		var relic_rewards: Array[Dictionary] = relic_manager.get_available_relic_reward_options()
		for relic_reward in relic_rewards:
			pool.append(relic_reward)

	return _filter_unavailable_unit_rewards(pool)


func _can_offer_unit_rewards() -> bool:
	if roster_manager == null:
		return true

	return roster_manager.can_add_unit()


func _filter_unavailable_unit_rewards(pool: Array[Dictionary]) -> Array[Dictionary]:
	if roster_manager == null or not roster_manager.has_method("is_unit_id_available_for_run"):
		return pool

	var filtered_pool: Array[Dictionary] = []
	for reward: Dictionary in pool:
		if str(reward.get("type", "")) != REWARD_TYPE_UNIT:
			filtered_pool.append(reward)
			continue

		var unit_id: String = str(reward.get("unit_id", ""))
		if unit_id == "" or bool(roster_manager.is_unit_id_available_for_run(unit_id)):
			filtered_pool.append(reward)

	return filtered_pool


func _build_stat_rewards() -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []

	const RARITY_VALUES: Dictionary = {
		"COMMON": 5,
		"FINE": 10,
		"RARE": 15,
		"EPIC": 20,
		"LEGENDARY": 25,
	}

	var stat_definitions: Array[Dictionary] = [
		{"id_prefix": "STAT_MAX_HP_PERCENT", "name_template": "全队生命 +{value}%", "description_template": "所有友军最大生命提高 {value}%。", "is_percent": true},
		{"id_prefix": "STAT_ATTACK_PERCENT", "name_template": "全队攻击 +{value}%", "description_template": "所有友军攻击力提高 {value}%。", "is_percent": true},
		{"id_prefix": "STAT_ATTACK_SPEED_PERCENT", "name_template": "全队攻速 +{value}%", "description_template": "所有友军攻击速度提高 {value}%。", "is_percent": true},
		{"id_prefix": "STAT_DEFENSE_FLAT", "name_template": "全队防御 +{value}", "description_template": "所有友军防御力提高 {value}。", "is_percent": false},
		{"id_prefix": "STAT_LUCK", "name_template": "幸运 +{value}", "description_template": "幸运值提高 {value}，影响奖励稀有度概率。", "is_percent": false},
	]

	for stat_def: Dictionary in stat_definitions:
		for rarity: String in REWARD_RARITY_ORDER:
			if not RARITY_VALUES.has(rarity):
				continue
			var value: int = int(RARITY_VALUES[rarity])
			var id: String = str(stat_def["id_prefix"]) + "_" + rarity
			var name: String = str(stat_def["name_template"]).format({"value": value})
			var description: String = str(stat_def["description_template"]).format({"value": value})
			rewards.append({
				"type": REWARD_TYPE_STAT,
				"id": id,
				"name": name,
				"description": description,
				"rarity": rarity,
			})

	return rewards


func _build_unit_rewards() -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []

	if roster_manager == null or not roster_manager.has_method("get_all_unit_pool"):
		return rewards

	var unit_pool: Array = roster_manager.get_all_unit_pool()
	for unit_data: Resource in unit_pool:
		if unit_data == null:
			continue

		var unit_id: String = ""
		var unit_name: String = ""
		var rarity: String = "COMMON"

		if unit_data.has_method("get"):
			var type_value = unit_data.get("unit_type")
			if type_value != null:
				unit_id = str(type_value)
			var name_value = unit_data.get("unit_name_cn")
			if name_value != null and str(name_value).strip_edges() != "":
				unit_name = str(name_value)
			else:
				var name_en_value = unit_data.get("unit_name")
				if name_en_value != null:
					unit_name = str(name_en_value)
			var rarity_value = unit_data.get("rarity")
			if rarity_value != null:
				rarity = str(rarity_value)
		else:
			# Fallback for direct property access
			if "unit_type" in unit_data:
				unit_id = str(unit_data.unit_type)
			if "unit_name_cn" in unit_data and str(unit_data.unit_name_cn).strip_edges() != "":
				unit_name = str(unit_data.unit_name_cn)
			elif "unit_name" in unit_data:
				unit_name = str(unit_data.unit_name)
			if "rarity" in unit_data:
				rarity = str(unit_data.rarity)

		if unit_id == "":
			continue

		var reward_id: String = "ADD_UNIT_" + unit_id.to_upper()
		rewards.append({
			"type": REWARD_TYPE_UNIT,
			"id": reward_id,
			"unit_id": unit_id,
			"name": "获得" + unit_name,
			"description": "添加一名" + unit_name + "到队伍。",
			"rarity": rarity,
		})

	return rewards


func _roll_reward_rarity(encounter_type: String, current_round: int) -> String:
	var round_index: int = maxi(0, current_round - 1)
	var encounter_bonus: float = float(ENCOUNTER_BONUS.get(encounter_type, 0.0))
	var luck_value: float = 0.0
	if run_modifier_manager != null and run_modifier_manager.has_method("get_luck"):
		luck_value = run_modifier_manager.get_luck()

	var modified: Dictionary = {}
	for rarity: String in REWARD_RARITY_ORDER:
		var base: float = float(BASE_RARITY_CHANCE.get(rarity, 0.0))
		var per_round: float = float(RARITY_CHANCE_PER_ROUND.get(rarity, 0.0))
		var raw: float = base + round_index * per_round + encounter_bonus
		modified[rarity] = minf(raw * (1.0 + luck_value / 100.0), 100.0)

	var final_chances: Dictionary = {}
	var remaining: float = 100.0
	for rarity: String in REWARD_RARITY_ROLL_ORDER:
		var chance: float = minf(float(modified.get(rarity, 0.0)), remaining)
		final_chances[rarity] = chance
		remaining -= chance

	var roll: float = randf() * 100.0
	var cumulative: float = 0.0
	for rarity: String in REWARD_RARITY_ROLL_ORDER:
		cumulative += float(final_chances.get(rarity, 0.0))
		if roll < cumulative:
			return rarity

	return "COMMON"


func _pick_reward_by_rarity(pool: Array[Dictionary], rarity: String) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for reward: Dictionary in pool:
		if _get_reward_rarity(reward) == rarity:
			candidates.append(reward)

	if not candidates.is_empty():
		return candidates[randi_range(0, candidates.size() - 1)]

	# 空池兜底：先向低稀有度查找，再向高稀有度查找
	var rarity_index: int = REWARD_RARITY_ORDER.find(rarity)

	# 向低查找
	for i: int in range(rarity_index - 1, -1, -1):
		var lower_rarity: String = REWARD_RARITY_ORDER[i]
		for reward: Dictionary in pool:
			if _get_reward_rarity(reward) == lower_rarity:
				candidates.append(reward)
		if not candidates.is_empty():
			return candidates[randi_range(0, candidates.size() - 1)]

	# 向高查找
	for i: int in range(rarity_index + 1, REWARD_RARITY_ORDER.size()):
		var higher_rarity: String = REWARD_RARITY_ORDER[i]
		for reward: Dictionary in pool:
			if _get_reward_rarity(reward) == higher_rarity:
				candidates.append(reward)
		if not candidates.is_empty():
			return candidates[randi_range(0, candidates.size() - 1)]

	return {}


func _get_reward_rarity(reward: Dictionary) -> String:
	if reward.has("rarity") and str(reward["rarity"]).strip_edges() != "":
		return str(reward["rarity"])

	if reward.has("relic_data"):
		var relic_data: Resource = reward["relic_data"] as Resource
		if relic_data != null and relic_data.has_method("get"):
			var relic_rarity = relic_data.get("rarity")
			if relic_rarity != null:
				return str(relic_rarity)

	return "COMMON"


func _remove_reward_from_pool(pool: Array[Dictionary], reward: Dictionary) -> void:
	var reward_key: String = _get_reward_key(reward)

	for index: int in range(pool.size() - 1, -1, -1):
		var pool_reward: Dictionary = pool[index]
		if _get_reward_key(pool_reward) == reward_key:
			pool.remove_at(index)


func _get_reward_key(reward: Dictionary) -> String:
	return _get_reward_type(reward) + ":" + str(reward.get("id", ""))
