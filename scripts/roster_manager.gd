class_name RosterManager
extends RefCounted

const DEBUG_LOG_SCRIPT: Script = preload("res://scripts/debug_log.gd")
const UNIT_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/unit_catalog.gd")
const UNIT_SCALING_SERVICE_SCRIPT: Script = preload("res://scripts/roster/unit_scaling_service.gd")
const ROSTER_POSITION_SERVICE_SCRIPT: Script = preload("res://scripts/roster/roster_position_service.gd")
const MERGE_SERVICE_SCRIPT: Script = preload("res://scripts/roster/merge_service.gd")

const MAX_STAR: int = 3
const DEFAULT_UNIT_PRICE: int = 2
const PERMANENT_STAT_BONUSES_KEY: String = "permanent_stat_bonuses"

var active_roster: Array[Dictionary] = []
var bench_roster: Array[Dictionary] = []
var max_active_units: int = 10
var max_total_units: int = 25
var max_bench_units: int = 15
var player_hp_multiplier: float = 1.0
var player_attack_multiplier: float = 1.0
var global_stat_bonuses: Dictionary = {}
var has_death_prevention: bool = false
var next_roster_id: int = 1
var unlocked_unit_ids: Array[String] = []
var selected_hero_id: String = ""
var selected_hero_exclusive_unit_ids: Array[String] = []
var all_hero_exclusive_unit_ids: Array[String] = []
var unit_catalog: Variant = UNIT_CATALOG_SCRIPT.new()
var unit_scaling_service: Variant = UNIT_SCALING_SERVICE_SCRIPT.new()
var roster_position_service: Variant = ROSTER_POSITION_SERVICE_SCRIPT.new()
var merge_service: Variant = MERGE_SERVICE_SCRIPT.new()


func setup(
	configured_warrior_data: Resource,
	configured_archer_data: Resource,
	configured_assassin_data: Resource,
	configured_tank_data: Resource = null,
	configured_mage_data: Resource = null,
	configured_priest_data: Resource = null,
	configured_bard_data: Resource = null,
	configured_forest_druid_data: Resource = null,
	configured_plague_caster_data: Resource = null,
	configured_guardian_captain_data: Resource = null,
	configured_wind_chanter_data: Resource = null,
	configured_greatsword_knight_data: Resource = null,
	configured_bomb_thrower_data: Resource = null,
	configured_cleric_data: Resource = null,
	configured_alchemist_data: Resource = null,
	configured_necromancer_data: Resource = null,
	configured_puppet_warlock_data: Resource = null
) -> void:
	unit_catalog.setup(
		configured_warrior_data,
		configured_archer_data,
		configured_assassin_data,
		configured_tank_data,
		configured_mage_data,
		configured_priest_data,
		configured_bard_data,
		configured_forest_druid_data,
		configured_plague_caster_data,
		configured_guardian_captain_data,
		configured_wind_chanter_data,
		configured_greatsword_knight_data,
		configured_bomb_thrower_data,
		configured_cleric_data,
		configured_alchemist_data,
		configured_necromancer_data,
		configured_puppet_warlock_data
	)


func reset_roster() -> void:
	clear_hero_exclusive_unit_pool()
	_reset_roster_state()
	var warrior_data: Resource = get_unit_data_by_id("warrior")
	var archer_data: Resource = get_unit_data_by_id("archer")
	var assassin_data: Resource = get_unit_data_by_id("assassin")
	_add_starter_unit_data(warrior_data)
	_add_starter_unit_data(archer_data)
	_add_starter_unit_data(assassin_data)


func clear_hero_exclusive_unit_pool() -> void:
	selected_hero_id = ""
	selected_hero_exclusive_unit_ids.clear()
	all_hero_exclusive_unit_ids.clear()


func configure_hero_exclusive_unit_pool(hero_id: String, selected_exclusive_ids: Array[String], all_exclusive_ids: Array[String]) -> void:
	selected_hero_id = hero_id
	selected_hero_exclusive_unit_ids = _deduplicate_unit_ids(selected_exclusive_ids)
	all_hero_exclusive_unit_ids = _deduplicate_unit_ids(all_exclusive_ids)


