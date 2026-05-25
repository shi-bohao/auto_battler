extends SceneTree

const UNIT_DATA_APPLIER_SCRIPT: Script = preload("res://scripts/unit_data_applier.gd")
const STATUS_EFFECT_FACTORY_SCRIPT: Script = preload("res://scripts/combat/status_effect_factory.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const MAGE_LENS: Resource = preload("res://data/relics/mage_lens.tres")
const HEALING_BELL: Resource = preload("res://data/relics/healing_bell.tres")
const ARCANE_PRISM: Resource = preload("res://data/relics/arcane_prism.tres")
const MERCY_CENSER: Resource = preload("res://data/relics/mercy_censer.tres")
const PIERCING_WHETSTONE: Resource = preload("res://data/relics/piercing_whetstone.tres")
const BLOODGLASS_CHARM: Resource = preload("res://data/relics/bloodglass_charm.tres")
const BULWARK_RUNE: Resource = preload("res://data/relics/bulwark_rune.tres")
const OPENING_TOME: Resource = preload("res://data/relics/opening_tome.tres")
const DYNAMO_NEEDLE: Resource = preload("res://data/relics/dynamo_needle.tres")
const MIRAGE_CLOAK: Resource = preload("res://data/relics/mirage_cloak.tres")

var failures: Array[String] = []
var created_units: Array[Unit] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_unit_data_applier_copies_extended_attributes()
	_test_damage_formula_uses_penetration_and_reduction()
	_test_heal_and_shield_power()
	_test_initial_mana_attack_mana_and_life_steal()
	_test_status_resistance_reduces_enemy_dot_duration()
	_test_relics_use_new_attribute_fields()
	_test_new_attribute_relics_apply_battle_start_bonuses()
	_cleanup_units()
	_finish()


func _test_unit_data_applier_copies_extended_attributes() -> void:
	var unit_data: UnitData = UnitData.new()
	unit_data.skill_power = 0.11
	unit_data.healing_power = 0.12
	unit_data.shield_power = 0.13
	unit_data.defense_penetration = 7
	unit_data.life_steal = 0.14
	unit_data.damage_reduction = 0.15
	unit_data.initial_mana = 16.0
	unit_data.mana_on_attack = 17.0
	unit_data.mana_on_hit_taken = 18.0
	unit_data.status_resistance = 0.19
	unit_data.dodge_chance = 0.20

	var unit: Unit = _create_unit("Applied", 1)
	UNIT_DATA_APPLIER_SCRIPT.new().apply_unit_data(unit, unit_data)

	_expect_float(unit.skill_power, 0.11, "UnitDataApplier should copy skill power.")
	_expect_float(unit.healing_power, 0.12, "UnitDataApplier should copy healing power.")
	_expect_float(unit.shield_power, 0.13, "UnitDataApplier should copy shield power.")
	_expect_int(unit.defense_penetration, 7, "UnitDataApplier should copy defense penetration.")
	_expect_float(unit.life_steal, 0.14, "UnitDataApplier should copy life steal.")
	_expect_float(unit.damage_reduction, 0.15, "UnitDataApplier should copy damage reduction.")
	_expect_float(unit.initial_mana, 16.0, "UnitDataApplier should copy initial mana.")
	_expect_float(unit.mana_on_attack, 17.0, "UnitDataApplier should copy attack mana.")
	_expect_float(unit.mana_on_hit_taken, 18.0, "UnitDataApplier should copy hit mana.")
	_expect_float(unit.status_resistance, 0.19, "UnitDataApplier should copy status resistance.")
	_expect_float(unit.dodge_chance, 0.20, "UnitDataApplier should copy dodge chance.")


func _test_damage_formula_uses_penetration_and_reduction() -> void:
	var attacker: Unit = _create_unit("Penetrator", 1)
	var target: Unit = _create_unit("Defender", 2)
	attacker.defense_penetration = 50
	target.max_hp = 1000
	target.hp = 1000
	target.defense = 100
	target.damage_reduction = 0.25

	var actual_damage: int = target.take_damage(100, attacker, false)

	_expect_int(actual_damage, 50, "Damage should use defense penetration before damage reduction.")
	_expect_int(target.hp, 950, "Target HP should lose the resolved damage.")


func _test_heal_and_shield_power() -> void:
	var source: Unit = _create_unit("Support", 1)
	var target: Unit = _create_unit("Ally", 1)
	source.healing_power = 0.5
	source.shield_power = 0.25
	target.max_hp = 100
	target.hp = 50

	target.heal(20, source)
	target.add_shield(40, source)

	_expect_int(target.hp, 80, "Healing power should increase outgoing healing.")
	_expect_int(target.shield, 50, "Shield power should increase outgoing shields.")


func _test_initial_mana_attack_mana_and_life_steal() -> void:
	var unit: Unit = _create_unit("Leech", 1)
	unit.max_hp = 100
	unit.hp = 50
	unit.max_mana = 100
	unit.initial_mana = 30.0
	unit.mana_on_attack = 12.0
	unit.life_steal = 0.20

	unit.unit_skill.reset_mana(unit)
	unit._apply_basic_attack_attribute_rewards(50)

	_expect_float(unit.current_mana, 42.0, "Initial mana and mana on attack should stack.")
	_expect_int(unit.hp, 60, "Life steal should heal from actual basic attack damage.")


func _test_status_resistance_reduces_enemy_dot_duration() -> void:
	var source: Unit = _create_unit("Poisoner", 2)
	var target: Unit = _create_unit("Resistant", 1)
	target.status_resistance = 0.50

	var factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()
	factory.apply_status_effect(target, "test_dot", "DAMAGE_OVER_TIME", source, 4.0, 1.0, 10.0, "")

	_expect_int(target.effect_controller.effects.size(), 1, "Status effect should be applied.")
	if target.effect_controller.effects.size() > 0:
		var effect: StatusEffect = target.effect_controller.effects[0]
		_expect_float(effect.duration, 2.0, "Status resistance should shorten enemy negative status duration.")


func _test_relics_use_new_attribute_fields() -> void:
	var relic_manager: RelicManager = RelicManager.new()
	relic_manager.add_relic(MAGE_LENS)
	relic_manager.add_relic(HEALING_BELL)

	var mage: Unit = _create_unit("Mage", 1)
	mage.unit_type = "mage"
	var priest: Unit = _create_unit("Priest", 1)
	priest.unit_type = "priest"

	relic_manager.apply_always_on_relics_to_runtime_unit(mage)
	relic_manager.apply_always_on_relics_to_runtime_unit(priest)

	_expect_float(mage.skill_power, 0.35, "Mage Lens should now write to skill power.")
	_expect_float(priest.healing_power, 0.40, "Healing Bell should now write to healing power.")
	_expect_true(mage.has_meta("always_on_relic_mage_lens"), "Mage Lens should mark itself as an always-on relic.")
	_expect_true(priest.has_meta("always_on_relic_healing_bell"), "Healing Bell should mark itself as an always-on relic.")


func _test_new_attribute_relics_apply_battle_start_bonuses() -> void:
	var relic_manager: RelicManager = RelicManager.new()
	relic_manager.add_relic(ARCANE_PRISM)
	relic_manager.add_relic(MERCY_CENSER)
	relic_manager.add_relic(PIERCING_WHETSTONE)
	relic_manager.add_relic(BLOODGLASS_CHARM)
	relic_manager.add_relic(BULWARK_RUNE)
	relic_manager.add_relic(OPENING_TOME)
	relic_manager.add_relic(DYNAMO_NEEDLE)
	relic_manager.add_relic(MIRAGE_CLOAK)

	var frontline: Unit = _create_unit("Frontline", 1)
	frontline.position = Vector2(600.0, 240.0)
	frontline.max_mana = 100
	var backline: Unit = _create_unit("Backline", 1)
	backline.position = Vector2(100.0, 240.0)
	backline.max_mana = 100

	relic_manager.apply_always_on_relics_to_runtime_unit(frontline)
	relic_manager.apply_always_on_relics_to_runtime_unit(backline)
	relic_manager.trigger_battle_start_relics([frontline, backline])

	_expect_float(frontline.skill_power, 0.15, "Arcane Prism should increase skill power.")
	_expect_float(frontline.healing_power, 0.20, "Mercy Censer should increase healing power.")
	_expect_float(frontline.shield_power, 0.20, "Mercy Censer should increase shield power.")
	_expect_int(frontline.defense_penetration, 8, "Armorbreaker Whetstone should increase defense penetration.")
	_expect_float(frontline.life_steal, 0.08, "Bloodglass Charm should increase life steal.")
	_expect_float(frontline.damage_reduction, 0.08, "Bulwark Rune should increase frontline damage reduction.")
	_expect_float(frontline.status_resistance, 0.15, "Bulwark Rune should increase frontline status resistance.")
	_expect_float(frontline.initial_mana, 20.0, "Opening Tome should increase initial mana.")
	_expect_float(frontline.current_mana, 20.0, "Opening Tome should immediately restore mana.")
	_expect_float(frontline.mana_on_attack, 4.0, "Dynamo Needle should increase mana on attack.")
	_expect_float(frontline.mana_on_hit_taken, 4.0, "Dynamo Needle should increase mana on hit taken.")
	_expect_float(backline.dodge_chance, 0.10, "Mirage Cloak should increase backline dodge chance.")
	_expect_float(backline.status_resistance, 0.10, "Mirage Cloak should increase backline status resistance.")
	_expect_true(frontline.has_meta("always_on_relic_arcane_prism"), "Arcane Prism should mark itself as an always-on relic.")
	_expect_true(frontline.has_meta("always_on_relic_piercing_whetstone"), "Armorbreaker Whetstone should mark itself as an always-on relic.")
	_expect_true(frontline.effect_controller.has_effect("relic_opening_tome_initial_mana"), "Opening Tome initial mana should apply through the status effect system.")
	_expect_true(backline.effect_controller.has_effect("relic_mirage_cloak_dodge_chance"), "Mirage Cloak should apply through the status effect system.")


func _create_unit(display_name: String, team_id: int) -> Unit:
	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	created_units.append(unit)
	get_root().add_child(unit)
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
	unit.ally_units = [unit]
	return unit


func _cleanup_units() -> void:
	for unit in created_units:
		if unit != null and is_instance_valid(unit):
			unit.queue_free()
	created_units.clear()


func _finish() -> void:
	if failures.is_empty():
		print("Extended unit attribute tests passed.")
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
