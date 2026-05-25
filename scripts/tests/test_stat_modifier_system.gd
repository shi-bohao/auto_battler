extends SceneTree

const GOLDEN_ARMOR_CONTRACT: Resource = preload("res://data/relics/golden_armor_contract.tres")
const GOLDEN_CHARM: Resource = preload("res://data/relics/golden_charm.tres")
const CROWN_OF_GREED: Resource = preload("res://data/relics/crown_of_greed.tres")

var failures: Array[String] = []
var created_units: Array[Unit] = []
var test_gold: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_stat_modifier_stage_order()
	_test_dynamic_gold_auras_refresh_with_gold_and_position()
	_cleanup_units()
	_finish()


func _test_stat_modifier_stage_order() -> void:
	var unit: Unit = _create_player_unit("Layered Stats")
	unit.attack_damage = 100

	unit.add_stat_modifier({
		"modifier_id": "test:permanent_flat",
		"source_key": "test:permanent",
		"stat_name": "attack_damage",
		"stage": StatModifier.STAGE_PERMANENT_FLAT,
		"value": 10.0,
	})
	unit.add_stat_modifier({
		"modifier_id": "test:permanent_percent",
		"source_key": "test:permanent",
		"stat_name": "attack_damage",
		"stage": StatModifier.STAGE_PERMANENT_PERCENT,
		"value": 0.10,
	})
	unit.add_stat_modifier({
		"modifier_id": "test:runtime_flat",
		"source_key": "test:runtime",
		"stat_name": "attack_damage",
		"stage": StatModifier.STAGE_RUNTIME_FLAT,
		"value": 5.0,
	})
	unit.add_stat_modifier({
		"modifier_id": "test:runtime_percent",
		"source_key": "test:runtime",
		"stat_name": "attack_damage",
		"stage": StatModifier.STAGE_RUNTIME_PERCENT,
		"value": 0.20,
	})
	unit.add_stat_modifier({
		"modifier_id": "test:final_flat",
		"source_key": "test:final",
		"stat_name": "attack_damage",
		"stage": StatModifier.STAGE_FINAL_FLAT,
		"value": 1.0,
	})
	unit.add_stat_modifier({
		"modifier_id": "test:final_percent",
		"source_key": "test:final",
		"stat_name": "attack_damage",
		"stage": StatModifier.STAGE_FINAL_PERCENT,
		"value": 0.10,
	})
	unit.add_stat_modifier({
		"modifier_id": "test:final_multiply",
		"source_key": "test:final",
		"stat_name": "attack_damage",
		"stage": StatModifier.STAGE_FINAL_MULTIPLY,
		"value": 2.0,
	})

	_expect_int(unit.attack_damage, 335, "Stat modifiers should resolve by permanent/runtime/final stage order.")

	unit.remove_stat_modifiers_by_source("test:runtime")
	_expect_int(unit.attack_damage, 268, "Removing one modifier source should recalculate remaining stages from base stats.")


func _test_dynamic_gold_auras_refresh_with_gold_and_position() -> void:
	var relic_manager: RelicManager = RelicManager.new()
	relic_manager.set_gold_query_callback(Callable(self, "get_test_gold"))
	relic_manager.add_relic(GOLDEN_ARMOR_CONTRACT)
	relic_manager.add_relic(GOLDEN_CHARM)
	relic_manager.add_relic(CROWN_OF_GREED)

	var unit: Unit = _create_player_unit("Gold Aura Unit")
	unit.attack_damage = 100
	unit.defense = 0
	unit.skill_power = 0.0
	unit.healing_power = 0.0
	unit.position = Vector2(600.0, 220.0)

	test_gold = 10
	relic_manager.apply_always_on_relics_to_runtime_unit(unit)
	_expect_int(unit.attack_damage, 116, "Gold auras should apply attack bonuses from current gold.")
	_expect_int(unit.defense, 5, "Golden Armor Contract should grant frontline defense from current gold.")
	_expect_float(unit.skill_power, 0.06, "Crown of Greed should grant skill power by gold steps.")
	_expect_float(unit.healing_power, 0.06, "Crown of Greed should grant healing power by gold steps.")

	test_gold = 30
	relic_manager.refresh_dynamic_relic_auras_for_unit(unit)
	_expect_int(unit.attack_damage, 138, "Dynamic gold attack bonuses should refresh when gold changes.")
	_expect_int(unit.defense, 15, "Dynamic gold defense should refresh when gold changes.")
	_expect_float(unit.skill_power, 0.18, "Dynamic gold skill power should refresh when gold changes.")
	_expect_float(unit.healing_power, 0.18, "Dynamic gold healing power should refresh when gold changes.")

	unit.position = Vector2(120.0, 220.0)
	relic_manager.refresh_dynamic_relic_auras_for_unit(unit)
	_expect_int(unit.defense, 0, "Golden Armor Contract should be removed when the unit leaves the frontline.")
	_expect_int(unit.attack_damage, 138, "Non-position gold auras should remain after position refresh.")

	test_gold = 0
	relic_manager.refresh_dynamic_relic_auras_for_unit(unit)
	_expect_int(unit.attack_damage, 100, "Dynamic gold attack bonuses should return to base at zero gold.")
	_expect_float(unit.skill_power, 0.0, "Dynamic gold skill power should return to base at zero gold.")
	_expect_float(unit.healing_power, 0.0, "Dynamic gold healing power should return to base at zero gold.")


func get_test_gold() -> int:
	return test_gold


func _create_player_unit(display_name: String) -> Unit:
	var unit: Unit = Unit.new()
	created_units.append(unit)
	unit.display_name = display_name
	unit.team_id = 1
	unit.is_alive = true
	unit.max_hp = 100
	unit.hp = 100
	unit.attack_damage = 10
	unit.defense = 0
	unit.skill_power = 0.0
	unit.healing_power = 0.0
	unit.shield_power = 0.0
	unit.max_mana = 100
	unit.current_mana = 0.0
	return unit


func _cleanup_units() -> void:
	for unit: Unit in created_units:
		if unit != null and is_instance_valid(unit):
			unit.free()

	created_units.clear()


func _finish() -> void:
	if failures.is_empty():
		print("Stat modifier system tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")
