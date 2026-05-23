class_name UnitDetailPanelController
extends RefCounted


const SKILL_TYPE_NONE: String = ""
const SKILL_TYPE_PASSIVE: String = "PASSIVE"
const SKILL_TYPE_ACTIVE: String = "ACTIVE"
const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")

var panel: Panel = null
var title_label: Label = null
var detail_text: RichTextLabel = null
var unit_text_formatter: Variant = null
var rarity_formatter: Variant = null
var battle_board: Variant = null
var selected_unit: Unit = null
var selected_skill_type: String = SKILL_TYPE_NONE

var portrait_frame: ColorRect = null
var portrait_placeholder: Label = null
var unit_name_label: Label = null
var unit_meta_label: Label = null
var base_stats_grid: GridContainer = null
var passive_skill_button: Button = null
var active_skill_button: Button = null
var hero_upgrade_title_label: Label = null
var hero_upgrade_text: RichTextLabel = null
var skill_detail_title: Label = null


func setup(
	panel_value: Panel,
	title_label_value: Label,
	detail_text_value: RichTextLabel,
	unit_text_formatter_value: Variant,
	rarity_formatter_value: Variant,
	battle_board_value: Variant
) -> void:
	panel = panel_value
	title_label = title_label_value
	detail_text = detail_text_value
	unit_text_formatter = unit_text_formatter_value
	rarity_formatter = rarity_formatter_value
	battle_board = battle_board_value
	_bind_ui_nodes()
	_connect_skill_buttons()
	_apply_ui_style()


func show(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		hide()
		return

	selected_unit = unit
	selected_skill_type = SKILL_TYPE_NONE
	_refresh_panel_content()
	if panel != null:
		panel.visible = true
		panel.position = _get_clamped_panel_position()


func hide() -> void:
	selected_unit = null
	selected_skill_type = SKILL_TYPE_NONE
	if panel != null:
		panel.visible = false


func refresh_if_open() -> void:
	if panel == null or not panel.visible:
		return

	if selected_unit == null or not is_instance_valid(selected_unit):
		hide()
		return

	_refresh_panel_content()


func build_unit_detail_text(unit: Unit) -> String:
	if unit == null or not is_instance_valid(unit):
		return ""

	var lines: Array[String] = []
	lines.append(unit.display_name)
	lines.append(_get_unit_meta_text(unit))
	lines.append("")
	lines.append("基础属性")
	for stat: Dictionary in _get_base_stat_items(unit):
		lines.append(str(stat.get("name", "")) + "：" + str(stat.get("value", "")))
	lines.append("")
	lines.append("被动技能：" + _get_passive_skill_display_name(unit))
	lines.append("主动技能：" + _get_active_skill_display_name(unit))
	return _join_text(lines, "\n")


func _bind_ui_nodes() -> void:
	if panel == null:
		return

	portrait_frame = panel.get_node_or_null("PortraitFrame ColorRect") as ColorRect
	portrait_placeholder = panel.get_node_or_null("PortraitFrame ColorRect/PortraitPlaceholder Label") as Label
	unit_name_label = panel.get_node_or_null("UnitName Label") as Label
	unit_meta_label = panel.get_node_or_null("UnitMeta Label") as Label
	base_stats_grid = panel.get_node_or_null("BaseStatsGrid GridContainer") as GridContainer
	if base_stats_grid != null:
		base_stats_grid.columns = 3
	passive_skill_button = panel.get_node_or_null("PassiveSkillButton Button") as Button
	active_skill_button = panel.get_node_or_null("ActiveSkillButton Button") as Button
	hero_upgrade_title_label = panel.get_node_or_null("HeroUpgradeTitle Label") as Label
	hero_upgrade_text = panel.get_node_or_null("HeroUpgradeText RichTextLabel") as RichTextLabel
	skill_detail_title = panel.get_node_or_null("SkillDetailTitle Label") as Label


func _connect_skill_buttons() -> void:
	if passive_skill_button != null:
		var passive_callable: Callable = Callable(self, "_on_passive_skill_pressed")
		if not passive_skill_button.pressed.is_connected(passive_callable):
			passive_skill_button.pressed.connect(passive_callable)

	if active_skill_button != null:
		var active_callable: Callable = Callable(self, "_on_active_skill_pressed")
		if not active_skill_button.pressed.is_connected(active_callable):
			active_skill_button.pressed.connect(active_callable)


func _apply_ui_style() -> void:
	if panel != null:
		panel.add_theme_stylebox_override("panel", _create_style(Color(0.055, 0.07, 0.095, 0.96), Color(0.58, 0.70, 0.86, 1.0), 8, 2))

	if title_label != null:
		title_label.text = "单位详情"
		title_label.add_theme_font_size_override("font_size", 22)
		title_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.72, 1.0))

	if unit_name_label != null:
		unit_name_label.add_theme_font_size_override("font_size", 24)
		unit_name_label.add_theme_color_override("font_color", Color(0.98, 0.93, 0.80, 1.0))
		unit_name_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
		unit_name_label.add_theme_constant_override("outline_size", 2)

	if unit_meta_label != null:
		unit_meta_label.add_theme_font_size_override("font_size", 15)
		unit_meta_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.94, 1.0))

	if skill_detail_title != null:
		skill_detail_title.add_theme_font_size_override("font_size", 18)
		skill_detail_title.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62, 1.0))

	if hero_upgrade_title_label != null:
		hero_upgrade_title_label.add_theme_font_size_override("font_size", 18)
		hero_upgrade_title_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.46, 1.0))

	if hero_upgrade_text != null:
		hero_upgrade_text.add_theme_font_size_override("normal_font_size", 15)
		hero_upgrade_text.add_theme_color_override("default_color", Color(0.90, 0.88, 0.76, 1.0))

	if detail_text != null:
		detail_text.add_theme_font_size_override("normal_font_size", 16)
		detail_text.add_theme_color_override("default_color", Color(0.88, 0.92, 0.96, 1.0))

	_apply_skill_button_style(passive_skill_button)
	_apply_skill_button_style(active_skill_button)


