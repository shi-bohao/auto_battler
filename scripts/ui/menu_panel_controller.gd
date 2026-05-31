class_name MenuPanelController
extends RefCounted


const MAIN_MENU_PANEL_SCENE: PackedScene = preload("res://scenes/ui/main_menu_panel.tscn")
const GAME_END_PANEL_SCENE: PackedScene = preload("res://scenes/ui/game_end_panel.tscn")
const GAMEPLAY_MENU_PANEL_SCENE: PackedScene = preload("res://scenes/ui/gameplay_menu_panel.tscn")
const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")
const UI_LAYER: Script = preload("res://scripts/ui/ui_layer.gd")
const BACKGROUND_CATALOG: Script = preload("res://scripts/ui/background_catalog.gd")

signal start_requested()
signal mirror_challenge_requested()
signal encyclopedia_requested()
signal game_end_confirmed()
signal main_menu_requested()
signal restart_requested()
signal background_selected(index: int)


var canvas_layer: CanvasLayer = null
var rarity_formatter: Variant = null
var main_menu_panel: Panel = null
var game_end_panel: Panel = null
var game_end_title_label: Label = null
var game_end_message_label: Label = null
var gameplay_menu_panel: Panel = null
var main_menu_background: TextureRect = null
var background_selector: OptionButton = null
var selected_background_index: int = 0


func setup(canvas_layer_value: CanvasLayer, rarity_formatter_value: Variant) -> void:
	canvas_layer = canvas_layer_value
	rarity_formatter = rarity_formatter_value
	_create_main_menu_ui()
	_create_game_end_dialog()
	_create_gameplay_menu_dialog()


func show_main_menu() -> void:
	if main_menu_panel != null:
		main_menu_panel.visible = true
		_refresh_background_selector()


func hide_main_menu() -> void:
	if main_menu_panel != null:
		main_menu_panel.visible = false


func show_gameplay_menu() -> void:
	if gameplay_menu_panel != null:
		gameplay_menu_panel.visible = true


func hide_gameplay_menu() -> void:
	if gameplay_menu_panel != null:
		gameplay_menu_panel.visible = false


func show_game_end_dialog(game_over_text: String, current_round: int) -> void:
	if game_end_panel == null:
		return
	if game_end_title_label == null or game_end_message_label == null:
		return

	hide_gameplay_menu()
	game_end_title_label.text = get_game_end_title(game_over_text)
	game_end_message_label.text = get_game_end_message(game_over_text, current_round)
	game_end_panel.visible = true


func hide_game_end_dialog() -> void:
	if game_end_panel != null:
		game_end_panel.visible = false


func get_game_end_title(game_over_text: String) -> String:
	if game_over_text.find("Victory") >= 0:
		return "通关成功"
	if game_over_text.find("Draw") >= 0:
		return "战斗平局"

	return "挑战失败"


func get_game_end_message(game_over_text: String, current_round: int) -> String:
	if game_over_text.find("Victory") >= 0:
		return "你击败了最终首领，完成了本次挑战。\n确认后返回主菜单。"
	if game_over_text.find("Draw") >= 0:
		return "本轮战斗未分胜负，挑战到此结束。\n确认后返回主菜单。"

	return "队伍在第 " + str(current_round) + " 轮倒下，挑战失败。\n确认后返回主菜单。"


