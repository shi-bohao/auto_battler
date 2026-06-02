extends SceneTree

const STATUS_EFFECT_FACTORY_SCRIPT: Script = preload("res://scripts/combat/status_effect_factory.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")

var failures: Array[String] = []
var created_units: Array[Unit] = []
var next_unit_id: int = 1


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_default_refresh_only_keeps_existing_behavior()
	_test_unique_per_source_refreshes_same_source_and_stacks_different_sources()
	_test_independent_stack_duration_expires_layer_by_layer()
	_test_stack_refresh_duration_resets_existing_layers()
	_test_venom_stack_uses_merged_count_and_decay()
	_test_burning_adds_damage_and_keeps_longer_time()
	_test_permanent_stack_ignores_time_until_clear()
	_test_remove_status_effect_restores_stat_modifier()
	_test_update_survives_effects_cleared_during_tick()
	_cleanup_units()
	_finish()


func _test_default_refresh_only_keeps_existing_behavior() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Source", 2)
	var target: Unit = _create_unit("Target", 1)

	factory.apply_status_effect(target, "refresh_dot", "DAMAGE_OVER_TIME", source, 4.0, 1.0, 10.0, "")
	factory.apply_status_effect(target, "refresh_dot", "DAMAGE_OVER_TIME", source, 6.0, 1.0, 20.0, "")

	_expect_int(target.effect_controller.effects.size(), 1, "Default status policy should refresh the existing effect.")
	var effect: StatusEffect = target.effect_controller.effects[0]
	_expect_float(effect.duration, 6.0, "Refresh-only status should replace duration.")
	_expect_float(effect.value, 20.0, "Refresh-only status should replace value.")


func _test_unique_per_source_refreshes_same_source_and_stacks_different_sources() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source_a: Unit = _create_unit("A", 2)
	var source_b: Unit = _create_unit("B", 2)
	var target: Unit = _create_unit("Vulnerable", 1)
	var options: Dictionary = {
		"stack_policy": STATUS_EFFECT_FACTORY_SCRIPT.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
		"polarity": STATUS_EFFECT_FACTORY_SCRIPT.POLARITY_NEGATIVE,
		"category": STATUS_EFFECT_FACTORY_SCRIPT.CATEGORY_MARK,
	}

	factory.apply_status_effect(target, "vulnerability", "STAT_MULTIPLY", source_a, 5.0, 0.0, 1.10, "damage_taken_multiplier", options)
	factory.apply_status_effect(target, "vulnerability", "STAT_MULTIPLY", source_a, 6.0, 0.0, 1.10, "damage_taken_multiplier", options)
	_expect_int(target.effect_controller.effects.size(), 1, "Same source should refresh its unique status.")
	_expect_float(target.damage_taken_multiplier, 1.10, "Refreshing same-source vulnerability should not add another stack.")

	factory.apply_status_effect(target, "vulnerability", "STAT_MULTIPLY", source_b, 5.0, 0.0, 1.20, "damage_taken_multiplier", options)
	_expect_int(target.effect_controller.effects.size(), 2, "Different sources should keep separate unique statuses.")
	_expect_float(target.damage_taken_multiplier, 1.32, "Different-source vulnerabilities should both affect the target.")


func _test_independent_stack_duration_expires_layer_by_layer() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Buffer", 1)
	var target: Unit = _create_unit("Layered", 1)
	var options: Dictionary = {
		"stack_policy": STATUS_EFFECT_FACTORY_SCRIPT.STACK_POLICY_STACK_INDEPENDENT_DURATION,
		"polarity": STATUS_EFFECT_FACTORY_SCRIPT.POLARITY_POSITIVE,
		"category": STATUS_EFFECT_FACTORY_SCRIPT.CATEGORY_STAT,
	}

	factory.apply_status_effect(target, "layered_defense", "STAT_ADD", source, 1.0, 0.0, 5.0, "defense", options)
	target.update_status_effects(0.5)
	factory.apply_status_effect(target, "layered_defense", "STAT_ADD", source, 1.0, 0.0, 5.0, "defense", options)
	_expect_int(target.defense, 10, "Independent stacks should add their values.")

	target.update_status_effects(0.6)
	_expect_int(target.defense, 5, "Only the first independent stack should expire after its own timer.")
	_expect_int(target.effect_controller.effects.size(), 1, "One independent stack should remain active.")

	target.update_status_effects(0.5)
	_expect_int(target.defense, 0, "All independent stacks should be removed when their timers expire.")
	_expect_int(target.effect_controller.effects.size(), 0, "No independent stacks should remain after expiration.")