func _refresh_panel_content() -> void:
	if selected_unit == null or not is_instance_valid(selected_unit):
		return

	if title_label != null:
		title_label.text = "单位详情"

	if unit_name_label != null:
		unit_name_label.text = selected_unit.display_name

	if unit_meta_label != null:
		unit_meta_label.text = _get_unit_meta_text(selected_unit)

	if portrait_frame != null:
		portrait_frame.color = _get_portrait_color(selected_unit)

	if portrait_placeholder != null:
		portrait_placeholder.text = _get_portrait_placeholder_text(selected_unit)

	_refresh_base_stats(selected_unit)
	_refresh_skill_buttons(selected_unit)
	_refresh_hero_upgrade_section(selected_unit)
	_refresh_skill_detail()


func _refresh_hero_upgrade_section(unit: Unit) -> void:
	var should_show: bool = _is_hero_unit(unit)
	if hero_upgrade_title_label != null:
		hero_upgrade_title_label.visible = should_show
		hero_upgrade_title_label.text = "英雄强化"
	if hero_upgrade_text != null:
		hero_upgrade_text.visible = should_show
		if should_show:
			hero_upgrade_text.text = _get_hero_upgrade_display_text(unit)

	_layout_skill_detail_section(should_show)


func _layout_skill_detail_section(has_hero_upgrade_section: bool) -> void:
	if skill_detail_title == null or detail_text == null:
		return

	if has_hero_upgrade_section:
		skill_detail_title.position = Vector2(18.0, 702.0)
		skill_detail_title.size = Vector2(484.0, 26.0)
		detail_text.position = Vector2(18.0, 734.0)
		detail_text.size = Vector2(484.0, 92.0)
	else:
		skill_detail_title.position = Vector2(18.0, 596.0)
		skill_detail_title.size = Vector2(484.0, 26.0)
		detail_text.position = Vector2(18.0, 628.0)
		detail_text.size = Vector2(484.0, 198.0)


