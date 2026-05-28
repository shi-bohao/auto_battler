class_name MerchantManager
extends RefCounted


const MAX_POPULATION: int = 20
const POPULATION_BASE_COST: int = 3
const POPULATION_COST_MULTIPLIER: int = 2
const RELIC_REFRESH_BASE_COST: int = 2
const RELIC_REFRESH_COST_MULTIPLIER: int = 2
const RELIC_SLOTS: int = 4
const SPECIAL_SLOTS: int = 4

const RELIC_PRICES: Dictionary = {
	"RARE": 8,
	"EPIC": 12,
	"LEGENDARY": 16,
}

const RELIC_RARITY_WEIGHTS: Dictionary = {
	"RARE": 50,
	"EPIC": 35,
	"LEGENDARY": 15,
}

const GLOBAL_BUFFS: Array[Dictionary] = [
	{"id": "war_banner_oath", "name_cn": "战旗誓言", "description_cn": "全队普攻伤害 +10%", "price": 8, "stat": "attack_damage", "ratio": 0.10, "mode": "percent"},
	{"id": "arcane_crystal", "name_cn": "秘术结晶", "description_cn": "全队技能伤害 +12%", "price": 10, "stat": "skill_damage_bonus", "ratio": 0.12, "mode": "percent"},
	{"id": "solid_forging", "name_cn": "牢固铸造", "description_cn": "全队最大生命 +15%", "price": 9, "stat": "max_hp", "ratio": 0.15, "mode": "percent"},
	{"id": "sharp_engrave", "name_cn": "锐利刻印", "description_cn": "全队暴击率 +6%", "price": 11, "stat": "crit_chance", "ratio": 0.06, "mode": "flat"},
	{"id": "swift_tempo", "name_cn": "神速节拍", "description_cn": "全队攻击间隔 -10%", "price": 12, "stat": "attack_interval", "ratio": -0.10, "mode": "percent"},
	{"id": "holy_revelation", "name_cn": "神圣启示", "description_cn": "全队治疗效果 +25%", "price": 9, "stat": "healing_power", "ratio": 0.25, "mode": "percent"},
	{"id": "endless_pulse", "name_cn": "不竭脉络", "description_cn": "全队魔力回复 +15%", "price": 11, "stat": "mana_regen_per_second", "ratio": 0.15, "mode": "percent"},
	{"id": "eternal_oath", "name_cn": "永恒誓约", "description_cn": "全队战斗内首次致死保留 1HP（每场每单位 1 次）", "price": 15, "stat": "death_prevention", "ratio": 1.0, "mode": "special"},
]

var relic_manager: RelicManager = null
var roster_manager: Variant = null
var relic_shelf: Array[Dictionary] = []
var special_shelf: Array[Dictionary] = []
var relic_refresh_count: int = 0
var population_buy_count: int = 0
var purchased_buff_ids: Array[String] = []

func setup(relic_manager_value: RelicManager, roster_manager_value: Variant) -> void:
	relic_manager = relic_manager_value
	roster_manager = roster_manager_value


func enter_merchant() -> void:
	relic_refresh_count = 0
	population_buy_count = 0
	purchased_buff_ids.clear()
	_generate_relic_shelf()
	_generate_special_shelf()


func get_relic_shelf() -> Array[Dictionary]:
	return relic_shelf


func get_special_shelf() -> Array[Dictionary]:
	return special_shelf


func get_relic_refresh_cost() -> int:
	return RELIC_REFRESH_BASE_COST * int(pow(RELIC_REFRESH_COST_MULTIPLIER, relic_refresh_count))


func get_population_cost() -> int:
	return POPULATION_BASE_COST * int(pow(POPULATION_COST_MULTIPLIER, population_buy_count))


func can_buy_population() -> bool:
	return roster_manager.max_active_units < MAX_POPULATION


func refresh_relic_shelf() -> void:
	relic_refresh_count += 1
	_generate_relic_shelf()


func buy_population() -> void:
	population_buy_count += 1
	roster_manager.max_active_units = mini(roster_manager.max_active_units + 1, MAX_POPULATION)
	roster_manager.max_total_units = roster_manager.max_active_units + roster_manager.max_bench_units


func update_population_item_in_shelf() -> void:
	for i: int in range(special_shelf.size()):
		var item: Dictionary = special_shelf[i]
		if item.get("type", "") == "population":
			if can_buy_population():
				special_shelf[i] = _create_population_item()
			else:
				special_shelf[i] = {
					"type": "population",
					"display_name": "人口已达上限",
					"description": "上场单位上限已达 " + str(MAX_POPULATION),
					"price": 0,
					"is_sold": true,
					"buff_id": "",
				}
			return


func buy_relic_item(index: int) -> Dictionary:
	if index < 0 or index >= relic_shelf.size():
		return {}
	var item: Dictionary = relic_shelf[index]
	if item.get("is_sold", false):
		return {}
	relic_shelf[index]["is_sold"] = true
	return item


func buy_special_item(index: int) -> Dictionary:
	if index < 0 or index >= special_shelf.size():
		return {}
	var item: Dictionary = special_shelf[index]
	if item.get("is_sold", false):
		return {}
	special_shelf[index]["is_sold"] = true
	var buff_id: String = item.get("buff_id", "")
	if buff_id != "":
		purchased_buff_ids.append(buff_id)
	return item


