class_name EncounterManager
extends RefCounted

const ENEMY_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/enemy_catalog.gd")
const DEFAULT_ENCOUNTER_BUILDER_SCRIPT: Script = preload("res://scripts/encounter/default_encounter_builder.gd")
const ENCOUNTER_GENERATOR_SCRIPT: Script = preload("res://scripts/encounter/encounter_generator.gd")
const ENEMY_SCALING_SERVICE_SCRIPT: Script = preload("res://scripts/encounter/enemy_scaling_service.gd")
const UNIT_SCALING_SERVICE_SCRIPT: Script = preload("res://scripts/roster/unit_scaling_service.gd")

const ENCOUNTER_TYPE_NORMAL: String = "NORMAL"
const ENCOUNTER_TYPE_ELITE: String = "ELITE"
const ENCOUNTER_TYPE_BOSS: String = "BOSS"

var use_random_encounters: bool = true

var encounters: Array[Dictionary] = []
var random_encounter_cache: Dictionary = {}
var mirror_boss_encounters_by_round: Dictionary = {}
var enemy_catalog: Variant = ENEMY_CATALOG_SCRIPT.new()
var default_encounter_builder: Variant = DEFAULT_ENCOUNTER_BUILDER_SCRIPT.new()
var encounter_generator: Variant = ENCOUNTER_GENERATOR_SCRIPT.new()
var enemy_scaling_service: Variant = ENEMY_SCALING_SERVICE_SCRIPT.new()
var mirror_unit_scaling_service: Variant = UNIT_SCALING_SERVICE_SCRIPT.new()


func setup(
	configured_warrior_data: Resource,
	configured_archer_data: Resource,
	configured_assassin_data: Resource,
	configured_tank_data: Resource = null,
	configured_mage_data: Resource = null,
	configured_priest_data: Resource = null,
	configured_bard_data: Resource = null
) -> void:
	random_encounter_cache.clear()
	mirror_boss_encounters_by_round.clear()
	_build_default_encounters()


func set_mirror_boss_encounters(encounters_by_round: Dictionary) -> void:
	mirror_boss_encounters_by_round.clear()
	for round_value: Variant in encounters_by_round.keys():
		var round_number: int = int(round_value)
		var encounter_value: Variant = encounters_by_round[round_value]
		if encounter_value is Dictionary:
			mirror_boss_encounters_by_round[round_number] = (encounter_value as Dictionary).duplicate(true)
			random_encounter_cache.erase(round_number)


func clear_mirror_boss_encounters() -> void:
	mirror_boss_encounters_by_round.clear()
	random_encounter_cache.clear()


func get_encounter(current_round: int) -> Dictionary:
	if mirror_boss_encounters_by_round.has(current_round):
		return (mirror_boss_encounters_by_round[current_round] as Dictionary).duplicate(true)

	if use_random_encounters:
		return _get_or_create_random_encounter(current_round)

	if encounters.is_empty():
		_build_default_encounters()

	if encounters.is_empty():
		return {}

	var encounter_index: int = clampi(current_round - 1, 0, encounters.size() - 1)
	return encounters[encounter_index] as Dictionary


func get_enemy_unit_configs(current_round: int) -> Array[Dictionary]:
	var encounter: Dictionary = get_encounter(current_round)
	var unit_configs: Array[Dictionary] = []
	if encounter.is_empty():
		return unit_configs

	var enemy_units: Array = encounter["enemy_units"] as Array
	var hp_multiplier: float = float(encounter.get("enemy_hp_multiplier", 1.0))
	var attack_multiplier: float = float(encounter.get("enemy_attack_multiplier", 1.0))
	var defense_bonus: int = int(encounter.get("enemy_defense_bonus", 0))
	var mana_regen_multiplier: float = float(encounter.get("enemy_mana_regen_multiplier", 1.0))

	for enemy_unit_value: Variant in enemy_units:
		var enemy_unit: Dictionary = enemy_unit_value as Dictionary
		var unit_id: String = str(enemy_unit["unit_id"])
		var base_data: Resource = _get_unit_data_for_entry(enemy_unit)
		if base_data == null:
			continue

		var star: int = int(enemy_unit.get("star", 1))
		var unit_hp_multiplier: float = hp_multiplier * float(enemy_unit.get("hp_multiplier", 1.0))
		var unit_attack_multiplier: float = attack_multiplier * float(enemy_unit.get("attack_multiplier", 1.0))
		var unit_defense_bonus: int = defense_bonus + int(enemy_unit.get("defense_bonus", 0))
		var unit_mana_regen_multiplier: float = mana_regen_multiplier * float(enemy_unit.get("mana_regen_multiplier", 1.0))
		var is_boss: bool = bool(enemy_unit.get("is_boss", false))
		var display_name: String = str(enemy_unit.get("display_name", ""))
		if display_name == "":
			display_name = _create_enemy_display_name(unit_id, star, is_boss)
		var configured_unit_data: Resource = _create_scaled_unit_data_for_entry(
			enemy_unit,
			base_data,
			unit_id,
			star,
			unit_hp_multiplier,
			unit_attack_multiplier,
			unit_defense_bonus,
			unit_mana_regen_multiplier
		)
		var unit_config: Dictionary = {
			"unit_data": configured_unit_data,
			"unit_id": unit_id,
			"position": enemy_unit["position"],
			"display_name": display_name,
			"star": star,
			"is_boss": is_boss,
		}
		if enemy_unit.has("cell"):
			unit_config["cell"] = enemy_unit.get("cell", Vector2i(-1, -1))
		unit_configs.append(unit_config)

	return unit_configs


