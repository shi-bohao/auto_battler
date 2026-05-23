class_name StatusEffect
extends RefCounted

const EFFECT_HEAL_OVER_TIME: String = "HEAL_OVER_TIME"
const EFFECT_DAMAGE_OVER_TIME: String = "DAMAGE_OVER_TIME"
const EFFECT_STAT_ADD: String = "STAT_ADD"
const EFFECT_STAT_MULTIPLY: String = "STAT_MULTIPLY"

const POLARITY_AUTO: String = "AUTO"
const POLARITY_POSITIVE: String = "POSITIVE"
const POLARITY_NEGATIVE: String = "NEGATIVE"
const POLARITY_NEUTRAL: String = "NEUTRAL"

const CATEGORY_NONE: String = "NONE"
const CATEGORY_DOT: String = "DOT"
const CATEGORY_HOT: String = "HOT"
const CATEGORY_STAT: String = "STAT"
const CATEGORY_MARK: String = "MARK"
const CATEGORY_AURA: String = "AURA"

const DURATION_MODE_TIMED: String = "TIMED"
const DURATION_MODE_NONE: String = "NONE"
const DURATION_MODE_BATTLE: String = "BATTLE"

const STACK_POLICY_REFRESH_ONLY: String = "REFRESH_ONLY"
const STACK_POLICY_IGNORE_IF_ACTIVE: String = "IGNORE_IF_ACTIVE"
const STACK_POLICY_EXTEND_DURATION: String = "EXTEND_DURATION"
const STACK_POLICY_STACK_REFRESH_DURATION: String = "STACK_REFRESH_DURATION"
const STACK_POLICY_STACK_INDEPENDENT_DURATION: String = "STACK_INDEPENDENT_DURATION"
const STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH: String = "UNIQUE_PER_SOURCE_REFRESH"
const STACK_POLICY_UNIQUE_PER_SOURCE_INDEPENDENT: String = "UNIQUE_PER_SOURCE_INDEPENDENT"
const STACK_POLICY_STACK_PER_SOURCE_CAP_REFRESH: String = "STACK_PER_SOURCE_CAP_REFRESH"
const STACK_POLICY_STACK_PER_SOURCE_CAP_INDEPENDENT: String = "STACK_PER_SOURCE_CAP_INDEPENDENT"
const STACK_POLICY_PERMANENT_STACK: String = "PERMANENT_STACK"
const STACK_POLICY_STRONGEST_WINS: String = "STRONGEST_WINS"

var effect_id: String = ""
var effect_type: String = ""
var source_unit: Variant = null
var target_unit: Variant = null
var source_key: String = ""
var stack_group_key: String = ""
var stack_instance_key: String = ""
var stack_policy: String = STACK_POLICY_REFRESH_ONLY
var polarity: String = POLARITY_AUTO
var category: String = CATEGORY_NONE
var duration_mode: String = DURATION_MODE_TIMED
var duration: float = 0.0
var remaining_time: float = 0.0
var tick_interval: float = 0.0
var tick_timer: float = 0.0
var value: float = 0.0
var stat_name: String = ""
var is_expired: bool = false
var tick_values: Array[int] = []
var next_tick_index: int = 0

var _is_stat_applied: bool = false
var _applied_value: float = 0.0
var _applied_stat_name: String = ""
var _applied_effect_type: String = ""


func setup(effect_data: Dictionary) -> void:
	effect_id = str(effect_data.get("effect_id", ""))
	effect_type = str(effect_data.get("effect_type", ""))
	source_unit = effect_data.get("source_unit", null)
	target_unit = effect_data.get("target_unit", null)
	source_key = str(effect_data.get("source_key", ""))
	stack_group_key = str(effect_data.get("stack_group_key", effect_id))
	stack_instance_key = str(effect_data.get("stack_instance_key", stack_group_key))
	stack_policy = str(effect_data.get("stack_policy", STACK_POLICY_REFRESH_ONLY))
	polarity = _resolve_polarity(str(effect_data.get("polarity", POLARITY_AUTO)))
	category = str(effect_data.get("category", _infer_category()))
	duration_mode = _resolve_duration_mode(effect_data, DURATION_MODE_TIMED)
	tick_interval = maxf(0.0, float(effect_data.get("tick_interval", 0.0)))
	tick_timer = 0.0
	value = float(effect_data.get("value", 0.0))
	stat_name = str(effect_data.get("stat_name", ""))
	duration = _get_adjusted_duration(maxf(0.0, float(effect_data.get("duration", 0.0))))
	remaining_time = duration
	tick_values = _get_tick_values(effect_data)
	next_tick_index = 0
	is_expired = false


