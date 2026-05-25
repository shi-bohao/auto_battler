extends SceneTree

const BOND_MANAGER_SCRIPT: Script = preload("res://scripts/bond_manager.gd")
const HERO_MANAGER_SCRIPT: Script = preload("res://scripts/hero_manager.gd")
const STATUS_EFFECT_FACTORY_SCRIPT: Script = preload("res://scripts/combat/status_effect_factory.gd")
const UNIT_DATA_APPLIER_SCRIPT: Script = preload("res://scripts/unit_data_applier.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")

const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const TANK_DATA: Resource = preload("res://data/units/tank.tres")
const GUARDIAN_CAPTAIN_DATA: Resource = preload("res://data/units/guardian_captain.tres")
const GREATSWORD_KNIGHT_DATA: Resource = preload("res://data/units/greatsword_knight.tres")
const STARFORGED_VANGUARD_DATA: Resource = preload("res://data/units/starforged_vanguard.tres")
const ARCHER_DATA: Resource = preload("res://data/units/archer.tres")
const ASSASSIN_DATA: Resource = preload("res://data/units/assassin.tres")
const MAGE_DATA: Resource = preload("res://data/units/mage.tres")
const ALCHEMIST_DATA: Resource = preload("res://data/units/alchemist.tres")
const BOMB_THROWER_DATA: Resource = preload("res://data/units/bomb_thrower.tres")
const ARCANE_ARTILLERIST_DATA: Resource = preload("res://data/units/arcane_artillerist.tres")
const PRISM_WEAVER_DATA: Resource = preload("res://data/units/prism_weaver.tres")
const WIND_CHANTER_DATA: Resource = preload("res://data/units/wind_chanter.tres")
const PRIEST_DATA: Resource = preload("res://data/units/priest.tres")
const CLERIC_DATA: Resource = preload("res://data/units/cleric.tres")
const FOREST_DRUID_DATA: Resource = preload("res://data/units/forest_druid.tres")
const BARD_DATA: Resource = preload("res://data/units/bard.tres")
const DAWNBELL_SAINT_DATA: Resource = preload("res://data/units/dawnbell_saint.tres")
const NECROMANCER_DATA: Resource = preload("res://data/units/necromancer.tres")
const PUPPET_WARLOCK_DATA: Resource = preload("res://data/units/puppet_warlock.tres")
const SOUL_BINDER_DATA: Resource = preload("res://data/units/soul_binder.tres")
const PLAGUE_CASTER_DATA: Resource = preload("res://data/units/plague_caster.tres")
const VENOM_MATRIARCH_DATA: Resource = preload("res://data/units/venom_matriarch.tres")
const SKELETON_DATA: Resource = preload("res://data/summons/skeleton.tres")
const IRON_OATH_COMMANDER_DATA: Resource = preload("res://data/heroes/iron_oath_commander_unit.tres")

class BattleRootProxy:
	extends Node2D

	var bond_manager: Variant = null

	func modify_status_effect_data_for_bonds(effect_data: Dictionary) -> Dictionary:
		if bond_manager != null and bond_manager.has_method("modify_status_effect_data"):
			return bond_manager.modify_status_effect_data(effect_data)
		return effect_data


var failures: Array[String] = []
var created_nodes: Array[Node] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	seed(11)
	_test_unit_data_carries_bond_tags()
	_test_roster_counting_ignores_bench_duplicates_and_counts_hero()
	_test_iron_wall_and_hunter_member_only_bonuses()
	_test_arcane_and_divine_battle_start_bonuses()
	_test_summon_bond_applies_to_new_summons_and_death_event()
	_test_venom_bond_damage_and_extra_stack_cooldown()
	_cleanup()
	_finish()


func _test_unit_data_carries_bond_tags() -> void:
	_expect_true(_get_resource_tags(WARRIOR_DATA).has("iron_wall"), "Warrior should have iron_wall tag.")
	_expect_true(_get_resource_tags(BOMB_THROWER_DATA).has("hunter"), "Bomb Thrower should have hunter tag.")
	_expect_true(_get_resource_tags(BOMB_THROWER_DATA).has("arcane"), "Bomb Thrower should have arcane tag.")
	_expect_true(_get_resource_tags(ALCHEMIST_DATA).has("venom"), "Alchemist should have venom tag.")

	var unit: Unit = _create_unit(WARRIOR_DATA)
	_expect_true(unit.bond_tags.has("iron_wall"), "UnitDataApplier should copy bond_tags to Unit.")


