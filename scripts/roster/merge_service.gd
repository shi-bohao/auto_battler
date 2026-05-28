class_name MergeService
extends RefCounted


const DEBUG_LOG_SCRIPT: Script = preload("res://scripts/debug_log.gd")


func get_unit_upgrade_target_star(
	active_roster: Array[Dictionary],
	bench_roster: Array[Dictionary],
	unit_id: String,
	incoming_star: int = 1,
	max_star: int = 3
) -> int:
	if unit_id == "":
		return 0

	var counts: Dictionary = {}
	for star_index: int in range(1, max_star + 1):
		counts[star_index] = 0

	_append_unit_star_counts(counts, active_roster, unit_id, max_star)
	_append_unit_star_counts(counts, bench_roster, unit_id, max_star)

	var safe_incoming_star: int = clampi(incoming_star, 1, max_star)
	counts[safe_incoming_star] = int(counts.get(safe_incoming_star, 0)) + 1

	var highest_created_star: int = 0
	var did_merge: bool = true
	while did_merge:
		did_merge = false
		for star_index: int in range(1, max_star):
			var unit_count: int = int(counts.get(star_index, 0))
			if unit_count < 3:
				continue

			var merge_count: int = floori(float(unit_count) / 3.0)
			counts[star_index] = unit_count - merge_count * 3
			counts[star_index + 1] = int(counts.get(star_index + 1, 0)) + merge_count
			highest_created_star = maxi(highest_created_star, star_index + 1)
			did_merge = true

	return highest_created_star


func check_auto_merge(
	active_roster: Array[Dictionary],
	bench_roster: Array[Dictionary],
	max_active_units: int,
	max_star: int,
	default_unit_price: int,
	create_roster_item_func: Callable,
	get_unit_data_name_func: Callable
) -> void:
	var did_merge: bool = true

	while did_merge:
		did_merge = false
		var unit_ids: Array[String] = _get_merge_candidate_unit_ids(active_roster, bench_roster, max_star)
		for star: int in range(1, max_star):
			for unit_id: String in unit_ids:
				if merge_units(
					active_roster,
					bench_roster,
					unit_id,
					star,
					max_active_units,
					max_star,
					default_unit_price,
					create_roster_item_func,
					get_unit_data_name_func
				):
					did_merge = true
					break
			if did_merge:
				break


func find_merge_group(
	active_roster: Array[Dictionary],
	bench_roster: Array[Dictionary],
	unit_id: String,
	star: int
) -> Array[Dictionary]:
	var group: Array[Dictionary] = []
	_collect_merge_candidates(group, active_roster, "active", unit_id, star)
	if group.size() >= 3:
		return group

	_collect_merge_candidates(group, bench_roster, "bench", unit_id, star)
	return group


func merge_units(
	active_roster: Array[Dictionary],
	bench_roster: Array[Dictionary],
	unit_id: String,
	star: int,
	max_active_units: int,
	max_star: int,
	default_unit_price: int,
	create_roster_item_func: Callable,
	get_unit_data_name_func: Callable
) -> bool:
	if star >= max_star:
		return false

	var group: Array[Dictionary] = find_merge_group(active_roster, bench_roster, unit_id, star)
	if group.size() < 3:
		return false

	var first_position: Dictionary = group[0]
	var source_item: Dictionary = _get_roster_item_from_position(active_roster, bench_roster, first_position)
	var position_source_item: Dictionary = _get_merge_position_source_item(active_roster, bench_roster, group)
	var source_data: Resource = source_item["unit_data"] as Resource
	if source_data == null or not create_roster_item_func.is_valid():
		return false

	var source_base_price: int = int(source_item.get("base_price", default_unit_price))
	var created_item: Variant = create_roster_item_func.call(source_data, star + 1, source_base_price)
	if typeof(created_item) != TYPE_DICTIONARY:
		return false

	var merged_item: Dictionary = created_item
	var should_return_to_active: bool = _group_contains_active_unit(group)
	if bool(position_source_item.get("has_saved_position", false)):
		merged_item["saved_position"] = position_source_item.get("saved_position", Vector2.ZERO)
		merged_item["has_saved_position"] = true
	if bool(position_source_item.get("has_saved_cell", false)):
		merged_item["saved_cell"] = position_source_item.get("saved_cell", Vector2i(-1, -1))
		merged_item["has_saved_cell"] = true
	merged_item["permanent_stat_bonuses"] = _merge_permanent_stat_bonuses(active_roster, bench_roster, group)

	_remove_merge_group(active_roster, bench_roster, group)
	if should_return_to_active and active_roster.size() < max_active_units:
		active_roster.append(merged_item)
	else:
		bench_roster.append(merged_item)

	DEBUG_LOG_SCRIPT.info(_get_unit_data_name(source_data, get_unit_data_name_func) + " merged to " + str(star + 1) + " star.")
	return true


func get_star_sell_count(star: int, max_star: int = 3) -> int:
	match clampi(star, 1, max_star):
		2:
			return 3
		3:
			return 9
		_:
			return 1


