class_name PathSelectionPanelController
extends RefCounted


signal path_selected(candidate: Dictionary)


const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")

var panel: Panel = null
var title_label: Label = null
var path_buttons: Array[Button] = []
var candidates: Array[Dictionary] = []
var is_selection_enabled: bool = false


func setup(
	panel_value: Panel,
	title_label_value: Label,
	buttons: Array[Button]
) -> void:
	panel = panel_value
	title_label = title_label_value
	path_buttons = buttons

	for index: int in range(path_buttons.size()):
		path_buttons[index].pressed.connect(_on_path_button_pressed.bind(index))

	hide_panel()


func show_panel(new_candidates: Array[Dictionary]) -> void:
	candidates = new_candidates
	is_selection_enabled = true
	if panel != null:
		panel.visible = true
	_refresh_buttons()


func hide_panel() -> void:
	is_selection_enabled = false
	if panel != null:
		panel.visible = false


func _refresh_buttons() -> void:
	for i in range(path_buttons.size()):
		if i < candidates.size():
			var candidate: Dictionary = candidates[i]
			var button_text: String = _format_button_text(candidate)
			path_buttons[i].text = button_text
			path_buttons[i].visible = true
			path_buttons[i].tooltip_text = candidate.get("description", "")
			_apply_rarity_color(path_buttons[i], candidate.get("rarity_hint", "COMMON"))
		else:
			path_buttons[i].visible = false


func _format_button_text(candidate: Dictionary) -> String:
	var display_name: String = candidate.get("display_name", "")
	var description: String = candidate.get("description", "")
	var preview: String = candidate.get("preview_enemies", "")
	var text: String = display_name + "\n" + description
	if preview != "":
		text += "\n" + preview
	return text


func _apply_rarity_color(button: Button, rarity: String) -> void:
	var color: Color = _get_rarity_color(rarity)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.set_border_width_all(2)
	style.border_color = color.lightened(0.3)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	button.add_theme_stylebox_override("normal", style)
	var hover_style: StyleBoxFlat = style.duplicate()
	hover_style.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover_style)
	var pressed_style: StyleBoxFlat = style.duplicate()
	pressed_style.bg_color = color.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed_style)


func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"COMMON":
			return Color(0.25, 0.25, 0.28, 0.9)
		"FINE":
			return Color(0.15, 0.35, 0.15, 0.9)
		"RARE":
			return Color(0.15, 0.25, 0.45, 0.9)
		"EPIC":
			return Color(0.35, 0.15, 0.45, 0.9)
		"LEGENDARY":
			return Color(0.5, 0.3, 0.05, 0.9)
		"MYTHIC":
			return Color(0.5, 0.4, 0.1, 0.9)
		_:
			return Color(0.25, 0.25, 0.28, 0.9)


func _on_path_button_pressed(index: int) -> void:
	if not is_selection_enabled:
		return
	if index < 0 or index >= candidates.size():
		return
	is_selection_enabled = false
	path_selected.emit(candidates[index])
