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
const ENEMY_ID_ELITE_IRON_BULWARK: String = "enemy_elite_iron_bulwark"
const ENEMY_ID_BOSS_EARTHBREAKER_COLOSSUS: String = "enemy_boss_earthbreaker_colossus"
const ENEMY_ID_BOSS_TREANT_OVERLORD: String = "enemy_boss_treant_overlord"
const ENEMY_ID_BOSS_SWAMP_DEVOURER: String = "enemy_boss_swamp_devourer"
const ENEMY_ID_BOSS_LAVA_COLOSSUS: String = "enemy_boss_lava_colossus"
const ENEMY_ID_CROSSBOW_RAIDER: String = "enemy_crossbow_raider"
const ENEMY_ID_FLAME_IMP: String = "enemy_flame_imp"
const ENEMY_ID_ELITE_SHADOW_REAPER: String = "enemy_elite_shadow_reaper"
const ENEMY_ID_ELITE_FROST_THORN_WITCH: String = "enemy_elite_frost_thorn_witch"
const ENEMY_ID_BOSS_VOID_CANNON: String = "enemy_boss_void_cannon"
const ENEMY_ID_DARK_ACOLYTE: String = "enemy_dark_acolyte"
const ENEMY_ID_WAR_DRUMMER: String = "enemy_war_drummer"
const ENEMY_ID_ELITE_BLOOD_ORACLE: String = "enemy_elite_blood_oracle"
const ENEMY_ID_ELITE_BLOOD_BANNER_WARLORD: String = "enemy_elite_blood_banner_warlord"
const ENEMY_ID_BOSS_ABYSS_HIEROPHANT: String = "enemy_boss_abyss_hierophant"
const ENEMY_ID_BOSS_SCOURGE_LORD: String = "enemy_boss_scourge_lord"
const ENEMY_ID_BOSS_FAELORD_OF_THE_GROVE: String = "enemy_boss_faelord_of_the_grove"
const ENEMY_ID_GRAVE_CALLER: String = "enemy_grave_caller"
const ENEMY_ID_BONE_CARRIER: String = "enemy_bone_carrier"
const ENEMY_ID_PUPPET_BINDER: String = "enemy_puppet_binder"
const ENEMY_ID_GIANT_MAGGOT: String = "enemy_giant_maggot"
const ENEMY_ID_ELITE_MAGGOT_AMALGAM: String = "enemy_elite_maggot_amalgam"
const ENEMY_ID_ELITE_MIRROR_CARAPACE_BEETLE: String = "enemy_elite_mirror_carapace_beetle"
const ENEMY_ID_COMMON_SLIME: String = "enemy_common_slime"
const ENEMY_ID_FROST_SLIME: String = "enemy_frost_slime"
const ENEMY_ID_FLAME_SLIME: String = "enemy_flame_slime"
const ENEMY_ID_VENOM_SLIME: String = "enemy_venom_slime"
const ENEMY_ID_GIANT_SLIME: String = "enemy_giant_slime"
const ENEMY_ID_GOBLIN_GRUNT: String = "enemy_goblin_grunt"

const NORMAL_TANK_ENEMY_IDS: Array[String] = [ENEMY_ID_SHIELD_GUARD, ENEMY_ID_STONEBACK_BEAST, ENEMY_ID_BONE_CARRIER, ENEMY_ID_COMMON_SLIME]
const ELITE_TANK_ENEMY_IDS: Array[String] = [ENEMY_ID_ELITE_IRON_WARDEN, ENEMY_ID_ELITE_MAGGOT_AMALGAM, ENEMY_ID_GIANT_SLIME, ENEMY_ID_ELITE_IRON_BULWARK, ENEMY_ID_ELITE_MIRROR_CARAPACE_BEETLE]
const BOSS_TANK_ENEMY_IDS: Array[String] = [ENEMY_ID_BOSS_EARTHBREAKER_COLOSSUS, ENEMY_ID_BOSS_TREANT_OVERLORD, ENEMY_ID_BOSS_SWAMP_DEVOURER, ENEMY_ID_BOSS_LAVA_COLOSSUS]
const NORMAL_DAMAGE_ENEMY_IDS: Array[String] = [ENEMY_ID_CROSSBOW_RAIDER, ENEMY_ID_FLAME_IMP, ENEMY_ID_GIANT_MAGGOT, ENEMY_ID_FLAME_SLIME, ENEMY_ID_VENOM_SLIME, ENEMY_ID_GOBLIN_GRUNT]
const ELITE_DAMAGE_ENEMY_IDS: Array[String] = [ENEMY_ID_ELITE_SHADOW_REAPER]
const BOSS_DAMAGE_ENEMY_IDS: Array[String] = [ENEMY_ID_BOSS_VOID_CANNON]
const NORMAL_SUPPORT_ENEMY_IDS: Array[String] = [ENEMY_ID_DARK_ACOLYTE, ENEMY_ID_WAR_DRUMMER, ENEMY_ID_GRAVE_CALLER, ENEMY_ID_FROST_SLIME]
const ELITE_SUPPORT_ENEMY_IDS: Array[String] = [ENEMY_ID_ELITE_BLOOD_ORACLE, ENEMY_ID_PUPPET_BINDER, ENEMY_ID_ELITE_FROST_THORN_WITCH, ENEMY_ID_ELITE_BLOOD_BANNER_WARLORD]
const BOSS_SUPPORT_ENEMY_IDS: Array[String] = [ENEMY_ID_BOSS_ABYSS_HIEROPHANT, ENEMY_ID_BOSS_SCOURGE_LORD, ENEMY_ID_BOSS_FAELORD_OF_THE_GROVE]

