class_name EncyclopediaCatalog
extends RefCounted


const CATEGORY_PLAYER_UNITS: String = "player_units"
const CATEGORY_ENEMY_UNITS: String = "enemy_units"
const CATEGORY_SUMMONS: String = "summons"
const CATEGORY_RELICS: String = "relics"
const CATEGORY_HEROES: String = "heroes"
const CATEGORY_BONDS: String = "bonds"

const FILTER_ALL: String = "全部"
const ENEMY_TYPE_NORMAL: String = "普通敌人"
const ENEMY_TYPE_ELITE: String = "精英"
const ENEMY_TYPE_BOSS: String = "BOSS"

const RARITY_ORDER: Array[String] = ["COMMON", "FINE", "RARE", "EPIC", "LEGENDARY", "MYTHIC"]

const HERO_MANAGER_SCRIPT: Script = preload("res://scripts/hero_manager.gd")

const UNIT_DATA_DIR: String = "res://data/units"
const RELIC_DATA_DIR: String = "res://data/relics"
const ENEMY_DATA_DIR: String = "res://data/enemies"
const SUMMON_DATA_DIR: String = "res://data/summons"

var entries_by_category: Dictionary = {}
var bond_manager: Variant = null


func refresh() -> void:
	entries_by_category.clear()
	for category: String in get_category_order():
		entries_by_category[category] = []

	_collect_unit_dir(CATEGORY_PLAYER_UNITS, UNIT_DATA_DIR)
	_collect_relic_dir(RELIC_DATA_DIR)
	_collect_unit_dir(CATEGORY_ENEMY_UNITS, ENEMY_DATA_DIR)
	_collect_unit_dir(CATEGORY_SUMMONS, SUMMON_DATA_DIR)
	_collect_heroes()
	_collect_bonds()
	_sort_all_categories()


func _collect_bonds() -> void:
	if bond_manager == null or not bond_manager.has_method("get_all_bonds"):
		return
	const DISPLAY_NAMES: Dictionary = {
		"iron_wall": "铁壁", "hunter": "猎手", "arcane": "奥术",
		"divine": "圣疗", "summon": "召唤", "venom": "剧毒",
	}
	for bond_id: String in bond_manager.get_all_bonds():
		entries_by_category[CATEGORY_BONDS].append({
			"id": bond_id,
			"name": DISPLAY_NAMES.get(bond_id, bond_id),
			"sort_name": DISPLAY_NAMES.get(bond_id, bond_id),
			"category": CATEGORY_BONDS,
			"kind": "bond",
			"bond_id": bond_id,
		})


func set_bond_manager(bm: Variant) -> void:
	bond_manager = bm


func get_category_order() -> Array[String]:
	return [
		CATEGORY_PLAYER_UNITS,
		CATEGORY_HEROES,
		CATEGORY_BONDS,
		CATEGORY_ENEMY_UNITS,
		CATEGORY_SUMMONS,
		CATEGORY_RELICS,
	]


func get_category_display_name(category: String) -> String:
	match category:
		CATEGORY_PLAYER_UNITS:
			return "友方单位"
		CATEGORY_ENEMY_UNITS:
			return "敌方单位"
		CATEGORY_SUMMONS:
			return "召唤物"
		CATEGORY_RELICS:
			return "遗物"
		CATEGORY_HEROES:
			return "英雄"
		CATEGORY_BONDS:
			return "羁绊"
		_:
			return category


func get_entries(category: String) -> Array[Dictionary]:
	if entries_by_category.is_empty():
		refresh()

	var entries: Array[Dictionary] = []
	var configured_entries: Variant = entries_by_category.get(category, [])
	if configured_entries is Array:
		for entry_value: Variant in configured_entries:
			if entry_value is Dictionary:
				entries.append((entry_value as Dictionary).duplicate())

	return entries


func get_entry_count(category: String) -> int:
	if entries_by_category.is_empty():
		refresh()

	var entries: Variant = entries_by_category.get(category, [])
	if entries is Array:
		return (entries as Array).size()

	return 0


