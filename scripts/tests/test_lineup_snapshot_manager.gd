extends SceneTree

const LINEUP_SNAPSHOT_MANAGER_SCRIPT: Script = preload("res://scripts/lineup_snapshot_manager.gd")
const ROSTER_MANAGER_SCRIPT: Script = preload("res://scripts/roster_manager.gd")
const ECONOMY_MANAGER_SCRIPT: Script = preload("res://scripts/game/economy_manager.gd")
const RUN_CONTROLLER_SCRIPT: Script = preload("res://scripts/game/run_controller.gd")

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

const BLOOD_PENDANT: Resource = preload("res://data/relics/blood_pendant.tres")
const SOUL_LANTERN: Resource = preload("res://data/relics/soul_lantern.tres")

var failures: Array[String] = []


func _init() -> void:
	_test_build_parse_restore_snapshot()
	_test_append_and_load_snapshot()

	if failures.is_empty():
		print("Lineup snapshot tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_build_parse_restore_snapshot() -> void:
	var snapshot_manager: Variant = LINEUP_SNAPSHOT_MANAGER_SCRIPT.new()
	var roster_manager: Variant = _create_roster_manager()
	var relic_manager: RelicManager = RelicManager.new()
	var economy_manager: Variant = ECONOMY_MANAGER_SCRIPT.new()
	var run_controller: Variant = RUN_CONTROLLER_SCRIPT.new()
	var encounter: Dictionary = _create_boss_encounter()

	roster_manager.reset_roster()
	roster_manager.apply_team_hp_bonus(0.10)
	roster_manager.apply_team_attack_bonus(0.10)
	roster_manager.add_unit_by_id("mage")
	_set_first_active_unit_layout(roster_manager)
	relic_manager.add_relic(BLOOD_PENDANT)
	relic_manager.add_relic(SOUL_LANTERN)
	economy_manager.gold = 42
	run_controller.current_round = 10
	run_controller.max_round = 30

	var snapshot: Dictionary = snapshot_manager.build_boss_victory_snapshot(
		roster_manager,
		relic_manager,
		economy_manager,
		run_controller,
		encounter
	)
	_expect_string(str(snapshot.get("source", "")), "BOSS_VICTORY", "Snapshot source should mark boss victory.")
	_expect_int(int((snapshot.get("relics", []) as Array).size()), 2, "Snapshot should include owned relics.")

	var parsed_snapshot: Dictionary = snapshot_manager.parse_snapshot(snapshot, roster_manager, relic_manager)
	_expect_int(int((parsed_snapshot.get("active_units", []) as Array).size()), 4, "Parsed snapshot should resolve active units.")
	_expect_int(int((parsed_snapshot.get("relics", []) as Array).size()), 2, "Parsed snapshot should resolve relic resources.")

	var restored_roster_manager: Variant = _create_roster_manager()
	var restored_relic_manager: RelicManager = RelicManager.new()
	var restored: bool = snapshot_manager.restore_snapshot_to_managers(snapshot, restored_roster_manager, restored_relic_manager)
	_expect_bool(restored, true, "Snapshot should restore into managers.")
	_expect_float(restored_roster_manager.player_hp_multiplier, 1.10, "Restored HP multiplier should match snapshot.")
	_expect_float(restored_roster_manager.player_attack_multiplier, 1.10, "Restored attack multiplier should match snapshot.")
	_expect_bool(restored_relic_manager.has_relic_id("blood_pendant"), true, "Restored relic manager should include Blood Pendant.")
	_expect_bool(restored_relic_manager.has_relic_id("soul_lantern"), true, "Restored relic manager should include Soul Lantern.")

	var restored_active_roster: Array[Dictionary] = restored_roster_manager.get_active_roster()
	_expect_int(restored_active_roster.size(), 4, "Restored active roster size should match snapshot.")
	if not restored_active_roster.is_empty():
		var first_unit: Dictionary = restored_active_roster[0]
		_expect_int(int(first_unit.get("star", 0)), 2, "Restored unit star should match snapshot.")
		_expect_vector2i(first_unit.get("saved_cell", Vector2i(-1, -1)) as Vector2i, Vector2i(2, 1), "Restored saved cell should match snapshot.")


func _test_append_and_load_snapshot() -> void:
	var snapshot_manager: Variant = LINEUP_SNAPSHOT_MANAGER_SCRIPT.new()
	snapshot_manager.storage_path = "res://.godot_user/lineup_snapshot_test_" + str(Time.get_ticks_usec()) + ".json"

	var roster_manager: Variant = _create_roster_manager()
	var relic_manager: RelicManager = RelicManager.new()
	var economy_manager: Variant = ECONOMY_MANAGER_SCRIPT.new()
	var run_controller: Variant = RUN_CONTROLLER_SCRIPT.new()
	roster_manager.reset_roster()
	run_controller.current_round = 20
	run_controller.max_round = 30

	var snapshot: Dictionary = snapshot_manager.build_boss_victory_snapshot(
		roster_manager,
		relic_manager,
		economy_manager,
		run_controller,
		_create_boss_encounter()
	)
	var snapshot_id: String = str(snapshot.get("snapshot_id", ""))
	_expect_bool(snapshot_manager.append_snapshot(snapshot), true, "Snapshot append should write storage.")

	var loaded_snapshots: Array[Dictionary] = snapshot_manager.load_all_snapshots()
	_expect_int(loaded_snapshots.size(), 1, "Storage should load one appended snapshot.")
	if not loaded_snapshots.is_empty():
		_expect_string(str(loaded_snapshots[0].get("snapshot_id", "")), snapshot_id, "Loaded snapshot id should match saved id.")


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
		ALCHEMIST_DATA
	)
	return roster_manager


func _set_first_active_unit_layout(roster_manager: Variant) -> void:
	var first_unit: Dictionary = roster_manager.active_roster[0]
	first_unit["star"] = 2
	first_unit["has_saved_cell"] = true
	first_unit["saved_cell"] = Vector2i(2, 1)
	first_unit["has_saved_position"] = true
	first_unit["saved_position"] = Vector2(320.0, 240.0)
	roster_manager.active_roster[0] = first_unit


func _create_boss_encounter() -> Dictionary:
	return {
		"encounter_type": "BOSS",
		"encounter_name": "Test Boss",
	}


func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + expected + ", got " + actual + ".")


func _expect_vector2i(actual: Vector2i, expected: Vector2i, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
