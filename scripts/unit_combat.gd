class_name UnitCombat
extends RefCounted

const UNIT_STATE_DEAD: int = 3
const HERO_BLOOD_MARK_META: String = "hero_hunt_marked"
const HERO_BLOOD_MARK_TEAM_META: String = "hero_hunt_mark_team_id"
const HERO_META_IS_HERO: String = "is_hero"
const HERO_META_HERO_ID: String = "hero_id"
const HERO_META_UPGRADE_IDS: String = "hero_upgrade_ids"
const HERO_ID_BLOODSHADOW_HUNTER: String = "bloodshadow_hunter"
const HERO_BLOOD_MARK_DAMAGE_MULTIPLIER: float = 1.15
const HERO_SHIELD_RECEIVED_MULTIPLIER_META: String = "shield_received_multiplier"
const HERO_IRON_LINE_ECHO_ENABLED_META: String = "hero_iron_line_echo_enabled"
const HERO_IRON_LINE_ECHO_AMOUNT_META: String = "hero_iron_line_echo_amount"
const HERO_IRON_LINE_ECHO_COOLDOWN_META: String = "hero_iron_line_echo_cooldown"
const HERO_IRON_LINE_ECHO_LAST_TIME_META: String = "hero_iron_line_echo_last_time"


func take_damage(unit: Variant, amount: int, attacker: Variant, can_crit: bool = true) -> int:
	if not _is_valid_unit(unit):
		return 0

	if not unit.is_alive:
		return 0

	if amount <= 0:
		return 0

	if _should_dodge(unit, attacker, can_crit):
		_play_dodge_feedback(unit)
		return 0

	var damage_result: Dictionary = _calculate_incoming_damage(unit, amount, attacker, can_crit)
	var remaining_damage: int = int(damage_result["damage"])
	var is_critical: bool = bool(damage_result["is_critical"])
	var shield_damage: int = 0
	if unit.shield > 0:
		shield_damage = mini(unit.shield, remaining_damage)
		unit.shield -= shield_damage
		remaining_damage -= shield_damage

	var life_damage: int = unit.unit_skill.apply_incoming_life_damage_passives(unit, remaining_damage)
	var actual_damage: int = mini(life_damage, unit.hp)
	if shield_damage <= 0 and actual_damage <= 0:
		return 0

	var effective_damage: int = shield_damage + actual_damage
	unit.hp = maxi(unit.hp - actual_damage, 0)

	if unit.stats_manager != null:
		unit.stats_manager.record_damage_taken(unit, effective_damage)

	if attacker != null and is_instance_valid(attacker):
		attacker.record_damage_dealt(effective_damage)
		if attacker.unit_skill != null and attacker.unit_skill.has_method("notify_damage_dealt"):
			attacker.unit_skill.notify_damage_dealt(attacker, unit, effective_damage)

	unit._update_hp_bar()
	unit.update_info_display()
	unit.unit_feedback.play_damage_feedback(unit, unit.body, effective_damage, is_critical)

	if unit.hp > 0 and unit.mana_on_hit_taken > 0.0:
		unit.restore_mana(unit.mana_on_hit_taken, unit)

	if unit.hp == 0:
		_handle_death(unit, attacker)

	return effective_damage


func record_damage_dealt(unit: Variant, amount: int) -> void:
	if not _is_valid_unit(unit):
		return

	if unit.stats_manager != null:
		unit.stats_manager.record_damage_dealt(unit, amount)


