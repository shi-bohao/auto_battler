class_name RelicPanelController
extends RefCounted

const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")


const BAR_TEXT_COLOR: Color = Color(0.98, 0.78, 0.43, 1.0)
const BAR_HOVER_TEXT_COLOR: Color = Color(1.0, 0.90, 0.62, 1.0)
const BAR_OUTLINE_COLOR: Color = Color(0.02, 0.015, 0.02, 1.0)


var relic_bar_panel: Panel = null
var relic_bar_hbox: HBoxContainer = null
var relic_detail_panel: Panel = null
var relic_list_vbox: VBoxContainer = null
var relic_info_text: RichTextLabel = null
var relic_manager: RelicManager = null
var rarity_formatter: Variant = null
var max_bar_items: int = 5
var max_bar_name_length: int = 14
var is_showing_shop_detail: bool = false


func setup(
	relic_bar_panel_value: Panel,
	relic_bar_hbox_value: HBoxContainer,
	relic_detail_panel_value: Panel,
	relic_list_vbox_value: VBoxContainer,
	relic_info_text_value: RichTextLabel,
	relic_manager_value: RelicManager,
	rarity_formatter_value: Variant,
	max_bar_items_value: int,
	max_bar_name_length_value: int
) -> void:
	relic_bar_panel = relic_bar_panel_value
	relic_bar_hbox = relic_bar_hbox_value
	relic_detail_panel = relic_detail_panel_value
	relic_list_vbox = relic_list_vbox_value
	relic_info_text = relic_info_text_value
	relic_manager = relic_manager_value
	rarity_formatter = rarity_formatter_value
	max_bar_items = max_bar_items_value
	max_bar_name_length = max_bar_name_length_value


func refresh_relic_bar() -> void:
	if relic_bar_panel == null or relic_bar_hbox == null:
		return

	relic_bar_panel.visible = true
	_clear_container_children(relic_bar_hbox)

	var relics: Array[Resource] = _get_owned_relics()
	if relics.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "-"
		empty_label.custom_minimum_size = Vector2(40.0, 30.0)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_bar_label_style(empty_label)
		relic_bar_hbox.add_child(empty_label)
		_refresh_open_relic_detail_panel(0)
		return

	var visible_count: int = mini(max_bar_items, relics.size())
	if relics.size() > max_bar_items:
		visible_count = maxi(max_bar_items - 1, 1)

	for relic_index: int in range(visible_count):
		var relic_button: Button = Button.new()
		relic_button.text = _get_relic_bar_name(relics[relic_index])
		relic_button.tooltip_text = relic_manager.get_relic_name(relics[relic_index])
		relic_button.custom_minimum_size = Vector2(112.0, 30.0)
		relic_button.clip_text = true
		relic_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_bar_button_style(relic_button)
		relic_button.pressed.connect(_on_relic_bar_item_pressed.bind(relic_index))
		relic_bar_hbox.add_child(relic_button)

	if relics.size() > visible_count:
		var more_button: Button = Button.new()
		more_button.text = "+" + str(relics.size() - visible_count)
		more_button.tooltip_text = "查看全部遗物"
		more_button.custom_minimum_size = Vector2(64.0, 30.0)
		more_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_bar_button_style(more_button)
		more_button.pressed.connect(_on_more_relics_button_pressed)
		relic_bar_hbox.add_child(more_button)

	_refresh_open_relic_detail_panel(0)


func show_relic_detail(selected_index: int = 0) -> void:
	if relic_detail_panel == null:
		return

	is_showing_shop_detail = false
	var relics: Array[Resource] = _get_owned_relics()
	_rebuild_relic_detail_list()
	relic_detail_panel.visible = true

	if relics.is_empty():
		relic_info_text.text = "暂无遗物。"
		return

	var selected_relic_index: int = selected_index
	if selected_relic_index < 0:
		selected_relic_index = 0
	if selected_relic_index >= relics.size():
		selected_relic_index = relics.size() - 1

	_show_relic_info(selected_relic_index)


func hide_relic_detail() -> void:
	is_showing_shop_detail = false
	if relic_detail_panel != null:
		relic_detail_panel.visible = false


func show_shop_relic_detail(shop_item: Dictionary) -> void:
	if relic_detail_panel == null or relic_info_text == null:
		return

	var relic_data: Resource = shop_item.get("relic_data", null) as Resource
	if relic_data == null:
		return

	is_showing_shop_detail = true
	if relic_list_vbox != null:
		_clear_container_children(relic_list_vbox)
		var shop_label: Label = Label.new()
		shop_label.text = "商店遗物"
		shop_label.custom_minimum_size = Vector2(132.0, 30.0)
		shop_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.48, 1.0))
		relic_list_vbox.add_child(shop_label)

	var price_line: String = "商店价格：" + str(int(shop_item.get("price", 0))) + " 金币"
	relic_info_text.text = _build_relic_info_text(relic_data, price_line)
	relic_detail_panel.visible = true


func is_showing_shop_relic_detail() -> bool:
	return is_showing_shop_detail


func _refresh_open_relic_detail_panel(selected_index: int) -> void:
	if relic_detail_panel != null and relic_detail_panel.visible and not is_showing_shop_detail:
		show_relic_detail(selected_index)