func get_filter_options(category: String) -> Array[Dictionary]:
	if entries_by_category.is_empty():
		refresh()

	var options: Array[Dictionary] = []
	options.append({"key": FILTER_ALL, "label": FILTER_ALL})

	match category:
		CATEGORY_PLAYER_UNITS, CATEGORY_RELICS:
			var seen_rarities: Dictionary = {}
			for entry: Dictionary in get_entries(category):
				var resource: Resource = entry.get("resource", null) as Resource
				if resource == null:
					continue
				var rarity: String = _get_string(resource, "rarity")
				if rarity == "" or seen_rarities.has(rarity):
					continue
				seen_rarities[rarity] = true
			for rarity: String in RARITY_ORDER:
				if seen_rarities.has(rarity):
					options.append({"key": rarity, "label": _get_rarity_display_name(rarity)})

		CATEGORY_ENEMY_UNITS:
			var has_normal: bool = false
			var has_elite: bool = false
			var has_boss: bool = false
			for entry: Dictionary in get_entries(category):
				var resource: Resource = entry.get("resource", null) as Resource
				if resource == null:
					continue
				match _get_enemy_type_key(resource):
					ENEMY_TYPE_BOSS:
						has_boss = true
					ENEMY_TYPE_ELITE:
						has_elite = true
					_:
						has_normal = true
			if has_normal:
				options.append({"key": ENEMY_TYPE_NORMAL, "label": ENEMY_TYPE_NORMAL})
			if has_elite:
				options.append({"key": ENEMY_TYPE_ELITE, "label": ENEMY_TYPE_ELITE})
			if has_boss:
				options.append({"key": ENEMY_TYPE_BOSS, "label": ENEMY_TYPE_BOSS})

	return options


func get_entries_filtered(category: String, filter_key: String) -> Array[Dictionary]:
	if filter_key == FILTER_ALL or filter_key == "":
		return get_entries(category)

	var all_entries: Array[Dictionary] = get_entries(category)
	var filtered: Array[Dictionary] = []

	match category:
		CATEGORY_PLAYER_UNITS, CATEGORY_RELICS:
			for entry: Dictionary in all_entries:
				var resource: Resource = entry.get("resource", null) as Resource
				if resource != null and _get_string(resource, "rarity") == filter_key:
					filtered.append(entry)

		CATEGORY_ENEMY_UNITS:
			for entry: Dictionary in all_entries:
				var resource: Resource = entry.get("resource", null) as Resource
				if resource != null and _get_enemy_type_key(resource) == filter_key:
					filtered.append(entry)

		_:
			filtered = all_entries.duplicate()

	return filtered


