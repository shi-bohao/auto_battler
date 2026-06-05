class_name StatusEffect
extends RefCounted

const EFFECT_HEAL_OVER_TIME: String = "HEAL_OVER_TIME"
const EFFECT_DAMAGE_OVER_TIME: String = "DAMAGE_OVER_TIME"
const EFFECT_STAT_ADD: String = "STAT_ADD"
const EFFECT_STAT_MULTIPLY: String = "STAT_MULTIPLY"
const EFFECT_CONTROL: String = "CONTROL"

const CATEGORY_NONE: String = "NONE"
const CATEGORY_DOT: String = "DOT"
const CATEGORY_HOT: String = "HOT"
const CATEGORY_STAT: String = "STAT"
const CATEGORY_MARK: String = "MARK"
const CATEGORY_AURA: String = "AURA"
const CATEGORY_CONTROL: String = "CONTROL"

const CONTROL_SLOW: String = "SLOW"
const CONTROL_ROOT: String = "ROOT"
const CONTROL_STUN: String = "STUN"
const CONTROL_FREEZE: String = "FREEZE"
const CONTROL_TAUNT: String = "TAUNT"

const STACK_POLICY_REFRESH_LONGER_DURATION: String = "REFRESH_LONGER_DURATION"
const STACK_POLICY_REPLACE_BY_LAST: String = "REPLACE_BY_LAST"

const POLARITY_AUTO: String = "AUTO"
const POLARITY_POSITIVE: String = "POSITIVE"
const POLARITY_NEGATIVE: String = "NEGATIVE"
const POLARITY_NEUTRAL: String = "NEUTRAL"

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

const VENOM_STACK_EFFECT_ID: String = "venom_stack"
const BURNING_EFFECT_ID: String = "burning"
const DEFAULT_VENOM_STACK_DECAY_PER_TICK: int = 5

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
var stack_count: int = 1
var stack_decay_per_tick: int = 0
var stack_decay_after_duration: bool = false
var is_stack_decaying: bool = false

# Control fields
var control_type: String = ""
var move_speed_multiplier: float = 1.0
var disable_movement: bool = false
var disable_attack: bool = false
var disable_cast: bool = false
var disable_retarget: bool = false
var forced_target: Variant = null
var forced_target_unit_id: int = -1
var skill_damage_taken_multiplier: float = 1.0
var control_priority: int = 0
var control_ui_name: String = ""
var control_ui_color: Color = Color.WHITE

var _is_stat_applied: bool = false
var _applied_value: float = 0.0
var _applied_stat_name: String = ""
var _applied_effect_type: String = ""
var _applied_modifier_id: String = ""


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
	_read_stack_fields(effect_data)
	_read_control_fields(effect_data)
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
	_read_stack_fields(effect_data)
	_read_control_fields(effect_data)
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

	if _is_venom_stack_effect():
		add_venom_stacks(effect_data)
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

	if is_stack_decaying:
		return

	remaining_time -= delta
	if remaining_time <= 0.0:
		if _should_decay_stacks_after_duration():
			remaining_time = 0.0
			is_stack_decaying = true
			if _is_valid_unit(target_unit):
				target_unit.update_info_display()
		else:
			expire()


func expire(should_update_display: bool = true, stat_context: Dictionary = {}) -> void:
	if is_expired:
		return

	_remove_stat_modifier(should_update_display, stat_context)
	is_expired = true
	if should_update_display and _is_valid_unit(target_unit):
		target_unit.update_info_display()


func get_debug_text() -> String:
	var remaining_text: String = "%0.1f" % maxf(remaining_time, 0.0)
	if not _uses_timed_duration():
		remaining_text = "battle"
	var value_text: String = str(value)
	if not tick_values.is_empty():
		value_text = _format_tick_values()
	if effect_type == EFFECT_CONTROL:
		var control_name: String = control_ui_name if control_ui_name.strip_edges() != "" else control_type
		return effect_id + " " + control_name + " (" + remaining_text + "s)"
	if _is_venom_stack_effect():
		var decay_text: String = " decaying" if is_stack_decaying else ""
		return effect_id + " x" + str(stack_count) + " " + effect_type + " " + value_text + decay_text + " (" + remaining_text + "s)"
	if _is_burning_effect():
		return effect_id + " " + effect_type + " " + value_text + "/s (" + remaining_text + "s)"
	if stat_name.strip_edges() == "":
		return effect_id + " " + effect_type + " " + value_text + " (" + remaining_text + "s)"

	return effect_id + " " + effect_type + " " + stat_name + " " + value_text + " (" + remaining_text + "s)"


