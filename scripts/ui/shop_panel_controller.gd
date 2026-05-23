class_name ShopPanelController
extends RefCounted

const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")


signal buy_requested(shop_index: int)
signal refresh_requested()
signal relic_detail_requested(shop_item: Dictionary)


var shop_panel: Panel = null
var shop_title_label: Label = null
var shop_gold_label: Label = null
var refresh_shop_button: Button = null
var shop_close_button: Button = null
var item_labels: Array[Label] = []
var buy_buttons: Array[Button] = []
var item_backgrounds: Array[Panel] = []
var shop_manager: ShopManager = null
var roster_manager: Variant = null
var relic_manager: RelicManager = null
var rarity_formatter: Variant = null


func setup(
	shop_panel_value: Panel,
	shop_title_label_value: Label,
	shop_gold_label_value: Label,
	refresh_shop_button_value: Button,
	shop_close_button_value: Button,
	item_labels_value: Array[Label],
	buy_buttons_value: Array[Button],
	shop_manager_value: ShopManager,
	roster_manager_value: Variant,
	relic_manager_value: RelicManager,
	rarity_formatter_value: Variant
) -> void:
	shop_panel = shop_panel_value
	shop_title_label = shop_title_label_value
	shop_gold_label = shop_gold_label_value
	refresh_shop_button = refresh_shop_button_value
	shop_close_button = shop_close_button_value
	item_labels = item_labels_value
	buy_buttons = buy_buttons_value
	shop_manager = shop_manager_value
	roster_manager = roster_manager_value
	relic_manager = relic_manager_value
	rarity_formatter = rarity_formatter_value

	_setup_buy_buttons()
	_setup_item_labels()
	_setup_item_backgrounds()
	_apply_static_styles()


func refresh_shop_panel(is_prepare: bool) -> void:
	if shop_manager == null:
		return

	var shop_items: Array[Dictionary] = shop_manager.get_shop_items()
	if refresh_shop_button != null:
		refresh_shop_button.text = "刷新 - " + str(shop_manager.get_refresh_cost()) + " 金币"
		refresh_shop_button.disabled = not is_prepare

	for index: int in range(item_labels.size()):
		if index < shop_items.size() and not shop_items[index].is_empty():
			var shop_item: Dictionary = shop_items[index]
			var is_sold: bool = bool(shop_item.get("is_sold", false))
			var item_type: String = str(shop_item.get("type", "UNIT"))
			var rarity: String = str(shop_item.get("rarity", "COMMON"))
			var type_text: String = _get_item_type_text(shop_item, item_type)
			item_labels[index].clip_text = true
			item_labels[index].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item_labels[index].text = _build_item_label_text(shop_item, type_text, rarity)
			item_labels[index].tooltip_text = _build_item_tooltip(shop_item, item_type)
			item_labels[index].mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if item_type == "RELIC" else Control.CURSOR_ARROW
			item_labels[index].visible = true
			buy_buttons[index].visible = true
			var relic_data: Resource = shop_item.get("relic_data", null) as Resource
			var is_relic_owned: bool = item_type == "RELIC" and relic_manager != null and relic_manager.has_relic(relic_data)
			var cannot_add_unit: bool = item_type == "UNIT" and roster_manager != null and not roster_manager.can_add_unit()
			var is_empty_item: bool = item_type == "EMPTY"
			buy_buttons[index].disabled = not is_prepare or is_sold or cannot_add_unit or is_relic_owned or is_empty_item
			if is_sold:
				buy_buttons[index].text = "-" if is_empty_item else "已售"
			elif is_relic_owned:
				buy_buttons[index].text = "已拥有"
			elif cannot_add_unit:
				buy_buttons[index].text = "已满"
			elif bool(shop_item.get("is_unlock_offer", false)):
				buy_buttons[index].text = "解锁"
			elif _get_unit_upgrade_target_star(shop_item) > 0:
				buy_buttons[index].text = "升星"
			else:
				buy_buttons[index].text = "购买"
			_apply_item_style(_get_item_background(index), item_labels[index], buy_buttons[index], shop_item, item_type, rarity, is_sold)
		else:
			var item_background: Panel = _get_item_background(index)
			if item_background != null:
				item_background.visible = false
			item_labels[index].visible = false
			buy_buttons[index].visible = false


func _setup_buy_buttons() -> void:
	for index: int in range(buy_buttons.size()):
		buy_buttons[index].pressed.connect(_on_buy_button_pressed.bind(index))

	if refresh_shop_button != null:
		refresh_shop_button.pressed.connect(_on_refresh_button_pressed)


