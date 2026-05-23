extends RefCounted

## AoE unit selection and damage/healing application.
## New: get_units_in_shape() supports circle, rect, sector via shape_data.
## Old get_units_in_radius() is preserved as a compatibility wrapper.


# -- Public: shape-based queries --------------------------------------------------

func get_units_in_shape(units: Array, shape_data: Dictionary, excluded_units: Array = []) -> Array:
	var shape_type: String = str(shape_data.get("shape_type", "circle"))
	var targets: Array = []

	for unit_value: Variant in units:
		var unit: Variant = unit_value
		if not _is_valid_alive_unit(unit):
			continue
		if excluded_units.has(unit):
			continue
		if is_point_in_shape(unit.global_position, shape_data):
			targets.append(unit)

	return targets


func get_enemy_units_in_shape(source_unit: Variant, shape_data: Dictionary, excluded_units: Array = []) -> Array:
	if not _is_valid_unit(source_unit):
		return []
	return get_units_in_shape(source_unit.enemy_units, shape_data, excluded_units)


func get_ally_units_in_shape(source_unit: Variant, shape_data: Dictionary, excluded_units: Array = []) -> Array:
	if not _is_valid_unit(source_unit):
		return []
	return get_units_in_shape(source_unit.ally_units, shape_data, excluded_units)


# -- Public: point-in-shape dispatch ---------------------------------------------

func is_point_in_shape(point: Vector2, shape_data: Dictionary) -> bool:
	var shape_type: String = str(shape_data.get("shape_type", "circle"))
	match shape_type:
		"rect":
			return is_point_in_rect(point, shape_data)
		"sector":
			return is_point_in_sector(point, shape_data)
		_:
			return is_point_in_circle(point, shape_data)


func is_point_in_circle(point: Vector2, shape_data: Dictionary) -> bool:
	var center: Vector2 = shape_data.get("center", Vector2.ZERO) as Vector2
	var radius: float = maxf(0.0, float(shape_data.get("radius", 0.0)))
	return point.distance_squared_to(center) <= radius * radius


func is_point_in_rect(point: Vector2, shape_data: Dictionary) -> bool:
	var origin: Vector2 = shape_data.get("origin", Vector2.ZERO) as Vector2
	var direction: Vector2 = shape_data.get("direction", Vector2.RIGHT) as Vector2
	var length: float = maxf(0.0, float(shape_data.get("length", 0.0)))
	var width: float = maxf(0.0, float(shape_data.get("width", 0.0)))
	var anchor: String = str(shape_data.get("anchor", "forward"))

	if length <= 0.0 or width <= 0.0:
		return false

	var safe_direction: Vector2 = direction
	if is_zero_approx(safe_direction.length_squared()):
		safe_direction = Vector2.RIGHT
	safe_direction = safe_direction.normalized()

	var perpendicular: Vector2 = Vector2(-safe_direction.y, safe_direction.x)
	var to_point: Vector2 = point - origin
	var forward_dist: float = to_point.dot(safe_direction)
	var side_dist: float = to_point.dot(perpendicular)
	var half_width: float = width * 0.5

	if anchor == "forward":
		return forward_dist >= 0.0 and forward_dist <= length and absf(side_dist) <= half_width
	else:
		# "center" anchor: rect centered on origin
		var half_length: float = length * 0.5
		return absf(forward_dist) <= half_length and absf(side_dist) <= half_width


func is_point_in_sector(point: Vector2, shape_data: Dictionary) -> bool:
	var origin: Vector2 = shape_data.get("origin", Vector2.ZERO) as Vector2
	var direction: Vector2 = shape_data.get("direction", Vector2.RIGHT) as Vector2
	var radius: float = maxf(0.0, float(shape_data.get("radius", 0.0)))
	var angle_degrees: float = maxf(0.1, float(shape_data.get("angle_degrees", 90.0)))

	if radius <= 0.0:
		return false

	var to_point: Vector2 = point - origin
	var distance_sq: float = to_point.length_squared()

	if distance_sq <= 0.0:
		return true  # point is at origin, considered inside

	if distance_sq > radius * radius:
		return false

	var safe_direction: Vector2 = direction
	if is_zero_approx(safe_direction.length_squared()):
		safe_direction = Vector2.RIGHT
	safe_direction = safe_direction.normalized()

	var half_angle: float = deg_to_rad(angle_degrees * 0.5)
	var angle_to_point: float = to_point.angle()
	var angle_diff: float = absf(angle_difference(safe_direction.angle(), angle_to_point))
	return angle_diff <= half_angle + 0.0001


# -- Legacy: radius-based queries (compatibility wrappers) ------------------------

func get_enemy_units_in_radius(source_unit: Variant, center_position: Vector2, radius: float, excluded_units: Array = []) -> Array:
	if not _is_valid_unit(source_unit):
		return []
	return get_units_in_radius(source_unit.enemy_units, center_position, radius, excluded_units)


func get_ally_units_in_radius(source_unit: Variant, center_position: Vector2, radius: float, excluded_units: Array = []) -> Array:
	if not _is_valid_unit(source_unit):
		return []
	return get_units_in_radius(source_unit.ally_units, center_position, radius, excluded_units)


func get_units_in_radius(units: Array, center_position: Vector2, radius: float, excluded_units: Array = []) -> Array:
	return get_units_in_shape(units, {
		"shape_type": "circle",
		"center": center_position,
		"radius": radius,
	}, excluded_units)


# -- Damage / healing application ------------------------------------------------

func deal_aoe_damage(source_unit: Variant, targets: Array, damage: int, can_crit: bool = true) -> int:
	if damage <= 0:
		return 0

	var valid_source_unit: Variant = _get_valid_unit_or_null(source_unit)
	var hit_count: int = 0
	for target_value: Variant in targets:
		var target: Variant = target_value
		if not _is_valid_alive_unit(target):
			continue

		if valid_source_unit != null and int(target.team_id) == int(valid_source_unit.team_id):
			continue

		var actual_damage: int = int(target.take_damage(damage, valid_source_unit, can_crit))
		if actual_damage > 0:
			hit_count += 1

	return hit_count


func heal_aoe(source_unit: Variant, targets: Array, heal_amount: int) -> int:
	if heal_amount <= 0:
		return 0

	var valid_source_unit: Variant = _get_valid_unit_or_null(source_unit)
	var healed_count: int = 0
	for target_value: Variant in targets:
		var target: Variant = target_value
		if not _is_valid_alive_unit(target):
			continue

		if valid_source_unit != null and int(target.team_id) != int(valid_source_unit.team_id):
			continue

		var old_hp: int = int(target.hp)
		target.heal(heal_amount, valid_source_unit)
		if int(target.hp) > old_hp:
			healed_count += 1

	return healed_count


# -- Internal helpers ------------------------------------------------------------

func _is_valid_alive_unit(unit: Variant) -> bool:
	return _is_valid_unit(unit) and bool(unit.is_alive)


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)


func _get_valid_unit_or_null(unit: Variant) -> Variant:
	if _is_valid_unit(unit):
		return unit
	return null