func _test_roster_counting_ignores_bench_duplicates_and_counts_hero() -> void:
	var bond_manager: Variant = BOND_MANAGER_SCRIPT.new()
	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	hero_manager.select_hero("bloodshadow_hunter")
	var active_roster: Array[Dictionary] = [
		_create_roster_item(ARCHER_DATA),
		_create_roster_item(ARCHER_DATA),
		_create_roster_item(ASSASSIN_DATA),
	]
	bond_manager.calculate_from_roster(active_roster, hero_manager)

	_expect_int(bond_manager.get_count("hunter"), 3, "Hunter count should de-duplicate unit_type and include selected hero.")
	_expect_int(bond_manager.get_active_tier("hunter"), 2, "Three unique hunters should activate tier 2.")
	_expect_int(bond_manager.get_count("arcane"), 0, "Bench units should not be included when not passed as active_roster.")


func _test_iron_wall_and_hunter_member_only_bonuses() -> void:
	var bond_manager: Variant = BOND_MANAGER_SCRIPT.new()
	var units: Array[Unit] = [
		_create_unit(WARRIOR_DATA),
		_create_unit(TANK_DATA),
		_create_unit(GUARDIAN_CAPTAIN_DATA),
		_create_unit(GREATSWORD_KNIGHT_DATA),
		_create_unit(STARFORGED_VANGUARD_DATA),
		_create_unit(ARCHER_DATA),
	]
	var archer_defense_before: int = units[5].defense
	bond_manager.apply_battle_start_bonds(units)
	_expect_int(bond_manager.get_active_tier("iron_wall"), 4, "Five unique iron_wall members should activate tier 4.")
	_expect_int(units[0].defense, int(WARRIOR_DATA.get("defense")) + 20, "Iron Wall 4 should add defense to iron_wall members.")
	_expect_int(units[0].shield, 30, "Iron Wall 4 should add shield to iron_wall members.")
	_expect_int(units[5].defense, archer_defense_before, "Iron Wall should not affect non-members.")

	var hunter_manager: Variant = BOND_MANAGER_SCRIPT.new()
	var hunter_units: Array[Unit] = [
		_create_unit(ARCHER_DATA),
		_create_unit(ASSASSIN_DATA),
		_create_unit(GREATSWORD_KNIGHT_DATA),
		_create_unit(BOMB_THROWER_DATA),
		_create_unit(MAGE_DATA),
	]
	var mage_crit_before: float = hunter_units[4].crit_chance
	hunter_manager.apply_battle_start_bonds(hunter_units)
	_expect_int(hunter_manager.get_active_tier("hunter"), 4, "Four hunters should activate tier 4.")
	_expect_float(hunter_units[0].crit_chance, float(ARCHER_DATA.get("crit_chance")) + 0.15, "Hunter 4 should add crit chance to hunters.")
	_expect_float(hunter_units[0].crit_damage_multiplier, float(ARCHER_DATA.get("crit_damage_multiplier")) + 0.25, "Hunter 4 should add crit damage to hunters.")
	_expect_float(hunter_units[4].crit_chance, mage_crit_before, "Hunter should not affect non-members.")

	var iron_wall_6_manager: Variant = BOND_MANAGER_SCRIPT.new()
	var iron_wall_6_units: Array[Unit] = [
		_create_unit(WARRIOR_DATA),
		_create_unit(TANK_DATA),
		_create_unit(GUARDIAN_CAPTAIN_DATA),
		_create_unit(GREATSWORD_KNIGHT_DATA),
		_create_unit(STARFORGED_VANGUARD_DATA),
		_create_unit(IRON_OATH_COMMANDER_DATA),
	]
	iron_wall_6_manager.apply_battle_start_bonds(iron_wall_6_units)
	_expect_int(iron_wall_6_manager.get_active_tier("iron_wall"), 6, "Six iron_wall members should activate tier 6.")
	_expect_int(iron_wall_6_units[0].defense, int(WARRIOR_DATA.get("defense")) + 35, "Iron Wall 6 should add the tier 6 defense bonus.")
	_expect_int(iron_wall_6_units[0].shield, 60, "Iron Wall 6 should add the tier 6 shield bonus.")
	_expect_float(iron_wall_6_units[0].damage_reduction, 0.15, "Iron Wall 6 should add damage reduction to members.")


