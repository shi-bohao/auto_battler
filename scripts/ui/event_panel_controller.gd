class_name EventPanelController
extends RefCounted


signal choice_resolved(result: Dictionary)
signal continue_pressed()


const PIXEL_UI_THEME: Script = preload("res://scripts/ui/pixel_ui_theme.gd")

var panel: Panel = null
var title_label: Label = null
var event_text: RichTextLabel = null
var choice_buttons: Array[Button] = []
var result_label: Label = null
var continue_button: Button = null
var event_manager: Variant = null
var is_choice_enabled: bool = false


func setup(
	panel_value: Panel,
	title_label_value: Label,
	event_text_value: RichTextLabel,
	choice_buttons_value: Array[Button],
	result_label_value: Label,
	continue_button_value: Button,
	event_manager_value: Variant
) -> void:
	panel = panel_value
	title_label = title_label_value
	event_text = event_text_value
	choice_buttons = choice_buttons_value
	result_label = result_label_value
	continue_button = continue_button_value
	event_manager = event_manager_value

	for i: int in range(choice_buttons.size()):
		choice_buttons[i].pressed.connect(_on_choice_pressed.bind(i))
	continue_button.pressed.connect(_on_continue_pressed)
	hide_panel()


func show_panel(event: Dictionary) -> void:
	if panel == null:
		return
	panel.visible = true
	is_choice_enabled = true
	_show_choice_phase(event)


func hide_panel() -> void:
	is_choice_enabled = false
	if panel != null:
		panel.visible = false


func _show_choice_phase(event: Dictionary) -> void:
	if title_label != null:
		title_label.text = event.get("event_name_cn", "事件")
	if event_text != null:
		event_text.text = event.get("event_text_cn", "")
		event_text.visible = true
	if result_label != null:
		result_label.visible = false
	if continue_button != null:
		continue_button.visible = false

	var choices: Array = event.get("choices", [])
	for i: int in range(choice_buttons.size()):
		if i < choices.size():
			var choice: Dictionary = choices[i]
			var label: String = choice.get("label_cn", "选项")
			var desc: String = choice.get("description_cn", "")
			choice_buttons[i].text = label + "\n" + desc
			choice_buttons[i].visible = true
			choice_buttons[i].disabled = false
			PIXEL_UI_THEME.apply_button_style(choice_buttons[i], Color(0.15, 0.20, 0.30), Color(0.40, 0.55, 0.85), 2)
		else:
			choice_buttons[i].visible = false


func _show_result_phase(result_text: String) -> void:
	for btn: Button in choice_buttons:
		btn.visible = false
	if event_text != null:
		event_text.visible = false
	if result_label != null:
		result_label.text = result_text
		result_label.visible = true
	if continue_button != null:
		continue_button.visible = true
		PIXEL_UI_THEME.apply_button_style(continue_button, Color(0.15, 0.25, 0.15), Color(0.35, 0.60, 0.35), 2)


func _on_choice_pressed(index: int) -> void:
	if not is_choice_enabled:
		return
	is_choice_enabled = false
	for btn: Button in choice_buttons:
		btn.disabled = true

	var result: Dictionary = event_manager.resolve_choice(index)
	var result_text: String = result.get("result_text", "")

	_show_result_phase(result_text)
	choice_resolved.emit(result)


func _on_continue_pressed() -> void:
	continue_pressed.emit()