func add_venom_stacks(effect_data: Dictionary) -> void:
	if is_expired:
		return

	var added_stacks: int = maxi(1, int(effect_data.get("stack_count", 1)))
	stack_count += added_stacks
	source_unit = effect_data.get("source_unit", source_unit)
	source_key = str(effect_data.get("source_key", source_key))
	value = float(effect_data.get("value", value))
	stat_name = str(effect_data.get("stat_name", stat_name))
	_read_stack_fields(effect_data, false)
	duration_mode = _resolve_duration_mode(effect_data, duration_mode)
	duration = _get_adjusted_duration(maxf(0.0, float(effect_data.get("duration", duration))))
	remaining_time = duration
	tick_interval = maxf(0.0, float(effect_data.get("tick_interval", tick_interval)))
	if tick_interval <= 0.0:
		tick_timer = 0.0
	else:
		tick_timer = clampf(tick_timer, 0.0, tick_interval)
	is_stack_decaying = false
	if _is_valid_unit(target_unit):
		target_unit.update_info_display()


func add_burning_damage(effect_data: Dictionary) -> void:
	if is_expired:
		return

	source_unit = effect_data.get("source_unit", source_unit)
	source_key = str(effect_data.get("source_key", source_key))
	value += float(effect_data.get("value", 0.0))
	stat_name = str(effect_data.get("stat_name", stat_name))
	duration_mode = _resolve_duration_mode(effect_data, duration_mode)
	if _uses_timed_duration():
		var new_duration: float = _get_adjusted_duration(maxf(0.0, float(effect_data.get("duration", 0.0))))
		remaining_time = maxf(remaining_time, new_duration)
		duration = maxf(duration, remaining_time)
	tick_interval = maxf(0.0, float(effect_data.get("tick_interval", tick_interval)))
	if tick_interval <= 0.0:
		tick_timer = 0.0
	else:
		tick_timer = clampf(tick_timer, 0.0, tick_interval)
	if _is_valid_unit(target_unit):
		target_unit.update_info_display()


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
	if _is_venom_stack_effect():
		tick_value = maxi(0, int(round(value * float(stack_count))))

	if tick_value <= 0:
		_decay_stacks_after_tick()
		return

	match effect_type:
		EFFECT_HEAL_OVER_TIME:
			target_unit.heal(tick_value, _get_valid_source_or_target())
		EFFECT_DAMAGE_OVER_TIME:
			if _is_venom_stack_effect():
				target_unit.take_damage(tick_value, _get_valid_source_or_null(), false, "venom")
			elif _is_burning_effect():
				target_unit.take_damage(tick_value, _get_valid_source_or_null(), false, "burning")
			else:
				target_unit.take_damage(tick_value, _get_valid_source_or_null(), false)

	_decay_stacks_after_tick()


func _get_current_tick_value() -> int:
	if _is_venom_stack_effect():
		return maxi(0, int(round(value * float(stack_count))))
	if _is_burning_effect():
		return maxi(0, int(round(value)))

	if not tick_values.is_empty():
		if next_tick_index >= tick_values.size():
			return 0

		var tick_value: int = maxi(0, int(tick_values[next_tick_index]))
		next_tick_index += 1
		return tick_value

	return maxi(1, int(round(value)))


func _decay_stacks_after_tick() -> void:
	if not is_stack_decaying or stack_decay_per_tick <= 0:
		return

	stack_count = maxi(0, stack_count - stack_decay_per_tick)
	if stack_count <= 0:
		expire()
	elif _is_valid_unit(target_unit):
		target_unit.update_info_display()
		if target_unit.has_method("_refresh_control_status_display"):
			target_unit._refresh_control_status_display()


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

	if target_unit.has_method("add_stat_modifier"):
		var modifier_stage: String = StatModifier.STAGE_RUNTIME_FLAT
		if effect_type == EFFECT_STAT_MULTIPLY:
			modifier_stage = StatModifier.STAGE_FINAL_MULTIPLY
		elif effect_type != EFFECT_STAT_ADD:
			return

		_applied_modifier_id = "status:" + stack_instance_key + ":" + stat_name
		target_unit.add_stat_modifier({
			"modifier_id": _applied_modifier_id,
			"source_key": "status:" + stack_group_key,
			"stat_name": stat_name,
			"stage": modifier_stage,
			"value": value,
		})
		_is_stat_applied = true
		_applied_value = value
		_applied_stat_name = stat_name
		_applied_effect_type = effect_type
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


