class_name RelicEffectResolver
extends RefCounted


const RELIC_ID_BATTLE_BANNER: String = "battle_banner"
const RELIC_ID_IRON_ARMOR_BADGE: String = "iron_armor_badge"
const RELIC_ID_BLOOD_PENDANT: String = "blood_pendant"
const RELIC_ID_SOUL_LANTERN: String = "soul_lantern"
const RELIC_ID_EXECUTIONER_SIGIL: String = "executioner_sigil"
const RELIC_ID_VICTORY_DRUM: String = "victory_drum"
const RELIC_ID_HUNTER_MARK: String = "hunter_mark"
const RELIC_ID_VENGEANCE_SPARK: String = "vengeance_spark"
const RELIC_ID_STEEL_FORMATION: String = "steel_formation"
const RELIC_ID_SHARP_EDGE: String = "sharp_edge"
const RELIC_ID_BROKEN_FANG: String = "broken_fang"
const RELIC_ID_ARCANE_CORE: String = "arcane_core"
const RELIC_ID_FIRST_SPARK: String = "first_spark"
const RELIC_ID_GUARDIAN_OATH: String = "guardian_oath"
const RELIC_ID_LAST_STAND: String = "last_stand"
const RELIC_ID_SOUL_EMBER: String = "soul_ember"
const RELIC_ID_DUELIST_GLOVE: String = "duelist_glove"
const RELIC_ID_MAGE_LENS: String = "mage_lens"
const RELIC_ID_HEALING_BELL: String = "healing_bell"
const RELIC_ID_RESONANCE_HARP: String = "resonance_harp"
const RELIC_ID_STAR_CROWN: String = "star_crown"
const RELIC_ID_CROWN_OF_THREE: String = "crown_of_three"
const RELIC_ID_BACKLINE_SCOPE: String = "backline_scope"
const RELIC_ID_FRONTLINE_PLATE: String = "frontline_plate"
const RELIC_ID_ARCANE_PRISM: String = "arcane_prism"
const RELIC_ID_MERCY_CENSER: String = "mercy_censer"
const RELIC_ID_PIERCING_WHETSTONE: String = "piercing_whetstone"
const RELIC_ID_BLOODGLASS_CHARM: String = "bloodglass_charm"
const RELIC_ID_BULWARK_RUNE: String = "bulwark_rune"
const RELIC_ID_OPENING_TOME: String = "opening_tome"
const RELIC_ID_DYNAMO_NEEDLE: String = "dynamo_needle"
const RELIC_ID_MIRAGE_CLOAK: String = "mirage_cloak"
const RELIC_ID_GRAVEBONE_CHARM: String = "gravebone_charm"
const RELIC_ID_VITALITY_TROPHY: String = "vitality_trophy"
const SKELETON_SUMMON_DATA: Resource = preload("res://data/summons/skeleton.tres")
const GUARDIAN_OATH_DEFENSE_BONUS: int = 25
const STAR_CROWN_DEFENSE_BONUS: int = 18
const CROWN_OF_THREE_MANA_REGEN_BONUS: float = 0.40
const FRONTLINE_PLATE_SHIELD_AMOUNT: int = 20
const BULWARK_RUNE_STATUS_RESISTANCE_BONUS: float = 0.15
const FALLBACK_BACKLINE_X_MAX: float = 320.0
const FALLBACK_FRONTLINE_X_MIN: float = 560.0

var relic_manager_ref: WeakRef = null
var status_effect_factory: Variant = StatusEffectFactory.new()


func setup(relic_manager_value: Variant) -> void:
	relic_manager_ref = weakref(relic_manager_value)