func _collect_relic_dir(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("Failed to open encyclopedia relic dir: " + dir_path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path: String = dir_path + "/" + file_name
			var resource: Resource = ResourceLoader.load(resource_path)
			if _is_relic_data(resource):
				_add_entry(CATEGORY_RELICS, _create_relic_entry(resource, resource_path))
		file_name = dir.get_next()
	dir.list_dir_end()


func _collect_unit_dir(category: String, dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("Failed to open encyclopedia unit dir: " + dir_path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path: String = dir_path + "/" + file_name
			var resource: Resource = ResourceLoader.load(resource_path)
			if _is_unit_data(resource):
				_add_entry(category, _create_unit_entry(resource, resource_path, category))
		file_name = dir.get_next()
	dir.list_dir_end()


func _collect_heroes() -> void:
	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	var heroes: Array[Resource] = hero_manager.get_available_heroes()
	for hero: Resource in heroes:
		if hero == null:
			continue
		_add_entry(CATEGORY_HEROES, _create_hero_entry(hero))


func _add_entry(category: String, entry: Dictionary) -> void:
	if entry.is_empty():
		return

	if not entries_by_category.has(category):
		entries_by_category[category] = []

	(entries_by_category[category] as Array).append(entry)


func _create_unit_entry(unit_data: Resource, resource_path: String, category: String) -> Dictionary:
	var unit_id: String = _get_string(unit_data, "unit_type")
	if unit_id == "":
		unit_id = resource_path.get_file().get_basename()

	var display_name: String = _get_unit_display_name(unit_data)
	return {
		"id": unit_id,
		"name": display_name,
		"sort_name": display_name.to_lower(),
		"category": category,
		"kind": "unit",
		"resource": unit_data,
		"resource_path": resource_path,
	}


func _create_relic_entry(relic_data: Resource, resource_path: String) -> Dictionary:
	var relic_id: String = _get_string(relic_data, "relic_id")
	if relic_id == "":
		relic_id = resource_path.get_file().get_basename()

	var display_name: String = _get_relic_display_name(relic_data)
	return {
		"id": relic_id,
		"name": display_name,
		"sort_name": display_name.to_lower(),
		"category": CATEGORY_RELICS,
		"kind": "relic",
		"resource": relic_data,
		"resource_path": resource_path,
	}


func _create_hero_entry(hero_data: Resource) -> Dictionary:
	var hero_id: String = _get_string(hero_data, "hero_id")
	var display_name: String = _get_hero_display_name(hero_data)
	return {
		"id": hero_id,
		"name": display_name,
		"sort_name": display_name.to_lower(),
		"category": CATEGORY_HEROES,
		"kind": "hero",
		"resource": hero_data,
		"resource_path": "",
	}


func _sort_all_categories() -> void:
	for category: String in get_category_order():
		var entries: Array = entries_by_category.get(category, []) as Array
		entries.sort_custom(Callable(self, "_sort_entries_by_name"))


func _sort_entries_by_name(a: Dictionary, b: Dictionary) -> bool:
	return str(a.get("sort_name", "")) < str(b.get("sort_name", ""))


func _is_unit_data(resource: Resource) -> bool:
	return resource != null and _get_string(resource, "unit_type") != ""


func _is_relic_data(resource: Resource) -> bool:
	return resource != null and _get_string(resource, "relic_id") != ""


func _get_unit_display_name(unit_data: Resource) -> String:
	var cn_name: String = _get_string(unit_data, "unit_name_cn")
	if cn_name != "":
		return cn_name

	var name: String = _get_string(unit_data, "unit_name")
	if name != "":
		return name

	return _get_string(unit_data, "unit_type")


func _get_relic_display_name(relic_data: Resource) -> String:
	var cn_name: String = _get_string(relic_data, "relic_name_cn")
	if cn_name != "":
		return cn_name

	var name: String = _get_string(relic_data, "relic_name")
	if name != "":
		return name

	return _get_string(relic_data, "relic_id")


func _get_hero_display_name(hero_data: Resource) -> String:
	if hero_data != null and hero_data.has_method("get_display_name"):
		return str(hero_data.get_display_name())

	var cn_name: String = _get_string(hero_data, "hero_name_cn")
	if cn_name != "":
		return cn_name

	var name: String = _get_string(hero_data, "hero_name")
	if name != "":
		return name

	return _get_string(hero_data, "hero_id")


func _get_enemy_type_key(unit_data: Resource) -> String:
	var tier: String = _get_string(unit_data, "enemy_tier")
	if tier == "BOSS":
		return ENEMY_TYPE_BOSS
	if tier == "ELITE":
		return ENEMY_TYPE_ELITE
	if tier == "NORMAL":
		return ENEMY_TYPE_NORMAL

	var unit_type: String = _get_string(unit_data, "unit_type")
	if unit_type.begins_with("enemy_boss_"):
		return ENEMY_TYPE_BOSS
	if unit_type.begins_with("enemy_elite_"):
		return ENEMY_TYPE_ELITE
	return ENEMY_TYPE_NORMAL


func _get_rarity_display_name(rarity: String) -> String:
	match rarity:
		"COMMON":
			return "普通"
		"FINE":
			return "精良"
		"RARE":
			return "稀有"
		"EPIC":
			return "史诗"
		"LEGENDARY":
			return "传说"
		"MYTHIC":
			return "神话"
		_:
			return rarity


func _get_string(resource: Resource, property_name: String) -> String:
	if resource == null:
		return ""

	var value: Variant = resource.get(property_name)
	if value == null:
		return ""

	return str(value).strip_edges()
