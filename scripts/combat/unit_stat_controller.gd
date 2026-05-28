class_name UnitStatController
extends RefCounted


const STAT_MODIFIER_SCRIPT: Script = preload("res://scripts/combat/stat_modifier.gd")

const STAGE_ORDER: Array[String] = [
	StatModifier.STAGE_BASE_OVERRIDE,
	StatModifier.STAGE_PERMANENT_FLAT,
	StatModifier.STAGE_PERMANENT_PERCENT,
	StatModifier.STAGE_RUNTIME_FLAT,
	StatModifier.STAGE_RUNTIME_PERCENT,
	StatModifier.STAGE_FINAL_FLAT,
	StatModifier.STAGE_FINAL_PERCENT,
	StatModifier.STAGE_FINAL_MULTIPLY,
]

const INTEGER_STATS: Array[String] = [
	"max_hp",
	"attack_damage",
	"defense",
	"defense_penetration",
	"max_mana",
]

const SUPPORTED_STATS: Array[String] = [
	"max_hp",
	"attack_damage",
	"crit_chance",
	"crit_damage_multiplier",
	"defense",
	"skill_power",
	"healing_power",
	"shield_power",
	"defense_penetration",
	"life_steal",
	"damage_reduction",
	"damage_taken_multiplier",
	"initial_mana",
	"mana_on_attack",
	"mana_on_hit_taken",
	"status_resistance",
	"dodge_chance",
	"attack_range",
	"search_range",
	"move_speed",
	"attack_interval",
	"max_mana",
	"mana_regen_per_second",
	"active_skill_damage_multiplier",
	"active_heal_multiplier",
]

var base_stats: Dictionary = {}
var modifiers_by_id: Dictionary = {}


