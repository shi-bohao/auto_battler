class_name HeroSelectionPanelController
extends RefCounted


signal hero_selected(hero_id: String)
signal selection_cancelled()


const UNIT_TEXT_FORMATTER_SCRIPT: Script = preload("res://scripts/unit_text_formatter.gd")
const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")

const PORTRAIT_SIZE: Vector2 = Vector2(90.0, 90.0)
const PORTRAITS_PER_PAGE: int = 3
const PORTRAIT_BG: Color = Color(0.08, 0.12, 0.20, 0.95)
const PORTRAIT_BORDER: Color = Color(0.52, 0.44, 0.30, 1.0)
const PORTRAIT_SELECTED_BORDER: Color = Color(1.0, 0.82, 0.42, 1.0)
const STAT_COLUMNS: int = 4
const UPGRADE_COLUMNS: int = 3
const STAT_CELL_WIDTH: float = 200.0
const UPGRADE_BUTTON_WIDTH: float = 268.0
const UPGRADE_BUTTON_HEIGHT: float = 40.0

var hero_panel: Panel = null
var title_label: Label = null
var detail_scroll: ScrollContainer = null
var detail_content: Control = null
var portrait_frame: ColorRect = null
var portrait_placeholder: Label = null
var portrait_texture_rect: TextureRect = null
var unit_name_label: Label = null
var unit_meta_label: Label = null
var base_stats_grid: GridContainer = null
var passive_skill_button: Button = null
var active_skill_button: Button = null
var hero_upgrade_title: Label = null
var hero_upgrade_grid: GridContainer = null
var placeholder_label: Label = null
var info_popup: Panel = null
var info_popup_text: RichTextLabel = null
var portrait_container: HBoxContainer = null
var left_arrow: Button = null
var right_arrow: Button = null
var return_button: Button = null
var confirm_button: Button = null
var hero_manager: Variant = null
var rarity_formatter: Variant = null
var unit_text_formatter: Variant = UNIT_TEXT_FORMATTER_SCRIPT.new()
var hero_options: Array[Resource] = []
var portrait_buttons: Array[Button] = []
var portrait_name_labels: Array[Label] = []
var upgrade_buttons: Array[Button] = []
var selected_hero_index: int = -1
var selected_skill_type: String = ""
var page_index: int = 0
var is_selection_enabled: bool = false

const SKILL_NONE: String = ""
const SKILL_PASSIVE: String = "PASSIVE"
const SKILL_ACTIVE: String = "ACTIVE"


func setup(hero_panel_value: Panel, hero_manager_value: Variant, rarity_formatter_value: Variant) -> void:
	hero_panel = hero_panel_value
	hero_manager = hero_manager_value
	rarity_formatter = rarity_formatter_value
	_resolve_nodes()
	_apply_styles()
	hide()


func show_selection() -> void:
	if hero_manager == null:
		return

	hero_options = hero_manager.get_available_heroes()
	selected_hero_index = -1
	selected_skill_type = SKILL_NONE
	page_index = 0
	is_selection_enabled = true
	if hero_panel != null:
		hero_panel.visible = true
	_refresh_page()
	_show_placeholder()
	_refresh_confirm_button()


func hide() -> void:
	is_selection_enabled = false
	selected_hero_index = -1
	selected_skill_type = SKILL_NONE
	page_index = 0
	if hero_panel != null:
		hero_panel.visible = false
	_clear_portraits()
	_hide_detail()
	_hide_popup()