func apply_start() -> void:
	if is_expired or not _is_valid_unit(target_unit):
		is_expired = true
		return

	match effect_type:
		EFFECT_STAT_ADD, EFFECT_STAT_MULTIPLY:
			_apply_stat_modifier()


func refresh(effect_data: Dictionary) -> void:
	if is_expired:
		return

	if effect_type == EFFECT_STAT_ADD or effect_type == EFFECT_STAT_MULTIPLY:
		_remove_stat_modifier()

	effect_type = str(effect_data.get("effect_type", effect_type))
	source_unit = effect_data.get("source_unit", source_unit)
	target_unit = effect_data.get("target_unit", target_unit)
	source_key = str(effect_data.get("source_key", source_key))
	stack_group_key = str(effect_data.get("stack_group_key", stack_group_key))
	stack_instance_key = str(effect_data.get("stack_instance_key", stack_instance_key))
	stack_policy = str(effect_data.get("stack_policy", stack_policy))
	polarity = _resolve_polarity(str(effect_data.get("polarity", polarity)))
	category = str(effect_data.get("category", category))
	duration_mode = _resolve_duration_mode(effect_data, duration_mode)
	value = float(effect_data.get("value", value))
	stat_name = str(effect_data.get("stat_name", stat_name))
	duration = _get_adjusted_duration(maxf(0.0, float(effect_data.get("duration", duration))))
	remaining_time = duration
	tick_interval = maxf(0.0, float(effect_data.get("tick_interval", tick_interval)))
	if tick_interval <= 0.0:
		tick_timer = 0.0
	else:
		tick_timer = clampf(tick_timer, 0.0, tick_interval)
	tick_values = _get_tick_values(effect_data)
	next_tick_index = 0

	if effect_type == EFFECT_STAT_ADD or effect_type == EFFECT_STAT_MULTIPLY:
		_apply_stat_modifier()


func refresh_duration(effect_data: Dictionary) -> void:
	if is_expired:
		return

	duration_mode = _resolve_duration_mode(effect_data, duration_mode)
	if not _uses_timed_duration():
		return

	duration = _get_adjusted_duration(maxf(0.0, float(effect_data.get("duration", duration))))
	remaining_time = duration
	tick_interval = maxf(0.0, float(effect_data.get("tick_interval", tick_interval)))
	if tick_interval <= 0.0:
		tick_timer = 0.0
	else:
		tick_timer = clampf(tick_timer, 0.0, tick_interval)


func extend_duration(effect_data: Dictionary) -> void:
	if is_expired:
		return

	duration_mode = _resolve_duration_mode(effect_data, duration_mode)
	if not _uses_timed_duration():
		return

	var additional_duration: float = _get_adjusted_duration(maxf(0.0, float(effect_data.get("duration", 0.0))))
	if additional_duration <= 0.0:
		return

	var max_duration: float = float(effect_data.get("max_duration", -1.0))
	remaining_time += additional_duration
	if max_duration > 0.0:
		remaining_time = minf(remaining_time, max_duration)
	duration = maxf(duration, remaining_time)


func update(delta: float) -> void:
	if is_expired:
		return

	if not _is_valid_unit(target_unit) or not bool(target_unit.is_alive):
		expire()
		return

	if _uses_timed_duration() and duration <= 0.0:
		expire()
		return

	match effect_type:
		EFFECT_HEAL_OVER_TIME, EFFECT_DAMAGE_OVER_TIME:
			_update_tick_effect(delta)

	if not _uses_timed_duration():
		return

	remaining_time -= delta
	if remaining_time <= 0.0:
		expire()


func expire() -> void:
	if is_expired:
		return

	_remove_stat_modifier()
	is_expired = true
	if _is_valid_unit(target_unit):
		target_unit.update_info_display()


func get_debug_text() -> String:
	var remaining_text: String = "%0.1f" % maxf(remaining_time, 0.0)
	if not _uses_timed_duration():
		remaining_text = "battle"
	var value_text: String = str(value)
	if not tick_values.is_empty():
		value_text = _format_tick_values()
	if stat_name.strip_edges() == "":
		return effect_id + " " + effect_type + " " + value_text + " (" + remaining_text + "s)"

	return effect_id + " " + effect_type + " " + stat_name + " " + value_text + " (" + remaining_text + "s)"


func _update_tick_effect(delta: float) -> void:
	if tick_interval <= 0.0:
		return

	tick_timer += delta
	while tick_timer >= tick_interval and not is_expired:
		tick_timer -= tick_interval
		_apply_tick()
		if not _is_valid_unit(target_unit) or not bool(target_unit.is_alive):
			expire()
			return


