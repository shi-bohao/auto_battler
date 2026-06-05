extends SceneTree

const REWARD_MANAGER_SCRIPT: Script = preload("res://scripts/reward_manager.gd")

class MockUnitData:
	extends Resource

	var unit_type: String = ""
	var unit_name: String = ""
	var unit_name_cn: String = ""
	var rarity: String = "COMMON"


class MockRosterManager:
	extends RefCounted

	var _unit_pool: Array[Resource] = []
	var _can_add: bool = true
	var _added_unit_ids: Array[String] = []
	var _random_called: bool = false
	var _available_unit_ids: Array[String] = []

	func _init(unit_pool: Array[Resource] = [], can_add: bool = true, available_ids: Array[String] = []) -> void:
		_unit_pool = unit_pool
		_can_add = can_add
		_available_unit_ids = available_ids

	func get_all_unit_pool() -> Array[Resource]:
		return _unit_pool

	func can_add_unit() -> bool:
		return _can_add

	func add_unit_by_id(unit_id: String) -> bool:
		_added_unit_ids.append(unit_id)
		return true

	func add_random_unit() -> bool:
		_random_called = true
		return true

	func is_unit_id_available_for_run(unit_id: String) -> bool:
		if _available_unit_ids.is_empty():
			return true
		return _available_unit_ids.has(unit_id)

	func get_added_unit_ids() -> Array[String]:
		return _added_unit_ids

	func was_random_called() -> bool:
		return _random_called


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	seed(42)
	_test_dynamic_unit_reward_count()
	_test_hero_exclusive_filtering()
	_test_apply_any_unit_reward()
	_test_random_unit_reward_still_works()
	_test_full_roster_no_unit_rewards()
	_finish()


func _test_dynamic_unit_reward_count() -> void:
	var pool: Array[Resource] = _create_mock_unit_pool()
	var roster: MockRosterManager = MockRosterManager.new(pool, true)
	var rm: RewardManager = _create_reward_manager(roster)

	var reward_pool: Array[Dictionary] = rm._build_reward_pool()

	# Count unit rewards (excluding random unit)
	var unit_reward_count: int = 0
	var random_unit_found: bool = false
	for reward: Dictionary in reward_pool:
		var reward_type: String = str(reward.get("type", ""))
		if reward_type == "UNIT":
			if str(reward.get("id", "")) == "ADD_RANDOM_UNIT":
				random_unit_found = true
			else:
				unit_reward_count += 1

	_expect_true(random_unit_found, "ADD_RANDOM_UNIT should be in reward pool")
	_expect_int(unit_reward_count, pool.size(), "Unit reward count should match mock pool size")


func _test_hero_exclusive_filtering() -> void:
	var pool: Array[Resource] = _create_mock_unit_pool()
	var available_ids: Array[String] = ["warrior", "mage"]
	var roster: MockRosterManager = MockRosterManager.new(pool, true, available_ids)
	var rm: RewardManager = _create_reward_manager(roster)

	var reward_pool: Array[Dictionary] = rm._build_reward_pool()
	var filtered_pool: Array[Dictionary] = rm._filter_unavailable_unit_rewards(reward_pool)

	# After filtering, only warrior and mage unit rewards should remain (plus random and non-unit)
	var unit_rewards_after_filter: Array[Dictionary] = []
	for reward: Dictionary in filtered_pool:
		if str(reward.get("type", "")) == "UNIT" and str(reward.get("id", "")) != "ADD_RANDOM_UNIT":
			unit_rewards_after_filter.append(reward)

	_expect_int(unit_rewards_after_filter.size(), 2, "Only 2 hero-available units should remain after filtering")

	for reward: Dictionary in unit_rewards_after_filter:
		var unit_id: String = str(reward.get("unit_id", ""))
		_expect_true(available_ids.has(unit_id), "Filtered unit " + unit_id + " should be in available list")


func _test_apply_any_unit_reward() -> void:
	var pool: Array[Resource] = _create_mock_unit_pool()
	var roster: MockRosterManager = MockRosterManager.new(pool, true)
	var rm: RewardManager = _create_reward_manager(roster)

	# Apply a specific unit reward
	var unit_reward: Dictionary = {
		"type": "UNIT",
		"id": "ADD_UNIT_WARRIOR",
		"unit_id": "warrior",
	}
	rm.apply_reward(unit_reward)

	var added_ids: Array[String] = roster.get_added_unit_ids()
	_expect_int(added_ids.size(), 1, "Should have added 1 unit")
	_expect_string(added_ids[0], "warrior", "Added unit should be warrior")

	# Apply another unit reward
	var unit_reward2: Dictionary = {
		"type": "UNIT",
		"id": "ADD_UNIT_MAGE",
		"unit_id": "mage",
	}
	rm.apply_reward(unit_reward2)

	var added_ids2: Array[String] = roster.get_added_unit_ids()
	_expect_int(added_ids2.size(), 2, "Should have added 2 units total")
	_expect_string(added_ids2[1], "mage", "Second added unit should be mage")


func _test_random_unit_reward_still_works() -> void:
	var pool: Array[Resource] = _create_mock_unit_pool()
	var roster: MockRosterManager = MockRosterManager.new(pool, true)
	var rm: RewardManager = _create_reward_manager(roster)

	var random_reward: Dictionary = {
		"type": "UNIT",
		"id": "ADD_RANDOM_UNIT",
		"unit_id": "",
	}
	rm.apply_reward(random_reward)

	_expect_true(roster.was_random_called(), "ADD_RANDOM_UNIT should trigger add_random_unit()")


func _test_full_roster_no_unit_rewards() -> void:
	var pool: Array[Resource] = _create_mock_unit_pool()
	var roster: MockRosterManager = MockRosterManager.new(pool, false)
	var rm: RewardManager = _create_reward_manager(roster)

	var reward_pool: Array[Dictionary] = rm._build_reward_pool()

	# No unit rewards should be in pool when roster is full
	var unit_reward_found: bool = false
	for reward: Dictionary in reward_pool:
		if str(reward.get("type", "")) == "UNIT":
			unit_reward_found = true
			break

	_expect_true(not unit_reward_found, "No unit rewards should appear when roster is full")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _create_mock_unit_pool() -> Array[Resource]:
	var pool: Array[Resource] = []

	var warrior: MockUnitData = MockUnitData.new()
	warrior.unit_type = "warrior"
	warrior.unit_name_cn = "战士"
	warrior.rarity = "COMMON"
	pool.append(warrior)

	var mage: MockUnitData = MockUnitData.new()
	mage.unit_type = "mage"
	mage.unit_name_cn = "法师"
	mage.rarity = "COMMON"
	pool.append(mage)

	var assassin: MockUnitData = MockUnitData.new()
	assassin.unit_type = "assassin"
	assassin.unit_name_cn = "刺客"
	assassin.rarity = "FINE"
	pool.append(assassin)

	return pool


func _create_reward_manager(roster: Variant) -> RewardManager:
	var rm: RewardManager = RewardManager.new()
	rm.setup(null, roster, null)
	return rm


func _finish() -> void:
	if failures.is_empty():
		print("Dynamic unit pool tests passed.")
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


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected '" + expected + "', got '" + actual + "'.")
