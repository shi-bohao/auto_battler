extends Node2D

## Instant AoE visual: displays a shape briefly then fades out and self-destructs.
## Uses ShapeGeometry for vertex generation, no combat logic.
## Draws in local coordinates — caller must set global_position to the shape anchor.

const SHAPE_GEOMETRY_SCRIPT: Script = preload("res://scripts/combat/shape_geometry.gd")

var shape_geometry: Variant = SHAPE_GEOMETRY_SCRIPT.new()
var shape_data: Dictionary = {}
var duration: float = 0.25
var elapsed: float = 0.0
var fill_color: Color = Color.WHITE
var border_color: Color = Color.WHITE
var time_scale: float = 1.0


func setup(configured_shape_data: Dictionary, configured_color: Color, configured_duration: float = 0.25, configured_time_scale: float = 1.0) -> void:
	shape_data = configured_shape_data
	fill_color = configured_color
	border_color = Color(fill_color.r + 0.15, fill_color.g + 0.05, fill_color.b + 0.15, minf(1.0, fill_color.a + 0.15))
	duration = maxf(0.05, configured_duration)
	time_scale = maxf(0.01, configured_time_scale)
	z_index = -5
	queue_redraw()


func _process(delta: float) -> void:
	elapsed += delta * time_scale
	if elapsed >= duration:
		queue_free()
		return

	var fade_progress: float = clampf(elapsed / duration, 0.0, 1.0)
	var alpha_mult: float = 1.0
	if fade_progress > 0.5:
		alpha_mult = 1.0 - (fade_progress - 0.5) * 2.0

	modulate.a = alpha_mult


func _draw() -> void:
	if shape_data.is_empty():
		return

	var shape_type: String = str(shape_data.get("shape_type", "circle"))
	match shape_type:
		"rect":
			_draw_rect_shape()
		"sector":
			_draw_sector_shape()
		_:
			_draw_circle_shape()


func _draw_circle_shape() -> void:
	var radius: float = maxf(1.0, float(shape_data.get("radius", 0.0)))
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, border_color, 2.0)


func _draw_rect_shape() -> void:
	var direction: Vector2 = shape_data.get("direction", Vector2.RIGHT) as Vector2
	var length: float = maxf(0.0, float(shape_data.get("length", 0.0)))
	var width: float = maxf(0.0, float(shape_data.get("width", 0.0)))
	if length <= 0.0 or width <= 0.0:
		return

	var points: PackedVector2Array = shape_geometry.get_rect_points(Vector2.ZERO, direction, length, width)
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, border_color, 2.0, true)


func _draw_sector_shape() -> void:
	var direction: Vector2 = shape_data.get("direction", Vector2.RIGHT) as Vector2
	var radius: float = maxf(1.0, float(shape_data.get("radius", 0.0)))
	var angle_degrees: float = maxf(0.1, float(shape_data.get("angle_degrees", 90.0)))
	if radius <= 0.0:
		return

	var points: PackedVector2Array = shape_geometry.get_sector_points(Vector2.ZERO, direction, radius, angle_degrees)
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, border_color, 2.0, true)
