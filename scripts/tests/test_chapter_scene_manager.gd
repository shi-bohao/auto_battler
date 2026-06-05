extends SceneTree

const CHAPTER_SCENE_MANAGER_SCRIPT: Script = preload("res://scripts/game/chapter_scene_manager.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_chapter_ranges()
	_test_chapter_start_rounds()
	_test_scene_persistence()
	_test_boss_id_queries()
	_test_reset_clears_state()
	_test_chapter_start_text()
	_test_scene_boss_config_fixed()
	_finish()


func _test_chapter_ranges() -> void:
	var manager: Variant = CHAPTER_SCENE_MANAGER_SCRIPT.new()
	_expect_int(manager.get_chapter_for_round(1), 1, "Round 1 should be chapter 1.")
	_expect_int(manager.get_chapter_for_round(5), 1, "Round 5 should be chapter 1.")
	_expect_int(manager.get_chapter_for_round(10), 1, "Round 10 should be chapter 1.")
	_expect_int(manager.get_chapter_for_round(11), 2, "Round 11 should be chapter 2.")
	_expect_int(manager.get_chapter_for_round(15), 2, "Round 15 should be chapter 2.")
	_expect_int(manager.get_chapter_for_round(20), 2, "Round 20 should be chapter 2.")
	_expect_int(manager.get_chapter_for_round(21), 3, "Round 21 should be chapter 3.")
	_expect_int(manager.get_chapter_for_round(25), 3, "Round 25 should be chapter 3.")
	_expect_int(manager.get_chapter_for_round(30), 3, "Round 30 should be chapter 3.")
	_expect_int(manager.get_chapter_for_round(31), 0, "Round 31 should be out of range.")
	_expect_int(manager.get_chapter_for_round(0), 0, "Round 0 should be out of range.")


func _test_chapter_start_rounds() -> void:
	var manager: Variant = CHAPTER_SCENE_MANAGER_SCRIPT.new()
	_expect_bool(manager.is_chapter_start_round(1), true, "Round 1 should be chapter start.")
	_expect_bool(manager.is_chapter_start_round(11), true, "Round 11 should be chapter start.")
	_expect_bool(manager.is_chapter_start_round(21), true, "Round 21 should be chapter start.")
	_expect_bool(manager.is_chapter_start_round(2), false, "Round 2 should not be chapter start.")
	_expect_bool(manager.is_chapter_start_round(10), false, "Round 10 should not be chapter start.")
	_expect_bool(manager.is_chapter_start_round(20), false, "Round 20 should not be chapter start.")
	_expect_bool(manager.is_chapter_start_round(30), false, "Round 30 should not be chapter start.")


func _test_scene_persistence() -> void:
	var manager: Variant = CHAPTER_SCENE_MANAGER_SCRIPT.new()
	var scene_1: Dictionary = manager.ensure_scene_for_round(1)
	_expect_true(not scene_1.is_empty(), "ensure_scene_for_round(1) should return a scene.")
	var scene_id_1: String = str(scene_1.get("scene_id", ""))
	_expect_true(scene_id_1 != "", "Chapter 1 scene_id should not be empty.")

	var scene_1_again: Dictionary = manager.ensure_scene_for_round(5)
	_expect_string(str(scene_1_again.get("scene_id", "")), scene_id_1, "Same chapter should return same scene_id.")

	var scene_1_once_more: Dictionary = manager.get_scene_for_round(10)
	_expect_string(str(scene_1_once_more.get("scene_id", "")), scene_id_1, "get_scene_for_round should return same scene_id.")

	var scene_2: Dictionary = manager.ensure_scene_for_round(11)
	var scene_id_2: String = str(scene_2.get("scene_id", ""))
	_expect_true(scene_id_2 != "", "Chapter 2 scene_id should not be empty.")
	_expect_true(scene_id_2 != scene_id_1, "Chapter 2 scene should differ from chapter 1.")

	var scene_3: Dictionary = manager.ensure_scene_for_round(21)
	var scene_id_3: String = str(scene_3.get("scene_id", ""))
	_expect_true(scene_id_3 != "", "Chapter 3 scene_id should not be empty.")
	_expect_true(scene_id_3 != scene_id_2, "Chapter 3 scene should differ from chapter 2.")


func _test_boss_id_queries() -> void:
	var manager: Variant = CHAPTER_SCENE_MANAGER_SCRIPT.new()
	manager.ensure_scene_for_round(1)
	manager.ensure_scene_for_round(11)
	manager.ensure_scene_for_round(21)

	var boss_1: String = manager.get_boss_id_for_round(10)
	_expect_true(boss_1.begins_with("enemy_boss_"), "Chapter 1 boss should be a valid boss id.")

	var boss_2: String = manager.get_boss_id_for_round(20)
	_expect_true(boss_2.begins_with("enemy_boss_"), "Chapter 2 boss should be a valid boss id.")

	var boss_3: String = manager.get_boss_id_for_round(30)
	_expect_true(boss_3.begins_with("enemy_boss_"), "Chapter 3 boss should be a valid boss id.")

	_expect_bool(boss_1 != boss_2 or boss_2 != boss_3, true, "Boss ids should differ across chapters.")


func _test_reset_clears_state() -> void:
	var manager: Variant = CHAPTER_SCENE_MANAGER_SCRIPT.new()
	manager.ensure_scene_for_round(1)
	manager.ensure_scene_for_round(11)
	_expect_true(not manager.get_scene_for_round(1).is_empty(), "Before reset, chapter 1 should have a scene.")

	manager.reset()
	_expect_true(manager.get_scene_for_round(1).is_empty(), "After reset, chapter 1 should be empty.")
	_expect_true(manager.get_scene_for_round(11).is_empty(), "After reset, chapter 2 should be empty.")
	_expect_true(manager.get_boss_id_for_round(10) == "", "After reset, boss id should be empty.")


func _test_chapter_start_text() -> void:
	var manager: Variant = CHAPTER_SCENE_MANAGER_SCRIPT.new()
	var text: Dictionary = manager.build_chapter_start_text(1)
	_expect_true(text.has("title"), "build_chapter_start_text should have title.")
	_expect_true(text.has("subtitle"), "build_chapter_start_text should have subtitle.")
	var title: String = str(text.get("title", ""))
	_expect_true(title.find("章") >= 0, "Title should contain chapter marker.")
	_expect_true(title.find("：") >= 0, "Title should contain scene separator.")

	var subtitle: String = str(text.get("subtitle", ""))
	_expect_true(subtitle.find("本章 Boss：") >= 0, "Subtitle should contain Boss prefix.")
	_expect_true(subtitle.find("BOSS：") >= 0, "Subtitle should contain formatted boss name.")

	var empty_text: Dictionary = manager.build_chapter_start_text(0)
	_expect_true(empty_text.is_empty() or str(empty_text.get("title", "")) == "", "Invalid round should return empty text.")


func _test_scene_boss_config_fixed() -> void:
	var manager: Variant = CHAPTER_SCENE_MANAGER_SCRIPT.new()
	var expected: Dictionary = {
		"grass": {"boss_id": "enemy_boss_goblin_high_priest", "boss_name": "BOSS：哥布林大祭司"},
		"forest": {"boss_id": "enemy_boss_treant_overlord", "boss_name": "BOSS：树妖领主"},
		"snowfield": {"boss_id": "enemy_boss_crystal_cannon", "boss_name": "BOSS：冰晶炮台"},
		"desert": {"boss_id": "enemy_boss_earthbreaker_colossus", "boss_name": "BOSS：裂地巨像"},
		"swamp": {"boss_id": "enemy_boss_swamp_devourer", "boss_name": "BOSS：沼泽吞噬者"},
		"volcano": {"boss_id": "enemy_boss_lava_colossus", "boss_name": "BOSS：熔岩巨人"},
		"graveyard": {"boss_id": "enemy_boss_scourge_lord", "boss_name": "BOSS：天灾领主"},
		"magic_forest": {"boss_id": "enemy_boss_faelord_of_the_grove", "boss_name": "BOSS：森精灵之王"},
	}
	var all_scenes: Array[Dictionary] = manager.get_all_scene_configs()
	_expect_int(all_scenes.size(), 8, "Should have exactly 8 scene configs.")
	for scene: Dictionary in all_scenes:
		var scene_id: String = str(scene.get("scene_id", ""))
		_expect_true(expected.has(scene_id), scene_id + " should be in expected map.")
		if not expected.has(scene_id):
			continue
		var exp: Dictionary = expected[scene_id]
		_expect_string(str(scene.get("boss_id", "")), exp["boss_id"], scene_id + " boss_id should match.")
		_expect_string(str(scene.get("boss_name", "")), exp["boss_name"], scene_id + " boss_name should match.")


func _finish() -> void:
	if failures.is_empty():
		print("Chapter scene manager tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_bool(actual: bool, expected: bool, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _expect_string(actual: String, expected: String, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected '" + expected + "', got '" + actual + "'.")


func _expect_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
