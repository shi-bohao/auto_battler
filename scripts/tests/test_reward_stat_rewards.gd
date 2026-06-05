extends SceneTree

const REWARD_MANAGER_SCRIPT: Script = preload("res://scripts/reward_manager.gd")
const RUN_MODIFIER_MANAGER_SCRIPT: Script = preload("res://scripts/game/run_modifier_manager.gd")

class MockRosterManager:
	extends RefCounted

	var global_stat_bonuses: Dictionary = {}

	func apply_permanent_percent_bonus(stat: String, ratio: float) -> void:
		var key: String = stat + "_percent"
		global_stat_bonuses[key] = float(global_stat_bonuses.get(key, 0.0)) + ratio

	func apply_permanent_flat_bonus(stat: String, amount: float) -> void:
		var key: String = stat + "_flat"
		global_stat_bonuses[key] = float(global_stat_bonuses.get(key, 0.0)) + amount

	func apply_attack_speed_bonus(percent: float) -> void:
		global_stat_bonuses["attack_speed_percent"] = float(global_stat_bonuses.get("attack_speed_percent", 0.0)) + percent


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	seed(42)
	_test_stat_reward_pool_count()
	_test_stat_reward_rarity_distribution()
	_test_luck_reward_applies()
	_test_attack_speed_reward_applies()
	_test_stat_reward_stack()
	_finish()


func _test_stat_reward_pool_count() -> void:
	var rm: RewardManager = RewardManager.new()
	var stat_rewards: Array[Dictionary] = rm._build_stat_rewards()
	_expect_int(stat_rewards.size(), 25, "Stat reward pool should have 25 entries (5 rarities x 5 types)")


func _test_stat_reward_rarity_distribution() -> void:
	var rm: RewardManager = RewardManager.new()
	var stat_rewards: Array[Dictionary] = rm._build_stat_rewards()

	var rarity_counts: Dictionary = {
		"COMMON": 0,
		"FINE": 0,
		"RARE": 0,
		"EPIC": 0,
		"LEGENDARY": 0,
	}

	for reward: Dictionary in stat_rewards:
		var rarity: String = str(reward.get("rarity", ""))
		if rarity_counts.has(rarity):
			rarity_counts[rarity] = int(rarity_counts[rarity]) + 1

	for rarity: String in rarity_counts.keys():
		_expect_int(int(rarity_counts[rarity]), 5, "Stat reward rarity " + rarity + " should have 5 entries")

	# Verify each rarity has all 5 stat types
	var expected_prefixes: Array[String] = [
		"STAT_MAX_HP_PERCENT",
		"STAT_ATTACK_PERCENT",
		"STAT_ATTACK_SPEED_PERCENT",
		"STAT_DEFENSE_FLAT",
		"STAT_LUCK",
	]

	for rarity: String in ["COMMON", "FINE", "RARE", "EPIC", "LEGENDARY"]:
		for prefix: String in expected_prefixes:
			var expected_id: String = prefix + "_" + rarity
			var found: bool = false
			for reward: Dictionary in stat_rewards:
				if str(reward.get("id", "")) == expected_id:
					found = true
					break
			_expect_true(found, "Stat reward " + expected_id + " should exist in pool")


func _test_luck_reward_applies() -> void:
	var rm: RewardManager = _create_reward_manager_with_luck()

	# Apply STAT_LUCK_COMMON (+5)
	var luck_reward: Dictionary = {"type": "STAT", "id": "STAT_LUCK_COMMON"}
	rm.apply_reward(luck_reward)

	var luck: float = rm.run_modifier_manager.get_luck()
	_expect_float_approx(luck, 5.0, 0.001, "Luck should be 5 after applying STAT_LUCK_COMMON")

	# Apply STAT_LUCK_FINE (+10), should stack
	var luck_reward2: Dictionary = {"type": "STAT", "id": "STAT_LUCK_FINE"}
	rm.apply_reward(luck_reward2)

	var luck2: float = rm.run_modifier_manager.get_luck()
	_expect_float_approx(luck2, 15.0, 0.001, "Luck should be 15 after stacking STAT_LUCK_COMMON + STAT_LUCK_FINE")


func _test_attack_speed_reward_applies() -> void:
	var rm: RewardManager = _create_reward_manager_with_roster()

	# Apply STAT_ATTACK_SPEED_PERCENT_COMMON (+5%)
	var speed_reward: Dictionary = {"type": "STAT", "id": "STAT_ATTACK_SPEED_PERCENT_COMMON"}
	rm.apply_reward(speed_reward)

	var bonuses: Dictionary = rm.roster_manager.global_stat_bonuses
	var attack_speed: float = float(bonuses.get("attack_speed_percent", 0.0))
	_expect_float_approx(attack_speed, 0.05, 0.001, "Attack speed percent should be 0.05 after STAT_ATTACK_SPEED_PERCENT_COMMON")

	# Apply STAT_ATTACK_SPEED_PERCENT_FINE (+10%), should stack
	var speed_reward2: Dictionary = {"type": "STAT", "id": "STAT_ATTACK_SPEED_PERCENT_FINE"}
	rm.apply_reward(speed_reward2)

	var attack_speed2: float = float(rm.roster_manager.global_stat_bonuses.get("attack_speed_percent", 0.0))
	_expect_float_approx(attack_speed2, 0.15, 0.001, "Attack speed percent should be 0.15 after stacking")


func _test_stat_reward_stack() -> void:
	var rm: RewardManager = _create_reward_manager_with_roster()

	# Apply multiple max_hp percent rewards
	var reward1: Dictionary = {"type": "STAT", "id": "STAT_MAX_HP_PERCENT_COMMON"}
	var reward2: Dictionary = {"type": "STAT", "id": "STAT_MAX_HP_PERCENT_FINE"}
	rm.apply_reward(reward1)
	rm.apply_reward(reward2)

	var bonuses: Dictionary = rm.roster_manager.global_stat_bonuses
	var max_hp_percent: float = float(bonuses.get("max_hp_percent", 0.0))
	_expect_float_approx(max_hp_percent, 0.15, 0.001, "Max HP percent should stack to 0.15 (5% + 10%)")

	# Apply defense flat rewards
	var reward3: Dictionary = {"type": "STAT", "id": "STAT_DEFENSE_FLAT_COMMON"}
	var reward4: Dictionary = {"type": "STAT", "id": "STAT_DEFENSE_FLAT_RARE"}
	rm.apply_reward(reward3)
	rm.apply_reward(reward4)

	var defense_flat: float = float(rm.roster_manager.global_stat_bonuses.get("defense_flat", 0.0))
	_expect_float_approx(defense_flat, 20.0, 0.001, "Defense flat should stack to 20 (5 + 15)")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _create_reward_manager_with_luck() -> RewardManager:
	var rm: RewardManager = RewardManager.new()
	var rmm: Variant = RUN_MODIFIER_MANAGER_SCRIPT.new()
	rm.setup(null, null, rmm)
	return rm


func _create_reward_manager_with_roster() -> RewardManager:
	var rm: RewardManager = RewardManager.new()
	var rmm: Variant = RUN_MODIFIER_MANAGER_SCRIPT.new()
	var roster_proxy: MockRosterManager = MockRosterManager.new()
	rm.setup(null, roster_proxy, rmm)
	return rm


func _finish() -> void:
	if failures.is_empty():
		print("Reward stat reward tests passed.")
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


func _expect_float_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	var diff: float = absf(actual - expected)
	if diff > tolerance:
		failures.append(message + " Expected ~" + str(expected) + ", got " + str(actual) + " (tolerance " + str(tolerance) + ").")
