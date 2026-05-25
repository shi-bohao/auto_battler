class_name BondManager
extends RefCounted

const BOND_IRON_WALL: String = "iron_wall"
const BOND_HUNTER: String = "hunter"
const BOND_ARCANE: String = "arcane"
const BOND_DIVINE: String = "divine"
const BOND_SUMMON: String = "summon"
const BOND_VENOM: String = "venom"

const VENOM_STACK_EFFECT: String = "venom_stack"
const BATTLE_LONG_EFFECT_DURATION: float = 9999.0
const SUMMON_DEATH_TRIGGER_META: String = "bond_summon_death_triggered"
const VENOM_EXTRA_STACK_COOLDOWN_META: String = "bond_venom_extra_stack_last_time"

var bond_counts: Dictionary = {}
var active_tiers: Dictionary = {}
var counted_unit_types_by_bond: Dictionary = {}


func clear() -> void:
	bond_counts.clear()
	active_tiers.clear()
	counted_unit_types_by_bond.clear()


func calculate_from_units(units: Array[Unit]) -> Dictionary:
	clear()
	var counted_unit_types: Array[String] = []
	for unit: Unit in units:
		if not _is_countable_player_unit(unit):
			continue

		var unit_type: String = str(unit.unit_type)
		if unit_type == "" or counted_unit_types.has(unit_type):
			continue

		counted_unit_types.append(unit_type)
		_add_bond_tags(unit_type, _get_bond_tags_from_unit(unit))

	_finalize_active_tiers()
	return get_state_snapshot()


func calculate_from_roster(active_roster: Array[Dictionary], hero_manager: Variant = null) -> Dictionary:
	clear()
	var counted_unit_types: Array[String] = []
	for roster_item: Dictionary in active_roster:
		var unit_data: Resource = roster_item.get("unit_data", null) as Resource
		if unit_data == null:
			continue

		var unit_type: String = str(roster_item.get("unit_id", _get_resource_unit_type(unit_data)))
		if unit_type == "" or counted_unit_types.has(unit_type):
			continue

		counted_unit_types.append(unit_type)
		_add_bond_tags(unit_type, _get_bond_tags_from_resource(unit_data))

	var hero_unit_data: Resource = _get_selected_hero_unit_data(hero_manager)
	if hero_unit_data != null:
		var hero_unit_type: String = _get_resource_unit_type(hero_unit_data)
		if hero_unit_type != "" and not counted_unit_types.has(hero_unit_type):
			counted_unit_types.append(hero_unit_type)
			_add_bond_tags(hero_unit_type, _get_bond_tags_from_resource(hero_unit_data))

	_finalize_active_tiers()
	return get_state_snapshot()


func apply_battle_start_bonds(player_units: Array[Unit]) -> void:
	calculate_from_units(player_units)
	_clear_battle_start_bond_modifiers(player_units)
	_apply_iron_wall(player_units)
	_apply_hunter(player_units)
	_apply_arcane(player_units)
	_apply_divine(player_units)


func apply_bonds_to_summoned_unit(unit: Unit) -> void:
	if not _is_valid_unit(unit) or unit.team_id != 1 or not _is_summon_unit(unit):
		return

	var tier: int = get_active_tier(BOND_SUMMON)
	if tier < 2:
		return

	var multiplier: float = 1.25 if tier >= 3 else 1.15
	_apply_bond_stat_percent(unit, BOND_SUMMON, "attack_damage", multiplier - 1.0)
	var old_max_hp: int = int(unit.max_hp)
	unit.apply_runtime_stat_bonus("max_hp", float(maxi(1, int(round(float(unit.max_hp) * multiplier))) - old_max_hp), true)
	unit.hp = clampi(int(unit.hp), 0, int(unit.max_hp))
	unit.update_info_display()


func handle_unit_died(dead_unit: Unit, player_units: Array[Unit]) -> void:
	if not _is_valid_unit(dead_unit):
		return

	if dead_unit.team_id != 1 or not _is_summon_unit(dead_unit):
		return

	if get_active_tier(BOND_SUMMON) < 3:
		return

	if bool(dead_unit.get_meta(SUMMON_DEATH_TRIGGER_META, false)):
		return
	dead_unit.set_meta(SUMMON_DEATH_TRIGGER_META, true)

	var candidates: Array[Unit] = []
	for unit: Unit in player_units:
		if not _is_valid_unit(unit) or not unit.is_alive or _is_summon_unit(unit):
			continue
		candidates.append(unit)

	if candidates.is_empty():
		return

	var target: Unit = candidates[randi_range(0, candidates.size() - 1)]
	target.add_shield(30, target)
	target.restore_mana(20.0, target)