func _create_main_menu_ui() -> void:
	if canvas_layer == null:
		return

	main_menu_panel = MAIN_MENU_PANEL_SCENE.instantiate() as Panel
	if main_menu_panel == null:
		return

	main_menu_panel.z_index = UI_LAYER.MAIN_MENU
	main_menu_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.0, 0.0, 0.0, 1.0), Color.TRANSPARENT, 0, 0))
	canvas_layer.add_child(main_menu_panel)

	main_menu_background = main_menu_panel.get_node_or_null("Background") as TextureRect
	_create_background_selector()
	set_background_index(selected_background_index)

	var start_button: Button = main_menu_panel.get_node_or_null("MainMenuContent/StartButton") as Button
	if start_button != null:
		start_button.text = "开始游戏"
		PIXEL_UI_THEME.apply_button_style(start_button, Color(0.13, 0.30, 0.48, 1.0), Color(0.96, 0.72, 0.40, 1.0), 4, 34)
		start_button.pressed.connect(_on_start_button_pressed)

	var mirror_button: Button = main_menu_panel.get_node_or_null("MainMenuContent/MirrorChallengeButton") as Button
	if mirror_button != null:
		mirror_button.text = "镜像挑战"
		PIXEL_UI_THEME.apply_button_style(mirror_button, Color(0.12, 0.22, 0.36, 1.0), Color(0.68, 0.82, 1.0, 1.0), 3, 28)
		mirror_button.pressed.connect(_on_mirror_challenge_button_pressed)

	var encyclopedia_button: Button = main_menu_panel.get_node_or_null("MainMenuContent/EncyclopediaButton") as Button
	if encyclopedia_button != null:
		encyclopedia_button.text = "图鉴"
		PIXEL_UI_THEME.apply_button_style(encyclopedia_button, Color(0.12, 0.22, 0.36, 1.0), Color(0.68, 0.82, 1.0, 1.0), 3, 28)
		encyclopedia_button.pressed.connect(_on_encyclopedia_button_pressed)


func set_background_index(index: int) -> void:
	var count: int = BACKGROUND_CATALOG.get_count()
	selected_background_index = 0 if count <= 0 else posmod(index, count)
	_apply_main_menu_background()
	_refresh_background_selector()


func _create_background_selector() -> void:
	if main_menu_panel == null:
		return

	var content: Control = main_menu_panel.get_node_or_null("MainMenuContent") as Control
	if content == null:
		return

	background_selector = OptionButton.new()
	background_selector.name = "BackgroundSelector"
	background_selector.anchor_left = 1.0
	background_selector.anchor_right = 1.0
	background_selector.offset_left = -284.0
	background_selector.offset_top = 32.0
	background_selector.offset_right = -32.0
	background_selector.offset_bottom = 72.0
	background_selector.focus_mode = Control.FOCUS_NONE
	background_selector.tooltip_text = "选择主菜单与战斗背景"
	background_selector.add_theme_font_size_override("font_size", 16)
	PIXEL_UI_THEME.apply_button_style(background_selector, Color(0.12, 0.22, 0.34, 0.96), Color(0.80, 0.64, 0.36, 1.0), 2, 16)
	background_selector.item_selected.connect(_on_background_selected)
	content.add_child(background_selector)
	_refresh_background_selector()


func _refresh_background_selector() -> void:
	if background_selector == null:
		return

	var names: Array[String] = BACKGROUND_CATALOG.get_background_names()
	if background_selector.item_count != names.size():
		background_selector.clear()
		for index: int in range(names.size()):
			background_selector.add_item(names[index], index)

	if background_selector.item_count > 0:
		background_selector.select(clampi(selected_background_index, 0, background_selector.item_count - 1))


func _apply_main_menu_background() -> void:
	if main_menu_background == null:
		return

	var texture: Texture2D = load(BACKGROUND_CATALOG.get_texture_path(selected_background_index)) as Texture2D
	if texture != null:
		main_menu_background.texture = texture


func _on_background_selected(index: int) -> void:
	set_background_index(index)
	background_selected.emit(selected_background_index)


func _create_game_end_dialog() -> void:
	if canvas_layer == null:
		return

	game_end_panel = GAME_END_PANEL_SCENE.instantiate() as Panel
	if game_end_panel == null:
		return

	game_end_panel.z_index = UI_LAYER.GAME_END_DIALOG
	game_end_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.02, 0.025, 0.03, 0.72), Color(0.0, 0.0, 0.0, 0.0), 0, 0))
	canvas_layer.add_child(game_end_panel)

	var card_panel: Panel = game_end_panel.get_node_or_null("GameEndCard") as Panel
	if card_panel != null:
		card_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.08, 0.10, 0.12, 0.98), Color(0.46, 0.58, 0.66, 1.0), 8, 2))

	game_end_title_label = game_end_panel.get_node_or_null("GameEndCard/Content/TitleLabel") as Label
	game_end_message_label = game_end_panel.get_node_or_null("GameEndCard/Content/MessageLabel") as Label

	var confirm_button: Button = game_end_panel.get_node_or_null("GameEndCard/Content/ConfirmButton") as Button
	if confirm_button != null:
		_apply_button_style(confirm_button, Color(0.22, 0.42, 0.36, 1.0), Color(0.78, 0.96, 0.86, 1.0))
		confirm_button.pressed.connect(_on_game_end_confirm_button_pressed)


