class_name ShopManager
extends RefCounted

const UNIT_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/unit_catalog.gd")
const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const UNLOCKED_UNIT_SHOP_SLOT_COUNT: int = 5
const NEW_UNIT_SHOP_SLOT_COUNT: int = 2
const UNIT_SHOP_SLOT_COUNT: int = UNLOCKED_UNIT_SHOP_SLOT_COUNT + NEW_UNIT_SHOP_SLOT_COUNT
const RELIC_SHOP_SLOT_COUNT: int = 3
const SHOP_SLOT_COUNT: int = UNIT_SHOP_SLOT_COUNT + RELIC_SHOP_SLOT_COUNT
const UNIT_PRICE: int = 2
const REFRESH_COST: int = 1
const RARITY_PRICE_STEP: int = 2
const SHOP_ITEM_TYPE_UNIT: String = "UNIT"
const SHOP_ITEM_TYPE_RELIC: String = "RELIC"
const SHOP_ITEM_TYPE_EMPTY: String = "EMPTY"
const SHOP_CATEGORY_UNLOCKED_UNIT: String = "已解锁单位"
const SHOP_CATEGORY_NEW_UNIT: String = "新单位解锁"
const SHOP_CATEGORY_RELIC: String = "遗物"

const RARITY_ROLL_SERVICE_SCRIPT: Script = preload("res://scripts/game/rarity_roll_service.gd")

var relic_manager: RelicManager = null
var roster_manager: Variant = null
var run_modifier_manager: Variant = null
var unit_catalog: Variant = UNIT_CATALOG_SCRIPT.new()
var unit_text_formatter: Variant = UNIT_TEXT_FORMATTER_SCRIPT.new()
var current_shop_items: Array[Dictionary] = []
var rarity_roll_service: Variant = RARITY_ROLL_SERVICE_SCRIPT.new()
var current_round: int = 1


func setup(
	configured_warrior_data: Resource,
	configured_archer_data: Resource,
	configured_assassin_data: Resource,
	configured_tank_data: Resource = null,
	configured_mage_data: Resource = null,
	configured_priest_data: Resource = null,
	configured_bard_data: Resource = null,
	configured_forest_druid_data: Resource = null,
	configured_plague_caster_data: Resource = null,
	configured_guardian_captain_data: Resource = null,
	configured_wind_chanter_data: Resource = null,
	configured_greatsword_knight_data: Resource = null,
	configured_bomb_thrower_data: Resource = null,
	configured_cleric_data: Resource = null,
	configured_alchemist_data: Resource = null,
	configured_necromancer_data: Resource = null,
	configured_puppet_warlock_data: Resource = null,
	configured_relic_manager: RelicManager = null,
	configured_roster_manager: Variant = null,
	configured_run_modifier_manager: Variant = null
) -> void:
	unit_catalog.setup(
		configured_warrior_data,
		configured_archer_data,
		configured_assassin_data,
		configured_tank_data,
		configured_mage_data,
		configured_priest_data,
		configured_bard_data,
		configured_forest_druid_data,
		configured_plague_caster_data,
		configured_guardian_captain_data,
		configured_wind_chanter_data,
		configured_greatsword_knight_data,
		configured_bomb_thrower_data,
		configured_cleric_data,
		configured_alchemist_data,
		configured_necromancer_data,
		configured_puppet_warlock_data
	)
	relic_manager = configured_relic_manager
	roster_manager = configured_roster_manager
	run_modifier_manager = configured_run_modifier_manager


func roll_shop_items(round_value: int = 1) -> void:
	current_round = maxi(1, round_value)
	current_shop_items.clear()

	for _slot_index: int in range(UNLOCKED_UNIT_SHOP_SLOT_COUNT):
		current_shop_items.append(_create_random_unlocked_unit_shop_item())

	for _slot_index: int in range(NEW_UNIT_SHOP_SLOT_COUNT):
		current_shop_items.append(_create_random_new_unit_shop_item())

	for _slot_index: int in range(RELIC_SHOP_SLOT_COUNT):
		var relic_item: Dictionary = _create_random_relic_shop_item()
		current_shop_items.append(relic_item)