func start_roster_for_hero(starter_exclusive_unit_ids: Array[String], random_common_count: int = 1) -> void:
	_reset_roster_state()
	for starter_unit_id: String in starter_exclusive_unit_ids:
		_add_starter_unit_by_id(starter_unit_id)

	var excluded_random_ids: Array[String] = []
	for unit_id: String in starter_exclusive_unit_ids:
		if not excluded_random_ids.has(unit_id):
			excluded_random_ids.append(unit_id)
	for _index: int in range(maxi(0, random_common_count)):
		var random_common_data: Resource = _get_random_common_starter_unit(excluded_random_ids)
		if random_common_data == null:
			continue
		var random_unit_id: String = get_unit_id(random_common_data)
		if random_unit_id != "" and not excluded_random_ids.has(random_unit_id):
			excluded_random_ids.append(random_unit_id)
		_add_starter_unit_data(random_common_data)


func apply_team_hp_bonus(percent: float) -> void:
	player_hp_multiplier *= 1.0 + percent
	DEBUG_LOG_SCRIPT.info("Player team HP multiplier: " + str(player_hp_multiplier))


func apply_team_attack_bonus(percent: float) -> void:
	player_attack_multiplier *= 1.0 + percent
	DEBUG_LOG_SCRIPT.info("Player team attack multiplier: " + str(player_attack_multiplier))


func apply_permanent_percent_bonus(stat: String, ratio: float) -> void:
	if stat == "":
		return
	var key: String = stat + "_percent"
	global_stat_bonuses[key] = float(global_stat_bonuses.get(key, 0.0)) + ratio


func apply_permanent_flat_bonus(stat: String, amount: float) -> void:
	if stat == "":
		return
	var key: String = stat + "_flat"
	global_stat_bonuses[key] = float(global_stat_bonuses.get(key, 0.0)) + amount


func get_global_stat_bonuses() -> Dictionary:
	return global_stat_bonuses


func add_random_unit() -> bool:
	var unit_pool: Array[Resource] = _get_unit_data_pool()
	if unit_pool.is_empty():
		return false

	var random_index: int = randi_range(0, unit_pool.size() - 1)
	var selected_unit_data: Resource = unit_pool[random_index]
	return add_unit(selected_unit_data)


func add_unit_by_id(unit_id: String) -> bool:
	if not is_unit_id_available_for_run(unit_id):
		DEBUG_LOG_SCRIPT.info("Unit is not available for selected hero: " + unit_id)
		return false

	var unit_data: Resource = get_unit_data_by_id(unit_id)
	if unit_data == null:
		push_warning("Unknown unit id: " + unit_id)
		return false

	return add_unit(unit_data)


func add_unit(unit_data: Resource, base_price: int = -1) -> bool:
	if unit_data == null:
		return false

	if not is_unit_available_for_run(unit_data):
		DEBUG_LOG_SCRIPT.info("Cannot add unit: not available for selected hero.")
		return false

	if not can_add_unit():
		DEBUG_LOG_SCRIPT.info("Cannot add unit: roster is full.")
		return false

	var roster_item: Dictionary = create_roster_item(unit_data, 1, base_price)
	if get_active_count() < max_active_units:
		active_roster.append(roster_item)
		DEBUG_LOG_SCRIPT.info("Added active unit: " + get_unit_display_name_with_star(roster_item))
	else:
		if get_bench_count() >= max_bench_units:
			DEBUG_LOG_SCRIPT.info("Cannot add unit: bench is full.")
			return false
		bench_roster.append(roster_item)
		DEBUG_LOG_SCRIPT.info("Added bench unit: " + get_unit_display_name_with_star(roster_item))

	unlock_unit_data(unit_data)
	check_auto_merge()
	return true


func can_add_unit() -> bool:
	return get_total_unit_count() < max_total_units


func get_total_unit_count() -> int:
	return active_roster.size() + bench_roster.size()


func get_active_count() -> int:
	return active_roster.size()


func get_bench_count() -> int:
	return bench_roster.size()


