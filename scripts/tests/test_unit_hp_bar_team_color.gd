extends SceneTree

const UNIT_SCENE: PackedScene = preload("res://scenes/unit.tscn")
const WARRIOR_DATA: Resource = preload("res://data/units/warrior.tres")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var player_unit: Unit = _create_unit(1)
	var enemy_unit: Unit = _create_unit(2)
	await process_frame

	var player_fill: StyleBoxFlat = _get_hp_fill_style(player_unit)
	var enemy_fill: StyleBoxFlat = _get_hp_fill_style(enemy_unit)

	if player_fill == null:
		failures.append("Player unit HP fill style should exist.")
	elif not _is_color_close(player_fill.bg_color, Unit.PLAYER_HP_FILL_COLOR):
		failures.append("Player unit HP bar should be green.")

	if enemy_fill == null:
		failures.append("Enemy unit HP fill style should exist.")
	elif not _is_color_close(enemy_fill.bg_color, Unit.ENEMY_HP_FILL_COLOR):
		failures.append("Enemy unit HP bar should remain red.")

	if player_fill != null and enemy_fill != null and player_fill == enemy_fill:
		failures.append("Player and enemy HP fill styles should be separate instances.")

	player_unit.queue_free()
	enemy_unit.queue_free()
	_finish()


func _create_unit(unit_team_id: int) -> Unit:
	var unit: Unit = UNIT_SCENE.instantiate() as Unit
	unit.team_id = unit_team_id
	unit.unit_data = WARRIOR_DATA.duplicate(true)
	get_root().add_child(unit)
	return unit


func _get_hp_fill_style(unit: Unit) -> StyleBoxFlat:
	var hp_bar: ProgressBar = unit.get_node("HPBar ProgressBar") as ProgressBar
	if hp_bar == null:
		return null
	return hp_bar.get_theme_stylebox("fill") as StyleBoxFlat


func _is_color_close(actual: Color, expected: Color) -> bool:
	return absf(actual.r - expected.r) < 0.01 \
		and absf(actual.g - expected.g) < 0.01 \
		and absf(actual.b - expected.b) < 0.01 \
		and absf(actual.a - expected.a) < 0.01


func _finish() -> void:
	if failures.is_empty():
		print("Unit HP bar team color tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
