class_name EnemyPositionService
extends RefCounted

const ROLE_TANK: String = "tank"
const FRONT_X: float = 760.0
const MIDDLE_X: float = 820.0
const BACK_X: float = 880.0
const ENEMY_ID_ELITE_SHADOW_REAPER: String = "enemy_elite_shadow_reaper"


func assign_enemy_positions(units: Array[Dictionary], get_unit_role_func: Callable) -> void:
	var lane_counts: Dictionary = {
		"front": 0,
		"middle": 0,
		"back": 0,
	}

	for index: int in range(units.size()):
		var enemy_unit: Dictionary = units[index]
		if bool(enemy_unit.get("is_boss", false)):
			enemy_unit["position"] = Vector2(FRONT_X, 240.0)
			lane_counts["front"] = int(lane_counts["front"]) + 1
			units[index] = enemy_unit
			continue

		var lane: String = get_lane_for_unit(str(enemy_unit["unit_id"]), get_unit_role_func)
		var lane_index: int = int(lane_counts[lane])
		enemy_unit["position"] = get_position_for_lane(lane, lane_index)
		lane_counts[lane] = lane_index + 1
		units[index] = enemy_unit


func get_lane_for_unit(unit_id: String, get_unit_role_func: Callable) -> String:
	if get_unit_role_func.is_valid() and str(get_unit_role_func.call(unit_id)) == ROLE_TANK:
		return "front"

	if unit_id == ENEMY_ID_ELITE_SHADOW_REAPER:
		return "middle"

	return "back"


func get_position_for_lane(lane: String, index: int) -> Vector2:
	var y_values: Array[float] = [240.0, 200.0, 280.0, 160.0, 320.0, 360.0]
	var y: float = y_values[index % y_values.size()]
	match lane:
		"front":
			return Vector2(FRONT_X, y)
		"middle":
			return Vector2(MIDDLE_X, y)
		_:
			return Vector2(BACK_X, y)