func _test_stack_refresh_duration_resets_existing_layers() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Refresher", 1)
	var target: Unit = _create_unit("Stacked", 1)
	var options: Dictionary = {
		"stack_policy": STATUS_EFFECT_FACTORY_SCRIPT.STACK_POLICY_STACK_REFRESH_DURATION,
		"polarity": STATUS_EFFECT_FACTORY_SCRIPT.POLARITY_POSITIVE,
		"category": STATUS_EFFECT_FACTORY_SCRIPT.CATEGORY_STAT,
	}

	factory.apply_status_effect(target, "refreshing_defense", "STAT_ADD", source, 1.0, 0.0, 5.0, "defense", options)
	target.update_status_effects(0.8)
	factory.apply_status_effect(target, "refreshing_defense", "STAT_ADD", source, 1.0, 0.0, 5.0, "defense", options)
	target.update_status_effects(0.3)
	_expect_int(target.defense, 10, "Stack refresh duration should keep old and new layers active.")

	target.update_status_effects(0.8)
	_expect_int(target.defense, 0, "Refreshed layers should expire together after the refreshed timer.")


func _test_venom_stack_uses_merged_count_and_decay() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Venom Source", 2)
	var target: Unit = _create_unit("Venom Target", 1)
	var options: Dictionary = {
		"stack_policy": STATUS_EFFECT_FACTORY_SCRIPT.STACK_POLICY_STACK_INDEPENDENT_DURATION,
		"polarity": STATUS_EFFECT_FACTORY_SCRIPT.POLARITY_NEGATIVE,
		"category": STATUS_EFFECT_FACTORY_SCRIPT.CATEGORY_DOT,
		"stack_count": 3,
		"stack_decay_after_duration": true,
		"stack_decay_per_tick": 5,
	}

	factory.apply_status_effect(target, "venom_stack", "DAMAGE_OVER_TIME", source, 1.0, 1.0, 5.0, "", options)
	_expect_int(target.effect_controller.effects.size(), 1, "Venom should create one merged status instance.")
	_expect_int(target.get_status_effect_count("venom_stack"), 3, "Venom count should report stored stacks.")

	options["stack_count"] = 4
	factory.apply_status_effect(target, "venom_stack", "DAMAGE_OVER_TIME", source, 1.0, 1.0, 5.0, "", options)
	_expect_int(target.effect_controller.effects.size(), 1, "New venom should merge into the existing status.")
	_expect_int(target.get_status_effect_count("venom_stack"), 7, "New venom should add stacks instead of creating new timers.")

	target.update_status_effects(1.0)
	_expect_int(target.hp, 65, "Merged venom should deal damage from all stacks at once.")
	_expect_int(target.get_status_effect_count("venom_stack"), 7, "Venom should enter decay instead of clearing when duration ends.")

	target.update_status_effects(1.0)
	_expect_int(target.hp, 30, "Decaying venom should still deal damage using the current stack count.")
	_expect_int(target.get_status_effect_count("venom_stack"), 2, "Decaying venom should remove five stacks per tick.")

	target.update_status_effects(1.0)
	_expect_int(target.effect_controller.effects.size(), 0, "Venom should clear after decay removes all stacks.")


func _test_burning_adds_damage_and_keeps_longer_time() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Burn Source", 2)
	var target: Unit = _create_unit("Burn Target", 1)

	factory.apply_burning(target, source, 2.0, 4.0)
	_expect_int(target.effect_controller.effects.size(), 1, "Burning should create one status instance.")
	target.update_status_effects(1.0)
	_expect_int(target.hp, 96, "Burning should deal its configured damage every second.")

	factory.apply_burning(target, source, 3.0, 6.0)
	_expect_int(target.effect_controller.effects.size(), 1, "New burning should merge into the existing status.")
	var effect: StatusEffect = target.effect_controller.effects[0]
	_expect_float(effect.value, 10.0, "Burning damage should add together.")
	_expect_float(effect.remaining_time, 3.0, "Burning should keep the longer of current remaining time and new duration.")

	target.update_status_effects(1.0)
	_expect_int(target.hp, 86, "Merged burning should tick for the summed damage.")
	target.update_status_effects(2.0)
	_expect_int(target.hp, 66, "Merged burning should keep ticking until the longer duration expires.")
	_expect_int(target.effect_controller.effects.size(), 0, "Burning should expire normally after its duration.")