func get_shop_items() -> Array[Dictionary]:
	var shop_items: Array[Dictionary] = []

	for shop_item: Dictionary in current_shop_items:
		shop_items.append(shop_item.duplicate(true))

	return shop_items


func get_shop_item(index: int) -> Dictionary:
	if index < 0 or index >= current_shop_items.size():
		return {}

	return current_shop_items[index] as Dictionary


func mark_item_sold(index: int) -> void:
	if index < 0 or index >= current_shop_items.size():
		return

	var shop_item: Dictionary = current_shop_items[index] as Dictionary
	shop_item["is_sold"] = true
	current_shop_items[index] = shop_item


func get_refresh_cost() -> int:
	return REFRESH_COST


func get_unit_price(unit_data: Resource) -> int:
	return unit_catalog.get_unit_price(unit_data)


func get_relic_price(relic_data: Resource) -> int:
	if relic_data == null:
		return UNIT_PRICE

	return _get_price_for_rarity(_get_relic_rarity(relic_data))


func _create_random_unlocked_unit_shop_item() -> Dictionary:
	return _create_random_unit_shop_item(
		_get_unlocked_unit_pool(),
		SHOP_CATEGORY_UNLOCKED_UNIT,
		false,
		false,
		"暂无已解锁单位",
		"获得新单位后会加入该刷新池。"
	)


func _create_random_new_unit_shop_item() -> Dictionary:
	return _create_random_unit_shop_item(
		_get_locked_unit_pool(),
		SHOP_CATEGORY_NEW_UNIT,
		true,
		true,
		"新单位已全部解锁",
		"所有单位都会在前 5 个已解锁栏位中刷新。"
	)


func _create_random_unit_shop_item(
	unit_pool: Array[Resource],
	category: String,
	is_unlock_offer: bool,
	avoid_current_units: bool,
	empty_name: String,
	empty_description: String
) -> Dictionary:
	var available_pool: Array[Resource] = _filter_available_unit_pool(unit_pool, avoid_current_units)
	if available_pool.is_empty():
		return _create_empty_shop_item(empty_name, empty_description, category)

	var target_rarity: String = rarity_roll_service.roll_rarity(current_round, "SHOP", _get_luck())
	var unit_data: Resource = rarity_roll_service.pick_by_rarity(
		available_pool,
		target_rarity,
		Callable(self, "_get_unit_rarity")
	) as Resource

	if unit_data == null:
		return _create_empty_shop_item(empty_name, empty_description, category)

	var rarity: String = _get_unit_rarity(unit_data)
	return {
		"type": SHOP_ITEM_TYPE_UNIT,
		"category": category,
		"is_unlock_offer": is_unlock_offer,
		"unit_data": unit_data,
		"id": _get_unit_id(unit_data),
		"name": _get_unit_data_name(unit_data),
		"price": get_unit_price(unit_data),
		"description": _get_unit_description(unit_data),
		"rarity": rarity,
		"is_sold": false,
	}


func _filter_available_unit_pool(unit_pool: Array[Resource], avoid_current_units: bool) -> Array[Resource]:
	var available_pool: Array[Resource] = []
	for unit_data: Resource in unit_pool:
		if unit_data == null:
			continue

		var unit_id: String = _get_unit_id(unit_data)
		if avoid_current_units and unit_id != "" and _current_shop_has_unit_id(unit_id):
			continue

		available_pool.append(unit_data)

	return available_pool


func _current_shop_has_unit_id(unit_id: String) -> bool:
	for shop_item: Dictionary in current_shop_items:
		if str(shop_item.get("type", "")) == SHOP_ITEM_TYPE_UNIT and str(shop_item.get("id", "")) == unit_id:
			return true

	return false


