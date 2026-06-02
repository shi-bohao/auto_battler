extends SceneTree


const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const HERO_MANAGER_SCRIPT: Script = preload("res://scripts/hero_manager.gd")

const OUT_PATH: String = "res://docs/content_reference.md"
const PLAYER_UNIT_DIR: String = "res://data/units"
const ENEMY_UNIT_DIR: String = "res://data/enemies"
const SUMMON_UNIT_DIR: String = "res://data/summons"
const RELIC_DIR: String = "res://data/relics"

var unit_text_formatter: Variant = UNIT_TEXT_FORMATTER_SCRIPT.new()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var lines: Array[String] = []
	lines.append("# 当前单位与遗物信息总览")
	lines.append("")
	lines.append("更新时间：2026-06-01")
	lines.append("")
	lines.append("> 本文档用于快速核对当前项目已实现的单位、召唤物和遗物数值。单位属性来自 `UnitData` 资源默认值与 `.tres` 配置；技能说明来自 `UnitTextFormatter`；遗物信息来自 `RelicData`。")
	lines.append("")
	lines.append("## 维护方式")
	lines.append("")
	lines.append("```text")
	lines.append("Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tools/generate_content_reference.gd")
	lines.append("```")
	lines.append("")
	_append_unit_section(lines, "玩家单位", PLAYER_UNIT_DIR)
	_append_hero_section(lines)
	_append_unit_section(lines, "敌方单位", ENEMY_UNIT_DIR)
	_append_unit_section(lines, "召唤物", SUMMON_UNIT_DIR)
	_append_relic_section(lines)
	while not lines.is_empty() and lines[lines.size() - 1] == "":
		lines.remove_at(lines.size() - 1)

	var file: FileAccess = FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open output file: " + OUT_PATH)
		quit(1)
		return

	file.store_string(_join_lines(lines))
	file.close()
	print("Generated content reference: " + OUT_PATH)
	quit(0)