func _resolve_nodes() -> void:
	if hero_panel == null:
		return

	title_label = hero_panel.get_node_or_null("Title") as Label
	detail_scroll = hero_panel.get_node_or_null("DetailScroll") as ScrollContainer
	if detail_scroll != null:
		detail_content = detail_scroll.get_node_or_null("DetailContent") as Control
		if detail_content != null:
			detail_content.gui_input.connect(_on_detail_gui_input)
			portrait_frame = detail_content.get_node_or_null("PortraitFrame") as ColorRect
			portrait_placeholder = detail_content.get_node_or_null("PortraitFrame/PortraitPlaceholder") as Label
			portrait_texture_rect = detail_content.get_node_or_null("PortraitFrame/PortraitTexture") as TextureRect
			unit_name_label = detail_content.get_node_or_null("UnitName") as Label
			unit_meta_label = detail_content.get_node_or_null("UnitMeta") as Label
			base_stats_grid = detail_content.get_node_or_null("BaseStatsGrid") as GridContainer
			if base_stats_grid != null:
				base_stats_grid.columns = STAT_COLUMNS
			passive_skill_button = detail_content.get_node_or_null("PassiveSkillButton") as Button
			active_skill_button = detail_content.get_node_or_null("ActiveSkillButton") as Button
			hero_upgrade_title = detail_content.get_node_or_null("HeroUpgradeTitle") as Label
			hero_upgrade_grid = detail_content.get_node_or_null("HeroUpgradeGrid") as GridContainer
			if hero_upgrade_grid != null:
				hero_upgrade_grid.columns = UPGRADE_COLUMNS

	placeholder_label = hero_panel.get_node_or_null("PlaceholderLabel") as Label
	info_popup = hero_panel.get_node_or_null("InfoPopup") as Panel
	if info_popup != null:
		info_popup_text = info_popup.get_node_or_null("InfoPopupText") as RichTextLabel
	portrait_container = hero_panel.get_node_or_null("SelectionRow/PortraitContainer") as HBoxContainer
	left_arrow = hero_panel.get_node_or_null("SelectionRow/LeftArrow") as Button
	right_arrow = hero_panel.get_node_or_null("SelectionRow/RightArrow") as Button
	return_button = hero_panel.get_node_or_null("ButtonRow/ReturnButton") as Button
	confirm_button = hero_panel.get_node_or_null("ButtonRow/ConfirmButton") as Button

	if hero_panel != null:
		hero_panel.gui_input.connect(_on_panel_gui_input)
	if left_arrow != null:
		left_arrow.pressed.connect(_on_page_left)
	if right_arrow != null:
		right_arrow.pressed.connect(_on_page_right)
	if return_button != null:
		return_button.pressed.connect(_on_return_pressed)
	if confirm_button != null:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if passive_skill_button != null:
		passive_skill_button.pressed.connect(_on_passive_skill_pressed)
	if active_skill_button != null:
		active_skill_button.pressed.connect(_on_active_skill_pressed)


func _on_detail_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_hide_popup()


func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_hide_popup()


func _apply_styles() -> void:
	if hero_panel == null:
		return

	hero_panel.add_theme_stylebox_override("panel", _make_panel_bg(Color(0.045, 0.06, 0.09, 0.98), Color(0.78, 0.58, 0.32, 1.0), 2))

	if title_label != null:
		title_label.text = "选择英雄"
		title_label.add_theme_font_size_override("font_size", 28)
		title_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.52, 1.0))
		title_label.add_theme_color_override("font_outline_color", Color(0.015, 0.018, 0.024, 1.0))
		title_label.add_theme_constant_override("outline_size", 2)

	if unit_name_label != null:
		unit_name_label.add_theme_font_size_override("font_size", 24)
		unit_name_label.add_theme_color_override("font_color", Color(0.98, 0.93, 0.80, 1.0))
		unit_name_label.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 1.0))
		unit_name_label.add_theme_constant_override("outline_size", 2)

	if unit_meta_label != null:
		unit_meta_label.add_theme_font_size_override("font_size", 15)
		unit_meta_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.94, 1.0))

	if detail_scroll != null:
		var scroll_style: StyleBoxFlat = StyleBoxFlat.new()
		scroll_style.bg_color = Color(0.04, 0.05, 0.07, 0.94)
		scroll_style.border_color = Color(0.38, 0.50, 0.66, 1.0)
		scroll_style.border_width_left = 1
		scroll_style.border_width_top = 1
		scroll_style.border_width_right = 1
		scroll_style.border_width_bottom = 1
		detail_scroll.add_theme_stylebox_override("panel", scroll_style)

	if placeholder_label != null:
		placeholder_label.text = "请选择一位英雄"
		placeholder_label.add_theme_font_size_override("font_size", 22)
		placeholder_label.add_theme_color_override("font_color", Color(0.44, 0.50, 0.58, 1.0))

	if hero_upgrade_title != null:
		hero_upgrade_title.add_theme_font_size_override("font_size", 18)
		hero_upgrade_title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.46, 1.0))

	if info_popup != null:
		info_popup.add_theme_stylebox_override("panel", _make_sub_panel_style(Color(0.045, 0.055, 0.080, 0.98), Color(0.80, 0.62, 0.36, 1.0)))

	if info_popup_text != null:
		info_popup_text.add_theme_font_size_override("normal_font_size", 15)
		info_popup_text.add_theme_color_override("default_color", Color(0.92, 0.94, 1.0, 1.0))

	_apply_skill_button_style(passive_skill_button, false)
	_apply_skill_button_style(active_skill_button, false)
	_apply_arrow_style(left_arrow, "◀")
	_apply_arrow_style(right_arrow, "▶")
	_apply_bottom_button_style(return_button, "返回", Color(0.22, 0.25, 0.30, 1.0))
	_apply_bottom_button_style(confirm_button, "确认选择", Color(0.16, 0.30, 0.48, 0.96))