func apply_battle_start_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var relic_id: String = _get_relic_id(relic_data)

	match relic_id:
		RELIC_ID_BATTLE_BANNER:
			_apply_battle_banner_relic(relic_data, player_units)
		RELIC_ID_IRON_ARMOR_BADGE:
			_apply_iron_armor_badge_relic(relic_data, player_units)
		RELIC_ID_STEEL_FORMATION:
			_apply_steel_formation_relic(relic_data, player_units)
		RELIC_ID_SHARP_EDGE:
			_apply_sharp_edge_relic(relic_data, player_units)
		RELIC_ID_BROKEN_FANG:
			_apply_broken_fang_relic(relic_data, player_units)
		RELIC_ID_ARCANE_CORE:
			_apply_arcane_core_relic(relic_data, player_units)
		RELIC_ID_FIRST_SPARK:
			_apply_first_spark_relic(relic_data, player_units)
		RELIC_ID_GUARDIAN_OATH:
			_apply_guardian_oath_relic(relic_data, player_units)
		RELIC_ID_MAGE_LENS:
			_apply_mage_lens_relic(relic_data, player_units)
		RELIC_ID_HEALING_BELL:
			_apply_healing_bell_relic(relic_data, player_units)
		RELIC_ID_RESONANCE_HARP:
			_apply_resonance_harp_relic(relic_data, player_units)
		RELIC_ID_STAR_CROWN:
			_apply_star_crown_relic(relic_data, player_units)
		RELIC_ID_CROWN_OF_THREE:
			_apply_crown_of_three_relic(relic_data, player_units)
		RELIC_ID_BACKLINE_SCOPE:
			_apply_backline_scope_relic(relic_data, player_units)
		RELIC_ID_FRONTLINE_PLATE:
			_apply_frontline_plate_relic(relic_data, player_units)
		RELIC_ID_ARCANE_PRISM:
			_apply_arcane_prism_relic(relic_data, player_units)
		RELIC_ID_MERCY_CENSER:
			_apply_mercy_censer_relic(relic_data, player_units)
		RELIC_ID_PIERCING_WHETSTONE:
			_apply_piercing_whetstone_relic(relic_data, player_units)
		RELIC_ID_BLOODGLASS_CHARM:
			_apply_bloodglass_charm_relic(relic_data, player_units)
		RELIC_ID_BULWARK_RUNE:
			_apply_bulwark_rune_relic(relic_data, player_units)
		RELIC_ID_OPENING_TOME:
			_apply_opening_tome_relic(relic_data, player_units)
		RELIC_ID_DYNAMO_NEEDLE:
			_apply_dynamo_needle_relic(relic_data, player_units)
		RELIC_ID_MIRAGE_CLOAK:
			_apply_mirage_cloak_relic(relic_data, player_units)
		_:
			push_warning("Unknown battle start relic: " + relic_id)


func is_always_on_relic(relic_data: Resource) -> bool:
	var relic_id: String = _get_relic_id(relic_data)
	return [
		RELIC_ID_BATTLE_BANNER,
		RELIC_ID_STEEL_FORMATION,
		RELIC_ID_SHARP_EDGE,
		RELIC_ID_BROKEN_FANG,
		RELIC_ID_ARCANE_CORE,
		RELIC_ID_MAGE_LENS,
		RELIC_ID_HEALING_BELL,
		RELIC_ID_STAR_CROWN,
		RELIC_ID_CROWN_OF_THREE,
		RELIC_ID_ARCANE_PRISM,
		RELIC_ID_MERCY_CENSER,
		RELIC_ID_PIERCING_WHETSTONE,
		RELIC_ID_BLOODGLASS_CHARM,
		RELIC_ID_DYNAMO_NEEDLE,
	].has(relic_id)


func apply_always_on_relics_to_unit(unit: Unit) -> void:
	if not _is_alive_unit(unit) or not _is_owner_unit(unit):
		return

	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null or not current_relic_manager.has_method("get_player_relics"):
		return

	var player_relics: Array[Resource] = current_relic_manager.get_player_relics()
	for relic_data: Resource in player_relics:
		if relic_data == null or not is_always_on_relic(relic_data):
			continue

		_apply_always_on_relic_to_unit(relic_data, unit)


func try_apply_hunter_mark_relic(attacker: Unit, target: Unit) -> void:
	if not _is_archer_unit(attacker):
		return

	if attacker.attack_count <= 0 or attacker.attack_count % 3 != 0:
		return

	if not _is_alive_unit(target):
		return

	var hunter_mark: Resource = _get_relic_by_id(RELIC_ID_HUNTER_MARK)
	var damage_multiplier: float = _get_relic_value(hunter_mark, 0.75)
	var extra_damage: int = maxi(1, int(round(float(attacker.attack_damage) * damage_multiplier)))
	print("Relic triggered: Hunter Mark, " + attacker.display_name + " deals extra " + str(extra_damage))
	target.take_damage(extra_damage, attacker, false)


