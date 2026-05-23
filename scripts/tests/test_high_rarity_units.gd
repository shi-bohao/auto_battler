extends SceneTree

const ACTIVE_SKILL_CASTER_SCRIPT: Script = preload("res://scripts/combat/active_skill_caster.gd")
const PASSIVE_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/passive_resolver.gd")
const BATTLE_MANAGER_SCRIPT: Script = preload("res://scripts/battle_manager.gd")
const UNIT_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/unit_catalog.gd")
const UNIT_SCALING_SERVICE_SCRIPT: Script = preload("res://scripts/roster/unit_scaling_service.gd")
const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const ARCHER_DATA: Resource = preload("res://data/units/archer.tres")
const MAGE_DATA: Resource = preload("res://data/units/mage.tres")
const SOUL_BINDER_DATA: Resource = preload("res://data/units/soul_binder.tres")
const STARFORGED_VANGUARD_DATA: Resource = preload("res://data/units/starforged_vanguard.tres")
const ARCANE_ARTILLERIST_DATA: Resource = preload("res://data/units/arcane_artillerist.tres")
const VENOM_MATRIARCH_DATA: Resource = preload("res://data/units/venom_matriarch.tres")
const DAWNBELL_SAINT_DATA: Resource = preload("res://data/units/dawnbell_saint.tres")
const NIGHTBLADE_CAPTAIN_DATA: Resource = preload("res://data/units/nightblade_captain.tres")
const BLOODBOUND_BERSERKER_DATA: Resource = preload("res://data/units/bloodbound_berserker.tres")
const PRISM_WEAVER_DATA: Resource = preload("res://data/units/prism_weaver.tres")
const SOUL_PUPPET_DATA: Resource = preload("res://data/summons/soul_puppet.tres")

class BattleRootProxy:
	extends Node2D

	var battle_manager: Variant = null

	func summon_units(source_unit: Unit, summon_unit_data: Resource, count: int, context: Dictionary = {}) -> Array[Unit]:
		if battle_manager == null or not battle_manager.has_method("summon_units"):
			var empty_units: Array[Unit] = []
			return empty_units

		return battle_manager.summon_units(source_unit, summon_unit_data, count, context)

	func mark_puppet_summon_target(source_unit: Unit, target: Unit) -> bool:
		if battle_manager == null or battle_manager.summon_manager == null:
			return false

		return bool(battle_manager.summon_manager.mark_puppet_target(source_unit, target))

	func create_visual_field(_center_position: Vector2, _radius: float, _duration: float, _color: Color) -> int:
		return 1

	func create_damage_field(
		_source_unit: Variant,
		_center_position: Vector2,
		_radius: float,
		_duration: float,
		_tick_interval: float,
		_damage_per_tick: int
	) -> int:
		return 1

	func create_heal_field(
		_source_unit: Variant,
		_follow_unit: Variant,
		_center_position: Vector2,
		_radius: float,
		_duration: float,
		_tick_interval: float,
		_heal_tick_values: Array[int],
		_color: Color
	) -> int:
		return 1


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	seed(42)
	_test_catalog_loads_new_units_from_data_dir()
	_test_star_growth_defined_for_new_units()
	_test_starforged_and_dawnbell_passives()
	_test_soul_binding_summons_soul_puppet()
	_test_arcane_venom_bloodbound_and_prism_skills()
	_finish()


