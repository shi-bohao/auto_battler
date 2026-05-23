class_name UnitEffectController
extends RefCounted

const STATUS_EFFECT_SCRIPT: Script = preload("res://scripts/status_effect.gd")

const SOURCE_MODE_GLOBAL: String = "GLOBAL"
const SOURCE_MODE_PER_SOURCE: String = "PER_SOURCE"

const OVERFLOW_DROP_NEW: String = "DROP_NEW"
const OVERFLOW_REFRESH_OLDEST: String = "REFRESH_OLDEST"
const OVERFLOW_REPLACE_OLDEST: String = "REPLACE_OLDEST"
const OVERFLOW_REPLACE_WEAKEST: String = "REPLACE_WEAKEST"

var effects: Array[StatusEffect] = []
var next_stack_instance_id: int = 1


func apply_effect(target_unit: Variant, effect_data: Dictionary) -> StatusEffect:
	if not _is_valid_unit(target_unit):
		return null

	effect_data = effect_data.duplicate(true)
	var effect_id: String = str(effect_data.get("effect_id", ""))
	if effect_id.strip_edges() == "":
		push_warning("Status effect missing effect_id.")
		return null

	effect_data["target_unit"] = target_unit
	_normalize_effect_data(effect_data)

	var stack_policy: String = str(effect_data.get("stack_policy", StatusEffect.STACK_POLICY_REFRESH_ONLY))
	match stack_policy:
		StatusEffect.STACK_POLICY_IGNORE_IF_ACTIVE:
			return _apply_ignore_if_active(effect_data)
		StatusEffect.STACK_POLICY_EXTEND_DURATION:
			return _apply_extend_duration(effect_data)
		StatusEffect.STACK_POLICY_STACK_REFRESH_DURATION, \
		StatusEffect.STACK_POLICY_STACK_INDEPENDENT_DURATION, \
		StatusEffect.STACK_POLICY_STACK_PER_SOURCE_CAP_REFRESH, \
		StatusEffect.STACK_POLICY_STACK_PER_SOURCE_CAP_INDEPENDENT, \
		StatusEffect.STACK_POLICY_PERMANENT_STACK:
			return _apply_stack_effect(effect_data)
		StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH, \
		StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_INDEPENDENT:
			return _apply_refresh_only(effect_data)
		StatusEffect.STACK_POLICY_STRONGEST_WINS:
			return _apply_strongest_wins(effect_data)
		_:
			return _apply_refresh_only(effect_data)


func update_effects(target_unit: Variant, delta: float) -> void:
	if effects.is_empty():
		return

	var effects_to_update: Array[StatusEffect] = effects.duplicate()
	for effect: StatusEffect in effects_to_update:
		if effect == null or effect.is_expired:
			continue

		if not effects.has(effect):
			continue

		effect.update(delta)

	_remove_expired_effects()


func clear_effects(_target_unit: Variant) -> void:
	for effect: StatusEffect in effects:
		if effect != null:
			effect.expire()

	effects.clear()


func remove_effects_by_id(effect_id: String) -> int:
	var removed_count: int = 0
	for index: int in range(effects.size() - 1, -1, -1):
		var effect: StatusEffect = effects[index]
		if effect == null:
			effects.remove_at(index)
			continue

		if effect.effect_id != effect_id:
			continue

		effect.expire()
		effects.remove_at(index)
		removed_count += 1

	return removed_count


func _remove_expired_effects() -> void:
	for index: int in range(effects.size() - 1, -1, -1):
		var effect: StatusEffect = effects[index]
		if effect == null or effect.is_expired:
			effects.remove_at(index)


func get_debug_lines() -> Array[String]:
	var lines: Array[String] = []
	for effect: StatusEffect in effects:
		if effect != null and not effect.is_expired:
			lines.append(effect.get_debug_text())

	return lines


func has_effect(effect_id: String) -> bool:
	return _find_effect_by_id(effect_id) != null


func get_effect_count(effect_id: String) -> int:
	var count: int = 0
	for effect: StatusEffect in effects:
		if effect != null and not effect.is_expired and effect.effect_id == effect_id:
			count += 1

	return count


func _find_effect_by_id(effect_id: String) -> StatusEffect:
	for effect: StatusEffect in effects:
		if effect != null and not effect.is_expired and effect.effect_id == effect_id:
			return effect

	return null


func _apply_refresh_only(effect_data: Dictionary) -> StatusEffect:
	var group_key: String = str(effect_data.get("stack_group_key", ""))
	var existing_effect: StatusEffect = _find_first_effect_by_group(group_key)
	if existing_effect != null:
		existing_effect.refresh(effect_data)
		return existing_effect

	return _create_effect(effect_data)