func capture_base_stats(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	base_stats.clear()
	for stat_name: String in SUPPORTED_STATS:
		base_stats[stat_name] = _get_stat_value(unit, stat_name)


func has_modifiers() -> bool:
	return not modifiers_by_id.is_empty()


func clear_runtime_state() -> void:
	base_stats.clear()
	modifiers_by_id.clear()


func add_modifier(unit: Variant, modifier_data: Variant, context: Dictionary = {}) -> void:
	if not _is_valid_unit(unit):
		return

	_sync_base_from_current_if_empty(unit)
	if modifiers_by_id.is_empty() and not bool(context.get("preserve_base_stats", false)):
		capture_base_stats(unit)

	var modifier: StatModifier = null
	if modifier_data is StatModifier:
		modifier = modifier_data as StatModifier
	elif modifier_data is Dictionary:
		modifier = STAT_MODIFIER_SCRIPT.from_data(modifier_data as Dictionary)

	if modifier == null or modifier.stat_name.strip_edges() == "":
		return

	var key: String = modifier.get_key()
	if key.strip_edges() == "":
		return

	modifiers_by_id[key] = modifier
	if bool(context.get("skip_recalculate", false)):
		return
	recalculate(unit, context)


func remove_modifier(unit: Variant, modifier_id: String, context: Dictionary = {}) -> void:
	if modifier_id.strip_edges() == "":
		return

	if modifiers_by_id.erase(modifier_id):
		if bool(context.get("skip_recalculate", false)):
			return
		recalculate(unit, context)


func remove_modifiers_by_source(unit: Variant, source_key: String, context: Dictionary = {}) -> void:
	if source_key.strip_edges() == "":
		return

	var removed_any: bool = false
	for key: Variant in modifiers_by_id.keys():
		var modifier: StatModifier = modifiers_by_id[key] as StatModifier
		if modifier != null and modifier.source_key == source_key:
			modifiers_by_id.erase(key)
			removed_any = true

	if removed_any:
		if bool(context.get("skip_recalculate", false)):
			return
		recalculate(unit, context)


func clear_modifiers(unit: Variant) -> void:
	if modifiers_by_id.is_empty():
		return

	modifiers_by_id.clear()
	recalculate(unit)


func add_base_stat_bonus(unit: Variant, stat_name: String, amount: float, should_fill_current_hp: bool = false) -> void:
	if stat_name.strip_edges() == "" or is_zero_approx(amount) or not _is_valid_unit(unit):
		return

	if base_stats.is_empty():
		capture_base_stats(unit)
	elif modifiers_by_id.is_empty():
		capture_base_stats(unit)

	var old_max_hp: int = int(unit.max_hp) if stat_name == "max_hp" else 0
	base_stats[stat_name] = float(base_stats.get(stat_name, _get_stat_value(unit, stat_name))) + amount
	recalculate(unit)

	if stat_name == "max_hp":
		var hp_delta: int = int(unit.max_hp) - old_max_hp
		if should_fill_current_hp:
			unit.hp = clampi(int(unit.hp) + hp_delta, 0, int(unit.max_hp))
		else:
			unit.hp = clampi(int(unit.hp), 0, int(unit.max_hp))
		if unit.has_method("_update_hp_bar"):
			unit._update_hp_bar()
		if unit.has_method("update_info_display"):
			unit.update_info_display()


func recalculate(unit: Variant, context: Dictionary = {}) -> void:
	if not _is_valid_unit(unit):
		return

	_sync_base_from_current_if_empty(unit)
	var old_max_hp: int = int(unit.max_hp)
	for stat_name: String in SUPPORTED_STATS:
		if not base_stats.has(stat_name):
			continue
		var final_value: float = _calculate_stat(stat_name, context)
		_set_stat_value(unit, stat_name, final_value)

	if int(unit.max_hp) != old_max_hp:
		unit.hp = clampi(int(unit.hp), 0, int(unit.max_hp))
		if unit.has_method("_update_hp_bar"):
			unit._update_hp_bar()

	if unit.has_method("update_info_display"):
		unit.update_info_display()


func get_modifier_count() -> int:
	return modifiers_by_id.size()


func _calculate_stat(stat_name: String, context: Dictionary) -> float:
	var value: float = float(base_stats.get(stat_name, 0.0))
	var final_multiply: float = 1.0

	var override_modifier: StatModifier = _get_highest_priority_override(stat_name, context)
	if override_modifier != null:
		value = _resolve_modifier_value(override_modifier, context)

	for stage: String in STAGE_ORDER:
		if stage == StatModifier.STAGE_BASE_OVERRIDE:
			continue

		match stage:
			StatModifier.STAGE_PERMANENT_FLAT, StatModifier.STAGE_RUNTIME_FLAT, StatModifier.STAGE_FINAL_FLAT:
				value += _sum_stage(stat_name, stage, context)
			StatModifier.STAGE_PERMANENT_PERCENT, StatModifier.STAGE_RUNTIME_PERCENT, StatModifier.STAGE_FINAL_PERCENT:
				value *= 1.0 + _sum_stage(stat_name, stage, context)
			StatModifier.STAGE_FINAL_MULTIPLY:
				final_multiply *= _product_stage(stat_name, stage, context)

	return value * final_multiply


func _get_highest_priority_override(stat_name: String, context: Dictionary) -> StatModifier:
	var best_modifier: StatModifier = null
	for modifier_value: Variant in modifiers_by_id.values():
		var modifier: StatModifier = modifier_value as StatModifier
		if modifier == null or modifier.stat_name != stat_name or modifier.stage != StatModifier.STAGE_BASE_OVERRIDE:
			continue
		if best_modifier == null or modifier.priority >= best_modifier.priority:
			best_modifier = modifier
	return best_modifier


func _sum_stage(stat_name: String, stage: String, context: Dictionary) -> float:
	var total: float = 0.0
	for modifier_value: Variant in modifiers_by_id.values():
		var modifier: StatModifier = modifier_value as StatModifier
		if modifier == null or modifier.stat_name != stat_name or modifier.stage != stage:
			continue
		total += _resolve_modifier_value(modifier, context)
	return total


func _product_stage(stat_name: String, stage: String, context: Dictionary) -> float:
	var product: float = 1.0
	for modifier_value: Variant in modifiers_by_id.values():
		var modifier: StatModifier = modifier_value as StatModifier
		if modifier == null or modifier.stat_name != stat_name or modifier.stage != stage:
			continue
		product *= _resolve_modifier_value(modifier, context)
	return product


func _resolve_modifier_value(modifier: StatModifier, context: Dictionary) -> float:
	if modifier.dynamic_key == "":
		return modifier.value

	var gold: int = int(context.get("gold", 0))
	match modifier.dynamic_key:
		"gold_flat_step_capped":
			var step: int = maxi(1, int(modifier.params.get("step", 1)))
			var per_step: float = float(modifier.params.get("per_step", 1.0))
			var cap: float = float(modifier.params.get("cap", 999999.0))
			return minf(float(floori(float(gold) / float(step))) * per_step, cap)
		"gold_percent_capped":
			var per_gold: float = float(modifier.params.get("per_gold", 0.0))
			var cap: float = float(modifier.params.get("cap", 999999.0))
			return minf(float(gold) * per_gold, cap)
		"gold_percent_step":
			var step: int = maxi(1, int(modifier.params.get("step", 1)))
			var per_step: float = float(modifier.params.get("per_step", 0.0))
			return float(floori(float(gold) / float(step))) * per_step
		_:
			return modifier.value


func _sync_base_from_current_if_empty(unit: Variant) -> void:
	if base_stats.is_empty():
		capture_base_stats(unit)


func _get_stat_value(unit: Variant, stat_name: String) -> float:
	return float(unit.get(stat_name))


func _set_stat_value(unit: Variant, stat_name: String, value: float) -> void:
	match stat_name:
		"max_hp":
			unit.max_hp = maxi(1, int(round(value)))
		"attack_damage":
			unit.attack_damage = maxi(1, int(round(value)))
		"defense":
			unit.defense = maxi(0, int(round(value)))
		"defense_penetration":
			unit.defense_penetration = maxi(0, int(round(value)))
		"max_mana":
			unit.max_mana = maxi(0, int(round(value)))
			unit.current_mana = minf(float(unit.max_mana), float(unit.current_mana))
		"crit_chance", "life_steal":
			unit.set(stat_name, clampf(value, 0.0, 1.0))
		"damage_reduction", "status_resistance", "dodge_chance":
			unit.set(stat_name, clampf(value, 0.0, 0.95))
		"crit_damage_multiplier":
			unit.crit_damage_multiplier = maxf(1.0, value)
		"damage_taken_multiplier":
			unit.damage_taken_multiplier = maxf(0.0, value)
		"attack_interval":
			unit.attack_interval = maxf(0.05, value)
			unit.attack_cooldown = minf(float(unit.attack_cooldown), float(unit.attack_interval))
		"move_speed":
			unit.move_speed = maxf(1.0, value)
		"skill_power", "healing_power", "shield_power", "initial_mana", "mana_on_attack", "mana_on_hit_taken", "mana_regen_per_second", "active_skill_damage_multiplier", "active_heal_multiplier":
			unit.set(stat_name, maxf(0.0, value))
		"attack_range", "search_range":
			unit.set(stat_name, maxf(0.0, value))
		_:
			unit.set(stat_name, value)


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)
