extends SceneTree

const ENCOUNTER_GENERATOR_SCRIPT: Script = preload("res://scripts/encounter/encounter_generator.gd")
const ENCOUNTER_MANAGER_SCRIPT: Script = preload("res://scripts/encounter_manager.gd")

const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const ARCHER_DATA: Resource = preload("res://data/units/archer.tres")
const ASSASSIN_DATA: Resource = preload("res://data/units/assassin.tres")
const TANK_DATA: Resource = preload("res://data/units/tank.tres")
const MAGE_DATA: Resource = preload("res://data/units/mage.tres")
const PRIEST_DATA: Resource = preload("res://data/units/priest.tres")
const BARD_DATA: Resource = preload("res://data/units/bard.tres")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_forced_boss_id()
	_test_invalid_boss_id_fallback()
	_test_boss_encounter_structure()
	_test_encounter_manager_forced_boss_id()
	_finish()


func _test_forced_boss_id() -> void:
	var generator: Variant = ENCOUNTER_GENERATOR_SCRIPT.new()
	var encounter: Dictionary = generator.create_random_encounter(10, "BOSS", "enemy_boss_treant_overlord")

	_expect_string(str(encounter.get("encounter_type", "")), "BOSS", "Forced BOSS encounter should have type BOSS.")

	var enemy_units: Array = encounter.get("enemy_units", []) as Array
	_expect_true(enemy_units.size() >= 3, "Boss encounter should have at least 3 enemy units.")

	var boss_found: bool = false
	for unit_value: Variant in enemy_units:
		var unit: Dictionary = unit_value as Dictionary
		if str(unit.get("unit_id", "")) == "enemy_boss_treant_overlord":
			boss_found = true
			_expect_true(bool(unit.get("is_boss", false)), "Treant overlord should be marked as boss.")
			break
	_expect_true(boss_found, "Forced boss 'enemy_boss_treant_overlord' should appear in encounter.")


func _test_invalid_boss_id_fallback() -> void:
	var generator: Variant = ENCOUNTER_GENERATOR_SCRIPT.new()
	var encounter: Dictionary = generator.create_random_encounter(10, "BOSS", "nonexistent_boss_id")

	_expect_string(str(encounter.get("encounter_type", "")), "BOSS", "Invalid boss id should still produce a BOSS encounter.")

	var enemy_units: Array = encounter.get("enemy_units", []) as Array
	_expect_true(enemy_units.size() >= 3, "Boss encounter with invalid id should still have units.")

	var has_boss: bool = false
	for unit_value: Variant in enemy_units:
		var unit: Dictionary = unit_value as Dictionary
		if bool(unit.get("is_boss", false)):
			has_boss = true
			break
	_expect_true(has_boss, "Fallback boss encounter should still contain a boss unit.")


func _test_boss_encounter_structure() -> void:
	var generator: Variant = ENCOUNTER_GENERATOR_SCRIPT.new()
	var encounter: Dictionary = generator.create_random_encounter(20, "BOSS", "enemy_boss_lava_colossus")

	var enemy_units: Array = encounter.get("enemy_units", []) as Array
	_expect_true(enemy_units.size() >= 3, "Round 20 boss should have guards.")

	var boss_count: int = 0
	var guard_count: int = 0
	for unit_value: Variant in enemy_units:
		var unit: Dictionary = unit_value as Dictionary
		if bool(unit.get("is_boss", false)):
			boss_count += 1
		else:
			guard_count += 1
		var star: int = int(unit.get("star", 0))
		_expect_true(star >= 1 and star <= 3, "All enemy units should have valid star (1-3).")

	_expect_int(boss_count, 1, "Boss encounter should have exactly 1 boss.")
	_expect_true(guard_count >= 2, "Boss encounter should have at least 2 guards.")

	var hp_mult: float = float(encounter.get("enemy_hp_multiplier", 1.0))
	var atk_mult: float = float(encounter.get("enemy_attack_multiplier", 1.0))
	_expect_true(hp_mult > 0.0, "Boss encounter should have positive hp multiplier.")
	_expect_true(atk_mult > 0.0, "Boss encounter should have positive attack multiplier.")


func _test_encounter_manager_forced_boss_id() -> void:
	var encounter_manager: Variant = ENCOUNTER_MANAGER_SCRIPT.new()
	encounter_manager.setup(WARRIOR_DATA, ARCHER_DATA, ASSASSIN_DATA, TANK_DATA, MAGE_DATA, PRIEST_DATA, BARD_DATA)
	encounter_manager.use_random_encounters = true

	encounter_manager.forced_encounter_type = "BOSS"
	encounter_manager.forced_boss_id = "enemy_boss_swamp_devourer"

	var encounter: Dictionary = encounter_manager.get_encounter(10)
	_expect_string(str(encounter.get("encounter_type", "")), "BOSS", "EncounterManager should produce BOSS with forced type.")

	var enemy_units: Array = encounter.get("enemy_units", []) as Array
	var boss_found: bool = false
	for unit_value: Variant in enemy_units:
		var unit: Dictionary = unit_value as Dictionary
		if str(unit.get("unit_id", "")) == "enemy_boss_swamp_devourer":
			boss_found = true
			break
	_expect_true(boss_found, "EncounterManager should respect forced_boss_id.")

	var second_encounter: Dictionary = encounter_manager.get_encounter(10)
	var second_units: Array = second_encounter.get("enemy_units", []) as Array
	var second_boss_found: bool = false
	for unit_value: Variant in second_units:
		var unit: Dictionary = unit_value as Dictionary
		if str(unit.get("unit_id", "")) == "enemy_boss_swamp_devourer":
			second_boss_found = true
			break
	_expect_true(second_boss_found, "Cached encounter should still have forced boss.")


func _finish() -> void:
	if failures.is_empty():
		print("Chapter boss encounter tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected '" + expected + "', got '" + actual + "'.")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
