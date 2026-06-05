extends SceneTree

const SHOP_MANAGER_SCRIPT: Script = preload("res://scripts/shop_manager.gd")
const RUN_MODIFIER_MANAGER_SCRIPT: Script = preload("res://scripts/game/run_modifier_manager.gd")

class MockRosterManager:
	extends RefCounted

	var _unlocked_pool: Array[Resource] = []
	var _locked_pool: Array[Resource] = []
	var _hero_exclusive_ids: Array[String] = []
	var _all_exclusive_ids: Array[String] = []

	func _init(unlocked: Array[Resource] = [], locked: Array[Resource] = []) -> void:
		_unlocked_pool = unlocked
		_locked_pool = locked

	func get_unlocked_unit_pool() -> Array[Resource]:
		return _filter_by_exclusive(_unlocked_pool)

	func get_locked_unit_pool() -> Array[Resource]:
		return _filter_by_exclusive(_locked_pool)

	func _filter_by_exclusive(pool: Array[Resource]) -> Array[Resource]:
		if _all_exclusive_ids.is_empty():
			return pool
		var filtered: Array[Resource] = []
		for unit_data: Resource in pool:
			var unit_id: String = ""
			if unit_data.has_method("get"):
				var type_value = unit_data.get("unit_type")
				if type_value != null:
					unit_id = str(type_value)
			elif "unit_type" in unit_data:
				unit_id = str(unit_data.unit_type)
			if not _all_exclusive_ids.has(unit_id):
				filtered.append(unit_data)
			elif _hero_exclusive_ids.has(unit_id):
				filtered.append(unit_data)
		return filtered

	func configure_exclusive(hero_ids: Array[String], all_ids: Array[String]) -> void:
		_hero_exclusive_ids = hero_ids
		_all_exclusive_ids = all_ids

	func get_unit_id(unit_data: Resource) -> String:
		if unit_data == null:
			return ""
		if unit_data.has_method("get"):
			var type_value = unit_data.get("unit_type")
			if type_value != null:
				return str(type_value)
		if "unit_type" in unit_data:
			return str(unit_data.unit_type)
		return ""


class MockUnitData:
	extends Resource

	var unit_type: String = ""
	var unit_name: String = ""
	var unit_name_cn: String = ""
	var rarity: String = "COMMON"


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	seed(42)
	_test_shop_receives_run_modifier_manager()
	_test_luck_affects_shop_distribution()
	_test_hero_exclusive_filtering_in_shop()
	_test_empty_pool_fallback()
	_test_shop_items_have_valid_data()
	_finish()


func _test_shop_receives_run_modifier_manager() -> void:
	var sm: ShopManager = _create_shop_manager_with_luck(0.0)
	var items: Array[Dictionary] = sm.get_shop_items()
	_expect_int(items.size(), 10, "Shop should have 10 items (7 units + 3 relics)")


func _test_luck_affects_shop_distribution() -> void:
	var sm_no_luck: ShopManager = _create_shop_manager_with_luck(0.0)
	var sm_high_luck: ShopManager = _create_shop_manager_with_luck(100.0)

	var rare_count_no_luck: int = 0
	var rare_count_high_luck: int = 0
	var sample_count: int = 100

	for i: int in range(sample_count):
		sm_no_luck.roll_shop_items(5)
		for item: Dictionary in sm_no_luck.get_shop_items():
			if _is_high_rarity(str(item.get("rarity", "COMMON"))):
				rare_count_no_luck += 1

		sm_high_luck.roll_shop_items(5)
		for item: Dictionary in sm_high_luck.get_shop_items():
			if _is_high_rarity(str(item.get("rarity", "COMMON"))):
				rare_count_high_luck += 1

	_expect_true(rare_count_high_luck > rare_count_no_luck, "High luck should produce more high-rarity shop items over " + str(sample_count) + " rolls. No luck: " + str(rare_count_no_luck) + ", High luck: " + str(rare_count_high_luck))


func _test_hero_exclusive_filtering_in_shop() -> void:
	var warrior: MockUnitData = MockUnitData.new()
	warrior.unit_type = "warrior"
	warrior.unit_name_cn = "战士"
	warrior.rarity = "COMMON"

	var mage: MockUnitData = MockUnitData.new()
	mage.unit_type = "mage"
	mage.unit_name_cn = "法师"
	mage.rarity = "COMMON"

	var roster: MockRosterManager = MockRosterManager.new([warrior, mage], [])
	roster.configure_exclusive(["warrior"], ["warrior", "mage"])

	var sm: ShopManager = _create_shop_manager(roster, null)

	var mage_found: bool = false
	for i: int in range(50):
		sm.roll_shop_items(1)
		for item: Dictionary in sm.get_shop_items():
			if str(item.get("type", "")) == "UNIT" and str(item.get("id", "")) == "mage":
				mage_found = true
				break
		if mage_found:
			break

	_expect_true(not mage_found, "Hero exclusive filtering should prevent mage from appearing in shop for Iron Oath commander")


func _test_empty_pool_fallback() -> void:
	var roster: MockRosterManager = MockRosterManager.new([], [])
	var sm: ShopManager = _create_shop_manager(roster, null)
	sm.roll_shop_items(1)

	var items: Array[Dictionary] = sm.get_shop_items()
	_expect_int(items.size(), 10, "Shop should still have 10 items even with empty pools")

	var empty_count: int = 0
	for item: Dictionary in items:
		if str(item.get("type", "")) == "EMPTY":
			empty_count += 1
	_expect_true(empty_count > 0, "Empty pools should produce EMPTY shop items")


