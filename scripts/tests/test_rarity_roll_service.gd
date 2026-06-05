extends SceneTree

const RARITY_ROLL_SERVICE_SCRIPT: Script = preload("res://scripts/game/rarity_roll_service.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	seed(42)
	_test_modified_chances_round_1_normal_zero_luck()
	_test_modified_chances_round_1_normal_100_luck()
	_test_final_chances_round_1_elite()
	_test_final_chances_round_1_boss()
	_test_final_chances_high_rarity_first_truncation()
	_test_roll_rarity_distribution_round_1_normal()
	_test_roll_rarity_distribution_round_1_elite()
	_test_pick_by_rarity_exact_match()
	_test_pick_by_rarity_fallback_lower()
	_test_pick_by_rarity_fallback_higher()
	_test_pick_by_rarity_all_empty()
	_finish()


func _test_modified_chances_round_1_normal_zero_luck() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var modified: Dictionary = rrs.get_modified_chances(1, "NORMAL", 0.0)

	_expect_float_approx(float(modified.get("COMMON", 0.0)), 70.0, 0.001, "Modified COMMON round 1 normal 0 luck")
	_expect_float_approx(float(modified.get("FINE", 0.0)), 20.0, 0.001, "Modified FINE round 1 normal 0 luck")
	_expect_float_approx(float(modified.get("RARE", 0.0)), 9.0, 0.001, "Modified RARE round 1 normal 0 luck")
	_expect_float_approx(float(modified.get("EPIC", 0.0)), 1.0, 0.001, "Modified EPIC round 1 normal 0 luck")
	_expect_float_approx(float(modified.get("LEGENDARY", 0.0)), 0.0, 0.001, "Modified LEGENDARY round 1 normal 0 luck")


func _test_modified_chances_round_1_normal_100_luck() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var modified: Dictionary = rrs.get_modified_chances(1, "NORMAL", 100.0)

	# raw = base, modified = raw * 2.0, capped at 100
	_expect_float_approx(float(modified.get("COMMON", 0.0)), 100.0, 0.001, "Modified COMMON round 1 normal 100 luck")
	_expect_float_approx(float(modified.get("FINE", 0.0)), 40.0, 0.001, "Modified FINE round 1 normal 100 luck")
	_expect_float_approx(float(modified.get("RARE", 0.0)), 18.0, 0.001, "Modified RARE round 1 normal 100 luck")
	_expect_float_approx(float(modified.get("EPIC", 0.0)), 2.0, 0.001, "Modified EPIC round 1 normal 100 luck")
	_expect_float_approx(float(modified.get("LEGENDARY", 0.0)), 0.0, 0.001, "Modified LEGENDARY round 1 normal 100 luck")


func _test_final_chances_round_1_elite() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var final_chances: Dictionary = rrs.get_final_chances(1, "ELITE", 0.0)

	# raw: COMMON 80, FINE 30, RARE 19, EPIC 11, LEGENDARY 10
	# final (high to low): LEGENDARY 10, EPIC 11, RARE 19, FINE 30, COMMON 30
	_expect_float_approx(float(final_chances.get("LEGENDARY", 0.0)), 10.0, 0.001, "Final LEGENDARY round 1 elite")
	_expect_float_approx(float(final_chances.get("EPIC", 0.0)), 11.0, 0.001, "Final EPIC round 1 elite")
	_expect_float_approx(float(final_chances.get("RARE", 0.0)), 19.0, 0.001, "Final RARE round 1 elite")
	_expect_float_approx(float(final_chances.get("FINE", 0.0)), 30.0, 0.001, "Final FINE round 1 elite")
	_expect_float_approx(float(final_chances.get("COMMON", 0.0)), 30.0, 0.001, "Final COMMON round 1 elite")


func _test_final_chances_round_1_boss() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var final_chances: Dictionary = rrs.get_final_chances(1, "BOSS", 0.0)

	# raw: COMMON 90, FINE 40, RARE 29, EPIC 21, LEGENDARY 20
	# final (high to low): LEGENDARY 20, EPIC 21, RARE 29, FINE 30, COMMON 0
	_expect_float_approx(float(final_chances.get("LEGENDARY", 0.0)), 20.0, 0.001, "Final LEGENDARY round 1 boss")
	_expect_float_approx(float(final_chances.get("EPIC", 0.0)), 21.0, 0.001, "Final EPIC round 1 boss")
	_expect_float_approx(float(final_chances.get("RARE", 0.0)), 29.0, 0.001, "Final RARE round 1 boss")
	_expect_float_approx(float(final_chances.get("FINE", 0.0)), 30.0, 0.001, "Final FINE round 1 boss")
	_expect_float_approx(float(final_chances.get("COMMON", 0.0)), 0.0, 0.001, "Final COMMON round 1 boss")


func _test_final_chances_high_rarity_first_truncation() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var final_chances: Dictionary = rrs.get_final_chances(1, "NORMAL", 100.0)

	# modified: COMMON 100, FINE 40, RARE 18, EPIC 2, LEGENDARY 0
	# final (high to low): LEGENDARY 0, EPIC 2, RARE 18, FINE 40, COMMON 40
	_expect_float_approx(float(final_chances.get("LEGENDARY", 0.0)), 0.0, 0.001, "Truncated LEGENDARY")
	_expect_float_approx(float(final_chances.get("EPIC", 0.0)), 2.0, 0.001, "Truncated EPIC")
	_expect_float_approx(float(final_chances.get("RARE", 0.0)), 18.0, 0.001, "Truncated RARE")
	_expect_float_approx(float(final_chances.get("FINE", 0.0)), 40.0, 0.001, "Truncated FINE")
	_expect_float_approx(float(final_chances.get("COMMON", 0.0)), 40.0, 0.001, "Truncated COMMON")

	var total: float = 0.0
	for value: Variant in final_chances.values():
		total += float(value)
	_expect_float_approx(total, 100.0, 0.001, "Final chances should sum to 100%")


func _test_roll_rarity_distribution_round_1_normal() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var distribution: Dictionary = _sample_rarity_distribution(rrs, 1, "NORMAL", 0.0, 10000)

	_expect_distribution_approx(distribution, "COMMON", 70.0, 2.0, "Roll distribution COMMON")
	_expect_distribution_approx(distribution, "FINE", 20.0, 2.0, "Roll distribution FINE")
	_expect_distribution_approx(distribution, "RARE", 9.0, 1.5, "Roll distribution RARE")
	_expect_distribution_approx(distribution, "EPIC", 1.0, 0.8, "Roll distribution EPIC")
	_expect_distribution_approx(distribution, "LEGENDARY", 0.0, 0.1, "Roll distribution LEGENDARY")


func _test_roll_rarity_distribution_round_1_elite() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var distribution: Dictionary = _sample_rarity_distribution(rrs, 1, "ELITE", 0.0, 10000)

	_expect_distribution_approx(distribution, "COMMON", 30.0, 2.0, "Elite distribution COMMON")
	_expect_distribution_approx(distribution, "FINE", 30.0, 2.0, "Elite distribution FINE")
	_expect_distribution_approx(distribution, "RARE", 19.0, 1.5, "Elite distribution RARE")
	_expect_distribution_approx(distribution, "EPIC", 11.0, 1.5, "Elite distribution EPIC")
	_expect_distribution_approx(distribution, "LEGENDARY", 10.0, 1.5, "Elite distribution LEGENDARY")


func _test_pick_by_rarity_exact_match() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var pool: Array[Dictionary] = [
		{"id": "a", "rarity": "COMMON"},
		{"id": "b", "rarity": "FINE"},
		{"id": "c", "rarity": "RARE"},
	]
	var result: Variant = rrs.pick_by_rarity(pool, "FINE", Callable(self, "_get_dict_rarity"))
	_expect_true(result != null, "pick_by_rarity should find FINE item")
	_expect_string(str(result.get("id", "")), "b", "pick_by_rarity should find item b")


func _test_pick_by_rarity_fallback_lower() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var pool: Array[Dictionary] = [
		{"id": "a", "rarity": "COMMON"},
		{"id": "b", "rarity": "COMMON"},
	]
	var result: Variant = rrs.pick_by_rarity(pool, "RARE", Callable(self, "_get_dict_rarity"))
	_expect_true(result != null, "pick_by_rarity should fallback to lower rarity")
	_expect_string(str(result.get("rarity", "")), "COMMON", "pick_by_rarity fallback should yield COMMON")


func _test_pick_by_rarity_fallback_higher() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var pool: Array[Dictionary] = [
		{"id": "c", "rarity": "RARE"},
	]
	var result: Variant = rrs.pick_by_rarity(pool, "COMMON", Callable(self, "_get_dict_rarity"))
	_expect_true(result != null, "pick_by_rarity should fallback to higher rarity")
	_expect_string(str(result.get("rarity", "")), "RARE", "pick_by_rarity fallback should yield RARE")


func _test_pick_by_rarity_all_empty() -> void:
	var rrs = RARITY_ROLL_SERVICE_SCRIPT.new()
	var pool: Array[Dictionary] = []
	var result: Variant = rrs.pick_by_rarity(pool, "COMMON", Callable(self, "_get_dict_rarity"))
	_expect_true(result == null, "pick_by_rarity from empty pool should return null")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _get_dict_rarity(item: Dictionary) -> String:
	return str(item.get("rarity", "COMMON"))


func _sample_rarity_distribution(rrs: Variant, current_round: int, encounter_type: String, luck: float, sample_count: int) -> Dictionary:
	var counts: Dictionary = {
		"COMMON": 0,
		"FINE": 0,
		"RARE": 0,
		"EPIC": 0,
		"LEGENDARY": 0,
	}

	for i: int in range(sample_count):
		var rarity: String = rrs.roll_rarity(current_round, encounter_type, luck)
		if counts.has(rarity):
			counts[rarity] = int(counts[rarity]) + 1

	var distribution: Dictionary = {}
	for rarity: String in counts.keys():
		distribution[rarity] = float(int(counts[rarity])) / float(sample_count) * 100.0

	return distribution


func _finish() -> void:
	if failures.is_empty():
		print("Rarity roll service tests passed.")
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


func _expect_float_approx(actual: float, expected: float, tolerance: float, message: String) -> void:
	var diff: float = absf(actual - expected)
	if diff > tolerance:
		failures.append(message + " Expected ~" + str(expected) + ", got " + str(actual) + " (tolerance " + str(tolerance) + ").")


func _expect_distribution_approx(distribution: Dictionary, rarity: String, expected_percent: float, tolerance: float, message: String) -> void:
	var actual: float = float(distribution.get(rarity, 0.0))
	var diff: float = absf(actual - expected_percent)
	if diff > tolerance:
		failures.append(message + ": expected ~" + str(expected_percent) + "%, got " + str(snappedf(actual, 0.01)) + "% (tolerance " + str(tolerance) + "%).")