func get_enemy_unit_data_list(current_round: int) -> Array[Resource]:
	var unit_data_list: Array[Resource] = []
	var unit_configs: Array[Dictionary] = get_enemy_unit_configs(current_round)

	for unit_config: Dictionary in unit_configs:
		unit_data_list.append(unit_config["unit_data"] as Resource)

	return unit_data_list


func get_encounter_debug_text(current_round: int) -> String:
	var encounter: Dictionary = get_encounter(current_round)
	if encounter.is_empty():
		return "遭遇数据缺失"

	var unit_names: Array[String] = []
	var enemy_units: Array = encounter["enemy_units"] as Array
	for enemy_unit_value: Variant in enemy_units:
		var enemy_unit: Dictionary = enemy_unit_value as Dictionary
		unit_names.append(str(enemy_unit["display_name"]) + "@" + str(enemy_unit["position"]))
	var unit_text: String = ""
	for index: int in range(unit_names.size()):
		if index > 0:
			unit_text += ", "
		unit_text += unit_names[index]

	return "遭遇：" + str(encounter["encounter_name"]) \
		+ " [" + str(encounter["encounter_type"]) + "]" \
		+ " 生命 x" + _format_multiplier(float(encounter.get("enemy_hp_multiplier", 1.0))) \
		+ " 攻击 x" + _format_multiplier(float(encounter.get("enemy_attack_multiplier", 1.0))) \
		+ " 单位 " + unit_text


func _get_or_create_random_encounter(current_round: int) -> Dictionary:
	if random_encounter_cache.has(current_round):
		return random_encounter_cache[current_round] as Dictionary

	var encounter: Dictionary = _create_random_encounter(current_round)
	random_encounter_cache[current_round] = encounter
	return encounter


func _create_random_encounter(current_round: int) -> Dictionary:
	return encounter_generator.create_random_encounter(current_round)


func _build_default_encounters() -> void:
	encounters = default_encounter_builder.build_default_encounters()


func _get_unit_data_by_id(unit_id: String) -> Resource:
	return enemy_catalog.get_unit_data_by_id(unit_id)


func _get_unit_data_for_entry(enemy_unit: Dictionary) -> Resource:
	var resource_path: String = str(enemy_unit.get("resource_path", ""))
	if resource_path != "" and ResourceLoader.exists(resource_path):
		var resource_data: Resource = ResourceLoader.load(resource_path) as Resource
		if resource_data != null:
			return resource_data

	return _get_unit_data_by_id(str(enemy_unit.get("unit_id", "")))


func _create_enemy_display_name(unit_id: String, star: int, is_boss: bool) -> String:
	return enemy_catalog.create_enemy_display_name(unit_id, star, is_boss)


func _get_unit_type_display_name(unit_id: String) -> String:
	return enemy_catalog.get_unit_type_display_name(unit_id)


func _get_star_text(star: int) -> String:
	return enemy_catalog.get_star_text(star)


func _create_scaled_unit_data(
	base_data: Resource,
	unit_id: String,
	star: int,
	hp_multiplier: float,
	attack_multiplier: float,
	defense_bonus: int,
	mana_regen_multiplier: float
) -> Resource:
	return enemy_scaling_service.create_scaled_unit_data(
		base_data,
		unit_id,
		star,
		hp_multiplier,
		attack_multiplier,
		defense_bonus,
		mana_regen_multiplier,
		Callable(self, "_get_unit_type_display_name"),
		Callable(self, "_get_star_text")
	)


func _create_scaled_unit_data_for_entry(
	enemy_unit: Dictionary,
	base_data: Resource,
	unit_id: String,
	star: int,
	hp_multiplier: float,
	attack_multiplier: float,
	defense_bonus: int,
	mana_regen_multiplier: float
) -> Resource:
	if bool(enemy_unit.get("is_mirror_unit", false)):
		var roster_item: Dictionary = {
			"unit_data": base_data,
			"unit_id": unit_id,
			"display_name": str(enemy_unit.get("base_display_name", enemy_unit.get("display_name", unit_id))),
			"star": star,
		}
		var configured_data: Resource = mirror_unit_scaling_service.create_scaled_unit_data(
			roster_item,
			hp_multiplier,
			attack_multiplier
		)
		var base_defense: int = int(configured_data.get("defense"))
		var base_mana_regen: float = float(configured_data.get("mana_regen_per_second"))
		configured_data.set("defense", maxi(0, base_defense + defense_bonus))
		configured_data.set("mana_regen_per_second", base_mana_regen * mana_regen_multiplier)
		configured_data.set("unit_name", str(enemy_unit.get("display_name", configured_data.get("unit_name"))))
		configured_data.set("unit_name_cn", str(enemy_unit.get("display_name", configured_data.get("unit_name_cn"))))
		return configured_data

	return _create_scaled_unit_data(
		base_data,
		unit_id,
		star,
		hp_multiplier,
		attack_multiplier,
		defense_bonus,
		mana_regen_multiplier
	)


func _format_multiplier(multiplier: float) -> String:
	return "%0.2f" % multiplier