func _refresh_base_stats(unit: Unit) -> void:
	if base_stats_grid == null:
		return

	var stats: Array[Dictionary] = _get_base_stat_items(unit)
	base_stats_grid.columns = 3
	var expected_child_count: int = stats.size()
	while base_stats_grid.get_child_count() > expected_child_count:
		var extra_child: Node = base_stats_grid.get_child(base_stats_grid.get_child_count() - 1)
		base_stats_grid.remove_child(extra_child)
		extra_child.queue_free()

	while base_stats_grid.get_child_count() < expected_child_count:
		base_stats_grid.add_child(_create_stat_label(""))

	for index: int in range(stats.size()):
		var stat: Dictionary = stats[index]
		var stat_label: Label = base_stats_grid.get_child(index) as Label
		if stat_label != null:
			stat_label.text = _format_stat_cell_text(stat)


func _refresh_skill_buttons(unit: Unit) -> void:
	if passive_skill_button != null:
		passive_skill_button.text = _get_passive_skill_display_name(unit)
		passive_skill_button.disabled = unit.passive_id.strip_edges() == ""

	if active_skill_button != null:
		active_skill_button.text = _get_active_skill_display_name(unit)
		active_skill_button.disabled = unit.active_skill_id.strip_edges() == ""


func _refresh_skill_detail() -> void:
	if selected_unit == null or not is_instance_valid(selected_unit):
		return

	if selected_skill_type == SKILL_TYPE_PASSIVE:
		_show_skill_detail("被动技能", _get_passive_skill_display_name(selected_unit), _get_passive_skill_detail_text_for_unit(selected_unit))
	elif selected_skill_type == SKILL_TYPE_ACTIVE:
		_show_skill_detail("主动技能", _get_active_skill_display_name(selected_unit), _get_active_skill_detail_text_for_unit(selected_unit))
	else:
		if skill_detail_title != null:
			skill_detail_title.text = "技能详情"
		if detail_text != null:
			detail_text.text = "点击上方技能名称查看详细效果。"

	_update_skill_button_selected_state()


func _show_skill_detail(skill_type_label: String, skill_name: String, detail: String) -> void:
	if skill_detail_title != null:
		skill_detail_title.text = skill_type_label + "：" + skill_name

	if detail_text != null:
		var safe_detail: String = detail.strip_edges()
		detail_text.text = safe_detail if safe_detail != "" else "-"


func _on_passive_skill_pressed() -> void:
	selected_skill_type = SKILL_TYPE_PASSIVE
	_refresh_skill_detail()


func _on_active_skill_pressed() -> void:
	selected_skill_type = SKILL_TYPE_ACTIVE
	_refresh_skill_detail()


func _update_skill_button_selected_state() -> void:
	_apply_skill_button_style(passive_skill_button, selected_skill_type == SKILL_TYPE_PASSIVE)
	_apply_skill_button_style(active_skill_button, selected_skill_type == SKILL_TYPE_ACTIVE)