func try_apply_duelist_glove_relic(attacker: Unit, target: Unit) -> void:
	if not _is_assassin_unit(attacker):
		return

	if not _is_alive_unit(target):
		return

	if _get_hp_ratio(target) >= 0.5:
		return

	var duelist_glove: Resource = _get_relic_by_id(RELIC_ID_DUELIST_GLOVE)
	var damage_multiplier: float = _get_relic_value(duelist_glove, 0.35)
	var extra_damage: int = maxi(1, int(round(float(attacker.attack_damage) * damage_multiplier)))
	print("Relic triggered: Duelist Glove, " + attacker.display_name + " deals extra " + str(extra_damage))
	target.take_damage(extra_damage, attacker, false)


func apply_blood_pendant_relic(attacker: Unit) -> void:
	var blood_pendant: Resource = _get_relic_by_id(RELIC_ID_BLOOD_PENDANT)
	var heal_amount: int = maxi(0, int(round(_get_relic_value(blood_pendant, 35.0))))
	print("Relic triggered: Blood Pendant, " + attacker.display_name + " heals " + str(heal_amount))
	attacker.heal(heal_amount)


func apply_soul_lantern_relic(attacker: Unit) -> void:
	var soul_lantern: Resource = _get_relic_by_id(RELIC_ID_SOUL_LANTERN)
	var mana_amount: float = _get_relic_value(soul_lantern, 25.0)
	if mana_amount <= 0.0:
		return

	print("Relic triggered: Soul Lantern, " + attacker.display_name + " restores " + str(mana_amount) + " mana")
	_restore_mana(attacker, mana_amount)


func apply_executioner_sigil_relic(attacker: Unit) -> void:
	var executioner_sigil: Resource = _get_relic_by_id(RELIC_ID_EXECUTIONER_SIGIL)
	var attack_bonus: float = _get_relic_value(executioner_sigil, 0.12)
	if attack_bonus <= 0.0:
		return

	print("Relic triggered: Executioner Sigil, " + attacker.display_name + " gains +" + str(roundi(attack_bonus * 100.0)) + "% attack damage")
	_apply_relic_stat_multiply(attacker, RELIC_ID_EXECUTIONER_SIGIL, "attack_damage", 1.0 + attack_bonus, StatusEffectFactory.STACK_POLICY_PERMANENT_STACK)


func apply_vitality_trophy_relic(attacker: Unit, roster_manager: Variant = null, hero_manager: Variant = null) -> void:
	if not _is_alive_unit(attacker):
		return

	if attacker.roster_area == "summon" or bool(attacker.get_meta("is_summon", false)):
		return

	var vitality_trophy: Resource = _get_relic_by_id(RELIC_ID_VITALITY_TROPHY)
	var max_hp_bonus: float = maxf(0.0, _get_relic_value(vitality_trophy, 5.0))
	if max_hp_bonus <= 0.0:
		return

	var did_store_bonus: bool = false
	if attacker.roster_area == "hero" or bool(attacker.get_meta("is_hero", false)):
		if hero_manager != null and hero_manager.has_method("add_permanent_stat_bonus"):
			did_store_bonus = bool(hero_manager.add_permanent_stat_bonus("max_hp", max_hp_bonus))
	elif attacker.roster_id > 0:
		if roster_manager != null and roster_manager.has_method("add_permanent_stat_bonus_by_roster_id"):
			did_store_bonus = bool(roster_manager.add_permanent_stat_bonus_by_roster_id(attacker.roster_id, "max_hp", max_hp_bonus))

	if not did_store_bonus:
		return

	print("Relic triggered: Blood Oath Chalice, " + attacker.display_name + " permanently gains +" + str(int(round(max_hp_bonus))) + " max HP")
	attacker.apply_runtime_stat_bonus("max_hp", max_hp_bonus, true)


func apply_victory_drum_relic(attacker: Unit) -> void:
	var victory_drum: Resource = _get_relic_by_id(RELIC_ID_VICTORY_DRUM)
	var shield_amount: int = maxi(0, int(round(_get_relic_value(victory_drum, 12.0))))
	if shield_amount <= 0:
		return

	var player_units: Array[Unit] = _get_alive_allies_including_self(attacker)
	if player_units.is_empty():
		return

	print("Relic triggered: Victory Drum, surviving player units gain " + str(shield_amount) + " shield")
	for unit in player_units:
		unit.add_shield(shield_amount, attacker)


func apply_last_stand_relic(dead_unit: Unit, player_units: Array[Unit]) -> void:
	var last_stand: Resource = _get_relic_by_id(RELIC_ID_LAST_STAND)
	var shield_amount: int = maxi(0, int(round(_get_relic_value(last_stand, 60.0))))
	if shield_amount <= 0:
		return

	print("Relic triggered: Ember Bulwark, surviving player units gain " + str(shield_amount) + " shield")
	for unit in player_units:
		if _is_alive_unit(unit) and unit != dead_unit:
			unit.add_shield(shield_amount)


