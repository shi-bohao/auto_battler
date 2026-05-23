class_name FieldEffectVisual
extends Node2D


var radius: float = 100.0
var fill_color: Color = Color(0.25, 0.95, 0.35, 0.22)
var border_color: Color = Color(0.55, 1.0, 0.55, 0.55)


func setup(configured_radius: float, configured_fill_color: Color = Color(0.25, 0.95, 0.35, 0.22)) -> void:
	radius = maxf(1.0, configured_radius)
	fill_color = configured_fill_color
	border_color = Color(fill_color.r + 0.20, fill_color.g + 0.05, fill_color.b + 0.20, 0.58)
	z_index = -5
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, border_color, 2.0)