func _test_permanent_stack_ignores_time_until_clear() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Permanent", 1)
	var target: Unit = _create_unit("Battle Long", 1)
	var options: Dictionary = {
		"stack_policy": STATUS_EFFECT_FACTORY_SCRIPT.STACK_POLICY_PERMANENT_STACK,
		"duration_mode": STATUS_EFFECT_FACTORY_SCRIPT.DURATION_MODE_NONE,
		"polarity": STATUS_EFFECT_FACTORY_SCRIPT.POLARITY_POSITIVE,
		"category": STATUS_EFFECT_FACTORY_SCRIPT.CATEGORY_STAT,
	}

	factory.apply_status_effect(target, "permanent_defense", "STAT_ADD", source, -1.0, 0.0, 5.0, "defense", options)
	target.update_status_effects(99.0)
	_expect_int(target.defense, 5, "Permanent battle stack should not expire from time passing.")
	_expect_int(target.effect_controller.effects.size(), 1, "Permanent battle stack should remain active until cleared.")

	target.clear_status_effects()
	_expect_int(target.defense, 0, "Clearing status effects should remove permanent battle stacks.")


func _test_remove_status_effect_restores_stat_modifier() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Marker", 1)
	var target: Unit = _create_unit("Marked", 2)
	target.defense = 30
	var options: Dictionary = {
		"stack_policy": STATUS_EFFECT_FACTORY_SCRIPT.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
		"duration_mode": STATUS_EFFECT_FACTORY_SCRIPT.DURATION_MODE_NONE,
		"polarity": STATUS_EFFECT_FACTORY_SCRIPT.POLARITY_NEGATIVE,
		"category": STATUS_EFFECT_FACTORY_SCRIPT.CATEGORY_MARK,
	}

	factory.apply_status_effect(target, "defense_mark", "STAT_ADD", source, -1.0, 0.0, -20.0, "defense", options)
	_expect_int(target.defense, 10, "No-duration defense mark should reduce defense.")
	var removed_count: int = target.remove_status_effect("defense_mark")
	_expect_int(removed_count, 1, "Removing a status effect by id should remove one active mark.")
	_expect_int(target.defense, 30, "Removing a status effect by id should restore its stat modifier.")


func _test_update_survives_effects_cleared_during_tick() -> void:
	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	var source: Unit = _create_unit("Fatal Source", 2)
	var target: Unit = _create_unit("Fragile Target", 1)
	target.max_hp = 10
	target.hp = 10
	var positive_options: Dictionary = {
		"stack_policy": STATUS_EFFECT_FACTORY_SCRIPT.STACK_POLICY_STACK_INDEPENDENT_DURATION,
		"polarity": STATUS_EFFECT_FACTORY_SCRIPT.POLARITY_POSITIVE,
		"category": STATUS_EFFECT_FACTORY_SCRIPT.CATEGORY_STAT,
	}
	var negative_options: Dictionary = {
		"stack_policy": STATUS_EFFECT_FACTORY_SCRIPT.STACK_POLICY_STACK_INDEPENDENT_DURATION,
		"polarity": STATUS_EFFECT_FACTORY_SCRIPT.POLARITY_NEGATIVE,
		"category": STATUS_EFFECT_FACTORY_SCRIPT.CATEGORY_DOT,
	}

	factory.apply_status_effect(target, "padding_defense_a", "STAT_ADD", source, 5.0, 0.0, 1.0, "defense", positive_options)
	factory.apply_status_effect(target, "padding_defense_b", "STAT_ADD", source, 5.0, 0.0, 1.0, "defense", positive_options)
	factory.apply_status_effect(target, "fatal_dot", "DAMAGE_OVER_TIME", source, 1.0, 0.1, 20.0, "", negative_options)
	target.update_status_effects(0.2)

	_expect_true(not target.is_alive, "Fatal DOT should kill the target.")
	_expect_int(target.effect_controller.effects.size(), 0, "Death should clear status effects without update index errors.")


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
	unit.ally_units = [unit]
	return unit


func _cleanup_units() -> void:
	for unit in created_units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()
	created_units.clear()


func _finish() -> void:
	if failures.is_empty():
		print("Status effect stack policy tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