func _get_base_stat_items(unit: Unit) -> Array[Dictionary]:
	var stats: Array[Dictionary] = []
	stats.append({"name": "生命", "value": str(unit.hp) + " / " + str(unit.max_hp)})
	stats.append({"name": "护盾", "value": str(unit.shield)})
	stats.append({"name": "攻击", "value": str(unit.attack_damage)})
	stats.append({"name": "防御", "value": str(unit.defense)})
	stats.append({"name": "攻速", "value": _format_attack_speed(unit.attack_interval)})
	stats.append({"name": "范围", "value": _format_float_value(unit.attack_range)})
	stats.append({"name": "魔力", "value": _format_float_value(unit.current_mana) + " / " + str(unit.max_mana)})
	stats.append({"name": "回魔", "value": _format_float_value(unit.mana_regen_per_second) + " / 秒"})
	stats.append({"name": "暴击", "value": _format_percent(unit.crit_chance)})
	stats.append({"name": "暴伤", "value": "x" + _format_float_value(unit.crit_damage_multiplier)})
	stats.append({"name": "技能强度", "value": _format_percent(unit.skill_power)})
	stats.append({"name": "治疗强度", "value": _format_percent(unit.healing_power)})
	stats.append({"name": "护盾强度", "value": _format_percent(unit.shield_power)})
	stats.append({"name": "防御穿透", "value": str(unit.defense_penetration)})
	stats.append({"name": "吸血", "value": _format_percent(unit.life_steal)})
	stats.append({"name": "减伤", "value": _format_percent(unit.damage_reduction)})
	stats.append({"name": "初始魔力", "value": _format_float_value(unit.initial_mana)})
	stats.append({"name": "普攻回魔", "value": _format_float_value(unit.mana_on_attack)})
	stats.append({"name": "受击回魔", "value": _format_float_value(unit.mana_on_hit_taken)})
	stats.append({"name": "状态抗性", "value": _format_percent(unit.status_resistance)})
	stats.append({"name": "闪避", "value": _format_percent(unit.dodge_chance)})
	return stats


func _get_unit_meta_text(unit: Unit) -> String:
	var parts: Array[String] = []
	parts.append(_get_team_display_name(unit.team_id))
	parts.append(_get_role_display_name(unit.role))
	parts.append(_get_rarity_display_name(unit.rarity))
	if _is_hero_unit(unit):
		parts.append("英雄 Lv." + str(_get_hero_level(unit)))
	else:
		parts.append(str(unit.star) + " 星")
	return _join_text(parts, " / ")


func _get_portrait_color(unit: Unit) -> Color:
	if _is_hero_unit(unit):
		return Color(0.48, 0.30, 0.14, 1.0)
	if unit.team_id == 2:
		return Color(0.34, 0.10, 0.12, 1.0)

	match unit.role:
		"tank":
			return Color(0.16, 0.28, 0.42, 1.0)
		"support":
			return Color(0.16, 0.34, 0.26, 1.0)
		_:
			return Color(0.14, 0.22, 0.38, 1.0)


func _get_portrait_placeholder_text(unit: Unit) -> String:
	var display_name: String = unit.display_name.strip_edges()
	if display_name.length() > 0:
		return display_name.substr(0, 1) + "\n立绘占位"

	return "立绘\n占位"


func _get_passive_skill_display_name(unit: Unit) -> String:
	return _extract_skill_name(_get_passive_skill_detail_text_for_unit(unit), unit.passive_id)


func _get_active_skill_display_name(unit: Unit) -> String:
	return _extract_skill_name(_get_active_skill_detail_text_for_unit(unit), unit.active_skill_id)


func _extract_skill_name(detail: String, fallback_id: String) -> String:
	var first_line: String = detail.strip_edges().split("\n", false, 1)[0] if detail.strip_edges() != "" else ""
	var colon_index: int = first_line.find("：")
	if colon_index < 0:
		colon_index = first_line.find(":")

	if colon_index > 0:
		return first_line.substr(0, colon_index).strip_edges()

	if first_line.strip_edges() != "":
		return first_line.strip_edges()

	if fallback_id.strip_edges() != "":
		return fallback_id

	return "-"


func _get_passive_skill_detail_text_for_unit(unit: Unit) -> String:
	if _is_hero_unit(unit):
		return _get_hero_passive_skill_detail_text(unit)

	return _get_passive_skill_detail_text(unit.passive_id, unit.star)


func _get_active_skill_detail_text_for_unit(unit: Unit) -> String:
	if _is_hero_unit(unit):
		return _get_hero_active_skill_detail_text(unit)

	return _get_active_skill_detail_text(unit.active_skill_id, unit.star)


