class_name LineupSnapshotManager
extends RefCounted

const SCHEMA_VERSION: int = 1
const DEFAULT_STORAGE_PATH: String = "user://lineup_snapshots.json"
const SNAPSHOT_SOURCE_BOSS_VICTORY: String = "BOSS_VICTORY"

var storage_path: String = DEFAULT_STORAGE_PATH


func build_boss_victory_snapshot(
	roster_manager: Variant,
	relic_manager: RelicManager,
	economy_manager: Variant,
	run_controller: Variant,
	encounter: Dictionary
) -> Dictionary:
	var current_round: int = _get_int_property(run_controller, "current_round", 0)
	return {
		"schema_version": SCHEMA_VERSION,
		"snapshot_id": _create_snapshot_id(current_round),
		"created_unix_time": int(Time.get_unix_time_from_system()),
		"created_datetime": Time.get_datetime_string_from_system(false, true),
		"source": SNAPSHOT_SOURCE_BOSS_VICTORY,
		"run": _build_run_snapshot(economy_manager, run_controller, encounter),
		"global_effects": _build_global_effects_snapshot(roster_manager),
		"units": {
			"active": _build_roster_area_snapshot(_get_roster_area(roster_manager, "get_active_roster"), "active"),
			"bench": _build_roster_area_snapshot(_get_roster_area(roster_manager, "get_bench_roster"), "bench"),
		},
		"relics": _build_relic_snapshots(relic_manager),
	}


func save_boss_victory_snapshot(
	roster_manager: Variant,
	relic_manager: RelicManager,
	economy_manager: Variant,
	run_controller: Variant,
	encounter: Dictionary
) -> Dictionary:
	var snapshot: Dictionary = build_boss_victory_snapshot(
		roster_manager,
		relic_manager,
		economy_manager,
		run_controller,
		encounter
	)
	if not append_snapshot(snapshot):
		return {}

	return snapshot


func append_snapshot(snapshot: Dictionary) -> bool:
	if snapshot.is_empty():
		return false

	var document: Dictionary = _load_storage_document()
	var snapshots: Array = _get_array(document, "snapshots")
	snapshots.append(snapshot.duplicate(true))
	document["schema_version"] = SCHEMA_VERSION
	document["snapshots"] = snapshots
	return _write_storage_document(document)


func load_all_snapshots() -> Array[Dictionary]:
	var document: Dictionary = _load_storage_document()
	var snapshots_value: Array = _get_array(document, "snapshots")
	var snapshots: Array[Dictionary] = []
	for snapshot_value: Variant in snapshots_value:
		if snapshot_value is Dictionary:
			snapshots.append((snapshot_value as Dictionary).duplicate(true))

	return snapshots


func load_latest_snapshot() -> Dictionary:
	var snapshots: Array[Dictionary] = load_all_snapshots()
	if snapshots.is_empty():
		return {}

	return snapshots[snapshots.size() - 1].duplicate(true)


func parse_snapshot(snapshot: Dictionary, roster_manager: Variant, relic_manager: RelicManager) -> Dictionary:
	if snapshot.is_empty():
		return {}

	var units: Dictionary = _get_dictionary(snapshot, "units")
	return {
		"schema_version": int(snapshot.get("schema_version", 0)),
		"snapshot_id": str(snapshot.get("snapshot_id", "")),
		"created_unix_time": int(snapshot.get("created_unix_time", 0)),
		"created_datetime": str(snapshot.get("created_datetime", "")),
		"source": str(snapshot.get("source", "")),
		"run": _get_dictionary(snapshot, "run"),
		"global_effects": _get_dictionary(snapshot, "global_effects"),
		"active_units": _parse_unit_snapshots(_get_array(units, "active"), roster_manager),
		"bench_units": _parse_unit_snapshots(_get_array(units, "bench"), roster_manager),
		"relics": _parse_relic_snapshots(_get_array(snapshot, "relics"), relic_manager),
	}


func restore_snapshot_to_managers(snapshot: Dictionary, roster_manager: Variant, relic_manager: RelicManager) -> bool:
	var parsed_snapshot: Dictionary = parse_snapshot(snapshot, roster_manager, relic_manager)
	if parsed_snapshot.is_empty():
		return false

	if roster_manager == null or not roster_manager.has_method("restore_lineup_snapshot"):
		push_warning("RosterManager cannot restore lineup snapshots.")
		return false

	roster_manager.restore_lineup_snapshot(
		_get_array(parsed_snapshot, "active_units"),
		_get_array(parsed_snapshot, "bench_units"),
		_get_dictionary(parsed_snapshot, "global_effects")
	)

	if relic_manager != null and relic_manager.has_method("restore_relic_ids"):
		var relic_ids: Array[String] = []
		for relic_snapshot_value: Variant in _get_array(parsed_snapshot, "relics"):
			if not (relic_snapshot_value is Dictionary):
				continue

			var relic_id: String = str((relic_snapshot_value as Dictionary).get("relic_id", ""))
			if relic_id != "":
				relic_ids.append(relic_id)

		relic_manager.restore_relic_ids(relic_ids)

	return true