func _apply_ignore_if_active(effect_data: Dictionary) -> StatusEffect:
	var group_key: String = str(effect_data.get("stack_group_key", ""))
	var existing_effect: StatusEffect = _find_first_effect_by_group(group_key)
	if existing_effect != null:
		return existing_effect

	return _create_effect(effect_data)


func _apply_extend_duration(effect_data: Dictionary) -> StatusEffect:
	var group_key: String = str(effect_data.get("stack_group_key", ""))
	var existing_effect: StatusEffect = _find_first_effect_by_group(group_key)
	if existing_effect != null:
		existing_effect.extend_duration(effect_data)
		return existing_effect

	return _create_effect(effect_data)


func _apply_stack_effect(effect_data: Dictionary) -> StatusEffect:
	var group_key: String = str(effect_data.get("stack_group_key", ""))
	var group_effects: Array[StatusEffect] = _find_effects_by_group(group_key)
	var cap: int = _get_stack_cap(effect_data)
	if cap >= 0 and group_effects.size() >= cap:
		return _handle_stack_overflow(effect_data, group_effects)

	var effect: StatusEffect = _create_effect(effect_data)
	if _policy_refreshes_group_duration(str(effect_data.get("stack_policy", ""))):
		_refresh_group_durations(group_key, effect_data)
	return effect


func _apply_strongest_wins(effect_data: Dictionary) -> StatusEffect:
	var group_key: String = str(effect_data.get("stack_group_key", ""))
	var strongest_effect: StatusEffect = _find_strongest_effect_by_group(group_key)
	if strongest_effect == null:
		return _create_effect(effect_data)

	var new_strength: float = _get_effect_data_strength(effect_data)
	var current_strength: float = _get_effect_strength(strongest_effect)
	if new_strength > current_strength:
		strongest_effect.refresh(effect_data)
	else:
		strongest_effect.refresh_duration(effect_data)
	return strongest_effect


func _handle_stack_overflow(effect_data: Dictionary, group_effects: Array[StatusEffect]) -> StatusEffect:
	if group_effects.is_empty():
		return _create_effect(effect_data)

	var overflow_policy: String = str(effect_data.get("overflow_policy", OVERFLOW_REFRESH_OLDEST))
	match overflow_policy:
		OVERFLOW_DROP_NEW:
			return null
		OVERFLOW_REPLACE_OLDEST:
			var oldest_effect: StatusEffect = group_effects[0]
			_expire_and_remove(oldest_effect)
			var replacement: StatusEffect = _create_effect(effect_data)
			if _policy_refreshes_group_duration(str(effect_data.get("stack_policy", ""))):
				_refresh_group_durations(str(effect_data.get("stack_group_key", "")), effect_data)
			return replacement
		OVERFLOW_REPLACE_WEAKEST:
			var weakest_effect: StatusEffect = _find_weakest_effect(group_effects)
			_expire_and_remove(weakest_effect)
			var stronger_replacement: StatusEffect = _create_effect(effect_data)
			if _policy_refreshes_group_duration(str(effect_data.get("stack_policy", ""))):
				_refresh_group_durations(str(effect_data.get("stack_group_key", "")), effect_data)
			return stronger_replacement
		_:
			var refreshed_effect: StatusEffect = group_effects[0]
			refreshed_effect.refresh(effect_data)
			if _policy_refreshes_group_duration(str(effect_data.get("stack_policy", ""))):
				_refresh_group_durations(str(effect_data.get("stack_group_key", "")), effect_data)
			return refreshed_effect


func _create_effect(effect_data: Dictionary) -> StatusEffect:
	var configured_data: Dictionary = effect_data.duplicate(true)
	configured_data["stack_instance_key"] = str(configured_data.get("stack_group_key", configured_data.get("effect_id", ""))) + "#" + str(next_stack_instance_id)
	next_stack_instance_id += 1

	var effect: StatusEffect = STATUS_EFFECT_SCRIPT.new() as StatusEffect
	effect.setup(configured_data)
	effects.append(effect)
	effect.apply_start()
	return effect