func _apply_skill_button_style(button: Button, is_selected: bool) -> void:
	if button == null:
		return
	var base_color: Color = Color(0.12, 0.20, 0.32, 1.0) if not is_selected else Color(0.22, 0.38, 0.58, 1.0)
	var border_color: Color = Color(0.48, 0.64, 0.82, 1.0) if not is_selected else Color(0.98, 0.82, 0.46, 1.0)
	PIXEL_UI_THEME.apply_button_style(button, base_color, border_color, 2, 16)


func _apply_upgrade_button_style(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(UPGRADE_BUTTON_WIDTH, UPGRADE_BUTTON_HEIGHT)
	PIXEL_UI_THEME.apply_button_style(button, Color(0.10, 0.18, 0.28, 1.0), Color(0.48, 0.40, 0.30, 1.0), 2, 14)


func _apply_arrow_style(button: Button, text: String) -> void:
	if button == null:
		return
	button.text = text
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(0.82, 0.72, 0.50, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.60, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.28, 0.30, 0.34, 1.0))
	button.add_theme_stylebox_override("normal", _make_arrow_style(Color(0.08, 0.10, 0.14, 0.90), Color(0.44, 0.36, 0.24, 1.0)))
	button.add_theme_stylebox_override("hover", _make_arrow_style(Color(0.12, 0.14, 0.20, 0.90), Color(0.78, 0.58, 0.32, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_arrow_style(Color(0.06, 0.08, 0.12, 0.90), Color(0.56, 0.42, 0.28, 1.0)))


func _make_arrow_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg_color
	s.border_color = border_color
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	return s


func _apply_bottom_button_style(button: Button, text: String, base_color: Color) -> void:
	if button == null:
		return
	button.text = text
	PIXEL_UI_THEME.apply_button_style(button, base_color, Color(0.78, 0.58, 0.32, 1.0), 2, 18)


# --- Popup ---

func _show_popup(text: String, near_button: Button) -> void:
	if info_popup == null or info_popup_text == null:
		return

	info_popup_text.text = text

	var btn_global: Vector2 = near_button.global_position
	var panel_global: Vector2 = hero_panel.global_position
	var popup_x: float = btn_global.x - panel_global.x + near_button.size.x + 12.0
	var popup_y: float = btn_global.y - panel_global.y

	var popup_width: float = info_popup.size.x
	var panel_width: float = hero_panel.size.x
	if popup_x + popup_width > panel_width - 16.0:
		popup_x = btn_global.x - panel_global.x - popup_width - 12.0

	var popup_height: float = info_popup.size.y
	var panel_height: float = hero_panel.size.y
	if popup_y + popup_height > panel_height - 16.0:
		popup_y = panel_height - popup_height - 16.0
	if popup_y < 8.0:
		popup_y = 8.0

	info_popup.position = Vector2(popup_x, popup_y)
	info_popup.visible = true


func _hide_popup() -> void:
	if info_popup != null:
		info_popup.visible = false
	selected_skill_type = SKILL_NONE
	_update_skill_button_states()


# --- Pagination ---

func _page_count() -> int:
	if hero_options.is_empty():
		return 1
	return hero_options.size()


func _on_page_left() -> void:
	_shift_portrait_window(-1)


func _on_page_right() -> void:
	_shift_portrait_window(1)


func _shift_portrait_window(step: int) -> void:
	if not is_selection_enabled:
		return

	if hero_options.is_empty():
		return

	page_index = wrapi(page_index + step, 0, hero_options.size())
	_hide_popup()
	_refresh_page()
	_refresh_confirm_button()


func _on_return_pressed() -> void:
	_hide_popup()
	selection_cancelled.emit()
	hide()


func _on_confirm_pressed() -> void:
	if not is_selection_enabled:
		return
	if selected_hero_index < 0 or selected_hero_index >= hero_options.size():
		return
	var hero: Resource = hero_options[selected_hero_index]
	var hero_id: String = str(hero.get("hero_id"))
	if hero_id == "":
		return
	hero_selected.emit(hero_id)


func _refresh_page() -> void:
	_clear_portraits()
	_update_nav_controls()

	var visible_count: int = mini(PORTRAITS_PER_PAGE, hero_options.size())

	for slot_index: int in range(visible_count):
		var index: int = wrapi(page_index + slot_index, 0, hero_options.size())
		var hero: Resource = hero_options[index]
		var slot: VBoxContainer = VBoxContainer.new()
		slot.name = "PortraitSlot" + str(index)
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.custom_minimum_size = Vector2(PORTRAIT_SIZE.x, PORTRAIT_SIZE.y + 28.0)

		var btn: Button = Button.new()
		btn.name = "PortraitButton" + str(index)
		btn.custom_minimum_size = PORTRAIT_SIZE
		btn.focus_mode = Control.FOCUS_NONE
		var hero_icon: Texture2D = _get_hero_icon_texture(hero)
		if hero_icon != null:
			btn.icon = hero_icon
			btn.expand_icon = true
			btn.text = ""
		else:
			btn.text = _get_hero_display_name(hero).substr(0, 1)
		btn.add_theme_font_size_override("font_size", 36)
		btn.add_theme_color_override("font_color", Color(0.94, 0.90, 0.78, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.80, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.94, 0.90, 0.78, 1.0))
		btn.pressed.connect(_on_portrait_pressed.bind(index))
		_apply_portrait_style(btn, index == selected_hero_index)
		slot.add_child(btn)
		portrait_buttons.append(btn)

		var lbl: Label = Label.new()
		lbl.name = "PortraitName" + str(index)
		lbl.text = _get_hero_display_name(hero)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.78, 0.82, 0.88, 1.0))
		lbl.custom_minimum_size = Vector2(PORTRAIT_SIZE.x, 24.0)
		slot.add_child(lbl)
		portrait_name_labels.append(lbl)

		portrait_container.add_child(slot)

	_recenter_portrait_row()
	_refresh_selection_display()