func _test_catalog_loads_new_units_from_data_dir() -> void:
	var catalog: Variant = UNIT_CATALOG_SCRIPT.new()
	catalog.setup(null, null, null)
	var formatter: Variant = UNIT_TEXT_FORMATTER_SCRIPT.new()
	var specs: Array[Dictionary] = [
		{"id": "soul_binder", "rarity": "EPIC", "price": 8, "passive": "soul_thread", "active": "binding_rite"},
		{"id": "starforged_vanguard", "rarity": "EPIC", "price": 8, "passive": "starforged_body", "active": "astral_bulwark"},
		{"id": "arcane_artillerist", "rarity": "EPIC", "price": 8, "passive": "overload_core", "active": "arcane_barrage"},
		{"id": "venom_matriarch", "rarity": "EPIC", "price": 8, "passive": "venom_brood", "active": "feast_of_venom"},
		{"id": "dawnbell_saint", "rarity": "LEGENDARY", "price": 10, "passive": "dawnbell_echo", "active": "bell_of_sanctuary"},
		{"id": "nightblade_captain", "rarity": "EPIC", "price": 8, "passive": "nightblade_order", "active": "reaping_command"},
		{"id": "bloodbound_berserker", "rarity": "RARE", "price": 6, "passive": "bloodbound_rage", "active": "blood_debt_slash"},
		{"id": "prism_weaver", "rarity": "RARE", "price": 6, "passive": "prism_refraction", "active": "focus_beam"},
	]

	_expect_min(catalog.get_unit_pool().size(), 25, "UnitCatalog should include data-dir units.")
	for spec: Dictionary in specs:
		var unit_data: Resource = catalog.get_unit_data_by_id(str(spec["id"]))
		_expect_true(unit_data != null, "Catalog should load " + str(spec["id"]) + ".")
		if unit_data == null:
			continue

		_expect_string(str(unit_data.get("rarity")), str(spec["rarity"]), str(spec["id"]) + " rarity should match design.")
		_expect_int(catalog.get_unit_price(unit_data), int(spec["price"]), str(spec["id"]) + " price should follow rarity.")
		_expect_string(str(unit_data.get("passive_id")), str(spec["passive"]), str(spec["id"]) + " passive id should match design.")
		_expect_string(str(unit_data.get("active_skill_id")), str(spec["active"]), str(spec["id"]) + " active id should match design.")
		_expect_true(formatter.get_passive_skill_text(str(spec["passive"]), 3).strip_edges() != "", str(spec["id"]) + " passive text should exist.")
		_expect_true(formatter.get_active_skill_text(str(spec["active"]), 3).strip_edges() != "", str(spec["id"]) + " active text should exist.")


func _test_star_growth_defined_for_new_units() -> void:
	var scaler: Variant = UNIT_SCALING_SERVICE_SCRIPT.new()
	var unit_datas: Array[Resource] = [
		SOUL_BINDER_DATA,
		STARFORGED_VANGUARD_DATA,
		ARCANE_ARTILLERIST_DATA,
		VENOM_MATRIARCH_DATA,
		DAWNBELL_SAINT_DATA,
		NIGHTBLADE_CAPTAIN_DATA,
		BLOODBOUND_BERSERKER_DATA,
		PRISM_WEAVER_DATA,
		SOUL_PUPPET_DATA,
	]

	for unit_data: Resource in unit_datas:
		var unit_id: String = str(unit_data.get("unit_type"))
		var scaled: Resource = scaler.create_scaled_unit_data({
			"unit_data": unit_data,
			"unit_id": unit_id,
			"display_name": unit_id,
			"star": 3,
		}, 1.0, 1.0)
		_expect_true(scaled != null, unit_id + " should scale to star 3.")
		if scaled == null:
			continue

		_expect_min(int(scaled.get("max_hp")), int(unit_data.get("max_hp")) + 1, unit_id + " star 3 HP should grow.")
		_expect_min(int(scaled.get("attack_damage")), int(unit_data.get("attack_damage")) + 1, unit_id + " star 3 attack should grow.")
		_expect_string(str(scaled.get("active_skill_id")), str(unit_data.get("active_skill_id")), unit_id + " scaling should preserve active skill.")


