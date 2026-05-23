class_name RewardManager
extends RefCounted

const REWARD_TYPE_STAT: String = "STAT"
const REWARD_TYPE_UNIT: String = "UNIT"
const REWARD_TYPE_RELIC: String = "RELIC"
const ENCOUNTER_TYPE_ELITE: String = "ELITE"

var relic_manager: RelicManager = null
var roster_manager: Variant = null


func setup(
	configured_relic_manager: RelicManager,
	configured_roster_manager: Variant
) -> void:
	relic_manager = configured_relic_manager
	roster_manager = configured_roster_manager


func roll_reward_options(reward_count: int, encounter_type: String = "") -> Array[Dictionary]:
	var pool: Array[Dictionary] = _build_reward_pool()
	var rolled_rewards: Array[Dictionary] = []

	while not pool.is_empty() and rolled_rewards.size() < reward_count:
		var selected_index: int = _get_reward_roll_index(pool, encounter_type)
		var selected_reward: Dictionary = pool[selected_index]
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
		"TEAM_HP_UP":
			if roster_manager != null:
				roster_manager.apply_team_hp_bonus(0.1)
		"TEAM_ATTACK_UP":
			if roster_manager != null:
				roster_manager.apply_team_attack_bonus(0.1)
		_:
			push_warning("Unknown stat reward id: " + reward_id)


func _apply_unit_reward(reward: Dictionary) -> void:
	var reward_id: String = str(reward["id"])
	var added_unit: bool = false

	match reward_id:
		"ADD_RANDOM_UNIT":
			if roster_manager != null:
				added_unit = roster_manager.add_random_unit()
		"ADD_WARRIOR":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("warrior")
		"ADD_ARCHER":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("archer")
		"ADD_ASSASSIN":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("assassin")
		"ADD_TANK":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("tank")
		"ADD_MAGE":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("mage")
		"ADD_PRIEST":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("priest")
		"ADD_BARD":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("bard")
		"ADD_FOREST_DRUID":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("forest_druid")
		"ADD_PLAGUE_CASTER":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("plague_caster")
		"ADD_GUARDIAN_CAPTAIN":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("guardian_captain")
		"ADD_WIND_CHANTER":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("wind_chanter")
		"ADD_GREATSWORD_KNIGHT":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("greatsword_knight")
		"ADD_BOMB_THROWER":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("bomb_thrower")
		"ADD_CLERIC":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("cleric")
		"ADD_ALCHEMIST":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("alchemist")
		"ADD_NECROMANCER":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("necromancer")
		"ADD_PUPPET_WARLOCK":
			if roster_manager != null:
				added_unit = roster_manager.add_unit_by_id("puppet_warlock")
		_:
			push_warning("Unknown unit reward id: " + reward_id)

	if not added_unit:
		print("Unit reward was not added. Roster may be full.")


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

	pool.append({
		"type": REWARD_TYPE_STAT,
		"id": "TEAM_HP_UP",
		"name": "全队生命 +10%",
		"description": "所有友军最大生命提高 10%。",
		"rarity": "COMMON",
	})
	pool.append({
		"type": REWARD_TYPE_STAT,
		"id": "TEAM_ATTACK_UP",
		"name": "全队攻击 +10%",
		"description": "所有友军攻击力提高 10%。",
		"rarity": "COMMON",
	})

	if _can_offer_unit_rewards():
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_RANDOM_UNIT",
			"unit_id": "",
			"name": "获得随机单位",
			"description": "添加一个随机单位到队伍。",
			"rarity": "COMMON",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_WARRIOR",
			"unit_id": "warrior",
			"name": "获得战士",
			"description": "添加一名战士到队伍。",
			"rarity": "COMMON",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_ARCHER",
			"unit_id": "archer",
			"name": "获得弓手",
			"description": "添加一名弓手到队伍。",
			"rarity": "COMMON",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_ASSASSIN",
			"unit_id": "assassin",
			"name": "获得刺客",
			"description": "添加一名刺客到队伍。",
			"rarity": "FINE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_TANK",
			"unit_id": "tank",
			"name": "获得重装坦克",
			"description": "添加一名重装坦克到队伍。",
			"rarity": "COMMON",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_MAGE",
			"unit_id": "mage",
			"name": "获得法师",
			"description": "添加一名法师到队伍。",
			"rarity": "COMMON",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_PRIEST",
			"unit_id": "priest",
			"name": "获得牧师",
			"description": "添加一名牧师到队伍。",
			"rarity": "COMMON",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_BARD",
			"unit_id": "bard",
			"name": "获得吟游诗人",
			"description": "添加一名吟游诗人到队伍。",
			"rarity": "COMMON",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_FOREST_DRUID",
			"unit_id": "forest_druid",
			"name": "获得森林德鲁伊",
			"description": "添加一名森林德鲁伊到队伍。",
			"rarity": "FINE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_PLAGUE_CASTER",
			"unit_id": "plague_caster",
			"name": "获得瘟疫术士",
			"description": "添加一名瘟疫术士到队伍。",
			"rarity": "FINE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_GUARDIAN_CAPTAIN",
			"unit_id": "guardian_captain",
			"name": "获得守护队长",
			"description": "添加一名守护队长到队伍。",
			"rarity": "FINE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_WIND_CHANTER",
			"unit_id": "wind_chanter",
			"name": "获得风语者",
			"description": "添加一名风语者到队伍。",
			"rarity": "FINE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_GREATSWORD_KNIGHT",
			"unit_id": "greatsword_knight",
			"name": "获得巨剑骑士",
			"description": "添加一名巨剑骑士到队伍。",
			"rarity": "RARE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_BOMB_THROWER",
			"unit_id": "bomb_thrower",
			"name": "获得爆弹投手",
			"description": "添加一名爆弹投手到队伍。",
			"rarity": "RARE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_CLERIC",
			"unit_id": "cleric",
			"name": "获得神官",
			"description": "添加一名神官到队伍。",
			"rarity": "RARE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_ALCHEMIST",
			"unit_id": "alchemist",
			"name": "获得炼金术士",
			"description": "添加一名炼金术士到队伍。",
			"rarity": "RARE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_NECROMANCER",
			"unit_id": "necromancer",
			"name": "获得亡灵法师",
			"description": "添加一名亡灵法师到队伍。",
			"rarity": "RARE",
		})
		pool.append({
			"type": REWARD_TYPE_UNIT,
			"id": "ADD_PUPPET_WARLOCK",
			"unit_id": "puppet_warlock",
			"name": "获得傀儡术士",
			"description": "添加一名傀儡术士到队伍。",
			"rarity": "RARE",
		})

	if relic_manager != null:
		var relic_rewards: Array[Dictionary] = relic_manager.get_available_relic_reward_options()
		for relic_reward in relic_rewards:
			pool.append(relic_reward)

	return pool


