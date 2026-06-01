class_name SummonManager
extends RefCounted

const META_IS_SUMMON: String = "is_summon"
const META_SUMMON_SOURCE_TYPE: String = "summon_source_type"
const META_SUMMON_SOURCE_KEY: String = "summon_source_key"
const META_SUMMON_SOURCE_UNIT_ID: String = "summon_source_unit_id"
const META_SUMMON_RELIC_ID: String = "summon_relic_id"
const META_SUMMON_AFFECTS_RESULT: String = "summon_affects_result"

const SOURCE_TYPE_UNIT: String = "unit"
const SOURCE_TYPE_RELIC: String = "relic"
const DEFAULT_UNIT_SUMMON_CAP: int = 3
const DEFAULT_SPAWN_RADIUS: float = 42.0
const PASSIVE_GRAVE_COMMAND: String = "grave_command"
const PASSIVE_ENEMY_DEATH_SUMMONS_SKELETONS: String = "enemy_death_summons_skeletons"
const PASSIVE_ENEMY_KILL_SUMMONS_SKELETONS: String = "enemy_kill_summons_skeletons"
const PUPPET_MARK_META: String = "summon_puppet_marked"
const PUPPET_MARK_SOURCE_ID_META: String = "summon_puppet_source_unit_id"
const PUPPET_MARK_TEAM_ID_META: String = "summon_puppet_team_id"
const SOUL_BINDING_MARK_META: String = "soul_binding_marked"
const SOUL_BINDING_SOURCE_ID_META: String = "soul_binding_source_unit_id"
const SOUL_BINDING_TEAM_ID_META: String = "soul_binding_team_id"
const SOUL_BINDING_EXPIRES_AT_META: String = "soul_binding_expires_at"

const SKELETON_SUMMON_DATA: Resource = preload("res://data/summons/skeleton.tres")
const PUPPET_SUMMON_DATA: Resource = preload("res://data/summons/puppet.tres")
const SOUL_PUPPET_SUMMON_DATA: Resource = preload("res://data/summons/soul_puppet.tres")
const GIANT_MAGGOT_UNIT_DATA: Resource = preload("res://data/enemies/giant_maggot.tres")
const GIANT_SLIME_UNIT_DATA: Resource = preload("res://data/enemies/giant_slime.tres")

const PASSIVE_MAGGOT_DEATH_BURST: String = "maggot_death_burst"
const PASSIVE_AMALGAM_SPLIT_BIRTH: String = "amalgam_split_birth"
const PASSIVE_FROST_BURST: String = "frost_burst"
const PASSIVE_FLAME_BURST: String = "flame_burst"
const PASSIVE_VENOM_POOL: String = "venom_pool"
const PASSIVE_SLIME_SPLIT: String = "slime_split"
const SLIME_SPLIT_COUNT_META: String = "slime_split_count"

var battle_manager_ref: WeakRef = null
var active_unit_summons_by_source: Dictionary = {}
var active_relic_summons_by_source: Dictionary = {}
var timed_summons: Dictionary = {}


func setup(battle_manager_value: Variant) -> void:
	battle_manager_ref = weakref(battle_manager_value)


func clear() -> void:
	active_unit_summons_by_source.clear()
	active_relic_summons_by_source.clear()
	timed_summons.clear()


func update(delta: float) -> void:
	if delta <= 0.0 or timed_summons.is_empty():
		return

	var expired_ids: Array[int] = []
	for summon_id: Variant in timed_summons.keys():
		var entry: Dictionary = timed_summons[summon_id] as Dictionary
		var remaining: float = float(entry.get("remaining", 0.0)) - delta
		entry["remaining"] = remaining
		timed_summons[summon_id] = entry
		if remaining <= 0.0:
			expired_ids.append(int(summon_id))

	for summon_id: int in expired_ids:
		var entry: Dictionary = timed_summons.get(summon_id, {}) as Dictionary
		timed_summons.erase(summon_id)
		var unit_value: Variant = entry.get("unit", null)
		if _is_alive_unit(unit_value):
			var unit: Unit = unit_value as Unit
			_unregister_summon(unit)
			var battle_manager: Variant = _get_battle_manager()
			if battle_manager != null and battle_manager.has_method("remove_summoned_unit"):
				battle_manager.remove_summoned_unit(unit)


