extends SceneTree

const BATTLE_MANAGER_SCRIPT: Script = preload("res://scripts/battle_manager.gd")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")

class BattleRootProxy:
	extends Node2D
	var battle_manager: Variant = null

class MockRosterManager:
	extends RefCounted
	var has_death_prevention: bool = false

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	seed(42)
	_test_death_prevention_keeps_unit_alive()
	_test_death_prevention_once_per_unit_per_battle()
	_test_death_prevention_does_not_affect_enemies()
	_finish()

func _test_death_prevention_keeps_unit_alive() -> void:
	var battle_root: Node2D = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	var roster_manager: MockRosterManager = MockRosterManager.new()
	roster_manager.has_death_prevention = true
	battle_manager.roster_manager = roster_manager

	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 220.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 260.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var player_unit: Unit = battle_manager.get_left_units()[0]
	var enemy_unit: Unit = battle_manager.get_right_units()[0]

	_expect_true(player_unit.hp > 0, "Player unit should have HP before damage.")
	player_unit.take_damage(player_unit.hp + 100, enemy_unit, false)
	_expect_true(player_unit.is_alive, "Death prevention should keep unit alive.")
	_expect_int(player_unit.hp, 1, "Death prevention should leave unit at 1 HP.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()

func _test_death_prevention_once_per_unit_per_battle() -> void:
	var battle_root: Node2D = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	var roster_manager: MockRosterManager = MockRosterManager.new()
	roster_manager.has_death_prevention = true
	battle_manager.roster_manager = roster_manager

	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 220.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 260.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var player_unit: Unit = battle_manager.get_left_units()[0]
	var enemy_unit: Unit = battle_manager.get_right_units()[0]

	# First lethal damage
	player_unit.take_damage(player_unit.hp + 100, enemy_unit, false)
	_expect_true(player_unit.is_alive, "First lethal damage should be prevented.")
	_expect_int(player_unit.hp, 1, "Unit should be at 1 HP after first prevention.")

	# Second lethal damage
	player_unit.take_damage(100, enemy_unit, false)
	_expect_true(not player_unit.is_alive, "Second lethal damage should kill unit.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()

func _test_death_prevention_does_not_affect_enemies() -> void:
	var battle_root: Node2D = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	var roster_manager: MockRosterManager = MockRosterManager.new()
	roster_manager.has_death_prevention = true
	battle_manager.roster_manager = roster_manager

	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 220.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 260.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var player_unit: Unit = battle_manager.get_left_units()[0]
	var enemy_unit: Unit = battle_manager.get_right_units()[0]

	# Enemy takes lethal damage
	enemy_unit.take_damage(enemy_unit.hp + 100, player_unit, false)
	_expect_true(not enemy_unit.is_alive, "Death prevention should not affect enemies.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()

func _create_battle_root() -> Node2D:
	var battle_root: Node2D = Node2D.new()
	get_root().add_child(battle_root)
	return battle_root

func _create_battle_manager(battle_root: Node) -> Variant:
	var battle_manager: Variant = BATTLE_MANAGER_SCRIPT.new()
	battle_manager.setup(battle_root, UNIT_SCENE, null, null)
	return battle_manager

func _create_config(unit_data: Resource, position: Vector2, roster_id: int) -> Dictionary:
	return {
		"unit_data": unit_data,
		"position": position,
		"display_name": "Test Unit " + str(roster_id),
		"roster_id": roster_id,
	}

func _finish() -> void:
	if failures.is_empty():
		print("Death prevention tests passed.")
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
