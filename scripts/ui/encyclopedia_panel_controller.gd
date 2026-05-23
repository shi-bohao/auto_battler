class_name EncyclopediaPanelController
extends RefCounted


const ENCYCLOPEDIA_PANEL_SCENE: PackedScene = preload("res://scenes/ui/encyclopedia_panel.tscn")
const ENCYCLOPEDIA_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/encyclopedia_catalog.gd")
const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")

var panel: Panel = null
var card_panel: Panel = null
var close_button: Button = null
var title_label: Label = null
var category_hbox: HBoxContainer = null
var entry_list_vbox: VBoxContainer = null
var detail_text: RichTextLabel = null
var count_label: Label = null
var catalog: Variant = ENCYCLOPEDIA_CATALOG_SCRIPT.new()
var unit_text_formatter: Variant = null
var rarity_formatter: Variant = null
var selected_category: String = ""
var selected_entry_id: String = ""
var category_buttons: Dictionary = {}


func setup(canvas_layer: CanvasLayer, unit_text_formatter_value: Variant, rarity_formatter_value: Variant) -> void:
	unit_text_formatter = unit_text_formatter_value
	rarity_formatter = rarity_formatter_value
	if canvas_layer == null:
		return

	panel = ENCYCLOPEDIA_PANEL_SCENE.instantiate() as Panel
	if panel == null:
		return

	canvas_layer.add_child(panel)
	_bind_nodes()
	_apply_style()
	_connect_buttons()


func show() -> void:
	if panel == null:
		return

	catalog.refresh()
	_rebuild_category_buttons()
	var category_order: Array[String] = catalog.get_category_order()
	if selected_category == "" and not category_order.is_empty():
		selected_category = category_order[0]
	_rebuild_entry_list()
	panel.visible = true


func hide() -> void:
	if panel != null:
		panel.visible = false


func is_visible() -> bool:
	return panel != null and panel.visible


func _bind_nodes() -> void:
	if panel == null:
		return

	card_panel = panel.get_node_or_null("Card") as Panel
	title_label = panel.get_node_or_null("Card/TitleLabel") as Label
	close_button = panel.get_node_or_null("Card/CloseButton") as Button
	category_hbox = panel.get_node_or_null("Card/CategoryHBox") as HBoxContainer
	entry_list_vbox = panel.get_node_or_null("Card/ListPanel/EntryListScroll/EntryListVBox") as VBoxContainer
	detail_text = panel.get_node_or_null("Card/DetailPanel/DetailScroll/DetailText") as RichTextLabel
	count_label = panel.get_node_or_null("Card/CountLabel") as Label


func _connect_buttons() -> void:
	if close_button != null:
		close_button.pressed.connect(hide)


func _apply_style() -> void:
	if panel != null:
		panel.add_theme_stylebox_override("panel", _create_style(Color(0.0, 0.0, 0.0, 0.62), Color.TRANSPARENT, 0, 0))

	if card_panel != null:
		card_panel.add_theme_stylebox_override("panel", _create_style(Color(0.045, 0.062, 0.095, 0.97), Color(0.70, 0.54, 0.32, 1.0), 8, 2))

	if title_label != null:
		title_label.add_theme_font_size_override("font_size", 28)
		title_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.58, 1.0))
		title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
		title_label.add_theme_constant_override("outline_size", 2)

	if close_button != null:
		close_button.add_theme_font_size_override("font_size", 22)
		_apply_button_style(close_button, false, Color(0.22, 0.25, 0.30, 1.0), Color(0.72, 0.60, 0.44, 1.0))

	var list_panel: Panel = null
	if panel != null:
		list_panel = panel.get_node_or_null("Card/ListPanel") as Panel
	if list_panel != null:
		list_panel.add_theme_stylebox_override("panel", _create_style(Color(0.06, 0.09, 0.14, 0.92), Color(0.32, 0.45, 0.62, 1.0), 6, 1))

	var detail_panel: Panel = null
	if panel != null:
		detail_panel = panel.get_node_or_null("Card/DetailPanel") as Panel
	if detail_panel != null:
		detail_panel.add_theme_stylebox_override("panel", _create_style(Color(0.055, 0.075, 0.115, 0.92), Color(0.42, 0.56, 0.72, 1.0), 6, 1))

	if detail_text != null:
		detail_text.add_theme_font_size_override("normal_font_size", 17)
		detail_text.add_theme_color_override("default_color", Color(0.90, 0.93, 0.98, 1.0))

	if count_label != null:
		count_label.add_theme_font_size_override("font_size", 15)
		count_label.add_theme_color_override("font_color", Color(0.76, 0.82, 0.90, 1.0))