func _append_unit_section(lines: Array[String], title: String, dir_path: String) -> void:
	var entries: Array[Dictionary] = _load_unit_entries(dir_path)
	lines.append("## " + title)
	lines.append("")
	lines.append("| 名称 | ID | 简介 | 定位 | 羁绊 | 基本信息 | 基础属性 | 扩展属性 | 技能 |")
	lines.append("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
	for entry: Dictionary in entries:
		var unit_data: Resource = entry["resource"] as Resource
		lines.append("| " + _cell(_get_unit_display_name(unit_data)) \
			+ " | `" + _cell(_get_string(unit_data, "unit_type")) + "`" \
			+ " | " + _cell(_get_string(unit_data, "description_cn")) \
			+ " | " + _cell(_format_role(unit_data)) \
			+ " | " + _cell(_format_bond_tags(unit_data)) \
			+ " | " + _cell(_format_unit_meta(unit_data)) \
			+ " | " + _cell(_format_base_stats(unit_data)) \
			+ " | " + _cell(_format_extended_stats(unit_data)) \
			+ " | " + _cell(_format_unit_skills(unit_data)) \
			+ " |")
	lines.append("")


func _append_hero_section(lines: Array[String]) -> void:
	var hero_manager: Variant = HERO_MANAGER_SCRIPT.new()
	var heroes: Array[Resource] = hero_manager.get_available_heroes()
	heroes.sort_custom(Callable(self, "_sort_heroes_by_catalog_id"))
	lines.append("## 英雄（特殊玩家单位）")
	lines.append("")
	lines.append("| 名称 | ID | 简介 | 羁绊 | 推荐站位 | 基础属性 | 扩展属性 | 技能 |")
	lines.append("| --- | --- | --- | --- | --- | --- | --- | --- |")
	for hero_data: Resource in heroes:
		var unit_data: Resource = hero_data.get("hero_unit_data") as Resource
		if unit_data == null:
			continue
		lines.append("| " + _cell(_get_hero_display_name(hero_data)) \
			+ " | `" + _cell(_get_string(hero_data, "hero_id")) + "`" \
			+ " | " + _cell(_get_string(hero_data, "description")) \
			+ " | " + _cell(_format_bond_tags(unit_data)) \
			+ " | " + _cell(_format_hero_cells(hero_data)) \
			+ " | " + _cell(_format_base_stats(unit_data)) \
			+ " | " + _cell(_format_extended_stats(unit_data)) \
			+ " | " + _cell(_format_hero_skills(hero_data, unit_data)) \
			+ " |")
	lines.append("")


func _append_relic_section(lines: Array[String]) -> void:
	var entries: Array[Dictionary] = _load_relic_entries(RELIC_DIR)
	lines.append("## 遗物")
	lines.append("")
	lines.append("| 名称 | ID | 稀有度 | 触发 | 数值 | 效果 |")
	lines.append("| --- | --- | --- | --- | --- | --- |")
	for entry: Dictionary in entries:
		var relic_data: Resource = entry["resource"] as Resource
		lines.append("| " + _cell(_get_relic_display_name(relic_data)) \
			+ " | `" + _cell(_get_string(relic_data, "relic_id")) + "`" \
			+ " | " + _cell(_get_string(relic_data, "rarity")) \
			+ " | " + _cell(_get_string(relic_data, "trigger_type")) \
			+ " | " + _cell(_format_number(_get_float(relic_data, "value", 0.0))) \
			+ " | " + _cell(_get_relic_effect_text(relic_data)) \
			+ " |")
	lines.append("")


func _load_unit_entries(dir_path: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("Failed to open unit dir: " + dir_path)
		return entries

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = dir_path + "/" + file_name
			var resource: Resource = ResourceLoader.load(path)
			if resource != null and _get_string(resource, "unit_type") != "":
				entries.append({
					"name": _get_unit_display_name(resource),
					"resource": resource,
				})
		file_name = dir.get_next()
	dir.list_dir_end()
	entries.sort_custom(Callable(self, "_sort_entries_by_catalog_id"))
	return entries


func _load_relic_entries(dir_path: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("Failed to open relic dir: " + dir_path)
		return entries

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var path: String = dir_path + "/" + file_name
			var resource: Resource = ResourceLoader.load(path)
			if resource != null and _get_string(resource, "relic_id") != "":
				entries.append({
					"name": _get_relic_display_name(resource),
					"resource": resource,
				})
		file_name = dir.get_next()
	dir.list_dir_end()
	entries.sort_custom(Callable(self, "_sort_entries_by_catalog_id"))
	return entries


func _sort_entries_by_catalog_id(a: Dictionary, b: Dictionary) -> bool:
	var a_resource: Resource = a.get("resource", null) as Resource
	var b_resource: Resource = b.get("resource", null) as Resource
	var a_catalog_id: int = _get_catalog_id(a_resource)
	var b_catalog_id: int = _get_catalog_id(b_resource)
	if a_catalog_id > 0 and b_catalog_id > 0 and a_catalog_id != b_catalog_id:
		return a_catalog_id < b_catalog_id
	if a_catalog_id > 0 and b_catalog_id <= 0:
		return true
	if a_catalog_id <= 0 and b_catalog_id > 0:
		return false
	return str(a.get("name", "")).to_lower() < str(b.get("name", "")).to_lower()


func _sort_heroes_by_catalog_id(a: Resource, b: Resource) -> bool:
	var a_catalog_id: int = _get_catalog_id(a)
	var b_catalog_id: int = _get_catalog_id(b)
	if a_catalog_id > 0 and b_catalog_id > 0 and a_catalog_id != b_catalog_id:
		return a_catalog_id < b_catalog_id
	if a_catalog_id > 0 and b_catalog_id <= 0:
		return true
	if a_catalog_id <= 0 and b_catalog_id > 0:
		return false
	return _get_hero_display_name(a).to_lower() < _get_hero_display_name(b).to_lower()


func _get_unit_display_name(unit_data: Resource) -> String:
	var cn_name: String = _get_string(unit_data, "unit_name_cn")
	var en_name: String = _get_string(unit_data, "unit_name")
	if cn_name != "" and en_name != "" and cn_name != en_name:
		return cn_name + "<br>(" + en_name + ")"
	if cn_name != "":
		return cn_name
	if en_name != "":
		return en_name
	return _get_string(unit_data, "unit_type")


func _get_hero_display_name(hero_data: Resource) -> String:
	var cn_name: String = _get_string(hero_data, "hero_name_cn")
	var en_name: String = _get_string(hero_data, "hero_name")
	if cn_name != "" and en_name != "" and cn_name != en_name:
		return cn_name + "<br>(" + en_name + ")"
	if cn_name != "":
		return cn_name
	if en_name != "":
		return en_name
	return _get_string(hero_data, "hero_id")


func _get_relic_display_name(relic_data: Resource) -> String:
	var cn_name: String = _get_string(relic_data, "relic_name_cn")
	var en_name: String = _get_string(relic_data, "relic_name")
	if cn_name != "" and en_name != "" and cn_name != en_name:
		return cn_name + "<br>(" + en_name + ")"
	if cn_name != "":
		return cn_name
	if en_name != "":
		return en_name
	return _get_string(relic_data, "relic_id")


func _format_role(unit_data: Resource) -> String:
	return _get_string(unit_data, "role")


func _format_bond_tags(unit_data: Resource) -> String:
	var tags: Variant = unit_data.get("bond_tags")
	if not (tags is Array) or tags.is_empty():
		return "-"

	var parts: Array[String] = []
	for tag_value: Variant in tags:
		var tag: String = str(tag_value)
		match tag:
			"iron_wall":
				parts.append("铁壁")
			"hunter":
				parts.append("猎手")
			"arcane":
				parts.append("奥术")
			"divine":
				parts.append("圣疗")
			"summon":
				parts.append("召唤")
			"venom":
				parts.append("剧毒")
			_:
				if tag != "":
					parts.append(tag)

	if parts.is_empty():
		return "-"
	return _join_parts(parts, "<br>")


func _format_unit_meta(unit_data: Resource) -> String:
	var parts: Array[String] = []
	parts.append("星级 " + str(_get_int(unit_data, "star", 1)))
	parts.append("稀有度 " + _get_string(unit_data, "rarity"))
	parts.append("价格 " + str(_get_int(unit_data, "price", 0)))
	parts.append("目标 " + _get_string(unit_data, "target_mode"))
	var attack_type: String = _get_string(unit_data, "basic_attack_type")
	if attack_type == "projectile":
		var visual_type: String = _get_string(unit_data, "projectile_visual_type")
		var speed_val: float = _get_float(unit_data, "projectile_speed", 500.0)
		parts.append("弹道 " + visual_type + " " + _format_number(speed_val))
	return _join_parts(parts, "<br>")


func _format_base_stats(unit_data: Resource) -> String:
	var parts: Array[String] = []
	parts.append("生命 " + str(_get_int(unit_data, "max_hp", 0)))
	parts.append("攻击 " + str(_get_int(unit_data, "attack_damage", 0)))
	parts.append("防御 " + str(_get_int(unit_data, "defense", 0)))
	parts.append("攻速间隔 " + _format_number(_get_float(unit_data, "attack_interval", 0.0)) + "s")
	parts.append("范围 " + _format_number(_get_float(unit_data, "attack_range", 0.0)))
	parts.append("移速 " + _format_number(_get_float(unit_data, "move_speed", 0.0)))
	parts.append("魔力 " + str(_get_int(unit_data, "max_mana", 0)))
	parts.append("回魔 " + _format_number(_get_float(unit_data, "mana_regen_per_second", 0.0)) + "/s")
	return _join_parts(parts, "<br>")


func _format_extended_stats(unit_data: Resource) -> String:
	var parts: Array[String] = []
	parts.append("暴击 " + _format_percent(_get_float(unit_data, "crit_chance", 0.0)))
	parts.append("暴伤 x" + _format_number(_get_float(unit_data, "crit_damage_multiplier", 1.5)))
	parts.append("技能强度 " + _format_percent(_get_float(unit_data, "skill_power", 0.0)))
	parts.append("治疗强度 " + _format_percent(_get_float(unit_data, "healing_power", 0.0)))
	parts.append("护盾强度 " + _format_percent(_get_float(unit_data, "shield_power", 0.0)))
	parts.append("防御穿透 " + str(_get_int(unit_data, "defense_penetration", 0)))
	parts.append("吸血 " + _format_percent(_get_float(unit_data, "life_steal", 0.0)))
	parts.append("减伤 " + _format_percent(_get_float(unit_data, "damage_reduction", 0.0)))
	parts.append("伤害承受倍率 x" + _format_number(_get_float(unit_data, "damage_taken_multiplier", 1.0)))
	parts.append("初始魔力 " + _format_number(_get_float(unit_data, "initial_mana", 0.0)))
	parts.append("普攻回魔 " + _format_number(_get_float(unit_data, "mana_on_attack", 0.0)))
	parts.append("受击回魔 " + _format_number(_get_float(unit_data, "mana_on_hit_taken", 0.0)))
	parts.append("状态抗性 " + _format_percent(_get_float(unit_data, "status_resistance", 0.0)))
	parts.append("闪避 " + _format_percent(_get_float(unit_data, "dodge_chance", 0.0)))
	return _join_parts(parts, "<br>")


func _format_unit_skills(unit_data: Resource) -> String:
	var star: int = _get_int(unit_data, "star", 1)
	var passive_id: String = _get_string(unit_data, "passive_id")
	var active_id: String = _get_string(unit_data, "active_skill_id")
	var parts: Array[String] = []
	if passive_id != "":
		parts.append("被动 `" + passive_id + "`：" + unit_text_formatter.get_passive_skill_text(passive_id, star))
	if active_id != "":
		parts.append("主动 `" + active_id + "`：" + unit_text_formatter.get_active_skill_text(active_id, star))
	if parts.is_empty():
		return "-"
	return _join_parts(parts, "<br>")


func _format_hero_skills(hero_data: Resource, unit_data: Resource) -> String:
	var parts: Array[String] = []
	var passive_id: String = _get_string(unit_data, "passive_id")
	if passive_id != "":
		parts.append("被动 `" + passive_id + "`：" + unit_text_formatter.get_passive_skill_text(passive_id, 1))
	var active_id: String = _get_string(hero_data, "base_active_skill_id")
	if active_id == "":
		active_id = _get_string(unit_data, "active_skill_id")
	if active_id != "":
		parts.append("主动 `" + active_id + "`：" + unit_text_formatter.get_active_skill_text(active_id, 1))
	if parts.is_empty():
		return "-"
	return _join_parts(parts, "<br>")


func _format_hero_cells(hero_data: Resource) -> String:
	var cells: Array = hero_data.get("recommended_cells") as Array
	if cells.is_empty():
		return "-"

	var parts: Array[String] = []
	for cell_value: Variant in cells:
		var cell: Vector2i = cell_value
		parts.append("(" + str(cell.x) + "," + str(cell.y) + ")")
	return _join_parts(parts, " / ")


func _get_relic_effect_text(relic_data: Resource) -> String:
	var cn_description: String = _get_string(relic_data, "description_cn")
	if cn_description != "":
		return cn_description
	return _get_string(relic_data, "description")


func _get_string(resource: Resource, property_name: String) -> String:
	if resource == null:
		return ""
	var value: Variant = resource.get(property_name)
	if value == null:
		return ""
	return str(value).strip_edges()


func _get_catalog_id(resource: Resource) -> int:
	if resource == null:
		return 0
	var value: Variant = resource.get("catalog_id")
	if value == null:
		return 0
	return maxi(0, int(value))


func _get_int(resource: Resource, property_name: String, default_value: int) -> int:
	if resource == null:
		return default_value
	var value: Variant = resource.get(property_name)
	if value == null:
		return default_value
	return int(value)


func _get_float(resource: Resource, property_name: String, default_value: float) -> float:
	if resource == null:
		return default_value
	var value: Variant = resource.get(property_name)
	if value == null:
		return default_value
	return float(value)


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.2f" % value


func _format_percent(value: float) -> String:
	return _format_number(value * 100.0) + "%"


func _cell(value: String) -> String:
	var text: String = value.strip_edges()
	if text == "":
		text = "-"
	text = text.replace("\r\n", "<br>").replace("\n", "<br>")
	text = text.replace("|", "\\|")
	return text


func _join_parts(parts: Array[String], separator: String) -> String:
	var output: String = ""
	for index: int in range(parts.size()):
		if index > 0:
			output += separator
		output += parts[index]
	return output


func _join_lines(lines: Array[String]) -> String:
	var output: String = ""
	for index: int in range(lines.size()):
		if index > 0:
			output += "\n"
		output += lines[index]
	return output
