extends SceneTree

const BATTLE_MANAGER_SCRIPT: Script = preload("res://scripts/battle_manager.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const BONE_ACOLYTE_DATA: Resource = preload("res://data/units/bone_acolyte.tres")
const GRAVE_WARDEN_DATA: Resource = preload("res://data/units/grave_warden.tres")
const SKELETON_SUMMON_DATA: Resource = preload("res://data/summons/skeleton.tres")

class BattleRootProxy:
	extends Node2D

	var battle_manager: Variant = null

	func summon_units(source_unit: Unit, summon_unit_data: Resource, count: int, context: Dictionary = {}) -> Array[Unit]:
		if battle_manager == null or not battle_manager.has_method("summon_units"):
			var empty_units: Array[Unit] = []
			return empty_units

		return battle_manager.summon_units(source_unit, summon_unit_data, count, context)


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	seed(42)
	_test_bone_acolyte_data_loaded()
	_test_grave_warden_data_loaded()
	_test_bone_acolyte_summon_count_and_bonus()
	_test_bone_acolyte_star_three_bonus()
	_test_grave_warden_bone_shield_command()
	_test_grave_warden_bone_shield_command_star_3()
	_test_grave_warden_shield_on_summon_death()
	_finish()


func _test_bone_acolyte_data_loaded() -> void:
	_expect_true(BONE_ACOLYTE_DATA != null, "Bone Acolyte data should be loaded.")
	_expect_string(BONE_ACOLYTE_DATA.unit_type, "bone_acolyte", "Bone Acolyte unit_type should be bone_acolyte.")
	_expect_string(BONE_ACOLYTE_DATA.rarity, "COMMON", "Bone Acolyte rarity should be COMMON.")
	_expect_int(BONE_ACOLYTE_DATA.catalog_id, 31, "Bone Acolyte catalog_id should be 31.")
	_expect_string(BONE_ACOLYTE_DATA.passive_id, "bone_familiarity", "Bone Acolyte passive_id should be bone_familiarity.")
	_expect_string(BONE_ACOLYTE_DATA.active_skill_id, "lesser_raise_bones", "Bone Acolyte active_skill_id should be lesser_raise_bones.")


func _test_grave_warden_data_loaded() -> void:
	_expect_true(GRAVE_WARDEN_DATA != null, "Grave Warden data should be loaded.")
	_expect_string(GRAVE_WARDEN_DATA.unit_type, "grave_warden", "Grave Warden unit_type should be grave_warden.")
	_expect_string(GRAVE_WARDEN_DATA.rarity, "FINE", "Grave Warden rarity should be FINE.")
	_expect_int(GRAVE_WARDEN_DATA.catalog_id, 32, "Grave Warden catalog_id should be 32.")
	_expect_string(GRAVE_WARDEN_DATA.passive_id, "grave_armor", "Grave Warden passive_id should be grave_armor.")
	_expect_string(GRAVE_WARDEN_DATA.active_skill_id, "bone_shield_command", "Grave Warden active_skill_id should be bone_shield_command.")


func _test_bone_acolyte_summon_count_and_bonus() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager

	var acolyte: Unit = _spawn_player_unit(battle_manager, BONE_ACOLYTE_DATA, Vector2(120.0, 240.0), 1)
	acolyte.star = 1
	battle_manager.start_battle()

	acolyte.unit_skill.try_cast_active_skill(acolyte)
	var summoned: Array[Unit] = _find_summoned_skeletons(battle_manager.get_left_units())
	_expect_int(summoned.size(), 1, "Star 1 Bone Acolyte should summon 1 skeleton.")
	if not summoned.is_empty():
		var skeleton: Unit = summoned[0]
		_expect_string(skeleton.unit_type, "summoned_skeleton", "Summoned unit should be a skeleton.")
		_expect_int(skeleton.attack_damage, 11, "Star 1 skeleton should receive 10% bone_familiarity attack bonus (10 -> 11).")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_bone_acolyte_star_three_bonus() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager

	var acolyte: Unit = _spawn_player_unit(battle_manager, BONE_ACOLYTE_DATA, Vector2(120.0, 240.0), 1)
	acolyte.star = 3
	battle_manager.start_battle()

	acolyte.unit_skill.try_cast_active_skill(acolyte)
	var summoned: Array[Unit] = _find_summoned_skeletons(battle_manager.get_left_units())
	_expect_int(summoned.size(), 2, "Star 3 Bone Acolyte should summon 2 skeletons.")
	if not summoned.is_empty():
		var skeleton: Unit = summoned[0]
		_expect_int(skeleton.attack_damage, 21, "Star 3 skeleton should receive 18% bone_familiarity attack bonus (18 -> 21).")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_grave_warden_bone_shield_command() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager

	var warden: Unit = _spawn_player_unit(battle_manager, GRAVE_WARDEN_DATA, Vector2(120.0, 240.0), 1)
	warden.star = 1
	warden.shield = 0

	var summon: Unit = _spawn_summon(battle_manager, warden, Vector2(130.0, 240.0))
	summon.shield = 0

	battle_manager.start_battle()
	warden.unit_skill.try_cast_active_skill(warden)

	var expected_self_shield: int = int(round(40.0 + 0.12 * float(warden.max_hp)))
	_expect_int(warden.shield, expected_self_shield, "Star 1 Grave Warden should grant itself expected shield from bone_shield_command.")
	var expected_summon_shield: int = int(round(25.0 + 0.60 * float(warden.attack_damage)))
	_expect_int(summon.shield, expected_summon_shield, "Star 1 summon within range should receive expected shield from bone_shield_command.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_grave_warden_bone_shield_command_star_3() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager

	var warden: Unit = _spawn_player_unit(battle_manager, GRAVE_WARDEN_DATA, Vector2(120.0, 240.0), 1)
	warden.star = 3
	# Simulate star-3 scaled stats as they would appear entering battle from roster.
	warden.max_hp = int(round(float(GRAVE_WARDEN_DATA.max_hp) * 2.1))
	warden.hp = warden.max_hp
	warden.attack_damage = int(round(float(GRAVE_WARDEN_DATA.attack_damage) * 1.4))
	warden.shield = 0

	var summon: Unit = _spawn_summon(battle_manager, warden, Vector2(130.0, 240.0))
	summon.shield = 0

	battle_manager.start_battle()
	warden.unit_skill.try_cast_active_skill(warden)

	# self shield = round(60 + 0.16 * 483) = 137
	var expected_self_shield: int = int(round(60.0 + 0.16 * float(warden.max_hp)))
	_expect_int(warden.shield, expected_self_shield, "Star 3 Grave Warden should grant itself expected shield from bone_shield_command.")
	# summon shield = round(35 + 0.80 * 18) = 49
	var expected_summon_shield: int = int(round(35.0 + 0.80 * float(warden.attack_damage)))
	_expect_int(summon.shield, expected_summon_shield, "Star 3 summon within range should receive expected shield from bone_shield_command.")
	_expect_int(summon.get_status_effect_count("bone_shield_command_reduction"), 1, "Star 3 summon should receive bone_shield_command_reduction status effect.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_grave_warden_shield_on_summon_death() -> void:
	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	get_root().add_child(unit)
	unit.unit_id = 1
	unit.unit_data = GRAVE_WARDEN_DATA
	unit.unit_type = "grave_warden"
	unit.display_name = "Grave Warden"
	unit.team_id = 1
	unit.is_alive = true
	unit.is_targetable = true
	unit.max_hp = GRAVE_WARDEN_DATA.max_hp
	unit.hp = GRAVE_WARDEN_DATA.max_hp
	unit.attack_damage = GRAVE_WARDEN_DATA.attack_damage
	unit.defense = GRAVE_WARDEN_DATA.defense
	unit.passive_id = "grave_armor"
	unit.active_skill_id = "bone_shield_command"
	unit.shield = 0
	unit.battle_elapsed_time = 10.0

	var summon: Unit = UNIT_SCENE.instantiate() as Unit
	get_root().add_child(summon)
	summon.unit_id = 2
	summon.set_meta("is_summon", true)
	summon.is_alive = true

	unit.unit_skill.passive_resolver.notify_ally_died(unit, summon)
	_expect_int(unit.shield, 12, "Grave Warden should gain 12 shield when a summon dies (star 1).")

	unit.queue_free()
	summon.queue_free()


func _create_battle_root() -> BattleRootProxy:
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(battle_root)
	return battle_root


func _create_battle_manager(battle_root: BattleRootProxy) -> Variant:
	var battle_manager: Variant = BATTLE_MANAGER_SCRIPT.new()
	battle_manager.setup(battle_root, UNIT_SCENE, null, RelicManager.new())
	return battle_manager


func _spawn_player_unit(battle_manager: Variant, unit_data: Resource, position: Vector2, roster_id: int) -> Unit:
	var config: Dictionary = {
		"unit_data": unit_data,
		"position": position,
		"display_name": unit_data.unit_name,
		"roster_id": roster_id,
	}
	var player_configs: Array[Dictionary] = [config]
	var enemy_configs: Array[Dictionary] = []
	battle_manager.spawn_battle(player_configs, enemy_configs)
	var left_units: Array[Unit] = battle_manager.get_left_units()
	if left_units.is_empty():
		return null
	return left_units[-1]


func _spawn_summon(battle_manager: Variant, source_unit: Unit, position: Vector2) -> Unit:
	return battle_manager.spawn_summoned_unit(source_unit, SKELETON_SUMMON_DATA, position, {})


func _find_summoned_skeletons(units: Array[Unit]) -> Array[Unit]:
	var result: Array[Unit] = []
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and unit.is_alive and unit.unit_type == "summoned_skeleton":
			result.append(unit)
	return result


func _finish() -> void:
	if failures.is_empty():
		print("New unit tests passed.")
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