func _setup_item_labels() -> void:
	for index: int in range(item_labels.size()):
		item_labels[index].mouse_filter = Control.MOUSE_FILTER_STOP
		item_labels[index].gui_input.connect(_on_item_gui_input.bind(index))


func _setup_item_backgrounds() -> void:
	item_backgrounds.clear()
	if shop_panel == null:
		return

	for index: int in range(item_labels.size()):
		var label: Label = item_labels[index]
		if label == null:
			continue

		var background: Panel = Panel.new()
		background.name = "ShopItemBackground" + str(index + 1)
		background.mouse_filter = Control.MOUSE_FILTER_STOP
		background.position = label.position
		background.size = label.size
		background.visible = false
		background.gui_input.connect(_on_item_gui_input.bind(index))
		shop_panel.add_child(background)
		shop_panel.move_child(background, label.get_index())
		item_backgrounds.append(background)
		label.position += Vector2(12.0, 0.0)
		label.size = Vector2(maxf(label.size.x - 24.0, 1.0), label.size.y)


func _on_buy_button_pressed(shop_index: int) -> void:
	buy_requested.emit(shop_index)


func _on_refresh_button_pressed() -> void:
	refresh_requested.emit()


func _on_item_gui_input(event: InputEvent, shop_index: int) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_button.pressed:
		return

	if mouse_button.button_index != MOUSE_BUTTON_LEFT and mouse_button.button_index != MOUSE_BUTTON_RIGHT:
		return

	var shop_item: Dictionary = shop_manager.get_shop_item(shop_index)
	if shop_item.is_empty():
		return

	if str(shop_item.get("type", "UNIT")) != "RELIC":
		return

	relic_detail_requested.emit(shop_item)
	if shop_panel != null:
		shop_panel.get_viewport().set_input_as_handled()


func _get_item_background(index: int) -> Panel:
	if index < 0 or index >= item_backgrounds.size():
		return null

	return item_backgrounds[index]


func _get_item_type_text(shop_item: Dictionary, item_type: String) -> String:
	if item_type == "RELIC":
		return "遗物"
	if item_type == "EMPTY":
		return str(shop_item.get("category", ""))
	if bool(shop_item.get("is_unlock_offer", false)):
		return "新单位解锁"

	return "已解锁单位"


func _build_item_label_text(shop_item: Dictionary, type_text: String, rarity: String) -> String:
	var name: String = str(shop_item.get("name", "物品"))
	var price: int = int(shop_item.get("price", 0))
	var description: String = str(shop_item.get("description", ""))
	if str(shop_item.get("type", "")) == "EMPTY":
		var empty_parts: Array[String] = [name]
		if type_text.strip_edges() != "":
			empty_parts.append(type_text)
		if description.strip_edges() != "":
			empty_parts.append(description)
		return _join_text(empty_parts, "\n")

	var rarity_text: String = _get_rarity_display_name(rarity)
	var item_line: String = type_text + " - " + rarity_text + " - " + str(price) + " 金币"
	var upgrade_target_star: int = _get_unit_upgrade_target_star(shop_item)
	if upgrade_target_star > 0:
		name += "  【可升至" + str(upgrade_target_star) + "星】"

	var parts: Array[String] = [name, item_line]
	var upgrade_hint: String = _get_unit_upgrade_hint(shop_item)
	if description.strip_edges() != "":
		var description_line: String = description
		if upgrade_hint != "":
			description_line += "  " + upgrade_hint
		parts.append(description_line)
	elif upgrade_hint != "":
		parts.append(upgrade_hint)

	return _join_text(parts, "\n")


func _build_item_tooltip(shop_item: Dictionary, item_type: String) -> String:
	var tooltip_parts: Array[String] = [str(shop_item.get("name", "物品"))]
	var description: String = str(shop_item.get("description", ""))
	if description.strip_edges() != "":
		tooltip_parts.append(description)

	var upgrade_hint: String = _get_unit_upgrade_hint(shop_item)
	if upgrade_hint != "":
		tooltip_parts.append(upgrade_hint)

	if item_type == "RELIC":
		tooltip_parts.append("点击卡片查看遗物详情。")
	return _join_text(tooltip_parts, "\n")


func _get_unit_upgrade_hint(shop_item: Dictionary) -> String:
	if str(shop_item.get("type", "")) != "UNIT":
		return ""

	var unit_data: Resource = shop_item.get("unit_data", null) as Resource
	if unit_data == null:
		return ""

	if roster_manager == null or not roster_manager.has_method("get_unit_upgrade_hint_for_data"):
		return ""

	return str(roster_manager.get_unit_upgrade_hint_for_data(unit_data))


