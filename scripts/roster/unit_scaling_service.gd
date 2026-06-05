class_name UnitScalingService
extends RefCounted

const MAX_STAR: int = 3


func create_scaled_unit_data(roster_item: Dictionary, hp_multiplier: float, attack_multiplier: float, global_bonuses: Dictionary = {}) -> Resource:
	var base_data: Resource = roster_item["unit_data"] as Resource
	var configured_data: Resource = base_data.duplicate(true) as Resource
	var star: int = int(roster_item.get("star", 1))
	var unit_type: String = str(roster_item.get("unit_id", ""))
	var star_growth: Dictionary = get_star_growth(unit_type, star)
	var base_max_hp: int = int(base_data.get("max_hp"))
	var base_attack_damage: int = int(base_data.get("attack_damage"))
	var base_defense: int = _get_int_property(base_data, "defense", 0)
	var base_attack_interval: float = _get_float_property(base_data, "attack_interval", 1.0)
	var base_move_speed: float = _get_float_property(base_data, "move_speed", 120.0)
	var base_crit_chance: float = _get_float_property(base_data, "crit_chance", 0.0)
	var base_crit_damage_multiplier: float = _get_float_property(base_data, "crit_damage_multiplier", 1.5)
	var boosted_max_hp: int = maxi(1, int(round(float(base_max_hp) * hp_multiplier * float(star_growth["max_hp_multiplier"]))))
	var boosted_attack_damage: int = maxi(1, int(round(float(base_attack_damage) * attack_multiplier * float(star_growth["attack_damage_multiplier"]))))
	var boosted_defense: int = maxi(0, base_defense + int(star_growth["defense_bonus"]))
	var boosted_attack_interval: float = maxf(0.1, base_attack_interval * float(star_growth["attack_interval_multiplier"]))
	var boosted_move_speed: float = maxf(1.0, base_move_speed * float(star_growth["move_speed_multiplier"]))
	var boosted_crit_chance: float = clampf(base_crit_chance + float(star_growth["crit_chance_bonus"]), 0.0, 1.0)
	var boosted_crit_damage_multiplier: float = maxf(1.0, base_crit_damage_multiplier + float(star_growth["crit_damage_multiplier_bonus"]))
	var display_name: String = str(roster_item.get("display_name", "Unit")) + " " + _get_star_text(star)

	configured_data.set("max_hp", boosted_max_hp)
	configured_data.set("attack_damage", boosted_attack_damage)
	configured_data.set("defense", boosted_defense)
	configured_data.set("attack_interval", boosted_attack_interval)
	configured_data.set("move_speed", boosted_move_speed)
	configured_data.set("crit_chance", boosted_crit_chance)
	configured_data.set("crit_damage_multiplier", boosted_crit_damage_multiplier)
	configured_data.set("star", star)
	configured_data.set("unit_name", display_name)
	configured_data.set("unit_name_cn", display_name)
	_apply_permanent_stat_bonuses(configured_data, roster_item)
	_apply_global_stat_bonuses(configured_data, global_bonuses)
	return configured_data


