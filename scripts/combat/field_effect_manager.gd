class_name FieldEffectManager
extends RefCounted


const AOE_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/aoe_resolver.gd")
const FIELD_EFFECT_VISUAL_SCRIPT: Script = preload("res://scripts/combat/field_effect_visual.gd")
const FIELD_TYPE_DAMAGE: String = "DAMAGE"
const FIELD_TYPE_HEAL: String = "HEAL"
const FIELD_TYPE_VISUAL_ONLY: String = "VISUAL_ONLY"

var field_root: Node = null
var fields: Array[Dictionary] = []
var next_field_id: int = 1
var aoe_resolver: Variant = AOE_RESOLVER_SCRIPT.new()


func setup(configured_field_root: Node) -> void:
	field_root = configured_field_root


func create_damage_field(
	source_unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	damage_per_tick: int
) -> int:
	if duration <= 0.0 or tick_interval <= 0.0 or radius <= 0.0 or damage_per_tick <= 0:
		return -1

	var visual: Node2D = _create_visual(center_position, radius)
	var field_id: int = next_field_id
	next_field_id += 1
	fields.append({
		"field_type": FIELD_TYPE_DAMAGE,
		"field_id": field_id,
		"source_unit": source_unit,
		"center_position": center_position,
		"radius": radius,
		"duration": duration,
		"remaining_time": duration,
		"tick_interval": tick_interval,
		"tick_timer": 0.0,
		"damage_per_tick": damage_per_tick,
		"target_team": _get_enemy_team(source_unit),
		"is_expired": false,
		"visual_node": visual,
	})
	return field_id


func create_visual_field(center_position: Vector2, radius: float, duration: float, color: Color) -> int:
	if duration <= 0.0 or radius <= 0.0:
		return -1

	var visual: Node2D = _create_visual(center_position, radius, color)
	var field_id: int = next_field_id
	next_field_id += 1
	fields.append({
		"field_type": FIELD_TYPE_VISUAL_ONLY,
		"field_id": field_id,
		"center_position": center_position,
		"radius": radius,
		"duration": duration,
		"remaining_time": duration,
		"tick_interval": 0.0,
		"tick_timer": 0.0,
		"is_expired": false,
		"visual_node": visual,
	})
	return field_id


func create_follow_visual_field(follow_unit: Variant, center_position: Vector2, radius: float, duration: float, color: Color) -> int:
	if duration <= 0.0 or radius <= 0.0:
		return -1

	var visual: Node2D = _create_visual(center_position, radius, color)
	var field_id: int = next_field_id
	next_field_id += 1
	fields.append({
		"field_type": FIELD_TYPE_VISUAL_ONLY,
		"field_id": field_id,
		"follow_unit": follow_unit,
		"center_position": center_position,
		"radius": radius,
		"duration": duration,
		"remaining_time": duration,
		"tick_interval": 0.0,
		"tick_timer": 0.0,
		"is_expired": false,
		"visual_node": visual,
	})
	return field_id


func create_heal_field(
	source_unit: Variant,
	follow_unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	heal_tick_values: Array[int],
	color: Color
) -> int:
	if duration <= 0.0 or tick_interval <= 0.0 or radius <= 0.0 or heal_tick_values.is_empty():
		return -1

	var visual: Node2D = _create_visual(center_position, radius, color)
	var field_id: int = next_field_id
	next_field_id += 1
	fields.append({
		"field_type": FIELD_TYPE_HEAL,
		"field_id": field_id,
		"source_unit": source_unit,
		"follow_unit": follow_unit,
		"center_position": center_position,
		"radius": radius,
		"duration": duration,
		"remaining_time": duration,
		"tick_interval": tick_interval,
		"tick_timer": 0.0,
		"heal_tick_values": heal_tick_values.duplicate(),
		"next_tick_index": 0,
		"target_team": _get_ally_team(source_unit),
		"is_expired": false,
		"visual_node": visual,
	})
	return field_id


func update_fields(delta: float) -> void:
	if delta <= 0.0:
		return

	for index: int in range(fields.size() - 1, -1, -1):
		var field: Dictionary = fields[index]
		if bool(field.get("is_expired", false)):
			_remove_field_at(index)
			continue

		_update_followed_field_position(field)
		field["remaining_time"] = maxf(0.0, float(field.get("remaining_time", 0.0)) - delta)
		var field_type: String = str(field.get("field_type", FIELD_TYPE_DAMAGE))
		if field_type == FIELD_TYPE_DAMAGE or field_type == FIELD_TYPE_HEAL:
			field["tick_timer"] = float(field.get("tick_timer", 0.0)) + delta
			while float(field["tick_interval"]) > 0.0 and float(field["tick_timer"]) >= float(field["tick_interval"]) and not bool(field.get("is_expired", false)):
				field["tick_timer"] = float(field["tick_timer"]) - float(field["tick_interval"])
				apply_field_tick(field)
				if fields.is_empty() or index >= fields.size():
					return

		if float(field["remaining_time"]) <= 0.0:
			field["is_expired"] = true

		fields[index] = field
		if bool(field.get("is_expired", false)):
			_remove_field_at(index)


