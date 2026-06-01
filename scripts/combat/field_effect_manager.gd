class_name FieldEffectManager
extends RefCounted


const AOE_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/aoe_resolver.gd")
const FIELD_EFFECT_VISUAL_SCRIPT: Script = preload("res://scripts/combat/field_effect_visual.gd")
const AOE_SHAPE_VISUAL_SCRIPT: Script = preload("res://scripts/combat/aoe_shape_visual.gd")
const STATUS_EFFECT_FACTORY_SCRIPT: Script = preload("res://scripts/combat/status_effect_factory.gd")
const FIELD_TYPE_DAMAGE: String = "DAMAGE"
const FIELD_TYPE_HEAL: String = "HEAL"
const FIELD_TYPE_STATUS: String = "STATUS"
const FIELD_TYPE_VISUAL_ONLY: String = "VISUAL_ONLY"
const FIELD_VISUAL_LAYER_NAME: String = "FieldEffectLayer"
const FIELD_VISUAL_LAYER_Z_INDEX: int = 3
const FIELD_VISUAL_MODE_INSTANT: String = "instant"
const FIELD_VISUAL_MODE_PERSISTENT: String = "persistent"

var field_root: Node = null
var visual_root: Node = null
var fields: Array[Dictionary] = []
var next_field_id: int = 1
var aoe_resolver: Variant = AOE_RESOLVER_SCRIPT.new()
var status_effect_factory: Variant = STATUS_EFFECT_FACTORY_SCRIPT.new()


