extends SceneTree

const SOUL_LANTERN: Resource = preload("res://data/relics/soul_lantern.tres")
const EXECUTIONER_SIGIL: Resource = preload("res://data/relics/executioner_sigil.tres")
const VICTORY_DRUM: Resource = preload("res://data/relics/victory_drum.tres")
const BATTLE_BANNER: Resource = preload("res://data/relics/battle_banner.tres")
const VITALITY_TROPHY: Resource = preload("res://data/relics/vitality_trophy.tres")


class FakeRosterManager:
	extends RefCounted

	var bonuses: Dictionary = {}

	func add_permanent_stat_bonus_by_roster_id(roster_id: int, stat_name: String, amount: float) -> bool:
		var key: String = str(roster_id) + ":" + stat_name
		bonuses[key] = float(bonuses.get(key, 0.0)) + amount
		return true

	func get_bonus(roster_id: int, stat_name: String) -> float:
		return float(bonuses.get(str(roster_id) + ":" + stat_name, 0.0))

var failures: Array[String] = []
var created_units: Array[Unit] = []


func _init() -> void:
	_test_soul_lantern_restores_mana()
	_test_executioner_sigil_increases_attack_damage()
	_test_victory_drum_shields_alive_allies()
	_test_vitality_trophy_stores_permanent_max_hp()
	_test_always_on_relics_apply_once()
	_test_kill_relics_can_trigger_together()
	_cleanup_units()

	if failures.is_empty():
		print("Kill relic tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_soul_lantern_restores_mana() -> void:
	var relic_manager: RelicManager = _create_relic_manager([SOUL_LANTERN])
	var attacker: Unit = _create_player_unit("Mana Killer")
	attacker.max_mana = 100
	attacker.current_mana = 80.0

	relic_manager.trigger_kill_relics(attacker, _create_enemy_unit())

	_expect_float(attacker.current_mana, 100.0, "Soul Lantern should restore mana and cap at max_mana.")


func _test_executioner_sigil_increases_attack_damage() -> void:
	var relic_manager: RelicManager = _create_relic_manager([EXECUTIONER_SIGIL])
	var attacker: Unit = _create_player_unit("Attack Killer")
	attacker.attack_damage = 100

	relic_manager.trigger_kill_relics(attacker, _create_enemy_unit())

	_expect_int(attacker.attack_damage, 112, "Executioner Sigil should increase attack damage by 12%.")
	_expect_true(attacker.effect_controller.has_effect("relic_executioner_sigil_attack_damage"), "Executioner Sigil should apply attack damage through the status effect system.")

	relic_manager.trigger_kill_relics(attacker, _create_enemy_unit())
	_expect_int(attacker.attack_damage, 125, "Executioner Sigil should stack once per kill.")
	_expect_int(attacker.effect_controller.effects.size(), 2, "Executioner Sigil should keep separate permanent stacks.")


func _test_victory_drum_shields_alive_allies() -> void:
	var relic_manager: RelicManager = _create_relic_manager([VICTORY_DRUM])
	var attacker: Unit = _create_player_unit("Shield Killer")
	var ally: Unit = _create_player_unit("Alive Ally")
	var dead_ally: Unit = _create_player_unit("Dead Ally")
	dead_ally.is_alive = false
	attacker.ally_units = [attacker, ally, dead_ally]

	relic_manager.trigger_kill_relics(attacker, _create_enemy_unit())

	_expect_int(attacker.shield, 12, "Victory Drum should shield the attacker.")
	_expect_int(ally.shield, 12, "Victory Drum should shield alive allies.")
	_expect_int(dead_ally.shield, 0, "Victory Drum should not shield dead allies.")


func _test_vitality_trophy_stores_permanent_max_hp() -> void:
	var relic_manager: RelicManager = _create_relic_manager([VITALITY_TROPHY])
	var roster_manager: FakeRosterManager = FakeRosterManager.new()
	var attacker: Unit = _create_player_unit("Vitality Killer")
	attacker.roster_id = 7
	attacker.roster_area = "active"
	attacker.max_hp = 100
	attacker.hp = 60

	relic_manager.trigger_kill_relics(attacker, _create_enemy_unit(), roster_manager, null)

	_expect_int(attacker.max_hp, 105, "Blood Oath Chalice should increase runtime max HP.")
	_expect_int(attacker.hp, 65, "Blood Oath Chalice should preserve current HP ratio by adding the same HP amount.")
	_expect_float(roster_manager.get_bonus(7, "max_hp"), 5.0, "Blood Oath Chalice should store max HP on the roster item.")


func _test_always_on_relics_apply_once() -> void:
	var relic_manager: RelicManager = _create_relic_manager([BATTLE_BANNER])
	var unit: Unit = _create_player_unit("Aura Unit")
	unit.attack_damage = 100
	var units: Array[Unit] = [unit]

	relic_manager.apply_always_on_relics_to_runtime_unit(unit)
	_expect_int(unit.attack_damage, 110, "Battle Banner should apply as an always-on aura.")

	relic_manager.trigger_battle_start_relics(units)
	_expect_int(unit.attack_damage, 110, "Always-on relics should not apply again at battle start.")


func _test_kill_relics_can_trigger_together() -> void:
	var relic_manager: RelicManager = _create_relic_manager([SOUL_LANTERN, EXECUTIONER_SIGIL, VICTORY_DRUM])
	var attacker: Unit = _create_player_unit("Combo Killer")
	var ally: Unit = _create_player_unit("Combo Ally")
	attacker.ally_units = [attacker, ally]
	attacker.max_mana = 100
	attacker.current_mana = 10.0
	attacker.attack_damage = 100

	relic_manager.trigger_kill_relics(attacker, _create_enemy_unit())

	_expect_float(attacker.current_mana, 35.0, "Multiple kill relics should restore mana.")
	_expect_int(attacker.attack_damage, 112, "Multiple kill relics should increase attack damage.")
	_expect_int(attacker.shield, 12, "Multiple kill relics should shield the attacker.")
	_expect_int(ally.shield, 12, "Multiple kill relics should shield allies.")


func _create_relic_manager(relics: Array[Resource]) -> RelicManager:
	var relic_manager: RelicManager = RelicManager.new()
	for relic in relics:
		relic_manager.add_relic(relic)

	return relic_manager


func _create_player_unit(display_name: String) -> Unit:
	var unit: Unit = Unit.new()
	created_units.append(unit)
	unit.display_name = display_name
	unit.team_id = 1
	unit.is_alive = true
	unit.max_hp = 100
	unit.hp = 100
	unit.max_mana = 0
	unit.current_mana = 0.0
	unit.attack_damage = 10
	unit.shield = 0
	unit.ally_units = [unit]
	return unit


func _create_enemy_unit() -> Unit:
	var unit: Unit = Unit.new()
	created_units.append(unit)
	unit.display_name = "Target"
	unit.team_id = 2
	unit.is_alive = false
	return unit


func _cleanup_units() -> void:
	for unit in created_units:
		if unit != null and is_instance_valid(unit):
			unit.free()

	created_units.clear()


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_float(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
