class_name EnemyCatalog
extends RefCounted

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
const ENEMY_ID_BOSS_VOID_CANNON: String = "enemy_boss_void_cannon"
const ENEMY_ID_DARK_ACOLYTE: String = "enemy_dark_acolyte"
const ENEMY_ID_WAR_DRUMMER: String = "enemy_war_drummer"
const ENEMY_ID_ELITE_BLOOD_ORACLE: String = "enemy_elite_blood_oracle"
const ENEMY_ID_BOSS_ABYSS_HIEROPHANT: String = "enemy_boss_abyss_hierophant"
const ENEMY_ID_GRAVE_CALLER: String = "enemy_grave_caller"
const ENEMY_ID_BONE_CARRIER: String = "enemy_bone_carrier"
const ENEMY_ID_PUPPET_BINDER: String = "enemy_puppet_binder"

const NORMAL_TANK_ENEMY_IDS: Array[String] = [ENEMY_ID_SHIELD_GUARD, ENEMY_ID_STONEBACK_BEAST, ENEMY_ID_BONE_CARRIER]
const ELITE_TANK_ENEMY_IDS: Array[String] = [ENEMY_ID_ELITE_IRON_WARDEN]
const BOSS_TANK_ENEMY_IDS: Array[String] = [ENEMY_ID_BOSS_EARTHBREAKER_COLOSSUS]
const NORMAL_DAMAGE_ENEMY_IDS: Array[String] = [ENEMY_ID_CROSSBOW_RAIDER, ENEMY_ID_FLAME_IMP]
const ELITE_DAMAGE_ENEMY_IDS: Array[String] = [ENEMY_ID_ELITE_SHADOW_REAPER]
const BOSS_DAMAGE_ENEMY_IDS: Array[String] = [ENEMY_ID_BOSS_VOID_CANNON]
const NORMAL_SUPPORT_ENEMY_IDS: Array[String] = [ENEMY_ID_DARK_ACOLYTE, ENEMY_ID_WAR_DRUMMER, ENEMY_ID_GRAVE_CALLER]
const ELITE_SUPPORT_ENEMY_IDS: Array[String] = [ENEMY_ID_ELITE_BLOOD_ORACLE, ENEMY_ID_PUPPET_BINDER]
const BOSS_SUPPORT_ENEMY_IDS: Array[String] = [ENEMY_ID_BOSS_ABYSS_HIEROPHANT]

const SHIELD_GUARD_DATA: Resource = preload("res://data/enemies/shield_guard.tres")
const STONEBACK_BEAST_DATA: Resource = preload("res://data/enemies/stoneback_beast.tres")
const ELITE_IRON_WARDEN_DATA: Resource = preload("res://data/enemies/elite_iron_warden.tres")
const BOSS_EARTHBREAKER_COLOSSUS_DATA: Resource = preload("res://data/enemies/boss_earthbreaker_colossus.tres")
const CROSSBOW_RAIDER_DATA: Resource = preload("res://data/enemies/crossbow_raider.tres")
const FLAME_IMP_DATA: Resource = preload("res://data/enemies/flame_imp.tres")
const ELITE_SHADOW_REAPER_DATA: Resource = preload("res://data/enemies/elite_shadow_reaper.tres")
const BOSS_VOID_CANNON_DATA: Resource = preload("res://data/enemies/boss_void_cannon.tres")
const DARK_ACOLYTE_DATA: Resource = preload("res://data/enemies/dark_acolyte.tres")
const WAR_DRUMMER_DATA: Resource = preload("res://data/enemies/war_drummer.tres")
const ELITE_BLOOD_ORACLE_DATA: Resource = preload("res://data/enemies/elite_blood_oracle.tres")
const BOSS_ABYSS_HIEROPHANT_DATA: Resource = preload("res://data/enemies/boss_abyss_hierophant.tres")
const GRAVE_CALLER_DATA: Resource = preload("res://data/enemies/grave_caller.tres")
const BONE_CARRIER_DATA: Resource = preload("res://data/enemies/bone_carrier.tres")
const PUPPET_BINDER_DATA: Resource = preload("res://data/enemies/puppet_binder.tres")


func get_unit_data_by_id(unit_id: String) -> Resource:
	match unit_id:
		ENEMY_ID_SHIELD_GUARD:
			return SHIELD_GUARD_DATA
		ENEMY_ID_STONEBACK_BEAST:
			return STONEBACK_BEAST_DATA
		ENEMY_ID_ELITE_IRON_WARDEN:
			return ELITE_IRON_WARDEN_DATA
		ENEMY_ID_BOSS_EARTHBREAKER_COLOSSUS:
			return BOSS_EARTHBREAKER_COLOSSUS_DATA
		ENEMY_ID_CROSSBOW_RAIDER:
			return CROSSBOW_RAIDER_DATA
		ENEMY_ID_FLAME_IMP:
			return FLAME_IMP_DATA
		ENEMY_ID_ELITE_SHADOW_REAPER:
			return ELITE_SHADOW_REAPER_DATA
		ENEMY_ID_BOSS_VOID_CANNON:
			return BOSS_VOID_CANNON_DATA
		ENEMY_ID_DARK_ACOLYTE:
			return DARK_ACOLYTE_DATA
		ENEMY_ID_WAR_DRUMMER:
			return WAR_DRUMMER_DATA
		ENEMY_ID_ELITE_BLOOD_ORACLE:
			return ELITE_BLOOD_ORACLE_DATA
		ENEMY_ID_BOSS_ABYSS_HIEROPHANT:
			return BOSS_ABYSS_HIEROPHANT_DATA
		ENEMY_ID_GRAVE_CALLER:
			return GRAVE_CALLER_DATA
		ENEMY_ID_BONE_CARRIER:
			return BONE_CARRIER_DATA
		ENEMY_ID_PUPPET_BINDER:
			return PUPPET_BINDER_DATA
		_:
			push_warning("Unknown encounter unit id: " + unit_id)
			return null