func move_bench_to_active(index: int) -> bool:
	if index < 0 or index >= bench_roster.size():
		return false

	if get_active_count() >= max_active_units:
		DEBUG_LOG_SCRIPT.info("Cannot move unit to active: active roster is full.")
		return false

	var roster_item: Dictionary = bench_roster[index]
	bench_roster.remove_at(index)
	active_roster.append(roster_item)
	DEBUG_LOG_SCRIPT.info("Moved to active: " + get_unit_display_name_with_star(roster_item))
	return true


func move_active_to_bench(index: int) -> bool:
	if index < 0 or index >= active_roster.size():
		return false

	if get_bench_count() >= max_bench_units:
		DEBUG_LOG_SCRIPT.info("Cannot move unit to bench: bench is full.")
		return false

	var roster_item: Dictionary = active_roster[index]
	active_roster.remove_at(index)
	bench_roster.append(roster_item)
	DEBUG_LOG_SCRIPT.info("Moved to bench: " + get_unit_display_name_with_star(roster_item))
	return true


func move_bench_to_active_by_id(roster_id: int) -> bool:
	var bench_index: int = _get_roster_index_by_id(bench_roster, roster_id)
	return move_bench_to_active(bench_index)


func move_active_to_bench_by_id(roster_id: int) -> bool:
	var active_index: int = _get_roster_index_by_id(active_roster, roster_id)
	return move_active_to_bench(active_index)


func sell_active_unit(index: int) -> int:
	if index < 0 or index >= active_roster.size():
		return 0

	var roster_item: Dictionary = active_roster[index]
	var sell_price: int = get_sell_price(roster_item)
	active_roster.remove_at(index)
	DEBUG_LOG_SCRIPT.info("Sold active unit: " + get_unit_display_name_with_star(roster_item) + " for " + str(sell_price) + " gold.")
	return sell_price


func sell_bench_unit(index: int) -> int:
	if index < 0 or index >= bench_roster.size():
		return 0

	var roster_item: Dictionary = bench_roster[index]
	var sell_price: int = get_sell_price(roster_item)
	bench_roster.remove_at(index)
	DEBUG_LOG_SCRIPT.info("Sold bench unit: " + get_unit_display_name_with_star(roster_item) + " for " + str(sell_price) + " gold.")
	return sell_price


func sell_active_unit_by_id(roster_id: int) -> int:
	return sell_active_unit(_get_roster_index_by_id(active_roster, roster_id))


func sell_bench_unit_by_id(roster_id: int) -> int:
	return sell_bench_unit(_get_roster_index_by_id(bench_roster, roster_id))


func get_sell_price(roster_item: Dictionary) -> int:
	var base_price: int = int(roster_item.get("base_price", DEFAULT_UNIT_PRICE))
	var star: int = int(roster_item.get("star", 1))
	return maxi(0, base_price) * _get_star_sell_count(star)


func get_active_roster() -> Array[Dictionary]:
	var roster: Array[Dictionary] = []
	for roster_item: Dictionary in active_roster:
		roster.append(roster_item.duplicate(true))
	return roster


func get_bench_roster() -> Array[Dictionary]:
	var roster: Array[Dictionary] = []
	for roster_item: Dictionary in bench_roster:
		roster.append(roster_item.duplicate(true))
	return roster


func add_permanent_stat_bonus_by_roster_id(roster_id: int, stat_name: String, amount: float) -> bool:
	if roster_id <= 0 or stat_name.strip_edges() == "" or is_zero_approx(amount):
		return false

	if _add_permanent_stat_bonus_to_roster(active_roster, roster_id, stat_name, amount):
		return true

	return _add_permanent_stat_bonus_to_roster(bench_roster, roster_id, stat_name, amount)


func set_unit_star_by_roster_id(roster_id: int, new_star: int) -> bool:
	if roster_id <= 0:
		return false
	var safe_star: int = clampi(new_star, 1, MAX_STAR)
	for roster_item: Dictionary in active_roster:
		if int(roster_item.get("roster_id", -1)) == roster_id:
			roster_item["star"] = safe_star
			return true
	for roster_item: Dictionary in bench_roster:
		if int(roster_item.get("roster_id", -1)) == roster_id:
			roster_item["star"] = safe_star
			return true
	return false


