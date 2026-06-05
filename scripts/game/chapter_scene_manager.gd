class_name ChapterSceneManager
extends RefCounted


const CHAPTERS: Array[Dictionary] = [
	{
		"chapter": 1,
		"round_start": 1,
		"round_end": 10,
		"scenes": [
			{"scene_id": "grass", "scene_name": "草地", "boss_id": "enemy_boss_goblin_high_priest", "boss_name": "BOSS：哥布林大祭司"},
			{"scene_id": "forest", "scene_name": "森林", "boss_id": "enemy_boss_treant_overlord", "boss_name": "BOSS：树妖领主"},
		],
	},
	{
		"chapter": 2,
		"round_start": 11,
		"round_end": 20,
		"scenes": [
			{"scene_id": "snowfield", "scene_name": "雪原", "boss_id": "enemy_boss_crystal_cannon", "boss_name": "BOSS：冰晶炮台"},
			{"scene_id": "desert", "scene_name": "沙漠", "boss_id": "enemy_boss_earthbreaker_colossus", "boss_name": "BOSS：裂地巨像"},
			{"scene_id": "swamp", "scene_name": "沼泽", "boss_id": "enemy_boss_swamp_devourer", "boss_name": "BOSS：沼泽吞噬者"},
		],
	},
	{
		"chapter": 3,
		"round_start": 21,
		"round_end": 30,
		"scenes": [
			{"scene_id": "volcano", "scene_name": "火山", "boss_id": "enemy_boss_lava_colossus", "boss_name": "BOSS：熔岩巨人"},
			{"scene_id": "graveyard", "scene_name": "墓园", "boss_id": "enemy_boss_scourge_lord", "boss_name": "BOSS：天灾领主"},
			{"scene_id": "magic_forest", "scene_name": "奇幻森林", "boss_id": "enemy_boss_faelord_of_the_grove", "boss_name": "BOSS：森精灵之王"},
		],
	},
]

var selected_scenes_by_chapter: Dictionary = {}


func reset() -> void:
	selected_scenes_by_chapter.clear()


func get_chapter_for_round(round_number: int) -> int:
	for chapter_data: Dictionary in CHAPTERS:
		if round_number >= int(chapter_data["round_start"]) and round_number <= int(chapter_data["round_end"]):
			return int(chapter_data["chapter"])
	return 0


func is_chapter_start_round(round_number: int) -> bool:
	for chapter_data: Dictionary in CHAPTERS:
		if round_number == int(chapter_data["round_start"]):
			return true
	return false


func ensure_scene_for_round(round_number: int) -> Dictionary:
	var chapter: int = get_chapter_for_round(round_number)
	if chapter <= 0:
		return {}

	if selected_scenes_by_chapter.has(chapter):
		return selected_scenes_by_chapter[chapter] as Dictionary

	var chapter_data: Dictionary = _get_chapter_data(chapter)
	if chapter_data.is_empty():
		return {}

	var scenes: Array = chapter_data["scenes"] as Array
	if scenes.is_empty():
		return {}

	var selected_scene: Dictionary = scenes[randi_range(0, scenes.size() - 1)] as Dictionary
	selected_scenes_by_chapter[chapter] = selected_scene.duplicate()
	return selected_scenes_by_chapter[chapter]


func get_scene_for_round(round_number: int) -> Dictionary:
	var chapter: int = get_chapter_for_round(round_number)
	if chapter <= 0 or not selected_scenes_by_chapter.has(chapter):
		return {}
	return selected_scenes_by_chapter[chapter] as Dictionary


func get_scene_id_for_round(round_number: int) -> String:
	var scene: Dictionary = get_scene_for_round(round_number)
	return str(scene.get("scene_id", ""))


func get_scene_name_for_round(round_number: int) -> String:
	var scene: Dictionary = get_scene_for_round(round_number)
	return str(scene.get("scene_name", ""))


func get_boss_id_for_round(round_number: int) -> String:
	var scene: Dictionary = get_scene_for_round(round_number)
	return str(scene.get("boss_id", ""))


func build_chapter_start_text(round_number: int) -> Dictionary:
	var chapter: int = get_chapter_for_round(round_number)
	var scene: Dictionary = ensure_scene_for_round(round_number)
	if chapter <= 0 or scene.is_empty():
		return {"title": "", "subtitle": ""}

	var chapter_name: String = "第" + _number_to_chinese(chapter) + "章"
	var scene_name: String = str(scene.get("scene_name", ""))
	var boss_name: String = str(scene.get("boss_name", ""))

	return {
		"title": chapter_name + "：" + scene_name,
		"subtitle": "本章 Boss：" + boss_name,
	}


func get_all_scene_configs() -> Array[Dictionary]:
	var all_scenes: Array[Dictionary] = []
	for chapter_data: Dictionary in CHAPTERS:
		var scenes: Array = chapter_data.get("scenes", []) as Array
		for scene: Variant in scenes:
			if scene is Dictionary:
				all_scenes.append(scene as Dictionary)
	return all_scenes


func _get_chapter_data(chapter: int) -> Dictionary:
	for chapter_data: Dictionary in CHAPTERS:
		if int(chapter_data["chapter"]) == chapter:
			return chapter_data
	return {}


func _number_to_chinese(num: int) -> String:
	match num:
		1: return "一"
		2: return "二"
		3: return "三"
		4: return "四"
		5: return "五"
		_: return str(num)
