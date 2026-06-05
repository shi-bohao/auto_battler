class_name ControlStatusView
extends RefCounted

const BADGE_SIZE: Vector2 = Vector2(22.0, 20.0)
const BADGE_FONT_SIZE: int = 12
const BADGE_CHAR_WIDTH: float = 10.5
const BADGE_H_PADDING: float = 8.0

var row: HBoxContainer = null
var badges_by_type: Dictionary = {}
var active_types: Array[String] = []
var pulse_tweens: Dictionary = {}


func setup(container: HBoxContainer) -> void:
	row = container
	if row == null:
		return

	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.visible = false


func refresh(tags: Array[Dictionary]) -> void:
	if row == null or not is_instance_valid(row):
		return

	active_types.clear()
	for badge_type: Variant in badges_by_type.keys():
		var badge: Control = badges_by_type[badge_type] as Control
		if badge != null and is_instance_valid(badge):
			badge.visible = false

	var sorted_tags: Array[Dictionary] = tags.duplicate()
	sorted_tags.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)

	var index: int = 0
	for tag: Dictionary in sorted_tags:
		var control_type: String = str(tag.get("type", tag.get("text", "")))
		if control_type.strip_edges() == "":
			continue

		var badge: Control = _get_or_create_badge(control_type)
		_update_badge(badge, tag)
		badge.visible = true
		row.move_child(badge, index)
		active_types.append(control_type)
		index += 1

	row.visible = not active_types.is_empty()


func clear() -> void:
	refresh([])


func pulse(control_type: String) -> void:
	if control_type.strip_edges() == "":
		return

	var badge: Control = badges_by_type.get(control_type, null) as Control
	if badge == null or not is_instance_valid(badge):
		return

	if pulse_tweens.has(control_type):
		var old_tween: Tween = pulse_tweens[control_type] as Tween
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()

	badge.scale = Vector2.ONE
	badge.pivot_offset = BADGE_SIZE * 0.5
	var tween: Tween = badge.create_tween()
	pulse_tweens[control_type] = tween
	tween.tween_property(badge, "scale", Vector2(1.22, 1.22), 0.08)
	tween.tween_property(badge, "scale", Vector2.ONE, 0.10)


func _get_or_create_badge(control_type: String) -> Control:
	var existing_badge: Control = badges_by_type.get(control_type, null) as Control
	if existing_badge != null and is_instance_valid(existing_badge):
		return existing_badge

	var badge: PanelContainer = PanelContainer.new()
	badge.name = control_type + "Badge"
	badge.custom_minimum_size = BADGE_SIZE
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var label: Label = Label.new()
	label.name = "Label"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", BADGE_FONT_SIZE)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 2)
	badge.add_child(label)

	row.add_child(badge)
	badges_by_type[control_type] = badge
	return badge


func _update_badge(badge: Control, tag: Dictionary) -> void:
	if badge == null or not is_instance_valid(badge):
		return

	var label: Label = badge.get_node_or_null("Label") as Label
	var label_text: String = str(tag.get("label", tag.get("text", "")))
	if label != null:
		label.text = label_text
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

	var text_width: float = float(label_text.length()) * BADGE_CHAR_WIDTH
	var min_width: float = maxf(BADGE_SIZE.x, text_width + BADGE_H_PADDING)
	badge.custom_minimum_size = Vector2(min_width, BADGE_SIZE.y)

	var color: Color = tag.get("color", Color.WHITE) as Color
	var background: Color = Color(
		clampf(color.r * 0.25, 0.04, 0.35),
		clampf(color.g * 0.25, 0.04, 0.35),
		clampf(color.b * 0.25, 0.04, 0.35),
		0.92
	)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = color
	style.corner_radius_top_left = 1
	style.corner_radius_top_right = 1
	style.corner_radius_bottom_left = 1
	style.corner_radius_bottom_right = 1
	badge.add_theme_stylebox_override("panel", style)
