class_name EncounterGenerator
extends RefCounted

const ENEMY_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/enemy_catalog.gd")
const WAVE_RULE_SCRIPT: Script = preload("res://scripts/encounter/wave_rule.gd")
const ENEMY_POSITION_SERVICE_SCRIPT: Script = preload("res://scripts/encounter/enemy_position_service.gd")

const ENCOUNTER_TYPE_NORMAL: String = "NORMAL"
const ENCOUNTER_TYPE_ELITE: String = "ELITE"
const ENCOUNTER_TYPE_BOSS: String = "BOSS"

const ROLE_TANK: String = "tank"
const ROLE_DAMAGE: String = "damage"
const ROLE_SUPPORT: String = "support"

const ENEMY_ID_SHIELD_GUARD: String = "enemy_shield_guard"
const ENEMY_ID_STONEBACK_BEAST: String = "enemy_stoneback_beast"
const ENEMY_ID_ELITE_IRON_WARDEN: String = "enemy_elite_iron_warden"
const ENEMY_ID_BOSS_EARTHBREAKER_COLOSSUS: String = "enemy_boss_earthbreaker_colossus"
const ENEMY_ID_CROSSBOW_RAIDER: String = "enemy_crossbow_raider"
const ENEMY_ID_FLAME_IMP: String = "enemy_flame_imp"
const ENEMY_ID_ELITE_SHADOW_REAPER: String = "enemy_elite_shadow_reaper"
const ENEMY_ID_DARK_ACOLYTE: String = "enemy_dark_acolyte"
const ENEMY_ID_WAR_DRUMMER: String = "enemy_war_drummer"
const ENEMY_ID_ELITE_BLOOD_ORACLE: String = "enemy_elite_blood_oracle"
const ENEMY_ID_GRAVE_CALLER: String = "enemy_grave_caller"
const ENEMY_ID_BONE_CARRIER: String = "enemy_bone_carrier"
const ENEMY_ID_PUPPET_BINDER: String = "enemy_puppet_binder"

var enemy_catalog: Variant = ENEMY_CATALOG_SCRIPT.new()
var wave_rule: Variant = WAVE_RULE_SCRIPT.new()
var enemy_position_service: Variant = ENEMY_POSITION_SERVICE_SCRIPT.new()


func create_random_encounter(current_round: int, forced_type: String = "", forced_boss_id: String = "") -> Dictionary:
	var encounter_type: String = forced_type if forced_type != "" else wave_rule.get_encounter_type_for_round(current_round)
	match encounter_type:
		ENCOUNTER_TYPE_BOSS:
			return _create_random_boss_encounter(current_round, forced_boss_id)
		ENCOUNTER_TYPE_ELITE:
			return _create_random_elite_encounter(current_round)
		_:
			return _create_random_normal_encounter(current_round)


func _create_random_normal_encounter(current_round: int) -> Dictionary:
	var enemy_count: int = wave_rule.get_normal_enemy_count(current_round)
	var template_id: String = _pick_string(["balanced", "frontline", "backline", "assassin", "arcane", "summoner"])
	var units: Array[Dictionary] = _build_units_from_template(current_round, ENCOUNTER_TYPE_NORMAL, enemy_count, template_id)
	_assign_enemy_positions(units)
	var multipliers: Dictionary = wave_rule.get_normal_multipliers(current_round)
	var name: String = _pick_string(["敌方巡逻队", "敌方阵线", "游荡阵型"])
	return _create_random_encounter_data(current_round, name, ENCOUNTER_TYPE_NORMAL, units, multipliers)