func _create_gameplay_menu_dialog() -> void:
	if canvas_layer == null:
		return

	gameplay_menu_panel = GAMEPLAY_MENU_PANEL_SCENE.instantiate() as Panel
	if gameplay_menu_panel == null:
		return

	gameplay_menu_panel.z_index = UI_LAYER.GAMEPLAY_MENU
	gameplay_menu_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.02, 0.025, 0.03, 0.62), Color(0.0, 0.0, 0.0, 0.0), 0, 0))
	canvas_layer.add_child(gameplay_menu_panel)

	var card_panel: Panel = gameplay_menu_panel.get_node_or_null("GameplayMenuCard") as Panel
	if card_panel != null:
		card_panel.add_theme_stylebox_override("panel", _create_panel_style(Color(0.08, 0.10, 0.12, 0.98), Color(0.46, 0.58, 0.66, 1.0), 8, 2))

	var main_menu_button: Button = gameplay_menu_panel.get_node_or_null("GameplayMenuCard/Content/MainMenuButton") as Button
	if main_menu_button != null:
		_apply_button_style(main_menu_button, Color(0.20, 0.36, 0.52, 1.0), Color(0.68, 0.82, 1.0, 1.0))
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	var restart_button: Button = gameplay_menu_panel.get_node_or_null("GameplayMenuCard/Content/RestartButton") as Button
	if restart_button != null:
		_apply_button_style(restart_button, Color(0.44, 0.27, 0.22, 1.0), Color(1.0, 0.76, 0.62, 1.0))
		restart_button.pressed.connect(_on_restart_button_pressed)

	var continue_button: Button = gameplay_menu_panel.get_node_or_null("GameplayMenuCard/Content/ContinueButton") as Button
	if continue_button != null:
		_apply_button_style(continue_button, Color(0.24, 0.28, 0.32, 1.0), Color(0.62, 0.68, 0.74, 1.0))
		continue_button.pressed.connect(hide_gameplay_menu)


func _create_panel_style(bg_color: Color, border_color: Color, corner_radius: int, border_width: int) -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_panel_style(bg_color, border_color, border_width, 8.0)


func _on_start_button_pressed() -> void:
	start_requested.emit()


func _on_mirror_challenge_button_pressed() -> void:
	mirror_challenge_requested.emit()


func _on_encyclopedia_button_pressed() -> void:
	encyclopedia_requested.emit()


func _on_game_end_confirm_button_pressed() -> void:
	game_end_confirmed.emit()


func _on_main_menu_button_pressed() -> void:
	main_menu_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _apply_button_style(button: Button, base_color: Color, border_color: Color) -> void:
	PIXEL_UI_THEME.apply_button_style(button, base_color, border_color, 2)


func _create_button_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	return PIXEL_UI_THEME.create_button_style(bg_color, border_color, border_width, 10.0)


func _lighten_color(color: Color, amount: float) -> Color:
	if rarity_formatter != null and rarity_formatter.has_method("lighten_color"):
		return rarity_formatter.lighten_color(color, amount)

	return Color(
		minf(color.r + amount, 1.0),
		minf(color.g + amount, 1.0),
		minf(color.b + amount, 1.0),
		color.a
	)


func _darken_color(color: Color, amount: float) -> Color:
	if rarity_formatter != null and rarity_formatter.has_method("darken_color"):
		return rarity_formatter.darken_color(color, amount)

	return Color(
		maxf(color.r - amount, 0.0),
		maxf(color.g - amount, 0.0),
		maxf(color.b - amount, 0.0),
		color.a
	)
