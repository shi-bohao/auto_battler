class_name RosterPositionService
extends RefCounted


func get_spawn_position_for_roster_item(roster_item: Dictionary, occupied_positions: Array[Vector2], fallback_index: int) -> Vector2:
	if bool(roster_item.get("has_saved_position", false)):
		var saved_position: Vector2 = roster_item.get("saved_position", Vector2.ZERO) as Vector2
		if _is_valid_saved_position(saved_position):
			return saved_position

	var row_name: String = _get_preferred_row(roster_item)
	return _get_recommended_position(row_name, occupied_positions, fallback_index)


func _is_valid_saved_position(saved_position: Vector2) -> bool:
	return saved_position.x >= 20.0 \
		and saved_position.x <= 440.0 \
		and saved_position.y >= 80.0 \
		and saved_position.y <= 680.0


func _get_preferred_row(roster_item: Dictionary) -> String:
	var unit_id: String = str(roster_item.get("unit_id", ""))
	var unit_data: Resource = roster_item.get("unit_data", null) as Resource
	var role: String = _get_unit_role(unit_data, unit_id)

	if role == "tank":
		return "front"

	if role == "support":
		return "back"

	match unit_id:
		"warrior", "tank", "greatsword_knight":
			return "front"
		"archer", "mage", "priest", "bard", "forest_druid", "plague_caster", "wind_chanter", "bomb_thrower", "cleric", "alchemist":
			return "back"
		"guardian_captain":
			return "front"
		"assassin":
			return "middle"
		_:
			return "middle"


func _get_unit_role(unit_data: Resource, unit_id: String) -> String:
	if unit_data != null:
		var configured_role: Variant = unit_data.get("role")
		if configured_role != null and str(configured_role).strip_edges() != "":
			return str(configured_role)

	match unit_id:
		"warrior", "tank", "guardian_captain", "greatsword_knight":
			return "tank"
		"priest", "bard", "forest_druid", "wind_chanter", "cleric":
			return "support"
		_:
			return "damage"


func _get_recommended_position(row_name: String, occupied_positions: Array[Vector2], fallback_index: int) -> Vector2:
	var row_x: float = 160.0
	match row_name:
		"front":
			row_x = 220.0
		"back":
			row_x = 100.0
		_:
			row_x = 160.0

	var y_values: Array[float] = [240.0, 180.0, 300.0, 360.0, 120.0, 420.0, 480.0]
	for offset: int in range(y_values.size()):
		var y_index: int = (fallback_index + offset) % y_values.size()
		var candidate_position: Vector2 = Vector2(row_x, y_values[y_index])
		if not _is_position_occupied(candidate_position, occupied_positions):
			return candidate_position

	var extra_column: int = int(float(fallback_index) / float(y_values.size()))
	var fallback_y: float = y_values[fallback_index % y_values.size()]
	return Vector2(maxf(60.0, row_x - float(extra_column) * 36.0), fallback_y)


func _is_position_occupied(candidate_position: Vector2, occupied_positions: Array[Vector2]) -> bool:
	for occupied_position: Vector2 in occupied_positions:
		if occupied_position.distance_to(candidate_position) < 28.0:
			return true

	return false