func _get_passive_skill_detail_text(passive_id: String, star: int) -> String:
	if passive_id.strip_edges() == "":
		return ""

	if unit_text_formatter != null and unit_text_formatter.has_method("get_passive_skill_text"):
		var skill_text: String = str(unit_text_formatter.get_passive_skill_text(passive_id, star))
		if skill_text.strip_edges() != "":
			return skill_text

	return passive_id


func _get_active_skill_detail_text(active_skill_id: String, star: int) -> String:
	if active_skill_id.strip_edges() == "":
		return ""

	if unit_text_formatter != null and unit_text_formatter.has_method("get_active_skill_text"):
		var skill_text: String = str(unit_text_formatter.get_active_skill_text(active_skill_id, star))
		if skill_text.strip_edges() != "":
			return skill_text

	return active_skill_id


func _is_hero_unit(unit: Unit) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false

	return bool(unit.get_meta("is_hero", false)) or unit.roster_area == "hero" or unit.unit_type.begins_with("hero_")


func _get_hero_passive_skill_detail_text(unit: Unit) -> String:
	var upgrade_ids: Array[String] = _get_hero_upgrade_ids(unit)
	if unit_text_formatter != null and unit_text_formatter.has_method("get_hero_passive_skill_text"):
		var skill_text: String = str(unit_text_formatter.get_hero_passive_skill_text(unit.passive_id, upgrade_ids))
		if skill_text.strip_edges() != "":
			return skill_text

	return _get_passive_skill_detail_text(unit.passive_id, unit.star)


func _get_hero_active_skill_detail_text(unit: Unit) -> String:
	var upgrade_ids: Array[String] = _get_hero_upgrade_ids(unit)
	var hero_level: int = _get_hero_level(unit)
	if unit_text_formatter != null and unit_text_formatter.has_method("get_hero_active_skill_text"):
		var skill_text: String = str(unit_text_formatter.get_hero_active_skill_text(unit.active_skill_id, hero_level, upgrade_ids))
		if skill_text.strip_edges() != "":
			return skill_text

	return _get_active_skill_detail_text(unit.active_skill_id, unit.star)


func _get_hero_upgrade_display_text(unit: Unit) -> String:
	var lines: Array[String] = _get_hero_upgrade_lines(unit)
	if lines.is_empty():
		return "-"

	return _join_text(lines, "\n")


func _get_hero_upgrade_lines(unit: Unit) -> Array[String]:
	var lines: Array[String] = []
	var upgrade_ids: Array[String] = _get_hero_upgrade_ids(unit)
	for upgrade_id: String in upgrade_ids:
		var upgrade_text: String = _get_hero_upgrade_text(upgrade_id).strip_edges()
		if upgrade_text != "":
			lines.append(upgrade_text)

	var base_stat_counts: Dictionary = _get_hero_base_stat_upgrade_counts(unit)
	for upgrade_id: String in base_stat_counts.keys():
		var count: int = int(base_stat_counts[upgrade_id])
		if count <= 0:
			continue

		lines.append(_get_hero_upgrade_text(upgrade_id) + " x" + str(count))

	return lines


func _get_hero_upgrade_text(upgrade_id: String) -> String:
	if unit_text_formatter != null and unit_text_formatter.has_method("get_hero_upgrade_text"):
		return str(unit_text_formatter.get_hero_upgrade_text(upgrade_id))

	return upgrade_id


func _get_hero_upgrade_ids(unit: Unit) -> Array[String]:
	var result: Array[String] = []
	if unit == null or not unit.has_meta("hero_upgrade_ids"):
		return result

	var upgrade_ids: Variant = unit.get_meta("hero_upgrade_ids")
	if not (upgrade_ids is Array):
		return result

	for upgrade_id_value: Variant in upgrade_ids:
		var upgrade_id: String = str(upgrade_id_value)
		if upgrade_id != "":
			result.append(upgrade_id)

	return result