func _test_starforged_and_dawnbell_passives() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager
	var player_configs: Array[Dictionary] = [
		_create_config(STARFORGED_VANGUARD_DATA, Vector2(120.0, 220.0), 1),
		_create_config(WARRIOR_DATA, Vector2(150.0, 260.0), 2),
		_create_config(ARCHER_DATA, Vector2(170.0, 300.0), 3),
	]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 260.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)

	var vanguard: Unit = battle_manager.get_left_units()[0]
	var star_two: Unit = battle_manager.get_left_units()[1]
	var star_three: Unit = battle_manager.get_left_units()[2]
	star_two.star = 2
	star_three.star = 3
	battle_manager.start_battle()

	_expect_int(vanguard.defense, 69, "Starforged Vanguard should gain defense from allies and Iron Wall 2.")
	_expect_int(vanguard.shield, 25, "Starforged Vanguard should gain shield from a 3-star ally.")
	battle_manager.clear_battlefield()
	battle_root.queue_free()

	var dawn_root: BattleRootProxy = _create_battle_root()
	var dawn_battle: Variant = _create_battle_manager(dawn_root)
	dawn_root.battle_manager = dawn_battle
	var dawn_player_configs: Array[Dictionary] = [
		_create_config(DAWNBELL_SAINT_DATA, Vector2(120.0, 220.0), 1),
		_create_config(WARRIOR_DATA, Vector2(150.0, 260.0), 2),
	]
	var dawn_enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 260.0), 101)]
	dawn_battle.spawn_battle(dawn_player_configs, dawn_enemy_configs)
	dawn_battle.start_battle()

	var dawnbell: Unit = dawn_battle.get_left_units()[0]
	var ally: Unit = dawn_battle.get_left_units()[1]
	ally.heal(100, dawnbell)
	_expect_int(ally.shield, 70, "Dawnbell Saint should convert overheal into shield.")
	var enemy: Unit = dawn_battle.get_right_units()[0]
	ally.shield = 0
	ally.take_damage(9999, enemy, false)
	_expect_true(ally.is_alive, "Dawnbell Saint should prevent the first allied death.")
	_expect_int(ally.hp, int(round(float(ally.max_hp) * 0.5)), "Dawnbell redemption should restore 50 percent HP.")
	_expect_int(ally.shield, 100, "Dawnbell redemption should grant shield.")

	dawn_battle.clear_battlefield()
	dawn_root.queue_free()


