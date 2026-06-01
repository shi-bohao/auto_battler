extends SceneTree

const ENEMY_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/enemy_catalog.gd")
const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const BATTLE_BOARD_SCRIPT: Script = preload("res://scripts/battle_board.gd")
const FIELD_EFFECT_MANAGER_SCRIPT: Script = preload("res://scripts/combat/field_effect_manager.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_boss_catalog_and_skill_text()
	_test_boss_positions()
	_test_shape_status_field_creation()
	_finish()


func _test_boss_catalog_and_skill_text() -> void:
	var catalog: Variant = ENEMY_CATALOG_SCRIPT.new()
	var formatter: Variant = UNIT_TEXT_FORMATTER_SCRIPT.new()
	var specs: Array[Dictionary] = [
		{"id": "enemy_boss_treant_overlord", "passive": "boss_ancient_vitality", "active": "boss_root_sweep", "role": "tank"},
		{"id": "enemy_boss_swamp_devourer", "passive": "boss_corpse_devour", "active": "boss_mire_engulf", "role": "tank"},
		{"id": "enemy_boss_lava_colossus", "passive": "boss_molten_body", "active": "boss_magma_fissure", "role": "tank"},
		{"id": "enemy_boss_scourge_lord", "passive": "boss_raise_the_fallen", "active": "boss_undead_warband", "role": "support"},
		{"id": "enemy_boss_faelord_of_the_grove", "passive": "boss_grove_resonance", "active": "boss_starleaf_storm", "role": "support"},
	]

	for spec: Dictionary in specs:
		var unit_id: String = str(spec["id"])
		var unit_data: Resource = catalog.get_unit_data_by_id(unit_id)
		_expect_true(unit_data != null, unit_id + " should load from EnemyCatalog.")
		if unit_data == null:
			continue
		_expect_string(str(unit_data.get("enemy_tier")), "BOSS", unit_id + " should be a BOSS.")
		_expect_true(str(unit_data.get("unit_name_cn")).begins_with("BOSS："), unit_id + " CN name should use BOSS prefix.")
		_expect_string(str(unit_data.get("passive_id")), str(spec["passive"]), unit_id + " passive id should match.")
		_expect_string(str(unit_data.get("active_skill_id")), str(spec["active"]), unit_id + " active id should match.")
		_expect_string(catalog.get_unit_role(unit_id), str(spec["role"]), unit_id + " role should match.")
		_expect_true(formatter.get_passive_skill_text(str(spec["passive"]), 1).find("Unknown") < 0, unit_id + " passive text should be defined.")
		_expect_true(formatter.get_active_skill_text(str(spec["active"]), 1).find("Unknown") < 0, unit_id + " active text should be defined.")

	var boss_ids: Array[String] = catalog.get_boss_enemy_ids()
	for spec: Dictionary in specs:
		_expect_true(boss_ids.has(str(spec["id"])), str(spec["id"]) + " should be in boss pool.")


func _test_boss_positions() -> void:
	var battle_board: BattleBoard = BATTLE_BOARD_SCRIPT.new() as BattleBoard
	var frontline_ids: Array[String] = [
		"enemy_boss_treant_overlord",
		"enemy_boss_swamp_devourer",
		"enemy_boss_lava_colossus",
	]
	for unit_id: String in frontline_ids:
		var cell: Vector2i = battle_board.choose_enemy_cell_for_unit(unit_id, "tank", [], false)
		_expect_int(cell.x, BattleBoard.ENEMY_MIN_COL, unit_id + " should prefer the enemy frontline.")

	var backline_ids: Array[String] = [
		"enemy_boss_scourge_lord",
		"enemy_boss_faelord_of_the_grove",
	]
	for unit_id: String in backline_ids:
		var cell: Vector2i = battle_board.choose_enemy_cell_for_unit(unit_id, "support", [], false)
		_expect_true(cell.x >= BattleBoard.ENEMY_MIN_COL + 4, unit_id + " should prefer the enemy backline.")
	battle_board.free()


func _test_shape_status_field_creation() -> void:
	var root: Node2D = Node2D.new()
	get_root().add_child(root)
	var manager: Variant = FIELD_EFFECT_MANAGER_SCRIPT.new()
	manager.setup(root, root)
	var field_id: int = manager.create_shape_status_field(null, {
		"shape_type": "rect",
		"origin": Vector2(100.0, 100.0),
		"direction": Vector2.LEFT,
		"length": 180.0,
		"width": 80.0,
		"anchor": "forward",
	}, 3.0, 1.0, {
		"mode": "burning",
		"duration": 2.0,
		"damage_per_second": 5.0,
		"damage_per_tick": 3,
	}, Color(1.0, 0.2, 0.1, 0.2))
	_expect_true(field_id > 0, "Shape status fields should be creatable for persistent boss areas.")
	root.queue_free()


func _finish() -> void:
	if failures.is_empty():
		print("test_boss_units: PASS")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_true(actual: bool, message: String) -> void:
	if not actual:
		failures.append(message)


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + expected + ", got " + actual + ".")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