func _rebuild_category_buttons() -> void:
	if category_hbox == null:
		return

	for child: Node in category_hbox.get_children():
		category_hbox.remove_child(child)
		child.queue_free()
	category_buttons.clear()

	for category: String in catalog.get_category_order():
		var button: Button = Button.new()
		button.text = catalog.get_category_display_name(category)
		button.custom_minimum_size = Vector2(150.0, 38.0)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_category_pressed.bind(category))
		category_hbox.add_child(button)
		category_buttons[category] = button

	_update_category_button_styles()


func _rebuild_entry_list() -> void:
	if entry_list_vbox == null:
		return

	for child: Node in entry_list_vbox.get_children():
		entry_list_vbox.remove_child(child)
		child.queue_free()

	var entries: Array[Dictionary] = catalog.get_entries(selected_category)
	if count_label != null:
		count_label.text = catalog.get_category_display_name(selected_category) + "：" + str(entries.size()) + " 项"

	if entries.is_empty():
		selected_entry_id = ""
		_show_empty_detail()
		return

	var has_selected_entry: bool = false
	for entry: Dictionary in entries:
		if str(entry.get("id", "")) == selected_entry_id:
			has_selected_entry = true
			break
	if not has_selected_entry:
		selected_entry_id = str(entries[0].get("id", ""))

	for entry: Dictionary in entries:
		var button: Button = Button.new()
		var entry_id: String = str(entry.get("id", ""))
		button.text = _format_entry_button_text(entry)
		button.custom_minimum_size = Vector2(300.0, 38.0)
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_entry_pressed.bind(entry))
		_apply_entry_button_style(button, entry_id == selected_entry_id)
		entry_list_vbox.add_child(button)

		if entry_id == selected_entry_id:
			_show_entry_detail(entry)


func _on_category_pressed(category: String) -> void:
	if selected_category == category:
		return

	selected_category = category
	selected_entry_id = ""
	_update_category_button_styles()
	_rebuild_entry_list()


func _on_entry_pressed(entry: Dictionary) -> void:
	selected_entry_id = str(entry.get("id", ""))
	_rebuild_entry_list()


func _update_category_button_styles() -> void:
	for category: String in category_buttons.keys():
		var button: Button = category_buttons[category] as Button
		if button == null:
			continue
		_apply_button_style(button, category == selected_category, Color(0.12, 0.20, 0.33, 1.0), Color(0.62, 0.78, 0.96, 1.0))


func _show_empty_detail() -> void:
	if detail_text != null:
		detail_text.text = "暂无条目"


func _show_entry_detail(entry: Dictionary) -> void:
	if detail_text == null:
		return

	match str(entry.get("kind", "")):
		"relic":
			detail_text.text = _build_relic_detail(entry)
		"hero":
			detail_text.text = _build_hero_detail(entry)
		_:
			detail_text.text = _build_unit_detail(entry)


func _format_entry_button_text(entry: Dictionary) -> String:
	var name: String = str(entry.get("name", ""))
	var resource: Resource = entry.get("resource", null) as Resource
	var rarity: String = ""
	match str(entry.get("kind", "")):
		"relic":
			rarity = _get_string(resource, "rarity")
		"unit":
			rarity = _get_string(resource, "rarity")
		"hero":
			rarity = "MYTHIC"
	if rarity != "":
		return name + "  [" + _get_rarity_display_name(rarity) + "]"
	return name


