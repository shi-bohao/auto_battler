class_name DefaultEncounterBuilder
extends RefCounted

const ENEMY_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/enemy_catalog.gd")
const ENCOUNTER_GENERATOR_SCRIPT: Script = preload("res://scripts/encounter/encounter_generator.gd")

const ENCOUNTER_TYPE_NORMAL: String = "NORMAL"
const ENCOUNTER_TYPE_ELITE: String = "ELITE"
const ENCOUNTER_TYPE_BOSS: String = "BOSS"

const ENEMY_ID_SHIELD_GUARD: String = "enemy_shield_guard"
const ENEMY_ID_STONEBACK_BEAST: String = "enemy_stoneback_beast"
const ENEMY_ID_ELITE_IRON_WARDEN: String = "enemy_elite_iron_warden"
const ENEMY_ID_BOSS_EARTHBREAKER_COLOSSUS: String = "enemy_boss_earthbreaker_colossus"
const ENEMY_ID_CROSSBOW_RAIDER: String = "enemy_crossbow_raider"
const ENEMY_ID_FLAME_IMP: String = "enemy_flame_imp"
const ENEMY_ID_DARK_ACOLYTE: String = "enemy_dark_acolyte"
const ENEMY_ID_WAR_DRUMMER: String = "enemy_war_drummer"
const ENEMY_ID_ELITE_BLOOD_ORACLE: String = "enemy_elite_blood_oracle"
const ENEMY_ID_GRAVE_CALLER: String = "enemy_grave_caller"
const ENEMY_ID_BONE_CARRIER: String = "enemy_bone_carrier"
const ENEMY_ID_PUPPET_BINDER: String = "enemy_puppet_binder"

var enemy_catalog: Variant = ENEMY_CATALOG_SCRIPT.new()
var encounter_generator: Variant = ENCOUNTER_GENERATOR_SCRIPT.new()


