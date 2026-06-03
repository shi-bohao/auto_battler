extends SceneTree

const UNIT_ART_HELPER: Script = preload("res://scripts/unit_art_helper.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const IRON_OATH_COMMANDER_DATA: Resource = preload("res://data/heroes/iron_oath_commander_unit.tres")
const COMMON_SLIME_DATA: Resource = preload("res://data/enemies/common_slime.tres")

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

	var missing_texture: Texture2D = UNIT_ART_HELPER.get_player_unit_art_texture("missing_unit_art_probe")
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

	var enemy_texture: Texture2D = UNIT_ART_HELPER.get_enemy_unit_art_texture(COMMON_SLIME_DATA)
	if enemy_texture == null:
		failures.append("Expected common_slime enemy unit art to load.")
	elif enemy_texture.get_width() <= 0 or enemy_texture.get_height() <= 0:
		failures.append("Loaded common_slime enemy art has invalid dimensions.")

	var enemy_thumbnail: Texture2D = UNIT_ART_HELPER.get_enemy_unit_art_texture_sized(COMMON_SLIME_DATA, Vector2i(96, 96))
	if enemy_thumbnail == null:
		failures.append("Expected common_slime enemy unit art thumbnail to load.")
	elif enemy_thumbnail.get_width() != 96 or enemy_thumbnail.get_height() != 96:
		failures.append("Expected 96x96 common_slime thumbnail, got " + str(enemy_thumbnail.get_width()) + "x" + str(enemy_thumbnail.get_height()) + ".")

	if not UNIT_ART_HELPER.has_enemy_unit_art(COMMON_SLIME_DATA):
		failures.append("Expected has_enemy_unit_art(common_slime) to return true.")

	var enemy_unit: Unit = UNIT_SCENE.instantiate() as Unit
	enemy_unit.unit_data = COMMON_SLIME_DATA.duplicate(true)
	get_root().add_child(enemy_unit)
	await process_frame

	if enemy_unit.board_sprite == null:
		failures.append("Expected enemy generated unit art to populate board_sprite.")
	if enemy_unit.portrait_texture == null:
		failures.append("Expected enemy generated unit art to populate portrait_texture.")
	if enemy_unit.icon_texture == null:
		failures.append("Expected enemy generated unit art to populate icon_texture.")
	if not enemy_unit.has_board_art():
		failures.append("Expected enemy unit to show board art after applying generated art.")

	enemy_unit.queue_free()
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("Unit art helper tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
