extends SceneTree

const HERO_MANAGER_SCRIPT: Script = preload("res://scripts/hero_manager.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_hero_selection_and_reset()
	_test_hero_spawn_config()
	_test_hero_level_up_options()

	if failures.is_empty():
		print("Hero manager tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_hero_selection_and_reset() -> void:
	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	_expect_int(hero_manager.get_available_heroes().size(), 4, "HeroManager should expose four heroes.")
	_expect_bool(hero_manager.has_selected_hero(), false, "HeroManager should start without a selected hero.")
	_expect_bool(hero_manager.select_hero("iron_oath_commander"), true, "Hero selection should accept a known hero.")
	_expect_string(hero_manager.get_selected_hero_id(), "iron_oath_commander", "Selected hero id should be saved.")
	_expect_int(hero_manager.hero_level, 1, "Selected hero should start at level 1.")
	_expect_int(hero_manager.hero_experience, 0, "Selected hero should start with no experience.")
	hero_manager.reset_hero()
	_expect_bool(hero_manager.has_selected_hero(), false, "Reset should clear selected hero.")
	_expect_int(hero_manager.hero_level, 0, "Reset should clear hero level.")
	_expect_int(hero_manager.hero_experience, 0, "Reset should clear hero experience.")


func _test_hero_spawn_config() -> void:
	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	hero_manager.select_hero("arcane_mentor")
	var player_units: Array[Unit] = []
	var config: Dictionary = hero_manager.get_hero_battle_unit_config(null, player_units)
	_expect_bool(not config.is_empty(), true, "HeroManager should create a hero spawn config.")
	_expect_bool(bool(config.get("is_hero", false)), true, "Hero spawn config should be marked as hero.")
	_expect_string(str(config.get("roster_area", "")), "hero", "Hero roster area should be hero.")
	_expect_int(int(config.get("roster_id", 0)), -1, "Hero should not have a normal roster id.")
	var unit_data: Resource = config.get("unit_data", null) as Resource
	_expect_bool(unit_data != null, true, "Hero spawn config should include runtime UnitData.")
	if unit_data != null:
		_expect_string(str(unit_data.get("unit_type")), "hero_arcane_mentor", "Hero runtime UnitData should preserve hero unit type.")


func _test_hero_level_up_options() -> void:
	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	hero_manager.select_hero("bloodshadow_hunter")
	_expect_bool(hero_manager.process_victory_encounter(1, "NORMAL"), false, "Normal victory should grant experience without leveling yet.")
	_expect_int(hero_manager.hero_experience, 10, "Normal victory should grant 10 hero experience.")
	_expect_bool(hero_manager.process_victory_encounter(5, "ELITE"), false, "Elite victory should grant experience without leveling at 30 total.")
	_expect_int(hero_manager.hero_experience, 30, "Elite victory should grant 20 hero experience.")
	_expect_bool(hero_manager.process_victory_encounter(10, "BOSS"), true, "Boss victory should grant enough experience to level.")
	_expect_int(hero_manager.hero_level, 2, "50 experience should raise hero to level 2.")
	_expect_int(hero_manager.hero_experience, 10, "Experience should carry over after leveling.")
	var options: Array[Dictionary] = hero_manager.get_pending_upgrade_options()
	_expect_int(options.size(), 3, "Hero level up should roll three upgrade options.")
	if not options.is_empty():
		_expect_bool(hero_manager.apply_hero_upgrade(options[0]), true, "Selected hero upgrade should apply.")
		_expect_int(hero_manager.get_selected_upgrade_ids().size(), 1, "Applied hero upgrade should be saved for this run.")
		_expect_bool(hero_manager.apply_hero_upgrade(options[0]), false, "The same hero upgrade should not apply twice.")

	_expect_bool(hero_manager.process_victory_encounter(10, "BOSS"), false, "The same round should not grant hero experience twice.")
	_expect_int(hero_manager.hero_experience, 10, "Duplicate round processing should not add experience.")

	hero_manager.hero_level = 12
	var selected_count_before: int = hero_manager.get_selected_upgrade_ids().size()
	var selected_hero: Resource = hero_manager.selected_hero as Resource
	var upgrade_pool: Array = selected_hero.get("upgrade_pool") as Array
	for upgrade_value: Variant in upgrade_pool:
		var upgrade_data: Resource = upgrade_value as Resource
		if upgrade_data != null and upgrade_data.has_method("to_reward_option"):
			hero_manager.apply_hero_upgrade(upgrade_data.to_reward_option())
	_expect_bool(hero_manager.get_selected_upgrade_ids().size() >= selected_count_before, true, "Hero-specific upgrades should be selectable by id.")
	var fallback_options: Array[Dictionary] = hero_manager.generate_hero_upgrade_options(3)
	_expect_int(fallback_options.size(), 3, "Base stat options should fill choices after all hero upgrades are selected.")
	if not fallback_options.is_empty():
		_expect_string(str(fallback_options[0].get("effect_type", "")), "BASE_STAT", "Fallback hero upgrade should be a base stat upgrade.")
		_expect_bool(hero_manager.apply_hero_upgrade(fallback_options[0]), true, "Repeatable base stat upgrade should apply.")

	var partial_manager: Variant = HERO_MANAGER_SCRIPT.new()
	partial_manager.select_hero("arcane_mentor")
	partial_manager.hero_level = 4
	var partial_hero: Resource = partial_manager.selected_hero as Resource
	var partial_pool: Array = partial_hero.get("upgrade_pool") as Array
	for index: int in range(maxi(0, partial_pool.size() - 1)):
		var partial_upgrade: Resource = partial_pool[index] as Resource
		if partial_upgrade != null and partial_upgrade.has_method("to_reward_option"):
			partial_manager.apply_hero_upgrade(partial_upgrade.to_reward_option())
	var partial_options: Array[Dictionary] = partial_manager.generate_hero_upgrade_options(3)
	_expect_int(partial_options.size(), 3, "Base stat options should fill when fewer than three hero-specific upgrades remain.")

	var level_1_manager: Variant = HERO_MANAGER_SCRIPT.new()
	level_1_manager.select_hero("iron_oath_commander")
	var level_1_data: Resource = level_1_manager.create_hero_battle_unit_data()
	var level_5_manager: Variant = HERO_MANAGER_SCRIPT.new()
	level_5_manager.select_hero("iron_oath_commander")
	level_5_manager.hero_level = 5
	var level_5_data: Resource = level_5_manager.create_hero_battle_unit_data()
	_expect_bool(int(level_5_data.get("max_hp")) > int(level_1_data.get("max_hp")), true, "Hero max hp should grow with level.")
	_expect_bool(int(level_5_data.get("attack_damage")) > int(level_1_data.get("attack_damage")), true, "Hero attack should grow with level.")
	_expect_bool(int(level_5_data.get("defense")) > int(level_1_data.get("defense")), true, "Hero defense should grow with level.")


func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + expected + ", got " + actual + ".")