func _build_run_snapshot(economy_manager: Variant, run_controller: Variant, encounter: Dictionary) -> Dictionary:
	return {
		"current_round": _get_int_property(run_controller, "current_round", 0),
		"max_round": _get_int_property(run_controller, "max_round", 0),
		"encounter_type": str(encounter.get("encounter_type", "")),
		"encounter_name": str(encounter.get("encounter_name", "")),
		"gold": _get_int_property(economy_manager, "gold", 0),
	}


func _build_global_effects_snapshot(roster_manager: Variant) -> Dictionary:
	var unlocked_unit_ids: Array[String] = []
	if roster_manager != null and roster_manager.has_method("get_unlocked_unit_ids"):
		unlocked_unit_ids = roster_manager.get_unlocked_unit_ids()

	return {
		"player_hp_multiplier": _get_float_property(roster_manager, "player_hp_multiplier", 1.0),
		"player_attack_multiplier": _get_float_property(roster_manager, "player_attack_multiplier", 1.0),
		"max_active_units": _get_int_property(roster_manager, "max_active_units", 10),
		"max_total_units": _get_int_property(roster_manager, "max_total_units", 25),
		"unlocked_unit_ids": unlocked_unit_ids,
	}


func _build_roster_area_snapshot(roster: Array[Dictionary], area: String) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for index: int in range(roster.size()):
		var roster_item: Dictionary = roster[index]
		var unit_data: Resource = roster_item.get("unit_data", null) as Resource
		var unit_id: String = str(roster_item.get("unit_id", ""))
		var saved_cell: Vector2i = roster_item.get("saved_cell", Vector2i(-1, -1)) as Vector2i
		var saved_position: Vector2 = roster_item.get("saved_position", Vector2.ZERO) as Vector2
		snapshots.append({
			"area": area,
			"index": index,
			"roster_id": int(roster_item.get("roster_id", -1)),
			"unit_id": unit_id,
			"resource_path": _get_resource_path(unit_data),
			"display_name": str(roster_item.get("display_name", unit_id)),
			"star": int(roster_item.get("star", 1)),
			"base_price": int(roster_item.get("base_price", 0)),
			"has_saved_cell": bool(roster_item.get("has_saved_cell", false)),
			"saved_cell": _vector2i_to_dictionary(saved_cell),
			"has_saved_position": bool(roster_item.get("has_saved_position", false)),
			"saved_position": _vector2_to_dictionary(saved_position),
		})

	return snapshots


func _build_relic_snapshots(relic_manager: RelicManager) -> Array[Dictionary]:
	var relic_snapshots: Array[Dictionary] = []
	if relic_manager == null:
		return relic_snapshots

	var relics: Array[Resource] = relic_manager.get_player_relics()
	for relic_data: Resource in relics:
		if relic_data == null:
			continue

		relic_snapshots.append({
			"relic_id": relic_manager.get_relic_id(relic_data),
			"resource_path": _get_resource_path(relic_data),
			"name": relic_manager.get_relic_name(relic_data),
			"rarity": relic_manager.get_relic_rarity(relic_data),
			"trigger_type": relic_manager.get_relic_trigger_type(relic_data),
			"value": relic_manager.get_relic_value(relic_data, 0.0),
		})

	return relic_snapshots


func _parse_unit_snapshots(unit_snapshots: Array, roster_manager: Variant) -> Array[Dictionary]:
	var parsed_units: Array[Dictionary] = []
	for unit_snapshot_value: Variant in unit_snapshots:
		if not (unit_snapshot_value is Dictionary):
			continue

		var unit_snapshot: Dictionary = unit_snapshot_value as Dictionary
		var unit_data: Resource = _resolve_unit_data(unit_snapshot, roster_manager)
		if unit_data == null:
			continue

		var parsed_unit: Dictionary = unit_snapshot.duplicate(true)
		parsed_unit["unit_data"] = unit_data
		parsed_unit["unit_id"] = _get_unit_id_from_snapshot(unit_snapshot, roster_manager, unit_data)
		parsed_unit["saved_cell"] = _dictionary_to_vector2i(unit_snapshot.get("saved_cell", {}), Vector2i(-1, -1))
		parsed_unit["saved_position"] = _dictionary_to_vector2(unit_snapshot.get("saved_position", {}), Vector2.ZERO)
		parsed_units.append(parsed_unit)

	return parsed_units


func _parse_relic_snapshots(relic_snapshots: Array, relic_manager: RelicManager) -> Array[Dictionary]:
	var parsed_relics: Array[Dictionary] = []
	for relic_snapshot_value: Variant in relic_snapshots:
		if not (relic_snapshot_value is Dictionary):
			continue

		var relic_snapshot: Dictionary = relic_snapshot_value as Dictionary
		var relic_data: Resource = _resolve_relic_data(relic_snapshot, relic_manager)
		if relic_data == null:
			continue

		var parsed_relic: Dictionary = relic_snapshot.duplicate(true)
		if relic_manager != null:
			parsed_relic["relic_id"] = relic_manager.get_relic_id(relic_data)
		parsed_relic["relic_data"] = relic_data
		parsed_relics.append(parsed_relic)

	return parsed_relics


