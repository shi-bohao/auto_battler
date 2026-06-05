extends SceneTree

const REWARD_MANAGER_SCRIPT: Script = preload("res://scripts/reward_manager.gd")
const RUN_MODIFIER_MANAGER_SCRIPT: Script = preload("res://scripts/game/run_modifier_manager.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	seed(42)
	_test_probability_calculation_round_1_normal_zero_luck()
	_test_probability_calculation_round_1_normal_100_luck()
	_test_probability_calculation_round_1_elite()
	_test_probability_calculation_round_1_boss()
	_test_round_growth()
	_test_empty_pool_fallback()
	_test_roll_no_duplicates()
	_finish()


func _test_probability_calculation_round_1_normal_zero_luck() -> void:
	var rm: RewardManager = _create_reward_manager(0.0)
	var distribution: Dictionary = _sample_rarity_distribution(rm, "", 1, 10000)

	# raw = base + 0 + 0, modified = raw * 1.0
	# final (high to low): LEGENDARY 0, EPIC 1, RARE 9, FINE 20, COMMON 70
	_expect_distribution_approx(distribution, "COMMON", 70.0, 2.0, "Round 1 NORMAL 0 luck COMMON")
	_expect_distribution_approx(distribution, "FINE", 20.0, 2.0, "Round 1 NORMAL 0 luck FINE")
	_expect_distribution_approx(distribution, "RARE", 9.0, 1.5, "Round 1 NORMAL 0 luck RARE")
	_expect_distribution_approx(distribution, "EPIC", 1.0, 0.8, "Round 1 NORMAL 0 luck EPIC")
	_expect_distribution_approx(distribution, "LEGENDARY", 0.0, 0.1, "Round 1 NORMAL 0 luck LEGENDARY")


func _test_probability_calculation_round_1_normal_100_luck() -> void:
	var rm: RewardManager = _create_reward_manager(100.0)
	var distribution: Dictionary = _sample_rarity_distribution(rm, "", 1, 10000)

	# raw = base, modified = raw * 2.0, capped at 100
	# LEGENDARY 0, EPIC 2, RARE 18, FINE 40, COMMON 100
	# final (high to low): LEGENDARY 0, EPIC 2, RARE 18, FINE 40, COMMON 40
	_expect_distribution_approx(distribution, "COMMON", 40.0, 2.0, "Round 1 NORMAL 100 luck COMMON")
	_expect_distribution_approx(distribution, "FINE", 40.0, 2.0, "Round 1 NORMAL 100 luck FINE")
	_expect_distribution_approx(distribution, "RARE", 18.0, 1.5, "Round 1 NORMAL 100 luck RARE")
	_expect_distribution_approx(distribution, "EPIC", 2.0, 0.8, "Round 1 NORMAL 100 luck EPIC")
	_expect_distribution_approx(distribution, "LEGENDARY", 0.0, 0.1, "Round 1 NORMAL 100 luck LEGENDARY")


func _test_probability_calculation_round_1_elite() -> void:
	var rm: RewardManager = _create_reward_manager(0.0)
	var distribution: Dictionary = _sample_rarity_distribution(rm, "ELITE", 1, 10000)

	# raw: COMMON 80, FINE 30, RARE 19, EPIC 11, LEGENDARY 10
	# final (high to low):
	#   LEGENDARY 10, EPIC 11, RARE 19, FINE 30, COMMON 30
	_expect_distribution_approx(distribution, "COMMON", 30.0, 2.0, "Round 1 ELITE 0 luck COMMON")
	_expect_distribution_approx(distribution, "FINE", 30.0, 2.0, "Round 1 ELITE 0 luck FINE")
	_expect_distribution_approx(distribution, "RARE", 19.0, 1.5, "Round 1 ELITE 0 luck RARE")
	_expect_distribution_approx(distribution, "EPIC", 11.0, 1.5, "Round 1 ELITE 0 luck EPIC")
	_expect_distribution_approx(distribution, "LEGENDARY", 10.0, 1.5, "Round 1 ELITE 0 luck LEGENDARY")


func _test_probability_calculation_round_1_boss() -> void:
	var rm: RewardManager = _create_reward_manager(0.0)
	var distribution: Dictionary = _sample_rarity_distribution(rm, "BOSS", 1, 10000)

	# raw: COMMON 90, FINE 40, RARE 29, EPIC 21, LEGENDARY 20
	# final (high to low):
	#   LEGENDARY 20, EPIC 21, RARE 29, FINE 30, COMMON 0
	_expect_distribution_approx(distribution, "COMMON", 0.0, 0.5, "Round 1 BOSS 0 luck COMMON")
	_expect_distribution_approx(distribution, "FINE", 30.0, 2.0, "Round 1 BOSS 0 luck FINE")
	_expect_distribution_approx(distribution, "RARE", 29.0, 2.0, "Round 1 BOSS 0 luck RARE")
	_expect_distribution_approx(distribution, "EPIC", 21.0, 1.5, "Round 1 BOSS 0 luck EPIC")
	_expect_distribution_approx(distribution, "LEGENDARY", 20.0, 1.5, "Round 1 BOSS 0 luck LEGENDARY")


func _test_round_growth() -> void:
	var rm: RewardManager = _create_reward_manager(0.0)
	var distribution: Dictionary = _sample_rarity_distribution(rm, "", 5, 10000)

	# round_index = 4
	# raw: COMMON 70, FINE 40, RARE 17, EPIC 5, LEGENDARY 2
	# modified = raw
	# final (high to low): LEGENDARY 2, EPIC 5, RARE 17, FINE 40, COMMON 36
	_expect_distribution_approx(distribution, "COMMON", 36.0, 2.0, "Round 5 NORMAL 0 luck COMMON")
	_expect_distribution_approx(distribution, "FINE", 40.0, 2.0, "Round 5 NORMAL 0 luck FINE")
	_expect_distribution_approx(distribution, "RARE", 17.0, 1.5, "Round 5 NORMAL 0 luck RARE")
	_expect_distribution_approx(distribution, "EPIC", 5.0, 1.0, "Round 5 NORMAL 0 luck EPIC")
	_expect_distribution_approx(distribution, "LEGENDARY", 2.0, 0.8, "Round 5 NORMAL 0 luck LEGENDARY")


func _test_empty_pool_fallback() -> void:
	var rm: RewardManager = RewardManager.new()

	# Build a pool with only COMMON rewards
	var pool: Array[Dictionary] = [
		{"type": "STAT", "id": "TEAM_HP_UP", "rarity": "COMMON"},
		{"type": "STAT", "id": "TEAM_ATTACK_UP", "rarity": "COMMON"},
	]

	# Try to pick RARE from this pool - should fallback to COMMON
	var picked: Dictionary = rm._pick_reward_by_rarity(pool, "RARE")
	_expect_true(not picked.is_empty(), "Empty pool fallback should return a reward")
	_expect_string(str(picked.get("rarity", "")), "COMMON", "Fallback from empty RARE pool should yield COMMON")

	# Try to pick LEGENDARY - should also fallback to COMMON
	var picked2: Dictionary = rm._pick_reward_by_rarity(pool, "LEGENDARY")
	_expect_true(not picked2.is_empty(), "Empty pool fallback from LEGENDARY should return a reward")
	_expect_string(str(picked2.get("rarity", "")), "COMMON", "Fallback from empty LEGENDARY pool should yield COMMON")

	# Build a pool with only RARE reward
	var pool2: Array[Dictionary] = [
		{"type": "STAT", "id": "TEST_RARE", "rarity": "RARE"},
	]

	# Try to pick COMMON - should fallback to RARE (first lower, then higher)
	var picked3: Dictionary = rm._pick_reward_by_rarity(pool2, "COMMON")
	_expect_true(not picked3.is_empty(), "Empty pool fallback from COMMON should return a reward")
	_expect_string(str(picked3.get("rarity", "")), "RARE", "Fallback from empty COMMON pool should yield RARE")


func _test_roll_no_duplicates() -> void:
	var rm: RewardManager = RewardManager.new()

	# Build a small pool with 2 unique rewards
	var pool: Array[Dictionary] = [
		{"type": "STAT", "id": "TEAM_HP_UP", "rarity": "COMMON"},
		{"type": "STAT", "id": "TEAM_ATTACK_UP", "rarity": "COMMON"},
	]

	# Roll 3 times, should not get duplicates
	var rolled: Array[Dictionary] = []
	for i: int in range(3):
		var picked: Dictionary = rm._pick_reward_by_rarity(pool, "COMMON")
		if not picked.is_empty():
			rolled.append(picked)
			rm._remove_reward_from_pool(pool, picked)

	_expect_int(rolled.size(), 2, "Should roll 2 rewards from pool of 2")

	var keys: Array[String] = []
	for reward: Dictionary in rolled:
		var key: String = str(reward.get("type", "")) + ":" + str(reward.get("id", ""))
		keys.append(key)

	_expect_true(keys[0] != keys[1], "Rolled rewards should not be duplicates")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _create_reward_manager(luck_value: float) -> RewardManager:
	var rm: RewardManager = RewardManager.new()
	var rmm: Variant = RUN_MODIFIER_MANAGER_SCRIPT.new()
	rmm.set_luck(luck_value)
	rm.setup(null, null, rmm)
	return rm


func _sample_rarity_distribution(rm: RewardManager, encounter_type: String, current_round: int, sample_count: int) -> Dictionary:
	var counts: Dictionary = {
		"COMMON": 0,
		"FINE": 0,
		"RARE": 0,
		"EPIC": 0,
		"LEGENDARY": 0,
	}

	for i: int in range(sample_count):
		var rarity: String = rm._roll_reward_rarity(encounter_type, current_round)
		if counts.has(rarity):
			counts[rarity] = int(counts[rarity]) + 1

	var distribution: Dictionary = {}
	for rarity: String in counts.keys():
		distribution[rarity] = float(int(counts[rarity])) / float(sample_count) * 100.0

	return distribution


func _finish() -> void:
	if failures.is_empty():
		print("Reward rarity roll tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected '" + expected + "', got '" + actual + "'.")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_distribution_approx(distribution: Dictionary, rarity: String, expected_percent: float, tolerance: float, message: String) -> void:
	var actual: float = float(distribution.get(rarity, 0.0))
	var diff: float = absf(actual - expected_percent)
	if diff > tolerance:
		failures.append(message + ": expected ~" + str(expected_percent) + "%, got " + str(snappedf(actual, 0.01)) + "% (tolerance " + str(tolerance) + "%).")