func _test_soul_binding_summons_soul_puppet() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager
	var player_configs: Array[Dictionary] = [_create_config(SOUL_BINDER_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var binder: Unit = battle_manager.get_left_units()[0]
	var target: Unit = battle_manager.get_right_units()[0]
	binder.star = 3
	binder.current_target = target
	var cast_success: bool = binder.unit_skill.try_cast_active_skill(binder)
	_expect_true(cast_success, "Soul Binder should cast Binding Rite.")
	_expect_true(bool(target.get_meta("soul_binding_marked", false)), "Binding Rite should mark the target.")

	target.take_damage(9999, binder, false)
	var soul_puppet: Unit = _find_unit_type(battle_manager.get_left_units(), "summoned_soul_puppet")
	_expect_true(soul_puppet != null, "Marked target death should summon a soul puppet.")
	if soul_puppet != null:
		_expect_int(soul_puppet.star, 3, "Soul puppet should inherit summoner star.")
		_expect_min(soul_puppet.max_hp, int(SOUL_PUPPET_DATA.get("max_hp")) + int(WARRIOR_DATA.get("max_hp")), "Star 3 soul puppet should inherit target HP.")
		_expect_min(soul_puppet.attack_damage, int(SOUL_PUPPET_DATA.get("attack_damage")) + int(WARRIOR_DATA.get("attack_damage")), "Star 3 soul puppet should inherit target attack.")
		_expect_int(soul_puppet.shield, 50, "Star 3 soul puppet should gain initial shield.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_arcane_venom_bloodbound_and_prism_skills() -> void:
	var battle_root: BattleRootProxy = _create_battle_root()
	var battle_manager: Variant = _create_battle_manager(battle_root)
	battle_root.battle_manager = battle_manager
	var player_configs: Array[Dictionary] = [
		_create_config(ARCANE_ARTILLERIST_DATA, Vector2(120.0, 220.0), 1),
		_create_config(VENOM_MATRIARCH_DATA, Vector2(120.0, 260.0), 2),
		_create_config(BLOODBOUND_BERSERKER_DATA, Vector2(120.0, 300.0), 3),
		_create_config(PRISM_WEAVER_DATA, Vector2(120.0, 340.0), 4),
		_create_config(MAGE_DATA, Vector2(120.0, 380.0), 5),
	]
	var enemy_configs: Array[Dictionary] = [
		_create_config(WARRIOR_DATA, Vector2(780.0, 220.0), 101),
		_create_config(WARRIOR_DATA, Vector2(800.0, 260.0), 102),
	]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var arcane: Unit = battle_manager.get_left_units()[0]
	var venom: Unit = battle_manager.get_left_units()[1]
	var bloodbound: Unit = battle_manager.get_left_units()[2]
	var prism: Unit = battle_manager.get_left_units()[3]
	var mage: Unit = battle_manager.get_left_units()[4]
	var target: Unit = battle_manager.get_right_units()[0]
	arcane.current_target = target
	var arcane_success: bool = arcane.unit_skill.try_cast_active_skill(arcane)
	_expect_true(arcane_success, "Arcane Artillerist should cast Arcane Barrage.")
	_expect_min(int(round(arcane.current_mana)), 4, "Arcane Barrage should restore mana based on hit count.")

	venom.current_target = target
	var venom_success: bool = venom.unit_skill.try_cast_active_skill(venom)
	_expect_true(venom_success, "Venom Matriarch should cast Feast of Venom.")
	for enemy: Unit in battle_manager.get_right_units():
		if enemy != null and is_instance_valid(enemy) and enemy.is_alive:
			_expect_min(enemy.get_status_effect_count("venom_stack"), 1, "Feast of Venom should apply venom stacks to all enemies.")

	bloodbound.hp = int(round(float(bloodbound.max_hp) * 0.4))
	var boosted_damage: int = bloodbound.unit_skill.get_basic_attack_damage(bloodbound, target, bloodbound.attack_damage)
	_expect_min(boosted_damage, int(round(float(bloodbound.attack_damage) * 1.2)), "Bloodbound Rage should boost low-HP attack damage.")
	_expect_float(bloodbound.unit_skill.passive_resolver.get_bloodbound_rage_life_steal_bonus(bloodbound), 0.10, "Bloodbound Rage should add life steal at low HP.")

	mage.skill_power = 0.20
	mage.max_mana = 100
	mage.current_mana = 0.0
	prism.star = 3
	var focus_success: bool = prism.unit_skill.try_cast_active_skill(prism)
	_expect_true(focus_success, "Prism Weaver should cast Focus Beam.")
	_expect_true(mage.effect_controller.has_effect("focus_beam_skill_power"), "Focus Beam should buff the highest skill-power ally.")
	_expect_true(mage.effect_controller.has_effect("focus_beam_crit"), "Focus Beam should grant crit chance.")
	_expect_float(mage.current_mana, 25.0, "Star 3 Focus Beam should restore mana.")

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
		"display_name": "Test Unit " + str(roster_id),
		"roster_id": roster_id,
	}


func _find_unit_type(units: Array[Unit], unit_type: String) -> Unit:
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and unit.is_alive and unit.unit_type == unit_type:
			return unit

	return null


func _finish() -> void:
	if failures.is_empty():
		print("High rarity unit tests passed.")
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
		failures.append(message + " Expected " + expected + ", got " + actual + ".")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_min(actual: int, minimum: int, message: String) -> void:
	if actual < minimum:
		failures.append(message + " Expected at least " + str(minimum) + ", got " + str(actual) + ".")


func _expect_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