func _get_unit_data_name(unit_data: Resource, get_unit_data_name_func: Callable) -> String:
	if get_unit_data_name_func.is_valid():
		return str(get_unit_data_name_func.call(unit_data))

	return "Unit"


func _get_merge_candidate_unit_ids(
	active_roster: Array[Dictionary],
	bench_roster: Array[Dictionary],
	max_star: int
) -> Array[String]:
	var unit_ids: Array[String] = []
	_append_merge_candidate_unit_ids(unit_ids, active_roster, max_star)
	_append_merge_candidate_unit_ids(unit_ids, bench_roster, max_star)
	return unit_ids


func _append_merge_candidate_unit_ids(unit_ids: Array[String], roster: Array[Dictionary], max_star: int) -> void:
	for roster_item: Dictionary in roster:
		var star: int = int(roster_item.get("star", 1))
		if star >= max_star:
			continue

		var unit_id: String = str(roster_item.get("unit_id", ""))
		if unit_id != "" and not unit_ids.has(unit_id):
			unit_ids.append(unit_id)


func _append_unit_star_counts(counts: Dictionary, roster: Array[Dictionary], unit_id: String, max_star: int) -> void:
	for roster_item: Dictionary in roster:
		if str(roster_item.get("unit_id", "")) != unit_id:
			continue

		var star: int = clampi(int(roster_item.get("star", 1)), 1, max_star)
		counts[star] = int(counts.get(star, 0)) + 1


func _collect_merge_candidates(
	group: Array[Dictionary],
	roster: Array[Dictionary],
	roster_name: String,
	unit_id: String,
	star: int
) -> void:
	if group.size() >= 3:
		return

	for index: int in range(roster.size()):
		if group.size() >= 3:
			return

		var roster_item: Dictionary = roster[index]
		if str(roster_item.get("unit_id", "")) == unit_id and int(roster_item.get("star", 1)) == star:
			group.append({
				"roster": roster_name,
				"index": index,
			})


func _get_roster_item_from_position(
	active_roster: Array[Dictionary],
	bench_roster: Array[Dictionary],
	position: Dictionary
) -> Dictionary:
	var roster_name: String = str(position["roster"])
	var index: int = int(position["index"])
	if roster_name == "active":
		return active_roster[index]

	return bench_roster[index]


func _get_merge_position_source_item(
	active_roster: Array[Dictionary],
	bench_roster: Array[Dictionary],
	group: Array[Dictionary]
) -> Dictionary:
	for position: Dictionary in group:
		if str(position["roster"]) == "active":
			var active_item: Dictionary = _get_roster_item_from_position(active_roster, bench_roster, position)
			if bool(active_item.get("has_saved_position", false)):
				return active_item

	for position: Dictionary in group:
		if str(position["roster"]) == "active":
			return _get_roster_item_from_position(active_roster, bench_roster, position)

	return _get_roster_item_from_position(active_roster, bench_roster, group[0])


func _group_contains_active_unit(group: Array[Dictionary]) -> bool:
	for position: Dictionary in group:
		if str(position["roster"]) == "active":
			return true

	return false


func _merge_permanent_stat_bonuses(
	active_roster: Array[Dictionary],
	bench_roster: Array[Dictionary],
	group: Array[Dictionary]
) -> Dictionary:
	var merged_bonuses: Dictionary = {}
	for position: Dictionary in group:
		var roster_item: Dictionary = _get_roster_item_from_position(active_roster, bench_roster, position)
		var bonuses_value: Variant = roster_item.get("permanent_stat_bonuses", {})
		if not (bonuses_value is Dictionary):
			continue

		var bonuses: Dictionary = bonuses_value as Dictionary
		for stat_name_value: Variant in bonuses.keys():
			var stat_name: String = str(stat_name_value).strip_edges()
			if stat_name == "":
				continue

			merged_bonuses[stat_name] = float(merged_bonuses.get(stat_name, 0.0)) + float(bonuses.get(stat_name_value, 0.0))

	return merged_bonuses


func _remove_merge_group(
	active_roster: Array[Dictionary],
	bench_roster: Array[Dictionary],
	group: Array[Dictionary]
) -> void:
	var active_indexes: Array[int] = []
	var bench_indexes: Array[int] = []

	for position: Dictionary in group:
		if str(position["roster"]) == "active":
			active_indexes.append(int(position["index"]))
		else:
			bench_indexes.append(int(position["index"]))

	_remove_indexes_from_roster(active_roster, active_indexes)
	_remove_indexes_from_roster(bench_roster, bench_indexes)


func _remove_indexes_from_roster(roster: Array[Dictionary], indexes: Array[int]) -> void:
	indexes.sort()
	for index_position: int in range(indexes.size() - 1, -1, -1):
		var remove_index: int = indexes[index_position]
		if remove_index >= 0 and remove_index < roster.size():
			roster.remove_at(remove_index)