func _test_arcane_and_divine_battle_start_bonuses() -> void:
	var arcane_manager: Variant = BOND_MANAGER_SCRIPT.new()
	var arcane_units: Array[Unit] = [
		_create_unit(MAGE_DATA),
		_create_unit(ALCHEMIST_DATA),
		_create_unit(BOMB_THROWER_DATA),
		_create_unit(ARCANE_ARTILLERIST_DATA),
		_create_unit(PRISM_WEAVER_DATA),
		_create_unit(WIND_CHANTER_DATA),
		_create_unit(WARRIOR_DATA),
	]
	for unit: Unit in arcane_units:
		unit.max_mana = 100
		unit.current_mana = 0.0
	arcane_manager.apply_battle_start_bonds(arcane_units)
	_expect_int(arcane_manager.get_active_tier("arcane"), 6, "Six arcane members should activate tier 6.")
	_expect_float(arcane_units[6].skill_power, 0.28, "Arcane 6 should add skill power to all player units.")
	_expect_float(arcane_units[0].mana_regen_per_second, float(MAGE_DATA.get("mana_regen_per_second")) * 1.25, "Arcane 6 should increase arcane member mana regen.")
	_expect_float(arcane_units[0].current_mana, 30.0, "Arcane 6 should grant initial mana to arcane members.")
	_expect_float(arcane_units[6].current_mana, 0.0, "Arcane 6 initial mana should not affect non-members.")

	var divine_manager: Variant = BOND_MANAGER_SCRIPT.new()
	var divine_units: Array[Unit] = [
		_create_unit(PRIEST_DATA),
		_create_unit(CLERIC_DATA),
		_create_unit(FOREST_DRUID_DATA),
		_create_unit(BARD_DATA),
		_create_unit(WARRIOR_DATA),
	]
	divine_manager.apply_battle_start_bonds(divine_units)
	_expect_int(divine_manager.get_active_tier("divine"), 4, "Four divine members should activate tier 4.")
	_expect_float(divine_units[4].healing_power, 0.25, "Divine 4 should add healing power to all player units.")
	_expect_float(divine_units[4].shield_power, 0.15, "Divine 4 should add shield power to all player units.")

	var divine_6_manager: Variant = BOND_MANAGER_SCRIPT.new()
	var extra_divine: Unit = _create_unit(WARRIOR_DATA)
	extra_divine.unit_type = "test_divine_sixth"
	extra_divine.bond_tags = ["divine"]
	var divine_6_non_member: Unit = _create_unit(WARRIOR_DATA)
	var divine_6_non_member_shield_before: int = divine_6_non_member.shield
	var divine_6_units: Array[Unit] = [
		_create_unit(PRIEST_DATA),
		_create_unit(CLERIC_DATA),
		_create_unit(FOREST_DRUID_DATA),
		_create_unit(BARD_DATA),
		_create_unit(DAWNBELL_SAINT_DATA),
		extra_divine,
		divine_6_non_member,
	]
	divine_6_manager.apply_battle_start_bonds(divine_6_units)
	_expect_int(divine_6_manager.get_active_tier("divine"), 6, "Six divine members should activate tier 6 when enough tagged units exist.")
	_expect_float(divine_6_units[6].healing_power, 0.35, "Divine 6 should add healing power to all player units.")
	_expect_float(divine_6_units[6].shield_power, 0.25, "Divine 6 should add shield power to all player units.")
	_expect_int(divine_6_units[6].shield, divine_6_non_member_shield_before + 25, "Divine 6 should add battle start shield to all player units.")


func _test_summon_bond_applies_to_new_summons_and_death_event() -> void:
	var summon_2_manager: Variant = BOND_MANAGER_SCRIPT.new()
	var summon_2_units: Array[Unit] = [
		_create_unit(NECROMANCER_DATA),
		_create_unit(PUPPET_WARLOCK_DATA),
	]
	summon_2_manager.apply_battle_start_bonds(summon_2_units)
	_expect_int(summon_2_manager.get_active_tier("summon"), 2, "Two summon members should activate tier 2.")
	var tier_2_skeleton: Unit = _create_unit(SKELETON_DATA)
	tier_2_skeleton.roster_area = "summon"
	tier_2_skeleton.set_meta("is_summon", true)
	summon_2_manager.apply_bonds_to_summoned_unit(tier_2_skeleton)
	_expect_int(tier_2_skeleton.attack_damage, int(round(float(SKELETON_DATA.get("attack_damage")) * 1.15)), "Summon 2 should increase new summon attack.")
	_expect_int(tier_2_skeleton.max_hp, int(round(float(SKELETON_DATA.get("max_hp")) * 1.15)), "Summon 2 should increase new summon max HP.")
	_expect_int(tier_2_skeleton.hp, tier_2_skeleton.max_hp, "Summon 2 should not raise current HP above max HP.")

	var bond_manager: Variant = BOND_MANAGER_SCRIPT.new()
	var player_units: Array[Unit] = [
		_create_unit(NECROMANCER_DATA),
		_create_unit(PUPPET_WARLOCK_DATA),
		_create_unit(SOUL_BINDER_DATA),
		_create_unit(WARRIOR_DATA),
	]
	player_units[3].max_mana = 100
	player_units[3].current_mana = 0.0
	bond_manager.apply_battle_start_bonds(player_units)
	_expect_int(bond_manager.get_active_tier("summon"), 3, "Three summon members should activate tier 3.")

	var skeleton: Unit = _create_unit(SKELETON_DATA)
	skeleton.roster_area = "summon"
	skeleton.set_meta("is_summon", true)
	bond_manager.apply_bonds_to_summoned_unit(skeleton)
	_expect_int(skeleton.attack_damage, int(round(float(SKELETON_DATA.get("attack_damage")) * 1.25)), "Summon 3 should increase new summon attack.")
	_expect_int(skeleton.max_hp, int(round(float(SKELETON_DATA.get("max_hp")) * 1.25)), "Summon 3 should increase new summon max HP.")
	_expect_int(skeleton.hp, skeleton.max_hp, "Summon 3 should not raise current HP above max HP.")

	skeleton.is_alive = false
	bond_manager.handle_unit_died(skeleton, player_units)
	var first_benefit_total: int = _get_total_non_summon_shield(player_units)
	var first_mana_total: float = _get_total_non_summon_mana(player_units)
	_expect_int(first_benefit_total, 30, "Summon 3 death event should grant shield to one non-summon ally.")
	_expect_float(first_mana_total, 20.0, "Summon 3 death event should restore mana to one non-summon ally.")
	bond_manager.handle_unit_died(skeleton, player_units)
	_expect_int(_get_total_non_summon_shield(player_units), 30, "Each summon death should trigger at most once.")


