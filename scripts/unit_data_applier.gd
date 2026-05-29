class_name UnitDataApplier
extends RefCounted


func apply_unit_data(unit: Variant, unit_data: Resource) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	if unit_data == null:
		return

	unit.board_sprite = null
	unit.portrait_texture = null
	unit.icon_texture = null
	unit.art_scale = 1.0
	unit.art_offset = Vector2.ZERO
	unit.basic_attack_type = "melee"
	unit.projectile_speed = 500.0
	unit.projectile_visual_type = "arrow"

	unit.max_hp = int(unit_data.get("max_hp"))
	unit.attack_damage = int(unit_data.get("attack_damage"))

	var configured_crit_chance: Variant = unit_data.get("crit_chance")
	if configured_crit_chance != null:
		unit.crit_chance = float(configured_crit_chance)

	var configured_crit_damage_multiplier: Variant = unit_data.get("crit_damage_multiplier")
	if configured_crit_damage_multiplier != null:
		unit.crit_damage_multiplier = float(configured_crit_damage_multiplier)

	var configured_defense: Variant = unit_data.get("defense")
	if configured_defense != null:
		unit.defense = int(configured_defense)

	var configured_skill_power: Variant = unit_data.get("skill_power")
	if configured_skill_power != null:
		unit.skill_power = maxf(0.0, float(configured_skill_power))

	var configured_healing_power: Variant = unit_data.get("healing_power")
	if configured_healing_power != null:
		unit.healing_power = maxf(0.0, float(configured_healing_power))

	var configured_shield_power: Variant = unit_data.get("shield_power")
	if configured_shield_power != null:
		unit.shield_power = maxf(0.0, float(configured_shield_power))

	var configured_defense_penetration: Variant = unit_data.get("defense_penetration")
	if configured_defense_penetration != null:
		unit.defense_penetration = maxi(0, int(configured_defense_penetration))

	var configured_life_steal: Variant = unit_data.get("life_steal")
	if configured_life_steal != null:
		unit.life_steal = clampf(float(configured_life_steal), 0.0, 1.0)

	var configured_damage_reduction: Variant = unit_data.get("damage_reduction")
	if configured_damage_reduction != null:
		unit.damage_reduction = clampf(float(configured_damage_reduction), 0.0, 0.95)

	var configured_damage_taken_multiplier: Variant = unit_data.get("damage_taken_multiplier")
	if configured_damage_taken_multiplier != null:
		unit.damage_taken_multiplier = maxf(0.0, float(configured_damage_taken_multiplier))

	var configured_initial_mana: Variant = unit_data.get("initial_mana")
	if configured_initial_mana != null:
		unit.initial_mana = maxf(0.0, float(configured_initial_mana))

	var configured_mana_on_attack: Variant = unit_data.get("mana_on_attack")
	if configured_mana_on_attack != null:
		unit.mana_on_attack = maxf(0.0, float(configured_mana_on_attack))

	var configured_mana_on_hit_taken: Variant = unit_data.get("mana_on_hit_taken")
	if configured_mana_on_hit_taken != null:
		unit.mana_on_hit_taken = maxf(0.0, float(configured_mana_on_hit_taken))

	var configured_status_resistance: Variant = unit_data.get("status_resistance")
	if configured_status_resistance != null:
		unit.status_resistance = clampf(float(configured_status_resistance), 0.0, 0.95)

	var configured_ctrl_dur: Variant = unit_data.get("control_duration_multiplier")
	if configured_ctrl_dur != null:
		unit.control_duration_multiplier = maxf(0.0, float(configured_ctrl_dur))
	var configured_hard_ctrl_dur: Variant = unit_data.get("hard_control_duration_multiplier")
	if configured_hard_ctrl_dur != null:
		unit.hard_control_duration_multiplier = maxf(0.0, float(configured_hard_ctrl_dur))
	var configured_ctrl_immunity: Variant = unit_data.get("control_immunity_tags")
	if configured_ctrl_immunity is Array:
		unit.control_immunity_tags.clear()
		for tag: String in configured_ctrl_immunity:
			if str(tag).strip_edges() != "":
				unit.control_immunity_tags.append(str(tag).strip_edges())

	var configured_dodge_chance: Variant = unit_data.get("dodge_chance")
	if configured_dodge_chance != null:
		unit.dodge_chance = clampf(float(configured_dodge_chance), 0.0, 0.95)

	var configured_unit_type: Variant = unit_data.get("unit_type")
	if configured_unit_type != null:
		unit.unit_type = str(configured_unit_type)
	else:
		var configured_unit_name: Variant = unit_data.get("unit_name")
		if configured_unit_name != null:
			unit.unit_type = str(configured_unit_name).to_lower()

	var configured_role: Variant = unit_data.get("role")
	if configured_role != null and str(configured_role).strip_edges() != "":
		unit.role = str(configured_role)

	unit.bond_tags.clear()
	var configured_bond_tags: Variant = unit_data.get("bond_tags")
	if configured_bond_tags is Array:
		for tag_value: Variant in configured_bond_tags:
			var tag: String = str(tag_value).strip_edges()
			if tag != "" and not unit.bond_tags.has(tag):
				unit.bond_tags.append(tag)

	var configured_star: Variant = unit_data.get("star")
	if configured_star != null:
		unit.star = int(configured_star)

	var configured_rarity: Variant = unit_data.get("rarity")
	if configured_rarity != null and str(configured_rarity).strip_edges() != "":
		unit.rarity = str(configured_rarity)

	var configured_passive_id: Variant = unit_data.get("passive_id")
	if configured_passive_id != null:
		unit.passive_id = str(configured_passive_id)

	var configured_active_skill_id: Variant = unit_data.get("active_skill_id")
	if configured_active_skill_id != null:
		unit.active_skill_id = str(configured_active_skill_id)

	var configured_max_mana: Variant = unit_data.get("max_mana")
	if configured_max_mana != null:
		unit.max_mana = int(configured_max_mana)

	var configured_mana_regen: Variant = unit_data.get("mana_regen_per_second")
	if configured_mana_regen != null:
		unit.mana_regen_per_second = float(configured_mana_regen)

	unit.attack_interval = float(unit_data.get("attack_interval"))
	unit.attack_range = float(unit_data.get("attack_range"))

	var configured_search_range: Variant = unit_data.get("search_range")
	if configured_search_range != null:
		unit.search_range = float(configured_search_range)

	unit.move_speed = float(unit_data.get("move_speed"))

	var configured_target_mode: Variant = unit_data.get("target_mode")
	if configured_target_mode != null:
		unit.target_mode = str(configured_target_mode)
	else:
		var legacy_strategy: Variant = unit_data.get("target_strategy")
		if legacy_strategy != null:
			unit.target_mode = _convert_legacy_target_strategy(str(legacy_strategy))

	var configured_retarget_interval: Variant = unit_data.get("retarget_interval")
	if configured_retarget_interval != null:
		unit.retarget_interval = float(configured_retarget_interval)

	var configured_switch_threshold: Variant = unit_data.get("lowest_hp_switch_threshold")
	if configured_switch_threshold != null:
		unit.lowest_hp_switch_threshold = float(configured_switch_threshold)

	var configured_basic_attack_type: Variant = unit_data.get("basic_attack_type")
	if configured_basic_attack_type != null and str(configured_basic_attack_type).strip_edges() != "":
		unit.basic_attack_type = str(configured_basic_attack_type)

	var configured_projectile_speed: Variant = unit_data.get("projectile_speed")
	if configured_projectile_speed != null:
		unit.projectile_speed = maxf(1.0, float(configured_projectile_speed))

	var configured_projectile_visual_type: Variant = unit_data.get("projectile_visual_type")
	if configured_projectile_visual_type != null and str(configured_projectile_visual_type).strip_edges() != "":
		unit.projectile_visual_type = str(configured_projectile_visual_type)

	var configured_board_sprite: Variant = unit_data.get("board_sprite")
	if configured_board_sprite is Texture2D:
		unit.board_sprite = configured_board_sprite

	var configured_portrait_texture: Variant = unit_data.get("portrait_texture")
	if configured_portrait_texture is Texture2D:
		unit.portrait_texture = configured_portrait_texture

	var configured_icon_texture: Variant = unit_data.get("icon_texture")
	if configured_icon_texture is Texture2D:
		unit.icon_texture = configured_icon_texture

	var configured_art_scale: Variant = unit_data.get("art_scale")
	if configured_art_scale != null:
		unit.art_scale = maxf(0.05, float(configured_art_scale))

	var configured_art_offset: Variant = unit_data.get("art_offset")
	if configured_art_offset is Vector2:
		unit.art_offset = configured_art_offset

	if unit.has_method("refresh_unit_art"):
		unit.refresh_unit_art()


func _convert_legacy_target_strategy(strategy: String) -> String:
	if strategy.to_lower() == "lowest_hp":
		return "LOWEST_HP"

	return "NEAREST"