const SHIELD_GUARD_DATA: Resource = preload("res://data/enemies/shield_guard.tres")
const STONEBACK_BEAST_DATA: Resource = preload("res://data/enemies/stoneback_beast.tres")
const ELITE_IRON_WARDEN_DATA: Resource = preload("res://data/enemies/elite_iron_warden.tres")
const ELITE_IRON_BULWARK_DATA: Resource = preload("res://data/enemies/elite_iron_bulwark.tres")
const BOSS_EARTHBREAKER_COLOSSUS_DATA: Resource = preload("res://data/enemies/boss_earthbreaker_colossus.tres")
const BOSS_TREANT_OVERLORD_DATA: Resource = preload("res://data/enemies/boss_treant_overlord.tres")
const BOSS_SWAMP_DEVOURER_DATA: Resource = preload("res://data/enemies/boss_swamp_devourer.tres")
const BOSS_LAVA_COLOSSUS_DATA: Resource = preload("res://data/enemies/boss_lava_colossus.tres")
const CROSSBOW_RAIDER_DATA: Resource = preload("res://data/enemies/crossbow_raider.tres")
const FLAME_IMP_DATA: Resource = preload("res://data/enemies/flame_imp.tres")
const ELITE_SHADOW_REAPER_DATA: Resource = preload("res://data/enemies/elite_shadow_reaper.tres")
const ELITE_FROST_THORN_WITCH_DATA: Resource = preload("res://data/enemies/elite_frost_thorn_witch.tres")
const BOSS_VOID_CANNON_DATA: Resource = preload("res://data/enemies/boss_void_cannon.tres")
const DARK_ACOLYTE_DATA: Resource = preload("res://data/enemies/dark_acolyte.tres")
const WAR_DRUMMER_DATA: Resource = preload("res://data/enemies/war_drummer.tres")
const ELITE_BLOOD_ORACLE_DATA: Resource = preload("res://data/enemies/elite_blood_oracle.tres")
const ELITE_BLOOD_BANNER_WARLORD_DATA: Resource = preload("res://data/enemies/elite_blood_banner_warlord.tres")
const BOSS_ABYSS_HIEROPHANT_DATA: Resource = preload("res://data/enemies/boss_abyss_hierophant.tres")
const BOSS_SCOURGE_LORD_DATA: Resource = preload("res://data/enemies/boss_scourge_lord.tres")
const BOSS_FAELORD_OF_THE_GROVE_DATA: Resource = preload("res://data/enemies/boss_faelord_of_the_grove.tres")
const GRAVE_CALLER_DATA: Resource = preload("res://data/enemies/grave_caller.tres")
const BONE_CARRIER_DATA: Resource = preload("res://data/enemies/bone_carrier.tres")
const PUPPET_BINDER_DATA: Resource = preload("res://data/enemies/puppet_binder.tres")
const GIANT_MAGGOT_DATA: Resource = preload("res://data/enemies/giant_maggot.tres")
const MAGGOT_AMALGAM_DATA: Resource = preload("res://data/enemies/maggot_amalgam.tres")
const ELITE_MIRROR_CARAPACE_BEETLE_DATA: Resource = preload("res://data/enemies/elite_mirror_carapace_beetle.tres")
const COMMON_SLIME_DATA: Resource = preload("res://data/enemies/common_slime.tres")
const FROST_SLIME_DATA: Resource = preload("res://data/enemies/frost_slime.tres")
const FLAME_SLIME_DATA: Resource = preload("res://data/enemies/flame_slime.tres")
const VENOM_SLIME_DATA: Resource = preload("res://data/enemies/venom_slime.tres")
const GIANT_SLIME_DATA: Resource = preload("res://data/enemies/giant_slime.tres")
const GOBLIN_GRUNT_DATA: Resource = preload("res://data/enemies/goblin_grunt.tres")