func get_relic_price_for_rarity(rarity: String) -> int:
	return RELIC_PRICES.get(rarity, 8)


func _generate_relic_shelf() -> void:
	relic_shelf.clear()
	var used_relic_ids: Array[String] = []
	for i in range(RELIC_SLOTS):
		var rarity: String = _roll_relic_rarity()
		var relic_data: Variant = _get_random_relic_of_rarity(rarity, used_relic_ids)
		if relic_data == null:
			continue
		var actual_rarity: String = _get_relic_rarity_str(relic_data)
		var relic_id: String = _get_relic_id_str(relic_data)
		used_relic_ids.append(relic_id)
		var item: Dictionary = {
			"type": "relic",
			"rarity": actual_rarity,
			"price": get_relic_price_for_rarity(actual_rarity),
			"relic_data": relic_data,
			"display_name": _get_relic_display_name(relic_data),
			"description": _get_relic_description(relic_data),
			"is_sold": false,
		}
		relic_shelf.append(item)

func _generate_special_shelf() -> void:
	special_shelf.clear()
	var unit_item: Dictionary = _create_high_rarity_unit_item()
	special_shelf.append(unit_item)

	if can_buy_population():
		special_shelf.append(_create_population_item())

	var available_buffs: Array[Dictionary] = _get_available_buffs()
	available_buffs.shuffle()
	for buff: Dictionary in available_buffs:
		if special_shelf.size() >= SPECIAL_SLOTS:
			break
		special_shelf.append(_create_buff_item(buff))

	while special_shelf.size() < SPECIAL_SLOTS:
		if can_buy_population() and special_shelf.size() < SPECIAL_SLOTS:
			special_shelf.append(_create_population_item())
			continue
		break


func _create_high_rarity_unit_item() -> Dictionary:
	return {
		"type": "unit",
		"display_name": "高稀有度单位",
		"description": "获得一个随机稀有及以上单位",
		"price": 5,
		"is_sold": false,
		"buff_id": "",
	}


func _create_population_item() -> Dictionary:
	return {
		"type": "population",
		"display_name": "人口提升 +1",
		"description": "上场单位上限 +1（当前：" + str(roster_manager.max_active_units) + "/" + str(MAX_POPULATION) + "）",
		"price": get_population_cost(),
		"is_sold": false,
		"buff_id": "",
	}


func _create_buff_item(buff: Dictionary) -> Dictionary:
	return {
		"type": "buff",
		"display_name": buff.get("name_cn", ""),
		"description": buff.get("description_cn", ""),
		"price": int(buff.get("price", 10)),
		"is_sold": false,
		"buff_id": buff.get("id", ""),
		"buff_data": buff,
	}


func _get_available_buffs() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for buff: Dictionary in GLOBAL_BUFFS:
		if buff.get("id", "") not in purchased_buff_ids:
			available.append(buff)
	return available


func _roll_relic_rarity() -> String:
	var total: int = 0
	for rarity: String in RELIC_RARITY_WEIGHTS:
		total += int(RELIC_RARITY_WEIGHTS[rarity])
	var roll: int = randi() % total
	var cumulative: int = 0
	for rarity: String in RELIC_RARITY_WEIGHTS:
		cumulative += int(RELIC_RARITY_WEIGHTS[rarity])
		if roll < cumulative:
			return rarity
	return "RARE"


func _get_random_relic_of_rarity(rarity: String, used_ids: Array[String] = []) -> Variant:
	if relic_manager == null:
		return null
	var all_options: Array = relic_manager.get_available_relic_reward_options()
	var filtered: Array[Dictionary] = []
	for option: Dictionary in all_options:
		var option_rarity: String = str(option.get("rarity", ""))
		var option_id: String = str(option.get("id", ""))
		if option_id in used_ids:
			continue
		if option_rarity == rarity:
			filtered.append(option)
	if filtered.is_empty():
		for option: Dictionary in all_options:
			var option_id: String = str(option.get("id", ""))
			if option_id in used_ids:
				continue
			filtered.append(option)
	if filtered.is_empty():
		return null
	return filtered[randi() % filtered.size()].get("relic_data", null)


func _get_relic_rarity_str(relic_data: Variant) -> String:
	if relic_data == null:
		return "RARE"
	var r: Variant = relic_data.get("rarity")
	if r != null and str(r) != "" and str(r) != "<null>":
		return str(r)
	return "RARE"


func _get_relic_id_str(relic_data: Variant) -> String:
	if relic_data == null:
		return ""
	var rid: Variant = relic_data.get("relic_id")
	if rid != null and str(rid) != "" and str(rid) != "<null>":
		return str(rid)
	return ""


func _get_relic_display_name(relic_data: Variant) -> String:
	if relic_data == null:
		return "未知遗物"
	if relic_data.has_method("get") or "relic_name_cn" in relic_data:
		var name_cn: String = str(relic_data.get("relic_name_cn"))
		if name_cn != "" and name_cn != "<null>":
			return name_cn
	if "relic_name" in relic_data:
		return str(relic_data.get("relic_name"))
	return "遗物"


func _get_relic_description(relic_data: Variant) -> String:
	if relic_data == null:
		return ""
	if "description_cn" in relic_data:
		var desc: String = str(relic_data.get("description_cn"))
		if desc != "" and desc != "<null>":
			return desc
	if "description" in relic_data:
		return str(relic_data.get("description"))
	return ""
