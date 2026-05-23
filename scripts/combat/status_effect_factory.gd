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
	var applied_effect: StatusEffect = target.apply_status_effect(effect_data)
	if bool(effect_data.get("bond_venom_extra_stack", false)):
		var extra_effect_data: Dictionary = effect_data.duplicate(true)
		extra_effect_data["bond_venom_extra_stack"] = false
		target.apply_status_effect(extra_effect_data)

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
