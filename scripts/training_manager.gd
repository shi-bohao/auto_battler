class_name TrainingManager
extends RefCounted


const TRAINING_DUMMY_DATA: Resource = preload("res://data/enemies/training_dummy.tres")

const DUMMY_COUNT_TABLE: Array[Dictionary] = [
	{"min_round": 1, "max_round": 9, "count": 3, "timer": 18.0},
	{"min_round": 10, "max_round": 19, "count": 4, "timer": 20.0},
	{"min_round": 20, "max_round": 99, "count": 5, "timer": 22.0},
]

const DROP_WEIGHTS: Array[Dictionary] = [
	{"type": "gold", "weight": 35},
	{"type": "relic_common", "weight": 25},
	{"type": "relic_rare", "weight": 15},
	{"type": "relic_epic", "weight": 5},
	{"type": "star_up", "weight": 8},
	{"type": "permanent_stat", "weight": 12},
]

const PERMANENT_STAT_TABLE: Array[Dictionary] = [
	{"stat": "max_hp", "ratio": 0.05, "mode": "percent", "weight": 30},
	{"stat": "attack_damage", "ratio": 0.05, "mode": "percent", "weight": 30},
	{"stat": "defense", "ratio": 5.0, "mode": "flat", "weight": 20},
	{"stat": "skill_damage_bonus", "ratio": 0.05, "mode": "percent", "weight": 10},
	{"stat": "crit_chance", "ratio": 0.03, "mode": "flat", "weight": 10},
]

const HP_PER_ROUND: int = 20
const GOLD_DROP_MIN: int = 3
const GOLD_DROP_MAX: int = 8
const STAR_UP_FALLBACK_GOLD: int = 8

var relic_manager: Variant = null
var roster_manager: Variant = null
var economy_manager: Variant = null
var training_timer: float = 0.0
var training_duration: float = 18.0
var is_training_active: bool = false
var drops_collected: Array[Dictionary] = []


func setup(relic_mgr: Variant, roster_mgr: Variant, economy_mgr: Variant) -> void:
	relic_manager = relic_mgr
	roster_manager = roster_mgr
	economy_manager = economy_mgr


func get_training_config(current_round: int) -> Dictionary:
	for entry: Dictionary in DUMMY_COUNT_TABLE:
		if current_round >= int(entry["min_round"]) and current_round <= int(entry["max_round"]):
			return entry
	return DUMMY_COUNT_TABLE[DUMMY_COUNT_TABLE.size() - 1]


func create_training_encounter(current_round: int) -> Dictionary:
	var config: Dictionary = get_training_config(current_round)
	var count: int = int(config.get("count", 3))
	training_duration = float(config.get("timer", 18.0))
	var dummy_hp: int = 120 + current_round * HP_PER_ROUND
	var units: Array[Dictionary] = []
	for i: int in range(count):
		units.append({
			"unit_id": "training_dummy",
			"display_name": "训练木桩",
			"position": Vector2.ZERO,
			"star": 1,
			"is_boss": false,
			"hp_multiplier": 1.0,
			"attack_multiplier": 1.0,
			"defense_bonus": 0,
			"mana_regen_multiplier": 1.0,
			"resource_path": "res://data/enemies/training_dummy.tres",
		})
	return {
		"encounter_id": "training_round_" + str(current_round),
		"encounter_name": "训练场",
		"encounter_type": "TRAINING",
		"enemy_hp_multiplier": float(dummy_hp) / 120.0,
		"enemy_attack_multiplier": 1.0,
		"enemy_defense_bonus": 0,
		"enemy_mana_regen_multiplier": 1.0,
		"enemy_count": count,
		"enemy_units": units,
	}


func start_training() -> void:
	is_training_active = true
	training_timer = 0.0
	drops_collected.clear()


func tick(delta: float) -> bool:
	if not is_training_active:
		return false
	training_timer += delta
	if training_timer >= training_duration:
		is_training_active = false
		return true
	return false


func end_training() -> void:
	is_training_active = false


func on_dummy_killed() -> Dictionary:
	var drop: Dictionary = _roll_drop()
	var actual_display: String = _apply_drop(drop)
	if actual_display != "":
		drop["display"] = actual_display
	drops_collected.append(drop)
	return drop


func get_drops_collected() -> Array[Dictionary]:
	return drops_collected


func _roll_drop() -> Dictionary:
	var total_weight: int = 0
	for entry: Dictionary in DROP_WEIGHTS:
		total_weight += int(entry["weight"])
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	var drop_type: String = "gold"
	for entry: Dictionary in DROP_WEIGHTS:
		cumulative += int(entry["weight"])
		if roll < cumulative:
			drop_type = str(entry["type"])
			break
	return _create_drop(drop_type)


