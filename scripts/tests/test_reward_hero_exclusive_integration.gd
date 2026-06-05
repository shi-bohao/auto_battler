extends SceneTree

const REWARD_MANAGER_SCRIPT: Script = preload("res://scripts/reward_manager.gd")
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

const HERO_ID_IRON_OATH_COMMANDER: String = "iron_oath_commander"
const HERO_ID_ARCANE_MENTOR: String = "arcane_mentor"
const HERO_ID_BLOODSHADOW_HUNTER: String = "bloodshadow_hunter"
const HERO_ID_BONEWEAVER: String = "boneweaver"

# Hero exclusive unit IDs per hero
const ARCANE_MENTOR_UNITS: Array[String] = ["mage", "wind_chanter", "prism_weaver", "arcane_artillerist"]
const BLOODSHADOW_HUNTER_UNITS: Array[String] = ["archer", "assassin", "bloodbound_berserker", "nightblade_captain"]
const BONEWEAVER_UNITS: Array[String] = ["bone_acolyte", "grave_warden", "necromancer", "soul_binder"]
const IRON_OATH_COMMANDER_UNITS: Array[String] = ["warrior", "guardian_captain", "taunt_banneret", "starforged_vanguard"]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	seed(42)
	_test_iron_oath_excludes_arcane_mentor_units()
	_test_iron_oath_excludes_bloodshadow_hunter_units()
	_test_iron_oath_excludes_boneweaver_units()
	_test_arcane_mentor_includes_own_units()
	_test_boneweaver_includes_own_units()
	_test_iron_oath_includes_own_units()
	_test_iron_oath_includes_warrior()
	_test_arcane_mentor_includes_mage()
	_test_bloodshadow_hunter_includes_archer()
	_test_common_units_always_available()
	_finish()


func _test_iron_oath_excludes_arcane_mentor_units() -> void:
	var rm: RewardManager = _create_reward_manager_for_hero(HERO_ID_IRON_OATH_COMMANDER)
	var unit_ids: Array[String] = _get_unit_reward_ids(rm)

	for unit_id: String in ARCANE_MENTOR_UNITS:
		_expect_not_in_list(unit_id, unit_ids, "Iron Oath should NOT include Arcane Mentor exclusive: " + unit_id)


func _test_iron_oath_excludes_bloodshadow_hunter_units() -> void:
	var rm: RewardManager = _create_reward_manager_for_hero(HERO_ID_IRON_OATH_COMMANDER)
	var unit_ids: Array[String] = _get_unit_reward_ids(rm)

	for unit_id: String in BLOODSHADOW_HUNTER_UNITS:
		_expect_not_in_list(unit_id, unit_ids, "Iron Oath should NOT include Bloodshadow Hunter exclusive: " + unit_id)


func _test_iron_oath_excludes_boneweaver_units() -> void:
	var rm: RewardManager = _create_reward_manager_for_hero(HERO_ID_IRON_OATH_COMMANDER)
	var unit_ids: Array[String] = _get_unit_reward_ids(rm)

	for unit_id: String in BONEWEAVER_UNITS:
		_expect_not_in_list(unit_id, unit_ids, "Iron Oath should NOT include Boneweaver exclusive: " + unit_id)


func _test_arcane_mentor_includes_own_units() -> void:
	var rm: RewardManager = _create_reward_manager_for_hero(HERO_ID_ARCANE_MENTOR)
	var unit_ids: Array[String] = _get_unit_reward_ids(rm)

	for unit_id: String in ARCANE_MENTOR_UNITS:
		_expect_in_list(unit_id, unit_ids, "Arcane Mentor SHOULD include its exclusive: " + unit_id)

	for unit_id: String in IRON_OATH_COMMANDER_UNITS:
		_expect_not_in_list(unit_id, unit_ids, "Arcane Mentor should NOT include Iron Oath exclusive: " + unit_id)


func _test_boneweaver_includes_own_units() -> void:
	var rm: RewardManager = _create_reward_manager_for_hero(HERO_ID_BONEWEAVER)
	var unit_ids: Array[String] = _get_unit_reward_ids(rm)

	for unit_id: String in BONEWEAVER_UNITS:
		_expect_in_list(unit_id, unit_ids, "Boneweaver SHOULD include its exclusive: " + unit_id)

	for unit_id: String in BLOODSHADOW_HUNTER_UNITS:
		_expect_not_in_list(unit_id, unit_ids, "Boneweaver should NOT include Bloodshadow Hunter exclusive: " + unit_id)


func _test_iron_oath_includes_own_units() -> void:
	var rm: RewardManager = _create_reward_manager_for_hero(HERO_ID_IRON_OATH_COMMANDER)
	var unit_ids: Array[String] = _get_unit_reward_ids(rm)

	for unit_id: String in IRON_OATH_COMMANDER_UNITS:
		_expect_in_list(unit_id, unit_ids, "Iron Oath SHOULD include its exclusive: " + unit_id)