func modify_status_effect_data(effect_data: Dictionary) -> Dictionary:
	var modified_data: Dictionary = effect_data.duplicate(true)
	if str(modified_data.get("effect_id", "")) != VENOM_STACK_EFFECT:
		return modified_data

	var source: Variant = modified_data.get("source_unit", null)
	if not _is_valid_unit(source) or int(source.team_id) != 1:
		return modified_data

	var tier: int = get_active_tier(BOND_VENOM)
	if tier < 2:
		return modified_data

	var bonus_damage: float = 8.0 if tier >= 3 else 4.0
	modified_data["value"] = float(modified_data.get("value", 0.0)) + bonus_damage

	if tier >= 3 and not bool(modified_data.get("bond_venom_extra_stack", false)):
		var target: Variant = modified_data.get("target_unit", null)
		if _can_apply_extra_venom_stack(target):
			_mark_extra_venom_stack_time(target)
			modified_data["bond_venom_extra_stack"] = true

	return modified_data


func get_state_snapshot() -> Dictionary:
	return {
		"bond_counts": bond_counts.duplicate(),
		"active_tiers": active_tiers.duplicate(),
		"counted_unit_types_by_bond": counted_unit_types_by_bond.duplicate(true),
	}


func get_count(bond_id: String) -> int:
	return int(bond_counts.get(bond_id, 0))


func get_active_tier(bond_id: String) -> int:
	return int(active_tiers.get(bond_id, 0))


func has_bond_tag(unit: Unit, bond_id: String) -> bool:
	return _get_bond_tags_from_unit(unit).has(bond_id)


func get_active_bond_display_lines() -> Array[String]:
	var lines: Array[String] = []
	for bond_id: String in _get_bond_order():
		var tier: int = get_active_tier(bond_id)
		if tier <= 0:
			continue
		lines.append(_get_bond_display_name(bond_id) + " " + str(tier) + "/" + str(_get_max_tier(bond_id)))

	return lines


func get_active_bond_button_data() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for bond_id: String in _get_bond_order():
		var tier: int = get_active_tier(bond_id)
		if tier <= 0:
			continue
		var max_tier: int = _get_max_tier(bond_id)
		items.append({
			"bond_id": bond_id,
			"name": _get_bond_display_name(bond_id),
			"count": get_count(bond_id),
			"tier": tier,
			"max_tier": max_tier,
			"label": _get_bond_display_name(bond_id) + " " + str(tier) + "/" + str(max_tier),
		})
	return items


func get_bond_panel_text() -> String:
	var lines: Array[String] = get_active_bond_display_lines()
	if lines.is_empty():
		return "羁绊：无"

	var packed_lines: PackedStringArray = PackedStringArray()
	for line: String in lines:
		packed_lines.append(line)
	return "羁绊：" + "\n" + "\n".join(packed_lines)


func get_bond_detail_text_for_bond(bond_id: String) -> String:
	var count: int = get_count(bond_id)
	var tier: int = get_active_tier(bond_id)
	var max_tier: int = _get_max_tier(bond_id)
	var status_text: String = "未激活"
	if tier > 0:
		status_text = "已激活 " + str(tier) + "/" + str(max_tier)

	var lines: PackedStringArray = PackedStringArray()
	lines.append(_get_bond_display_name(bond_id) + "  " + str(count) + "/" + str(max_tier))
	lines.append("当前状态：" + status_text)
	lines.append(_get_threshold_text(bond_id))
	lines.append("")
	lines.append("效果：")

	var thresholds: Array[int] = _get_thresholds(bond_id)
	var effects: Array[String] = _get_effect_lines(bond_id)
	for index: int in effects.size():
		var threshold: int = thresholds[index] if index < thresholds.size() else 0
		var prefix: String = "  "
		if tier >= threshold and threshold > 0:
			prefix = "已激活  "
		lines.append(prefix + effects[index])

	return "\n".join(lines)


