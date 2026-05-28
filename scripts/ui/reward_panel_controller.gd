class_name RewardPanelController
extends RefCounted


const DEBUG_LOG_SCRIPT: Script = preload("res://scripts/debug_log.gd")

signal reward_applied(reward: Dictionary)
signal hero_upgrade_selected(upgrade: Dictionary)


const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")


var reward_panel: Panel = null
var reward_buttons: Array[Button] = []
var reward_manager: RewardManager = null
var roster_manager: Variant = null
var relic_manager: RelicManager = null
var rarity_formatter: Variant = null
var hover_detail_panel: Panel = null
var hover_detail_text: RichTextLabel = null
var unit_text_formatter: Variant = UNIT_TEXT_FORMATTER_SCRIPT.new()
var reward_options: Array[Dictionary] = []
var is_selection_enabled: bool = false
var selection_mode: String = "reward"


func setup(
	reward_panel_value: Panel,
	reward_buttons_value: Array[Button],
	reward_manager_value: RewardManager,
	roster_manager_value: Variant,
	relic_manager_value: RelicManager,
	rarity_formatter_value: Variant
) -> void:
	reward_panel = reward_panel_value
	reward_buttons = reward_buttons_value
	reward_manager = reward_manager_value
	roster_manager = roster_manager_value
	relic_manager = relic_manager_value
	rarity_formatter = rarity_formatter_value

	for index: int in range(reward_buttons.size()):
		reward_buttons[index].pressed.connect(_on_reward_button_pressed.bind(index))
		reward_buttons[index].mouse_entered.connect(_on_reward_button_hovered.bind(index))
		reward_buttons[index].mouse_exited.connect(_hide_hover_detail)
		reward_buttons[index].focus_entered.connect(_on_reward_button_hovered.bind(index))
		reward_buttons[index].focus_exited.connect(_hide_hover_detail)

	_resolve_hover_detail_nodes()
	_apply_hover_detail_style()
	refresh_reward_buttons()
	hide_reward_panel()


func show_reward_panel(encounter_type: String) -> void:
	if reward_manager == null:
		return

	reward_options = reward_manager.roll_reward_options(3, encounter_type)
	selection_mode = "reward"
	is_selection_enabled = true
	if reward_panel != null:
		reward_panel.visible = true
		_set_title_text("选择奖励")
	refresh_reward_buttons()


func show_hero_upgrade_panel(upgrade_options: Array[Dictionary]) -> void:
	reward_options = upgrade_options.duplicate(true)
	selection_mode = "hero_upgrade"
	is_selection_enabled = true
	if reward_panel != null:
		reward_panel.visible = true
		_set_title_text("选择英雄强化")
	refresh_reward_buttons()


func show_custom_options(options: Array[Dictionary]) -> void:
	reward_options = options.duplicate(true)
	selection_mode = "reward"
	is_selection_enabled = true
	if reward_panel != null:
		reward_panel.visible = true
		reward_panel.z_index = 50
		_set_title_text("选择奖励")
	refresh_reward_buttons()


func hide_reward_panel() -> void:
	is_selection_enabled = false
	if reward_panel != null:
		reward_panel.visible = false
	_hide_hover_detail()
	_set_title_text("选择奖励")
	selection_mode = "reward"


func refresh_reward_buttons() -> void:
	for index: int in range(reward_buttons.size()):
		if index < reward_options.size():
			var reward: Dictionary = reward_options[index]
			reward_buttons[index].text = _build_reward_button_text(reward)
			reward_buttons[index].tooltip_text = ""
			reward_buttons[index].visible = true
			_apply_reward_button_style(reward_buttons[index], reward)
		else:
			reward_buttons[index].visible = false


func _on_reward_button_pressed(reward_index: int) -> void:
	if not is_selection_enabled:
		return

	if reward_index < 0 or reward_index >= reward_options.size():
		return

	var reward: Dictionary = reward_options[reward_index]
	_hide_hover_detail()
	DEBUG_LOG_SCRIPT.info("Selected reward: " + str(reward["name"]))
	if selection_mode == "hero_upgrade":
		hero_upgrade_selected.emit(reward)
		return

	if reward_manager != null:
		reward_manager.apply_reward(reward)
	reward_applied.emit(reward)