func _build_unit_detail(entry: Dictionary) -> String:
	var unit_data: Resource = entry.get("resource", null) as Resource
	if unit_data == null:
		return ""

	var lines: Array[String] = []
	lines.append(str(entry.get("name", "")))
	lines.append(_get_category_meta_text(str(entry.get("category", "")), unit_data))
	_append_non_empty(lines, _get_unit_description(unit_data))
	lines.append("")
	lines.append("基础属性")
	lines.append_array(_get_unit_stat_lines(unit_data))
	lines.append("")
	_append_skill_lines(lines, unit_data, maxi(1, int(_get_number(unit_data, "star", 1.0))))
	return _join_lines(lines)


func _build_relic_detail(entry: Dictionary) -> String:
	var relic_data: Resource = entry.get("resource", null) as Resource
	if relic_data == null:
		return ""

	var lines: Array[String] = []
	lines.append(str(entry.get("name", "")))
	lines.append("稀有度：" + _get_rarity_display_name(_get_string(relic_data, "rarity")))
	lines.append("触发：" + _get_trigger_display_name(_get_string(relic_data, "trigger_type")))
	lines.append("数值：" + _format_number(_get_number(relic_data, "value", 0.0)))
	_append_non_empty(lines, _get_relic_description(relic_data))
	lines.append("")
	lines.append("资源：" + str(entry.get("resource_path", "")))
	return _join_lines(lines)


func _build_hero_detail(entry: Dictionary) -> String:
	var hero_data: Resource = entry.get("resource", null) as Resource
	if hero_data == null:
		return ""

	var unit_data: Resource = hero_data.get("hero_unit_data") as Resource
	var lines: Array[String] = []
	lines.append(str(entry.get("name", "")))
	lines.append("分类：英雄 / " + _get_rarity_display_name("MYTHIC"))
	_append_non_empty(lines, _get_string(hero_data, "description"))
	var tagline: String = str(hero_data.call("get_tagline")) if hero_data.has_method("get_tagline") else ""
	_append_non_empty(lines, "定位：" + tagline if tagline != "" else "")
	lines.append("")

	if unit_data != null:
		lines.append("基础属性")
		lines.append_array(_get_unit_stat_lines(unit_data))
		lines.append("")
		_append_skill_lines(lines, unit_data, 1)
		lines.append("")

	var recommended_cells: Array[String] = _get_recommended_cell_text(hero_data)
	if not recommended_cells.is_empty():
		lines.append("推荐站位：" + _join_text(recommended_cells, " / "))
		lines.append("")

	var upgrade_lines: Array[String] = _get_hero_upgrade_lines(hero_data)
	if not upgrade_lines.is_empty():
		lines.append("专属强化")
		lines.append_array(upgrade_lines)

	return _join_lines(lines)


func _get_category_meta_text(category: String, unit_data: Resource) -> String:
	var parts: Array[String] = []
	parts.append(catalog.get_category_display_name(category))
	parts.append(_get_role_display_name(_get_string(unit_data, "role")))
	parts.append(_get_rarity_display_name(_get_string(unit_data, "rarity")))
	var unit_type: String = _get_string(unit_data, "unit_type")
	if unit_type != "":
		parts.append(unit_type)
	return _join_text(parts, " / ")


