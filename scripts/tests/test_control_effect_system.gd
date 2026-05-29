extends SceneTree

const STATUS_EFFECT_FACTORY_SCRIPT: Script = preload("res://scripts/combat/status_effect_factory.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")

var failures: Array[String] = []
var created_units: Array[Unit] = []
var next_unit_id: int = 1


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_control_applies_immediately_and_updates_visual_row()
	_test_control_refresh_keeps_longer_duration_policy()
	_test_taunt_forced_target_is_valid()
	_test_taunt_overrides_existing_target()
	_test_invalid_taunt_source_releases_retarget_lock()
	_test_control_duration_multipliers()
	_cleanup_units()
	_finish()


func _test_control_applies_immediately_and_updates_visual_row() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Source", 1)
	var target: Unit = _create_unit("Target", 2)

	factory.apply_control_effect(target, "SLOW", source, 3.0, {
		"effect_id": "test_slow",
		"move_speed_multiplier": 0.45,
	})

	_expect_true(target.control_state.is_slowed, "Slow should rebuild UnitControlState immediately.")
	_expect_float(target.control_state.move_speed_multiplier, 0.45, "Slow should update movement multiplier.")
	_expect_float(target.control_state.attack_cooldown_rate_multiplier, 0.45, "Slow should update attack cooldown rate multiplier.")
	_expect_float(target.control_state.mana_regen_multiplier, 0.45, "Slow should update mana regen multiplier.")
	_expect_true(target.control_status_row.visible, "Control status row should become visible when control is active.")

	target.is_battle_active = true
	target.attack_cooldown = 10.0
	target.max_mana = 100
	target.current_mana = 0.0
	target.mana_regen_per_second = 10.0
	target._process(1.0)

	_expect_float(target.attack_cooldown, 9.55, "Slow should reduce attack cooldown recovery rate.")
	_expect_float(target.current_mana, 4.5, "Slow should reduce natural mana regen rate.")


func _test_control_refresh_keeps_longer_duration_policy() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Source", 1)
	var target: Unit = _create_unit("Target", 2)

	factory.apply_control_effect(target, "ROOT", source, 3.0, {"effect_id": "test_root"})
	target.update_status_effects(1.0)
	factory.apply_control_effect(target, "ROOT", source, 1.0, {"effect_id": "test_root"})
	_expect_float(roundf(target.effect_controller.effects[0].remaining_time * 10.0) / 10.0, 2.0, "Shorter root refresh should keep the longer remaining duration.")

	factory.apply_control_effect(target, "ROOT", source, 4.0, {"effect_id": "test_root"})
	_expect_float(target.effect_controller.effects[0].remaining_time, 4.0, "Longer root refresh should replace remaining duration.")


func _test_taunt_forced_target_is_valid() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Banner", 1)
	var target: Unit = _create_unit("Enemy", 2)

	factory.apply_control_effect(target, "TAUNT", source, 3.0, {"effect_id": "test_taunt"})

	_expect_true(target.control_state.is_taunted, "Taunt state should be active.")
	_expect_true(target.control_state.get_valid_forced_target(target) == source, "Taunt forced target should point to the source unit.")


func _test_taunt_overrides_existing_target() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var banner: Unit = _create_unit("Banner", 1)
	var old_target: Unit = _create_unit("Old Target", 1)
	var enemy: Unit = _create_unit("Enemy", 2)
	enemy.enemy_units = [banner, old_target]
	enemy.current_target = old_target

	factory.apply_control_effect(enemy, "TAUNT", banner, 3.0, {"effect_id": "test_taunt_override"})
	enemy.unit_targeting.update_targeting(enemy, 0.1)

	_expect_true(enemy.current_target == banner, "Taunt should immediately override an already valid current target.")


func _test_invalid_taunt_source_releases_retarget_lock() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var banner: Unit = _create_unit("Banner", 1)
	var fallback: Unit = _create_unit("Fallback", 1)
	var enemy: Unit = _create_unit("Enemy", 2)
	enemy.enemy_units = [banner, fallback]

	factory.apply_control_effect(enemy, "TAUNT", banner, 3.0, {"effect_id": "test_taunt_invalid_source"})
	enemy.unit_targeting.update_targeting(enemy, 0.1)
	_expect_true(enemy.current_target == banner, "Taunt should initially force the banner target.")

	banner.is_alive = false
	enemy.current_target = banner
	enemy.unit_targeting.update_targeting(enemy, 0.1)

	_expect_true(enemy.current_target == fallback, "Taunt should release target lock when its source is no longer valid.")
	_expect_true(enemy.control_state.can_retarget, "Invalid taunt source should release retarget lock after control state rebuild.")


func _test_control_duration_multipliers() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Source", 1)
	var target: Unit = _create_unit("Resistant", 2)
	target.status_resistance = 0.25
	target.control_duration_multiplier = 0.8
	target.hard_control_duration_multiplier = 0.5

	factory.apply_control_effect(target, "STUN", source, 4.0, {"effect_id": "test_stun"})
	_expect_float(target.effect_controller.effects[0].duration, 1.2, "Hard control duration should include status resistance, control multiplier, and hard-control multiplier.")


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
	unit.max_hp = 100
	unit.hp = 100
	unit.max_mana = 0
	unit.current_mana = 0.0
	unit.attack_damage = 10
	unit.defense = 0
	unit.shield = 0
	unit.damage_taken_multiplier = 1.0
	return unit


func _cleanup_units() -> void:
	for unit: Unit in created_units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()
	created_units.clear()


func _finish() -> void:
	if failures.is_empty():
		print("Control effect system tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_float(actual: float, expected: float, message: String) -> void:
	if absf(actual - expected) > 0.01:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
