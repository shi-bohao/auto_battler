extends SceneTree

const HERO_MANAGER_SCRIPT: Script = preload("res://scripts/hero_manager.gd")
const ROSTER_MANAGER_SCRIPT: Script = preload("res://scripts/roster_manager.gd")

const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const ARCHER_DATA: Resource = preload("res://data/units/archer.tres")
const ASSASSIN_DATA: Resource = preload("res://data/units/assassin.tres")
const TANK_DATA: Resource = preload("res://data/units/tank.tres")
const MAGE_DATA: Resource = preload("res://data/units/mage.tres")
const PRIEST_DATA: Resource = preload("res://data/units/priest.tres")
const BARD_DATA: Resource = preload("res://data/units/bard.tres")
const FOREST_DRUID_DATA: Resource = preload("res://data/units/forest_druid.tres")
const PLAGUE_CASTER_DATA: Resource = preload("res://data/units/plague_caster.tres")
const GUARDIAN_CAPTAIN_DATA: Resource = preload("res://data/units/guardian_captain.tres")
const WIND_CHANTER_DATA: Resource = preload("res://data/units/wind_chanter.tres")
const GREATSWORD_KNIGHT_DATA: Resource = preload("res://data/units/greatsword_knight.tres")
const BOMB_THROWER_DATA: Resource = preload("res://data/units/bomb_thrower.tres")
const CLERIC_DATA: Resource = preload("res://data/units/cleric.tres")
const ALCHEMIST_DATA: Resource = preload("res://data/units/alchemist.tres")
const NECROMANCER_DATA: Resource = preload("res://data/units/necromancer.tres")
const PUPPET_WARLOCK_DATA: Resource = preload("res://data/units/puppet_warlock.tres")

var failures: Array[String] = []


func _init() -> void:
	seed(42)
	_test_hero_starters()
	_test_exclusive_pool_filtering()
	_test_reset_clears_exclusive_pool()
	_finish()


func _test_hero_starters() -> void:
	var starter_expectations: Dictionary = {
		"iron_oath_commander": ["warrior", "guardian_captain"],
		"arcane_mentor": ["mage", "wind_chanter"],
		"bloodshadow_hunter": ["archer", "assassin"],
		"boneweaver": ["bone_acolyte", "grave_warden"],
	}

	for hero_id: String in starter_expectations.keys():
		var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
		_expect_bool(hero_manager.select_hero(hero_id), true, "Hero should be selectable: " + hero_id)
		var roster_manager: Variant = _create_roster_manager()
		_configure_roster_for_hero(roster_manager, hero_manager)
		roster_manager.start_roster_for_hero(hero_manager.get_selected_hero_starter_unit_ids(), 1)

		var active_roster: Array[Dictionary] = roster_manager.get_active_roster()
		_expect_int(active_roster.size(), 3, "Hero starter roster should contain two exclusive units plus one common unit for " + hero_id + ".")
		if active_roster.size() < 3:
			continue

		var expected_starters: Array = starter_expectations.get(hero_id, []) as Array
		_expect_string(str(active_roster[0].get("unit_id", "")), str(expected_starters[0]), "First starter should match hero exclusive tier 1 for " + hero_id + ".")
		_expect_string(str(active_roster[1].get("unit_id", "")), str(expected_starters[1]), "Second starter should match hero exclusive tier 2 for " + hero_id + ".")

		var random_unit_id: String = str(active_roster[2].get("unit_id", ""))
		var random_unit_data: Resource = roster_manager.get_unit_data_by_id(random_unit_id)
		_expect_bool(not hero_manager.get_all_hero_exclusive_unit_ids().has(random_unit_id), true, "Random starter should come from common non-exclusive pool for " + hero_id + ".")
		_expect_string(str(random_unit_data.get("rarity")), "COMMON", "Random starter should be COMMON for " + hero_id + ".")


func _test_exclusive_pool_filtering() -> void:
	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	hero_manager.select_hero("iron_oath_commander")
	var roster_manager: Variant = _create_roster_manager()
	_configure_roster_for_hero(roster_manager, hero_manager)
	roster_manager.start_roster_for_hero(hero_manager.get_selected_hero_starter_unit_ids(), 1)

	var locked_ids: Array[String] = _get_unit_ids_from_pool(roster_manager.get_locked_unit_pool(), roster_manager)
	_expect_bool(locked_ids.has("taunt_banneret"), true, "Iron hero should be able to unlock Taunt Banneret.")
	_expect_bool(locked_ids.has("starforged_vanguard"), true, "Iron hero should be able to unlock Starforged Vanguard.")
	_expect_bool(locked_ids.has("mage"), false, "Iron hero should not see Arcane Mentor exclusive Mage in locked pool.")
	_expect_bool(locked_ids.has("bloodbound_berserker"), false, "Iron hero should not see Bloodshadow exclusive Bloodbound Berserker in locked pool.")
	_expect_bool(locked_ids.has("necromancer"), false, "Iron hero should not see Boneweaver exclusive Necromancer in locked pool.")

	_expect_bool(roster_manager.add_unit_by_id("mage"), false, "Roster should reject another hero's exclusive unit.")
	_expect_bool(roster_manager.add_unit_by_id("taunt_banneret"), true, "Roster should allow selected hero exclusive units.")


func _test_reset_clears_exclusive_pool() -> void:
	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	hero_manager.select_hero("bloodshadow_hunter")
	var roster_manager: Variant = _create_roster_manager()
	_configure_roster_for_hero(roster_manager, hero_manager)
	roster_manager.reset_roster()

	_expect_bool(roster_manager.all_hero_exclusive_unit_ids.is_empty(), true, "Reset roster should clear hero exclusive restrictions.")
	_expect_bool(roster_manager.is_unit_id_available_for_run("mage"), true, "After reset without hero restrictions, unit pool should be unrestricted.")


func _configure_roster_for_hero(roster_manager: Variant, hero_manager: Variant) -> void:
	roster_manager.configure_hero_exclusive_unit_pool(
		hero_manager.get_selected_hero_id(),
		hero_manager.get_selected_hero_exclusive_unit_ids(),
		hero_manager.get_all_hero_exclusive_unit_ids()
	)


func _get_unit_ids_from_pool(unit_pool: Array[Resource], roster_manager: Variant) -> Array[String]:
	var unit_ids: Array[String] = []
	for unit_data: Resource in unit_pool:
		var unit_id: String = roster_manager.get_unit_id(unit_data)
		if unit_id != "":
			unit_ids.append(unit_id)
	return unit_ids


func _create_roster_manager() -> Variant:
	var roster_manager: Variant = ROSTER_MANAGER_SCRIPT.new()
	roster_manager.setup(
		WARRIOR_DATA,
		ARCHER_DATA,
		ASSASSIN_DATA,
		TANK_DATA,
		MAGE_DATA,
		PRIEST_DATA,
		BARD_DATA,
		FOREST_DRUID_DATA,
		PLAGUE_CASTER_DATA,
		GUARDIAN_CAPTAIN_DATA,
		WIND_CHANTER_DATA,
		GREATSWORD_KNIGHT_DATA,
		BOMB_THROWER_DATA,
		CLERIC_DATA,
		ALCHEMIST_DATA,
		NECROMANCER_DATA,
		PUPPET_WARLOCK_DATA
	)
	return roster_manager


func _finish() -> void:
	if failures.is_empty():
		print("Hero exclusive unit pool tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected '" + expected + "', got '" + actual + "'.")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