func get_bond_detail_text() -> String:
	var sections: PackedStringArray = PackedStringArray()
	for bond_id: String in _get_bond_order():
		var count: int = get_count(bond_id)
		var tier: int = get_active_tier(bond_id)
		var status_text: String = "未激活"
		if tier > 0:
			status_text = "已激活 " + str(tier) + "/" + str(_get_max_tier(bond_id))

		var lines: PackedStringArray = PackedStringArray()
		lines.append(_get_bond_display_name(bond_id) + "  " + str(count) + "/" + str(_get_max_tier(bond_id)) + "  " + status_text)
		lines.append(_get_threshold_text(bond_id))
		for effect_line: String in _get_effect_lines(bond_id):
			lines.append(effect_line)
		sections.append("\n".join(lines))

	return "\n\n".join(sections)


func _apply_iron_wall(player_units: Array[Unit]) -> void:
	var tier: int = get_active_tier(BOND_IRON_WALL)
	if tier <= 0:
		return

	var defense_bonus: int = 10
	var shield_amount: int = 0
	var damage_reduction_bonus: float = 0.0
	if tier >= 6:
		defense_bonus = 35
		shield_amount = 60
		damage_reduction_bonus = 0.15
	elif tier >= 4:
		defense_bonus = 20
		shield_amount = 30

	for unit: Unit in player_units:
		if not _is_valid_unit(unit) or not unit.is_alive or not has_bond_tag(unit, BOND_IRON_WALL):
			continue
		_apply_bond_stat_add(unit, BOND_IRON_WALL, "defense", defense_bonus)
		if shield_amount > 0:
			unit.add_shield(shield_amount, unit)
		if damage_reduction_bonus > 0.0:
			_apply_bond_stat_add(unit, BOND_IRON_WALL, "damage_reduction", damage_reduction_bonus)


func _apply_hunter(player_units: Array[Unit]) -> void:
	var tier: int = get_active_tier(BOND_HUNTER)
	if tier <= 0:
		return

	var crit_chance_bonus: float = 0.15 if tier >= 4 else 0.08
	var crit_damage_bonus: float = 0.25 if tier >= 4 else 0.0
	for unit: Unit in player_units:
		if not _is_valid_unit(unit) or not unit.is_alive or not has_bond_tag(unit, BOND_HUNTER):
			continue
		_apply_bond_stat_add(unit, BOND_HUNTER, "crit_chance", crit_chance_bonus)
		_apply_bond_stat_add(unit, BOND_HUNTER, "crit_damage_multiplier", crit_damage_bonus)


func _apply_arcane(player_units: Array[Unit]) -> void:
	var tier: int = get_active_tier(BOND_ARCANE)
	if tier <= 0:
		return

	var skill_power_bonus: float = 0.10
	var mana_regen_multiplier: float = 1.0
	var initial_mana_bonus: float = 0.0
	if tier >= 6:
		skill_power_bonus = 0.28
		mana_regen_multiplier = 1.25
		initial_mana_bonus = 30.0
	elif tier >= 4:
		skill_power_bonus = 0.18
		mana_regen_multiplier = 1.15

	for unit: Unit in player_units:
		if not _is_valid_unit(unit) or not unit.is_alive:
			continue
		_apply_bond_stat_add(unit, BOND_ARCANE, "skill_power", skill_power_bonus)
		if has_bond_tag(unit, BOND_ARCANE):
			_apply_bond_stat_percent(unit, BOND_ARCANE, "mana_regen_per_second", mana_regen_multiplier - 1.0)
			if initial_mana_bonus > 0.0:
				unit.restore_mana(initial_mana_bonus, unit)


func _apply_divine(player_units: Array[Unit]) -> void:
	var tier: int = get_active_tier(BOND_DIVINE)
	if tier <= 0:
		return

	var healing_power_bonus: float = 0.15
	var shield_power_bonus: float = 0.0
	var shield_amount: int = 0
	if tier >= 6:
		healing_power_bonus = 0.35
		shield_power_bonus = 0.25
		shield_amount = 25
	elif tier >= 4:
		healing_power_bonus = 0.25
		shield_power_bonus = 0.15

	for unit: Unit in player_units:
		if not _is_valid_unit(unit) or not unit.is_alive:
			continue
		_apply_bond_stat_add(unit, BOND_DIVINE, "healing_power", healing_power_bonus)
		_apply_bond_stat_add(unit, BOND_DIVINE, "shield_power", shield_power_bonus)
		if shield_amount > 0:
			_add_fixed_shield(unit, shield_amount)


