class_name StatusEffectFactory
extends RefCounted


const EFFECT_TYPE_HEAL_OVER_TIME: String = "HEAL_OVER_TIME"
const EFFECT_TYPE_DAMAGE_OVER_TIME: String = "DAMAGE_OVER_TIME"
const EFFECT_TYPE_STAT_ADD: String = "STAT_ADD"
const EFFECT_TYPE_STAT_MULTIPLY: String = "STAT_MULTIPLY"

const POLARITY_POSITIVE: String = "POSITIVE"
const POLARITY_NEGATIVE: String = "NEGATIVE"
const POLARITY_NEUTRAL: String = "NEUTRAL"

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

const SOURCE_MODE_GLOBAL: String = "GLOBAL"
const SOURCE_MODE_PER_SOURCE: String = "PER_SOURCE"

const VENOM_STACK_EFFECT_ID: String = "venom_stack"
const BURNING_EFFECT_ID: String = "burning"


func apply_status_effect(
	target: Variant,
	effect_id: String,
	effect_type: String,
	source: Variant,
	duration: float,
	tick_interval: float,
	value: float,
	stat_name: String,
	options: Dictionary = {}
) -> StatusEffect:
	if not _is_valid_alive_target(target):
		return null

	if not target.has_method("apply_status_effect"):
		return null

	var effect_data: Dictionary = create_status_effect_data(
		target,
		effect_id,
		effect_type,
		source,
		duration,
		tick_interval,
		value,
		stat_name,
		options
	)
	effect_data = _apply_bond_modifiers(effect_data)
	if _is_venom_stack_data(effect_data) and bool(effect_data.get("bond_venom_extra_stack", false)):
		effect_data["stack_count"] = maxi(1, int(effect_data.get("stack_count", 1))) + 1
		effect_data["bond_venom_extra_stack"] = false
	var applied_effect: StatusEffect = target.apply_status_effect(effect_data)

	return applied_effect


func apply_status_effect_with_tick_values(
	target: Variant,
	effect_id: String,
	effect_type: String,
	source: Variant,
	duration: float,
	tick_interval: float,
	tick_values: Array[int],
	stat_name: String = "",
	options: Dictionary = {}
) -> StatusEffect:
	if not _is_valid_alive_target(target):
		return null

	if not target.has_method("apply_status_effect"):
		return null

	var effect_data: Dictionary = create_status_effect_data(
		target,
		effect_id,
		effect_type,
		source,
		duration,
		tick_interval,
		0.0,
		stat_name,
		options
	)
	effect_data["tick_values"] = tick_values.duplicate()
	return target.apply_status_effect(effect_data)


func apply_burning(
	target: Variant,
	source: Variant,
	duration: float,
	damage_per_second: float,
	options: Dictionary = {}
) -> StatusEffect:
	var merged_options: Dictionary = options.duplicate(true)
	merged_options["stack_policy"] = str(merged_options.get("stack_policy", STACK_POLICY_REFRESH_ONLY))
	merged_options["polarity"] = str(merged_options.get("polarity", POLARITY_NEGATIVE))
	merged_options["category"] = str(merged_options.get("category", CATEGORY_DOT))
	return apply_status_effect(
		target,
		BURNING_EFFECT_ID,
		EFFECT_TYPE_DAMAGE_OVER_TIME,
		source,
		duration,
		1.0,
		damage_per_second,
		"",
		merged_options
	)


func create_status_effect_data(
	target: Variant,
	effect_id: String,
	effect_type: String,
	source: Variant,
	duration: float,
	tick_interval: float,
	value: float,
	stat_name: String,
	options: Dictionary = {}
) -> Dictionary:
	var effect_data: Dictionary = {
		"effect_id": effect_id,
		"effect_type": effect_type,
		"source_unit": source,
		"target_unit": target,
		"duration": duration,
		"remaining_time": duration,
		"tick_interval": tick_interval,
		"tick_timer": 0.0,
		"value": value,
		"stat_name": stat_name,
	}
	for key: Variant in options.keys():
		effect_data[key] = options[key]

	return effect_data


func _is_valid_alive_target(target: Variant) -> bool:
	return target != null and is_instance_valid(target) and target.is_alive


func _is_venom_stack_data(effect_data: Dictionary) -> bool:
	return str(effect_data.get("effect_id", "")) == VENOM_STACK_EFFECT_ID \
		and str(effect_data.get("effect_type", "")) == EFFECT_TYPE_DAMAGE_OVER_TIME


