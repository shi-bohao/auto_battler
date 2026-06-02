class_name FieldEffectVisual
extends Node2D


const VISUAL_Z_INDEX: int = 3
const PERSISTENT_VISUAL_Z_INDEX: int = 6
const MIN_FILL_ALPHA: float = 0.30
const PERSISTENT_FILL_ALPHA: float = 0.46
const MIN_BORDER_ALPHA: float = 0.82
const PERSISTENT_BORDER_ALPHA: float = 0.96
const BORDER_WIDTH: float = 4.0
const VISUAL_MODE_INSTANT: String = "instant"
const VISUAL_MODE_PERSISTENT: String = "persistent"

var radius: float = 100.0
var fill_color: Color = Color(0.25, 0.95, 0.35, 0.22)
var border_color: Color = Color(0.55, 1.0, 0.55, 0.55)
var visual_mode: String = VISUAL_MODE_INSTANT
var pulse_time: float = 0.0


func setup(
	configured_radius: float,
	configured_fill_color: Color = Color(0.25, 0.95, 0.35, 0.22),
	configured_visual_mode: String = VISUAL_MODE_INSTANT
) -> void:
	radius = maxf(1.0, configured_radius)
	visual_mode = configured_visual_mode
	fill_color = configured_fill_color
	var minimum_alpha: float = PERSISTENT_FILL_ALPHA if visual_mode == VISUAL_MODE_PERSISTENT else MIN_FILL_ALPHA
	fill_color.a = clampf(maxf(fill_color.a, minimum_alpha), 0.0, 0.72)
	var minimum_border_alpha: float = PERSISTENT_BORDER_ALPHA if visual_mode == VISUAL_MODE_PERSISTENT else MIN_BORDER_ALPHA
	border_color = Color(
		clampf(fill_color.r + 0.24, 0.0, 1.0),
		clampf(fill_color.g + 0.12, 0.0, 1.0),
		clampf(fill_color.b + 0.24, 0.0, 1.0),
		minimum_border_alpha
	)
	z_as_relative = false
	z_index = PERSISTENT_VISUAL_Z_INDEX if visual_mode == VISUAL_MODE_PERSISTENT else VISUAL_Z_INDEX
	queue_redraw()


func _process(delta: float) -> void:
	pulse_time += maxf(delta, 0.0)
	queue_redraw()


func _draw() -> void:
	if visual_mode == VISUAL_MODE_PERSISTENT:
		_draw_persistent_field()
		return

	_draw_instant_field()


func _draw_instant_field() -> void:
	var pulse: float = 0.82 + 0.18 * sin(pulse_time * TAU * 1.2)
	var current_fill: Color = fill_color
	var current_border: Color = border_color
	current_fill.a *= pulse
	current_border.a = clampf(border_color.a * (0.88 + 0.12 * pulse), 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, current_fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, current_border, BORDER_WIDTH)
	draw_arc(Vector2.ZERO, maxf(1.0, radius * 0.86), 0.0, TAU, 96, Color(current_border.r, current_border.g, current_border.b, current_border.a * 0.45), 2.0)


func _draw_persistent_field() -> void:
	var pulse: float = 0.72 + 0.28 * sin(pulse_time * TAU * 0.75)
	var current_fill: Color = fill_color
	var current_border: Color = border_color
	current_fill.a *= 0.88 + 0.12 * pulse
	current_border.a = clampf(border_color.a * (0.90 + 0.10 * pulse), 0.0, 1.0)

	draw_circle(Vector2.ZERO, radius, current_fill)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, current_border, BORDER_WIDTH + 1.0)
	draw_arc(Vector2.ZERO, maxf(1.0, radius * 0.72), 0.0, TAU, 128, Color(current_border.r, current_border.g, current_border.b, current_border.a * 0.70), 3.0)

	var tick_color: Color = Color(current_border.r, current_border.g, current_border.b, current_border.a * 0.82)
	for index: int in range(16):
		var angle: float = TAU * float(index) / 16.0 + pulse_time * 0.45
		var direction: Vector2 = Vector2(cos(angle), sin(angle))
		var start_point: Vector2 = direction * radius * 0.78
		var end_point: Vector2 = direction * radius * 0.96
		draw_line(start_point, end_point, tick_color, 2.0)