func _add_fixed_shield(unit: Unit, amount: int) -> void:
	if amount <= 0:
		return
	unit.shield = max(0, int(unit.shield) + amount)


func _clear_battle_start_bond_modifiers(player_units: Array[Unit]) -> void:
	for unit: Unit in player_units:
		if not _is_valid_unit(unit) or not unit.has_method("remove_stat_modifiers_by_source"):
			continue
		for bond_id: String in [BOND_IRON_WALL, BOND_HUNTER, BOND_ARCANE, BOND_DIVINE]:
			unit.remove_stat_modifiers_by_source("bond:" + bond_id)


func _apply_bond_stat_add(unit: Unit, bond_id: String, stat_name: String, value: float) -> void:
	if is_zero_approx(value):
		return

	if unit.has_method("add_stat_modifier"):
		unit.add_stat_modifier({
			"modifier_id": "bond:" + bond_id + ":" + stat_name + ":runtime_flat",
			"source_key": "bond:" + bond_id,
			"stat_name": stat_name,
			"stage": StatModifier.STAGE_RUNTIME_FLAT,
			"value": value,
		})
	else:
		unit.apply_runtime_stat_bonus(stat_name, value)


func _apply_bond_stat_percent(unit: Unit, bond_id: String, stat_name: String, value: float) -> void:
	if is_zero_approx(value):
		return

	if unit.has_method("add_stat_modifier"):
		unit.add_stat_modifier({
			"modifier_id": "bond:" + bond_id + ":" + stat_name + ":runtime_percent",
			"source_key": "bond:" + bond_id,
			"stat_name": stat_name,
			"stage": StatModifier.STAGE_RUNTIME_PERCENT,
			"value": value,
		})
	else:
		var current_value: Variant = unit.get(stat_name)
		if current_value != null:
			unit.apply_runtime_stat_bonus(stat_name, float(current_value) * value)


func _add_bond_tags(unit_type: String, tags: Array[String]) -> void:
	for tag: String in tags:
		if tag == "" or _is_summon_tag_for_summon_unit(unit_type, tag):
			continue
		bond_counts[tag] = int(bond_counts.get(tag, 0)) + 1
		if not counted_unit_types_by_bond.has(tag):
			counted_unit_types_by_bond[tag] = []
		var unit_types: Array = counted_unit_types_by_bond[tag] as Array
		if not unit_types.has(unit_type):
			unit_types.append(unit_type)


func _finalize_active_tiers() -> void:
	for bond_id: String in _get_bond_order():
		active_tiers[bond_id] = _get_active_tier_for_count(bond_id, get_count(bond_id))


func _get_active_tier_for_count(bond_id: String, count: int) -> int:
	var tier: int = 0
	for threshold: int in _get_thresholds(bond_id):
		if count >= threshold:
			tier = threshold
	return tier


func _get_thresholds(bond_id: String) -> Array[int]:
	match bond_id:
		BOND_IRON_WALL:
			return [2, 4, 6]
		BOND_HUNTER:
			return [2, 4]
		BOND_ARCANE:
			return [2, 4, 6]
		BOND_DIVINE:
			return [2, 4, 6]
		BOND_SUMMON:
			return [2, 3]
		BOND_VENOM:
			return [2, 3]
		_:
			return []


func _get_threshold_text(bond_id: String) -> String:
	var thresholds: PackedStringArray = PackedStringArray()
	for threshold: int in _get_thresholds(bond_id):
		thresholds.append(str(threshold))
	return "档位：" + " / ".join(thresholds)


func _get_effect_lines(bond_id: String) -> Array[String]:
	match bond_id:
		BOND_IRON_WALL:
			return [
				"2：铁壁成员防御 +10。",
				"4：铁壁成员防御 +20，战斗开始获得 30 护盾。",
				"6：铁壁成员防御 +35，战斗开始获得 60 护盾，生命伤害降低 15%。",
			]
		BOND_HUNTER:
			return [
				"2：猎手成员暴击率 +8%。",
				"4：猎手成员暴击率 +15%，暴击伤害 +25%。",
			]
		BOND_ARCANE:
			return [
				"2：全体玩家单位技能强度 +10%。",
				"4：全体玩家单位技能强度 +18%，奥术成员魔力回复速度 +15%。",
				"6：全体玩家单位技能强度 +28%，奥术成员魔力回复速度 +25%，战斗开始获得 30 魔力。",
			]
		BOND_DIVINE:
			return [
				"2：全体玩家单位治疗强度 +15%。",
				"4：全体玩家单位治疗强度 +25%，护盾强度 +15%。",
				"6：全体玩家单位治疗强度 +35%，护盾强度 +25%，战斗开始获得 25 护盾。",
			]
		BOND_SUMMON:
			return [
				"2：玩家召唤物攻击力和最大生命 +15%。",
				"3：玩家召唤物攻击力和最大生命 +25%；友方召唤物死亡时，随机存活非召唤友军获得 30 护盾和 20 魔力。",
			]
		BOND_VENOM:
			return [
				"2：玩家单位施加的剧毒每跳伤害 +4。",
				"3：玩家单位施加的剧毒每跳伤害 +8；施加剧毒时额外增加 1 层，同一目标 2 秒冷却。",
			]
		_:
			return []