func _test_venom_bond_damage_and_extra_stack_cooldown() -> void:
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	created_nodes.append(battle_root)
	get_root().add_child(battle_root)

	var bond_manager: Variant = BOND_MANAGER_SCRIPT.new()
	battle_root.bond_manager = bond_manager
	var player_units: Array[Unit] = [
		_create_unit(PLAGUE_CASTER_DATA, battle_root),
		_create_unit(ALCHEMIST_DATA, battle_root),
		_create_unit(VENOM_MATRIARCH_DATA, battle_root),
	]
	bond_manager.apply_battle_start_bonds(player_units)
	_expect_int(bond_manager.get_active_tier("venom"), 3, "Three venom members should activate tier 3.")

	var target: Unit = _create_unit(WARRIOR_DATA, battle_root, 2)
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var venom_options: Dictionary = {
		"stack_policy": "STACK_INDEPENDENT_DURATION",
		"polarity": "NEGATIVE",
		"category": "DOT",
	}
	factory.apply_status_effect(target, "venom_stack", "DAMAGE_OVER_TIME", player_units[0], 6.0, 1.0, 5.0, "", venom_options)
	_expect_int(target.get_status_effect_count("venom_stack"), 2, "Venom 3 should add one extra stack on first application.")
	_expect_float(target.effect_controller.effects[0].value, 13.0, "Venom 3 should add 8 damage to venom stacks.")

	factory.apply_status_effect(target, "venom_stack", "DAMAGE_OVER_TIME", player_units[0], 6.0, 1.0, 5.0, "", venom_options)
	_expect_int(target.get_status_effect_count("venom_stack"), 3, "Venom extra stack should respect the same-target cooldown.")


func _create_unit(unit_data: Resource, parent: Node = null, team_id: int = 1) -> Unit:
	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	created_nodes.append(unit)
	unit.team_id = team_id
	unit.unit_data = unit_data
	unit.roster_area = "active"
	var target_parent: Node = parent if parent != null else get_root()
	target_parent.add_child(unit)
	unit.is_alive = true
	unit.is_targetable = true
	return unit


func _create_roster_item(unit_data: Resource) -> Dictionary:
	return {
		"unit_data": unit_data,
		"unit_id": str(unit_data.get("unit_type")),
		"star": 1,
	}


func _get_resource_tags(unit_data: Resource) -> Array:
	var tags: Variant = unit_data.get("bond_tags")
	if tags is Array:
		return tags as Array
	return []


func _get_total_non_summon_shield(units: Array[Unit]) -> int:
	var total: int = 0
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and not bool(unit.get_meta("is_summon", false)):
			total += int(unit.shield)
	return total


func _get_total_non_summon_mana(units: Array[Unit]) -> float:
	var total: float = 0.0
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and not bool(unit.get_meta("is_summon", false)):
			total += float(unit.current_mana)
	return total


func _cleanup() -> void:
	for index: int in range(created_nodes.size() - 1, -1, -1):
		var node: Node = created_nodes[index]
		if node != null and is_instance_valid(node):
			node.queue_free()
	created_nodes.clear()


func _finish() -> void:
	if failures.is_empty():
		print("Bond manager tests passed.")
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


func _expect_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