func summon_units(source_unit: Unit, summon_unit_data: Resource, count: int, context: Dictionary = {}) -> Array[Unit]:
	var summoned_units: Array[Unit] = []
	if summon_unit_data == null or count <= 0:
		return summoned_units

	var battle_manager: Variant = _get_battle_manager()
	if battle_manager == null or not battle_manager.has_method("spawn_summoned_unit"):
		return summoned_units

	var source_type: String = str(context.get("source_type", SOURCE_TYPE_UNIT))
	var source_key: String = _get_source_key(source_unit, source_type, context)
	if source_key == "":
		return summoned_units

	var allowed_count: int = _get_allowed_count(source_unit, source_type, source_key, count, context)
	if allowed_count <= 0:
		return summoned_units

	for index: int in range(allowed_count):
		var spawn_position: Vector2 = _resolve_spawn_position(source_unit, context, index)
		var spawn_context: Dictionary = context.duplicate(true)
		spawn_context["source_type"] = source_type
		spawn_context["source_key"] = source_key
		if not spawn_context.has("summon_star"):
			spawn_context["summon_star"] = source_unit.star if source_unit != null and is_instance_valid(source_unit) else 1
		var summoned_unit: Unit = battle_manager.spawn_summoned_unit(source_unit, summon_unit_data, spawn_position, spawn_context)
		if summoned_unit == null:
			continue

		_register_summon(source_type, source_key, summoned_unit, source_unit, context)
		summoned_units.append(summoned_unit)

	return summoned_units


