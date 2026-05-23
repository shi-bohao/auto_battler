extends SceneTree

const LINEUP_SNAPSHOT_MANAGER_SCRIPT: Script = preload("res://scripts/lineup_snapshot_manager.gd")
const MIRROR_CHALLENGE_MANAGER_SCRIPT: Script = preload("res://scripts/game/mirror_challenge_manager.gd")
const ROSTER_MANAGER_SCRIPT: Script = preload("res://scripts/roster_manager.gd")
const ENCOUNTER_MANAGER_SCRIPT: Script = preload("res://scripts/encounter_manager.gd")
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

var failures: Array[String] = []


func _init() -> void:
	_test_mirror_challenge_locks_boss_encounters()

	if failures.is_empty():
		print("Mirror challenge tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_mirror_challenge_locks_boss_encounters() -> void:
	var storage_path: String = "res://.godot_user/mirror_challenge_test_" + str(Time.get_ticks_usec()) + ".json"
	var snapshot_writer: Variant = LINEUP_SNAPSHOT_MANAGER_SCRIPT.new()
	snapshot_writer.storage_path = storage_path
	snapshot_writer.append_snapshot(_create_snapshot_for_round(10, Vector2i(2, 1), "warrior"))
	snapshot_writer.append_snapshot(_create_snapshot_for_round(20, Vector2i(0, 3), "archer"))

	var mirror_manager: Variant = MIRROR_CHALLENGE_MANAGER_SCRIPT.new()
	mirror_manager.snapshot_manager.storage_path = storage_path
	mirror_manager.prepare_challenge(20)

	_expect_bool(mirror_manager.has_mirror_for_round(10), true, "Mirror challenge should lock round 10.")
	_expect_bool(mirror_manager.has_mirror_for_round(20), true, "Mirror challenge should lock round 20.")

	var mirror_encounters: Dictionary = mirror_manager.get_mirror_encounters()
	var round_10_encounter: Dictionary = mirror_encounters[10] as Dictionary
	_expect_string(str(round_10_encounter.get("encounter_type", "")), "BOSS", "Mirror encounter should remain a BOSS encounter.")
	_expect_bool(bool(round_10_encounter.get("is_mirror_challenge", false)), true, "Mirror encounter should be marked.")

	var round_10_units: Array = round_10_encounter.get("enemy_units", []) as Array
	_expect_int(round_10_units.size(), 4, "Mirror encounter should use active snapshot units.")
	if not round_10_units.is_empty():
		var first_unit: Dictionary = round_10_units[0] as Dictionary
		_expect_string(str(first_unit.get("unit_id", "")), "warrior", "Mirror unit should preserve unit_id.")
		_expect_vector2i(first_unit.get("cell", Vector2i(-1, -1)) as Vector2i, Vector2i(12, 1), "Mirror unit cell should be mirrored to enemy side.")

	var relic_ids: Array[String] = mirror_manager.get_relic_ids_for_round(10)
	_expect_int(relic_ids.size(), 1, "Mirror relic ids should come from selected snapshot.")
	if not relic_ids.is_empty():
		_expect_string(relic_ids[0], "blood_pendant", "Mirror relic id should match snapshot relic.")

	var encounter_manager: Variant = ENCOUNTER_MANAGER_SCRIPT.new()
	encounter_manager.setup(WARRIOR_DATA, ARCHER_DATA, ASSASSIN_DATA, TANK_DATA, MAGE_DATA, PRIEST_DATA, BARD_DATA)
	encounter_manager.set_mirror_boss_encounters(mirror_encounters)
	var enemy_configs: Array[Dictionary] = encounter_manager.get_enemy_unit_configs(10)
	_expect_int(enemy_configs.size(), 4, "EncounterManager should convert mirror encounter to enemy configs.")
	if not enemy_configs.is_empty():
		var first_config: Dictionary = enemy_configs[0]
		var unit_data: Resource = first_config.get("unit_data", null) as Resource
		_expect_bool(unit_data != null, true, "Mirror unit config should resolve unit resource.")
		_expect_string(str(unit_data.get("unit_type")), "warrior", "Mirror unit resource should preserve player unit type.")


func _create_snapshot_for_round(round_number: int, saved_cell: Vector2i, extra_unit_id: String) -> Dictionary:
	var roster_manager: Variant = _create_roster_manager()
	var relic_manager: RelicManager = RelicManager.new()
	var economy_manager: Variant = ECONOMY_MANAGER_SCRIPT.new()
	var run_controller: Variant = RUN_CONTROLLER_SCRIPT.new()
	var snapshot_manager: Variant = LINEUP_SNAPSHOT_MANAGER_SCRIPT.new()

	roster_manager.reset_roster()
	roster_manager.add_unit_by_id(extra_unit_id)
	_set_first_active_unit_layout(roster_manager, saved_cell)
	roster_manager.apply_team_hp_bonus(0.10)
	roster_manager.apply_team_attack_bonus(0.10)
	relic_manager.add_relic(BLOOD_PENDANT)
	run_controller.current_round = round_number
	run_controller.max_round = 20
	economy_manager.gold = 30 + round_number
	return snapshot_manager.build_boss_victory_snapshot(
		roster_manager,
		relic_manager,
		economy_manager,
		run_controller,
		{
			"encounter_type": "BOSS",
			"encounter_name": "Snapshot Boss " + str(round_number),
		}
	)


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


func _set_first_active_unit_layout(roster_manager: Variant, saved_cell: Vector2i) -> void:
	var first_unit: Dictionary = roster_manager.active_roster[0]
	first_unit["has_saved_cell"] = true
	first_unit["saved_cell"] = saved_cell
	first_unit["has_saved_position"] = true
	first_unit["saved_position"] = Vector2(320.0, 240.0)
	roster_manager.active_roster[0] = first_unit


func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + expected + ", got " + actual + ".")


func _expect_vector2i(actual: Vector2i, expected: Vector2i, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