func _test_common_units_always_available() -> void:
	# Units not in any hero exclusive pool should be available for all heroes
	# Note: warrior is Iron Oath exclusive, archer/assassin are Bloodshadow Hunter exclusive
	var truly_common_unit_ids: Array[String] = ["tank", "priest", "bard", "forest_druid", "plague_caster", "cleric", "alchemist"]

	for hero_id: String in [HERO_ID_IRON_OATH_COMMANDER, HERO_ID_ARCANE_MENTOR, HERO_ID_BLOODSHADOW_HUNTER, HERO_ID_BONEWEAVER]:
		var rm: RewardManager = _create_reward_manager_for_hero(hero_id)
		var unit_ids: Array[String] = _get_unit_reward_ids(rm)
		for unit_id: String in truly_common_unit_ids:
			_expect_in_list(unit_id, unit_ids, "Common unit " + unit_id + " should be available for " + hero_id)


func _test_iron_oath_includes_warrior() -> void:
	# warrior is Iron Oath exclusive, should appear for Iron Oath but not others
	var rm: RewardManager = _create_reward_manager_for_hero(HERO_ID_IRON_OATH_COMMANDER)
	var unit_ids: Array[String] = _get_unit_reward_ids(rm)
	_expect_in_list("warrior", unit_ids, "Iron Oath SHOULD include warrior")

func _test_arcane_mentor_includes_mage() -> void:
	var rm: RewardManager = _create_reward_manager_for_hero(HERO_ID_ARCANE_MENTOR)
	var unit_ids: Array[String] = _get_unit_reward_ids(rm)
	_expect_in_list("mage", unit_ids, "Arcane Mentor SHOULD include mage")

func _test_bloodshadow_hunter_includes_archer() -> void:
	var rm: RewardManager = _create_reward_manager_for_hero(HERO_ID_BLOODSHADOW_HUNTER)
	var unit_ids: Array[String] = _get_unit_reward_ids(rm)
	_expect_in_list("archer", unit_ids, "Bloodshadow Hunter SHOULD include archer")
	_expect_in_list("assassin", unit_ids, "Bloodshadow Hunter SHOULD include assassin")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _create_roster_manager() -> RosterManager:
	var rm: RosterManager = RosterManager.new()
	rm.setup(
		WARRIOR_DATA, ARCHER_DATA, ASSASSIN_DATA,
		TANK_DATA, MAGE_DATA, PRIEST_DATA, BARD_DATA,
		FOREST_DRUID_DATA, PLAGUE_CASTER_DATA, GUARDIAN_CAPTAIN_DATA, WIND_CHANTER_DATA,
		GREATSWORD_KNIGHT_DATA, BOMB_THROWER_DATA, CLERIC_DATA, ALCHEMIST_DATA,
		NECROMANCER_DATA, PUPPET_WARLOCK_DATA
	)
	return rm


func _create_reward_manager_for_hero(hero_id: String) -> RewardManager:
	var roster_manager: RosterManager = _create_roster_manager()

	var all_exclusive: Array[String] = []
	all_exclusive.append_array(IRON_OATH_COMMANDER_UNITS)
	all_exclusive.append_array(ARCANE_MENTOR_UNITS)
	all_exclusive.append_array(BLOODSHADOW_HUNTER_UNITS)
	all_exclusive.append_array(BONEWEAVER_UNITS)

	var selected_exclusive: Array[String] = []
	match hero_id:
		HERO_ID_IRON_OATH_COMMANDER:
			selected_exclusive = IRON_OATH_COMMANDER_UNITS.duplicate()
		HERO_ID_ARCANE_MENTOR:
			selected_exclusive = ARCANE_MENTOR_UNITS.duplicate()
		HERO_ID_BLOODSHADOW_HUNTER:
			selected_exclusive = BLOODSHADOW_HUNTER_UNITS.duplicate()
		HERO_ID_BONEWEAVER:
			selected_exclusive = BONEWEAVER_UNITS.duplicate()

	roster_manager.configure_hero_exclusive_unit_pool(hero_id, selected_exclusive, all_exclusive)

	var reward_manager: RewardManager = RewardManager.new()
	reward_manager.setup(null, roster_manager, null)
	return reward_manager


func _get_unit_reward_ids(rm: RewardManager) -> Array[String]:
	var pool: Array[Dictionary] = rm._build_reward_pool()
	var ids: Array[String] = []
	for reward: Dictionary in pool:
		if str(reward.get("type", "")) == "UNIT" and str(reward.get("id", "")) != "ADD_RANDOM_UNIT":
			var unit_id: String = str(reward.get("unit_id", ""))
			if unit_id != "" and not ids.has(unit_id):
				ids.append(unit_id)
	return ids


func _finish() -> void:
	if failures.is_empty():
		print("Hero exclusive integration tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_in_list(item: String, list: Array[String], message: String) -> void:
	if not list.has(item):
		failures.append(message + " (not found in pool)")


func _expect_not_in_list(item: String, list: Array[String], message: String) -> void:
	if list.has(item):
		failures.append(message + " (found in pool unexpectedly)")