func get_permanent_stat_bonuses_by_roster_id(roster_id: int) -> Dictionary:
	var roster_item: Dictionary = _find_roster_item_by_id(roster_id)
	if roster_item.is_empty():
		return {}

	return _sanitize_permanent_stat_bonuses(roster_item.get(PERMANENT_STAT_BONUSES_KEY, {}))


func restore_lineup_snapshot(active_units: Array, bench_units: Array, global_effects: Dictionary) -> void:
	active_roster.clear()
	bench_roster.clear()
	next_roster_id = 1
	unlocked_unit_ids.clear()
	player_hp_multiplier = maxf(0.01, float(global_effects.get("player_hp_multiplier", 1.0)))
	player_attack_multiplier = maxf(0.01, float(global_effects.get("player_attack_multiplier", 1.0)))
	var saved_bonuses: Variant = global_effects.get("global_stat_bonuses", {})
	if saved_bonuses is Dictionary:
		global_stat_bonuses = (saved_bonuses as Dictionary).duplicate()
	else:
		global_stat_bonuses.clear()
	has_death_prevention = bool(global_effects.get("has_death_prevention", false))
	max_active_units = maxi(1, int(global_effects.get("max_active_units", max_active_units)))
	max_total_units = maxi(max_active_units, int(global_effects.get("max_total_units", max_total_units)))
	max_bench_units = maxi(0, max_total_units - max_active_units)

	_restore_roster_area(active_roster, active_units, max_active_units)
	_restore_roster_area(bench_roster, bench_units, max_bench_units)
	_restore_unlocked_unit_ids(global_effects)
	_unlock_roster_units(active_roster)
	_unlock_roster_units(bench_roster)


func unlock_unit_by_id(unit_id: String) -> void:
	unlock_unit_data(get_unit_data_by_id(unit_id))


func unlock_unit_data(unit_data: Resource) -> void:
	var unit_id: String = get_unit_id(unit_data)
	if unit_id == "" or unlocked_unit_ids.has(unit_id):
		return

	if not is_unit_id_available_for_run(unit_id):
		return

	unlocked_unit_ids.append(unit_id)


func is_unit_unlocked(unit_data: Resource) -> bool:
	return is_unit_id_unlocked(get_unit_id(unit_data))


func is_unit_id_unlocked(unit_id: String) -> bool:
	return unit_id != "" and unlocked_unit_ids.has(unit_id)


func get_unlocked_unit_ids() -> Array[String]:
	var unit_ids: Array[String] = []
	for unit_id: String in unlocked_unit_ids:
		unit_ids.append(unit_id)
	return unit_ids


func get_unlocked_unit_pool() -> Array[Resource]:
	var unit_pool: Array[Resource] = []
	for unit_data: Resource in _get_unit_data_pool():
		if is_unit_unlocked(unit_data):
			unit_pool.append(unit_data)
	return unit_pool


func get_locked_unit_pool() -> Array[Resource]:
	var unit_pool: Array[Resource] = []
	for unit_data: Resource in _get_unit_data_pool():
		if not is_unit_unlocked(unit_data):
			unit_pool.append(unit_data)
	return unit_pool


func is_unit_available_for_run(unit_data: Resource) -> bool:
	return is_unit_id_available_for_run(get_unit_id(unit_data))


func is_unit_id_available_for_run(unit_id: String) -> bool:
	if unit_id == "":
		return false
	if all_hero_exclusive_unit_ids.is_empty():
		return true
	if not all_hero_exclusive_unit_ids.has(unit_id):
		return true
	return selected_hero_exclusive_unit_ids.has(unit_id)


func get_unit_data_by_id(unit_id: String) -> Resource:
	return unit_catalog.get_unit_data_by_id(unit_id)


func get_unit_upgrade_hint_for_data(unit_data: Resource) -> String:
	return get_unit_upgrade_hint(get_unit_id(unit_data), 1)