func apply_soul_ember_relic(dead_unit: Unit, player_units: Array[Unit]) -> void:
	var soul_ember: Resource = _get_relic_by_id(RELIC_ID_SOUL_EMBER)
	var mana_amount: float = _get_relic_value(soul_ember, 45.0)
	if mana_amount <= 0.0:
		return

	print("Relic triggered: Soul Ember, surviving player units restore " + str(mana_amount) + " mana")
	for unit in player_units:
		if _is_alive_unit(unit) and unit != dead_unit:
			_restore_mana(unit, mana_amount)


func apply_vengeance_spark_relic(dead_unit: Unit, enemy_units: Array[Unit]) -> void:
	var target: Unit = _find_nearest_alive_enemy(dead_unit.global_position, enemy_units)
	if target == null:
		return

	var vengeance_spark: Resource = _get_relic_by_id(RELIC_ID_VENGEANCE_SPARK)
	var damage: int = maxi(0, int(round(_get_relic_value(vengeance_spark, 50.0))))
	if damage <= 0:
		return

	print("Relic triggered: Vengeance Spark, " + dead_unit.display_name + " deals " + str(damage) + " relic damage to " + target.display_name)
	var actual_damage: int = target.take_damage(damage, null, false)
	_add_relic_damage_dealt(actual_damage)


func apply_gravebone_charm_relic(dead_unit: Unit) -> void:
	if dead_unit == null or not is_instance_valid(dead_unit):
		return

	var gravebone_charm: Resource = _get_relic_by_id(RELIC_ID_GRAVEBONE_CHARM)
	var summon_cap: int = maxi(0, int(round(_get_relic_value(gravebone_charm, 3.0))))
	if summon_cap <= 0:
		return

	var battle_root: Node = dead_unit.get_parent()
	if battle_root == null or not battle_root.has_method("summon_units"):
		return

	var context: Dictionary = {
		"source_type": "relic",
		"relic_id": RELIC_ID_GRAVEBONE_CHARM,
		"summon_cap": summon_cap,
		"team_id": dead_unit.team_id,
		"position": dead_unit.position,
		"ignore_source_alive": true,
	}
	print("Relic triggered: Gravebone Charm summons a Skeleton")
	battle_root.summon_units(dead_unit, SKELETON_SUMMON_DATA, 1, context)


func _apply_always_on_relic_to_unit(relic_data: Resource, unit: Unit) -> void:
	if not _is_alive_unit(unit):
		return

	var relic_id: String = _get_relic_id(relic_data)
	var applied_meta_key: String = "always_on_relic_" + relic_id
	if unit.has_meta(applied_meta_key):
		return

	match relic_id:
		RELIC_ID_BATTLE_BANNER:
			_apply_direct_stat_multiply(unit, "attack_damage", 1.0 + _get_relic_value(relic_data, 0.10))
		RELIC_ID_STEEL_FORMATION:
			_apply_direct_stat_add(unit, "defense", maxi(0, int(round(_get_relic_value(relic_data, 12.0)))))
		RELIC_ID_SHARP_EDGE:
			_apply_direct_stat_add(unit, "crit_chance", _get_relic_value(relic_data, 0.10))
		RELIC_ID_BROKEN_FANG:
			if _is_archer_unit(unit) or _is_assassin_unit(unit):
				_apply_direct_stat_add(unit, "crit_damage_multiplier", _get_relic_value(relic_data, 0.55))
			else:
				return
		RELIC_ID_ARCANE_CORE:
			_apply_direct_stat_multiply(unit, "mana_regen_per_second", 1.0 + _get_relic_value(relic_data, 0.25))
		RELIC_ID_MAGE_LENS:
			if _is_mage_unit(unit):
				_apply_direct_stat_add(unit, "skill_power", _get_relic_value(relic_data, 0.35))
			else:
				return
		RELIC_ID_HEALING_BELL:
			if _is_priest_unit(unit):
				_apply_direct_stat_add(unit, "healing_power", _get_relic_value(relic_data, 0.40))
			else:
				return
		RELIC_ID_STAR_CROWN:
			if unit.star >= 2:
				_apply_direct_stat_multiply(unit, "attack_damage", 1.0 + _get_relic_value(relic_data, 0.25))
				_apply_direct_stat_add(unit, "defense", STAR_CROWN_DEFENSE_BONUS)
			else:
				return
		RELIC_ID_CROWN_OF_THREE:
			if unit.star == 3:
				_apply_direct_stat_multiply(unit, "attack_damage", 1.0 + _get_relic_value(relic_data, 0.45))
				_apply_direct_stat_multiply(unit, "mana_regen_per_second", 1.0 + CROWN_OF_THREE_MANA_REGEN_BONUS)
			else:
				return
		RELIC_ID_ARCANE_PRISM:
			_apply_direct_stat_add(unit, "skill_power", maxf(0.0, _get_relic_value(relic_data, 0.15)))
		RELIC_ID_MERCY_CENSER:
			var output_bonus: float = maxf(0.0, _get_relic_value(relic_data, 0.20))
			_apply_direct_stat_add(unit, "healing_power", output_bonus)
			_apply_direct_stat_add(unit, "shield_power", output_bonus)
		RELIC_ID_PIERCING_WHETSTONE:
			_apply_direct_stat_add(unit, "defense_penetration", maxi(0, int(round(_get_relic_value(relic_data, 8.0)))))
		RELIC_ID_BLOODGLASS_CHARM:
			_apply_direct_stat_add(unit, "life_steal", maxf(0.0, _get_relic_value(relic_data, 0.08)))
		RELIC_ID_DYNAMO_NEEDLE:
			var mana_bonus: float = maxf(0.0, _get_relic_value(relic_data, 4.0))
			_apply_direct_stat_add(unit, "mana_on_attack", mana_bonus)
			_apply_direct_stat_add(unit, "mana_on_hit_taken", mana_bonus)
		_:
			return

	unit.set_meta(applied_meta_key, true)


