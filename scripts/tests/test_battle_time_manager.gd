extends SceneTree

const BATTLE_TIME_MANAGER_SCRIPT: Script = preload("res://scripts/battle_time_manager.gd")
const STATS_MANAGER_SCRIPT: Script = preload("res://scripts/stats_manager.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_speed_cycle_and_delta()
	_test_idle_update_does_not_advance_battle_time()
	_test_stats_use_battle_time()

	if failures.is_empty():
		print("Battle time manager tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_speed_cycle_and_delta() -> void:
	var battle_time_manager: Variant = BATTLE_TIME_MANAGER_SCRIPT.new()
	_expect_string(battle_time_manager.get_speed_label(), "x1", "Battle speed should start at x1.")
	_expect_float(battle_time_manager.update(0.5, true), 0.5, "x1 should pass raw delta through.")
	_expect_float(battle_time_manager.battle_elapsed, 0.5, "Battle elapsed should advance by scaled delta.")
	_expect_float(battle_time_manager.real_elapsed, 0.5, "Real elapsed should advance by raw delta.")

	battle_time_manager.cycle_speed()
	_expect_string(battle_time_manager.get_speed_label(), "x2", "First speed click should switch to x2.")
	_expect_float(battle_time_manager.update(0.5, true), 1.0, "x2 should double battle delta.")

	battle_time_manager.cycle_speed()
	_expect_string(battle_time_manager.get_speed_label(), "x3", "Second speed click should switch to x3.")
	_expect_float(battle_time_manager.update(0.5, true), 1.5, "x3 should triple battle delta.")

	battle_time_manager.cycle_speed()
	_expect_string(battle_time_manager.get_speed_label(), "x1", "Third speed click should wrap to x1.")


func _test_idle_update_does_not_advance_battle_time() -> void:
	var battle_time_manager: Variant = BATTLE_TIME_MANAGER_SCRIPT.new()
	battle_time_manager.cycle_speed()
	_expect_float(battle_time_manager.update(1.0, false), 0.0, "Idle update should return zero battle delta.")
	_expect_float(battle_time_manager.battle_elapsed, 0.0, "Idle update should not advance battle elapsed.")
	_expect_float(battle_time_manager.real_elapsed, 0.0, "Idle update should not advance real elapsed.")


func _test_stats_use_battle_time() -> void:
	var stats_manager: Variant = STATS_MANAGER_SCRIPT.new()
	stats_manager.start_battle_timer()
	stats_manager.advance_battle_timer(2.0)
	stats_manager.finish_battle_timer()
	_expect_float(stats_manager.battle_duration, 2.0, "Stats should record simulated battle duration.")


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + expected + ", got " + actual + ".")


func _expect_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