func _resolve_unit_data(unit_snapshot: Dictionary, roster_manager: Variant) -> Resource:
	var unit_id: String = str(unit_snapshot.get("unit_id", ""))
	if unit_id != "" and roster_manager != null and roster_manager.has_method("get_unit_data_by_id"):
		var unit_data_by_id: Resource = roster_manager.get_unit_data_by_id(unit_id)
		if unit_data_by_id != null:
			return unit_data_by_id

	return _load_resource_from_path(str(unit_snapshot.get("resource_path", "")))


func _resolve_relic_data(relic_snapshot: Dictionary, relic_manager: RelicManager) -> Resource:
	var relic_id: String = str(relic_snapshot.get("relic_id", ""))
	if relic_id != "" and relic_manager != null and relic_manager.has_method("get_relic_data_by_id"):
		var relic_data_by_id: Resource = relic_manager.get_relic_data_by_id(relic_id)
		if relic_data_by_id != null:
			return relic_data_by_id

	return _load_resource_from_path(str(relic_snapshot.get("resource_path", "")))


func _load_resource_from_path(resource_path: String) -> Resource:
	if resource_path == "" or not ResourceLoader.exists(resource_path):
		return null

	return ResourceLoader.load(resource_path) as Resource


func _get_unit_id_from_snapshot(unit_snapshot: Dictionary, roster_manager: Variant, unit_data: Resource) -> String:
	if roster_manager != null and roster_manager.has_method("get_unit_id"):
		var unit_id: String = str(roster_manager.get_unit_id(unit_data))
		if unit_id != "":
			return unit_id

	return str(unit_snapshot.get("unit_id", ""))


func _get_roster_area(roster_manager: Variant, method_name: String) -> Array[Dictionary]:
	var roster: Array[Dictionary] = []
	if roster_manager == null or not roster_manager.has_method(method_name):
		return roster

	var roster_value: Variant = roster_manager.call(method_name)
	if roster_value is Array:
		for roster_item_value: Variant in roster_value:
			if roster_item_value is Dictionary:
				roster.append(roster_item_value as Dictionary)

	return roster


func _load_storage_document() -> Dictionary:
	if not FileAccess.file_exists(storage_path):
		return _create_empty_storage_document()

	var file_text: String = FileAccess.get_file_as_string(storage_path)
	if file_text.strip_edges() == "":
		return _create_empty_storage_document()

	var parsed_document: Variant = JSON.parse_string(file_text)
	if not (parsed_document is Dictionary):
		push_warning("Lineup snapshot storage is not a JSON object: " + storage_path)
		return _create_empty_storage_document()

	var document: Dictionary = parsed_document as Dictionary
	if not document.has("snapshots") or not (document["snapshots"] is Array):
		document["snapshots"] = []
	if not document.has("schema_version"):
		document["schema_version"] = SCHEMA_VERSION

	return document


func _write_storage_document(document: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		push_warning("Cannot write lineup snapshots to " + storage_path + ": " + str(FileAccess.get_open_error()))
		return false

	file.store_string(JSON.stringify(document, "\t"))
	file.close()
	return true


func _create_empty_storage_document() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"snapshots": [],
	}


func _create_snapshot_id(current_round: int) -> String:
	return "boss_round_" + str(current_round) + "_" + str(int(Time.get_unix_time_from_system()))


func _get_resource_path(resource: Resource) -> String:
	if resource == null:
		return ""

	return resource.resource_path


func _vector2_to_dictionary(value: Vector2) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}


func _vector2i_to_dictionary(value: Vector2i) -> Dictionary:
	return {
		"x": value.x,
		"y": value.y,
	}


func _dictionary_to_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if not (value is Dictionary):
		return fallback

	var dictionary: Dictionary = value as Dictionary
	return Vector2(float(dictionary.get("x", fallback.x)), float(dictionary.get("y", fallback.y)))


func _dictionary_to_vector2i(value: Variant, fallback: Vector2i) -> Vector2i:
	if not (value is Dictionary):
		return fallback

	var dictionary: Dictionary = value as Dictionary
	return Vector2i(int(dictionary.get("x", fallback.x)), int(dictionary.get("y", fallback.y)))


func _get_dictionary(dictionary: Dictionary, key: String) -> Dictionary:
	var value: Variant = dictionary.get(key, {})
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)

	return {}


func _get_array(dictionary: Dictionary, key: String) -> Array:
	var value: Variant = dictionary.get(key, [])
	if value is Array:
		return (value as Array).duplicate(true)

	return []


func _get_int_property(object: Variant, property_name: String, default_value: int) -> int:
	if object == null:
		return default_value

	var value: Variant = object.get(property_name)
	if value == null:
		return default_value

	return int(value)


func _get_float_property(object: Variant, property_name: String, default_value: float) -> float:
	if object == null:
		return default_value

	var value: Variant = object.get(property_name)
	if value == null:
		return default_value

	return float(value)
