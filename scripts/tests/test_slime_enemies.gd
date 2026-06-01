extends SceneTree

const BATTLE_MANAGER_SCRIPT: Script = preload("res://scripts/battle_manager.gd")
const COMBAT_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/combat_resolver.gd")
const ENEMY_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/enemy_catalog.gd")
const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const BATTLE_BOARD_SCRIPT: Script = preload("res://scripts/battle_board.gd")
const FIELD_EFFECT_MANAGER_SCRIPT: Script = preload("res://scripts/combat/field_effect_manager.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const COMMON_SLIME_DATA: Resource = preload("res://data/enemies/common_slime.tres")
const FROST_SLIME_DATA: Resource = preload("res://data/enemies/frost_slime.tres")
const FLAME_SLIME_DATA: Resource = preload("res://data/enemies/flame_slime.tres")
const VENOM_SLIME_DATA: Resource = preload("res://data/enemies/venom_slime.tres")
const GIANT_SLIME_DATA: Resource = preload("res://data/enemies/giant_slime.tres")

class BattleRootProxy:
	extends Node2D

	var battle_manager: Variant = null

	func summon_units(source_unit: Unit, summon_unit_data: Resource, count: int, context: Dictionary = {}) -> Array[Unit]:
		if battle_manager == null or not battle_manager.has_method("summon_units"):
			var empty_units: Array[Unit] = []
			return empty_units
		return battle_manager.summon_units(source_unit, summon_unit_data, count, context)

	func create_visual_field(center_position: Vector2, radius: float, duration: float, color: Color) -> int:
		if battle_manager != null and battle_manager.has_method("create_visual_field"):
			return int(battle_manager.create_visual_field(center_position, radius, duration, color))
		return 1

	func create_status_field(
		source_unit: Variant,
		center_position: Vector2,
		radius: float,
		duration: float,
		tick_interval: float,
		status_data: Dictionary,
		color: Color
	) -> int:
		if battle_manager != null and battle_manager.has_method("create_status_field"):
			return int(battle_manager.create_status_field(source_unit, center_position, radius, duration, tick_interval, status_data, color))
		return 1


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_enemy_catalog_and_skill_text()
	_test_slime_enemy_positions_are_frontline()
	_test_slime_body_reduces_basic_attack_damage()
	_test_slime_active_skills_apply_statuses()
	_test_death_status_field_outlives_source_unit()
	_test_slime_death_field_survives_real_death_flow()
	_test_giant_slime_split_chain_metadata()
	_finish()


func _test_enemy_catalog_and_skill_text() -> void:
	var catalog: Variant = ENEMY_CATALOG_SCRIPT.new()
	var formatter: Variant = UNIT_TEXT_FORMATTER_SCRIPT.new()
	var specs: Array[Dictionary] = [
		{"id": "enemy_common_slime", "data": COMMON_SLIME_DATA, "passive": "slime_body", "active": "slime_bounce"},
		{"id": "enemy_frost_slime", "data": FROST_SLIME_DATA, "passive": "frost_burst", "active": "frost_explosion"},
		{"id": "enemy_flame_slime", "data": FLAME_SLIME_DATA, "passive": "flame_burst", "active": "fire_splash"},
		{"id": "enemy_venom_slime", "data": VENOM_SLIME_DATA, "passive": "venom_pool", "active": "toxic_blob"},
		{"id": "enemy_giant_slime", "data": GIANT_SLIME_DATA, "passive": "slime_split", "active": "heavy_bounce"},
	]

	for spec: Dictionary in specs:
		var unit_id: String = str(spec["id"])
		var unit_data: Resource = catalog.get_unit_data_by_id(unit_id)
		_expect_true(unit_data != null, unit_id + " should load from EnemyCatalog.")
		if unit_data == null:
			continue

		_expect_string(str(unit_data.get("passive_id")), str(spec["passive"]), unit_id + " passive id should match.")
		_expect_string(str(unit_data.get("active_skill_id")), str(spec["active"]), unit_id + " active id should match.")
		_expect_string(str(unit_data.get("basic_attack_type")), "melee", unit_id + " should use melee basic attacks.")
		_expect_true(formatter.get_passive_skill_text(str(spec["passive"]), 3).find("Unknown") < 0, unit_id + " passive text should be defined.")
		_expect_true(formatter.get_active_skill_text(str(spec["active"]), 3).find("Unknown") < 0, unit_id + " active text should be defined.")


func _test_slime_enemy_positions_are_frontline() -> void:
	var battle_board: BattleBoard = BATTLE_BOARD_SCRIPT.new() as BattleBoard
	var slime_ids: Array[String] = [
		"enemy_common_slime",
		"enemy_frost_slime",
		"enemy_flame_slime",
		"enemy_venom_slime",
		"enemy_giant_slime",
	]
	for slime_id: String in slime_ids:
		var cell: Vector2i = battle_board.choose_enemy_cell_for_unit(slime_id, "damage", [], false)
		_expect_int(cell.x, BattleBoard.ENEMY_MIN_COL, slime_id + " should prefer the enemy frontline column.")

	var fallback_cell: Vector2i = battle_board.choose_enemy_cell_for_unit("enemy_frost_slime", "support", [
		Vector2i(BattleBoard.ENEMY_MIN_COL, 3),
		Vector2i(BattleBoard.ENEMY_MIN_COL, 2),
		Vector2i(BattleBoard.ENEMY_MIN_COL, 4),
		Vector2i(BattleBoard.ENEMY_MIN_COL + 1, 3),
		Vector2i(BattleBoard.ENEMY_MIN_COL + 1, 2),
		Vector2i(BattleBoard.ENEMY_MIN_COL + 1, 4),
	], false)
	_expect_int(fallback_cell.x, BattleBoard.ENEMY_MIN_COL, "Slime fallback should stay in enemy melee columns before using role defaults.")
	battle_board.free()


func _test_slime_body_reduces_basic_attack_damage() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager
	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(COMMON_SLIME_DATA, Vector2(760.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var attacker: Unit = battle_manager.get_left_units()[0]
	var slime: Unit = battle_manager.get_right_units()[0]
	attacker.attack_damage = 100
	attacker.crit_chance = 0.0
	slime.defense = 0
	slime.damage_taken_multiplier = 1.0
	slime.hp = slime.max_hp

	var combat_resolver: Variant = COMBAT_RESOLVER_SCRIPT.new()
	var actual_damage: int = combat_resolver.resolve_basic_attack_hit(attacker, slime)
	_expect_int(actual_damage, 92, "Common Slime should reduce basic attack damage by 8%.")

	slime.hp = slime.max_hp
	slime.star = 3
	actual_damage = combat_resolver.resolve_basic_attack_hit(attacker, slime)
	_expect_int(actual_damage, 85, "Star 3 Common Slime should reduce basic attack damage by 15%.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_slime_active_skills_apply_statuses() -> void:
	_expect_control_status(FROST_SLIME_DATA, "frost_explosion", "is_slowed", "Frost Slime active should apply slow.")
	_expect_status_effect(FLAME_SLIME_DATA, "fire_splash", "burning", "Flame Slime active should apply burning.")
	_expect_status_effect(VENOM_SLIME_DATA, "toxic_blob", "venom_stack", "Venom Slime active should apply venom stacks.")


func _expect_control_status(enemy_data: Resource, active_skill_id: String, control_flag: String, message: String) -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager
	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(enemy_data, Vector2(760.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var target: Unit = battle_manager.get_left_units()[0]
	var caster: Unit = battle_manager.get_right_units()[0]
	caster.active_skill_id = active_skill_id
	caster.current_target = target
	target.defense = 0
	target.passive_id = ""
	caster.unit_skill.try_cast_active_skill(caster)
	_expect_true(target.control_state != null and bool(target.control_state.get(control_flag)), message)

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _expect_status_effect(enemy_data: Resource, active_skill_id: String, effect_id: String, message: String) -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager
	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(enemy_data, Vector2(760.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var target: Unit = battle_manager.get_left_units()[0]
	var caster: Unit = battle_manager.get_right_units()[0]
	caster.active_skill_id = active_skill_id
	caster.current_target = target
	target.defense = 0
	target.passive_id = ""
	caster.unit_skill.try_cast_active_skill(caster)
	_expect_true(target.get_status_effect_count(effect_id) > 0, message)

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_death_status_field_outlives_source_unit() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var field_manager: Variant = FIELD_EFFECT_MANAGER_SCRIPT.new()
	field_manager.setup(battle_root)

	var source: Unit = UNIT_SCENE.instantiate() as Unit
	source.team_id = 2
	source.unit_data = FROST_SLIME_DATA
	battle_root.add_child(source)

	var target: Unit = UNIT_SCENE.instantiate() as Unit
	target.team_id = 1
	target.unit_data = WARRIOR_DATA
	target.position = Vector2(20.0, 0.0)
	battle_root.add_child(target)

	field_manager.create_visual_field(Vector2.ZERO, 100.0, 0.35, Color(0.3, 0.7, 1.0, 0.3))
	field_manager.create_status_field(source, Vector2.ZERO, 100.0, 3.0, 1.0, {
		"mode": "control",
		"control_type": "SLOW",
		"duration": 2.0,
		"options": {
			"effect_id": "test_death_field_slow",
			"move_speed_multiplier": 0.8,
			"source_key": "test_death_field",
		},
	}, Color(0.3, 0.7, 1.0, 0.3))

	source.free()
	field_manager.update_fields(0.4)
	_expect_int(field_manager.fields.size(), 1, "Death status field should remain after the instant death AoE visual expires.")
	if field_manager.fields.size() == 1:
		var remaining_visual: Node = field_manager.fields[0].get("visual_node", null) as Node
		_expect_true(remaining_visual != null and is_instance_valid(remaining_visual), "Death status field visual should remain after the instant death AoE visual expires.")
		_expect_string(str(remaining_visual.get("visual_mode")), "persistent", "Death status field should use the persistent field visual mode.")
	field_manager.update_fields(0.1)
	_expect_true(target.control_state != null and bool(target.control_state.is_slowed), "Death status field should still apply after its source unit is freed.")

	field_manager.clear_all_fields()
	battle_root.queue_free()


func _test_slime_death_field_survives_real_death_flow() -> void:
	_expect_death_field_survives_real_flow(FROST_SLIME_DATA, "enemy_frost_slime", "slow")
	_expect_death_field_survives_real_flow(FLAME_SLIME_DATA, "enemy_flame_slime", "burning")
	_expect_death_field_survives_real_flow(VENOM_SLIME_DATA, "enemy_venom_slime", "venom_stack")


func _expect_death_field_survives_real_flow(enemy_data: Resource, enemy_unit_type: String, expected_status: String) -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager
	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [
		_create_config(enemy_data, Vector2(160.0, 240.0), 101),
		_create_config(COMMON_SLIME_DATA, Vector2(720.0, 240.0), 102),
	]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var attacker: Unit = battle_manager.get_left_units()[0]
	var slime: Unit = _find_unit_by_type(battle_manager.get_right_units(), enemy_unit_type)
	_expect_true(slime != null, "Real death flow should spawn " + enemy_unit_type + ".")
	if slime == null:
		battle_manager.clear_battlefield()
		battle_root.queue_free()
		return

	slime.take_damage(99999, attacker, false)
	_expect_true(battle_manager.is_battle_active, "Battle should continue while another enemy remains alive.")
	_expect_true(battle_manager.field_effect_manager.fields.size() >= 2, enemy_unit_type + " death should create an instant burst visual and a persistent status field.")

	battle_manager.update(0.4)
	var has_status_field: bool = false
	var has_persistent_visual: bool = false
	for field: Dictionary in battle_manager.field_effect_manager.fields:
		if str(field.get("field_type", "")) != "STATUS":
			continue
		has_status_field = true
		var visual: Node = field.get("visual_node", null) as Node
		if visual != null and is_instance_valid(visual) and str(visual.get("visual_mode")) == "persistent":
			has_persistent_visual = true

	_expect_true(has_status_field, enemy_unit_type + " persistent status field should remain after the death burst visual expires.")
	_expect_true(has_persistent_visual, enemy_unit_type + " persistent status field visual should remain after the source death tween starts.")
	match expected_status:
		"slow":
			_expect_true(attacker.control_state != null and bool(attacker.control_state.is_slowed), enemy_unit_type + " persistent field should still apply slow after the source unit dies.")
		"burning", "venom_stack":
			_expect_true(attacker.get_status_effect_count(expected_status) > 0, enemy_unit_type + " persistent field should still apply " + expected_status + " after the source unit dies.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_giant_slime_split_chain_metadata() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager
	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(GIANT_SLIME_DATA, Vector2(760.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var attacker: Unit = battle_manager.get_left_units()[0]
	var giant: Unit = battle_manager.get_right_units()[0]
	giant.take_damage(99999, attacker, false)
	var split_units: Array[Unit] = _get_units_by_type(battle_manager.get_right_units(), "enemy_giant_slime")
	_expect_int(split_units.size(), 2, "Giant Slime should split into two child slimes.")
	if split_units.size() >= 2:
		_expect_int(split_units[0].max_hp, 186, "Giant Slime child should inherit 30% max HP.")
		_expect_int(split_units[0].attack_damage, 12, "Giant Slime child attack should be halved.")
		_expect_int(split_units[0].defense, 12, "Giant Slime child defense should be halved.")
		_expect_int(int(split_units[0].get_meta("slime_split_count", 0)), 1, "Giant Slime child should record split generation.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _create_battle_root() -> BattleRootProxy:
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(battle_root)
	return battle_root


func _create_battle_manager(battle_root: Node) -> Variant:
	var battle_manager: Variant = BATTLE_MANAGER_SCRIPT.new()
	battle_manager.setup(battle_root, UNIT_SCENE, null, RelicManager.new())
	return battle_manager


func _create_config(unit_data: Resource, position: Vector2, roster_id: int) -> Dictionary:
	return {
		"unit_data": unit_data,
		"position": position,
		"display_name": str(unit_data.get("unit_name")) + " " + str(roster_id),
		"roster_id": roster_id,
	}


func _get_units_by_type(units: Array[Unit], unit_type: String) -> Array[Unit]:
	var matched: Array[Unit] = []
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and unit.is_alive and str(unit.unit_type) == unit_type:
			matched.append(unit)
	return matched


func _find_unit_by_type(units: Array[Unit], unit_type: String) -> Unit:
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and str(unit.unit_type) == unit_type:
			return unit
	return null


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + expected + ", got " + actual + ".")


func _finish() -> void:
	if failures.is_empty():
		print("test_slime_enemies: PASS")
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)