func get_unit_upgrade_hint(unit_id: String, incoming_star: int = 1) -> String:
	var target_star: int = get_unit_upgrade_target_star(unit_id, incoming_star)
	if target_star <= 0:
		return ""

	return "可升星：获得后可合成 " + str(target_star) + " 星"


func get_unit_upgrade_target_star_for_data(unit_data: Resource) -> int:
	return get_unit_upgrade_target_star(get_unit_id(unit_data), 1)


func get_unit_upgrade_target_star(unit_id: String, incoming_star: int = 1) -> int:
	return merge_service.get_unit_upgrade_target_star(active_roster, bench_roster, unit_id, incoming_star, MAX_STAR)


func has_any_unit_upgrade_candidate() -> bool:
	for unit_data: Resource in _get_unit_data_pool():
		if get_unit_upgrade_target_star_for_data(unit_data) > 0:
			return true
	return false


func get_bench_unit_configs(battle_board: Variant = null) -> Array[Dictionary]:
	var unit_configs: Array[Dictionary] = []
	for index: int in range(bench_roster.size()):
		var roster_item: Dictionary = bench_roster[index]
		var base_data: Resource = roster_item["unit_data"] as Resource
		if base_data == null:
			continue

		var spawn_position: Vector2 = Vector2(80.0 + float(index) * 48.0, 980.0)
		if battle_board != null and is_instance_valid(battle_board):
			spawn_position = battle_board.bench_slot_to_world(index)

		unit_configs.append({
			"unit_data": _create_scaled_unit_data(roster_item, player_hp_multiplier, player_attack_multiplier),
			"position": spawn_position,
			"display_name": get_unit_display_name_with_star(roster_item),
			"roster_id": int(roster_item.get("roster_id", -1)),
			"bench_slot": index,
		})

	return unit_configs


func create_battle_unit_data(unit_data: Resource) -> Resource:
	if unit_data == null:
		return null

	return _create_scaled_unit_data(create_roster_item(unit_data), player_hp_multiplier, player_attack_multiplier)


func get_player_battle_unit_data() -> Array[Resource]:
	var unit_data_list: Array[Resource] = []

	for roster_item: Dictionary in active_roster:
		var base_data: Resource = roster_item["unit_data"] as Resource
		if base_data == null:
			continue

		unit_data_list.append(_create_scaled_unit_data(roster_item, player_hp_multiplier, player_attack_multiplier))

	return unit_data_list


func get_player_battle_unit_configs(battle_board: Variant = null, reserved_player_cells: Array[Vector2i] = []) -> Array[Dictionary]:
	var unit_configs: Array[Dictionary] = []
	var occupied_positions: Array[Vector2] = []
	var occupied_cells: Array[Vector2i] = reserved_player_cells.duplicate()

	for index: int in range(active_roster.size()):
		var roster_item: Dictionary = active_roster[index]
		var base_data: Resource = roster_item["unit_data"] as Resource
		if base_data == null:
			continue

		var spawn_position: Vector2 = Vector2.ZERO
		var spawn_cell: Vector2i = Vector2i(-1, -1)
		if battle_board != null and is_instance_valid(battle_board):
			spawn_cell = battle_board.choose_player_cell_for_roster_item(roster_item, occupied_cells)
			if spawn_cell != Vector2i(-1, -1):
				spawn_position = battle_board.grid_to_world(spawn_cell)
				occupied_cells.append(spawn_cell)
			else:
				spawn_position = _get_spawn_position_for_roster_item(roster_item, occupied_positions, index)
		else:
			spawn_position = _get_spawn_position_for_roster_item(roster_item, occupied_positions, index)

		occupied_positions.append(spawn_position)
		unit_configs.append({
			"unit_data": _create_scaled_unit_data(roster_item, player_hp_multiplier, player_attack_multiplier),
			"position": spawn_position,
			"display_name": get_unit_display_name_with_star(roster_item),
			"roster_id": int(roster_item.get("roster_id", -1)),
			"cell": spawn_cell,
		})

	return unit_configs