func _create_empty_shop_item(name: String, description: String, category: String) -> Dictionary:
	return {
		"type": SHOP_ITEM_TYPE_EMPTY,
		"category": category,
		"name": name,
		"price": 0,
		"description": description,
		"rarity": "COMMON",
		"is_sold": true,
	}


func _create_random_relic_shop_item() -> Dictionary:
	var relic_pool: Array[Dictionary] = _get_available_relic_shop_pool()
	if relic_pool.is_empty():
		return _create_empty_shop_item("暂无可购买遗物", "已拥有的遗物不会重复出现在商店。", SHOP_CATEGORY_RELIC)

	var target_rarity: String = rarity_roll_service.roll_rarity(current_round, "SHOP", _get_luck())
	var relic_reward: Dictionary = rarity_roll_service.pick_by_rarity(
		relic_pool,
		target_rarity,
		Callable(self, "_get_relic_reward_rarity")
	)

	if relic_reward == null:
		return _create_empty_shop_item("暂无可购买遗物", "遗物数据缺失。", SHOP_CATEGORY_RELIC)

	var relic_data: Resource = relic_reward.get("relic_data", null) as Resource
	if relic_data == null:
		return _create_empty_shop_item("暂无可购买遗物", "遗物数据缺失。", SHOP_CATEGORY_RELIC)

	var rarity: String = _get_relic_rarity(relic_data)
	return {
		"type": SHOP_ITEM_TYPE_RELIC,
		"category": SHOP_CATEGORY_RELIC,
		"relic_data": relic_data,
		"id": str(relic_reward.get("id", "")),
		"name": str(relic_reward.get("name", _get_relic_name(relic_data))),
		"price": get_relic_price(relic_data),
		"description": str(relic_reward.get("description", _get_relic_description(relic_data))),
		"rarity": rarity,
		"is_sold": false,
	}


func _get_luck() -> float:
	if run_modifier_manager != null and run_modifier_manager.has_method("get_luck"):
		return run_modifier_manager.get_luck()
	return 0.0


func _get_relic_reward_rarity(relic_reward: Dictionary) -> String:
	return str(relic_reward.get("rarity", "COMMON"))


func _get_available_relic_shop_pool() -> Array[Dictionary]:
	var relic_pool: Array[Dictionary] = []
	if relic_manager == null:
		return relic_pool

	var used_relic_ids: Array[String] = []
	for shop_item: Dictionary in current_shop_items:
		if str(shop_item.get("type", "")) != SHOP_ITEM_TYPE_RELIC:
			continue

		var relic_id: String = str(shop_item.get("id", ""))
		if relic_id != "":
			used_relic_ids.append(relic_id)

	var available_relics: Array[Dictionary] = relic_manager.get_available_relic_reward_options()
	for relic_reward: Dictionary in available_relics:
		var relic_id: String = str(relic_reward.get("id", ""))
		if relic_id == "" or used_relic_ids.has(relic_id):
			continue

		relic_pool.append(relic_reward)

	return relic_pool


func _get_unlocked_unit_pool() -> Array[Resource]:
	if roster_manager != null and roster_manager.has_method("get_unlocked_unit_pool"):
		var unlocked_pool: Array[Resource] = roster_manager.get_unlocked_unit_pool()
		if not unlocked_pool.is_empty():
			return unlocked_pool

	return _get_unit_pool()


func _get_locked_unit_pool() -> Array[Resource]:
	if roster_manager != null and roster_manager.has_method("get_locked_unit_pool"):
		var locked_pool: Array[Resource] = roster_manager.get_locked_unit_pool()
		return locked_pool

	return []


func _get_unit_pool() -> Array[Resource]:
	return unit_catalog.get_unit_pool()


func _get_unit_id(unit_data: Resource) -> String:
	if roster_manager != null and roster_manager.has_method("get_unit_id"):
		return str(roster_manager.get_unit_id(unit_data))

	return unit_catalog.get_unit_id(unit_data)


