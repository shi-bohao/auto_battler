extends SceneTree

const UNIT_ART_HELPER: Script = preload("res://scripts/unit_art_helper.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const IRON_OATH_COMMANDER_DATA: Resource = preload("res://data/heroes/iron_oath_commander_unit.tres")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var texture: Texture2D = UNIT_ART_HELPER.get_player_unit_art_texture(WARRIOR_DATA)
	if texture == null:
		failures.append("Expected warrior generated unit art to load.")
	elif texture.get_width() <= 0 or texture.get_height() <= 0:
		failures.append("Loaded warrior unit art has invalid dimensions.")

	var thumbnail: Texture2D = UNIT_ART_HELPER.get_player_unit_art_texture_sized(WARRIOR_DATA, Vector2i(96, 96))
	if thumbnail == null:
		failures.append("Expected warrior generated unit art thumbnail to load.")
	elif thumbnail.get_width() != 96 or thumbnail.get_height() != 96:
		failures.append("Expected 96x96 warrior thumbnail, got " + str(thumbnail.get_width()) + "x" + str(thumbnail.get_height()) + ".")

	var missing_texture: Texture2D = UNIT_ART_HELPER.get_player_unit_art_texture("enemy_boss_abyss_hierophant")
	if missing_texture != null:
		failures.append("Expected missing generated unit art to return null.")

	var hero_portrait: Texture2D = IRON_OATH_COMMANDER_DATA.get("portrait_texture") as Texture2D
	var hero_thumbnail: Texture2D = UNIT_ART_HELPER.get_texture_sized(hero_portrait, "test_iron_oath_portrait", Vector2i(96, 96))
	if hero_thumbnail == null:
		failures.append("Expected configured hero portrait thumbnail to load.")
	elif hero_thumbnail.get_width() != 96 or hero_thumbnail.get_height() != 96:
		failures.append("Expected 96x96 hero portrait thumbnail, got " + str(hero_thumbnail.get_width()) + "x" + str(hero_thumbnail.get_height()) + ".")

	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	unit.unit_data = WARRIOR_DATA.duplicate(true)
	get_root().add_child(unit)
	await process_frame

	if unit.board_sprite == null:
		failures.append("Expected generated unit art to populate board_sprite.")
	if unit.portrait_texture == null:
		failures.append("Expected generated unit art to populate portrait_texture.")
	if unit.icon_texture == null:
		failures.append("Expected generated unit art to populate icon_texture.")
	if not unit.has_board_art():
		failures.append("Expected unit to show board art after applying generated art.")

	unit.queue_free()
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("Unit art helper tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