func _apply_tick() -> void:
	var tick_value: int = _get_current_tick_value()
	if tick_value <= 0:
		return

	match effect_type:
		EFFECT_HEAL_OVER_TIME:
			target_unit.heal(tick_value, _get_valid_source_or_target())
		EFFECT_DAMAGE_OVER_TIME:
			target_unit.take_damage(tick_value, _get_valid_source_or_null(), false)


func _get_current_tick_value() -> int:
	if not tick_values.is_empty():
		if next_tick_index >= tick_values.size():
			return 0

		var tick_value: int = maxi(0, int(tick_values[next_tick_index]))
		next_tick_index += 1
		return tick_value

	return maxi(1, int(round(value)))


func _get_tick_values(effect_data: Dictionary) -> Array[int]:
	var values: Array[int] = []
	var configured_values: Variant = effect_data.get("tick_values", [])
	if not (configured_values is Array):
		return values

	for configured_value: Variant in configured_values:
		values.append(maxi(0, int(configured_value)))

	return values


func _format_tick_values() -> String:
	var joined_text: String = ""
	for tick_value: int in tick_values:
		if joined_text != "":
			joined_text += ","
		joined_text += str(tick_value)

	return "[" + joined_text + "]"


func _apply_stat_modifier() -> void:
	if _is_stat_applied:
		return

	if stat_name.strip_edges() == "" or not _is_valid_unit(target_unit):
		return

	var current_value: float = _get_stat_value(target_unit, stat_name)
	var new_value: float = current_value
	match effect_type:
		EFFECT_STAT_ADD:
			new_value = current_value + value
		EFFECT_STAT_MULTIPLY:
			new_value = current_value * value
		_:
			return

	_set_stat_value(target_unit, stat_name, new_value)
	_is_stat_applied = true
	_applied_value = value
	_applied_stat_name = stat_name
	_applied_effect_type = effect_type
	target_unit.update_info_display()


func _remove_stat_modifier() -> void:
	if not _is_stat_applied:
		return

	if not _is_valid_unit(target_unit):
		_is_stat_applied = false
		return

	var current_value: float = _get_stat_value(target_unit, _applied_stat_name)
	var restored_value: float = current_value
	match _applied_effect_type:
		EFFECT_STAT_ADD:
			restored_value = current_value - _applied_value
		EFFECT_STAT_MULTIPLY:
			if not is_zero_approx(_applied_value):
				restored_value = current_value / _applied_value

	_set_stat_value(target_unit, _applied_stat_name, restored_value)
	_is_stat_applied = false
	target_unit.update_info_display()


func _get_stat_value(unit: Variant, configured_stat_name: String) -> float:
	match configured_stat_name:
		"defense":
			return float(unit.defense)
		"attack_damage":
			return float(unit.attack_damage)
		"attack_interval":
			return float(unit.attack_interval)
		"mana_regen_per_second":
			return float(unit.mana_regen_per_second)
		"move_speed":
			return float(unit.move_speed)
		"crit_chance":
			return float(unit.crit_chance)
		"crit_damage_multiplier":
			return float(unit.crit_damage_multiplier)
		"active_skill_damage_multiplier":
			return float(unit.active_skill_damage_multiplier)
		"active_heal_multiplier":
			return float(unit.active_heal_multiplier)
		"skill_power":
			return float(unit.skill_power)
		"healing_power":
			return float(unit.healing_power)
		"shield_power":
			return float(unit.shield_power)
		"defense_penetration":
			return float(unit.defense_penetration)
		"life_steal":
			return float(unit.life_steal)
		"damage_reduction":
			return float(unit.damage_reduction)
		"damage_taken_multiplier":
			return float(unit.damage_taken_multiplier)
		"initial_mana":
			return float(unit.initial_mana)
		"mana_on_attack":
			return float(unit.mana_on_attack)
		"mana_on_hit_taken":
			return float(unit.mana_on_hit_taken)
		"status_resistance":
			return float(unit.status_resistance)
		"dodge_chance":
			return float(unit.dodge_chance)
		_:
			push_warning("Unsupported status effect stat: " + configured_stat_name)
			return 0.0