func _build_reward_button_text(reward: Dictionary) -> String:
	var rarity_text: String = _get_rarity_display_name(_get_reward_rarity(reward))
	var parts: Array[String] = [
		str(reward["name"]) + "  [" + rarity_text + "]",
		str(reward["description"]),
	]
	var upgrade_hint: String = _get_reward_unit_upgrade_hint(reward)
	if upgrade_hint != "":
		parts.append(upgrade_hint)

	return _join_text(parts, "\n")


func _build_reward_button_tooltip(reward: Dictionary) -> String:
	var parts: Array[String] = [str(reward["name"])]
	var description: String = str(reward["description"])
	if description.strip_edges() != "":
		parts.append(description)

	var upgrade_hint: String = _get_reward_unit_upgrade_hint(reward)
	if upgrade_hint != "":
		parts.append(upgrade_hint)

	return _join_text(parts, "\n")


func _build_reward_detail_text(reward: Dictionary) -> String:
	var rarity_text: String = _get_rarity_display_name(_get_reward_rarity(reward))
	var parts: Array[String] = [
		"[b]" + str(reward.get("name", "奖励")) + "[/b]  [" + rarity_text + "]",
	]

	var description: String = str(reward.get("description", ""))
	if description.strip_edges() != "":
		parts.append(description)

	var upgrade_hint: String = _get_reward_unit_upgrade_hint(reward)
	if upgrade_hint != "":
		parts.append(upgrade_hint)

	var skill_info: String = _get_reward_unit_skill_info(reward)
	if skill_info != "":
		parts.append("")
		parts.append("[b]技能详情[/b]")
		parts.append(skill_info)

	if str(reward.get("type", "")) == "HERO_UPGRADE":
		parts.append(_build_hero_upgrade_detail_text(reward))

	return _join_text(parts, "\n")


func _build_hero_upgrade_detail_text(reward: Dictionary) -> String:
	var parts: Array[String] = []
	var effect_type: String = str(reward.get("effect_type", ""))
	var effect_key: String = str(reward.get("effect_key", ""))
	if effect_type != "":
		parts.append("")
		parts.append("[b]强化类型[/b] " + effect_type)
	if effect_key != "":
		parts.append("[b]效果键[/b] " + effect_key)
	if reward.has("required_level"):
		parts.append("[b]需求等级[/b] Lv." + str(int(reward.get("required_level", 1))))

	return _join_text(parts, "\n")


func _get_reward_unit_upgrade_hint(reward: Dictionary) -> String:
	if str(reward.get("type", "")) != "UNIT":
		return ""
	if roster_manager == null:
		return ""

	var unit_id: String = str(reward.get("unit_id", ""))
	if unit_id == "":
		if roster_manager.has_method("has_any_unit_upgrade_candidate") and roster_manager.has_any_unit_upgrade_candidate():
			return "提示：随机单位可能触发升星"
		return ""

	if not roster_manager.has_method("get_unit_upgrade_hint"):
		return ""

	return str(roster_manager.get_unit_upgrade_hint(unit_id, 1))


func _get_reward_unit_skill_info(reward: Dictionary) -> String:
	if str(reward.get("type", "")) != "UNIT":
		return ""

	var unit_id: String = str(reward.get("unit_id", ""))
	if unit_id == "":
		return "技能：随机单位将在获得后确定。"

	if roster_manager == null or not roster_manager.has_method("get_unit_data_by_id"):
		return ""

	var unit_data: Resource = roster_manager.get_unit_data_by_id(unit_id) as Resource
	if unit_data == null:
		return ""

	var star: int = int(unit_data.get("star")) if unit_data.get("star") != null else 1
	var passive_text: String = ""
	var active_text: String = ""
	if unit_text_formatter != null:
		if unit_text_formatter.has_method("get_passive_skill_text"):
			passive_text = str(unit_text_formatter.get_passive_skill_text(str(unit_data.get("passive_id")), star))
		if unit_text_formatter.has_method("get_active_skill_text"):
			active_text = str(unit_text_formatter.get_active_skill_text(str(unit_data.get("active_skill_id")), star))

	var parts: Array[String] = []
	if passive_text.strip_edges() != "":
		parts.append("被动：" + passive_text)
	if active_text.strip_edges() != "":
		parts.append("主动：" + active_text)

	return _join_text(parts, "\n")