func _create_random_elite_encounter(current_round: int) -> Dictionary:
	var total_count: int = clampi(wave_rule.get_normal_enemy_count(current_round) - 1, 4, 9)
	var elite_count: int = floori(float(current_round) / 5.0)
	var normal_count: int = maxi(0, total_count - elite_count)

	var elite_template_id: String = _pick_string(["elite_assassin", "elite_mage", "elite_iron_wall", "elite_summoner"])
	var elite_units: Array[Dictionary] = _build_units_from_template(current_round, ENCOUNTER_TYPE_ELITE, elite_count, elite_template_id)
	_ensure_elite_has_elite_unit(elite_units, elite_template_id)
	_ensure_elite_has_high_star(elite_units)

	var normal_units: Array[Dictionary] = []
	if normal_count > 0:
		var normal_template_id: String = _pick_string(["balanced", "frontline", "backline", "assassin", "arcane", "summoner"])
		normal_units = _build_units_from_template(current_round, ENCOUNTER_TYPE_NORMAL, normal_count, normal_template_id)

	var units: Array[Dictionary] = []
	units.append_array(elite_units)
	units.append_array(normal_units)
	_assign_enemy_positions(units)

	var multipliers: Dictionary = wave_rule.get_elite_multipliers(current_round)
	var name_map: Dictionary = {
		"elite_assassin": "精英突击队",
		"elite_mage": "奥术精英",
		"elite_iron_wall": "铁壁精英",
		"elite_summoner": "召唤精英",
	}
	return _create_random_encounter_data(current_round, str(name_map.get(elite_template_id, "精英突击队")), ENCOUNTER_TYPE_ELITE, units, multipliers)


func _create_random_boss_encounter(current_round: int, forced_boss_id: String = "") -> Dictionary:
	var units: Array[Dictionary] = []
	var boss_unit_id: String = forced_boss_id
	if boss_unit_id.strip_edges() == "" or enemy_catalog.get_unit_data_by_id(boss_unit_id) == null:
		boss_unit_id = _pick_string(enemy_catalog.get_boss_enemy_ids())
	var boss_star: int = wave_rule.get_boss_star(current_round)
	var guard_star: int = wave_rule.get_boss_guard_star(current_round)
	units.append(_create_random_enemy_entry(
		boss_unit_id,
		boss_star,
		true,
		1.0,
		1.0,
		0,
		1.0
	))
	var boss_tier: int = clampi(floori(float(maxi(current_round - 10, 0)) / 10.0), 0, 2)
	var guard_count: int = 3 + boss_tier
	units.append(_create_random_enemy_entry(
		_select_unit_id(ROLE_TANK, {"enemy_shield_guard": 2.0, "enemy_stoneback_beast": 2.0, "enemy_elite_iron_warden": 1.0}, ENCOUNTER_TYPE_ELITE),
		guard_star,
		false,
		1.0,
		1.0,
		0,
		1.0
	))
	units.append(_create_random_enemy_entry(
		_select_unit_id(ROLE_SUPPORT, {}, ENCOUNTER_TYPE_NORMAL),
		guard_star,
		false,
		1.0,
		1.0,
		0,
		1.0
	))
	for _idx: int in range(guard_count - 2):
		units.append(_create_random_enemy_entry(
			_select_unit_id(ROLE_DAMAGE, {}, ENCOUNTER_TYPE_NORMAL),
			guard_star,
			false,
			1.0,
			1.0,
			0,
			1.0
		))
	var elite_count: int = floori(float(current_round) / 5.0)
	if elite_count > 0:
		var elite_star: int = wave_rule.roll_star(current_round, ENCOUNTER_TYPE_ELITE)
		for _idx: int in range(elite_count):
			units.append(_create_random_enemy_entry(
				_select_unit_id(ROLE_DAMAGE, {}, ENCOUNTER_TYPE_ELITE),
				elite_star,
				false,
				1.0,
				1.0,
				0,
				1.0
			))
	_assign_enemy_positions(units)
	var multipliers: Dictionary = wave_rule.get_boss_multipliers(current_round)
	var name: String = enemy_catalog.get_unit_type_display_name(boss_unit_id)
	return _create_random_encounter_data(current_round, name, ENCOUNTER_TYPE_BOSS, units, multipliers)
func _build_units_from_template(current_round: int, encounter_type: String, enemy_count: int, template_id: String) -> Array[Dictionary]:
	var role_counts: Dictionary = _get_template_role_counts(template_id, enemy_count)
	var unit_weights: Dictionary = _get_template_unit_weights(template_id)
	var units: Array[Dictionary] = []

	_append_role_units(units, current_round, encounter_type, ROLE_TANK, int(role_counts.get(ROLE_TANK, 0)), unit_weights)
	_append_role_units(units, current_round, encounter_type, ROLE_DAMAGE, int(role_counts.get(ROLE_DAMAGE, 0)), unit_weights)
	_append_role_units(units, current_round, encounter_type, ROLE_SUPPORT, int(role_counts.get(ROLE_SUPPORT, 0)), unit_weights)

	while units.size() < enemy_count:
		_append_role_units(units, current_round, encounter_type, ROLE_DAMAGE, 1, unit_weights)

	while units.size() > enemy_count:
		units.remove_at(units.size() - 1)

	return units


