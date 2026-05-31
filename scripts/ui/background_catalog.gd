class_name BackgroundCatalog
extends RefCounted


const BACKGROUNDS: Array[Dictionary] = [
	{"name": "草地背景图1", "path": "res://assets/game/ui/backgrounds/grass_background_1.png"},
	{"name": "草地背景图2", "path": "res://assets/game/ui/backgrounds/grass_background_2.png"},
	{"name": "森林背景图1", "path": "res://assets/game/ui/backgrounds/forest_background_1.png"},
	{"name": "森林背景图2", "path": "res://assets/game/ui/backgrounds/forest_background_2.png"},
	{"name": "魔法森林背景图1", "path": "res://assets/game/ui/backgrounds/magic_forest_background_1.png"},
	{"name": "魔法森林背景图2", "path": "res://assets/game/ui/backgrounds/magic_forest_background_2.png"},
	{"name": "魔法森林背景图3", "path": "res://assets/game/ui/backgrounds/magic_forest_background_3.png"},
	{"name": "雪原背景图1", "path": "res://assets/game/ui/backgrounds/snowfield_background_1.png"},
	{"name": "雪原背景图2", "path": "res://assets/game/ui/backgrounds/snowfield_background_2.png"},
	{"name": "沙漠背景图1", "path": "res://assets/game/ui/backgrounds/desert_background_1.png"},
	{"name": "沙漠背景图2", "path": "res://assets/game/ui/backgrounds/desert_background_2.png"},
	{"name": "墓园背景图1", "path": "res://assets/game/ui/backgrounds/graveyard_background_1.png"},
	{"name": "墓园背景图2", "path": "res://assets/game/ui/backgrounds/graveyard_background_2.png"},
	{"name": "火山背景图1", "path": "res://assets/game/ui/backgrounds/volcano_background_1.png"},
	{"name": "火山背景图2", "path": "res://assets/game/ui/backgrounds/volcano_background_2.png"},
	{"name": "沼泽背景图1", "path": "res://assets/game/ui/backgrounds/swamp_background_1.png"},
	{"name": "沼泽背景图2", "path": "res://assets/game/ui/backgrounds/swamp_background_2.png"},
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
