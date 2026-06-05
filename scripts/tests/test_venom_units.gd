extends SceneTree

const BATTLE_MANAGER_SCRIPT: Script = preload("res://scripts/battle_manager.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const PLAGUE_CASTER_DATA: Resource = preload("res://data/units/plague_caster.tres")
const ALCHEMIST_DATA: Resource = preload("res://data/units/alchemist.tres")
const VINE_BINDER_DATA: Resource = preload("res://data/units/vine_binder.tres")

class BattleRootProxy:
	extends Node2D

	var battle_manager: Variant = null

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
	_test_plague_caster_passive_applies_venom()
	_test_plague_caster_active_spreads_venom()
	_test_alchemist_passive_applies_aoe_venom()
	_test_alchemist_active_creates_status_field()
	_test_vine_binder_active_applies_venom()
	_finish()


# ── Plague Caster ───────────────────────────────────────────

func _test_plague_caster_passive_applies_venom() -> void:
	var root: BattleRootProxy = _create_battle_root()
	var bm: Variant = _create_battle_manager(root)
	root.battle_manager = bm

	var player: Unit = _spawn_unit(root, PLAGUE_CASTER_DATA, 1, Vector2(120.0, 240.0), 1)
	var enemy: Unit = _spawn_unit(root, WARRIOR_DATA, 2, Vector2(300.0, 240.0), 2)
	player.ally_units = [player]
	player.enemy_units = [enemy]
	enemy.ally_units = [enemy]
	enemy.enemy_units = [player]

	var passive_resolver: Variant = preload("res://scripts/combat/passive_resolver.gd").new()
	passive_resolver.apply_battle_start_passives(player)
	passive_resolver.apply_attack_landed_passives(player, enemy)

	_expect_int(enemy.get_status_effect_count("venom_stack"), 2, "Plague caster normal star should apply 2 venom stacks on attack landed.")

	var root2: BattleRootProxy = _create_battle_root()
	var bm2: Variant = _create_battle_manager(root2)
	root2.battle_manager = bm2
	var player2: Unit = _spawn_unit(root2, PLAGUE_CASTER_DATA, 1, Vector2(120.0, 240.0), 10)
	var enemy2: Unit = _spawn_unit(root2, WARRIOR_DATA, 2, Vector2(300.0, 240.0), 20)
	player2.ally_units = [player2]
	player2.enemy_units = [enemy2]
	enemy2.ally_units = [enemy2]
	enemy2.enemy_units = [player2]
	player2.star = 3

	passive_resolver.apply_battle_start_passives(player2)
	passive_resolver.apply_attack_landed_passives(player2, enemy2)
	_expect_int(enemy2.get_status_effect_count("venom_stack"), 3, "Plague caster 3-star should apply 3 venom stacks on attack landed.")

	root2.queue_free()


func _test_plague_caster_active_spreads_venom() -> void:
	var root: BattleRootProxy = _create_battle_root()
	var bm: Variant = _create_battle_manager(root)
	root.battle_manager = bm

	var player: Unit = _spawn_unit(root, PLAGUE_CASTER_DATA, 1, Vector2(120.0, 240.0), 1)
	var target: Unit = _spawn_unit(root, WARRIOR_DATA, 2, Vector2(760.0, 240.0), 2)
	var nearby: Unit = _spawn_unit(root, WARRIOR_DATA, 2, Vector2(760.0, 336.0), 3)
	player.ally_units = [player]
	player.enemy_units = [target, nearby]
	target.ally_units = [target, nearby]
	target.enemy_units = [player]
	nearby.ally_units = [target, nearby]
	nearby.enemy_units = [player]
	player.current_target = target

	var caster: Variant = preload("res://scripts/combat/active_skill_caster.gd").new()
	caster.setup(null)

	var result_no_venom: bool = caster.try_cast_active_skill(player)
	_expect_bool(result_no_venom, false, "Toxic cloud should return false when target has no venom stacks.")

	var effect_factory: Variant = preload("res://scripts/combat/status_effect_factory.gd").new()
	effect_factory.apply_status_effect(
		target, "venom_stack", preload("res://scripts/combat/status_effect_factory.gd").EFFECT_TYPE_DAMAGE_OVER_TIME,
		player, 6.0, 1.0, 5.0, "", {
			"stack_policy": preload("res://scripts/combat/status_effect_factory.gd").STACK_POLICY_REFRESH_ONLY,
			"polarity": preload("res://scripts/combat/status_effect_factory.gd").POLARITY_NEGATIVE,
			"category": preload("res://scripts/combat/status_effect_factory.gd").CATEGORY_DOT,
			"stack_count": 8,
			"stack_decay_after_duration": true,
			"stack_decay_per_tick": 5,
		}
	)

	var result_with_venom: bool = caster.try_cast_active_skill(player)
	_expect_bool(result_with_venom, true, "Toxic cloud should return true when target has venom stacks.")

	_expect_int(nearby.get_status_effect_count("venom_stack"), 2, "Toxic cloud normal star should spread ceil(8 * 0.25) = 2 venom stacks to nearby enemy.")

	root.queue_free()


# ── Alchemist ────────────────────────────────────────────────

func _test_alchemist_passive_applies_aoe_venom() -> void:
	var root: BattleRootProxy = _create_battle_root()
	var bm: Variant = _create_battle_manager(root)
	root.battle_manager = bm

	var player: Unit = _spawn_unit(root, ALCHEMIST_DATA, 1, Vector2(120.0, 240.0), 1)
	var target: Unit = _spawn_unit(root, WARRIOR_DATA, 2, Vector2(300.0, 240.0), 2)
	var nearby: Unit = _spawn_unit(root, WARRIOR_DATA, 2, Vector2(340.0, 240.0), 3)
	var faraway: Unit = _spawn_unit(root, WARRIOR_DATA, 2, Vector2(600.0, 240.0), 4)
	player.ally_units = [player]
	player.enemy_units = [target, nearby, faraway]
	for e: Unit in [target, nearby, faraway]:
		e.ally_units = [target, nearby, faraway]
		e.enemy_units = [player]

	var passive_resolver: Variant = preload("res://scripts/combat/passive_resolver.gd").new()
	passive_resolver.apply_battle_start_passives(player)
	passive_resolver.apply_attack_landed_passives(player, target)

	_expect_int(target.get_status_effect_count("venom_stack"), 1, "Alchemist normal star should apply 1 venom stack to target.")
	_expect_int(nearby.get_status_effect_count("venom_stack"), 1, "Alchemist normal star should apply 1 venom stack to nearby enemy within radius.")
	_expect_int(faraway.get_status_effect_count("venom_stack"), 0, "Alchemist should NOT apply venom to faraway enemy outside radius.")

	root.queue_free()


func _test_alchemist_active_creates_status_field() -> void:
	var root: BattleRootProxy = _create_battle_root()
	var bm: Variant = _create_battle_manager(root)
	root.battle_manager = bm

	var player: Unit = _spawn_unit(root, ALCHEMIST_DATA, 1, Vector2(120.0, 240.0), 1)
	var target: Unit = _spawn_unit(root, WARRIOR_DATA, 2, Vector2(760.0, 240.0), 2)
	player.ally_units = [player]
	player.enemy_units = [target]
	target.ally_units = [target]
	target.enemy_units = [player]
	player.current_target = target

	var caster: Variant = preload("res://scripts/combat/active_skill_caster.gd").new()
	caster.setup(null)
	var result: bool = caster.try_cast_active_skill(player)
	_expect_bool(result, true, "Acid field should successfully create a status field.")

	root.queue_free()


# ── Vine Binder ──────────────────────────────────────────────

func _test_vine_binder_active_applies_venom() -> void:
	var root: BattleRootProxy = _create_battle_root()
	var bm: Variant = _create_battle_manager(root)
	root.battle_manager = bm

	var player: Unit = _spawn_unit(root, VINE_BINDER_DATA, 1, Vector2(120.0, 240.0), 1)
	var target: Unit = _spawn_unit(root, WARRIOR_DATA, 2, Vector2(760.0, 240.0), 2)
	player.ally_units = [player]
	player.enemy_units = [target]
	target.ally_units = [target]
	target.enemy_units = [player]
	player.current_target = target

	var caster: Variant = preload("res://scripts/combat/active_skill_caster.gd").new()
	caster.setup(null)
	caster.try_cast_active_skill(player)
	_expect_int(target.get_status_effect_count("venom_stack"), 6, "Vine binder normal star should apply 6 venom stacks with active skill.")

	root.queue_free()

	var root2: BattleRootProxy = _create_battle_root()
	var bm2: Variant = _create_battle_manager(root2)
	root2.battle_manager = bm2
	var player2: Unit = _spawn_unit(root2, VINE_BINDER_DATA, 1, Vector2(120.0, 240.0), 10)
	var target2: Unit = _spawn_unit(root2, WARRIOR_DATA, 2, Vector2(760.0, 240.0), 20)
	player2.ally_units = [player2]
	player2.enemy_units = [target2]
	target2.ally_units = [target2]
	target2.enemy_units = [player2]
	player2.current_target = target2
	player2.star = 3

	caster.try_cast_active_skill(player2)
	_expect_int(target2.get_status_effect_count("venom_stack"), 10, "Vine binder 3-star should apply 10 venom stacks with active skill.")

	root2.queue_free()


# ── Helpers ──────────────────────────────────────────────────

func _create_battle_root() -> BattleRootProxy:
	var root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(root)
	return root


func _create_battle_manager(battle_root: Node) -> Variant:
	var bm: Variant = BATTLE_MANAGER_SCRIPT.new()
	bm.setup(battle_root, UNIT_SCENE, null, RelicManager.new())
	return bm


func _spawn_unit(parent: Node, unit_data: Resource, team_id: int, position: Vector2, roster_id: int) -> Unit:
	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	unit.unit_data = unit_data
	unit.team_id = team_id
	unit.position = position
	unit.star = 1
	unit.display_name = str(unit_data.get("unit_name")) + " " + str(roster_id)
	parent.add_child(unit)
	return unit


func _finish() -> void:
	if failures.is_empty():
		print("Venom unit tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
