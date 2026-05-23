extends RefCounted

## Pure utility: generates polygon vertex arrays for circle, rect, and sector shapes.
## Used by AoeShapeVisual (instant) and potentially FieldEffectVisual (persistent) for _draw().
## Does NOT handle hit detection — that's AoeResolver's job.


func get_rect_points(origin: Vector2, direction: Vector2, length: float, width: float) -> PackedVector2Array:
	var safe_direction: Vector2 = normalize_direction_or_fallback(direction)
	var perpendicular: Vector2 = Vector2(-safe_direction.y, safe_direction.x)
	var half_width: float = maxf(0.0, width) * 0.5
	var safe_length: float = maxf(0.0, length)

	return PackedVector2Array([
		origin + perpendicular * half_width,
		origin - perpendicular * half_width,
		origin + safe_direction * safe_length - perpendicular * half_width,
		origin + safe_direction * safe_length + perpendicular * half_width,
	])


func get_sector_points(origin: Vector2, direction: Vector2, radius: float, angle_degrees: float, steps: int = 16) -> PackedVector2Array:
	var safe_radius: float = maxf(1.0, radius)
	var safe_angle: float = maxf(0.1, angle_degrees)
	var safe_steps: int = maxi(3, steps)
	var safe_direction: Vector2 = normalize_direction_or_fallback(direction)

	var half_angle: float = deg_to_rad(safe_angle * 0.5)
	var base_angle: float = safe_direction.angle()
	var start_angle: float = base_angle - half_angle
	var end_angle: float = base_angle + half_angle

	var points: PackedVector2Array = PackedVector2Array([origin])
	for i: int in range(safe_steps + 1):
		var t: float = float(i) / float(safe_steps)
		var angle: float = lerpf(start_angle, end_angle, t)
		var point: Vector2 = origin + Vector2(cos(angle), sin(angle)) * safe_radius
		points.append(point)

	return points


func get_circle_points(center: Vector2, radius: float, steps: int = 24) -> PackedVector2Array:
	var safe_radius: float = maxf(1.0, radius)
	var safe_steps: int = maxi(8, steps)

	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(safe_steps):
		var angle: float = float(i) / float(safe_steps) * TAU
		var point: Vector2 = center + Vector2(cos(angle), sin(angle)) * safe_radius
		points.append(point)

	return points


func normalize_direction_or_fallback(direction: Vector2, fallback: Vector2 = Vector2.RIGHT) -> Vector2:
	if is_zero_approx(direction.length_squared()):
		return fallback.normalized()

	return direction.normalized()
