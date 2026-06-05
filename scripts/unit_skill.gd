class_name UnitSkill
extends RefCounted


const ACTIVE_SKILL_CASTER_SCRIPT: Script = preload("res://scripts/combat/active_skill_caster.gd")
const PASSIVE_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/passive_resolver.gd")

var passive_resolver: Variant = PASSIVE_RESOLVER_SCRIPT.new()
var active_skill_caster: Variant = ACTIVE_SKILL_CASTER_SCRIPT.new()


func _init() -> void:
	active_skill_caster.setup(passive_resolver)


func reset_mana(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	unit.current_mana = minf(float(unit.max_mana), maxf(0.0, float(unit.initial_mana)))
	unit._update_mana_bar()
	unit.update_info_display()


func update(unit: Variant, delta: float) -> void:
	if not _is_valid_unit(unit):
		return

	if not unit.is_alive or not unit.is_battle_active:
		return

	passive_resolver.update_periodic_passives(unit, delta)

	if unit.max_mana <= 0:
		return

	if unit.current_mana < float(unit.max_mana):
		var mana_regen_multiplier: float = unit.control_state.mana_regen_multiplier if unit.control_state != null else 1.0
		unit.restore_mana(unit.mana_regen_per_second * delta * mana_regen_multiplier, unit)

	if unit.current_mana >= float(unit.max_mana):
		if unit.control_state != null and not unit.control_state.can_cast:
			return
		var cast_success: bool = try_cast_active_skill(unit)
		if cast_success:
			var post_skill_mana_restore: float = _consume_post_skill_mana_restore(unit)
			unit.current_mana = 0.0
			if post_skill_mana_restore > 0.0:
				unit.restore_mana(post_skill_mana_restore, unit)
			unit._update_mana_bar()
			unit.update_info_display()
			passive_resolver.notify_active_skill_cast(unit)
		elif unit._is_valid_target(unit.current_target):
			unit.current_mana = 0.0
			unit._update_mana_bar()
			unit.update_info_display()


func try_cast_active_skill(unit: Variant) -> bool:
	return active_skill_caster.try_cast_active_skill(unit)


func apply_battle_start_passives(unit: Variant) -> void:
	passive_resolver.apply_battle_start_passives(unit)


func get_effective_defense_bonus(unit: Variant) -> int:
	return passive_resolver.get_effective_defense_bonus(unit)


func apply_incoming_life_damage_passives(unit: Variant, life_damage: int) -> int:
	return passive_resolver.apply_incoming_life_damage_passives(unit, life_damage)


func get_basic_attack_damage(unit: Variant, target: Variant, base_damage: int) -> int:
	return passive_resolver.get_basic_attack_damage(unit, target, base_damage)


func apply_attack_landed_passives(unit: Variant, target: Variant) -> void:
	passive_resolver.apply_attack_landed_passives(unit, target)


func apply_kill_passives(attacker: Variant, target: Variant) -> void:
	passive_resolver.apply_kill_passives(attacker, target)


func notify_mana_restored(unit: Variant, amount: float, source: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("notify_mana_restored"):
		passive_resolver.notify_mana_restored(unit, amount, source)


func notify_damage_dealt(attacker: Variant, target: Variant, amount: int) -> void:
	if passive_resolver != null and passive_resolver.has_method("notify_damage_dealt"):
		passive_resolver.notify_damage_dealt(attacker, target, amount)


func notify_ally_died(unit: Variant, dead_ally: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("notify_ally_died"):
		passive_resolver.notify_ally_died(unit, dead_ally)


func notify_unit_died(unit: Variant, dead_unit: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("notify_unit_died"):
		passive_resolver.notify_unit_died(unit, dead_unit)


func apply_corpse_devour_bonus(unit: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("apply_corpse_devour_bonus"):
		passive_resolver.apply_corpse_devour_bonus(unit)


func notify_heal_overflow(target: Variant, overflow_amount: int, source: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("notify_heal_overflow"):
		passive_resolver.notify_heal_overflow(target, overflow_amount, source)


func notify_summon_created(summoner: Variant, summon: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("notify_summon_created"):
		passive_resolver.notify_summon_created(summoner, summon)


func apply_maggot_death_burst(unit: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("apply_maggot_death_burst"):
		passive_resolver.apply_maggot_death_burst(unit)


func apply_frost_slime_death_burst(unit: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("apply_frost_slime_death_burst"):
		passive_resolver.apply_frost_slime_death_burst(unit)


func apply_flame_slime_death_burst(unit: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("apply_flame_slime_death_burst"):
		passive_resolver.apply_flame_slime_death_burst(unit)


func apply_venom_slime_death_pool(unit: Variant) -> void:
	if passive_resolver != null and passive_resolver.has_method("apply_venom_slime_death_pool"):
		passive_resolver.apply_venom_slime_death_pool(unit)


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)


func _consume_post_skill_mana_restore(unit: Variant) -> float:
	if not _is_valid_unit(unit):
		return 0.0

	if not unit.has_meta("post_skill_mana_restore"):
		return 0.0

	var restored_mana: float = float(unit.get_meta("post_skill_mana_restore"))
	unit.remove_meta("post_skill_mana_restore")
	return restored_mana