func _get_template_role_counts(template_id: String, enemy_count: int) -> Dictionary:
	var tank_count: int = 1
	var support_count: int = 0

	match template_id:
		"frontline":
			tank_count = mini(2, enemy_count)
		"backline", "arcane":
			support_count = 1 if enemy_count >= 3 and not enemy_catalog.get_available_unit_ids_by_role(ROLE_SUPPORT).is_empty() else 0
		"elite_assassin":
			tank_count = 1
			support_count = 0
		"elite_mage":
			tank_count = 1
			support_count = 1 if not enemy_catalog.get_available_unit_ids_by_role(ROLE_SUPPORT).is_empty() else 0
		"elite_iron_wall":
			tank_count = mini(2, enemy_count)
			support_count = 1 if enemy_count >= 4 and not enemy_catalog.get_available_unit_ids_by_role(ROLE_SUPPORT).is_empty() else 0
		"summoner", "elite_summoner":
			tank_count = 1
			support_count = 1 if enemy_count >= 3 and not enemy_catalog.get_available_unit_ids_by_role(ROLE_SUPPORT).is_empty() else 0
		_:
			tank_count = 1

	var damage_count: int = maxi(0, enemy_count - tank_count - support_count)
	if enemy_count >= 4 and damage_count <= 0:
		damage_count = 1
		if support_count > 0:
			support_count -= 1
		else:
			tank_count = maxi(1, tank_count - 1)

	return {
		ROLE_TANK: tank_count,
		ROLE_DAMAGE: damage_count,
		ROLE_SUPPORT: mini(1, support_count),
	}


func _get_template_unit_weights(template_id: String) -> Dictionary:
	match template_id:
		"assassin", "elite_assassin":
			return {"enemy_elite_shadow_reaper": 5.0, "enemy_crossbow_raider": 1.0, "enemy_flame_imp": 1.0, "enemy_giant_maggot": 2.0}
		"arcane":
			return {"enemy_flame_imp": 5.0, "enemy_war_drummer": 3.0, "enemy_crossbow_raider": 1.0, "enemy_frost_slime": 2.0}
		"elite_mage":
			return {"enemy_flame_imp": 5.0, "enemy_elite_blood_oracle": 3.0, "enemy_war_drummer": 2.0, "enemy_elite_maggot_amalgam": 2.0, "enemy_giant_slime": 2.0}
		"elite_iron_wall":
			return {"enemy_elite_iron_warden": 5.0, "enemy_stoneback_beast": 3.0, "enemy_elite_blood_oracle": 4.0, "enemy_elite_maggot_amalgam": 4.0, "enemy_giant_slime": 4.0}
		"summoner":
			return {"enemy_grave_caller": 5.0, "enemy_bone_carrier": 3.0, "enemy_flame_imp": 1.0, "enemy_venom_slime": 2.0}
		"elite_summoner":
			return {"enemy_puppet_binder": 5.0, "enemy_grave_caller": 4.0, "enemy_bone_carrier": 3.0, "enemy_giant_maggot": 2.0, "enemy_giant_slime": 2.0}
		"frontline":
			return {"enemy_shield_guard": 2.0, "enemy_stoneback_beast": 2.0, "enemy_giant_maggot": 2.0, "enemy_common_slime": 3.0}
		_:
			return {}


func _append_role_units(
	units: Array[Dictionary],
	current_round: int,
	encounter_type: String,
	role: String,
	count: int,
	unit_weights: Dictionary
) -> void:
	for _index: int in range(count):
		var unit_id: String = _select_unit_id(role, unit_weights, encounter_type)
		var star: int = wave_rule.roll_star(current_round, encounter_type)
		units.append(_create_random_enemy_entry(unit_id, star, false, 1.0, 1.0, 0, 1.0))


