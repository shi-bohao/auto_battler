class_name TransitionPanelController
extends RefCounted


signal transition_completed()


const FADE_IN_TIME: float = 0.25
const HOLD_TIME: float = 0.4
const FADE_OUT_TIME: float = 0.25

var panel: Panel = null
var background: ColorRect = null
var round_label: Label = null
var node_type_label: Label = null
var description_label: Label = null
var is_active: bool = false
var pending_callback: Callable = Callable()


func setup(
	panel_value: Panel,
	background_value: ColorRect,
	round_label_value: Label,
	node_type_label_value: Label,
	description_label_value: Label
) -> void:
	panel = panel_value
	background = background_value
	round_label = round_label_value
	node_type_label = node_type_label_value
	description_label = description_label_value


func show_transition(current_round: int, node_type: String, node_display: String, node_desc: String, on_complete: Callable = Callable()) -> void:
	if is_active:
		return
	is_active = true
	pending_callback = on_complete

	panel.visible = true
	panel.z_index = 1000
	background.modulate = Color(1.0, 1.0, 1.0, 0.0)

	round_label.text = "第 " + str(current_round) + " 波"
	node_type_label.text = node_display
	description_label.text = node_desc

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.08, 0.95)
	panel.add_theme_stylebox_override("panel", style)

	var tween: Tween = panel.create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(background, "modulate:a", 1.0, FADE_IN_TIME)
	tween.tween_interval(HOLD_TIME)
	tween.tween_property(background, "modulate:a", 0.0, FADE_OUT_TIME)
	tween.tween_callback(_on_fade_complete)


func _on_fade_complete() -> void:
	is_active = false
	panel.visible = false
	var callback: Callable = pending_callback
	pending_callback = Callable()
	if not callback.is_null():
		callback.call()
	transition_completed.emit()