func _update_nav_controls() -> void:
	var show_arrows: bool = hero_options.size() > 1
	if left_arrow != null:
		left_arrow.visible = show_arrows
		left_arrow.disabled = not show_arrows
	if right_arrow != null:
		right_arrow.visible = show_arrows
		right_arrow.disabled = not show_arrows


func _recenter_portrait_row() -> void:
	if portrait_container == null or hero_panel == null:
		return
	if portrait_container.get_parent() is Container:
		return
	portrait_container.position.x = (hero_panel.size.x - portrait_container.size.x) / 2.0


func _clear_portraits() -> void:
	if portrait_container == null:
		return
	for child: Node in portrait_container.get_children():
		portrait_container.remove_child(child)
		child.queue_free()
	portrait_buttons.clear()
	portrait_name_labels.clear()


func _apply_portrait_style(button: Button, is_selected: bool) -> void:
	var border_color: Color = PORTRAIT_SELECTED_BORDER if is_selected else PORTRAIT_BORDER
	var border_width: int = 3 if is_selected else 2
	var bg_color: Color = PORTRAIT_BG
	if is_selected:
		bg_color = Color(PORTRAIT_BG.r + 0.06, PORTRAIT_BG.g + 0.06, PORTRAIT_BG.b + 0.10, 1.0)

	button.add_theme_stylebox_override("normal", _make_portrait_style(bg_color, border_color, border_width))
	button.add_theme_stylebox_override("hover", _make_portrait_style(Color(bg_color.r + 0.04, bg_color.g + 0.04, bg_color.b + 0.06, 1.0), PORTRAIT_SELECTED_BORDER, 3))
	button.add_theme_stylebox_override("pressed", _make_portrait_style(Color(bg_color.r - 0.02, bg_color.g - 0.02, bg_color.b + 0.04, 1.0), PORTRAIT_SELECTED_BORDER, 3))