func record_kill(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	if unit.stats_manager != null:
		unit.stats_manager.record_kill(unit)


func add_battle_attack_bonus_percent(unit: Variant, percent: float) -> void:
	if not _is_valid_unit(unit):
		return

	var old_attack_damage: int = unit.attack_damage
	unit.attack_damage = maxi(1, int(round(float(unit.attack_damage) * (1.0 + percent))))
	print(unit.display_name + " attack damage: " + str(old_attack_damage) + " -> " + str(unit.attack_damage))


func add_shield(unit: Variant, amount: int, source: Variant = null) -> void:
	if not _is_valid_unit(unit):
		return

	if amount <= 0:
		return

	var final_amount: int = _get_final_shield_amount(unit, amount, source)
	unit.shield += final_amount
	var stat_source: Variant = source if _is_valid_unit(source) else unit
	if stat_source.stats_manager != null:
		stat_source.stats_manager.record_shield_given(stat_source, final_amount)
	unit.update_info_display()
	_try_apply_iron_line_echo(unit, stat_source)
	print(unit.display_name + " shield: " + str(unit.shield))


func heal(unit: Variant, amount: int, source: Variant = null) -> void:
	if not _is_valid_unit(unit):
		return

	if amount <= 0 or not unit.is_alive:
		return

	var final_amount: int = _get_final_heal_amount(unit, amount, source)
	var old_hp: int = unit.hp
	var missing_hp: int = maxi(0, int(unit.max_hp) - int(unit.hp))
	var healed_amount: int = mini(missing_hp, final_amount)
	var overflow_amount: int = maxi(0, final_amount - healed_amount)
	var stat_source: Variant = source if _is_valid_unit(source) else unit
	if overflow_amount > 0 and unit.unit_skill != null and unit.unit_skill.has_method("notify_heal_overflow"):
		unit.unit_skill.notify_heal_overflow(unit, overflow_amount, stat_source)
	if healed_amount <= 0:
		return

	unit.hp = mini(unit.max_hp, unit.hp + healed_amount)
	if stat_source.stats_manager != null:
		stat_source.stats_manager.record_healing_done(stat_source, healed_amount)
	unit._update_hp_bar()
	unit.update_info_display()
	unit.unit_feedback.play_heal_feedback(unit, healed_amount)
	print(unit.display_name + " healed: " + str(old_hp) + " -> " + str(unit.hp))


func _calculate_incoming_damage(unit: Variant, amount: int, attacker: Variant, can_crit: bool) -> Dictionary:
	var damage_after_crit: float = float(amount)
	var is_critical: bool = false

	if can_crit and _is_valid_unit(attacker):
		var critical_chance: float = clampf(float(attacker.crit_chance), 0.0, 1.0)
		if critical_chance > 0.0 and randf() < critical_chance:
			var critical_multiplier: float = maxf(1.0, float(attacker.crit_damage_multiplier))
			damage_after_crit *= critical_multiplier
			is_critical = true
			print(attacker.display_name + " critical hit: " + str(amount) + " x" + str(critical_multiplier))

	damage_after_crit *= _get_hero_damage_multiplier(unit, attacker)
	var defense_bonus: int = unit.unit_skill.get_effective_defense_bonus(unit)
	var defense_penetration: float = 0.0
	if _is_valid_unit(attacker):
		defense_penetration = maxf(0.0, float(attacker.defense_penetration))
	var defense_value: float = maxf(0.0, float(unit.defense + defense_bonus) - defense_penetration)
	var damage_after_defense: float = damage_after_crit * 100.0 / (100.0 + defense_value)
	var reduction: float = clampf(float(unit.damage_reduction), 0.0, 0.95)
	var damage_after_reduction: float = damage_after_defense * (1.0 - reduction)
	var incoming_multiplier: float = maxf(0.0, float(unit.damage_taken_multiplier))
	var final_damage: int = maxi(1, int(round(damage_after_reduction * incoming_multiplier)))
	return {
		"damage": final_damage,
		"is_critical": is_critical,
	}


func _get_final_shield_amount(unit: Variant, amount: int, source: Variant = null) -> int:
	var multiplier: float = 1.0
	var stat_source: Variant = source if _is_valid_unit(source) else unit
	if _is_valid_unit(stat_source):
		multiplier *= 1.0 + maxf(0.0, float(stat_source.shield_power))
	if unit.has_meta(HERO_SHIELD_RECEIVED_MULTIPLIER_META):
		multiplier *= maxf(0.0, float(unit.get_meta(HERO_SHIELD_RECEIVED_MULTIPLIER_META)))

	return maxi(1, int(round(float(amount) * multiplier)))


func _get_final_heal_amount(unit: Variant, amount: int, source: Variant = null) -> int:
	var stat_source: Variant = source if _is_valid_unit(source) else unit
	var multiplier: float = 1.0
	if _is_valid_unit(stat_source):
		multiplier *= 1.0 + maxf(0.0, float(stat_source.healing_power))

	return maxi(1, int(round(float(amount) * multiplier)))


func _should_dodge(unit: Variant, attacker: Variant, can_crit: bool) -> bool:
	if not can_crit:
		return false

	if not _is_valid_unit(attacker):
		return false

	if int(attacker.team_id) == int(unit.team_id):
		return false

	var chance: float = clampf(float(unit.dodge_chance), 0.0, 0.95)
	return chance > 0.0 and randf() < chance


func _play_dodge_feedback(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	if unit.unit_feedback != null and unit.is_inside_tree():
		unit.unit_feedback.play_skill_feedback(unit, "闪避")


func _try_apply_iron_line_echo(unit: Variant, source: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	if not bool(unit.get_meta(HERO_IRON_LINE_ECHO_ENABLED_META, false)):
		return

	if unit.max_mana <= 0:
		return

	var cooldown: float = maxf(0.0, float(unit.get_meta(HERO_IRON_LINE_ECHO_COOLDOWN_META, 2.0)))
	var now: float = _get_unit_battle_time(unit)
	var last_time: float = float(unit.get_meta(HERO_IRON_LINE_ECHO_LAST_TIME_META, -9999.0))
	if now - last_time < cooldown:
		return

	unit.set_meta(HERO_IRON_LINE_ECHO_LAST_TIME_META, now)
	var mana_amount: float = maxf(0.0, float(unit.get_meta(HERO_IRON_LINE_ECHO_AMOUNT_META, 10.0)))
	if mana_amount > 0.0:
		unit.restore_mana(mana_amount, source if _is_valid_unit(source) else unit)


func _get_hero_damage_multiplier(target: Variant, attacker: Variant) -> float:
	if not _is_valid_unit(target) or not _is_valid_unit(attacker):
		return 1.0

	var multiplier: float = 1.0
	if attacker.team_id == 1 and bool(target.get_meta(HERO_BLOOD_MARK_META, false)) and int(target.get_meta(HERO_BLOOD_MARK_TEAM_META, -1)) == attacker.team_id:
		multiplier *= HERO_BLOOD_MARK_DAMAGE_MULTIPLIER

	if attacker.team_id == 1 and target.max_hp > 0 and float(target.hp) / float(target.max_hp) < 0.35:
		var blood_hero: Variant = _find_team_hero(attacker, HERO_ID_BLOODSHADOW_HUNTER)
		if _is_valid_unit(blood_hero) and _hero_has_upgrade(blood_hero, "blood_wounded_hunter"):
			multiplier *= 1.12

	return multiplier


func _find_team_hero(unit: Variant, hero_id: String) -> Variant:
	if not _is_valid_unit(unit):
		return null

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		if not bool(ally.get_meta(HERO_META_IS_HERO, false)):
			continue

		if str(ally.get_meta(HERO_META_HERO_ID, "")) == hero_id:
			return ally

	return null


func _hero_has_upgrade(hero: Variant, upgrade_id: String) -> bool:
	if not _is_valid_unit(hero) or upgrade_id == "":
		return false

	if not hero.has_meta(HERO_META_UPGRADE_IDS):
		return false

	var upgrade_ids: Variant = hero.get_meta(HERO_META_UPGRADE_IDS)
	if not (upgrade_ids is Array):
		return false

	var upgrade_array: Array = upgrade_ids as Array
	return upgrade_array.has(upgrade_id)


func _handle_death(unit: Variant, attacker: Variant) -> void:
	unit.is_alive = false
	unit.is_targetable = false
	unit.unit_state = UNIT_STATE_DEAD
	unit.current_target = null
	if unit.has_method("clear_status_effects"):
		unit.clear_status_effects()

	if unit.stats_manager != null:
		unit.stats_manager.record_death(unit)

	if attacker != null and is_instance_valid(attacker):
		attacker.record_kill()
		attacker.emit_killed_target_signal(unit)

	unit.unit_feedback.play_death_feedback(unit)
	unit.emit_died_signal()


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)


func _get_unit_battle_time(unit: Variant) -> float:
	if not _is_valid_unit(unit):
		return 0.0

	return maxf(0.0, float(unit.battle_elapsed_time))
