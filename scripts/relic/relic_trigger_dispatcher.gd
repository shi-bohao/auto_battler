class_name RelicTriggerDispatcher
extends RefCounted


const RELIC_TRIGGER_BATTLE_START: String = "BATTLE_START"
const RELIC_ID_BLOOD_PENDANT: String = "blood_pendant"
const RELIC_ID_SOUL_LANTERN: String = "soul_lantern"
const RELIC_ID_EXECUTIONER_SIGIL: String = "executioner_sigil"
const RELIC_ID_VICTORY_DRUM: String = "victory_drum"
const RELIC_ID_HUNTER_MARK: String = "hunter_mark"
const RELIC_ID_VENGEANCE_SPARK: String = "vengeance_spark"
const RELIC_ID_LAST_STAND: String = "last_stand"
const RELIC_ID_SOUL_EMBER: String = "soul_ember"
const RELIC_ID_DUELIST_GLOVE: String = "duelist_glove"
const RELIC_ID_GRAVEBONE_CHARM: String = "gravebone_charm"

var relic_manager_ref: WeakRef = null
var relic_effect_resolver: Variant = null


func setup(relic_manager_value: Variant, relic_effect_resolver_value: Variant) -> void:
	relic_manager_ref = weakref(relic_manager_value)
	relic_effect_resolver = relic_effect_resolver_value


func trigger_battle_start_relics(player_units: Array[Unit]) -> void:
	var player_relics: Array[Resource] = _get_player_relics()
	if player_relics.is_empty():
		return

	print("Triggering battle start relics")
	for relic_data in player_relics:
		if relic_data == null:
			continue

		if _get_relic_trigger_type(relic_data) != RELIC_TRIGGER_BATTLE_START:
			continue

		relic_effect_resolver.apply_battle_start_relic(relic_data, player_units)


func trigger_attack_relics(attacker: Unit, target: Unit) -> void:
	if not _is_owner_unit(attacker):
		return

	if _has_relic_id(RELIC_ID_HUNTER_MARK):
		relic_effect_resolver.try_apply_hunter_mark_relic(attacker, target)

	if _has_relic_id(RELIC_ID_DUELIST_GLOVE):
		relic_effect_resolver.try_apply_duelist_glove_relic(attacker, target)


func trigger_kill_relics(attacker: Unit, target: Unit) -> void:
	if not _is_owner_unit(attacker):
		return

	if _has_relic_id(RELIC_ID_BLOOD_PENDANT):
		relic_effect_resolver.apply_blood_pendant_relic(attacker)

	if _has_relic_id(RELIC_ID_SOUL_LANTERN):
		relic_effect_resolver.apply_soul_lantern_relic(attacker)

	if _has_relic_id(RELIC_ID_EXECUTIONER_SIGIL):
		relic_effect_resolver.apply_executioner_sigil_relic(attacker)

	if _has_relic_id(RELIC_ID_VICTORY_DRUM):
		relic_effect_resolver.apply_victory_drum_relic(attacker)


func trigger_death_relics(dead_unit: Unit, enemy_units: Array[Unit], is_battle_active: bool, player_units: Array[Unit]) -> void:
	if not is_battle_active:
		return

	if dead_unit == null or not is_instance_valid(dead_unit):
		return

	if dead_unit.team_id != _get_owner_team_id():
		return

	if _has_relic_id(RELIC_ID_LAST_STAND):
		relic_effect_resolver.apply_last_stand_relic(dead_unit, player_units)

	if _has_relic_id(RELIC_ID_SOUL_EMBER):
		relic_effect_resolver.apply_soul_ember_relic(dead_unit, player_units)

	if _has_relic_id(RELIC_ID_VENGEANCE_SPARK):
		relic_effect_resolver.apply_vengeance_spark_relic(dead_unit, enemy_units)

	if _has_relic_id(RELIC_ID_GRAVEBONE_CHARM) and not bool(dead_unit.get_meta("is_summon", false)):
		relic_effect_resolver.apply_gravebone_charm_relic(dead_unit)


func _get_player_relics() -> Array[Resource]:
	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager != null and current_relic_manager.has_method("get_player_relics"):
		return current_relic_manager.get_player_relics()

	var empty_relics: Array[Resource] = []
	return empty_relics


func _get_relic_trigger_type(relic_data: Resource) -> String:
	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null or not current_relic_manager.has_method("get_relic_trigger_type"):
		return ""

	return str(current_relic_manager.get_relic_trigger_type(relic_data))


func _has_relic_id(relic_id: String) -> bool:
	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null or not current_relic_manager.has_method("has_relic_id"):
		return false

	return bool(current_relic_manager.has_relic_id(relic_id))


func _is_owner_unit(unit: Unit) -> bool:
	return unit != null and is_instance_valid(unit) and unit.team_id == _get_owner_team_id() and unit.is_alive


func _get_owner_team_id() -> int:
	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null or not current_relic_manager.has_method("get_owner_team_id"):
		return 1

	return int(current_relic_manager.get_owner_team_id())


func _get_relic_manager() -> Variant:
	if relic_manager_ref == null:
		return null

	return relic_manager_ref.get_ref()