func get_star_growth(unit_type: String, star: int) -> Dictionary:
	var safe_star: int = clampi(star, 1, MAX_STAR)

	match unit_type:
		"warrior":
			return _get_warrior_star_growth(safe_star)
		"archer":
			return _get_archer_star_growth(safe_star)
		"assassin":
			return _get_assassin_star_growth(safe_star)
		"tank":
			return _get_tank_star_growth(safe_star)
		"mage":
			return _get_mage_star_growth(safe_star)
		"priest":
			return _get_priest_star_growth(safe_star)
		"bard":
			return _get_bard_star_growth(safe_star)
		"forest_druid":
			return _get_forest_druid_star_growth(safe_star)
		"plague_caster":
			return _get_plague_caster_star_growth(safe_star)
		"guardian_captain":
			return _get_guardian_captain_star_growth(safe_star)
		"wind_chanter":
			return _get_wind_chanter_star_growth(safe_star)
		"greatsword_knight":
			return _get_greatsword_knight_star_growth(safe_star)
		"bomb_thrower":
			return _get_bomb_thrower_star_growth(safe_star)
		"cleric":
			return _get_cleric_star_growth(safe_star)
		"alchemist":
			return _get_alchemist_star_growth(safe_star)
		"necromancer":
			return _get_necromancer_star_growth(safe_star)
		"puppet_warlock":
			return _get_puppet_warlock_star_growth(safe_star)
		"soul_binder":
			return _get_soul_binder_star_growth(safe_star)
		"starforged_vanguard":
			return _get_starforged_vanguard_star_growth(safe_star)
		"arcane_artillerist":
			return _get_arcane_artillerist_star_growth(safe_star)
		"venom_matriarch":
			return _get_venom_matriarch_star_growth(safe_star)
		"dawnbell_saint":
			return _get_dawnbell_saint_star_growth(safe_star)
		"nightblade_captain":
			return _get_nightblade_captain_star_growth(safe_star)
		"bloodbound_berserker":
			return _get_bloodbound_berserker_star_growth(safe_star)
		"prism_weaver":
			return _get_prism_weaver_star_growth(safe_star)
		"frost_sentry":
			return _get_frost_sentry_star_growth(safe_star)
		"vine_binder":
			return _get_vine_binder_star_growth(safe_star)
		"thundermaul_vanguard":
			return _get_thundermaul_vanguard_star_growth(safe_star)
		"frost_prism_mage":
			return _get_frost_prism_mage_star_growth(safe_star)
		"taunt_banneret":
			return _get_taunt_banneret_star_growth(safe_star)
		"bone_acolyte":
			return _get_bone_acolyte_star_growth(safe_star)
		"grave_warden":
			return _get_grave_warden_star_growth(safe_star)
		"summoned_skeleton":
			return _get_summoned_skeleton_star_growth(safe_star)
		"summoned_skeleton_warrior":
			return _get_summoned_skeleton_warrior_star_growth(safe_star)
		"summoned_skeleton_archer":
			return _get_summoned_skeleton_archer_star_growth(safe_star)
		"summoned_skeleton_mage":
			return _get_summoned_skeleton_mage_star_growth(safe_star)
		"summoned_puppet":
			return _get_summoned_puppet_star_growth(safe_star)
		"summoned_soul_puppet":
			return _get_summoned_soul_puppet_star_growth(safe_star)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_warrior_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.6, 1.25, 20, 1.0, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(2.4, 1.5, 45, 1.0, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_archer_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.25, 1.5, 0, 0.9, 1.0, 0.10, 0.0)
		3:
			return _create_star_growth(1.6, 2.1, 0, 0.75, 1.0, 0.20, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_assassin_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.3, 1.55, 0, 0.95, 1.15, 0.15, 0.25)
		3:
			return _create_star_growth(1.7, 2.2, 0, 0.9, 1.3, 0.30, 0.50)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_tank_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.7, 1.15, 35, 1.0, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(2.7, 1.35, 80, 1.0, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_mage_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.2, 1.65, 0, 0.95, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(1.45, 2.4, 0, 0.9, 1.0, 0.10, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_priest_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.35, 1.25, 5, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(1.8, 1.55, 15, 0.9, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_bard_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.35, 1.2, 5, 0.95, 1.05, 0.0, 0.0)
		3:
			return _create_star_growth(1.75, 1.45, 15, 0.9, 1.1, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_forest_druid_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.3, 1.25, 5, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(1.75, 1.55, 15, 0.9, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_plague_caster_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.25, 1.55, 0, 0.95, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(1.55, 2.2, 0, 0.9, 1.0, 0.10, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_guardian_captain_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.65, 1.2, 30, 1.0, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(2.5, 1.4, 70, 1.0, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_wind_chanter_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.35, 1.2, 5, 0.95, 1.05, 0.0, 0.0)
		3:
			return _create_star_growth(1.8, 1.45, 15, 0.9, 1.1, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_greatsword_knight_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.45, 1.45, 15, 0.95, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(2.0, 1.9, 35, 0.9, 1.0, 0.10, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_bomb_thrower_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.2, 1.55, 0, 0.95, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(1.5, 2.15, 0, 0.9, 1.0, 0.10, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_cleric_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.35, 1.25, 10, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(1.85, 1.55, 25, 0.9, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_alchemist_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.25, 1.55, 0, 0.95, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(1.55, 2.15, 0, 0.9, 1.0, 0.10, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_necromancer_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.3, 1.25, 5, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(1.75, 1.55, 15, 0.9, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_puppet_warlock_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.25, 1.45, 5, 0.95, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(1.6, 2.0, 15, 0.9, 1.0, 0.10, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_soul_binder_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.3, 1.25, 8, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(1.75, 1.55, 20, 0.9, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_starforged_vanguard_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.65, 1.18, 35, 1.0, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(2.45, 1.40, 80, 1.0, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_arcane_artillerist_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.22, 1.55, 0, 0.95, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(1.55, 2.20, 0, 0.9, 1.0, 0.12, 0.30)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_venom_matriarch_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.25, 1.45, 6, 0.95, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(1.65, 2.00, 18, 0.9, 1.0, 0.10, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_dawnbell_saint_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.35, 1.25, 12, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(1.9, 1.65, 30, 0.9, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_nightblade_captain_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.3, 1.5, 5, 0.92, 1.10, 0.12, 0.30)
		3:
			return _create_star_growth(1.75, 2.15, 15, 0.85, 1.20, 0.25, 0.65)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_bloodbound_berserker_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.45, 1.45, 12, 0.95, 1.05, 0.10, 0.20)
		3:
			return _create_star_growth(2.0, 2.05, 30, 0.9, 1.10, 0.20, 0.45)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_prism_weaver_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.3, 1.25, 5, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(1.7, 1.55, 15, 0.9, 1.0, 0.05, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_summoned_skeleton_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.45, 1.35, 6, 0.95, 1.05, 0.05, 0.0)
		3:
			return _create_star_growth(2.0, 1.8, 14, 0.9, 1.1, 0.10, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_summoned_skeleton_warrior_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.55, 1.25, 12, 0.98, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(2.15, 1.60, 28, 0.95, 1.05, 0.05, 0.10)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_summoned_skeleton_archer_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.35, 1.45, 3, 0.95, 1.05, 0.08, 0.0)
		3:
			return _create_star_growth(1.75, 2.0, 8, 0.9, 1.1, 0.16, 0.20)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_summoned_skeleton_mage_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.30, 1.50, 2, 0.95, 1.0, 0.03, 0.0)
		3:
			return _create_star_growth(1.65, 2.10, 6, 0.9, 1.0, 0.08, 0.20)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_summoned_puppet_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.55, 1.25, 15, 0.98, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(2.2, 1.55, 35, 0.95, 1.05, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_summoned_soul_puppet_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.55, 1.35, 12, 0.95, 1.05, 0.0, 0.0)
		3:
			return _create_star_growth(2.15, 1.75, 30, 0.9, 1.10, 0.05, 0.15)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_frost_sentry_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.20, 1.55, 0, 0.90, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(1.45, 2.20, 0, 0.85, 1.0, 0.10, 0.25)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_vine_binder_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.30, 1.25, 5, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(1.75, 1.55, 15, 0.90, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_thundermaul_vanguard_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.65, 1.15, 35, 1.0, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(2.50, 1.35, 80, 1.0, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_frost_prism_mage_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.22, 1.55, 0, 0.95, 1.0, 0.05, 0.0)
		3:
			return _create_star_growth(1.55, 2.20, 0, 0.90, 1.0, 0.12, 0.30)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_taunt_banneret_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.65, 1.18, 35, 1.0, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(2.50, 1.40, 80, 1.0, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_bone_acolyte_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.2, 1.15, 0, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(1.55, 1.45, 0, 0.9, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _get_grave_warden_star_growth(star: int) -> Dictionary:
	match star:
		2:
			return _create_star_growth(1.5, 1.2, 20, 0.95, 1.0, 0.0, 0.0)
		3:
			return _create_star_growth(2.1, 1.4, 45, 0.9, 1.0, 0.0, 0.0)
		_:
			return _create_star_growth(1.0, 1.0, 0, 1.0, 1.0, 0.0, 0.0)


func _create_star_growth(
	max_hp_multiplier: float,
	attack_damage_multiplier: float,
	defense_bonus: int,
	attack_interval_multiplier: float,
	move_speed_multiplier: float,
	crit_chance_bonus: float,
	crit_damage_multiplier_bonus: float
) -> Dictionary:
	return {
		"max_hp_multiplier": max_hp_multiplier,
		"attack_damage_multiplier": attack_damage_multiplier,
		"defense_bonus": defense_bonus,
		"attack_interval_multiplier": attack_interval_multiplier,
		"move_speed_multiplier": move_speed_multiplier,
		"crit_chance_bonus": crit_chance_bonus,
		"crit_damage_multiplier_bonus": crit_damage_multiplier_bonus,
	}


func _get_int_property(resource: Resource, property_name: String, default_value: int) -> int:
	if resource == null:
		return default_value

	var configured_value: Variant = resource.get(property_name)
	if configured_value == null:
		return default_value

	return int(configured_value)


func _get_float_property(resource: Resource, property_name: String, default_value: float) -> float:
	if resource == null:
		return default_value

	var configured_value: Variant = resource.get(property_name)
	if configured_value == null:
		return default_value

	return float(configured_value)


func _apply_permanent_stat_bonuses(configured_data: Resource, roster_item: Dictionary) -> void:
	if configured_data == null:
		return

	var bonuses_value: Variant = roster_item.get("permanent_stat_bonuses", {})
	if not (bonuses_value is Dictionary):
		return

	var bonuses: Dictionary = bonuses_value as Dictionary
	for stat_name_value: Variant in bonuses.keys():
		var stat_name: String = str(stat_name_value).strip_edges()
		if stat_name == "":
			continue

		_apply_permanent_stat_bonus(configured_data, stat_name, float(bonuses.get(stat_name_value, 0.0)))


func _apply_global_stat_bonuses(configured_data: Resource, global_bonuses: Dictionary) -> void:
	if configured_data == null or global_bonuses.is_empty():
		return

	for key: Variant in global_bonuses.keys():
		var key_str: String = str(key)
		var value: float = float(global_bonuses[key])
		if is_zero_approx(value):
			continue
		if key_str == "attack_speed_percent":
			var current_interval: Variant = configured_data.get("attack_interval")
			if current_interval == null:
				continue
			var adjusted_interval: float = float(current_interval) / (1.0 + value)
			_apply_permanent_stat_bonus(configured_data, "attack_interval", adjusted_interval - float(current_interval))
			continue
		if key_str.ends_with("_percent"):
			var stat_name: String = key_str.substr(0, key_str.length() - 8)
			var current: Variant = configured_data.get(stat_name)
			if current == null:
				continue
			var adjusted: float = float(current) * (1.0 + value)
			_apply_permanent_stat_bonus(configured_data, stat_name, adjusted - float(current))
		elif key_str.ends_with("_flat"):
			var stat_name: String = key_str.substr(0, key_str.length() - 5)
			_apply_permanent_stat_bonus(configured_data, stat_name, value)


func _apply_permanent_stat_bonus(configured_data: Resource, stat_name: String, amount: float) -> void:
	if is_zero_approx(amount):
		return

	var current_value: Variant = configured_data.get(stat_name)
	if current_value == null:
		return

	match stat_name:
		"max_hp", "attack_damage":
			configured_data.set(stat_name, maxi(1, int(round(float(current_value) + amount))))
		"defense", "defense_penetration":
			configured_data.set(stat_name, maxi(0, int(round(float(current_value) + amount))))
		"crit_chance", "life_steal", "damage_reduction", "status_resistance", "dodge_chance":
			configured_data.set(stat_name, clampf(float(current_value) + amount, 0.0, 1.0))
		"crit_damage_multiplier":
			configured_data.set(stat_name, maxf(1.0, float(current_value) + amount))
		"attack_interval", "damage_taken_multiplier":
			configured_data.set(stat_name, maxf(0.05, float(current_value) + amount))
		"move_speed":
			configured_data.set(stat_name, maxf(1.0, float(current_value) + amount))
		_:
			configured_data.set(stat_name, float(current_value) + amount)


func _get_star_text(star: int) -> String:
	var star_text: String = ""
	var safe_star: int = clampi(star, 1, MAX_STAR)
	for _index: int in range(safe_star):
		star_text += "*"
	return star_text