func _get_unit_data_name(unit_data: Resource) -> String:
	return unit_catalog.get_unit_name(unit_data)

	if unit_data == null:
		return "单位"

	var configured_cn_name: Variant = unit_data.get("unit_name_cn")
	if configured_cn_name != null and str(configured_cn_name).strip_edges() != "":
		return str(configured_cn_name)

	var configured_name: Variant = unit_data.get("unit_name")
	if configured_name != null and str(configured_name).strip_edges() != "":
		return str(configured_name)

	var configured_type: Variant = unit_data.get("unit_type")
	if configured_type != null and str(configured_type).strip_edges() != "":
		return str(configured_type)

	return "单位"


func _get_unit_description(unit_data: Resource) -> String:
	if unit_data == null:
		return ""

	if unit_text_formatter != null and unit_text_formatter.has_method("get_unit_description_with_skills"):
		return unit_text_formatter.get_unit_description_with_skills(unit_data)

	var configured_cn_description: Variant = unit_data.get("description_cn")
	if configured_cn_description != null and str(configured_cn_description).strip_edges() != "":
		return str(configured_cn_description)

	var unit_id: String = ""
	var configured_type: Variant = unit_data.get("unit_type")
	if configured_type != null:
		unit_id = str(configured_type)

	match unit_id:
		"warrior":
			return "前排承伤，依靠减伤和护盾保护队伍。"
		"archer":
			return "后排远程输出，安全距离下持续造成伤害。"
		"assassin":
			return "高速收割，优先猎杀低血量目标。"
		"tank":
			return "核心承伤单位，拥有高生命和防御。"
		"mage":
			return "技能爆发输出，使用火球打击低血量目标。"
		"priest":
			return "治疗辅助，持续抬高队伍生存能力。"
		"bard":
			return "团队增幅辅助，为友军提供护盾和攻击强化。"
		"forest_druid":
			return "持续治疗辅助，通过恢复跳数保护低血量友军。"
		"plague_caster":
			return "持续伤害输出，使用毒素削弱敌人。"
		"guardian_captain":
			return "防御指挥型前排，为友军提供限时防御增益。"
		"wind_chanter":
			return "节奏辅助，提高全队攻速和魔力回复。"
		_:
			return ""


func _get_unit_rarity(unit_data: Resource) -> String:
	return unit_catalog.get_unit_rarity(unit_data)


func _get_relic_rarity(relic_data: Resource) -> String:
	if relic_manager != null:
		return relic_manager.get_relic_rarity(relic_data)

	if relic_data == null:
		return "COMMON"

	var configured_rarity: Variant = relic_data.get("rarity")
	if configured_rarity == null or str(configured_rarity).strip_edges() == "":
		return "COMMON"

	return str(configured_rarity)


func _get_relic_name(relic_data: Resource) -> String:
	if relic_manager != null:
		return relic_manager.get_relic_name(relic_data)

	if relic_data == null:
		return "遗物"

	var configured_cn_name: Variant = relic_data.get("relic_name_cn")
	if configured_cn_name != null and str(configured_cn_name).strip_edges() != "":
		return str(configured_cn_name)

	var configured_name: Variant = relic_data.get("relic_name")
	if configured_name == null:
		return "遗物"

	return str(configured_name)


func _get_relic_description(relic_data: Resource) -> String:
	if relic_manager != null:
		return relic_manager.get_relic_description(relic_data)

	if relic_data == null:
		return ""

	var configured_cn_description: Variant = relic_data.get("description_cn")
	if configured_cn_description != null and str(configured_cn_description).strip_edges() != "":
		return str(configured_cn_description)

	var configured_description: Variant = relic_data.get("description")
	if configured_description == null:
		return ""

	return str(configured_description)


func _get_price_for_rarity(rarity: String) -> int:
	return unit_catalog.get_price_for_rarity(rarity)


func _get_rarity_index(rarity: String) -> int:
	return unit_catalog.get_rarity_index(rarity)