func _normalize_effect_data(effect_data: Dictionary) -> void:
	var effect_id: String = str(effect_data.get("effect_id", ""))
	var stack_policy: String = _normalize_stack_policy(str(effect_data.get("stack_policy", StatusEffect.STACK_POLICY_REFRESH_ONLY)))
	effect_data["stack_policy"] = stack_policy

	var source_key: String = str(effect_data.get("source_key", ""))
	if source_key.strip_edges() == "":
		source_key = _build_source_key(effect_data.get("source_unit", null))
	effect_data["source_key"] = source_key

	var source_mode: String = str(effect_data.get("source_mode", _get_default_source_mode(stack_policy)))
	if source_mode != SOURCE_MODE_PER_SOURCE:
		source_mode = SOURCE_MODE_GLOBAL
	effect_data["source_mode"] = source_mode

	var stack_key: String = str(effect_data.get("stack_key", effect_id))
	if stack_key.strip_edges() == "":
		stack_key = effect_id

	var group_key: String = str(effect_data.get("stack_group_key", ""))
	if group_key.strip_edges() == "":
		group_key = stack_key
		if source_mode == SOURCE_MODE_PER_SOURCE:
			group_key += "|source:" + source_key
	effect_data["stack_group_key"] = group_key

	if not effect_data.has("polarity"):
		effect_data["polarity"] = _infer_polarity(effect_data)
	if not effect_data.has("category"):
		effect_data["category"] = _infer_category(effect_data)

	if stack_policy == StatusEffect.STACK_POLICY_PERMANENT_STACK:
		effect_data["duration_mode"] = StatusEffect.DURATION_MODE_NONE
	elif not effect_data.has("duration_mode") and float(effect_data.get("duration", 0.0)) < 0.0:
		effect_data["duration_mode"] = StatusEffect.DURATION_MODE_NONE


func _normalize_stack_policy(configured_policy: String) -> String:
	match configured_policy:
		StatusEffect.STACK_POLICY_REFRESH_ONLY, \
		StatusEffect.STACK_POLICY_IGNORE_IF_ACTIVE, \
		StatusEffect.STACK_POLICY_EXTEND_DURATION, \
		StatusEffect.STACK_POLICY_STACK_REFRESH_DURATION, \
		StatusEffect.STACK_POLICY_STACK_INDEPENDENT_DURATION, \
		StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH, \
		StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_INDEPENDENT, \
		StatusEffect.STACK_POLICY_STACK_PER_SOURCE_CAP_REFRESH, \
		StatusEffect.STACK_POLICY_STACK_PER_SOURCE_CAP_INDEPENDENT, \
		StatusEffect.STACK_POLICY_PERMANENT_STACK, \
		StatusEffect.STACK_POLICY_STRONGEST_WINS:
			return configured_policy
		_:
			return StatusEffect.STACK_POLICY_REFRESH_ONLY


func _get_default_source_mode(stack_policy: String) -> String:
	match stack_policy:
		StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH, \
		StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_INDEPENDENT, \
		StatusEffect.STACK_POLICY_STACK_PER_SOURCE_CAP_REFRESH, \
		StatusEffect.STACK_POLICY_STACK_PER_SOURCE_CAP_INDEPENDENT:
			return SOURCE_MODE_PER_SOURCE
		_:
			return SOURCE_MODE_GLOBAL


func _get_stack_cap(effect_data: Dictionary) -> int:
	var stack_policy: String = str(effect_data.get("stack_policy", ""))
	match stack_policy:
		StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH, StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_INDEPENDENT:
			return 1
		StatusEffect.STACK_POLICY_STACK_PER_SOURCE_CAP_REFRESH, StatusEffect.STACK_POLICY_STACK_PER_SOURCE_CAP_INDEPENDENT:
			return int(effect_data.get("max_stacks_per_source", 3))
		_:
			return int(effect_data.get("max_stacks", -1))


func _policy_refreshes_group_duration(stack_policy: String) -> bool:
	return stack_policy == StatusEffect.STACK_POLICY_STACK_REFRESH_DURATION \
		or stack_policy == StatusEffect.STACK_POLICY_STACK_PER_SOURCE_CAP_REFRESH


func _refresh_group_durations(group_key: String, effect_data: Dictionary) -> void:
	for effect: StatusEffect in _find_effects_by_group(group_key):
		effect.refresh_duration(effect_data)


func _find_first_effect_by_group(group_key: String) -> StatusEffect:
	for effect: StatusEffect in effects:
		if effect != null and not effect.is_expired and effect.stack_group_key == group_key:
			return effect

	return null


func _find_effects_by_group(group_key: String) -> Array[StatusEffect]:
	var group_effects: Array[StatusEffect] = []
	for effect: StatusEffect in effects:
		if effect != null and not effect.is_expired and effect.stack_group_key == group_key:
			group_effects.append(effect)

	return group_effects


func _find_strongest_effect_by_group(group_key: String) -> StatusEffect:
	var strongest_effect: StatusEffect = null
	var strongest_value: float = -INF
	for effect: StatusEffect in _find_effects_by_group(group_key):
		var strength: float = _get_effect_strength(effect)
		if strongest_effect == null or strength > strongest_value:
			strongest_effect = effect
			strongest_value = strength

	return strongest_effect


