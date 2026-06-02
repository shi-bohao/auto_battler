class_name UnitCatalog
extends RefCounted

const DEFAULT_UNIT_PRICE: int = 2
const RARITY_PRICE_STEP: int = 2
const UNIT_DATA_DIR: String = "res://data/units"

var unit_order: Array[String] = []
var unit_data_by_id: Dictionary = {}


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
	unit_order.clear()
	unit_data_by_id.clear()
	_register_unit(configured_warrior_data)
	_register_unit(configured_archer_data)
	_register_unit(configured_assassin_data)
	_register_unit(configured_tank_data)
	_register_unit(configured_mage_data)
	_register_unit(configured_priest_data)
	_register_unit(configured_bard_data)
	_register_unit(configured_forest_druid_data)
	_register_unit(configured_plague_caster_data)
	_register_unit(configured_guardian_captain_data)
	_register_unit(configured_wind_chanter_data)
	_register_unit(configured_greatsword_knight_data)
	_register_unit(configured_bomb_thrower_data)
	_register_unit(configured_cleric_data)
	_register_unit(configured_alchemist_data)
	_register_unit(configured_necromancer_data)
	_register_unit(configured_puppet_warlock_data)
	_register_units_from_dir(UNIT_DATA_DIR)
	_sort_unit_order_by_catalog_id()


func get_unit_pool() -> Array[Resource]:
	var unit_pool: Array[Resource] = []
	for unit_id: String in unit_order:
		var unit_data: Resource = unit_data_by_id.get(unit_id, null) as Resource
		if unit_data != null:
			unit_pool.append(unit_data)

	return unit_pool


func get_unit_data_by_id(unit_id: String) -> Resource:
	return unit_data_by_id.get(unit_id, null) as Resource


func get_unit_id(unit_data: Resource) -> String:
	if unit_data == null:
		return ""

	var configured_type: Variant = unit_data.get("unit_type")
	if configured_type != null and str(configured_type).strip_edges() != "":
		return str(configured_type)

	var configured_name: Variant = unit_data.get("unit_name")
	if configured_name != null and str(configured_name).strip_edges() != "":
		return str(configured_name).to_lower()

	return ""


func get_unit_name(unit_data: Resource) -> String:
	if unit_data == null:
		return "Unit"

	var configured_cn_name: Variant = unit_data.get("unit_name_cn")
	if configured_cn_name != null and str(configured_cn_name).strip_edges() != "":
		return str(configured_cn_name)

	var configured_name: Variant = unit_data.get("unit_name")
	if configured_name != null and str(configured_name).strip_edges() != "":
		return str(configured_name)

	var configured_type: Variant = unit_data.get("unit_type")
	if configured_type != null and str(configured_type).strip_edges() != "":
		return str(configured_type)

	return "Unit"


func get_unit_rarity(unit_data: Resource) -> String:
	if unit_data == null:
		return "COMMON"

	var configured_rarity: Variant = unit_data.get("rarity")
	if configured_rarity == null or str(configured_rarity).strip_edges() == "":
		return "COMMON"

	return str(configured_rarity)


func get_unit_price(unit_data: Resource, override_price: int = -1) -> int:
	if override_price > 0:
		return override_price

	return get_price_for_rarity(get_unit_rarity(unit_data))


func get_price_for_rarity(rarity: String) -> int:
	return DEFAULT_UNIT_PRICE + get_rarity_index(rarity) * RARITY_PRICE_STEP


func get_rarity_index(rarity: String) -> int:
	match rarity.strip_edges().to_upper():
		"FINE", "UNCOMMON":
			return 1
		"RARE":
			return 2
		"EPIC":
			return 3
		"LEGENDARY":
			return 4
		"MYTHIC", "MYTHICAL":
			return 5
		_:
			return 0


func _register_unit(unit_data: Resource) -> void:
	if unit_data == null:
		return

	var unit_id: String = get_unit_id(unit_data)
	if unit_id == "":
		return

	if not unit_data_by_id.has(unit_id):
		unit_order.append(unit_id)

	unit_data_by_id[unit_id] = unit_data


func _register_units_from_dir(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("Failed to open unit catalog dir: " + dir_path)
		return

	var file_names: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var resource_file_name: String = _normalize_exported_resource_file_name(file_name, ".tres")
			if resource_file_name != "" and not file_names.has(resource_file_name):
				file_names.append(resource_file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	file_names.sort()
	for unit_file_name: String in file_names:
		var resource_path: String = dir_path + "/" + unit_file_name
		var unit_data: Resource = ResourceLoader.load(resource_path)
		_register_unit(unit_data)


func _normalize_exported_resource_file_name(file_name: String, extension: String) -> String:
	if file_name.ends_with(extension):
		return file_name
	if file_name.ends_with(extension + ".remap"):
		return file_name.trim_suffix(".remap")
	return ""


func _sort_unit_order_by_catalog_id() -> void:
	unit_order.sort_custom(Callable(self, "_sort_unit_ids_by_catalog_id"))


func _sort_unit_ids_by_catalog_id(a: String, b: String) -> bool:
	var a_data: Resource = unit_data_by_id.get(a, null) as Resource
	var b_data: Resource = unit_data_by_id.get(b, null) as Resource
	var a_catalog_id: int = _get_catalog_id(a_data)
	var b_catalog_id: int = _get_catalog_id(b_data)
	if a_catalog_id > 0 and b_catalog_id > 0 and a_catalog_id != b_catalog_id:
		return a_catalog_id < b_catalog_id
	if a_catalog_id > 0 and b_catalog_id <= 0:
		return true
	if a_catalog_id <= 0 and b_catalog_id > 0:
		return false
	return a < b


func _get_catalog_id(unit_data: Resource) -> int:
	if unit_data == null:
		return 0

	var value: Variant = unit_data.get("catalog_id")
	if value == null:
		return 0

	return maxi(0, int(value))