func _set_stat_value(unit: Variant, configured_stat_name: String, configured_value: float) -> void:
	match configured_stat_name:
		"defense":
			unit.defense = maxi(0, int(round(configured_value)))
		"attack_damage":
			unit.attack_damage = maxi(1, int(round(configured_value)))
		"attack_interval":
			unit.attack_interval = maxf(0.05, configured_value)
			unit.attack_cooldown = minf(unit.attack_cooldown, unit.attack_interval)
		"mana_regen_per_second":
			unit.mana_regen_per_second = maxf(0.0, configured_value)
		"move_speed":
			unit.move_speed = maxf(1.0, configured_value)
		"crit_chance":
			unit.crit_chance = clampf(configured_value, 0.0, 1.0)
		"crit_damage_multiplier":
			unit.crit_damage_multiplier = maxf(1.0, configured_value)
		"active_skill_damage_multiplier":
			unit.active_skill_damage_multiplier = maxf(0.0, configured_value)
		"active_heal_multiplier":
			unit.active_heal_multiplier = maxf(0.0, configured_value)
		"skill_power":
			unit.skill_power = maxf(0.0, configured_value)
		"healing_power":
			unit.healing_power = maxf(0.0, configured_value)
		"shield_power":
			unit.shield_power = maxf(0.0, configured_value)
		"defense_penetration":
			unit.defense_penetration = maxi(0, int(round(configured_value)))
		"life_steal":
			unit.life_steal = clampf(configured_value, 0.0, 1.0)
		"damage_reduction":
			unit.damage_reduction = clampf(configured_value, 0.0, 0.95)
		"damage_taken_multiplier":
			unit.damage_taken_multiplier = maxf(0.0, configured_value)
		"initial_mana":
			unit.initial_mana = maxf(0.0, configured_value)
		"mana_on_attack":
			unit.mana_on_attack = maxf(0.0, configured_value)
		"mana_on_hit_taken":
			unit.mana_on_hit_taken = maxf(0.0, configured_value)
		"status_resistance":
			unit.status_resistance = clampf(configured_value, 0.0, 0.95)
		"dodge_chance":
			unit.dodge_chance = clampf(configured_value, 0.0, 0.95)
		_:
			push_warning("Unsupported status effect stat: " + configured_stat_name)


func _get_adjusted_duration(raw_duration: float) -> float:
	if not _uses_timed_duration():
		return raw_duration

	if raw_duration <= 0.0 or not _is_negative_effect():
		return raw_duration

	if not _is_valid_unit(target_unit):
		return raw_duration

	var resistance: float = clampf(float(target_unit.status_resistance), 0.0, 0.95)
	return raw_duration * (1.0 - resistance)


func _is_negative_effect() -> bool:
	match polarity:
		POLARITY_NEGATIVE:
			return true
		POLARITY_POSITIVE, POLARITY_NEUTRAL:
			return false

	if not _is_valid_unit(source_unit) or not _is_valid_unit(target_unit):
		return false

	if int(source_unit.team_id) == int(target_unit.team_id):
		return false

	match effect_type:
		EFFECT_DAMAGE_OVER_TIME:
			return true
		EFFECT_STAT_ADD:
			return _is_stat_add_harmful(stat_name, value)
		EFFECT_STAT_MULTIPLY:
			return _is_stat_multiply_harmful(stat_name, value)
		_:
			return false


func _is_stat_add_harmful(configured_stat_name: String, configured_value: float) -> bool:
	match configured_stat_name:
		"attack_interval":
			return configured_value > 0.0
		_:
			return configured_value < 0.0


func _is_stat_multiply_harmful(configured_stat_name: String, configured_value: float) -> bool:
	match configured_stat_name:
		"attack_interval":
			return configured_value > 1.0
		"damage_taken_multiplier":
			return configured_value > 1.0
		_:
			return configured_value < 1.0


func _get_valid_source_or_target() -> Variant:
	if _is_valid_unit(source_unit):
		return source_unit

	return target_unit


func _get_valid_source_or_null() -> Variant:
	if _is_valid_unit(source_unit):
		return source_unit

	return null


func _resolve_polarity(configured_polarity: String) -> String:
	match configured_polarity:
		POLARITY_POSITIVE, POLARITY_NEGATIVE, POLARITY_NEUTRAL:
			return configured_polarity
		_:
			return POLARITY_AUTO


func _resolve_duration_mode(effect_data: Dictionary, fallback_mode: String) -> String:
	var configured_mode: String = str(effect_data.get("duration_mode", fallback_mode))
	match configured_mode:
		DURATION_MODE_NONE, DURATION_MODE_BATTLE:
			return configured_mode
		DURATION_MODE_TIMED:
			return DURATION_MODE_TIMED
		_:
			return DURATION_MODE_TIMED


func _uses_timed_duration() -> bool:
	return duration_mode == DURATION_MODE_TIMED


func _infer_category() -> String:
	match effect_type:
		EFFECT_HEAL_OVER_TIME:
			return CATEGORY_HOT
		EFFECT_DAMAGE_OVER_TIME:
			return CATEGORY_DOT
		EFFECT_STAT_ADD, EFFECT_STAT_MULTIPLY:
			return CATEGORY_STAT
		_:
			return CATEGORY_NONE


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)