func save_active_unit_positions(positions_by_roster_id: Dictionary) -> void:
	for index: int in range(active_roster.size()):
		var roster_item: Dictionary = active_roster[index]
		var roster_id: int = int(roster_item.get("roster_id", -1))
		if roster_id <= 0 or not positions_by_roster_id.has(roster_id):
			continue

		roster_item["saved_position"] = positions_by_roster_id[roster_id]
		roster_item["has_saved_position"] = true
		active_roster[index] = roster_item


func save_active_unit_cells(cells_by_roster_id: Dictionary, positions_by_roster_id: Dictionary) -> void:
	for index: int in range(active_roster.size()):
		var roster_item: Dictionary = active_roster[index]
		var roster_id: int = int(roster_item.get("roster_id", -1))
		if roster_id <= 0 or not cells_by_roster_id.has(roster_id):
			continue

		roster_item["saved_cell"] = cells_by_roster_id[roster_id]
		roster_item["has_saved_cell"] = true
		if positions_by_roster_id.has(roster_id):
			roster_item["saved_position"] = positions_by_roster_id[roster_id]
			roster_item["has_saved_position"] = true
		active_roster[index] = roster_item


func save_active_unit_cell(roster_id: int, saved_cell: Vector2i, saved_position: Vector2) -> void:
	for index: int in range(active_roster.size()):
		var roster_item: Dictionary = active_roster[index]
		if int(roster_item.get("roster_id", -1)) != roster_id:
			continue

		roster_item["saved_cell"] = saved_cell
		roster_item["has_saved_cell"] = true
		roster_item["saved_position"] = saved_position
		roster_item["has_saved_position"] = true
		active_roster[index] = roster_item
		return


func check_auto_merge() -> void:
	merge_service.check_auto_merge(
		active_roster,
		bench_roster,
		max_active_units,
		MAX_STAR,
		DEFAULT_UNIT_PRICE,
		Callable(self, "create_roster_item"),
		Callable(self, "get_unit_data_name")
	)


func find_merge_group(unit_id: String, star: int) -> Array[Dictionary]:
	return merge_service.find_merge_group(active_roster, bench_roster, unit_id, star)


func merge_units(unit_id: String, star: int) -> bool:
	return merge_service.merge_units(
		active_roster,
		bench_roster,
		unit_id,
		star,
		max_active_units,
		MAX_STAR,
		DEFAULT_UNIT_PRICE,
		Callable(self, "create_roster_item"),
		Callable(self, "get_unit_data_name")
	)


func get_star_growth(unit_type: String, star: int) -> Dictionary:
	return unit_scaling_service.get_star_growth(unit_type, star)


func get_unit_display_name_with_star(roster_item: Dictionary) -> String:
	var display_name: String = str(roster_item.get("display_name", "单位"))
	var star: int = int(roster_item.get("star", 1))
	return display_name + " " + _get_star_text(star)


func create_roster_item(unit_data: Resource, star: int = 1, base_price: int = -1) -> Dictionary:
	var safe_star: int = clampi(star, 1, MAX_STAR)
	return {
		"roster_id": _take_next_roster_id(),
		"unit_data": unit_data,
		"unit_id": get_unit_id(unit_data),
		"display_name": get_unit_data_name(unit_data),
		"star": safe_star,
		"base_price": _get_unit_base_price(unit_data, base_price),
		PERMANENT_STAT_BONUSES_KEY: {},
		"has_saved_cell": false,
		"saved_cell": Vector2i(-1, -1),
		"has_saved_position": false,
		"saved_position": Vector2.ZERO,
	}


func _restore_roster_area(target_roster: Array[Dictionary], unit_snapshots: Array, max_count: int) -> void:
	for unit_snapshot_value: Variant in unit_snapshots:
		if target_roster.size() >= max_count:
			return

		if not (unit_snapshot_value is Dictionary):
			continue

		var roster_item: Dictionary = _create_roster_item_from_snapshot(unit_snapshot_value as Dictionary)
		if roster_item.is_empty():
			continue

		target_roster.append(roster_item)