func _remove_stat_modifier(should_update_display: bool = true, stat_context: Dictionary = {}) -> void:
	if not _is_stat_applied:
		return

	if not _is_valid_unit(target_unit):
		_is_stat_applied = false
		return

	if _applied_modifier_id.strip_edges() != "" and target_unit.has_method("remove_stat_modifier"):
		target_unit.remove_stat_modifier(_applied_modifier_id, stat_context)
		_is_stat_applied = false
		_applied_modifier_id = ""
		return

	if bool(stat_context.get("skip_stat_restore", false)):
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
	if should_update_display:
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
	var adjusted_duration: float = raw_duration * (1.0 - resistance)
	if effect_type == EFFECT_CONTROL:
		var control_multiplier: float = maxf(0.0, float(target_unit.get("control_duration_multiplier")))
		adjusted_duration *= control_multiplier
		if _is_hard_control_type(control_type):
			var hard_multiplier: float = maxf(0.0, float(target_unit.get("hard_control_duration_multiplier")))
			adjusted_duration *= hard_multiplier
	return adjusted_duration


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


func _read_control_fields(effect_data: Dictionary) -> void:
	if effect_type != EFFECT_CONTROL:
		return
	control_type = str(effect_data.get("control_type", ""))
	move_speed_multiplier = clampf(float(effect_data.get("move_speed_multiplier", 1.0)), 0.01, 1.0)
	disable_movement = bool(effect_data.get("disable_movement", false))
	disable_attack = bool(effect_data.get("disable_attack", false))
	disable_cast = bool(effect_data.get("disable_cast", false))
	disable_retarget = bool(effect_data.get("disable_retarget", false))
	forced_target = effect_data.get("forced_target", null)
	forced_target_unit_id = int(effect_data.get("forced_target_unit_id", -1))
	skill_damage_taken_multiplier = maxf(1.0, float(effect_data.get("skill_damage_taken_multiplier", 1.0)))
	control_priority = int(effect_data.get("control_priority", 0))
	control_ui_name = str(effect_data.get("control_ui_name", ""))
	var color_val: Variant = effect_data.get("control_ui_color", Color.WHITE)
	if color_val is Color:
		control_ui_color = color_val as Color


func _read_stack_fields(effect_data: Dictionary, should_replace_count: bool = true) -> void:
	if should_replace_count:
		stack_count = maxi(1, int(effect_data.get("stack_count", stack_count)))
	if _is_venom_stack_effect():
		stack_decay_per_tick = maxi(1, int(effect_data.get("stack_decay_per_tick", DEFAULT_VENOM_STACK_DECAY_PER_TICK)))
		stack_decay_after_duration = bool(effect_data.get("stack_decay_after_duration", true))
	else:
		stack_decay_per_tick = maxi(0, int(effect_data.get("stack_decay_per_tick", stack_decay_per_tick)))
		stack_decay_after_duration = bool(effect_data.get("stack_decay_after_duration", stack_decay_after_duration))


func _should_decay_stacks_after_duration() -> bool:
	return _is_venom_stack_effect() and stack_decay_after_duration and stack_count > 0 and stack_decay_per_tick > 0


func _is_venom_stack_effect() -> bool:
	return effect_id == VENOM_STACK_EFFECT_ID and effect_type == EFFECT_DAMAGE_OVER_TIME


func _is_burning_effect() -> bool:
	return effect_id == BURNING_EFFECT_ID and effect_type == EFFECT_DAMAGE_OVER_TIME


func _is_hard_control_type(configured_control_type: String) -> bool:
	return configured_control_type == CONTROL_ROOT \
		or configured_control_type == CONTROL_STUN \
		or configured_control_type == CONTROL_FREEZE


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