func _find_weakest_effect(group_effects: Array[StatusEffect]) -> StatusEffect:
	var weakest_effect: StatusEffect = null
	var weakest_value: float = INF
	for effect: StatusEffect in group_effects:
		if effect == null or effect.is_expired:
			continue

		var strength: float = _get_effect_strength(effect)
		if weakest_effect == null or strength < weakest_value:
			weakest_effect = effect
			weakest_value = strength

	return weakest_effect


func _get_effect_strength(effect: StatusEffect) -> float:
	if effect == null:
		return 0.0

	match effect.effect_type:
		StatusEffect.EFFECT_STAT_MULTIPLY:
			return absf(float(effect.value) - 1.0)
		_:
			return absf(float(effect.value))


func _get_effect_data_strength(effect_data: Dictionary) -> float:
	if effect_data.has("value_strength"):
		return absf(float(effect_data.get("value_strength", 0.0)))

	var effect_type: String = str(effect_data.get("effect_type", ""))
	var value: float = float(effect_data.get("value", 0.0))
	match effect_type:
		StatusEffect.EFFECT_STAT_MULTIPLY:
			return absf(value - 1.0)
		_:
			return absf(value)


func _expire_and_remove(effect: StatusEffect) -> void:
	if effect == null:
		return

	effect.expire()
	effects.erase(effect)


func _build_source_key(source_unit: Variant) -> String:
	if source_unit != null and is_instance_valid(source_unit):
		var unit_id_value: Variant = source_unit.get("unit_id")
		if unit_id_value != null:
			return "unit:" + str(int(unit_id_value))

		return "object:" + str(source_unit.get_instance_id())

	return "none"


func _infer_category(effect_data: Dictionary) -> String:
	match str(effect_data.get("effect_type", "")):
		StatusEffect.EFFECT_HEAL_OVER_TIME:
			return StatusEffect.CATEGORY_HOT
		StatusEffect.EFFECT_DAMAGE_OVER_TIME:
			return StatusEffect.CATEGORY_DOT
		StatusEffect.EFFECT_STAT_ADD, StatusEffect.EFFECT_STAT_MULTIPLY:
			return StatusEffect.CATEGORY_STAT
		_:
			return StatusEffect.CATEGORY_NONE


func _infer_polarity(effect_data: Dictionary) -> String:
	var effect_type: String = str(effect_data.get("effect_type", ""))
	match effect_type:
		StatusEffect.EFFECT_HEAL_OVER_TIME:
			return StatusEffect.POLARITY_POSITIVE
		StatusEffect.EFFECT_DAMAGE_OVER_TIME:
			return StatusEffect.POLARITY_NEGATIVE
		StatusEffect.EFFECT_STAT_ADD:
			return _infer_stat_add_polarity(str(effect_data.get("stat_name", "")), float(effect_data.get("value", 0.0)))
		StatusEffect.EFFECT_STAT_MULTIPLY:
			return _infer_stat_multiply_polarity(str(effect_data.get("stat_name", "")), float(effect_data.get("value", 0.0)))
		_:
			return StatusEffect.POLARITY_NEUTRAL


func _infer_stat_add_polarity(stat_name: String, value: float) -> String:
	if is_zero_approx(value):
		return StatusEffect.POLARITY_NEUTRAL

	match stat_name:
		"attack_interval":
			return StatusEffect.POLARITY_NEGATIVE if value > 0.0 else StatusEffect.POLARITY_POSITIVE
		"damage_taken_multiplier":
			return StatusEffect.POLARITY_NEGATIVE if value > 0.0 else StatusEffect.POLARITY_POSITIVE
		_:
			return StatusEffect.POLARITY_POSITIVE if value > 0.0 else StatusEffect.POLARITY_NEGATIVE


func _infer_stat_multiply_polarity(stat_name: String, value: float) -> String:
	if is_equal_approx(value, 1.0):
		return StatusEffect.POLARITY_NEUTRAL

	match stat_name:
		"attack_interval":
			return StatusEffect.POLARITY_POSITIVE if value < 1.0 else StatusEffect.POLARITY_NEGATIVE
		"damage_taken_multiplier":
			return StatusEffect.POLARITY_NEGATIVE if value > 1.0 else StatusEffect.POLARITY_POSITIVE
		_:
			return StatusEffect.POLARITY_POSITIVE if value > 1.0 else StatusEffect.POLARITY_NEGATIVE


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)