func _get_unit_upgrade_target_star(shop_item: Dictionary) -> int:
	if str(shop_item.get("type", "")) != "UNIT":
		return 0

	var unit_data: Resource = shop_item.get("unit_data", null) as Resource
	if unit_data == null:
		return 0

	if roster_manager == null or not roster_manager.has_method("get_unit_upgrade_target_star_for_data"):
		return 0

	return int(roster_manager.get_unit_upgrade_target_star_for_data(unit_data))


func _apply_static_styles() -> void:
	if shop_panel != null:
		shop_panel.add_theme_stylebox_override("panel", _create_panel_style())

	if shop_title_label != null:
		shop_title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0, 1.0))
		shop_title_label.add_theme_font_size_override("font_size", 18)
	if shop_gold_label != null:
		shop_gold_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42, 1.0))

	for label: Label in item_labels:
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.45))
		label.add_theme_constant_override("outline_size", 1)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_apply_action_button_style(refresh_shop_button, Color(0.20, 0.32, 0.46, 1.0))
	_apply_action_button_style(shop_close_button, Color(0.26, 0.28, 0.30, 1.0))


func _apply_item_style(
	item_background: Panel,
	item_label: Label,
	buy_button: Button,
	shop_item: Dictionary,
	item_type: String,
	rarity: String,
	is_sold: bool
) -> void:
	var is_unlock_offer: bool = bool(shop_item.get("is_unlock_offer", false))
	var is_upgrade_offer: bool = _get_unit_upgrade_target_star(shop_item) > 0
	var base_color: Color = _get_item_background_color(item_type, rarity, is_sold, is_unlock_offer)
	var border_color: Color = _get_item_border_color(item_type, rarity, is_sold, is_unlock_offer, is_upgrade_offer)
	var text_color: Color = _get_text_color(base_color)

	if item_background != null:
		item_background.visible = true
		item_background.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if item_type == "RELIC" else Control.CURSOR_ARROW
		item_background.add_theme_stylebox_override("panel", _create_card_style(base_color, border_color, item_type == "RELIC"))

	item_label.add_theme_color_override("font_color", text_color)

	var button_color: Color = _darken_color(base_color, 0.10)
	if bool(shop_item.get("is_sold", false)):
		button_color = Color(0.25, 0.25, 0.25, 1.0)
	_apply_action_button_style(buy_button, button_color)


func _get_item_background_color(item_type: String, rarity: String, is_sold: bool, is_unlock_offer: bool = false) -> Color:
	if item_type == "EMPTY":
		return Color(0.15, 0.16, 0.17, 0.90)

	if is_sold:
		return Color(0.22, 0.23, 0.24, 0.92)

	if is_unlock_offer:
		return Color(0.13, 0.22, 0.26, 0.96)

	var rarity_color: Color = _get_rarity_color(rarity)
	if item_type == "RELIC":
		return _lighten_color(rarity_color, 0.06)

	return _darken_color(rarity_color, 0.05)


func _get_item_border_color(
	item_type: String,
	rarity: String,
	is_sold: bool,
	is_unlock_offer: bool = false,
	is_upgrade_offer: bool = false
) -> Color:
	if item_type == "EMPTY":
		return Color(0.36, 0.38, 0.40, 1.0)

	if is_sold:
		return Color(0.42, 0.42, 0.42, 1.0)

	if is_upgrade_offer:
		return Color(1.0, 0.88, 0.30, 1.0)

	if is_unlock_offer:
		return Color(0.36, 0.82, 0.88, 1.0)

	if item_type == "RELIC":
		return Color(0.98, 0.78, 0.28, 1.0)

	return _darken_color(_get_rarity_color(rarity), 0.25)


func _create_panel_style() -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_panel_style(Color(0.060, 0.078, 0.110, 0.96), Color(0.54, 0.64, 0.76, 1.0), 2, 10.0)


func _create_card_style(bg_color: Color, border_color: Color, is_relic: bool) -> StyleBoxFlat:
	var border_width: int = 3 if is_relic else 2
	return PIXEL_UI_THEME.create_panel_style(bg_color, border_color, border_width, 6.0)


func _apply_action_button_style(button: Button, base_color: Color) -> void:
	if button == null:
		return

	var border_color: Color = _darken_color(base_color, 0.16)
	PIXEL_UI_THEME.apply_button_style(button, base_color, border_color, 2)
	var text_color: Color = _get_text_color(base_color)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", Color(0.68, 0.68, 0.68, 1.0))


func _create_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_button_style(bg_color, border_color, 2, 6.0)


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