func _apply_battle_banner_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var attack_bonus_percent: float = _get_relic_value(relic_data, 0.1)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if is_instance_valid(unit) and unit.is_alive:
			_apply_relic_stat_multiply(unit, RELIC_ID_BATTLE_BANNER, "attack_damage", 1.0 + attack_bonus_percent)


func _apply_iron_armor_badge_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var shield_amount: int = maxi(0, int(round(_get_relic_value(relic_data, 30.0))))
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if is_instance_valid(unit) and unit.is_alive:
			unit.add_shield(shield_amount)


func _apply_steel_formation_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var defense_bonus: int = maxi(0, int(round(_get_relic_value(relic_data, 12.0))))
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_STEEL_FORMATION, "defense", defense_bonus)


func _apply_sharp_edge_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var crit_chance_bonus: float = _get_relic_value(relic_data, 0.1)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_SHARP_EDGE, "crit_chance", crit_chance_bonus)


func _apply_broken_fang_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var crit_damage_bonus: float = _get_relic_value(relic_data, 0.55)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit) and (_is_archer_unit(unit) or _is_assassin_unit(unit)):
			_apply_relic_stat_add(unit, RELIC_ID_BROKEN_FANG, "crit_damage_multiplier", crit_damage_bonus)


func _apply_arcane_core_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var mana_regen_bonus: float = _get_relic_value(relic_data, 0.25)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_multiply(unit, RELIC_ID_ARCANE_CORE, "mana_regen_per_second", 1.0 + mana_regen_bonus)


func _apply_first_spark_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var mana_amount: float = _get_relic_value(relic_data, 50.0)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_restore_mana(unit, mana_amount)


func _apply_guardian_oath_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var target: Unit = _find_highest_defense_unit(player_units)
	if target == null:
		return

	var shield_amount: int = maxi(0, int(round(_get_relic_value(relic_data, 70.0))))
	print("Relic triggered: " + _get_relic_debug_name(relic_data) + " on " + target.display_name)
	target.add_shield(shield_amount)
	_apply_relic_stat_add(target, RELIC_ID_GUARDIAN_OATH, "defense", GUARDIAN_OATH_DEFENSE_BONUS)


func _apply_mage_lens_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var skill_damage_bonus: float = _get_relic_value(relic_data, 0.35)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit) and _is_mage_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_MAGE_LENS, "skill_power", skill_damage_bonus)


func _apply_healing_bell_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var heal_bonus: float = _get_relic_value(relic_data, 0.40)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit) and _is_priest_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_HEALING_BELL, "healing_power", heal_bonus)