func _create_roster_item_from_snapshot(unit_snapshot: Dictionary) -> Dictionary:
	var unit_data: Resource = unit_snapshot.get("unit_data", null) as Resource
	if unit_data == null:
		var unit_id: String = str(unit_snapshot.get("unit_id", ""))
		unit_data = get_unit_data_by_id(unit_id)

	if unit_data == null:
		push_warning("Cannot restore snapshot unit: " + str(unit_snapshot.get("unit_id", "")))
		return {}

	var roster_id: int = int(unit_snapshot.get("roster_id", -1))
	if roster_id <= 0:
		roster_id = _take_next_roster_id()
	else:
		next_roster_id = maxi(next_roster_id, roster_id + 1)

	var unit_id: String = get_unit_id(unit_data)
	if unit_id == "":
		unit_id = str(unit_snapshot.get("unit_id", ""))

	return {
		"roster_id": roster_id,
		"unit_data": unit_data,
		"unit_id": unit_id,
		"display_name": str(unit_snapshot.get("display_name", get_unit_data_name(unit_data))),
		"star": clampi(int(unit_snapshot.get("star", 1)), 1, MAX_STAR),
		"base_price": int(unit_snapshot.get("base_price", _get_unit_base_price(unit_data, -1))),
		PERMANENT_STAT_BONUSES_KEY: _sanitize_permanent_stat_bonuses(unit_snapshot.get(PERMANENT_STAT_BONUSES_KEY, {})),
		"has_saved_cell": bool(unit_snapshot.get("has_saved_cell", false)),
		"saved_cell": unit_snapshot.get("saved_cell", Vector2i(-1, -1)) as Vector2i,
		"has_saved_position": bool(unit_snapshot.get("has_saved_position", false)),
		"saved_position": unit_snapshot.get("saved_position", Vector2.ZERO) as Vector2,
	}


func _restore_unlocked_unit_ids(global_effects: Dictionary) -> void:
	var restored_unlocked_ids: Variant = global_effects.get("unlocked_unit_ids", [])
	if not (restored_unlocked_ids is Array):
		return

	for unit_id_value: Variant in restored_unlocked_ids:
		var unit_id: String = str(unit_id_value)
		if unit_id != "":
			unlock_unit_by_id(unit_id)


func _unlock_roster_units(roster: Array[Dictionary]) -> void:
	for roster_item: Dictionary in roster:
		var unit_data: Resource = roster_item.get("unit_data", null) as Resource
		unlock_unit_data(unit_data)


func _reset_roster_state() -> void:
	active_roster.clear()
	bench_roster.clear()
	next_roster_id = 1
	unlocked_unit_ids.clear()
	player_hp_multiplier = 1.0
	player_attack_multiplier = 1.0
	global_stat_bonuses.clear()
	has_death_prevention = false


func _add_starter_unit_by_id(unit_id: String) -> bool:
	return _add_starter_unit_data(get_unit_data_by_id(unit_id))


func _add_starter_unit_data(unit_data: Resource) -> bool:
	if unit_data == null:
		return false
	if not is_unit_available_for_run(unit_data):
		return false
	unlock_unit_data(unit_data)
	active_roster.append(create_roster_item(unit_data))
	return true


func _get_random_common_starter_unit(excluded_unit_ids: Array[String]) -> Resource:
	var common_pool: Array[Resource] = []
	for unit_data: Resource in _get_unit_data_pool():
		var unit_id: String = get_unit_id(unit_data)
		if unit_id == "" or excluded_unit_ids.has(unit_id):
			continue
		if all_hero_exclusive_unit_ids.has(unit_id):
			continue
		if _get_unit_rarity(unit_data).strip_edges().to_upper() != "COMMON":
			continue
		common_pool.append(unit_data)

	if common_pool.is_empty():
		return null

	return common_pool[randi_range(0, common_pool.size() - 1)]


