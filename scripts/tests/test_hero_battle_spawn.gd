extends SceneTree

const BATTLE_MANAGER_SCRIPT: Script = preload("res://scripts/battle_manager.gd")
const HERO_MANAGER_SCRIPT: Script = preload("res://scripts/hero_manager.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var battle_root: Node2D = Node2D.new()
	get_root().add_child(battle_root)

	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	hero_manager.select_hero("iron_oath_commander")

	var battle_manager: Variant = BATTLE_MANAGER_SCRIPT.new()
	battle_manager.setup(battle_root, UNIT_SCENE, null, null, null, Callable(), hero_manager)
	var player_configs: Array[Dictionary] = _create_player_configs(10)
	var enemy_configs: Array[Dictionary] = []
	var bench_configs: Array[Dictionary] = []
	battle_manager.spawn_battle(player_configs, enemy_configs, bench_configs)

	var player_units: Array[Unit] = battle_manager.get_left_units()
	_expect_int(player_units.size(), 11, "BattleManager should spawn normal units plus one hero.")
	var hero_unit: Unit = _find_hero_unit(player_units)
	_expect_bool(hero_unit != null, true, "Spawned player team should include a hero unit.")
	if hero_unit != null:
		_expect_string(str(hero_unit.roster_area), "hero", "Hero unit roster area should be hero.")
		_expect_int(hero_unit.roster_id, -1, "Hero unit should not use a normal roster id.")
		_expect_bool(hero_unit.drag_controller.can_drag, true, "Hero unit should be draggable in prepare.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()
	_finish()


func _create_player_configs(count: int) -> Array[Dictionary]:
	var configs: Array[Dictionary] = []
	for index: int in range(count):
		configs.append({
			"unit_data": WARRIOR_DATA.duplicate(true),
			"position": Vector2(80.0 + float(index) * 16.0, 240.0),
			"display_name": "战士 " + str(index + 1),
			"roster_id": index + 1,
		})

	return configs


func _find_hero_unit(units: Array[Unit]) -> Unit:
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and bool(unit.get_meta("is_hero", false)):
			return unit

	return null


func _finish() -> void:
	if failures.is_empty():
		print("Hero battle spawn tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + expected + ", got " + actual + ".")
