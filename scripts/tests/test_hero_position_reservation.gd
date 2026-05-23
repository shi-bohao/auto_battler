extends SceneTree

const ROSTER_MANAGER_SCRIPT: Script = preload("res://scripts/roster_manager.gd")
const HERO_MANAGER_SCRIPT: Script = preload("res://scripts/hero_manager.gd")
const BATTLE_BOARD_SCRIPT: Script = preload("res://scripts/battle_board.gd")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const ARCHER_DATA: Resource = preload("res://data/units/archer.tres")
const ASSASSIN_DATA: Resource = preload("res://data/units/assassin.tres")

var failures: Array[String] = []


func _init() -> void:
	_test_saved_hero_cell_is_reserved_for_roster_layout()

	if failures.is_empty():
		print("Hero position reservation tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_saved_hero_cell_is_reserved_for_roster_layout() -> void:
	var battle_board: BattleBoard = BATTLE_BOARD_SCRIPT.new() as BattleBoard
	var roster_manager: Variant = ROSTER_MANAGER_SCRIPT.new()
	roster_manager.setup(WARRIOR_DATA, ARCHER_DATA, ASSASSIN_DATA)
	roster_manager.reset_roster()

	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	hero_manager.select_hero("iron_oath_commander")
	var reserved_cell: Vector2i = Vector2i(6, 2)
	hero_manager.save_hero_cell(reserved_cell, battle_board.grid_to_world(reserved_cell))

	var reserved_cells: Array[Vector2i] = [hero_manager.get_reserved_hero_cell(battle_board)]
	var configs: Array[Dictionary] = roster_manager.get_player_battle_unit_configs(battle_board, reserved_cells)
	_expect_bool(not configs.is_empty(), true, "Roster layout should create player unit configs.")
	for config: Dictionary in configs:
		var cell: Vector2i = config.get("cell", Vector2i(-1, -1)) as Vector2i
		_expect_bool(cell != reserved_cell, true, "Normal roster layout should not occupy the saved hero cell.")

	battle_board.free()


func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