func _get_unit_stat_lines(unit_data: Resource) -> Array[String]:
	var lines: Array[String] = []
	lines.append("生命 " + str(int(_get_number(unit_data, "max_hp", 0.0))) + "    攻击 " + str(int(_get_number(unit_data, "attack_damage", 0.0))) + "    防御 " + str(int(_get_number(unit_data, "defense", 0.0))))
	lines.append("攻速 " + _format_attack_speed(_get_number(unit_data, "attack_interval", 1.0)) + "    范围 " + _format_number(_get_number(unit_data, "attack_range", 0.0)) + "    移速 " + _format_number(_get_number(unit_data, "move_speed", 0.0)))
	lines.append("魔力 " + str(int(_get_number(unit_data, "max_mana", 0.0))) + "    回魔 " + _format_number(_get_number(unit_data, "mana_regen_per_second", 0.0)) + "/秒    初始魔力 " + _format_number(_get_number(unit_data, "initial_mana", 0.0)))
	lines.append("暴击 " + _format_percent(_get_number(unit_data, "crit_chance", 0.0)) + "    暴伤 x" + _format_number(_get_number(unit_data, "crit_damage_multiplier", 1.5)) + "    技能强度 " + _format_percent(_get_number(unit_data, "skill_power", 0.0)))
	lines.append("治疗强度 " + _format_percent(_get_number(unit_data, "healing_power", 0.0)) + "    护盾强度 " + _format_percent(_get_number(unit_data, "shield_power", 0.0)) + "    防御穿透 " + str(int(_get_number(unit_data, "defense_penetration", 0.0))))
	lines.append("吸血 " + _format_percent(_get_number(unit_data, "life_steal", 0.0)) + "    减伤 " + _format_percent(_get_number(unit_data, "damage_reduction", 0.0)) + "    闪避 " + _format_percent(_get_number(unit_data, "dodge_chance", 0.0)))
	lines.append("普攻回魔 " + _format_number(_get_number(unit_data, "mana_on_attack", 0.0)) + "    受击回魔 " + _format_number(_get_number(unit_data, "mana_on_hit_taken", 0.0)) + "    状态抗性 " + _format_percent(_get_number(unit_data, "status_resistance", 0.0)))
	return lines


func _append_skill_lines(lines: Array[String], unit_data: Resource, star: int) -> void:
	var passive_id: String = _get_string(unit_data, "passive_id")
	var active_skill_id: String = _get_string(unit_data, "active_skill_id")
	var passive_text: String = _get_passive_skill_text(passive_id, star)
	var active_text: String = _get_active_skill_text(active_skill_id, star)
	lines.append("被动技能：" + _extract_skill_name(passive_text, passive_id))
	_append_non_empty(lines, passive_text)
	lines.append("")
	lines.append("主动技能：" + _extract_skill_name(active_text, active_skill_id))
	_append_non_empty(lines, active_text)


func _get_hero_upgrade_lines(hero_data: Resource) -> Array[String]:
	var lines: Array[String] = []
	var upgrade_pool_value: Variant = hero_data.get("upgrade_pool")
	if not (upgrade_pool_value is Array):
		return lines

	var upgrade_pool: Array = upgrade_pool_value as Array
	for upgrade_value: Variant in upgrade_pool:
		var upgrade: Resource = upgrade_value as Resource
		if upgrade == null:
			continue
		var upgrade_name: String = _get_string(upgrade, "upgrade_name")
		var description: String = _get_string(upgrade, "description")
		var required_level: int = int(_get_number(upgrade, "required_level", 1.0))
		if upgrade_name != "" and description != "":
			lines.append("Lv." + str(required_level) + " " + upgrade_name + "：" + description)

	return lines


func _get_recommended_cell_text(hero_data: Resource) -> Array[String]:
	var result: Array[String] = []
	var cells_value: Variant = hero_data.get("recommended_cells")
	if not (cells_value is Array):
		return result

	for cell_value: Variant in (cells_value as Array):
		var cell: Vector2i = cell_value as Vector2i
		result.append("(" + str(cell.x) + "," + str(cell.y) + ")")

	return result


func _get_unit_description(unit_data: Resource) -> String:
	var description: String = _get_string(unit_data, "description_cn")
	if description != "":
		return description

	if unit_text_formatter != null and unit_text_formatter.has_method("get_unit_description"):
		return str(unit_text_formatter.get_unit_description(unit_data)).strip_edges()

	return ""


func _get_relic_description(relic_data: Resource) -> String:
	var description: String = _get_string(relic_data, "description_cn")
	if description != "":
		return description

	return _get_string(relic_data, "description")


func _get_passive_skill_text(passive_id: String, star: int) -> String:
	if passive_id == "":
		return ""
	if unit_text_formatter != null and unit_text_formatter.has_method("get_passive_skill_text"):
		return str(unit_text_formatter.get_passive_skill_text(passive_id, star)).strip_edges()
	return passive_id