func setup(configured_field_root: Node, configured_visual_root: Node = null) -> void:
	field_root = configured_field_root
	visual_root = configured_visual_root
	if visual_root == null or not is_instance_valid(visual_root):
		visual_root = _ensure_visual_layer(field_root)


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

	var visual: Node2D = _create_visual(center_position, radius, Color(0.35, 0.95, 0.24, 0.22), FIELD_VISUAL_MODE_PERSISTENT)
	var field_id: int = next_field_id
	next_field_id += 1
	fields.append({
		"field_type": FIELD_TYPE_DAMAGE,
		"field_id": field_id,
		"source_unit_ref": _make_unit_ref(source_unit),
		"source_team_id": _get_source_team(source_unit),
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

	var visual: Node2D = _create_visual(center_position, radius, color, FIELD_VISUAL_MODE_INSTANT)
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

	var visual: Node2D = _create_visual(center_position, radius, color, FIELD_VISUAL_MODE_INSTANT)
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

	var visual: Node2D = _create_visual(center_position, radius, color, FIELD_VISUAL_MODE_PERSISTENT)
	var field_id: int = next_field_id
	next_field_id += 1
	fields.append({
		"field_type": FIELD_TYPE_HEAL,
		"field_id": field_id,
		"source_unit_ref": _make_unit_ref(source_unit),
		"source_team_id": _get_source_team(source_unit),
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


func create_status_field(
	source_unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	status_data: Dictionary,
	color: Color
) -> int:
	if duration <= 0.0 or tick_interval <= 0.0 or radius <= 0.0 or status_data.is_empty():
		return -1

	var visual: Node2D = _create_visual(center_position, radius, color, FIELD_VISUAL_MODE_PERSISTENT)
	var field_id: int = next_field_id
	next_field_id += 1
	fields.append({
		"field_type": FIELD_TYPE_STATUS,
		"field_id": field_id,
		"source_unit_ref": _make_unit_ref(source_unit),
		"source_team_id": _get_source_team(source_unit),
		"center_position": center_position,
		"radius": radius,
		"duration": duration,
		"remaining_time": duration,
		"tick_interval": tick_interval,
		"tick_timer": tick_interval,
		"status_data": status_data.duplicate(true),
		"target_team": _get_enemy_team(source_unit),
		"is_expired": false,
		"visual_node": visual,
	})
	return field_id


func create_shape_status_field(
	source_unit: Variant,
	shape_data: Dictionary,
	duration: float,
	tick_interval: float,
	status_data: Dictionary,
	color: Color
) -> int:
	if duration <= 0.0 or tick_interval <= 0.0 or shape_data.is_empty() or status_data.is_empty():
		return -1

	var visual: Node2D = _create_shape_visual(shape_data, color, FIELD_VISUAL_MODE_PERSISTENT, duration)
	var field_id: int = next_field_id
	next_field_id += 1
	fields.append({
		"field_type": FIELD_TYPE_STATUS,
		"field_id": field_id,
		"source_unit_ref": _make_unit_ref(source_unit),
		"source_team_id": _get_source_team(source_unit),
		"shape_data": shape_data.duplicate(true),
		"duration": duration,
		"remaining_time": duration,
		"tick_interval": tick_interval,
		"tick_timer": tick_interval,
		"status_data": status_data.duplicate(true),
		"target_team": _get_enemy_team(source_unit),
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
		if field_type == FIELD_TYPE_DAMAGE or field_type == FIELD_TYPE_HEAL or field_type == FIELD_TYPE_STATUS:
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
		FIELD_TYPE_STATUS:
			return _apply_status_field_tick(field)
		_:
			return 0


func clear_all_fields() -> void:
	for field: Dictionary in fields:
		_free_visual(field)
	fields.clear()


func _create_visual(
	center_position: Vector2,
	radius: float,
	color: Color = Color(0.35, 0.95, 0.24, 0.22),
	visual_mode: String = FIELD_VISUAL_MODE_INSTANT
) -> Node2D:
	var target_parent: Node = visual_root
	if target_parent == null or not is_instance_valid(target_parent):
		target_parent = field_root
	if target_parent == null or not is_instance_valid(target_parent):
		return null

	var visual: Node2D = FIELD_EFFECT_VISUAL_SCRIPT.new() as Node2D
	if visual == null:
		return null

	target_parent.add_child(visual)
	if visual.has_method("setup"):
		visual.setup(radius, color, visual_mode)
	visual.global_position = center_position
	return visual


func _create_shape_visual(
	shape_data: Dictionary,
	color: Color,
	visual_mode: String = FIELD_VISUAL_MODE_INSTANT,
	duration: float = 0.25
) -> Node2D:
	var target_parent: Node = visual_root
	if target_parent == null or not is_instance_valid(target_parent):
		target_parent = field_root
	if target_parent == null or not is_instance_valid(target_parent):
		return null

	var visual: Node2D = AOE_SHAPE_VISUAL_SCRIPT.new() as Node2D
	if visual == null:
		return null

	target_parent.add_child(visual)
	var configured_shape: Dictionary = shape_data.duplicate(true)
	var shape_type: String = str(configured_shape.get("shape_type", "circle"))
	var anchor: Vector2 = Vector2.ZERO
	if shape_type == "circle":
		anchor = configured_shape.get("center", Vector2.ZERO) as Vector2
	else:
		anchor = configured_shape.get("origin", Vector2.ZERO) as Vector2
	visual.global_position = anchor
	if visual.has_method("setup"):
		visual.setup(configured_shape, color, duration, 1.0)
	return visual


func _ensure_visual_layer(root: Node) -> Node:
	if root == null or not is_instance_valid(root):
		return null

	var existing_layer: Node = root.get_node_or_null(FIELD_VISUAL_LAYER_NAME)
	if existing_layer != null:
		return existing_layer

	var layer: Node2D = Node2D.new()
	layer.name = FIELD_VISUAL_LAYER_NAME
	layer.z_as_relative = false
	layer.z_index = FIELD_VISUAL_LAYER_Z_INDEX
	root.add_child(layer)
	return layer


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


func _get_units_for_field(field: Dictionary) -> Array:
	var targets: Array = []
	if field_root == null or not is_instance_valid(field_root):
		return targets

	var target_team: int = int(field.get("target_team", 0))
	var has_shape: bool = field.has("shape_data")
	var shape_data: Dictionary = field.get("shape_data", {}) as Dictionary
	var center_position: Vector2 = field.get("center_position", Vector2.ZERO) as Vector2
	var radius: float = float(field.get("radius", 0.0))
	for child: Node in field_root.get_children():
		var unit: Unit = child as Unit
		if unit == null or not is_instance_valid(unit):
			continue
		if not unit.is_alive or int(unit.team_id) != target_team:
			continue
		if has_shape:
			if aoe_resolver.is_point_in_shape(unit.global_position, shape_data):
				targets.append(unit)
		elif unit.global_position.distance_to(center_position) <= radius:
			targets.append(unit)

	return targets


func _apply_damage_field_tick(field: Dictionary) -> int:
	var source_unit: Variant = _get_effect_source(field)
	var center_position: Vector2 = field.get("center_position", Vector2.ZERO) as Vector2
	var radius: float = float(field.get("radius", 0.0))
	var target_team: int = int(field.get("target_team", 0))
	var damage_per_tick: int = int(field.get("damage_per_tick", 0))
	if damage_per_tick <= 0:
		return 0

	var targets: Array = _get_units_for_field(field)
	return aoe_resolver.deal_aoe_damage(source_unit, targets, damage_per_tick, false)


func _apply_heal_field_tick(field: Dictionary) -> int:
	var source_unit: Variant = _get_effect_source(field)
	var center_position: Vector2 = field.get("center_position", Vector2.ZERO) as Vector2
	var radius: float = float(field.get("radius", 0.0))
	var target_team: int = int(field.get("target_team", 0))
	var heal_amount: int = _take_next_heal_tick_value(field)
	if heal_amount <= 0:
		return 0

	var targets: Array = _get_units_for_field(field)
	return aoe_resolver.heal_aoe(source_unit, targets, heal_amount)


func _apply_status_field_tick(field: Dictionary) -> int:
	var source_unit: Variant = _get_effect_source(field)
	var status_data: Dictionary = field.get("status_data", {}) as Dictionary
	if status_data.is_empty():
		return 0

	var applied_count: int = 0
	var targets: Array = _get_units_for_field(field)
	for target_value: Variant in targets:
		var target: Variant = target_value
		if _apply_status_data_to_target(source_unit, target, status_data):
			applied_count += 1

	return applied_count


func _apply_status_data_to_target(source_unit: Variant, target: Variant, status_data: Dictionary) -> bool:
	if target == null or not is_instance_valid(target) or not bool(target.is_alive):
		return false

	var damage_per_tick: int = int(status_data.get("damage_per_tick", 0))
	if damage_per_tick > 0:
		var was_alive: bool = bool(target.is_alive)
		target.take_damage(damage_per_tick, source_unit, false)
		if was_alive and (target == null or not is_instance_valid(target) or not bool(target.is_alive)):
			if status_data.has("kill_bonus") and _is_valid_alive_source(source_unit) and source_unit.unit_skill != null and source_unit.unit_skill.has_method("apply_corpse_devour_bonus"):
				source_unit.unit_skill.apply_corpse_devour_bonus(source_unit)
			return true

	var mode: String = str(status_data.get("mode", "status"))
	match mode:
		"control":
			var control_type: String = str(status_data.get("control_type", "SLOW"))
			var control_duration: float = float(status_data.get("duration", 0.0))
			var control_options: Dictionary = status_data.get("options", {}) as Dictionary
			return status_effect_factory.apply_control_effect(target, control_type, source_unit, control_duration, control_options) != null
		"burning":
			var burn_duration: float = float(status_data.get("duration", 0.0))
			var damage_per_second: float = float(status_data.get("damage_per_second", status_data.get("value", 0.0)))
			var burn_options: Dictionary = status_data.get("options", {}) as Dictionary
			return status_effect_factory.apply_burning(target, source_unit, burn_duration, damage_per_second, burn_options) != null
		_:
			var effect_id: String = str(status_data.get("effect_id", ""))
			var effect_type: String = str(status_data.get("effect_type", ""))
			if effect_id == "" or effect_type == "":
				return false
			var status_duration: float = float(status_data.get("duration", 0.0))
			var tick_interval: float = float(status_data.get("tick_interval", 0.0))
			var value: float = float(status_data.get("value", 0.0))
			var stat_name: String = str(status_data.get("stat_name", ""))
			var status_options: Dictionary = status_data.get("options", {}) as Dictionary
			return status_effect_factory.apply_status_effect(target, effect_id, effect_type, source_unit, status_duration, tick_interval, value, stat_name, status_options) != null


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
	var source_team: int = _get_source_team(source_unit)
	if source_team != 0:
		return 2 if source_team == 1 else 1

	return 0


func _get_ally_team(source_unit: Variant) -> int:
	return _get_source_team(source_unit)


func _get_source_team(source_unit: Variant) -> int:
	if source_unit != null and is_instance_valid(source_unit):
		return int(source_unit.team_id)

	return 0


func _get_effect_source(field: Dictionary) -> Variant:
	var source_ref: WeakRef = field.get("source_unit_ref", null) as WeakRef
	if source_ref != null:
		var referenced_unit: Variant = source_ref.get_ref()
		if referenced_unit != null and is_instance_valid(referenced_unit) and bool(referenced_unit.is_alive):
			return referenced_unit

	var source_unit: Variant = field.get("source_unit", null)
	if source_unit != null and is_instance_valid(source_unit) and bool(source_unit.is_alive):
		return source_unit

	field["source_unit"] = null
	return null


func _make_unit_ref(unit: Variant) -> WeakRef:
	if unit != null and is_instance_valid(unit):
		return weakref(unit)

	return null


func _is_valid_alive_source(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit) and bool(unit.is_alive)