func apply_field_tick(field: Dictionary) -> int:
	match str(field.get("field_type", FIELD_TYPE_DAMAGE)):
		FIELD_TYPE_DAMAGE:
			return _apply_damage_field_tick(field)
		FIELD_TYPE_HEAL:
			return _apply_heal_field_tick(field)
		_:
			return 0


func clear_all_fields() -> void:
	for field: Dictionary in fields:
		_free_visual(field)
	fields.clear()


func _create_visual(center_position: Vector2, radius: float, color: Color = Color(0.35, 0.95, 0.24, 0.22)) -> Node2D:
	if field_root == null or not is_instance_valid(field_root):
		return null

	var visual: Node2D = FIELD_EFFECT_VISUAL_SCRIPT.new() as Node2D
	if visual == null:
		return null

	field_root.add_child(visual)
	if visual.has_method("setup"):
		visual.setup(radius, color)
	visual.global_position = center_position
	return visual


func _get_units_in_radius_for_team(center_position: Vector2, radius: float, target_team: int) -> Array:
	var targets: Array = []
	if field_root == null or not is_instance_valid(field_root):
		return targets

	for child: Node in field_root.get_children():
		var unit: Unit = child as Unit
		if unit == null or not is_instance_valid(unit):
			continue

		if not unit.is_alive or int(unit.team_id) != target_team:
			continue

		if unit.global_position.distance_to(center_position) <= radius:
			targets.append(unit)

	return targets


func _apply_damage_field_tick(field: Dictionary) -> int:
	var source_unit: Variant = field.get("source_unit", null)
	var center_position: Vector2 = field.get("center_position", Vector2.ZERO) as Vector2
	var radius: float = float(field.get("radius", 0.0))
	var target_team: int = int(field.get("target_team", 0))
	var damage_per_tick: int = int(field.get("damage_per_tick", 0))
	if damage_per_tick <= 0:
		return 0

	var targets: Array = _get_units_in_radius_for_team(center_position, radius, target_team)
	return aoe_resolver.deal_aoe_damage(source_unit, targets, damage_per_tick, false)


func _apply_heal_field_tick(field: Dictionary) -> int:
	var source_unit: Variant = field.get("source_unit", null)
	var center_position: Vector2 = field.get("center_position", Vector2.ZERO) as Vector2
	var radius: float = float(field.get("radius", 0.0))
	var target_team: int = int(field.get("target_team", 0))
	var heal_amount: int = _take_next_heal_tick_value(field)
	if heal_amount <= 0:
		return 0

	var targets: Array = _get_units_in_radius_for_team(center_position, radius, target_team)
	return aoe_resolver.heal_aoe(source_unit, targets, heal_amount)


func _take_next_heal_tick_value(field: Dictionary) -> int:
	var tick_values: Array = field.get("heal_tick_values", []) as Array
	var next_tick_index: int = int(field.get("next_tick_index", 0))
	if next_tick_index < 0 or next_tick_index >= tick_values.size():
		field["is_expired"] = true
		return 0

	var heal_amount: int = maxi(0, int(tick_values[next_tick_index]))
	field["next_tick_index"] = next_tick_index + 1
	return heal_amount


func _update_followed_field_position(field: Dictionary) -> void:
	var follow_unit: Variant = field.get("follow_unit", null)
	if follow_unit == null:
		return

	if not is_instance_valid(follow_unit) or not bool(follow_unit.is_alive):
		field["is_expired"] = true
		return

	field["center_position"] = follow_unit.global_position
	var visual: Node2D = field.get("visual_node", null) as Node2D
	if visual != null and is_instance_valid(visual):
		visual.global_position = follow_unit.global_position


func _remove_field_at(index: int) -> void:
	if index < 0 or index >= fields.size():
		return

	var field: Dictionary = fields[index]
	_free_visual(field)
	fields.remove_at(index)


func _free_visual(field: Dictionary) -> void:
	var visual: Node = field.get("visual_node", null) as Node
	if visual != null and is_instance_valid(visual):
		visual.queue_free()


func _get_enemy_team(source_unit: Variant) -> int:
	if source_unit != null and is_instance_valid(source_unit):
		return 2 if int(source_unit.team_id) == 1 else 1

	return 0


func _get_ally_team(source_unit: Variant) -> int:
	if source_unit != null and is_instance_valid(source_unit):
		return int(source_unit.team_id)

	return 0