func _apply_resonance_harp_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	if not _has_alive_unit_type(player_units, "bard"):
		return

	var attack_bonus: float = _get_relic_value(relic_data, 0.18)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_multiply(unit, RELIC_ID_RESONANCE_HARP, "attack_damage", 1.0 + attack_bonus)


func _apply_star_crown_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var attack_bonus: float = _get_relic_value(relic_data, 0.25)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit) and unit.star >= 2:
			_apply_relic_stat_multiply(unit, RELIC_ID_STAR_CROWN, "attack_damage", 1.0 + attack_bonus)
			_apply_relic_stat_add(unit, RELIC_ID_STAR_CROWN, "defense", STAR_CROWN_DEFENSE_BONUS)


func _apply_crown_of_three_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var attack_bonus: float = _get_relic_value(relic_data, 0.45)
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit) and unit.star == 3:
			_apply_relic_stat_multiply(unit, RELIC_ID_CROWN_OF_THREE, "attack_damage", 1.0 + attack_bonus)
			_apply_relic_stat_multiply(unit, RELIC_ID_CROWN_OF_THREE, "mana_regen_per_second", 1.0 + CROWN_OF_THREE_MANA_REGEN_BONUS)


func _apply_backline_scope_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var attack_bonus: float = _get_relic_value(relic_data, 0.12)
	var backline_columns: Array[int] = [0, 1, 2]
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit) and _is_player_unit_in_columns(unit, backline_columns, true):
			_apply_relic_stat_multiply(unit, RELIC_ID_BACKLINE_SCOPE, "attack_damage", 1.0 + attack_bonus)


func _apply_frontline_plate_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var defense_bonus: int = maxi(0, int(round(_get_relic_value(relic_data, 15.0))))
	var frontline_columns: Array[int] = [5, 6]
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit) and _is_player_unit_in_columns(unit, frontline_columns, false):
			_apply_relic_stat_add(unit, RELIC_ID_FRONTLINE_PLATE, "defense", defense_bonus)
			unit.add_shield(FRONTLINE_PLATE_SHIELD_AMOUNT)


func _apply_arcane_prism_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var skill_power_bonus: float = maxf(0.0, _get_relic_value(relic_data, 0.15))
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_ARCANE_PRISM, "skill_power", skill_power_bonus)


func _apply_mercy_censer_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var output_bonus: float = maxf(0.0, _get_relic_value(relic_data, 0.20))
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_MERCY_CENSER, "healing_power", output_bonus)
			_apply_relic_stat_add(unit, RELIC_ID_MERCY_CENSER, "shield_power", output_bonus)


func _apply_piercing_whetstone_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var penetration_bonus: int = maxi(0, int(round(_get_relic_value(relic_data, 8.0))))
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_PIERCING_WHETSTONE, "defense_penetration", penetration_bonus)


func _apply_bloodglass_charm_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var life_steal_bonus: float = maxf(0.0, _get_relic_value(relic_data, 0.08))
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_BLOODGLASS_CHARM, "life_steal", life_steal_bonus)


func _apply_bulwark_rune_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var damage_reduction_bonus: float = maxf(0.0, _get_relic_value(relic_data, 0.08))
	var frontline_columns: Array[int] = [5, 6]
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit) and _is_player_unit_in_columns(unit, frontline_columns, false):
			_apply_relic_stat_add(unit, RELIC_ID_BULWARK_RUNE, "damage_reduction", damage_reduction_bonus)
			_apply_relic_stat_add(unit, RELIC_ID_BULWARK_RUNE, "status_resistance", BULWARK_RUNE_STATUS_RESISTANCE_BONUS)


func _apply_opening_tome_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var mana_bonus: float = maxf(0.0, _get_relic_value(relic_data, 20.0))
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_OPENING_TOME, "initial_mana", mana_bonus)
			_restore_mana(unit, mana_bonus)


func _apply_dynamo_needle_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var mana_bonus: float = maxf(0.0, _get_relic_value(relic_data, 4.0))
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit):
			_apply_relic_stat_add(unit, RELIC_ID_DYNAMO_NEEDLE, "mana_on_attack", mana_bonus)
			_apply_relic_stat_add(unit, RELIC_ID_DYNAMO_NEEDLE, "mana_on_hit_taken", mana_bonus)


