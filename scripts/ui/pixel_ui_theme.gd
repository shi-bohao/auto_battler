class_name PixelUITheme
extends RefCounted

const PANEL_BG: Color = Color(0.055, 0.070, 0.105, 0.96)
const PANEL_BORDER: Color = Color(0.62, 0.70, 0.82, 1.0)
const BUTTON_BG: Color = Color(0.12, 0.22, 0.34, 1.0)
const BUTTON_BORDER: Color = Color(0.80, 0.64, 0.36, 1.0)
const BUTTON_DISABLED_BG: Color = Color(0.16, 0.17, 0.19, 0.92)
const BUTTON_DISABLED_BORDER: Color = Color(0.36, 0.38, 0.42, 1.0)
const TEXT_LIGHT: Color = Color(0.94, 0.96, 1.0, 1.0)
const TEXT_GOLD: Color = Color(1.0, 0.84, 0.50, 1.0)
const TEXT_DISABLED: Color = Color(0.58, 0.61, 0.66, 1.0)
const OUTLINE: Color = Color(0.015, 0.018, 0.024, 1.0)

const NORMAL_SCALE := Vector2(1.0, 1.0)
const HOVER_SCALE := Vector2(1.05, 1.05)
const PRESS_SCALE := Vector2(0.93, 0.93)

const META_TWEEN_CONNECTED: String = "_pixel_tween_connected"
const META_IS_HOVERING: String = "_pixel_is_hovering"
const META_TWEEN: String = "_pixel_tween"


static func apply_panel_style(
	panel: Control,
	bg_color: Color = PANEL_BG,
	border_color: Color = PANEL_BORDER,
	border_width: int = 2,
	content_margin: float = 8.0
) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", create_panel_style(bg_color, border_color, border_width, content_margin))


static func create_panel_style(
	bg_color: Color = PANEL_BG,
	border_color: Color = PANEL_BORDER,
	border_width: int = 2,
	content_margin: float = 8.0
) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	_set_square_corners(style)
	_set_content_margin(style, content_margin)
	return style


static func apply_button_style(
	button: Button,
	base_color: Color = BUTTON_BG,
	border_color: Color = BUTTON_BORDER,
	border_width: int = 2,
	font_size: int = -1
) -> void:
	if button == null:
		return

	button.add_theme_stylebox_override("normal", create_button_style(base_color, border_color, border_width))
	button.add_theme_stylebox_override("hover", create_button_style(lighten_color(base_color, 0.08), lighten_color(border_color, 0.06), border_width))
	button.add_theme_stylebox_override("pressed", create_button_style(darken_color(base_color, 0.10), darken_color(border_color, 0.08), border_width))
	button.add_theme_stylebox_override("focus", create_button_style(lighten_color(base_color, 0.12), Color(1.0, 0.92, 0.62, 1.0), border_width + 1))
	button.add_theme_stylebox_override("disabled", create_button_style(BUTTON_DISABLED_BG, BUTTON_DISABLED_BORDER, border_width))
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.68, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.84, 0.92, 1.0, 1.0))
	button.add_theme_color_override("font_focus_color", TEXT_LIGHT)
	button.add_theme_color_override("font_disabled_color", TEXT_DISABLED)
	button.add_theme_color_override("font_outline_color", OUTLINE)
	button.add_theme_constant_override("outline_size", 2)
	if font_size > 0:
		button.add_theme_font_size_override("font_size", font_size)

	_setup_button_tween_animations(button)


static func create_button_style(
	bg_color: Color = BUTTON_BG,
	border_color: Color = BUTTON_BORDER,
	border_width: int = 2,
	content_margin: float = 8.0
) -> StyleBoxFlat:
	var style: StyleBoxFlat = create_panel_style(bg_color, border_color, border_width, content_margin)
	return style


static func apply_label_style(label: Label, font_color: Color = TEXT_LIGHT, font_size: int = -1, outline_size: int = 2) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", outline_size)
	if font_size > 0:
		label.add_theme_font_size_override("font_size", font_size)


static func apply_rich_text_style(label: RichTextLabel, font_color: Color = TEXT_LIGHT, font_size: int = -1) -> void:
	if label == null:
		return
	label.add_theme_color_override("default_color", font_color)
	if font_size > 0:
		label.add_theme_font_size_override("normal_font_size", font_size)


static func lighten_color(color: Color, amount: float) -> Color:
	return Color(
		minf(color.r + amount, 1.0),
		minf(color.g + amount, 1.0),
		minf(color.b + amount, 1.0),
		color.a
	)


static func darken_color(color: Color, amount: float) -> Color:
	return Color(
		maxf(color.r - amount, 0.0),
		maxf(color.g - amount, 0.0),
		maxf(color.b - amount, 0.0),
		color.a
	)


static func _set_square_corners(style: StyleBoxFlat) -> void:
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.anti_aliasing = false


static func _set_content_margin(style: StyleBoxFlat, value: float) -> void:
	style.set_content_margin(SIDE_LEFT, value)
	style.set_content_margin(SIDE_TOP, value)
	style.set_content_margin(SIDE_RIGHT, value)
	style.set_content_margin(SIDE_BOTTOM, value)


static func _setup_button_tween_animations(button: Button) -> void:
	if button.has_meta(META_TWEEN_CONNECTED):
		return

	button.set_meta(META_TWEEN_CONNECTED, true)
	button.set_meta(META_IS_HOVERING, false)

	_ensure_button_pivot(button)
	button.resized.connect(_on_button_resized.bind(button))
	button.mouse_entered.connect(_on_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_mouse_exited.bind(button))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))


static func _ensure_button_pivot(button: Button) -> void:
	if button.size.x > 0.0 and button.size.y > 0.0:
		button.pivot_offset = button.size / 2.0


static func _on_button_resized(button: Button) -> void:
	_ensure_button_pivot(button)


static func _on_mouse_entered(button: Button) -> void:
	button.set_meta(META_IS_HOVERING, true)
	_play_button_tween(button, HOVER_SCALE, 0.12)


static func _on_mouse_exited(button: Button) -> void:
	button.set_meta(META_IS_HOVERING, false)
	_play_button_tween(button, NORMAL_SCALE, 0.12)


static func _on_button_down(button: Button) -> void:
	_play_button_tween(button, PRESS_SCALE, 0.06)


static func _on_button_up(button: Button) -> void:
	var is_hovering: bool = bool(button.get_meta(META_IS_HOVERING)) if button.has_meta(META_IS_HOVERING) else false
	if is_hovering:
		_play_button_tween(button, HOVER_SCALE, 0.16)
	else:
		_play_button_tween(button, NORMAL_SCALE, 0.16)


static func _play_button_tween(button: Button, target_scale: Vector2, duration: float) -> void:
	if button.has_meta(META_TWEEN):
		var existing_tween: Variant = button.get_meta(META_TWEEN)
		if existing_tween != null and is_instance_valid(existing_tween):
			existing_tween.kill()

	var tween: Tween = button.create_tween()
	button.set_meta(META_TWEEN, tween)
	tween.tween_property(button, "scale", target_scale, duration) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