func get_unit_role(unit_id: String) -> String:
	var unit_data: Resource = get_unit_data_by_id(unit_id)
	if unit_data != null:
		var configured_role: Variant = unit_data.get("role")
		if configured_role != null and str(configured_role).strip_edges() != "":
			return str(configured_role)

	match unit_id:
		"warrior", "tank":
			return ROLE_TANK
		"priest", "bard":
			return ROLE_SUPPORT
		_:
			return ROLE_DAMAGE


func get_unit_type_display_name(unit_id: String) -> String:
	var unit_data: Resource = get_unit_data_by_id(unit_id)
	if unit_data != null:
		var configured_cn_name: Variant = unit_data.get("unit_name_cn")
		if configured_cn_name != null and str(configured_cn_name).strip_edges() != "":
			return str(configured_cn_name)

		var configured_name: Variant = unit_data.get("unit_name")
		if configured_name != null and str(configured_name).strip_edges() != "":
			return str(configured_name)

	return unit_id.capitalize()


func create_enemy_display_name(unit_id: String, star: int, is_boss: bool) -> String:
	var unit_name: String = get_unit_type_display_name(unit_id)
	if is_boss:
		return unit_name + " " + get_star_text(star)

	return unit_name + " " + get_star_text(star)


func get_star_text(star: int) -> String:
	var star_text: String = ""
	var safe_star: int = clampi(star, 1, 3)
	for _index: int in range(safe_star):
		star_text += "*"

	return star_text


func is_elite_enemy_id(unit_id: String) -> bool:
	return unit_id.begins_with("enemy_elite_")


func get_available_unit_ids_by_role(role: String, encounter_type: String = ENCOUNTER_TYPE_NORMAL) -> Array[String]:
	var unit_ids: Array[String] = []
	var ordered_unit_ids: Array[String] = get_enemy_ids_by_role_and_encounter_type(role, encounter_type)
	for unit_id: String in ordered_unit_ids:
		if get_unit_role(unit_id) == role and get_unit_data_by_id(unit_id) != null:
			unit_ids.append(unit_id)

	return unit_ids


func get_fallback_unit_ids() -> Array[String]:
	var unit_ids: Array[String] = []
	var ordered_unit_ids: Array[String] = []
	ordered_unit_ids.append_array(NORMAL_TANK_ENEMY_IDS)
	ordered_unit_ids.append_array(NORMAL_DAMAGE_ENEMY_IDS)
	ordered_unit_ids.append_array(NORMAL_SUPPORT_ENEMY_IDS)
	for unit_id: String in ordered_unit_ids:
		if get_unit_data_by_id(unit_id) != null:
			unit_ids.append(unit_id)

	return unit_ids


func get_enemy_ids_by_role_and_encounter_type(role: String, encounter_type: String) -> Array[String]:
	var unit_ids: Array[String] = []
	match role:
		ROLE_TANK:
			unit_ids.append_array(NORMAL_TANK_ENEMY_IDS)
			if encounter_type == ENCOUNTER_TYPE_ELITE:
				unit_ids.append_array(ELITE_TANK_ENEMY_IDS)
			elif encounter_type == ENCOUNTER_TYPE_BOSS:
				unit_ids.append_array(BOSS_TANK_ENEMY_IDS)
		ROLE_DAMAGE:
			unit_ids.append_array(NORMAL_DAMAGE_ENEMY_IDS)
			if encounter_type == ENCOUNTER_TYPE_ELITE:
				unit_ids.append_array(ELITE_DAMAGE_ENEMY_IDS)
			elif encounter_type == ENCOUNTER_TYPE_BOSS:
				unit_ids.append_array(BOSS_DAMAGE_ENEMY_IDS)
		ROLE_SUPPORT:
			unit_ids.append_array(NORMAL_SUPPORT_ENEMY_IDS)
			if encounter_type == ENCOUNTER_TYPE_ELITE:
				unit_ids.append_array(ELITE_SUPPORT_ENEMY_IDS)
			elif encounter_type == ENCOUNTER_TYPE_BOSS:
				unit_ids.append_array(BOSS_SUPPORT_ENEMY_IDS)

	return unit_ids


func get_boss_enemy_ids() -> Array[String]:
	var boss_ids: Array[String] = []
	boss_ids.append_array(BOSS_TANK_ENEMY_IDS)
	boss_ids.append_array(BOSS_DAMAGE_ENEMY_IDS)
	boss_ids.append_array(BOSS_SUPPORT_ENEMY_IDS)
	return boss_ids