func _create_drop(drop_type: String) -> Dictionary:
	match drop_type:
		"gold":
			var amount: int = randi_range(GOLD_DROP_MIN, GOLD_DROP_MAX)
			return {"type": "gold", "amount": amount, "display": "+" + str(amount) + " 金币"}
		"relic_common":
			return {"type": "relic", "rarity_pool": ["COMMON", "FINE"], "display": "获得遗物（普通/精良）"}
		"relic_rare":
			return {"type": "relic", "rarity_pool": ["RARE"], "display": "获得遗物（稀有）"}
		"relic_epic":
			return {"type": "relic", "rarity_pool": ["EPIC"], "display": "获得遗物（史诗）"}
		"star_up":
			return {"type": "star_up", "display": "升星券"}
		"permanent_stat":
			var stat_entry: Dictionary = _roll_permanent_stat()
			return {"type": "permanent_stat", "stat_data": stat_entry, "display": _get_stat_display(stat_entry)}
		_:
			return {"type": "gold", "amount": GOLD_DROP_MIN, "display": "+" + str(GOLD_DROP_MIN) + " 金币"}


func _apply_drop(drop: Dictionary) -> String:
	var drop_type: String = drop.get("type", "")
	match drop_type:
		"gold":
			if economy_manager != null:
				economy_manager.add_gold(int(drop.get("amount", 0)))
			return drop.get("display", "")
		"relic":
			return _apply_relic_drop(drop)
		"star_up":
			return _apply_star_up()
		"permanent_stat":
			return _apply_permanent_stat_drop(drop)
		_:
			return ""


func _apply_relic_drop(drop: Dictionary) -> String:
	if relic_manager == null:
		return ""
	var rarity_pool: Array = drop.get("rarity_pool", ["COMMON"])
	var all_options: Array = relic_manager.get_available_relic_reward_options()
	var filtered: Array[Dictionary] = []
	for option: Dictionary in all_options:
		if str(option.get("rarity", "")) in rarity_pool:
			filtered.append(option)
	if filtered.is_empty():
		if economy_manager != null:
			economy_manager.add_gold(5)
		return "无匹配遗物，获得 5 金币"
	var selected: Dictionary = filtered[randi() % filtered.size()]
	var relic_data: Variant = selected.get("relic_data", null)
	if relic_data != null:
		relic_manager.add_relic(relic_data)
		var name: String = str(selected.get("name", "遗物"))
		return "获得遗物：" + name
	return ""


func _apply_star_up() -> String:
	if roster_manager == null:
		return ""
	var active: Array[Dictionary] = roster_manager.get_active_roster()
	var candidates: Array[Dictionary] = []
	for item: Dictionary in active:
		if int(item.get("star", 1)) == 1:
			candidates.append(item)
	if candidates.is_empty():
		if economy_manager != null:
			economy_manager.add_gold(STAR_UP_FALLBACK_GOLD)
		return "升星券（无可用单位，获得 " + str(STAR_UP_FALLBACK_GOLD) + " 金币）"
	var target: Dictionary = candidates[randi() % candidates.size()]
	var roster_id: int = int(target.get("roster_id", -1))
	if roster_id > 0:
		roster_manager.set_unit_star_by_roster_id(roster_id, 2)
		var unit_data: Resource = target.get("unit_data", null) as Resource
		var unit_name: String = "单位"
		if unit_data != null:
			unit_name = str(unit_data.get("unit_name_cn"))
		return "升星券：" + unit_name + " 升至 2 星"
	return ""


func _apply_permanent_stat_drop(drop: Dictionary) -> String:
	if roster_manager == null:
		return ""
	var stat_data: Dictionary = drop.get("stat_data", {})
	var stat: String = stat_data.get("stat", "")
	var ratio: float = float(stat_data.get("ratio", 0.0))
	var mode: String = stat_data.get("mode", "percent")
	if stat == "":
		return ""
	if mode == "percent":
		roster_manager.apply_permanent_percent_bonus(stat, ratio)
	elif mode == "flat":
		roster_manager.apply_permanent_flat_bonus(stat, ratio)
	return _get_stat_display(stat_data)


func _roll_permanent_stat() -> Dictionary:
	var total_weight: int = 0
	for entry: Dictionary in PERMANENT_STAT_TABLE:
		total_weight += int(entry["weight"])
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for entry: Dictionary in PERMANENT_STAT_TABLE:
		cumulative += int(entry["weight"])
		if roll < cumulative:
			return entry
	return PERMANENT_STAT_TABLE[0]


func _get_stat_display(stat_entry: Dictionary) -> String:
	var stat: String = stat_entry.get("stat", "")
	var ratio: float = float(stat_entry.get("ratio", 0.0))
	var mode: String = stat_entry.get("mode", "percent")
	match stat:
		"max_hp":
			return "全队 HP +" + str(int(ratio * 100.0)) + "%"
		"attack_damage":
			return "全队 ATK +" + str(int(ratio * 100.0)) + "%"
		"defense":
			return "全队防御 +" + str(int(ratio))
		"skill_damage_bonus":
			return "全队技能伤害 +" + str(int(ratio * 100.0)) + "%"
		"crit_chance":
			return "全队暴击率 +" + str(int(ratio * 100.0)) + "%"
		_:
			if mode == "percent":
				return stat + " +" + str(int(ratio * 100.0)) + "%"
			return stat + " +" + str(int(ratio))