func _get_hero_base_stat_upgrade_counts(unit: Unit) -> Dictionary:
	if unit == null or not unit.has_meta("hero_base_stat_upgrade_counts"):
		return {}

	var value: Variant = unit.get_meta("hero_base_stat_upgrade_counts")
	if value is Dictionary:
		return (value as Dictionary).duplicate()

	return {}


func _get_hero_level(unit: Unit) -> int:
	if unit != null and unit.has_meta("hero_level"):
		return maxi(1, int(unit.get_meta("hero_level")))

	return maxi(1, unit.star)


func _get_rarity_display_name(rarity: String) -> String:
	if rarity_formatter != null and rarity_formatter.has_method("get_display_name"):
		return str(rarity_formatter.get_display_name(rarity))

	return rarity


func _get_team_display_name(team_id: int) -> String:
	match team_id:
		1:
			return "玩家"
		2:
			return "敌人"
		_:
			return "中立"


func _get_role_display_name(role: String) -> String:
	match role:
		"tank":
			return "承伤"
		"support":
			return "辅助"
		"damage":
			return "输出"
		_:
			return role


func _format_attack_speed(attack_interval: float) -> String:
	if attack_interval <= 0.0:
		return "-"

	return _format_float_value(1.0 / attack_interval) + " / 秒"


func _format_percent(value: float) -> String:
	return "%0.0f%%" % (value * 100.0)


func _format_float_value(value: float) -> String:
	return "%0.1f" % value


func _format_stat_cell_text(stat: Dictionary) -> String:
	var stat_name: String = str(stat.get("name", "")).strip_edges()
	var stat_value: String = str(stat.get("value", "")).strip_edges()
	if stat_name == "":
		return stat_value
	if stat_value == "":
		return stat_name
	return stat_name + " " + stat_value


func _create_stat_label(text_value: String) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(150.0, 24.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 14)
	return label


func _apply_skill_button_style(button: Button, is_selected: bool = false) -> void:
	if button == null:
		return

	var base_color: Color = Color(0.12, 0.20, 0.32, 1.0) if not is_selected else Color(0.22, 0.38, 0.58, 1.0)
	var border_color: Color = Color(0.48, 0.64, 0.82, 1.0) if not is_selected else Color(0.98, 0.82, 0.46, 1.0)
	PIXEL_UI_THEME.apply_button_style(button, base_color, border_color, 2, 16)


func _create_style(bg_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_panel_style(bg_color, border_color, border_width, 8.0)


func _lighten_color(color: Color, amount: float) -> Color:
	return Color(
		minf(color.r + amount, 1.0),
		minf(color.g + amount, 1.0),
		minf(color.b + amount, 1.0),
		color.a
	)


func _darken_color(color: Color, amount: float) -> Color:
	return Color(
		maxf(color.r - amount, 0.0),
		maxf(color.g - amount, 0.0),
		maxf(color.b - amount, 0.0),
		color.a
	)


func _get_clamped_panel_position() -> Vector2:
	if panel == null:
		return Vector2.ZERO

	var viewport_size: Vector2 = panel.get_viewport().get_visible_rect().size
	var panel_size: Vector2 = panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		panel_size = Vector2(520.0, 848.0)

	var position: Vector2 = panel.get_viewport().get_mouse_position() + Vector2(16.0, 12.0)
	position.x = clampf(position.x, 8.0, maxf(8.0, viewport_size.x - panel_size.x - 8.0))
	position.y = clampf(position.y, 8.0, maxf(8.0, viewport_size.y - panel_size.y - 8.0))
	return position


func _join_text(parts: Array[String], separator: String) -> String:
	var joined_text: String = ""

	for index: int in range(parts.size()):
		if index > 0:
			joined_text += separator
		joined_text += parts[index]

	return joined_text