func _test_shop_items_have_valid_data() -> void:
	var warrior: MockUnitData = MockUnitData.new()
	warrior.unit_type = "warrior"
	warrior.unit_name_cn = "战士"
	warrior.rarity = "COMMON"

	var roster: MockRosterManager = MockRosterManager.new([warrior], [])
	var sm: ShopManager = _create_shop_manager(roster, null)
	sm.roll_shop_items(1)

	var items: Array[Dictionary] = sm.get_shop_items()
	for item: Dictionary in items:
		if str(item.get("type", "")) == "UNIT":
			_expect_true(item.has("unit_data"), "Unit shop item should have unit_data")
			_expect_true(item.has("price"), "Unit shop item should have price")
			_expect_true(item.has("rarity"), "Unit shop item should have rarity")
			_expect_true(item.has("is_sold"), "Unit shop item should have is_sold")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _is_high_rarity(rarity: String) -> bool:
	return rarity == "RARE" or rarity == "EPIC" or rarity == "LEGENDARY"


func _create_shop_manager_with_luck(luck_value: float) -> ShopManager:
	var rmm: Variant = null
	if luck_value != 0.0:
		rmm = RUN_MODIFIER_MANAGER_SCRIPT.new()
		rmm.set_luck(luck_value)
	return _create_shop_manager(null, rmm)


func _create_shop_manager(roster: Variant, run_modifier_manager: Variant) -> ShopManager:
	var sm: ShopManager = ShopManager.new()

	var warrior: MockUnitData = MockUnitData.new()
	warrior.unit_type = "warrior"
	warrior.unit_name_cn = "战士"
	warrior.rarity = "COMMON"

	var archer: MockUnitData = MockUnitData.new()
	archer.unit_type = "archer"
	archer.unit_name_cn = "弓手"
	archer.rarity = "COMMON"

	var tank: MockUnitData = MockUnitData.new()
	tank.unit_type = "tank"
	tank.unit_name_cn = "坦克"
	tank.rarity = "COMMON"

	var mage: MockUnitData = MockUnitData.new()
	mage.unit_type = "mage"
	mage.unit_name_cn = "法师"
	mage.rarity = "COMMON"

	var assassin: MockUnitData = MockUnitData.new()
	assassin.unit_type = "assassin"
	assassin.unit_name_cn = "刺客"
	assassin.rarity = "FINE"

	var cleric: MockUnitData = MockUnitData.new()
	cleric.unit_type = "cleric"
	cleric.unit_name_cn = "神官"
	cleric.rarity = "RARE"

	var prism_weaver: MockUnitData = MockUnitData.new()
	prism_weaver.unit_type = "prism_weaver"
	prism_weaver.unit_name_cn = "棱镜术师"
	prism_weaver.rarity = "RARE"

	var wind_chanter: MockUnitData = MockUnitData.new()
	wind_chanter.unit_type = "wind_chanter"
	wind_chanter.unit_name_cn = "风语者"
	wind_chanter.rarity = "FINE"

	var alchemist: MockUnitData = MockUnitData.new()
	alchemist.unit_type = "alchemist"
	alchemist.unit_name_cn = "炼金术士"
	alchemist.rarity = "RARE"

	var guardian_captain: MockUnitData = MockUnitData.new()
	guardian_captain.unit_type = "guardian_captain"
	guardian_captain.unit_name_cn = "守护队长"
	guardian_captain.rarity = "FINE"

	var greatsword_knight: MockUnitData = MockUnitData.new()
	greatsword_knight.unit_type = "greatsword_knight"
	greatsword_knight.unit_name_cn = "巨剑骑士"
	greatsword_knight.rarity = "RARE"

	var bomb_thrower: MockUnitData = MockUnitData.new()
	bomb_thrower.unit_type = "bomb_thrower"
	bomb_thrower.unit_name_cn = "爆弹投手"
	bomb_thrower.rarity = "RARE"

	var plague_caster: MockUnitData = MockUnitData.new()
	plague_caster.unit_type = "plague_caster"
	plague_caster.unit_name_cn = "瘟疫术士"
	plague_caster.rarity = "FINE"

	var forest_druid: MockUnitData = MockUnitData.new()
	forest_druid.unit_type = "forest_druid"
	forest_druid.unit_name_cn = "森林德鲁伊"
	forest_druid.rarity = "FINE"

	var necromancer: MockUnitData = MockUnitData.new()
	necromancer.unit_type = "necromancer"
	necromancer.unit_name_cn = "亡灵法师"
	necromancer.rarity = "RARE"

	var puppet_warlock: MockUnitData = MockUnitData.new()
	puppet_warlock.unit_type = "puppet_warlock"
	puppet_warlock.unit_name_cn = "傀儡术士"
	puppet_warlock.rarity = "RARE"

	var bard: MockUnitData = MockUnitData.new()
	bard.unit_type = "bard"
	bard.unit_name_cn = "吟游诗人"
	bard.rarity = "COMMON"

	var priest: MockUnitData = MockUnitData.new()
	priest.unit_type = "priest"
	priest.unit_name_cn = "牧师"
	priest.rarity = "COMMON"

	sm.setup(
		warrior, archer, assassin, tank, mage, priest, bard,
		forest_druid, plague_caster, guardian_captain, wind_chanter,
		greatsword_knight, bomb_thrower, cleric, alchemist,
		necromancer, puppet_warlock,
		null, roster, run_modifier_manager
	)

	sm.roll_shop_items(1)
	return sm


func _finish() -> void:
	if failures.is_empty():
		print("Shop rarity roll tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