func _apply_mirage_cloak_relic(relic_data: Resource, player_units: Array[Unit]) -> void:
	var dodge_bonus: float = maxf(0.0, _get_relic_value(relic_data, 0.10))
	var backline_columns: Array[int] = [0, 1, 2]
	print("Relic triggered: " + _get_relic_debug_name(relic_data))

	for unit in player_units:
		if _is_alive_unit(unit) and _is_player_unit_in_columns(unit, backline_columns, true):
			_apply_relic_stat_add(unit, RELIC_ID_MIRAGE_CLOAK, "dodge_chance", dodge_bonus)
			_apply_relic_stat_add(unit, RELIC_ID_MIRAGE_CLOAK, "status_resistance", dodge_bonus)


func _find_nearest_alive_enemy(origin_position: Vector2, enemy_units: Array[Unit]) -> Unit:
	var best_target: Unit = null
	var best_distance: float = INF
	var best_unit_id: int = 2147483647

	for unit in enemy_units:
		if not is_instance_valid(unit) or not unit.is_alive:
			continue

		var distance: float = origin_position.distance_to(unit.global_position)
		if best_target == null or distance < best_distance:
			best_target = unit
			best_distance = distance
			best_unit_id = unit.unit_id
		elif is_equal_approx(distance, best_distance) and unit.unit_id < best_unit_id:
			best_target = unit
			best_unit_id = unit.unit_id

	return best_target


func _is_alive_unit(unit: Unit) -> bool:
	return unit != null and is_instance_valid(unit) and unit.is_alive


func _is_archer_unit(unit: Unit) -> bool:
	return _is_unit_type(unit, "archer") or _is_unit_type(unit, "\u5f13\u624b")


func _is_assassin_unit(unit: Unit) -> bool:
	return _is_unit_type(unit, "assassin") or _is_unit_type(unit, "\u523a\u5ba2")


func _is_mage_unit(unit: Unit) -> bool:
	return _is_unit_type(unit, "mage") or _is_unit_type(unit, "\u6cd5\u5e08")


func _is_priest_unit(unit: Unit) -> bool:
	return _is_unit_type(unit, "priest") or _is_unit_type(unit, "\u7267\u5e08")


func _is_unit_type(unit: Unit, unit_type: String) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false

	return unit.unit_type.to_lower() == unit_type.to_lower()


func _has_alive_unit_type(units: Array[Unit], unit_type: String) -> bool:
	for unit in units:
		if _is_alive_unit(unit) and _is_unit_type(unit, unit_type):
			return true

	return false


func _get_alive_allies_including_self(attacker: Unit) -> Array[Unit]:
	var allies: Array[Unit] = []
	if not _is_alive_unit(attacker):
		return allies

	allies.append(attacker)
	for unit in attacker.ally_units:
		if _is_alive_unit(unit) and not allies.has(unit):
			allies.append(unit)

	return allies


func _is_owner_unit(unit: Unit) -> bool:
	if not _is_alive_unit(unit):
		return false

	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null or not current_relic_manager.has_method("get_owner_team_id"):
		return unit.team_id == 1

	return unit.team_id == int(current_relic_manager.get_owner_team_id())


func _apply_direct_stat_add(unit: Unit, stat_name: String, value: float) -> void:
	if not _is_alive_unit(unit) or is_zero_approx(value):
		return

	unit.apply_runtime_stat_bonus(stat_name, value)


func _apply_direct_stat_multiply(unit: Unit, stat_name: String, multiplier: float) -> void:
	if not _is_alive_unit(unit) or is_equal_approx(multiplier, 1.0):
		return

	var current_value: Variant = unit.get(stat_name)
	if current_value == null:
		return

	var bonus_value: float = float(current_value) * (multiplier - 1.0)
	_apply_direct_stat_add(unit, stat_name, bonus_value)


func _apply_relic_stat_add(unit: Unit, relic_id: String, stat_name: String, value: float, stack_policy: String = StatusEffectFactory.STACK_POLICY_REFRESH_ONLY) -> void:
	if is_zero_approx(value):
		return

	_apply_relic_stat_effect(unit, relic_id, StatusEffectFactory.EFFECT_TYPE_STAT_ADD, stat_name, value, stack_policy)


func _apply_relic_stat_multiply(unit: Unit, relic_id: String, stat_name: String, multiplier: float, stack_policy: String = StatusEffectFactory.STACK_POLICY_REFRESH_ONLY) -> void:
	if is_equal_approx(multiplier, 1.0):
		return

	_apply_relic_stat_effect(unit, relic_id, StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, stat_name, multiplier, stack_policy)