func _make_portrait_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg_color
	s.border_color = border_color
	s.border_width_left = border_width
	s.border_width_top = border_width
	s.border_width_right = border_width
	s.border_width_bottom = border_width
	s.corner_radius_top_left = 0
	s.corner_radius_top_right = 0
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.anti_aliasing = false
	s.set_content_margin(SIDE_LEFT, 4.0)
	s.set_content_margin(SIDE_TOP, 4.0)
	s.set_content_margin(SIDE_RIGHT, 4.0)
	s.set_content_margin(SIDE_BOTTOM, 4.0)
	return s


# --- Portrait selection ---

func _on_portrait_pressed(hero_index: int) -> void:
	if not is_selection_enabled:
		return
	if hero_index < 0 or hero_index >= hero_options.size():
		return
	selected_hero_index = hero_index
	selected_skill_type = SKILL_NONE
	_hide_popup()
	_refresh_portrait_styles()
	_refresh_hero_detail(hero_options[hero_index])
	_refresh_confirm_button()


func _refresh_portrait_styles() -> void:
	for index: int in range(portrait_buttons.size()):
		var global_index: int = wrapi(page_index + index, 0, hero_options.size())
		_apply_portrait_style(portrait_buttons[index], global_index == selected_hero_index)


func _refresh_selection_display() -> void:
	if selected_hero_index >= 0 and selected_hero_index < hero_options.size():
		_refresh_hero_detail(hero_options[selected_hero_index])
	else:
		_show_placeholder()


func _refresh_confirm_button() -> void:
	if confirm_button == null:
		return
	var has_selection: bool = is_selection_enabled and selected_hero_index >= 0 and selected_hero_index < hero_options.size()
	confirm_button.disabled = not has_selection
	confirm_button.text = "确认选择" if has_selection else "先选择英雄"
	if has_selection:
		confirm_button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.80, 1.0))
	else:
		confirm_button.add_theme_color_override("font_color", Color(0.68, 0.68, 0.68, 1.0))


# --- Detail panel ---

func _refresh_hero_detail(hero: Resource) -> void:
	_show_detail_panel()
	_hide_popup()

	var unit_data: Resource = _get_hero_unit_data(hero)

	if portrait_frame != null:
		portrait_frame.color = _get_portrait_frame_color(hero)

	var portrait_texture: Texture2D = _get_hero_portrait_texture(hero)
	if portrait_texture_rect != null:
		portrait_texture_rect.texture = portrait_texture
		portrait_texture_rect.visible = portrait_texture != null

	if portrait_placeholder != null:
		portrait_placeholder.visible = portrait_texture == null
		portrait_placeholder.text = _get_hero_display_name(hero).substr(0, 1) + "\n立绘占位"

	if unit_name_label != null:
		unit_name_label.text = _get_hero_display_name(hero)

	if unit_meta_label != null:
		unit_meta_label.text = _get_meta_line(hero)

	_refresh_base_stats(unit_data)
	_refresh_skill_buttons(hero)
	_refresh_hero_upgrades(hero)