func build_default_encounters() -> Array[Dictionary]:
	var encounters: Array[Dictionary] = []

	var round_1_units: Array[Dictionary] = []
	round_1_units.append(_create_enemy(ENEMY_ID_SHIELD_GUARD, Vector2(760, 240)))
	round_1_units.append(_create_enemy(ENEMY_ID_CROSSBOW_RAIDER, Vector2(880, 330)))
	encounters.append(_create_encounter(1, "敌方巡逻队", ENCOUNTER_TYPE_NORMAL, round_1_units))

	var round_2_units: Array[Dictionary] = []
	round_2_units.append(_create_enemy(ENEMY_ID_SHIELD_GUARD, Vector2(760, 230)))
	round_2_units.append(_create_enemy(ENEMY_ID_FLAME_IMP, Vector2(900, 310)))
	encounters.append(_create_encounter(2, "小鬼护卫", ENCOUNTER_TYPE_NORMAL, round_2_units))

	var round_3_units: Array[Dictionary] = []
	round_3_units.append(_create_enemy(ENEMY_ID_STONEBACK_BEAST, Vector2(760, 320)))
	round_3_units.append(_create_enemy(ENEMY_ID_CROSSBOW_RAIDER, Vector2(900, 220)))
	round_3_units.append(_create_enemy(ENEMY_ID_DARK_ACOLYTE, Vector2(900, 500)))
	encounters.append(_create_encounter(3, "石背护卫队", ENCOUNTER_TYPE_NORMAL, round_3_units))

	var round_4_units: Array[Dictionary] = []
	round_4_units.append(_create_enemy(ENEMY_ID_SHIELD_GUARD, Vector2(760, 260)))
	round_4_units.append(_create_enemy(ENEMY_ID_FLAME_IMP, Vector2(900, 330)))
	round_4_units.append(_create_enemy(ENEMY_ID_WAR_DRUMMER, Vector2(860, 500)))
	encounters.append(_create_encounter(4, "战鼓巡逻队", ENCOUNTER_TYPE_NORMAL, round_4_units))

	var round_5_units: Array[Dictionary] = []
	round_5_units.append(_create_enemy(ENEMY_ID_ELITE_IRON_WARDEN, Vector2(760, 250)))
	round_5_units.append(_create_enemy(ENEMY_ID_CROSSBOW_RAIDER, Vector2(900, 330)))
	round_5_units.append(_create_enemy(ENEMY_ID_DARK_ACOLYTE, Vector2(900, 430)))
	encounters.append(_create_encounter(5, "铁壁守卫", ENCOUNTER_TYPE_ELITE, round_5_units, 1.20, 1.15))

	var round_6_units: Array[Dictionary] = []
	round_6_units.append(_create_enemy(ENEMY_ID_STONEBACK_BEAST, Vector2(760, 220)))
	round_6_units.append(_create_enemy(ENEMY_ID_SHIELD_GUARD, Vector2(760, 360)))
	round_6_units.append(_create_enemy(ENEMY_ID_FLAME_IMP, Vector2(900, 320)))
	round_6_units.append(_create_enemy(ENEMY_ID_GRAVE_CALLER, Vector2(900, 440)))
	encounters.append(_create_encounter(6, "强化敌方防线", ENCOUNTER_TYPE_NORMAL, round_6_units, 1.20, 1.15))

	var round_7_units: Array[Dictionary] = []
	round_7_units.append(_create_enemy(ENEMY_ID_FLAME_IMP, Vector2(900, 210)))
	round_7_units.append(_create_enemy(ENEMY_ID_SHIELD_GUARD, Vector2(760, 330)))
	round_7_units.append(_create_enemy(ENEMY_ID_CROSSBOW_RAIDER, Vector2(900, 330)))
	round_7_units.append(_create_enemy(ENEMY_ID_DARK_ACOLYTE, Vector2(900, 460)))
	encounters.append(_create_encounter(7, "烈焰护卫队", ENCOUNTER_TYPE_NORMAL, round_7_units, 1.25, 1.20))

	var round_8_units: Array[Dictionary] = []
	round_8_units.append(_create_enemy(ENEMY_ID_SHIELD_GUARD, Vector2(760, 250)))
	round_8_units.append(_create_enemy(ENEMY_ID_BONE_CARRIER, Vector2(760, 420)))
	round_8_units.append(_create_enemy(ENEMY_ID_CROSSBOW_RAIDER, Vector2(900, 220)))
	round_8_units.append(_create_enemy(ENEMY_ID_FLAME_IMP, Vector2(900, 440)))
	round_8_units.append(_create_enemy(ENEMY_ID_WAR_DRUMMER, Vector2(860, 330)))
	encounters.append(_create_encounter(8, "敌方阵线", ENCOUNTER_TYPE_NORMAL, round_8_units, 1.30, 1.25))

	var round_9_units: Array[Dictionary] = []
	round_9_units.append(_create_enemy(ENEMY_ID_DARK_ACOLYTE, Vector2(900, 220)))
	round_9_units.append(_create_enemy(ENEMY_ID_WAR_DRUMMER, Vector2(860, 340)))
	round_9_units.append(_create_enemy(ENEMY_ID_SHIELD_GUARD, Vector2(760, 460)))
	round_9_units.append(_create_enemy(ENEMY_ID_CROSSBOW_RAIDER, Vector2(900, 340)))
	round_9_units.append(_create_enemy(ENEMY_ID_FLAME_IMP, Vector2(900, 460)))
	encounters.append(_create_encounter(9, "敌方先锋", ENCOUNTER_TYPE_NORMAL, round_9_units, 1.35, 1.30))

	var round_10_units: Array[Dictionary] = []
	round_10_units.append(_create_enemy(ENEMY_ID_BOSS_EARTHBREAKER_COLOSSUS, Vector2(760, 330), 1.0, 1.0, 1, true))
	round_10_units.append(_create_enemy(ENEMY_ID_CROSSBOW_RAIDER, Vector2(900, 240)))
	round_10_units.append(_create_enemy(ENEMY_ID_PUPPET_BINDER, Vector2(900, 430)))
	encounters.append(_create_encounter(10, "Boss：裂地巨像", ENCOUNTER_TYPE_BOSS, round_10_units, 1.0, 1.0))

	for generated_round: int in range(11, 31):
		encounters.append(encounter_generator.create_random_encounter(generated_round))

	return encounters


func _create_encounter(
	current_round: int,
	encounter_name: String,
	encounter_type: String,
	enemy_units: Array[Dictionary],
	hp_multiplier_override: float = -1.0,
	attack_multiplier_override: float = -1.0
) -> Dictionary:
	var multiplier: float = 1.0 + float(maxi(current_round - 1, 0)) * 0.05
	var hp_multiplier: float = multiplier if hp_multiplier_override < 0.0 else hp_multiplier_override
	var attack_multiplier: float = multiplier if attack_multiplier_override < 0.0 else attack_multiplier_override

	return {
		"encounter_id": "round_" + str(current_round),
		"encounter_name": encounter_name,
		"encounter_type": encounter_type,
		"enemy_hp_multiplier": hp_multiplier,
		"enemy_attack_multiplier": attack_multiplier,
		"enemy_defense_bonus": 0,
		"enemy_mana_regen_multiplier": 1.0,
		"enemy_count": enemy_units.size(),
		"enemy_units": enemy_units,
	}


func _create_enemy(
	unit_id: String,
	position: Vector2,
	hp_multiplier: float = 1.0,
	attack_multiplier: float = 1.0,
	star: int = 1,
	is_boss: bool = false
) -> Dictionary:
	var safe_star: int = clampi(star, 1, 3)
	return {
		"unit_id": unit_id,
		"display_name": enemy_catalog.create_enemy_display_name(unit_id, safe_star, is_boss),
		"position": position,
		"star": safe_star,
		"is_boss": is_boss,
		"hp_multiplier": hp_multiplier,
		"attack_multiplier": attack_multiplier,
		"defense_bonus": 0,
		"mana_regen_multiplier": 1.0,
	}
