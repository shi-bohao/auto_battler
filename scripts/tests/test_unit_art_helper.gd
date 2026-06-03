extends SceneTree

const UNIT_ART_HELPER: Script = preload("res://scripts/unit_art_helper.gd")
const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")
const COMMON_SLIME_DATA: Resource = preload("res://data/enemies/common_slime.tres")
const IRON_OATH_COMMANDER_DATA: Resource = preload("res://data/heroes/iron_oath_commander_unit.tres")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	# Test 1: get_texture_sized still works for configured textures
	var hero_portrait: Texture2D = IRON_OATH_COMMANDER_DATA.get("portrait_texture") as Texture2D
	var hero_thumbnail: Texture2D = UNIT_ART_HELPER.get_texture_sized(hero_portrait, "test_iron_oath_portrait", Vector2i(96, 96))
	if hero_thumbnail == null:
		failures.append("Expected configured hero portrait thumbnail to load.")
	elif hero_thumbnail.get_width() != 96 or hero_thumbnail.get_height() != 96:
		failures.append("Expected 96x96 hero portrait thumbnail, got " + str(hero_thumbnail.get_width()) + "x" + str(hero_thumbnail.get_height()) + ".")

	# Test 2: Player unit with explicit texture references
	var player_unit: Unit = UNIT_SCENE.instantiate() as Unit
	player_unit.unit_data = WARRIOR_DATA.duplicate(true)
	get_root().add_child(player_unit)
	await process_frame

	if player_unit.board_sprite == null:
		failures.append("Expected player unit board_sprite to be populated from .tres.")
	if player_unit.portrait_texture == null:
		failures.append("Expected player unit portrait_texture to be populated from .tres.")
	if player_unit.icon_texture == null:
		failures.append("Expected player unit icon_texture to be populated from .tres.")
	if not player_unit.has_board_art():
		failures.append("Expected player unit to show board art.")

	player_unit.queue_free()

	# Test 3: Enemy unit with explicit texture references
	var enemy_unit: Unit = UNIT_SCENE.instantiate() as Unit
	enemy_unit.unit_data = COMMON_SLIME_DATA.duplicate(true)
	get_root().add_child(enemy_unit)
	await process_frame

	if enemy_unit.board_sprite == null:
		failures.append("Expected enemy unit board_sprite to be populated from .tres.")
	if enemy_unit.portrait_texture == null:
		failures.append("Expected enemy unit portrait_texture to be populated from .tres.")
	if enemy_unit.icon_texture == null:
		failures.append("Expected enemy unit icon_texture to be populated from .tres.")
	if not enemy_unit.has_board_art():
		failures.append("Expected enemy unit to show board art.")

	enemy_unit.queue_free()

	# Test 4: Placeholder (ColorRect) when no texture is configured
	var bare_unit: Unit = UNIT_SCENE.instantiate() as Unit
	get_root().add_child(bare_unit)
	await process_frame

	if bare_unit.has_board_art():
		failures.append("Expected bare unit to NOT show board art when no texture is configured.")
	# ColorRect placeholder should be visible (modulate.a = 1.0)
	var body: ColorRect = bare_unit.get_node_or_null("Body ColorRect") as ColorRect
	if body == null:
		failures.append("Expected bare unit to have Body ColorRect for placeholder.")
	elif body.modulate.a <= 0.0:
		failures.append("Expected placeholder ColorRect to be visible when no texture configured.")

	bare_unit.queue_free()
	_finish()


func _finish() -> void:
	if failures.is_empty():
		print("Unit art helper tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