func _on_relic_bar_item_pressed(relic_index: int) -> void:
	show_relic_detail(relic_index)


func _on_more_relics_button_pressed() -> void:
	show_relic_detail(0)


func _on_relic_list_item_pressed(relic_index: int) -> void:
	_show_relic_info(relic_index)


func _rebuild_relic_detail_list() -> void:
	if relic_list_vbox == null:
		return

	_clear_container_children(relic_list_vbox)

	var relics: Array[Resource] = _get_owned_relics()
	if relics.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "暂无遗物"
		empty_label.custom_minimum_size = Vector2(132.0, 28.0)
		relic_list_vbox.add_child(empty_label)
		return

	for relic_index: int in range(relics.size()):
		var relic_button: Button = Button.new()
		relic_button.text = relic_manager.get_relic_name(relics[relic_index])
		relic_button.tooltip_text = relic_manager.get_relic_name(relics[relic_index])
		relic_button.custom_minimum_size = Vector2(132.0, 30.0)
		relic_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		relic_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_detail_button_style(relic_button)
		relic_button.pressed.connect(_on_relic_list_item_pressed.bind(relic_index))
		relic_list_vbox.add_child(relic_button)


func _show_relic_info(relic_index: int) -> void:
	if relic_info_text == null:
		return

	var relics: Array[Resource] = _get_owned_relics()
	if relic_index < 0 or relic_index >= relics.size():
		relic_info_text.text = "未选择遗物。"
		return

	var relic_data: Resource = relics[relic_index]
	relic_info_text.text = _build_relic_info_text(relic_data)


func _build_relic_info_text(relic_data: Resource, extra_line: String = "") -> String:
	var lines: Array[String] = []
	lines.append("[b]" + relic_manager.get_relic_name(relic_data) + "[/b]")
	if extra_line.strip_edges() != "":
		lines.append(extra_line)
	lines.append("稀有度：" + _get_rarity_display_name(relic_manager.get_relic_rarity(relic_data)))
	lines.append("触发：" + _get_relic_trigger_display_name(relic_manager.get_relic_trigger_type(relic_data)))
	lines.append("数值：" + _get_relic_value_text(relic_data))
	lines.append("")
	lines.append("[b]效果：[/b]")
	lines.append(_format_empty_value(relic_manager.get_relic_description(relic_data)))
	return _join_text(lines, "\n")


func _get_relic_bar_name(relic_data: Resource) -> String:
	var relic_name: String = relic_manager.get_relic_name(relic_data)
	if relic_name.length() <= max_bar_name_length:
		return relic_name

	return relic_name.substr(0, max_bar_name_length - 3) + "..."


func _get_relic_value_text(relic_data: Resource) -> String:
	if relic_data == null:
		return "-"

	var configured_value: Variant = relic_data.get("value")
	if configured_value == null:
		return "-"

	return str(configured_value)


func _get_owned_relics() -> Array[Resource]:
	if relic_manager == null:
		var empty_relics: Array[Resource] = []
		return empty_relics

	return relic_manager.get_player_relics()


func _get_rarity_display_name(rarity: String) -> String:
	if rarity_formatter != null and rarity_formatter.has_method("get_display_name"):
		return str(rarity_formatter.get_display_name(rarity))

	return rarity


func _get_relic_trigger_display_name(trigger_type: String) -> String:
	match trigger_type:
		"BATTLE_START":
			return "战斗开始"
		"ON_ATTACK":
			return "攻击命中"
		"ON_KILL":
			return "击杀"
		"ON_DEATH":
			return "死亡"
		_:
			return _format_empty_value(trigger_type)


func _apply_bar_label_style(label: Label) -> void:
	label.add_theme_color_override("font_color", BAR_TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", BAR_OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_font_size_override("font_size", 18)


func _apply_bar_button_style(button: Button) -> void:
	PIXEL_UI_THEME.apply_button_style(button, Color(0.070, 0.090, 0.125, 0.88), Color(0.70, 0.52, 0.30, 0.92), 1, 18)
	button.add_theme_color_override("font_color", BAR_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", BAR_HOVER_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", Color(0.82, 0.92, 1.0, 1.0))
	button.add_theme_color_override("font_outline_color", BAR_OUTLINE_COLOR)
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_font_size_override("font_size", 18)


func _apply_detail_button_style(button: Button) -> void:
	PIXEL_UI_THEME.apply_button_style(button, Color(0.06, 0.08, 0.11, 0.88), Color(0.42, 0.34, 0.24, 0.92), 1, 16)
	button.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74, 1.0))
	button.add_theme_color_override("font_hover_color", BAR_HOVER_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", Color(0.82, 0.92, 1.0, 1.0))


func _create_button_style(bg_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_button_style(bg_color, border_color, border_width, 6.0)


func _format_empty_value(value: String) -> String:
	if value.strip_edges() == "":
		return "-"

	return value


func _join_text(parts: Array[String], separator: String) -> String:
	var joined_text: String = ""

	for index: int in range(parts.size()):
		if index > 0:
			joined_text += separator
		joined_text += parts[index]

	return joined_text


func _clear_container_children(container: Node) -> void:
	if container == null:
		return

	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