func _get_active_skill_text(active_skill_id: String, star: int) -> String:
	if active_skill_id == "":
		return ""
	if unit_text_formatter != null and unit_text_formatter.has_method("get_active_skill_text"):
		return str(unit_text_formatter.get_active_skill_text(active_skill_id, star)).strip_edges()
	return active_skill_id


func _extract_skill_name(detail: String, fallback_id: String) -> String:
	var safe_detail: String = detail.strip_edges()
	if safe_detail == "":
		return fallback_id if fallback_id != "" else "-"

	var first_line: String = safe_detail.split("\n", false, 1)[0]
	var colon_index: int = first_line.find("：")
	if colon_index < 0:
		colon_index = first_line.find(":")
	if colon_index > 0:
		return first_line.substr(0, colon_index).strip_edges()

	return first_line.strip_edges()


func _get_trigger_display_name(trigger_type: String) -> String:
	match trigger_type:
		"BATTLE_START":
			return "战斗开始"
		"ON_ATTACK":
			return "普通攻击"
		"ON_KILL":
			return "击杀"
		"ON_DEATH":
			return "死亡"
		_:
			return trigger_type if trigger_type != "" else "-"


func _get_role_display_name(role: String) -> String:
	match role:
		"tank":
			return "承伤"
		"support":
			return "辅助"
		"damage":
			return "输出"
		_:
			return role if role != "" else "-"


func _get_rarity_display_name(rarity: String) -> String:
	if rarity_formatter != null and rarity_formatter.has_method("get_display_name"):
		return str(rarity_formatter.get_display_name(rarity))
	return rarity if rarity != "" else "COMMON"


func _get_string(resource: Resource, property_name: String) -> String:
	if resource == null:
		return ""
	var value: Variant = resource.get(property_name)
	if value == null:
		return ""
	return str(value).strip_edges()


func _get_number(resource: Resource, property_name: String, default_value: float) -> float:
	if resource == null:
		return default_value
	var value: Variant = resource.get(property_name)
	if value == null:
		return default_value
	return float(value)


func _append_non_empty(lines: Array[String], text: String) -> void:
	if text.strip_edges() != "":
		lines.append(text.strip_edges())


func _join_lines(lines: Array[String]) -> String:
	return _join_text(lines, "\n")


func _join_text(parts: Array[String], separator: String) -> String:
	var joined: String = ""
	for index: int in range(parts.size()):
		if index > 0:
			joined += separator
		joined += parts[index]
	return joined


func _format_percent(value: float) -> String:
	return "%0.0f%%" % (value * 100.0)


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%0.1f" % value


func _format_attack_speed(attack_interval: float) -> String:
	if attack_interval <= 0.0:
		return "-"
	return _format_number(1.0 / attack_interval) + "/秒"


func _apply_entry_button_style(button: Button, selected: bool) -> void:
	var base_color: Color = Color(0.10, 0.16, 0.25, 1.0) if not selected else Color(0.24, 0.36, 0.52, 1.0)
	var border_color: Color = Color(0.36, 0.50, 0.68, 1.0) if not selected else Color(0.98, 0.80, 0.42, 1.0)
	_apply_button_style(button, selected, base_color, border_color)
	button.add_theme_font_size_override("font_size", 15)


func _apply_button_style(button: Button, selected: bool, base_color: Color, border_color: Color) -> void:
	if button == null:
		return

	var normal_color: Color = base_color if not selected else Color(minf(base_color.r + 0.10, 1.0), minf(base_color.g + 0.10, 1.0), minf(base_color.b + 0.10, 1.0), base_color.a)
	PIXEL_UI_THEME.apply_button_style(button, normal_color, border_color, 2, 16)


func _create_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_panel_style(bg_color, border_color, border_width, 8.0)


func _lighten_color(color: Color, amount: float) -> Color:
	return Color(minf(color.r + amount, 1.0), minf(color.g + amount, 1.0), minf(color.b + amount, 1.0), color.a)


func _darken_color(color: Color, amount: float) -> Color:
	return Color(maxf(color.r - amount, 0.0), maxf(color.g - amount, 0.0), maxf(color.b - amount, 0.0), color.a)