func handle_unit_death(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var passive_id: String = str(unit.passive_id)
	if is_summon(unit):
		_unregister_summon(unit)
		if passive_id != PASSIVE_SLIME_SPLIT:
			return

	match passive_id:
		PASSIVE_MAGGOT_DEATH_BURST:
			if unit.unit_skill != null and unit.unit_skill.has_method("apply_maggot_death_burst"):
				unit.unit_skill.apply_maggot_death_burst(unit)
		PASSIVE_FROST_BURST:
			if unit.unit_skill != null and unit.unit_skill.has_method("apply_frost_slime_death_burst"):
				unit.unit_skill.apply_frost_slime_death_burst(unit)
		PASSIVE_FLAME_BURST:
			if unit.unit_skill != null and unit.unit_skill.has_method("apply_flame_slime_death_burst"):
				unit.unit_skill.apply_flame_slime_death_burst(unit)
		PASSIVE_VENOM_POOL:
			if unit.unit_skill != null and unit.unit_skill.has_method("apply_venom_slime_death_pool"):
				unit.unit_skill.apply_venom_slime_death_pool(unit)
		PASSIVE_AMALGAM_SPLIT_BIRTH:
			var maggot_context: Dictionary = {
				"source_type": SOURCE_TYPE_UNIT,
				"position": unit.position,
				"ignore_source_alive": true,
				"summon_cap": 4,
			}
			summon_units(unit, GIANT_MAGGOT_UNIT_DATA, 4, maggot_context)
		PASSIVE_ENEMY_DEATH_SUMMONS_SKELETONS:
			var context: Dictionary = {
				"source_type": SOURCE_TYPE_UNIT,
				"position": unit.position,
				"ignore_source_alive": true,
			}
			summon_units(unit, SKELETON_SUMMON_DATA, 2, context)
		PASSIVE_SLIME_SPLIT:
			_handle_slime_split(unit)

func handle_unit_killed_target(attacker: Unit, target: Unit) -> void:
	if attacker != null and is_instance_valid(attacker) and str(attacker.passive_id) == PASSIVE_ENEMY_KILL_SUMMONS_SKELETONS:
		var kill_context: Dictionary = {
			"source_type": SOURCE_TYPE_UNIT,
			"position": target.position if target != null and is_instance_valid(target) else attacker.position,
		}
		summon_units(attacker, SKELETON_SUMMON_DATA, 1, kill_context)

	if target == null or not is_instance_valid(target):
		return

	_handle_soul_binding_death(target)

	if not bool(target.get_meta(PUPPET_MARK_META, false)):
		return

	var source_unit_id: int = int(target.get_meta(PUPPET_MARK_SOURCE_ID_META, -1))
	var source_team_id: int = int(target.get_meta(PUPPET_MARK_TEAM_ID_META, -1))
	var source_unit: Unit = _find_alive_unit_by_id(source_unit_id)
	if source_unit == null or source_unit.team_id != source_team_id:
		return

	var puppet_context: Dictionary = {
		"source_type": SOURCE_TYPE_UNIT,
		"position": target.position,
	}
	summon_units(source_unit, PUPPET_SUMMON_DATA, 1, puppet_context)


func _handle_soul_binding_death(target: Unit) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not bool(target.get_meta(SOUL_BINDING_MARK_META, false)):
		return

	var expires_at: float = float(target.get_meta(SOUL_BINDING_EXPIRES_AT_META, INF))
	if float(target.battle_elapsed_time) > expires_at:
		return

	var source_unit_id: int = int(target.get_meta(SOUL_BINDING_SOURCE_ID_META, -1))
	var source_team_id: int = int(target.get_meta(SOUL_BINDING_TEAM_ID_META, -1))
	var source_unit: Unit = _find_alive_unit_by_id(source_unit_id)
	if source_unit == null or source_unit.team_id != source_team_id:
		return

	var inherit_ratio: float = 1.0 if int(source_unit.star) >= 3 else 0.5
	var context: Dictionary = {
		"source_type": SOURCE_TYPE_UNIT,
		"position": target.position,
		"bonus_max_hp": int(round(float(target.max_hp) * inherit_ratio)),
		"bonus_attack_damage": int(round(float(target.attack_damage) * inherit_ratio)),
	}
	if int(source_unit.star) >= 3:
		context["initial_shield"] = 50
	summon_units(source_unit, SOUL_PUPPET_SUMMON_DATA, 1, context)


func is_summon(unit: Unit) -> bool:
	return unit != null and is_instance_valid(unit) and bool(unit.get_meta(META_IS_SUMMON, false))


func get_unit_summon_cap(source_unit: Unit) -> int:
	if source_unit == null or not is_instance_valid(source_unit):
		return DEFAULT_UNIT_SUMMON_CAP

	var cap: int = int(source_unit.get_meta("summon_cap", DEFAULT_UNIT_SUMMON_CAP))
	if str(source_unit.passive_id) == PASSIVE_GRAVE_COMMAND:
		cap += _get_grave_command_cap_bonus(source_unit)

	cap += int(source_unit.get_meta("summon_cap_bonus", 0))
	return maxi(0, cap)


func _get_grave_command_cap_bonus(source_unit: Unit) -> int:
	var star: int = clampi(source_unit.star, 1, 3)
	match star:
		3:
			return 5
		2:
			return 3
		_:
			return 1


func mark_puppet_target(source_unit: Unit, target: Unit) -> bool:
	if source_unit == null or target == null:
		return false
	if not is_instance_valid(source_unit) or not is_instance_valid(target):
		return false
	if not source_unit.is_alive or not target.is_alive:
		return false

	target.set_meta(PUPPET_MARK_META, true)
	target.set_meta(PUPPET_MARK_SOURCE_ID_META, source_unit.unit_id)
	target.set_meta(PUPPET_MARK_TEAM_ID_META, source_unit.team_id)
	return true


func _get_allowed_count(source_unit: Unit, source_type: String, source_key: String, requested_count: int, context: Dictionary) -> int:
	var active_summons: Array[Unit] = _get_active_summons(source_type, source_key)
	var cap: int = int(context.get("summon_cap", get_unit_summon_cap(source_unit)))
	if source_type == SOURCE_TYPE_RELIC:
		cap = int(context.get("summon_cap", requested_count))

	if cap <= 0:
		return 0

	return clampi(requested_count, 0, maxi(0, cap - active_summons.size()))


func _register_summon(source_type: String, source_key: String, summoned_unit: Unit, source_unit: Unit, context: Dictionary) -> void:
	var summon_list: Array[Unit] = _get_active_summons(source_type, source_key)
	summon_list.append(summoned_unit)
	_set_active_summons(source_type, source_key, summon_list)

	summoned_unit.set_meta(META_IS_SUMMON, true)
	summoned_unit.set_meta(META_SUMMON_SOURCE_TYPE, source_type)
	summoned_unit.set_meta(META_SUMMON_SOURCE_KEY, source_key)
	summoned_unit.set_meta(META_SUMMON_AFFECTS_RESULT, bool(context.get("affects_battle_result", true)))
	if source_unit != null and is_instance_valid(source_unit):
		summoned_unit.set_meta(META_SUMMON_SOURCE_UNIT_ID, source_unit.unit_id)
	var relic_id: String = str(context.get("relic_id", ""))
	if relic_id != "":
		summoned_unit.set_meta(META_SUMMON_RELIC_ID, relic_id)
	if context.has(SLIME_SPLIT_COUNT_META):
		summoned_unit.set_meta(SLIME_SPLIT_COUNT_META, int(context.get(SLIME_SPLIT_COUNT_META, 0)))

	var duration: float = float(context.get("duration", -1.0))
	if duration > 0.0:
		timed_summons[summoned_unit.unit_id] = {
			"unit": summoned_unit,
			"remaining": duration,
		}


func _handle_slime_split(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var split_count: int = int(unit.get_meta(SLIME_SPLIT_COUNT_META, 0))
	var max_split_count: int = 3 if int(unit.star) >= 3 else 2
	if split_count >= max_split_count:
		return

	var hp_ratio: float = 0.40 if int(unit.star) >= 3 else 0.30
	var child_split_count: int = split_count + 1
	var child_max_hp: int = maxi(1, int(round(float(unit.max_hp) * hp_ratio)))
	var child_attack: int = maxi(1, int(round(float(unit.attack_damage) * 0.5)))
	var child_defense: int = maxi(0, int(round(float(unit.defense) * 0.5)))
	var context: Dictionary = {
		"source_type": SOURCE_TYPE_UNIT,
		"position": unit.position,
		"ignore_source_alive": true,
		"summon_cap": 2,
		"summon_star": unit.star,
		"team_id": unit.team_id,
		"override_max_hp": child_max_hp,
		"override_attack_damage": child_attack,
		"override_defense": child_defense,
		"display_name": unit.display_name,
		SLIME_SPLIT_COUNT_META: child_split_count,
	}
	summon_units(unit, GIANT_SLIME_UNIT_DATA, 2, context)


func _unregister_summon(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var source_type: String = str(unit.get_meta(META_SUMMON_SOURCE_TYPE, SOURCE_TYPE_UNIT))
	var source_key: String = str(unit.get_meta(META_SUMMON_SOURCE_KEY, ""))
	if source_key == "":
		return

	var summon_list: Array[Unit] = _get_active_summons(source_type, source_key)
	for index: int in range(summon_list.size() - 1, -1, -1):
		var summon_value: Variant = summon_list[index]
		if summon_value == unit or not _is_alive_unit(summon_value):
			summon_list.remove_at(index)

	_set_active_summons(source_type, source_key, summon_list)
	timed_summons.erase(unit.unit_id)


func _get_active_summons(source_type: String, source_key: String) -> Array[Unit]:
	var source_map: Dictionary = active_relic_summons_by_source if source_type == SOURCE_TYPE_RELIC else active_unit_summons_by_source
	var summon_list: Array[Unit] = []
	if source_map.has(source_key):
		var stored_summons: Array = source_map[source_key] as Array
		for stored_summon: Variant in stored_summons:
			if not _is_alive_unit(stored_summon):
				continue

			summon_list.append(stored_summon as Unit)

	for index: int in range(summon_list.size() - 1, -1, -1):
		var summon_value: Variant = summon_list[index]
		if not _is_alive_unit(summon_value):
			summon_list.remove_at(index)

	_set_active_summons(source_type, source_key, summon_list)
	return summon_list


func _set_active_summons(source_type: String, source_key: String, summon_list: Array[Unit]) -> void:
	if source_type == SOURCE_TYPE_RELIC:
		active_relic_summons_by_source[source_key] = summon_list
	else:
		active_unit_summons_by_source[source_key] = summon_list


func _get_source_key(source_unit: Unit, source_type: String, context: Dictionary) -> String:
	var configured_key: String = str(context.get("source_key", ""))
	if configured_key != "":
		return configured_key

	if source_type == SOURCE_TYPE_RELIC:
		var relic_id: String = str(context.get("relic_id", "relic"))
		var team_id: int = int(context.get("team_id", source_unit.team_id if source_unit != null and is_instance_valid(source_unit) else 1))
		return SOURCE_TYPE_RELIC + ":" + str(team_id) + ":" + relic_id

	if source_unit == null or not is_instance_valid(source_unit):
		return ""

	return SOURCE_TYPE_UNIT + ":" + str(source_unit.unit_id)


func _resolve_spawn_position(source_unit: Unit, context: Dictionary, index: int) -> Vector2:
	var has_explicit_position: bool = context.has("position")
	var base_position: Vector2 = context.get("position", Vector2.ZERO) as Vector2
	if not has_explicit_position and source_unit != null and is_instance_valid(source_unit):
		base_position = source_unit.position

	var team_id: int = int(context.get("team_id", source_unit.team_id if source_unit != null and is_instance_valid(source_unit) else 1))
	var direction: float = 1.0 if team_id == 1 else -1.0
	var radius: float = maxf(8.0, float(context.get("spawn_radius", DEFAULT_SPAWN_RADIUS)))
	var offsets: Array[Vector2] = []
	if has_explicit_position:
		offsets = [
			Vector2.ZERO,
			Vector2(0.0, -radius),
			Vector2(0.0, radius),
			Vector2(radius * direction, 0.0),
			Vector2(-radius * direction, 0.0),
		]
	else:
		offsets = [
			Vector2(radius * direction, 0.0),
			Vector2(radius * direction, -radius),
			Vector2(radius * direction, radius),
			Vector2(radius * 2.0 * direction, 0.0),
			Vector2(0.0, -radius),
			Vector2(0.0, radius),
		]

	return base_position + offsets[index % offsets.size()]


func _find_alive_unit_by_id(unit_id: int) -> Unit:
	var battle_manager: Variant = _get_battle_manager()
	if battle_manager == null or not battle_manager.has_method("get_all_units"):
		return null

	for unit_value: Variant in battle_manager.get_all_units():
		if not _is_alive_unit(unit_value):
			continue

		var unit: Unit = unit_value as Unit
		if unit.unit_id == unit_id:
			return unit

	return null


func _is_alive_unit(unit_value: Variant) -> bool:
	if unit_value == null or not is_instance_valid(unit_value):
		return false

	var unit: Unit = unit_value as Unit
	return unit != null and unit.is_alive


func _get_battle_manager() -> Variant:
	if battle_manager_ref == null:
		return null

	return battle_manager_ref.get_ref()
