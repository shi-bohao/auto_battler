extends SceneTree

const BATTLE_MANAGER_SCRIPT: Script = preload("res://scripts/battle_manager.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const THUNDERMAUL_DATA: Resource = preload("res://data/units/thundermaul_vanguard.tres")
const FROST_PRISM_DATA: Resource = preload("res://data/units/frost_prism_mage.tres")
const BANNERET_DATA: Resource = preload("res://data/units/taunt_banneret.tres")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")

var failures: Array[String] = []
var created_units: Array[Unit] = []
var next_unit_id: int = 1

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	seed(42)
	_test_concussive_armor_shielded_damage_reduction()
	_test_concussive_armor_shielded_damage_reduction_star3()
	_test_concussive_armor_stunned_damage_bonus()
	_test_shatter_focus_frozen_skill_damage()
	_test_shatter_focus_frozen_kill_mana_star3()
	_test_banner_guard_taunt_damage_reduction()
	_test_banner_guard_taunt_shield_power()
	_test_banner_guard_taunt_attack_mana_star3()
	_cleanup_units()
	_finish()

func _test_concussive_armor_shielded_damage_reduction() -> void:
	var target: Unit = _create_unit("Thundermaul", 1)
	target.passive_id = "concussive_armor"
	target.star = 1
	target.shield = 0
	var damage_without_shield: int = target.unit_skill.passive_resolver.apply_incoming_life_damage_passives(target, 100)
	target.set_meta("incoming_damage_had_shield", true)
	var damage_with_shield: int = target.unit_skill.passive_resolver.apply_incoming_life_damage_passives(target, 100)
	target.remove_meta("incoming_damage_had_shield")
	_expect_int(damage_without_shield, 100, "Concussive armor without shield should not reduce damage.")
	_expect_int(damage_with_shield, 90, "Concussive armor with shield should reduce damage by 10%.")

func _test_concussive_armor_shielded_damage_reduction_star3() -> void:
	var target: Unit = _create_unit("Thundermaul", 1)
	target.passive_id = "concussive_armor"
	target.star = 3
	target.set_meta("incoming_damage_had_shield", true)
	var damage: int = target.unit_skill.passive_resolver.apply_incoming_life_damage_passives(target, 100)
	target.remove_meta("incoming_damage_had_shield")
	_expect_int(damage, 85, "Concussive armor 3-star with shield should reduce damage by 15%.")

func _test_concussive_armor_stunned_damage_bonus() -> void:
	var attacker: Unit = _create_unit("Thundermaul", 1)
	attacker.passive_id = "concussive_armor"
	var target_normal: Unit = _create_unit("Normal", 2)
	var target_stunned: Unit = _create_unit("Stunned", 2)
	if target_stunned.control_state == null:
		push_error("Control state is null")
		return
	target_stunned.control_state.is_stunned = true
	var dmg_normal: int = attacker.unit_skill.passive_resolver.get_basic_attack_damage(attacker, target_normal, 100)
	var dmg_stunned: int = attacker.unit_skill.passive_resolver.get_basic_attack_damage(attacker, target_stunned, 100)
	_expect_int(dmg_normal, 100, "Concussive armor against normal target should be base damage.")
	_expect_int(dmg_stunned, 120, "Concussive armor against stunned target should increase damage by 20%.")

const COMBAT_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/combat_resolver.gd")

func _test_shatter_focus_frozen_skill_damage() -> void:
	var resolver: Variant = COMBAT_RESOLVER_SCRIPT.new()
	var caster: Unit = _create_unit("FrostPrism", 1)
	caster.passive_id = "shatter_focus"
	var target_normal: Unit = _create_unit("Normal", 2)
	var target_frozen: Unit = _create_unit("Frozen", 2)
	if target_frozen.control_state == null:
		push_error("Control state is null")
		return
	target_frozen.control_state.is_frozen = true
	var base_damage: int = 100
	var normal_result: int = resolver.resolve_skill_damage(caster, target_normal, base_damage)
	var frozen_result: int = resolver.resolve_skill_damage(caster, target_frozen, base_damage)
	_expect_int(normal_result, 100, "Shatter focus against normal target should be base damage.")
	_expect_int(frozen_result, 120, "Shatter focus against frozen target should increase skill damage by 20%.")

func _test_shatter_focus_frozen_kill_mana_star3() -> void:
	var caster: Unit = _create_unit("FrostPrism", 1)
	caster.passive_id = "shatter_focus"
	caster.star = 3
	caster.max_mana = 100
	caster.current_mana = 0.0
	var target: Unit = _create_unit("Frozen", 2)
	target.control_state.is_frozen = true
	target.hp = 1
	# Connect killed_target signal to apply kill passives through real death flow
	if not caster.killed_target.is_connected(caster.unit_skill.apply_kill_passives):
		caster.killed_target.connect(caster.unit_skill.apply_kill_passives)
	target.take_damage(10, caster, false)
	_expect_float(caster.current_mana, 30.0, "Shatter focus 3-star should restore 30 mana on killing frozen target.")

func _test_banner_guard_taunt_damage_reduction() -> void:
	var banner: Unit = _create_unit("Banner", 1)
	banner.passive_id = "banner_guard"
	var enemy1: Unit = _create_unit("Enemy1", 2)
	var enemy2: Unit = _create_unit("Enemy2", 2)
	banner.enemy_units = [enemy1, enemy2]
	var damage_no_taunt: int = banner.unit_skill.passive_resolver.apply_incoming_life_damage_passives(banner, 100)
	_expect_int(damage_no_taunt, 100, "Banner guard without taunt should not reduce damage.")
	factory_taunt(enemy1, banner, 3.0)
	var damage_with_taunt: int = banner.unit_skill.passive_resolver.apply_incoming_life_damage_passives(banner, 100)
	_expect_int(damage_with_taunt, 88, "Banner guard with taunt should reduce damage by 12%.")

func _test_banner_guard_taunt_shield_power() -> void:
	var banner: Unit = _create_unit("Banner", 1)
	banner.passive_id = "banner_guard"
	var enemy1: Unit = _create_unit("Enemy1", 2)
	var enemy2: Unit = _create_unit("Enemy2", 2)
	banner.enemy_units = [enemy1, enemy2]
	banner.add_shield(100, banner)
	var shield_no_taunt: int = banner.shield
	_expect_int(shield_no_taunt, 100, "Banner guard shield without taunt should be base amount.")
	banner.shield = 0
	factory_taunt(enemy1, banner, 3.0)
	factory_taunt(enemy2, banner, 3.0)
	banner.add_shield(100, banner)
	var shield_with_taunt: int = banner.shield
	_expect_int(shield_with_taunt, 108, "Banner guard shield with 2 taunts should increase by 8%.")

func _test_banner_guard_taunt_attack_mana_star3() -> void:
	var banner: Unit = _create_unit("Banner", 1)
	banner.passive_id = "banner_guard"
	banner.star = 3
	banner.max_mana = 100
	banner.current_mana = 0.0
	var enemy: Unit = _create_unit("Enemy1", 2)
	banner.enemy_units = [enemy]
	factory_taunt(enemy, banner, 3.0)
	banner.take_damage(10, enemy, false)
	_expect_float(banner.current_mana, 3.0, "Banner guard 3-star should restore 3 mana when taunted enemy attacks.")

func factory_taunt(enemy: Unit, banner: Unit, duration: float) -> void:
	if enemy.control_state == null:
		return
	enemy.control_state.is_taunted = true
	enemy.control_state.forced_target = banner
	enemy.control_state.forced_target_unit_id = banner.unit_id

func _create_unit(display_name: String, team_id: int) -> Unit:
	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	created_units.append(unit)
	get_root().add_child(unit)
	unit.unit_id = next_unit_id
	next_unit_id += 1
	unit.display_name = display_name
	unit.team_id = team_id
	unit.is_alive = true
	unit.is_targetable = true
	unit.max_hp = 1000
	unit.hp = 1000
	unit.max_mana = 0
	unit.current_mana = 0.0
	unit.attack_damage = 100
	unit.defense = 0
	unit.shield = 0
	unit.shield_power = 0.0
	unit.damage_taken_multiplier = 1.0
	return unit

func _cleanup_units() -> void:
	for unit: Unit in created_units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()
	created_units.clear()

func _finish() -> void:
	if failures.is_empty():
		print("Control passive tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")

func _expect_float(actual: float, expected: float, message: String) -> void:
	if absf(actual - expected) > 0.01:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