func _can_offer_unit_rewards() -> bool:
	if roster_manager == null:
		return true

	return roster_manager.can_add_unit()


func _get_reward_roll_index(pool: Array[Dictionary], encounter_type: String) -> int:
	if encounter_type == ENCOUNTER_TYPE_ELITE and randf() < 0.6:
		var relic_indexes: Array[int] = _get_reward_indexes_by_type(pool, REWARD_TYPE_RELIC)
		if not relic_indexes.is_empty():
			var relic_roll_index: int = randi_range(0, relic_indexes.size() - 1)
			return relic_indexes[relic_roll_index]

	return randi_range(0, pool.size() - 1)


func _get_reward_indexes_by_type(pool: Array[Dictionary], reward_type: String) -> Array[int]:
	var indexes: Array[int] = []

	for index: int in range(pool.size()):
		var reward: Dictionary = pool[index]
		if _get_reward_type(reward) == reward_type:
			indexes.append(index)

	return indexes


func _remove_reward_from_pool(pool: Array[Dictionary], reward: Dictionary) -> void:
	var reward_key: String = _get_reward_key(reward)

	for index: int in range(pool.size() - 1, -1, -1):
		var pool_reward: Dictionary = pool[index]
		if _get_reward_key(pool_reward) == reward_key:
			pool.remove_at(index)


func _get_reward_key(reward: Dictionary) -> String:
	return _get_reward_type(reward) + ":" + str(reward.get("id", ""))
