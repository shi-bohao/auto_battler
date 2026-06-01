extends SceneTree

const BATTLE_MANAGER_SCRIPT: Script = preload("res://scripts/battle_manager.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const NECROMANCER_DATA: Resource = preload("res://data/units/necromancer.tres")
const PUPPET_WARLOCK_DATA: Resource = preload("res://data/units/puppet_warlock.tres")
const SKELETON_SUMMON_DATA: Resource = preload("res://data/summons/skeleton.tres")
const SKELETON_WARRIOR_SUMMON_DATA: Resource = preload("res://data/summons/skeleton_warrior.tres")
const SKELETON_ARCHER_SUMMON_DATA: Resource = preload("res://data/summons/skeleton_archer.tres")
const SKELETON_MAGE_SUMMON_DATA: Resource = preload("res://data/summons/skeleton_mage.tres")
const GRAVEBONE_CHARM: Resource = preload("res://data/relics/gravebone_charm.tres")
const BATTLE_BANNER: Resource = preload("res://data/relics/battle_banner.tres")

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


var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_unit_summon_cap_and_no_battle_start_buff()
	_test_necromancer_star_three_active_and_cap()
	_test_puppet_mark_summons_puppet_on_marked_target_death()
	_test_puppet_mark_prefers_unmarked_targets_and_applies_vulnerability()
	_test_gravebone_charm_summons_skeleton_without_recursive_trigger()
	_test_skeleton_variant_summons_and_skills()
	_test_stale_freed_unit_references_are_ignored()
	_finish()


func _test_unit_summon_cap_and_no_battle_start_buff() -> void:
	var relic_manager: RelicManager = RelicManager.new()
	relic_manager.add_relic(BATTLE_BANNER)
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(battle_root)
	var battle_manager: Variant = _create_battle_manager(battle_root, relic_manager)
	battle_root.battle_manager = battle_manager

	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var source: Unit = battle_manager.get_left_units()[0]
	source.star = 3
	var summoned_units: Array[Unit] = battle_manager.summon_units(source, SKELETON_SUMMON_DATA, 4, {})

	_expect_int(summoned_units.size(), 3, "Unit summons should respect the default active cap of 3.")
	_expect_int(_count_summons(battle_manager.get_left_units()), 3, "Three summoned skeletons should be active.")
	if not summoned_units.is_empty():
		_expect_int(summoned_units[0].attack_damage, 18, "Star 3 summons should receive summon star growth but not battle-start relic buffs.")
		_expect_int(summoned_units[0].max_hp, 150, "Star 3 summons should receive HP growth.")
		_expect_int(summoned_units[0].star, 3, "Summons should inherit the summoner star level.")
		_expect_string(summoned_units[0].passive_id, "summoned_bone_edge", "Skeleton summons should have a passive skill.")
		_expect_string(summoned_units[0].active_skill_id, "summoned_bone_slash", "Skeleton summons should have an active skill.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_necromancer_star_three_active_and_cap() -> void:
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(battle_root)
	var battle_manager: Variant = _create_battle_manager(battle_root, RelicManager.new())
	battle_root.battle_manager = battle_manager

	var player_configs: Array[Dictionary] = [_create_config(NECROMANCER_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var source: Unit = battle_manager.get_left_units()[0]
	source.star = 3
	source.unit_skill.try_cast_active_skill(source)
	_expect_int(_count_unit_type(battle_manager.get_left_units(), "summoned_skeleton"), 4, "Star 3 Necromancer active skill should summon 4 skeletons.")

	var extra_summons: Array[Unit] = battle_manager.summon_units(source, SKELETON_SUMMON_DATA, 10, {})
	_expect_int(extra_summons.size(), 4, "Star 3 Grave Command should raise the total unit summon cap to 8.")
	_expect_int(_count_unit_type(battle_manager.get_left_units(), "summoned_skeleton"), 8, "Star 3 Necromancer should keep up to 8 skeletons active.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_puppet_mark_summons_puppet_on_marked_target_death() -> void:
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(battle_root)
	var battle_manager: Variant = _create_battle_manager(battle_root, RelicManager.new())
	battle_root.battle_manager = battle_manager

	var player_configs: Array[Dictionary] = [_create_config(PUPPET_WARLOCK_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var source: Unit = battle_manager.get_left_units()[0]
	var target: Unit = battle_manager.get_right_units()[0]
	var marked: bool = battle_manager.summon_manager.mark_puppet_target(source, target)
	target.take_damage(9999, source, false)

	_expect_bool(marked, true, "Puppet Warlock should be able to mark a live enemy.")
	_expect_int(_count_unit_type(battle_manager.get_left_units(), "summoned_puppet"), 1, "Marked target death should summon one puppet.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_puppet_mark_prefers_unmarked_targets_and_applies_vulnerability() -> void:
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(battle_root)
	var battle_manager: Variant = _create_battle_manager(battle_root, RelicManager.new())
	battle_root.battle_manager = battle_manager

	var player_configs: Array[Dictionary] = [_create_config(PUPPET_WARLOCK_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [
		_create_config(WARRIOR_DATA, Vector2(760.0, 220.0), 101),
		_create_config(WARRIOR_DATA, Vector2(780.0, 300.0), 102),
	]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var source: Unit = battle_manager.get_left_units()[0]
	var marked_target: Unit = battle_manager.get_right_units()[0]
	var unmarked_target: Unit = battle_manager.get_right_units()[1]
	battle_manager.summon_manager.mark_puppet_target(source, marked_target)
	source.current_target = marked_target
	source.unit_skill.try_cast_active_skill(source)

	_expect_bool(bool(unmarked_target.get_meta("summon_puppet_marked", false)), true, "Puppet Mark should prefer an unmarked target over the current marked target.")
	_expect_float(unmarked_target.damage_taken_multiplier, 1.15, "Puppet Mark should apply vulnerability to the newly marked target.")
	unmarked_target.defense = 0
	unmarked_target.passive_id = ""
	var actual_damage: int = unmarked_target.take_damage(100, source, false)
	_expect_int(actual_damage, 115, "Vulnerability should increase incoming damage.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_gravebone_charm_summons_skeleton_without_recursive_trigger() -> void:
	var relic_manager: RelicManager = RelicManager.new()
	relic_manager.add_relic(GRAVEBONE_CHARM)
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(battle_root)
	var battle_manager: Variant = _create_battle_manager(battle_root, relic_manager)
	battle_root.battle_manager = battle_manager

	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var ally: Unit = battle_manager.get_left_units()[0]
	var enemy: Unit = battle_manager.get_right_units()[0]
	ally.take_damage(9999, enemy, false)
	_expect_int(_count_unit_type(battle_manager.get_left_units(), "summoned_skeleton"), 1, "Gravebone Charm should summon one skeleton when a non-summon ally dies.")

	var skeleton: Unit = _find_unit_type(battle_manager.get_left_units(), "summoned_skeleton")
	if skeleton != null:
		skeleton.take_damage(9999, enemy, false)
	_expect_int(_count_unit_type(battle_manager.get_left_units(), "summoned_skeleton"), 0, "Summoned skeleton death should not trigger Gravebone Charm again.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_skeleton_variant_summons_and_skills() -> void:
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(battle_root)
	var battle_manager: Variant = _create_battle_manager(battle_root, RelicManager.new())
	battle_root.battle_manager = battle_manager

	var player_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [
		_create_config(WARRIOR_DATA, Vector2(780.0, 220.0), 101),
		_create_config(WARRIOR_DATA, Vector2(790.0, 260.0), 102),
	]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var source: Unit = battle_manager.get_left_units()[0]
	source.star = 3
	var warriors: Array[Unit] = battle_manager.summon_units(source, SKELETON_WARRIOR_SUMMON_DATA, 1, {"source_key": "test_warrior"})
	var archers: Array[Unit] = battle_manager.summon_units(source, SKELETON_ARCHER_SUMMON_DATA, 1, {"source_key": "test_archer"})
	var mages: Array[Unit] = battle_manager.summon_units(source, SKELETON_MAGE_SUMMON_DATA, 1, {"source_key": "test_mage"})
	_expect_int(warriors.size(), 1, "Skeleton Warrior should be summonable.")
	_expect_int(archers.size(), 1, "Skeleton Archer should be summonable.")
	_expect_int(mages.size(), 1, "Skeleton Mage should be summonable.")
	if warriors.is_empty() or archers.is_empty() or mages.is_empty():
		battle_manager.clear_battlefield()
		battle_root.queue_free()
		return

	var warrior: Unit = warriors[0]
	var archer: Unit = archers[0]
	var mage: Unit = mages[0]
	_expect_string(warrior.unit_type, "summoned_skeleton_warrior", "Skeleton Warrior should use its own unit type.")
	_expect_string(warrior.basic_attack_type, "melee", "Skeleton Warrior should use melee basic attacks.")
	_expect_string(archer.unit_type, "summoned_skeleton_archer", "Skeleton Archer should use its own unit type.")
	_expect_string(archer.basic_attack_type, "projectile", "Skeleton Archer should use projectile basic attacks.")
	_expect_string(mage.unit_type, "summoned_skeleton_mage", "Skeleton Mage should use its own unit type.")
	_expect_string(mage.basic_attack_type, "projectile", "Skeleton Mage should use projectile basic attacks.")
	_expect_int(warrior.star, 3, "Skeleton Warrior should inherit summoner star.")
	_expect_int(archer.star, 3, "Skeleton Archer should inherit summoner star.")
	_expect_int(mage.star, 3, "Skeleton Mage should inherit summoner star.")

	var target: Unit = battle_manager.get_right_units()[0]
	target.defense = 0
	target.passive_id = ""
	target.hp = 1000
	warrior.crit_chance = 0.0
	warrior.current_target = target
	var hp_before_warrior: int = target.hp
	warrior.unit_skill.try_cast_active_skill(warrior)
	_expect_int(hp_before_warrior - target.hp, 38, "Star 3 Skeleton Warrior active should damage its current target.")
	_expect_int(warrior.shield, 66, "Star 3 Skeleton Warrior active should grant a self shield.")

	target.defense = 100
	target.passive_id = ""
	target.hp = 1000
	archer.crit_chance = 0.0
	archer.current_target = target
	var hp_before_arrow: int = target.hp
	archer.unit_skill.try_cast_active_skill(archer)
	var archer_damage: int = hp_before_arrow - target.hp
	_expect_int(archer_damage, 32, "Star 3 Skeleton Archer active should use its defense penetration.")

	var aoe_target_a: Unit = battle_manager.get_right_units()[0]
	var aoe_target_b: Unit = battle_manager.get_right_units()[1]
	aoe_target_a.defense = 0
	aoe_target_b.defense = 0
	aoe_target_a.passive_id = ""
	aoe_target_b.passive_id = ""
	aoe_target_a.hp = 1000
	aoe_target_b.hp = 1000
	mage.crit_chance = 0.0
	mage.current_target = aoe_target_a
	mage.current_mana = 20.0
	mage.unit_skill.try_cast_active_skill(mage)
	_expect_int(1000 - aoe_target_a.hp, 44, "Star 3 Skeleton Mage active should damage the primary target.")
	_expect_int(1000 - aoe_target_b.hp, 44, "Star 3 Skeleton Mage active should damage nearby enemies.")
	_expect_float(mage.current_mana, 38.0, "Skeleton Mage passive should restore mana after casting.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _test_stale_freed_unit_references_are_ignored() -> void:
	var battle_root: BattleRootProxy = BattleRootProxy.new()
	get_root().add_child(battle_root)
	var battle_manager: Variant = _create_battle_manager(battle_root, RelicManager.new())
	battle_root.battle_manager = battle_manager

	var player_configs: Array[Dictionary] = [_create_config(PUPPET_WARLOCK_DATA, Vector2(120.0, 240.0), 1)]
	var enemy_configs: Array[Dictionary] = [_create_config(WARRIOR_DATA, Vector2(780.0, 240.0), 101)]
	battle_manager.spawn_battle(player_configs, enemy_configs)
	battle_manager.start_battle()

	var source: Unit = battle_manager.get_left_units()[0]
	var stale_unit: Unit = UNIT_SCENE.instantiate() as Unit
	battle_manager.all_units.append(stale_unit)
	stale_unit.free()

	var found_unit: Unit = battle_manager.summon_manager._find_alive_unit_by_id(source.unit_id)
	_expect_bool(found_unit == source, true, "SummonManager should ignore stale freed all_units entries when finding mark sources.")

	battle_manager.clear_battlefield()
	battle_root.queue_free()


func _create_battle_manager(battle_root: Node, relic_manager: RelicManager) -> Variant:
	var battle_manager: Variant = BATTLE_MANAGER_SCRIPT.new()
	battle_manager.setup(battle_root, UNIT_SCENE, null, relic_manager)
	return battle_manager


func _create_config(unit_data: Resource, position: Vector2, roster_id: int) -> Dictionary:
	return {
		"unit_data": unit_data,
		"position": position,
		"display_name": "Test Unit " + str(roster_id),
		"roster_id": roster_id,
	}


func _count_summons(units: Array[Unit]) -> int:
	var count: int = 0
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and bool(unit.get_meta("is_summon", false)):
			count += 1

	return count


func _count_unit_type(units: Array[Unit], unit_type: String) -> int:
	var count: int = 0
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and unit.is_alive and unit.unit_type == unit_type:
			count += 1

	return count


func _find_unit_type(units: Array[Unit], unit_type: String) -> Unit:
	for unit: Unit in units:
		if unit != null and is_instance_valid(unit) and unit.is_alive and unit.unit_type == unit_type:
			return unit

	return null


func _finish() -> void:
	if failures.is_empty():
		print("Summon system tests passed.")
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


func _expect_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