func _apply_relic_stat_effect(unit: Unit, relic_id: String, effect_type: String, stat_name: String, value: float, stack_policy: String) -> void:
	if not _is_alive_unit(unit):
		return

	var effect_id: String = "relic_" + relic_id + "_" + stat_name
	status_effect_factory.apply_status_effect(unit, effect_id, effect_type, null, -1.0, 0.0, value, stat_name, {
		"stack_policy": stack_policy,
		"duration_mode": StatusEffectFactory.DURATION_MODE_NONE,
		"polarity": StatusEffectFactory.POLARITY_POSITIVE,
		"category": StatusEffectFactory.CATEGORY_STAT,
		"source_key": "relic:" + relic_id,
		"stack_key": effect_id,
	})


func _restore_mana(unit: Unit, mana_amount: float) -> void:
	if not _is_alive_unit(unit):
		return

	if unit.max_mana <= 0 or mana_amount <= 0.0:
		return

	unit.restore_mana(mana_amount)


func _find_highest_defense_unit(player_units: Array[Unit]) -> Unit:
	var best_unit: Unit = null
	var best_defense: int = -2147483648
	var best_unit_id: int = 2147483647

	for unit in player_units:
		if not _is_alive_unit(unit):
			continue

		if best_unit == null or unit.defense > best_defense:
			best_unit = unit
			best_defense = unit.defense
			best_unit_id = unit.unit_id
		elif unit.defense == best_defense and unit.unit_id < best_unit_id:
			best_unit = unit
			best_unit_id = unit.unit_id

	return best_unit


func _get_hp_ratio(unit: Unit) -> float:
	if not _is_alive_unit(unit) or unit.max_hp <= 0:
		return 1.0

	return float(unit.hp) / float(unit.max_hp)


func _is_player_unit_in_columns(unit: Unit, columns: Array[int], use_backline_fallback: bool) -> bool:
	if not _is_alive_unit(unit):
		return false

	var board: Variant = unit.battle_board
	if board != null and is_instance_valid(board) and board.has_method("world_to_grid"):
		var cell: Vector2i = board.world_to_grid(unit.position)
		var is_player_side: bool = unit.team_id == 1
		if is_player_side and board.has_method("is_valid_player_cell") and not board.is_valid_player_cell(cell):
			return false
		if not is_player_side and board.has_method("is_valid_enemy_cell") and not board.is_valid_enemy_cell(cell):
			return false

		return _side_columns_have_cell(columns, cell.x, is_player_side)

	if use_backline_fallback:
		return unit.position.x <= FALLBACK_BACKLINE_X_MAX if unit.team_id == 1 else unit.position.x >= FALLBACK_FRONTLINE_X_MIN

	return unit.position.x >= FALLBACK_FRONTLINE_X_MIN if unit.team_id == 1 else unit.position.x <= FALLBACK_BACKLINE_X_MAX


func _side_columns_have_cell(player_side_columns: Array[int], cell_x: int, is_player_side: bool) -> bool:
	if is_player_side:
		return player_side_columns.has(cell_x)

	for player_column: int in player_side_columns:
		var mirrored_column: int = 14 - player_column
		if mirrored_column == cell_x:
			return true

	return false


func _get_relic_id(relic_data: Resource) -> String:
	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null or not current_relic_manager.has_method("get_relic_id"):
		return ""

	return str(current_relic_manager.get_relic_id(relic_data))


func _get_relic_debug_name(relic_data: Resource) -> String:
	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null or not current_relic_manager.has_method("get_relic_debug_name"):
		return _get_relic_id(relic_data)

	return str(current_relic_manager.get_relic_debug_name(relic_data))


func _get_relic_value(relic_data: Resource, default_value: float) -> float:
	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null or not current_relic_manager.has_method("get_relic_value"):
		return default_value

	return float(current_relic_manager.get_relic_value(relic_data, default_value))


func _get_relic_by_id(relic_id: String) -> Resource:
	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null or not current_relic_manager.has_method("get_relic_by_id"):
		return null

	return current_relic_manager.get_relic_by_id(relic_id)


func _add_relic_damage_dealt(damage: int) -> void:
	var current_relic_manager: Variant = _get_relic_manager()
	if current_relic_manager == null:
		return

	current_relic_manager.relic_damage_dealt += damage


func _get_relic_manager() -> Variant:
	if relic_manager_ref == null:
		return null

	return relic_manager_ref.get_ref()
