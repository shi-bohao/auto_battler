extends SceneTree

const ENCYCLOPEDIA_CATALOG_SCRIPT: Script = preload("res://scripts/catalog/encyclopedia_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	_run_tests()
	_finish()


func _run_tests() -> void:
	var catalog: Variant = ENCYCLOPEDIA_CATALOG_SCRIPT.new()
	catalog.refresh()

	_expect_int(catalog.get_category_order().size(), 6, "Encyclopedia should expose current categories.")
	_expect_min_count(catalog, "player_units", 25, "Player unit category should include current friendly units.")
	_expect_min_count(catalog, "enemy_units", 15, "Enemy unit category should include current enemy units.")
	_expect_min_count(catalog, "summons", 3, "Summon category should include current summon units.")
	_expect_min_count(catalog, "relics", 30, "Relic category should include current relics.")
	_expect_min_count(catalog, "heroes", 4, "Hero category should include current heroes.")
	_expect_entry_has_name(catalog.get_entries("player_units"), "warrior", "Warrior entry should have a display name.")
	_expect_entry_has_name(catalog.get_entries("relics"), "battle_banner", "Battle Banner relic entry should have a display name.")
	_expect_entry_has_name(catalog.get_entries("heroes"), "iron_oath_commander", "Iron Oath Commander hero entry should have a display name.")


func _expect_min_count(catalog: Variant, category: String, minimum: int, message: String) -> void:
	var actual: int = int(catalog.get_entry_count(category))
	if actual < minimum:
		failures.append(message + " Expected at least " + str(minimum) + ", got " + str(actual) + ".")


func _expect_entry_has_name(entries: Array[Dictionary], entry_id: String, message: String) -> void:
	for entry: Dictionary in entries:
		if str(entry.get("id", "")) != entry_id:
			continue
		if str(entry.get("name", "")).strip_edges() == "":
			failures.append(message + " Name is empty.")
		return

	failures.append(message + " Entry was not found.")


func _expect_int(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failures.append(message + " Expected " + str(expected) + ", got " + str(actual) + ".")


func _finish() -> void:
	if failures.is_empty():
		print("Encyclopedia catalog tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