func _show_detail_panel() -> void:
	if detail_scroll != null:
		detail_scroll.visible = true
	if placeholder_label != null:
		placeholder_label.visible = false


func _show_placeholder() -> void:
	if detail_scroll != null:
		detail_scroll.visible = false
	if placeholder_label != null:
		placeholder_label.visible = true


func _hide_detail() -> void:
	if detail_scroll != null:
		detail_scroll.visible = false
	if placeholder_label != null:
		placeholder_label.visible = true


func _get_portrait_frame_color(hero: Resource) -> Color:
	return Color(0.48, 0.30, 0.14, 1.0)


func _get_meta_line(hero: Resource) -> String:
	var parts: Array[String] = ["英雄"]
	parts.append(_rarity_name("MYTHIC"))
	var tagline: String = ""
	if hero.has_method("get_tagline"):
		tagline = str(hero.get_tagline())
	if tagline != "":
		parts.append(tagline)
	return _join_str(parts, " / ")


func _refresh_base_stats(unit_data: Resource) -> void:
	if base_stats_grid == null:
		return

	var stats: Array[Dictionary] = _get_stat_items(unit_data)
	var expected_count: int = stats.size()
	while base_stats_grid.get_child_count() > expected_count:
		var extra: Node = base_stats_grid.get_child(base_stats_grid.get_child_count() - 1)
		base_stats_grid.remove_child(extra)
		extra.queue_free()
	while base_stats_grid.get_child_count() < expected_count:
		base_stats_grid.add_child(_create_stat_label(""))

	for index: int in range(stats.size()):
		var stat_label: Label = base_stats_grid.get_child(index) as Label
		if stat_label != null:
			stat_label.text = _format_stat_cell(stats[index])


func _get_stat_items(unit_data: Resource) -> Array[Dictionary]:
	var stats: Array[Dictionary] = []
	if unit_data == null:
		return stats

	stats.append({"name": "生命", "value": str(int(unit_data.get("max_hp")))})
	stats.append({"name": "攻击", "value": str(int(unit_data.get("attack_damage")))})
	stats.append({"name": "防御", "value": str(int(unit_data.get("defense")))})
	stats.append({"name": "攻速", "value": _f1(float(unit_data.get("attack_interval"))) + "秒"})
	stats.append({"name": "范围", "value": _f1(float(unit_data.get("attack_range")))})
	stats.append({"name": "移速", "value": _f1(float(unit_data.get("move_speed")))})
	stats.append({"name": "魔力", "value": str(int(unit_data.get("max_mana")))})
	stats.append({"name": "回魔", "value": _f1(float(unit_data.get("mana_regen_per_second"))) + "/秒"})
	stats.append({"name": "初始魔力", "value": _f1(float(unit_data.get("initial_mana")))})
	stats.append({"name": "暴击", "value": _pct(float(unit_data.get("crit_chance")))})
	stats.append({"name": "暴伤", "value": "x" + _f1(float(unit_data.get("crit_damage_multiplier")))})
	stats.append({"name": "技能强度", "value": _pct(float(unit_data.get("skill_power")))})
	stats.append({"name": "治疗强度", "value": _pct(float(unit_data.get("healing_power")))})
	stats.append({"name": "护盾强度", "value": _pct(float(unit_data.get("shield_power")))})
	stats.append({"name": "防御穿透", "value": str(int(unit_data.get("defense_penetration")))})
	stats.append({"name": "吸血", "value": _pct(float(unit_data.get("life_steal")))})
	stats.append({"name": "减伤", "value": _pct(float(unit_data.get("damage_reduction")))})
	stats.append({"name": "闪避", "value": _pct(float(unit_data.get("dodge_chance")))})
	stats.append({"name": "普攻回魔", "value": _f1(float(unit_data.get("mana_on_attack")))})
	stats.append({"name": "受击回魔", "value": _f1(float(unit_data.get("mana_on_hit_taken")))})
	stats.append({"name": "状态抗性", "value": _pct(float(unit_data.get("status_resistance")))})
	return stats