func _apply_bond_modifiers(effect_data: Dictionary) -> Dictionary:
	var source: Variant = effect_data.get("source_unit", null)
	if source == null or not is_instance_valid(source):
		return effect_data

	var battle_root: Node = source.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return effect_data

	if not battle_root.has_method("modify_status_effect_data_for_bonds"):
		return effect_data

	return battle_root.modify_status_effect_data_for_bonds(effect_data)


func apply_control_effect(
	target: Variant,
	control_type: String,
	source: Variant,
	duration: float,
	options: Dictionary = {}
) -> Variant:
	if not _is_valid_alive_target(target):
		return null

	if not target.has_method("apply_status_effect"):
		return null

	if _is_control_immune(target, control_type):
		return null

	var source_key: String = str(options.get("source_key", _build_source_key(source)))
	var effect_data: Dictionary = {
		"effect_type": "CONTROL",
		"category": "CONTROL",
		"control_type": control_type,
		"source_unit": source,
		"target_unit": target,
		"duration": maxf(0.0, duration),
		"polarity": "NEGATIVE",
		"stack_policy": StatusEffect.STACK_POLICY_REFRESH_LONGER_DURATION,
		"effect_id": str(options.get("effect_id", control_type.to_lower() + "_control")),
		"source_key": source_key,
		"stack_group_key": str(options.get("stack_group_key", control_type.to_lower())),
	}

	match control_type:
		"SLOW":
			effect_data["move_speed_multiplier"] = float(options.get("move_speed_multiplier", 0.5))
			effect_data["control_ui_name"] = "SLOW"
			effect_data["control_ui_color"] = Color(0.4, 0.6, 1.0)
		"ROOT":
			effect_data["disable_movement"] = true
			effect_data["control_priority"] = 1
			effect_data["control_ui_name"] = "ROOT"
			effect_data["control_ui_color"] = Color(0.3, 0.9, 0.3)
		"STUN":
			effect_data["disable_movement"] = true
			effect_data["disable_attack"] = true
			effect_data["disable_cast"] = true
			effect_data["control_priority"] = 2
			effect_data["control_ui_name"] = "STUN"
			effect_data["control_ui_color"] = Color(1.0, 0.9, 0.2)
		"FREEZE":
			effect_data["disable_movement"] = true
			effect_data["disable_attack"] = true
			effect_data["disable_cast"] = true
			effect_data["control_priority"] = 3
			effect_data["control_ui_name"] = "FREEZE"
			effect_data["control_ui_color"] = Color(0.5, 0.8, 1.0)
			effect_data["skill_damage_taken_multiplier"] = float(options.get("skill_damage_taken_multiplier", 1.1))
		"TAUNT":
			effect_data["disable_retarget"] = true
			effect_data["forced_target"] = source
			effect_data["forced_target_unit_id"] = _get_unit_id(source)
			effect_data["control_priority"] = 1
			effect_data["control_ui_name"] = "TAUNT"
			effect_data["control_ui_color"] = Color(1.0, 0.3, 0.3)
			effect_data["stack_policy"] = StatusEffect.STACK_POLICY_REPLACE_BY_LAST

	for key: Variant in options.keys():
		if not effect_data.has(key):
			effect_data[key] = options[key]

	var adjusted: Dictionary = _apply_bond_modifiers(effect_data)
	return target.apply_status_effect(adjusted)


func _build_source_key(source: Variant) -> String:
	if source != null and is_instance_valid(source):
		var unit_type_value: Variant = source.get("unit_type")
		if unit_type_value != null and str(unit_type_value).strip_edges() != "":
			return str(unit_type_value)
		var unit_id_value: Variant = source.get("unit_id")
		if unit_id_value != null:
			return "unit:" + str(int(unit_id_value))
	return "none"


func _get_unit_id(unit: Variant) -> int:
	if unit != null and is_instance_valid(unit):
		var value: Variant = unit.get("unit_id")
		if value != null:
			return int(value)
	return -1


func _is_control_immune(target: Variant, control_type: String) -> bool:
	if target == null or not is_instance_valid(target):
		return true

	var tags_value: Variant = target.get("control_immunity_tags")
	if not (tags_value is Array):
		return false

	var normalized_type: String = control_type.strip_edges().to_upper()
	for tag_value: Variant in tags_value:
		var tag: String = str(tag_value).strip_edges().to_upper()
		if tag == "ALL" or tag == "CONTROL" or tag == normalized_type:
			return true

	return false