func _on_reward_button_hovered(reward_index: int) -> void:
	if not is_selection_enabled:
		return

	if reward_index < 0 or reward_index >= reward_options.size():
		_hide_hover_detail()
		return

	_show_hover_detail(_build_reward_detail_text(reward_options[reward_index]))


func _show_hover_detail(text: String) -> void:
	if hover_detail_panel == null or hover_detail_text == null:
		return

	if text.strip_edges() == "":
		_hide_hover_detail()
		return

	hover_detail_text.text = text
	hover_detail_panel.visible = true


func _hide_hover_detail() -> void:
	if hover_detail_panel != null:
		hover_detail_panel.visible = false


func _resolve_hover_detail_nodes() -> void:
	if reward_panel == null:
		return

	hover_detail_panel = reward_panel.get_node_or_null("HoverDetailPanel Panel") as Panel
	if hover_detail_panel != null:
		hover_detail_text = hover_detail_panel.get_node_or_null("HoverDetailText RichTextLabel") as RichTextLabel


func _apply_hover_detail_style() -> void:
	if hover_detail_panel != null:
		hover_detail_panel.add_theme_stylebox_override("panel", _create_reward_button_style(Color(0.045, 0.055, 0.080, 0.98), Color(0.80, 0.62, 0.36, 1.0), 2))
	if hover_detail_text != null:
		hover_detail_text.add_theme_color_override("default_color", Color(0.92, 0.94, 1.0, 1.0))


func _apply_reward_button_style(button: Button, reward: Dictionary) -> void:
	var rarity: String = _get_reward_rarity(reward)
	var base_color: Color = _get_rarity_color(rarity)
	var border_color: Color = _darken_color(base_color, 0.25)

	button.add_theme_stylebox_override("normal", _create_reward_button_style(base_color, border_color, 2))
	button.add_theme_stylebox_override("hover", _create_reward_button_style(_lighten_color(base_color, 0.08), border_color, 2))
	button.add_theme_stylebox_override("pressed", _create_reward_button_style(_darken_color(base_color, 0.08), border_color, 2))
	button.add_theme_stylebox_override("focus", _create_reward_button_style(_lighten_color(base_color, 0.12), Color(1.0, 1.0, 1.0, 0.75), 3))
	var text_color: Color = _get_text_color(base_color)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)


func _create_reward_button_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_button_style(bg_color, border_color, border_width, 10.0)


func _get_reward_rarity(reward: Dictionary) -> String:
	if reward.has("rarity") and str(reward["rarity"]).strip_edges() != "":
		return str(reward["rarity"])

	if reward.has("relic_data"):
		var relic_data: Resource = reward["relic_data"] as Resource
		if relic_data != null and relic_manager != null:
			return relic_manager.get_relic_rarity(relic_data)

	return "COMMON"


func _get_rarity_display_name(rarity: String) -> String:
	if rarity_formatter != null and rarity_formatter.has_method("get_display_name"):
		return str(rarity_formatter.get_display_name(rarity))

	return rarity


func _get_rarity_color(rarity: String) -> Color:
	if rarity_formatter != null and rarity_formatter.has_method("get_color"):
		return rarity_formatter.get_color(rarity)

	return Color(0.78, 0.80, 0.82, 1.0)


func _get_text_color(bg_color: Color) -> Color:
	if rarity_formatter != null and rarity_formatter.has_method("get_text_color"):
		return rarity_formatter.get_text_color(bg_color)

	return Color(1.0, 1.0, 1.0, 1.0)


func _lighten_color(color: Color, amount: float) -> Color:
	if rarity_formatter != null and rarity_formatter.has_method("lighten_color"):
		return rarity_formatter.lighten_color(color, amount)

	return color


func _darken_color(color: Color, amount: float) -> Color:
	if rarity_formatter != null and rarity_formatter.has_method("darken_color"):
		return rarity_formatter.darken_color(color, amount)

	return color


func _join_text(parts: Array[String], separator: String) -> String:
	var joined_text: String = ""

	for index: int in range(parts.size()):
		if index > 0:
			joined_text += separator
		joined_text += parts[index]

	return joined_text


func _set_title_text(text: String) -> void:
	if reward_panel == null:
		return

	var title_label: Label = reward_panel.get_node_or_null("RewardTitle Label") as Label
	if title_label != null:
		title_label.text = text