func _create_stat_label(text_value: String) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(STAT_CELL_WIDTH, 22.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.90, 0.94, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 14)
	return label


func _format_stat_cell(stat: Dictionary) -> String:
	var stat_name: String = str(stat.get("name", "")).strip_edges()
	var stat_value: String = str(stat.get("value", "")).strip_edges()
	if stat_name == "":
		return stat_value
	if stat_value == "":
		return stat_name
	return stat_name + " " + stat_value


func _refresh_skill_buttons(hero: Resource) -> void:
	var unit_data: Resource = _get_hero_unit_data(hero)
	var passive_id: String = ""
	var active_id: String = ""
	if unit_data != null:
		passive_id = str(unit_data.get("passive_id"))
		active_id = str(unit_data.get("active_skill_id"))

	if passive_skill_button != null:
		passive_skill_button.text = _extract_skill_name(_get_hero_passive_text(hero), passive_id)
		passive_skill_button.disabled = false

	if active_skill_button != null:
		active_skill_button.text = _extract_skill_name(_get_hero_active_text(hero), active_id)
		active_skill_button.disabled = false


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


func _refresh_hero_upgrades(hero: Resource) -> void:
	if hero_upgrade_grid == null:
		return

	for child: Node in hero_upgrade_grid.get_children():
		hero_upgrade_grid.remove_child(child)
		child.queue_free()
	upgrade_buttons.clear()

	var upgrades: Array[Resource] = _get_upgrade_list(hero)
	if hero_upgrade_title != null:
		hero_upgrade_title.visible = not upgrades.is_empty()

	for index: int in range(upgrades.size()):
		var upgrade: Resource = upgrades[index]
		var btn: Button = Button.new()
		btn.name = "UpgradeButton" + str(index)
		btn.text = "Lv." + str(int(upgrade.get("required_level"))) + " " + str(upgrade.get("upgrade_name"))
		btn.focus_mode = Control.FOCUS_NONE
		_apply_upgrade_button_style(btn)
		btn.pressed.connect(_on_upgrade_button_pressed.bind(upgrade, btn))
		hero_upgrade_grid.add_child(btn)
		upgrade_buttons.append(btn)


func _get_upgrade_list(hero: Resource) -> Array[Resource]:
	var result: Array[Resource] = []
	var upgrade_pool_value: Variant = hero.get("upgrade_pool")
	if not (upgrade_pool_value is Array):
		return result

	for upgrade_value: Variant in (upgrade_pool_value as Array):
		var upgrade: Resource = upgrade_value as Resource
		if upgrade != null:
			result.append(upgrade)

	return result


func _on_upgrade_button_pressed(upgrade: Resource, button: Button) -> void:
	var name: String = str(upgrade.get("upgrade_name"))
	var description: String = str(upgrade.get("description"))
	var text: String = "[b]" + name + "[/b]\n\n" + description
	_show_popup(text, button)


func _on_passive_skill_pressed() -> void:
	if selected_skill_type == SKILL_PASSIVE:
		_hide_popup()
	else:
		selected_skill_type = SKILL_PASSIVE
		if selected_hero_index >= 0 and selected_hero_index < hero_options.size():
			var hero: Resource = hero_options[selected_hero_index]
			_show_popup(_get_hero_passive_text(hero), passive_skill_button)


func _on_active_skill_pressed() -> void:
	if selected_skill_type == SKILL_ACTIVE:
		_hide_popup()
	else:
		selected_skill_type = SKILL_ACTIVE
		if selected_hero_index >= 0 and selected_hero_index < hero_options.size():
			var hero: Resource = hero_options[selected_hero_index]
			_show_popup(_get_hero_active_text(hero), active_skill_button)