func _get_max_tier(bond_id: String) -> int:
	var thresholds: Array[int] = _get_thresholds(bond_id)
	if thresholds.is_empty():
		return 0
	return thresholds[thresholds.size() - 1]


func _get_bond_order() -> Array[String]:
	return [BOND_IRON_WALL, BOND_HUNTER, BOND_ARCANE, BOND_DIVINE, BOND_SUMMON, BOND_VENOM]


func _get_bond_display_name(bond_id: String) -> String:
	match bond_id:
		BOND_IRON_WALL:
			return "铁壁"
		BOND_HUNTER:
			return "猎手"
		BOND_ARCANE:
			return "奥术"
		BOND_DIVINE:
			return "圣疗"
		BOND_SUMMON:
			return "召唤"
		BOND_VENOM:
			return "剧毒"
		_:
			return bond_id


func _get_bond_tags_from_unit(unit: Unit) -> Array[String]:
	if not _is_valid_unit(unit):
		return []
	if not unit.bond_tags.is_empty():
		return unit.bond_tags.duplicate()
	return _get_bond_tags_from_resource(unit.unit_data)


func _get_bond_tags_from_resource(unit_data: Resource) -> Array[String]:
	var tags: Array[String] = []
	if unit_data == null:
		return tags

	var configured_tags: Variant = unit_data.get("bond_tags")
	if not (configured_tags is Array):
		return tags

	for tag_value: Variant in configured_tags:
		var tag: String = str(tag_value).strip_edges()
		if tag != "" and not tags.has(tag):
			tags.append(tag)

	return tags


func _get_selected_hero_unit_data(hero_manager: Variant) -> Resource:
	if hero_manager == null or not hero_manager.has_method("has_selected_hero"):
		return null
	if not bool(hero_manager.has_selected_hero()):
		return null
	if not hero_manager.has_method("create_hero_battle_unit_data"):
		return null
	return hero_manager.create_hero_battle_unit_data() as Resource


func _get_resource_unit_type(unit_data: Resource) -> String:
	if unit_data == null:
		return ""
	var configured_type: Variant = unit_data.get("unit_type")
	if configured_type == null:
		return ""
	return str(configured_type)


func _is_countable_player_unit(unit: Unit) -> bool:
	if not _is_valid_unit(unit) or unit.team_id != 1:
		return false
	if _is_summon_unit(unit):
		return false
	if str(unit.roster_area) == "bench":
		return false
	return true


func _is_summon_unit(unit: Unit) -> bool:
	if not _is_valid_unit(unit):
		return false
	return bool(unit.get_meta("is_summon", false)) or str(unit.roster_area) == "summon"


func _is_summon_tag_for_summon_unit(unit_type: String, tag: String) -> bool:
	return tag == BOND_SUMMON and unit_type.begins_with("summoned_")


func _can_apply_extra_venom_stack(target: Variant) -> bool:
	if not _is_valid_unit(target):
		return false

	var now: float = _get_unit_battle_time(target)
	var last_time: float = float(target.get_meta(VENOM_EXTRA_STACK_COOLDOWN_META, -9999.0))
	return now - last_time >= 2.0


func _mark_extra_venom_stack_time(target: Variant) -> void:
	if _is_valid_unit(target):
		target.set_meta(VENOM_EXTRA_STACK_COOLDOWN_META, _get_unit_battle_time(target))


func _get_unit_battle_time(unit: Variant) -> float:
	if not _is_valid_unit(unit):
		return 0.0
	return maxf(0.0, float(unit.battle_elapsed_time))


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)
