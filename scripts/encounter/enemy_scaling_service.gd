class_name EnemyScalingService
extends RefCounted


func create_scaled_unit_data(
	base_data: Resource,
	unit_id: String,
	star: int,
	hp_multiplier: float,
	attack_multiplier: float,
	defense_bonus: int,
	mana_regen_multiplier: float,
	get_unit_type_display_name_func: Callable,
	get_star_text_func: Callable
) -> Resource:
	var configured_data: Resource = base_data.duplicate(true) as Resource
	var safe_star: int = clampi(star, 1, 3)
	var star_growth: Dictionary = get_star_growth(unit_id, safe_star)
	var base_max_hp: int = int(base_data.get("max_hp"))
	var base_attack_damage: int = int(base_data.get("attack_damage"))
	var base_defense: int = _get_int_property(base_data, "defense", 0)
	var base_attack_interval: float = _get_float_property(base_data, "attack_interval", 1.0)
	var base_move_speed: float = _get_float_property(base_data, "move_speed", 120.0)
	var base_crit_chance: float = _get_float_property(base_data, "crit_chance", 0.0)
	var base_crit_damage_multiplier: float = _get_float_property(base_data, "crit_damage_multiplier", 1.5)
	var base_mana_regen: float = _get_float_property(base_data, "mana_regen_per_second", 0.0)
	var unit_display_name: String = _get_unit_type_display_name(unit_id, get_unit_type_display_name_func)
	var star_text: String = _get_star_text(safe_star, get_star_text_func)

	configured_data.set("max_hp", maxi(1, int(round(float(base_max_hp) * hp_multiplier * float(star_growth["max_hp_multiplier"])))))
	configured_data.set("attack_damage", maxi(1, int(round(float(base_attack_damage) * attack_multiplier * float(star_growth["attack_damage_multiplier"])))))
	configured_data.set("defense", maxi(0, base_defense + int(star_growth["defense_bonus"]) + defense_bonus))
	configured_data.set("attack_interval", maxf(0.1, base_attack_interval * float(star_growth["attack_interval_multiplier"])))
	configured_data.set("move_speed", maxf(1.0, base_move_speed * float(star_growth["move_speed_multiplier"])))
	configured_data.set("crit_chance", clampf(base_crit_chance + float(star_growth["crit_chance_bonus"]), 0.0, 1.0))
	configured_data.set("crit_damage_multiplier", maxf(1.0, base_crit_damage_multiplier + float(star_growth["crit_damage_multiplier_bonus"])))
	configured_data.set("mana_regen_per_second", base_mana_regen * mana_regen_multiplier)
	configured_data.set("star", safe_star)
	configured_data.set("unit_name", unit_display_name + " " + star_text)
	configured_data.set("unit_name_cn", unit_display_name + " " + star_text)
	return configured_data


func get_star_growth(unit_type: String, star: int) -> Dictionary:
	var safe_star: int = clampi(star, 1, 3)

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


func _get_unit_type_display_name(unit_id: String, get_unit_type_display_name_func: Callable) -> String:
	if get_unit_type_display_name_func.is_valid():
		return str(get_unit_type_display_name_func.call(unit_id))

	return unit_id.capitalize()


func _get_star_text(star: int, get_star_text_func: Callable) -> String:
	if get_star_text_func.is_valid():
		return str(get_star_text_func.call(star))

	var star_text: String = ""
	for _index: int in range(clampi(star, 1, 3)):
		star_text += "*"
	return star_text


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