func _update_skill_button_states() -> void:
	_apply_skill_button_style(passive_skill_button, selected_skill_type == SKILL_PASSIVE)
	_apply_skill_button_style(active_skill_button, selected_skill_type == SKILL_ACTIVE)


# --- Helpers ---

func _get_hero_display_name(hero: Resource) -> String:
	if hero == null:
		return "英雄"
	if hero.has_method("get_display_name"):
		return str(hero.get_display_name())
	return str(hero.get("hero_name"))


func _get_hero_unit_data(hero: Resource) -> Resource:
	if hero == null:
		return null
	return hero.get("hero_unit_data") as Resource


func _get_hero_portrait_texture(hero: Resource) -> Texture2D:
	var unit_data: Resource = _get_hero_unit_data(hero)
	if unit_data == null:
		return null

	var portrait: Variant = unit_data.get("portrait_texture")
	if portrait is Texture2D:
		return portrait

	var icon: Variant = unit_data.get("icon_texture")
	if icon is Texture2D:
		return icon

	return null


func _get_hero_icon_texture(hero: Resource) -> Texture2D:
	var unit_data: Resource = _get_hero_unit_data(hero)
	if unit_data == null:
		return null

	var icon: Variant = unit_data.get("icon_texture")
	if icon is Texture2D:
		return icon

	var board_sprite: Variant = unit_data.get("board_sprite")
	if board_sprite is Texture2D:
		return board_sprite

	return null


func _get_hero_passive_text(hero: Resource) -> String:
	var unit_data: Resource = _get_hero_unit_data(hero)
	if unit_data == null:
		return ""
	var passive_id: String = str(unit_data.get("passive_id"))
	if unit_text_formatter != null and unit_text_formatter.has_method("get_passive_skill_text"):
		return str(unit_text_formatter.get_passive_skill_text(passive_id, 1))
	return passive_id


func _get_hero_active_text(hero: Resource) -> String:
	var unit_data: Resource = _get_hero_unit_data(hero)
	if unit_data == null:
		return ""
	var active_skill_id: String = str(unit_data.get("active_skill_id"))
	if unit_text_formatter != null and unit_text_formatter.has_method("get_active_skill_text"):
		return str(unit_text_formatter.get_active_skill_text(active_skill_id, 1))
	return active_skill_id


func _rarity_name(rarity: String) -> String:
	if rarity_formatter != null and rarity_formatter.has_method("get_display_name"):
		return str(rarity_formatter.get_display_name(rarity))
	return rarity


func _f1(value: float) -> String:
	return "%.1f" % value


func _pct(value: float) -> String:
	return "%.0f%%" % (value * 100.0)


func _join_str(parts: Array[String], sep: String) -> String:
	var s: String = ""
	for i: int in range(parts.size()):
		if i > 0:
			s += sep
		s += parts[i]
	return s


func _join_lines(lines: Array[String]) -> String:
	var t: String = ""
	for i: int in range(lines.size()):
		if i > 0:
			t += "\n"
		t += lines[i]
	return t


func _make_panel_bg(bg: Color, border: Color, w: int) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = w
	s.border_width_top = w
	s.border_width_right = w
	s.border_width_bottom = w
	s.corner_radius_top_left = 0
	s.corner_radius_top_right = 0
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.anti_aliasing = false
	s.set_content_margin(SIDE_LEFT, 8.0)
	s.set_content_margin(SIDE_TOP, 8.0)
	s.set_content_margin(SIDE_RIGHT, 8.0)
	s.set_content_margin(SIDE_BOTTOM, 8.0)
	return s


func _make_sub_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 0
	s.corner_radius_top_right = 0
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.anti_aliasing = false
	s.set_content_margin(SIDE_LEFT, 12.0)
	s.set_content_margin(SIDE_TOP, 12.0)
	s.set_content_margin(SIDE_RIGHT, 12.0)
	s.set_content_margin(SIDE_BOTTOM, 12.0)
	return s