func _deduplicate_unit_ids(unit_ids: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for unit_id_value: Variant in unit_ids:
		var unit_id: String = str(unit_id_value).strip_edges()
		if unit_id != "" and not result.has(unit_id):
			result.append(unit_id)
	return result


func _add_permanent_stat_bonus_to_roster(roster: Array[Dictionary], roster_id: int, stat_name: String, amount: float) -> bool:
	for roster_item: Dictionary in roster:
		if int(roster_item.get("roster_id", -1)) != roster_id:
			continue

		var bonuses: Dictionary = _sanitize_permanent_stat_bonuses(roster_item.get(PERMANENT_STAT_BONUSES_KEY, {}))
		bonuses[stat_name] = float(bonuses.get(stat_name, 0.0)) + amount
		roster_item[PERMANENT_STAT_BONUSES_KEY] = bonuses
		return true

	return false


func _find_roster_item_by_id(roster_id: int) -> Dictionary:
	for roster_item: Dictionary in active_roster:
		if int(roster_item.get("roster_id", -1)) == roster_id:
			return roster_item

	for roster_item: Dictionary in bench_roster:
		if int(roster_item.get("roster_id", -1)) == roster_id:
			return roster_item

	return {}


func _sanitize_permanent_stat_bonuses(value: Variant) -> Dictionary:
	var bonuses: Dictionary = {}
	if not (value is Dictionary):
		return bonuses

	var source: Dictionary = value as Dictionary
	for stat_name_value: Variant in source.keys():
		var stat_name: String = str(stat_name_value).strip_edges()
		if stat_name == "":
			continue

		bonuses[stat_name] = float(source.get(stat_name_value, 0.0))

	return bonuses


func get_unit_id(unit_data: Resource) -> String:
	return unit_catalog.get_unit_id(unit_data)


func get_unit_data_name(unit_data: Resource) -> String:
	return unit_catalog.get_unit_name(unit_data)


func _create_scaled_unit_data(roster_item: Dictionary, hp_multiplier: float, attack_multiplier: float) -> Resource:
	return unit_scaling_service.create_scaled_unit_data(roster_item, hp_multiplier, attack_multiplier, global_stat_bonuses)


func get_all_unit_pool() -> Array[Resource]:
	return _get_unit_data_pool()


func get_high_rarity_unit_pool(min_rarity: String = "RARE") -> Array[Resource]:
	var min_index: int = unit_catalog.get_rarity_index(min_rarity)
	var pool: Array[Resource] = []
	for unit_data: Resource in _get_unit_data_pool():
		var rarity: String = str(unit_data.get("rarity"))
		if unit_catalog.get_rarity_index(rarity) >= min_index:
			pool.append(unit_data)
	return pool


func _get_unit_data_pool() -> Array[Resource]:
	var available_pool: Array[Resource] = []
	for unit_data: Resource in unit_catalog.get_unit_pool():
		if is_unit_available_for_run(unit_data):
			available_pool.append(unit_data)
	return available_pool


func _get_spawn_position_for_roster_item(roster_item: Dictionary, occupied_positions: Array[Vector2], fallback_index: int) -> Vector2:
	return roster_position_service.get_spawn_position_for_roster_item(roster_item, occupied_positions, fallback_index)


func _get_star_text(star: int) -> String:
	var star_text: String = ""
	var safe_star: int = clampi(star, 1, MAX_STAR)
	for _index: int in range(safe_star):
		star_text += "*"
	return star_text


func _get_unit_base_price(unit_data: Resource, override_price: int) -> int:
	return unit_catalog.get_unit_price(unit_data, override_price)


func _get_unit_rarity(unit_data: Resource) -> String:
	return unit_catalog.get_unit_rarity(unit_data)


func _get_price_for_rarity(rarity: String) -> int:
	return unit_catalog.get_price_for_rarity(rarity)


func _get_rarity_index(rarity: String) -> int:
	return unit_catalog.get_rarity_index(rarity)


func _get_star_sell_count(star: int) -> int:
	return merge_service.get_star_sell_count(star, MAX_STAR)


func _get_roster_index_by_id(roster: Array[Dictionary], roster_id: int) -> int:
	for index: int in range(roster.size()):
		var roster_item: Dictionary = roster[index]
		if int(roster_item.get("roster_id", -1)) == roster_id:
			return index

	return -1


func _take_next_roster_id() -> int:
	var roster_id: int = next_roster_id
	next_roster_id += 1
	return roster_id