func _create_random_enemy_entry(
	unit_id: String,
	star: int,
	is_boss: bool,
	hp_multiplier: float,
	attack_multiplier: float,
	defense_bonus: int,
	mana_regen_multiplier: float
) -> Dictionary:
	var safe_star: int = clampi(star, 1, 3)
	return {
		"unit_id": unit_id,
		"display_name": enemy_catalog.create_enemy_display_name(unit_id, safe_star, is_boss),
		"position": Vector2.ZERO,
		"star": safe_star,
		"is_boss": is_boss,
		"hp_multiplier": hp_multiplier,
		"attack_multiplier": attack_multiplier,
		"defense_bonus": defense_bonus,
		"mana_regen_multiplier": mana_regen_multiplier,
	}


func _create_random_encounter_data(
	current_round: int,
	encounter_name: String,
	encounter_type: String,
	enemy_units: Array[Dictionary],
	multipliers: Dictionary
) -> Dictionary:
	return {
		"encounter_id": "random_round_" + str(current_round),
		"encounter_name": encounter_name,
		"encounter_type": encounter_type,
		"enemy_hp_multiplier": float(multipliers["hp_multiplier"]),
		"enemy_attack_multiplier": float(multipliers["attack_multiplier"]),
		"enemy_defense_bonus": int(multipliers["defense_bonus"]),
		"enemy_mana_regen_multiplier": float(multipliers["mana_regen_multiplier"]),
		"enemy_count": enemy_units.size(),
		"enemy_units": enemy_units,
	}


func _assign_enemy_positions(units: Array[Dictionary]) -> void:
	enemy_position_service.assign_enemy_positions(units, Callable(enemy_catalog, "get_unit_role"))


func _ensure_elite_has_high_star(units: Array[Dictionary]) -> void:
	for enemy_unit: Dictionary in units:
		if int(enemy_unit.get("star", 1)) >= 2:
			return

	if units.is_empty():
		return

	var unit_index: int = randi_range(0, units.size() - 1)
	var enemy_unit: Dictionary = units[unit_index]
	enemy_unit["star"] = 2
	enemy_unit["display_name"] = enemy_catalog.create_enemy_display_name(str(enemy_unit["unit_id"]), 2, bool(enemy_unit.get("is_boss", false)))
	units[unit_index] = enemy_unit


func _ensure_elite_has_elite_unit(units: Array[Dictionary], template_id: String) -> void:
	if units.is_empty():
		return

	for enemy_unit: Dictionary in units:
		if enemy_catalog.is_elite_enemy_id(str(enemy_unit.get("unit_id", ""))):
			return

	var elite_unit_id: String = ENEMY_ID_ELITE_SHADOW_REAPER
	match template_id:
		"elite_iron_wall":
			elite_unit_id = ENEMY_ID_ELITE_IRON_WARDEN
		"elite_mage":
			elite_unit_id = ENEMY_ID_ELITE_BLOOD_ORACLE
		"elite_summoner":
			elite_unit_id = ENEMY_ID_PUPPET_BINDER
		_:
			elite_unit_id = ENEMY_ID_ELITE_SHADOW_REAPER

	var replace_index: int = 0
	for index: int in range(units.size()):
		if enemy_catalog.get_unit_role(str(units[index].get("unit_id", ""))) == enemy_catalog.get_unit_role(elite_unit_id):
			replace_index = index
			break

	var enemy_unit: Dictionary = units[replace_index]
	enemy_unit["unit_id"] = elite_unit_id
	enemy_unit["display_name"] = enemy_catalog.create_enemy_display_name(elite_unit_id, int(enemy_unit.get("star", 1)), false)
	units[replace_index] = enemy_unit


func _select_unit_id(role: String, weights: Dictionary, encounter_type: String = ENCOUNTER_TYPE_NORMAL) -> String:
	var unit_ids: Array[String] = enemy_catalog.get_available_unit_ids_by_role(role, encounter_type)
	if unit_ids.is_empty():
		unit_ids = enemy_catalog.get_fallback_unit_ids()

	if unit_ids.is_empty():
		return ENEMY_ID_SHIELD_GUARD

	var total_weight: float = 0.0
	for unit_id: String in unit_ids:
		total_weight += float(weights.get(unit_id, 1.0))

	var roll: float = randf() * total_weight
	var current_weight: float = 0.0
	for unit_id: String in unit_ids:
		current_weight += float(weights.get(unit_id, 1.0))
		if roll <= current_weight:
			return unit_id

	return unit_ids[unit_ids.size() - 1]


func _pick_string(options: Array[String]) -> String:
	if options.is_empty():
		return ""

	return options[randi_range(0, options.size() - 1)]
