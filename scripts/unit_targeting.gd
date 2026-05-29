class_name UnitTargeting
extends RefCounted

const TARGET_MODE_NEAREST: int = 0
const TARGET_MODE_LOWEST_HP: int = 1
const ATTACK_RANGE_TOLERANCE: float = 4.0


func update_targeting(unit: Variant, delta: float) -> void:
	if not _is_valid_unit(unit):
		return

	var forced_target: Variant = _get_forced_target(unit)
	if forced_target != null:
		if unit.current_target != forced_target:
			unit.current_target = forced_target
			unit.target_search_timer = unit.target_search_interval
			unit.retarget_timer = unit.retarget_interval
		return

	if not is_valid_target(unit, unit.current_target):
		unit.current_target = null
		unit.target_search_timer = 0.0

	if unit.current_target == null:
		unit.target_search_timer = maxf(unit.target_search_timer - delta, 0.0)
		if unit.target_search_timer <= 0.0:
			unit.current_target = find_target(unit)
			unit.target_search_timer = unit.target_search_interval
		return

	if get_target_mode(unit) == TARGET_MODE_LOWEST_HP:
		unit.retarget_timer = maxf(unit.retarget_timer - delta, 0.0)
		if unit.retarget_timer <= 0.0:
			try_retarget_lowest_hp(unit)
			unit.retarget_timer = unit.retarget_interval


func check_targeting_stuck(unit: Variant, delta: float) -> void:
	if not _is_valid_unit(unit):
		return

	if unit.current_target == null:
		unit.last_ai_position = unit.global_position
		unit.last_attack_count = unit.attack_count
		unit.stuck_check_timer = 0.5
		return

	if unit.control_state != null and unit.control_state.is_taunted:
		if unit.control_state.get_valid_forced_target(unit) != null:
			unit.last_ai_position = unit.global_position
			unit.last_attack_count = unit.attack_count
			unit.stuck_check_timer = 0.5
			return

	unit.stuck_check_timer = maxf(unit.stuck_check_timer - delta, 0.0)
	if unit.stuck_check_timer > 0.0:
		return

	var moved_distance: float = unit.global_position.distance_to(unit.last_ai_position)
	var did_attack: bool = unit.attack_count != unit.last_attack_count
	if not did_attack and moved_distance < 0.5 and not is_current_target_in_range(unit):
		unit.current_target = null
		unit.target_search_timer = 0.0

	unit.last_ai_position = unit.global_position
	unit.last_attack_count = unit.attack_count
	unit.stuck_check_timer = 0.5


func find_target(unit: Variant) -> Variant:
	var forced: Variant = _get_forced_target(unit)
	if forced != null:
		return forced
	var candidates: Array = get_valid_targets(unit)
	if candidates.is_empty():
		return null

	match get_target_mode(unit):
		TARGET_MODE_LOWEST_HP:
			return find_lowest_hp_target(unit, candidates)
		_:
			return find_nearest_target(unit, candidates)


func get_valid_targets(unit: Variant) -> Array:
	var candidates: Array = []
	if not _is_valid_unit(unit):
		return candidates

	for enemy in unit.enemy_units:
		if is_valid_target(unit, enemy):
			candidates.append(enemy)

	return candidates


func find_nearest_target(unit: Variant, candidates: Array) -> Variant:
	var best_target: Variant = null
	var best_distance: float = INF
	var best_hp: int = 2147483647
	var best_unit_id: int = 2147483647

	for target in candidates:
		var distance: float = get_distance_to_target(unit, target)
		if is_better_nearest_target(target, distance, best_target, best_distance, best_hp, best_unit_id):
			best_target = target
			best_distance = distance
			best_hp = int(target.hp)
			best_unit_id = int(target.unit_id)

	return best_target


func find_lowest_hp_target(unit: Variant, candidates: Array) -> Variant:
	var best_target: Variant = null
	var best_hp_ratio: float = INF
	var best_hp: int = 2147483647
	var best_distance: float = INF
	var best_unit_id: int = 2147483647

	for target in candidates:
		var hp_ratio: float = get_hp_ratio(target)
		var distance: float = get_distance_to_target(unit, target)
		if is_better_lowest_hp_target(target, hp_ratio, distance, best_target, best_hp_ratio, best_hp, best_distance, best_unit_id):
			best_target = target
			best_hp_ratio = hp_ratio
			best_hp = int(target.hp)
			best_distance = distance
			best_unit_id = int(target.unit_id)

	return best_target


