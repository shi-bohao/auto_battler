extends SceneTree

const ENEMY_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/enemy_catalog.gd")
const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const BATTLE_BOARD_SCRIPT: Script = preload("res://scripts/battle_board.gd")
const COMBAT_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/combat_resolver.gd")
const STATUS_EFFECT_FACTORY_SCRIPT: Script = preload("res://scripts/combat/status_effect_factory.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")

const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const IRON_BULWARK_DATA: Resource = preload("res://data/enemies/elite_iron_bulwark.tres")
const FROST_THORN_WITCH_DATA: Resource = preload("res://data/enemies/elite_frost_thorn_witch.tres")
const BLOOD_BANNER_WARLORD_DATA: Resource = preload("res://data/enemies/elite_blood_banner_warlord.tres")
const MIRROR_CARAPACE_BEETLE_DATA: Resource = preload("res://data/enemies/elite_mirror_carapace_beetle.tres")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_catalog_and_skill_text()
	_test_positions()
	_test_mirror_reflects_skill_damage()
	_finish()


func _test_catalog_and_skill_text() -> void:
	var catalog: Variant = ENEMY_CATALOG_SCRIPT.new()
	var formatter: Variant = UNIT_TEXT_FORMATTER_SCRIPT.new()
	var specs: Array[Dictionary] = [
		{"id": "enemy_elite_iron_bulwark", "passive": "enemy_iron_bulwark", "active": "enemy_bulwark_slam", "role": "tank"},
		{"id": "enemy_elite_frost_thorn_witch", "passive": "enemy_frost_mark", "active": "enemy_frost_thorn_burst", "role": "support"},
		{"id": "enemy_elite_blood_banner_warlord", "passive": "enemy_blood_banner_aura", "active": "enemy_crimson_banner", "role": "support"},
		{"id": "enemy_elite_mirror_carapace_beetle", "passive": "enemy_mirror_carapace", "active": "enemy_refraction_shell", "role": "tank"},
	]

	for spec: Dictionary in specs:
		var unit_id: String = str(spec["id"])
		var unit_data: Resource = catalog.get_unit_data_by_id(unit_id)
		_expect_true(unit_data != null, unit_id + " should load from EnemyCatalog.")
		if unit_data == null:
			continue
		_expect_string(str(unit_data.get("enemy_tier")), "ELITE", unit_id + " should be an ELITE enemy.")
		_expect_true(str(unit_data.get("unit_name_cn")).begins_with("精英："), unit_id + " CN name should use elite prefix.")
		_expect_string(str(unit_data.get("passive_id")), str(spec["passive"]), unit_id + " passive id should match.")
		_expect_string(str(unit_data.get("active_skill_id")), str(spec["active"]), unit_id + " active id should match.")
		_expect_string(catalog.get_unit_role(unit_id), str(spec["role"]), unit_id + " role should match.")
		_expect_true(formatter.get_passive_skill_text(str(spec["passive"]), 3).find("Unknown") < 0, unit_id + " passive text should be defined.")
		_expect_true(formatter.get_active_skill_text(str(spec["active"]), 3).find("Unknown") < 0, unit_id + " active text should be defined.")

	_expect_true(catalog.get_available_unit_ids_by_role("tank", "ELITE").has("enemy_elite_iron_bulwark"), "Iron Bulwark should be in elite tank pool.")
	_expect_true(catalog.get_available_unit_ids_by_role("tank", "ELITE").has("enemy_elite_mirror_carapace_beetle"), "Mirror Beetle should be in elite tank pool.")
	_expect_true(catalog.get_available_unit_ids_by_role("support", "ELITE").has("enemy_elite_frost_thorn_witch"), "Frost Thorn Witch should be in elite support pool.")
	_expect_true(catalog.get_available_unit_ids_by_role("support", "ELITE").has("enemy_elite_blood_banner_warlord"), "Blood Banner Warlord should be in elite support pool.")


func _test_positions() -> void:
	var battle_board: BattleBoard = BATTLE_BOARD_SCRIPT.new() as BattleBoard
	var front_cell: Vector2i = battle_board.choose_enemy_cell_for_unit("enemy_elite_iron_bulwark", "tank", [], false)
	_expect_int(front_cell.x, BattleBoard.ENEMY_MIN_COL, "Iron Bulwark should prefer frontline.")
	var mirror_cell: Vector2i = battle_board.choose_enemy_cell_for_unit("enemy_elite_mirror_carapace_beetle", "tank", [], false)
	_expect_int(mirror_cell.x, BattleBoard.ENEMY_MIN_COL, "Mirror Beetle should prefer frontline.")
	var witch_cell: Vector2i = battle_board.choose_enemy_cell_for_unit("enemy_elite_frost_thorn_witch", "support", [], false)
	_expect_true(witch_cell.x >= BattleBoard.ENEMY_MIN_COL + 4, "Frost Thorn Witch should prefer backline.")
	battle_board.free()


func _test_mirror_reflects_skill_damage() -> void:
	var root: Node2D = Node2D.new()
	get_root().add_child(root)
	var caster: Unit = _spawn_unit(root, WARRIOR_DATA, 1)
	var beetle: Unit = _spawn_unit(root, MIRROR_CARAPACE_BEETLE_DATA, 2)
	caster.hp = caster.max_hp
	beetle.shield = 100
	beetle.hp = beetle.max_hp
	beetle.battle_elapsed_time = 5.0
	var resolver: Variant = COMBAT_RESOLVER_SCRIPT.new()
	var old_caster_hp: int = caster.hp
	resolver.resolve_skill_damage(caster, beetle, 40)
	_expect_true(caster.hp < old_caster_hp, "Mirror Carapace should reflect active skill damage while shielded.")
	root.queue_free()


func _spawn_unit(root: Node, unit_data: Resource, team_id: int) -> Unit:
	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	unit.unit_data = unit_data
	unit.team_id = team_id
	unit.display_name = str(unit_data.get("unit_name"))
	root.add_child(unit)
	unit.is_battle_active = true
	unit.is_alive = true
	unit.enemy_units = []
	unit.ally_units = []
	unit.crit_chance = 0.0
	return unit


func _finish() -> void:
	if failures.is_empty():
		print("test_elite_enemies: PASS")
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
