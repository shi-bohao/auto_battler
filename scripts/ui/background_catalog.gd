class_name BackgroundCatalog
extends RefCounted


const BACKGROUNDS: Array[Dictionary] = [
	{"name": "草地背景图1", "path": "res://assets/game/ui/backgrounds/grass_background_1.png", "scene_id": "grass"},
	{"name": "草地背景图2", "path": "res://assets/game/ui/backgrounds/grass_background_2.png", "scene_id": "grass"},
	{"name": "森林背景图1", "path": "res://assets/game/ui/backgrounds/forest_background_1.png", "scene_id": "forest"},
	{"name": "森林背景图2", "path": "res://assets/game/ui/backgrounds/forest_background_2.png", "scene_id": "forest"},
	{"name": "魔法森林背景图1", "path": "res://assets/game/ui/backgrounds/magic_forest_background_1.png", "scene_id": "magic_forest"},
	{"name": "魔法森林背景图2", "path": "res://assets/game/ui/backgrounds/magic_forest_background_2.png", "scene_id": "magic_forest"},
	{"name": "魔法森林背景图3", "path": "res://assets/game/ui/backgrounds/magic_forest_background_3.png", "scene_id": "magic_forest"},
	{"name": "雪原背景图1", "path": "res://assets/game/ui/backgrounds/snowfield_background_1.png", "scene_id": "snowfield"},
	{"name": "雪原背景图2", "path": "res://assets/game/ui/backgrounds/snowfield_background_2.png", "scene_id": "snowfield"},
	{"name": "沙漠背景图1", "path": "res://assets/game/ui/backgrounds/desert_background_1.png", "scene_id": "desert"},
	{"name": "沙漠背景图2", "path": "res://assets/game/ui/backgrounds/desert_background_2.png", "scene_id": "desert"},
	{"name": "墓园背景图1", "path": "res://assets/game/ui/backgrounds/graveyard_background_1.png", "scene_id": "graveyard"},
	{"name": "墓园背景图2", "path": "res://assets/game/ui/backgrounds/graveyard_background_2.png", "scene_id": "graveyard"},
	{"name": "火山背景图1", "path": "res://assets/game/ui/backgrounds/volcano_background_1.png", "scene_id": "volcano"},
	{"name": "火山背景图2", "path": "res://assets/game/ui/backgrounds/volcano_background_2.png", "scene_id": "volcano"},
	{"name": "沼泽背景图1", "path": "res://assets/game/ui/backgrounds/swamp_background_1.png", "scene_id": "swamp"},
	{"name": "沼泽背景图2", "path": "res://assets/game/ui/backgrounds/swamp_background_2.png", "scene_id": "swamp"},
]


static func get_background_names() -> Array[String]:
	var names: Array[String] = []
	for item: Dictionary in BACKGROUNDS:
		names.append(str(item.get("name", "")))
	return names


static func load_background_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for item: Dictionary in BACKGROUNDS:
		var texture: Texture2D = load(str(item.get("path", ""))) as Texture2D
		if texture != null:
			textures.append(texture)
	return textures


static func get_texture_path(index: int) -> String:
	if BACKGROUNDS.is_empty():
		return ""
	var safe_index: int = posmod(index, BACKGROUNDS.size())
	return str(BACKGROUNDS[safe_index].get("path", ""))


static func get_name(index: int) -> String:
	if BACKGROUNDS.is_empty():
		return "默认背景"
	var safe_index: int = posmod(index, BACKGROUNDS.size())
	return str(BACKGROUNDS[safe_index].get("name", "背景 " + str(safe_index + 1)))


static func get_count() -> int:
	return BACKGROUNDS.size()


static func get_background_indices_for_scene(scene_id: String) -> Array[int]:
	var indices: Array[int] = []
	for index: int in range(BACKGROUNDS.size()):
		if str(BACKGROUNDS[index].get("scene_id", "")) == scene_id:
			indices.append(index)
	return indices


static func get_background_names_for_indices(indices: Array[int]) -> Array[String]:
	var names: Array[String] = []
	for index: int in indices:
		if index >= 0 and index < BACKGROUNDS.size():
			names.append(str(BACKGROUNDS[index].get("name", "")))
	return names


static func get_random_background_index_for_scene(scene_id: String) -> int:
	var indices: Array[int] = get_background_indices_for_scene(scene_id)
	if indices.is_empty():
		return randi_range(0, maxi(0, BACKGROUNDS.size() - 1))
	return indices[randi_range(0, indices.size() - 1)]


static func get_scene_id(index: int) -> String:
	if BACKGROUNDS.is_empty():
		return ""
	var safe_index: int = posmod(index, BACKGROUNDS.size())
	return str(BACKGROUNDS[safe_index].get("scene_id", ""))