func try_retarget_lowest_hp(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	if unit.control_state != null and not unit.control_state.can_retarget:
		return

	if not is_valid_target(unit, unit.current_target):
		unit.current_target = find_target(unit)
		return

	var new_target: Variant = find_target(unit)
	if new_target == null or new_target == unit.current_target:
		return

	var current_ratio: float = get_hp_ratio(unit.current_target)
	var new_ratio: float = get_hp_ratio(new_target)
	if new_ratio + unit.lowest_hp_switch_threshold < current_ratio:
		unit.current_target = new_target


func is_valid_target(unit: Variant, target: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	if target == null or not is_instance_valid(target):
		return false

	if not (target is Node2D):
		return false

	if not target.is_alive:
		return false

	if target.team_id == unit.team_id:
		return false

	if not target.is_targetable:
		return false

	return get_distance_to_target(unit, target) <= unit.search_range


func get_target_mode(unit: Variant) -> int:
	if not _is_valid_unit(unit):
		return TARGET_MODE_NEAREST

	var normalized_mode: String = unit.target_mode.to_upper()
	if normalized_mode == "LOWEST_HP":
		return TARGET_MODE_LOWEST_HP

	return TARGET_MODE_NEAREST


func get_distance_to_target(unit: Variant, target: Variant) -> float:
	return unit.global_position.distance_to(target.global_position)


func get_hp_ratio(target: Variant) -> float:
	if target.max_hp <= 0:
		return 1.0

	return float(target.hp) / float(target.max_hp)


func is_better_nearest_target(
		target: Variant,
		distance: float,
		best_target: Variant,
		best_distance: float,
		best_hp: int,
		best_unit_id: int
) -> bool:
	if best_target == null:
		return true

	if distance < best_distance:
		return true

	if is_equal_approx(distance, best_distance) and target.hp < best_hp:
		return true

	if is_equal_approx(distance, best_distance) and target.hp == best_hp and target.unit_id < best_unit_id:
		return true

	return false


func is_better_lowest_hp_target(
		target: Variant,
		hp_ratio: float,
		distance: float,
		best_target: Variant,
		best_hp_ratio: float,
		best_hp: int,
		best_distance: float,
		best_unit_id: int
) -> bool:
	if best_target == null:
		return true

	if hp_ratio < best_hp_ratio:
		return true

	if is_equal_approx(hp_ratio, best_hp_ratio) and target.hp < best_hp:
		return true

	if is_equal_approx(hp_ratio, best_hp_ratio) and target.hp == best_hp and distance < best_distance:
		return true

	if is_equal_approx(hp_ratio, best_hp_ratio) and target.hp == best_hp and is_equal_approx(distance, best_distance) and target.unit_id < best_unit_id:
		return true

	return false


func move_toward_current_target(unit: Variant, delta: float) -> void:
	if not _is_valid_unit(unit):
		return

	if unit.control_state != null and not unit.control_state.can_move:
		return

	if not is_valid_target(unit, unit.current_target):
		return

	if is_current_target_in_range(unit):
		return

	var speed_multiplier: float = unit.control_state.move_speed_multiplier if unit.control_state != null else 1.0
	var distance: float = unit.global_position.distance_to(unit.current_target.global_position)
	var direction: Vector2 = unit.global_position.direction_to(unit.current_target.global_position)
	var desired_distance: float = maxf(unit.attack_range - ATTACK_RANGE_TOLERANCE, 0.0)
	var move_distance: float = minf(unit.move_speed * speed_multiplier * delta, distance - desired_distance)
	unit.global_position += direction * move_distance


func is_current_target_in_range(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	return is_target_in_range(unit, unit.current_target)


func is_target_in_range(unit: Variant, target: Variant) -> bool:
	if not is_valid_target(unit, target):
		return false

	return get_distance_to_target(unit, target) <= unit.attack_range + ATTACK_RANGE_TOLERANCE


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)


func _get_forced_target(unit: Variant) -> Variant:
	if not _is_valid_unit(unit) or unit.control_state == null:
		return null

	var forced: Variant = unit.control_state.get_valid_forced_target(unit)
	if forced != null:
		return forced

	if unit.control_state.is_taunted and unit.has_method("rebuild_control_state"):
		unit.rebuild_control_state()
		return unit.control_state.get_valid_forced_target(unit)

	return null