func get_unit_data_by_id(unit_id: String) -> Resource:
	match unit_id:
		ENEMY_ID_SHIELD_GUARD:
			return SHIELD_GUARD_DATA
		ENEMY_ID_STONEBACK_BEAST:
			return STONEBACK_BEAST_DATA
		ENEMY_ID_ELITE_IRON_WARDEN:
			return ELITE_IRON_WARDEN_DATA
		ENEMY_ID_ELITE_IRON_BULWARK:
			return ELITE_IRON_BULWARK_DATA
		ENEMY_ID_BOSS_EARTHBREAKER_COLOSSUS:
			return BOSS_EARTHBREAKER_COLOSSUS_DATA
		ENEMY_ID_BOSS_TREANT_OVERLORD:
			return BOSS_TREANT_OVERLORD_DATA
		ENEMY_ID_BOSS_SWAMP_DEVOURER:
			return BOSS_SWAMP_DEVOURER_DATA
		ENEMY_ID_BOSS_LAVA_COLOSSUS:
			return BOSS_LAVA_COLOSSUS_DATA
		ENEMY_ID_CROSSBOW_RAIDER:
			return CROSSBOW_RAIDER_DATA
		ENEMY_ID_FLAME_IMP:
			return FLAME_IMP_DATA
		ENEMY_ID_ELITE_SHADOW_REAPER:
			return ELITE_SHADOW_REAPER_DATA
		ENEMY_ID_ELITE_FROST_THORN_WITCH:
			return ELITE_FROST_THORN_WITCH_DATA
		ENEMY_ID_BOSS_VOID_CANNON:
			return BOSS_VOID_CANNON_DATA
		ENEMY_ID_DARK_ACOLYTE:
			return DARK_ACOLYTE_DATA
		ENEMY_ID_WAR_DRUMMER:
			return WAR_DRUMMER_DATA
		ENEMY_ID_ELITE_BLOOD_ORACLE:
			return ELITE_BLOOD_ORACLE_DATA
		ENEMY_ID_ELITE_BLOOD_BANNER_WARLORD:
			return ELITE_BLOOD_BANNER_WARLORD_DATA
		ENEMY_ID_BOSS_ABYSS_HIEROPHANT:
			return BOSS_ABYSS_HIEROPHANT_DATA
		ENEMY_ID_BOSS_SCOURGE_LORD:
			return BOSS_SCOURGE_LORD_DATA
		ENEMY_ID_BOSS_FAELORD_OF_THE_GROVE:
			return BOSS_FAELORD_OF_THE_GROVE_DATA
		ENEMY_ID_GRAVE_CALLER:
			return GRAVE_CALLER_DATA
		ENEMY_ID_BONE_CARRIER:
			return BONE_CARRIER_DATA
		ENEMY_ID_PUPPET_BINDER:
			return PUPPET_BINDER_DATA
		ENEMY_ID_GIANT_MAGGOT:
			return GIANT_MAGGOT_DATA
		ENEMY_ID_ELITE_MAGGOT_AMALGAM:
			return MAGGOT_AMALGAM_DATA
		ENEMY_ID_ELITE_MIRROR_CARAPACE_BEETLE:
			return ELITE_MIRROR_CARAPACE_BEETLE_DATA
		ENEMY_ID_COMMON_SLIME:
			return COMMON_SLIME_DATA
		ENEMY_ID_FROST_SLIME:
			return FROST_SLIME_DATA
		ENEMY_ID_FLAME_SLIME:
			return FLAME_SLIME_DATA
		ENEMY_ID_VENOM_SLIME:
			return VENOM_SLIME_DATA
		ENEMY_ID_GIANT_SLIME:
			return GIANT_SLIME_DATA
		ENEMY_ID_GOBLIN_GRUNT:
			return GOBLIN_GRUNT_DATA
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
	var unit_data: Resource = get_unit_data_by_id(unit_id)
	if unit_data != null:
		var tier: Variant = unit_data.get("enemy_tier")
		if tier != null:
			var tier_str: String = str(tier)
			if tier_str == "ELITE":
				return true
			if tier_str == "BOSS":
				return false
			if tier_str == "NORMAL":
				return false
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
