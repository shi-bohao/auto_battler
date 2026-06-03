class_name BattleBoard
extends Node2D

signal layout_changed(old_board_origin: Vector2, old_cell_size: float)

const ROW_COUNT: int = 7
const COLUMN_COUNT: int = 15
const PLAYER_MIN_COL: int = 0
const PLAYER_MAX_COL: int = 6
const GAP_COL: int = 7
const ENEMY_MIN_COL: int = 8
const ENEMY_MAX_COL: int = 14
const BENCH_SLOT_COUNT: int = 15
const INVALID_CELL: Vector2i = Vector2i(-1, -1)

@export var board_origin: Vector2 = Vector2(240.0, 204.0)
@export var cell_size: float = 96.0
@export var unit_origin_offset: Vector2 = Vector2(20.0, 20.0)
@export var max_cell_size: float = 90.0
@export var min_cell_size: float = 42.0
@export var viewport_width_ratio: float = 0.78
@export var viewport_height_ratio: float = 0.80
@export var bench_gap_ratio: float = 0.25
@export var board_layout_offset: Vector2 = Vector2(0.0, 48.0)
@export var background_texture: Texture2D = null
@export var background_options: Array[Texture2D] = []
@export var background_names: Array[String] = []
@export var background_index: int = 0
@export var board_texture: Texture2D = null
@export var textured_board_margin_ratio: Vector2 = Vector2(0.015, 0.018)
@export var show_grid: bool = true

var is_bench_visible: bool = true


func _ready() -> void:
	z_index = -20
	_update_board_layout()
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.size_changed.connect(_on_viewport_size_changed)
	queue_redraw()


func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1920.0, 1080.0)

	_draw_background_texture(viewport_size)

	var board_size: Vector2 = Vector2(float(COLUMN_COUNT) * cell_size, float(ROW_COUNT) * cell_size)
	var player_rect: Rect2 = Rect2(board_origin, Vector2(7.0 * cell_size, board_size.y))
	var gap_rect: Rect2 = Rect2(board_origin + Vector2(7.0 * cell_size, 0.0), Vector2(cell_size, board_size.y))
	var enemy_rect: Rect2 = Rect2(board_origin + Vector2(8.0 * cell_size, 0.0), Vector2(7.0 * cell_size, board_size.y))
	var bench_rect: Rect2 = Rect2(get_bench_origin(), Vector2(float(BENCH_SLOT_COUNT) * cell_size, cell_size))

	if show_grid:
		_draw_battle_grid(board_size, player_rect, gap_rect, enemy_rect)

	_draw_bench_grid(bench_rect)


func _draw_battle_grid(board_size: Vector2, player_rect: Rect2, gap_rect: Rect2, enemy_rect: Rect2) -> void:
	var grid_line_width: float = maxf(2.0, round(cell_size * 0.025))
	var border_line_width: float = maxf(4.0, round(cell_size * 0.045))
	for column: int in range(COLUMN_COUNT + 1):
		var x: float = board_origin.x + float(column) * cell_size
		var line_color: Color = Color(0.90, 1.0, 0.76, 0.34)
		if column == GAP_COL or column == GAP_COL + 1:
			line_color = Color(1.0, 0.95, 0.72, 0.50)
		draw_line(Vector2(x, board_origin.y), Vector2(x, board_origin.y + board_size.y), line_color, grid_line_width)

	for row: int in range(ROW_COUNT + 1):
		var y: float = board_origin.y + float(row) * cell_size
		draw_line(Vector2(board_origin.x, y), Vector2(board_origin.x + board_size.x, y), Color(0.90, 1.0, 0.76, 0.34), grid_line_width)

	draw_rect(player_rect, Color(0.40, 0.92, 0.48, 0.55), false, border_line_width)
	draw_rect(gap_rect, Color(1.0, 0.95, 0.72, 0.34), false, border_line_width)
	draw_rect(enemy_rect, Color(1.0, 0.45, 0.30, 0.55), false, border_line_width)


func _draw_background_texture(viewport_size: Vector2) -> void:
	var texture: Texture2D = get_current_background_texture()
	if texture == null:
		return

	var texture_size: Vector2 = texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var scale_value: float = maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	var draw_size: Vector2 = texture_size * scale_value
	var draw_position: Vector2 = (viewport_size - draw_size) * 0.5
	draw_texture_rect(texture, Rect2(draw_position, draw_size), false)


func get_current_background_texture() -> Texture2D:
	if not background_options.is_empty():
		var safe_index: int = posmod(background_index, background_options.size())
		var texture: Texture2D = background_options[safe_index]
		if texture != null:
			return texture

	return background_texture


func get_current_background_number() -> int:
	if background_options.is_empty():
		return 1
	return posmod(background_index, background_options.size()) + 1


func get_current_background_index() -> int:
	if background_options.is_empty():
		return 0
	return posmod(background_index, background_options.size())


func get_background_count() -> int:
	return maxi(background_options.size(), 1)


func get_background_name(index: int) -> String:
	if background_options.is_empty():
		return "默认背景"

	var safe_index: int = posmod(index, background_options.size())
	if safe_index >= 0 and safe_index < background_names.size():
		var display_name: String = background_names[safe_index].strip_edges()
		if display_name != "":
			return display_name
	return "背景 " + str(safe_index + 1)


func get_current_background_name() -> String:
	return get_background_name(get_current_background_index())


func set_background_index(value: int) -> void:
	if background_options.is_empty():
		background_index = 0
	else:
		background_index = posmod(value, background_options.size())
	queue_redraw()


func set_background_catalog(textures: Array[Texture2D], names: Array[String], selected_index: int = 0) -> void:
	background_options = textures.duplicate()
	background_names = names.duplicate()
	set_background_index(selected_index)


func cycle_background() -> int:
	var count: int = get_background_count()
	if count <= 1:
		return get_current_background_number()

	background_index = posmod(background_index + 1, count)
	queue_redraw()
	return get_current_background_number()


func _draw_board_texture(board_size: Vector2) -> void:
	var margin: Vector2 = Vector2(
		board_size.x * textured_board_margin_ratio.x,
		board_size.y * textured_board_margin_ratio.y
	)
	draw_texture_rect(
		board_texture,
		Rect2(board_origin - margin, board_size + margin * 2.0),
		false
	)


func _draw_bench_grid(bench_rect: Rect2) -> void:
	if not is_bench_visible:
		return

	var grid_line_width: float = maxf(2.0, round(cell_size * 0.025))
	var border_line_width: float = maxf(4.0, round(cell_size * 0.045))
	draw_rect(bench_rect, Color(0.04, 0.05, 0.035, 0.50), true)
	for slot_index: int in range(BENCH_SLOT_COUNT + 1):
		var bench_x: float = bench_rect.position.x + float(slot_index) * cell_size
		draw_line(Vector2(bench_x, bench_rect.position.y), Vector2(bench_x, bench_rect.position.y + cell_size), Color(0.90, 0.78, 0.48, 0.30), grid_line_width)
	draw_line(bench_rect.position, bench_rect.position + Vector2(bench_rect.size.x, 0.0), Color(0.90, 0.78, 0.48, 0.30), grid_line_width)
	draw_line(bench_rect.position + Vector2(0.0, cell_size), bench_rect.position + bench_rect.size, Color(0.90, 0.78, 0.48, 0.30), grid_line_width)
	draw_rect(bench_rect, Color(0.90, 0.64, 0.32, 0.48), false, border_line_width)


func set_grid_visible(value: bool) -> void:
	show_grid = value
	queue_redraw()


func toggle_grid_visible() -> bool:
	show_grid = not show_grid
	queue_redraw()
	return show_grid


func is_grid_visible() -> bool:
	return show_grid


func set_bench_visible(value: bool) -> void:
	is_bench_visible = value
	queue_redraw()


func _on_viewport_size_changed() -> void:
	var old_board_origin: Vector2 = board_origin
	var old_cell_size: float = cell_size
	_update_board_layout()
	if _did_layout_change(old_board_origin, old_cell_size):
		layout_changed.emit(old_board_origin, old_cell_size)
	queue_redraw()


func _update_board_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(1920.0, 1080.0)

	var width_based_cell: float = viewport_size.x * viewport_width_ratio / float(COLUMN_COUNT)
	var layout_rows: float = float(ROW_COUNT) + bench_gap_ratio + 1.0
	var height_based_cell: float = viewport_size.y * viewport_height_ratio / layout_rows
	cell_size = clampf(minf(width_based_cell, height_based_cell), min_cell_size, max_cell_size)

	var board_size: Vector2 = Vector2(float(COLUMN_COUNT) * cell_size, float(ROW_COUNT) * cell_size)
	var layout_size: Vector2 = Vector2(board_size.x, board_size.y + cell_size * bench_gap_ratio + cell_size)
	board_origin = (viewport_size - layout_size) * 0.5 + board_layout_offset


func grid_to_world(cell: Vector2i) -> Vector2:
	return board_origin + Vector2((float(cell.x) + 0.5) * cell_size, (float(cell.y) + 0.5) * cell_size) - unit_origin_offset


func remap_world_position_from_layout(world_position: Vector2, old_board_origin: Vector2, old_cell_size: float) -> Vector2:
	if old_cell_size <= 0.0:
		return world_position

	var board_space_position: Vector2 = (world_position + unit_origin_offset - old_board_origin) / old_cell_size
	return board_origin + board_space_position * cell_size - unit_origin_offset


func world_to_grid(world_position: Vector2) -> Vector2i:
	var local_position: Vector2 = world_position + unit_origin_offset - board_origin
	return Vector2i(floori(local_position.x / cell_size), floori(local_position.y / cell_size))


func get_bench_origin() -> Vector2:
	return board_origin + Vector2(0.0, float(ROW_COUNT) * cell_size + cell_size * bench_gap_ratio)


func bench_slot_to_world(slot_index: int) -> Vector2:
	return get_bench_origin() + Vector2((float(slot_index) + 0.5) * cell_size, 0.5 * cell_size) - unit_origin_offset


func world_to_bench_slot(world_position: Vector2) -> int:
	if not is_bench_visible:
		return -1

	var local_position: Vector2 = world_position + unit_origin_offset - get_bench_origin()
	var slot_index: int = floori(local_position.x / cell_size)
	var is_inside_y: bool = local_position.y >= 0.0 and local_position.y < cell_size
	if not is_inside_y or slot_index < 0 or slot_index >= BENCH_SLOT_COUNT:
		return -1

	return slot_index


func is_valid_bench_slot(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < BENCH_SLOT_COUNT


func is_bench_slot_occupied(slot_index: int, units: Array, ignored_unit: Variant = null) -> bool:
	if not is_valid_bench_slot(slot_index):
		return true

	for unit_value: Variant in units:
		if unit_value == null or not is_instance_valid(unit_value):
			continue

		if ignored_unit != null and unit_value == ignored_unit:
			continue

		if world_to_bench_slot(unit_value.position) == slot_index:
			return true

	return false


func is_within_board(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLUMN_COUNT and cell.y >= 0 and cell.y < ROW_COUNT


func is_valid_player_cell(cell: Vector2i) -> bool:
	return is_within_board(cell) and cell.x >= PLAYER_MIN_COL and cell.x <= PLAYER_MAX_COL


func is_valid_enemy_cell(cell: Vector2i) -> bool:
	return is_within_board(cell) and cell.x >= ENEMY_MIN_COL and cell.x <= ENEMY_MAX_COL


func is_gap_cell(cell: Vector2i) -> bool:
	return is_within_board(cell) and cell.x == GAP_COL


func get_player_drop_position(unit: Variant, fallback_position: Vector2) -> Vector2:
	if unit == null or not is_instance_valid(unit):
		return fallback_position

	var target_cell: Vector2i = world_to_grid(unit.position)
	if not is_valid_player_cell(target_cell):
		return fallback_position

	if is_cell_occupied(target_cell, unit.ally_units, unit):
		return fallback_position

	return grid_to_world(target_cell)


func is_cell_occupied(cell: Vector2i, units: Array, ignored_unit: Variant = null) -> bool:
	for unit_value: Variant in units:
		if unit_value == null or not is_instance_valid(unit_value):
			continue

		if ignored_unit != null and unit_value == ignored_unit:
			continue

		if not bool(unit_value.is_alive):
			continue

		if world_to_grid(unit_value.position) == cell:
			return true

	return false


func choose_player_cell_for_roster_item(roster_item: Dictionary, occupied_cells: Array[Vector2i]) -> Vector2i:
	var unit_id: String = str(roster_item.get("unit_id", ""))
	var role: String = _get_roster_item_role(roster_item)

	if bool(roster_item.get("has_saved_cell", false)):
		var saved_cell: Vector2i = roster_item.get("saved_cell", INVALID_CELL) as Vector2i
		if is_valid_player_cell(saved_cell) and not _is_cell_in_list(saved_cell, occupied_cells):
			return saved_cell

	if bool(roster_item.get("has_saved_position", false)):
		var saved_position: Vector2 = roster_item.get("saved_position", Vector2.ZERO) as Vector2
		var legacy_cell: Vector2i = world_to_grid(saved_position)
		if is_valid_player_cell(legacy_cell) and not _is_cell_in_list(legacy_cell, occupied_cells):
			return legacy_cell

	return get_recommended_cell_for_unit(unit_id, role, true, occupied_cells, false)


func choose_enemy_cell_for_unit(unit_id: String, role: String, occupied_cells: Array[Vector2i], is_boss: bool) -> Vector2i:
	return get_recommended_cell_for_unit(unit_id, role, false, occupied_cells, is_boss)


func get_recommended_cell_for_unit(
	unit_id: String,
	role: String,
	is_player_side: bool,
	occupied_cells: Array[Vector2i],
	is_boss: bool = false
) -> Vector2i:
	var recommended_cells: Array[Vector2i] = _get_recommended_cells(unit_id, role, is_player_side, is_boss)
	for cell: Vector2i in recommended_cells:
		if _is_valid_side_cell(cell, is_player_side) and not _is_cell_in_list(cell, occupied_cells):
			return cell

	var fallback_cells: Array[Vector2i] = _get_fallback_cells(unit_id, role, is_player_side)
	for cell: Vector2i in fallback_cells:
		if not _is_cell_in_list(cell, occupied_cells):
			return cell

	return INVALID_CELL


func get_unit_role_from_data(unit_data: Resource, unit_id: String) -> String:
	if unit_data != null:
		var configured_role: Variant = unit_data.get("role")
		if configured_role != null and str(configured_role).strip_edges() != "":
			return str(configured_role)

	match unit_id:
		"warrior", "tank", "guardian_captain":
			return "tank"
		"priest", "bard", "forest_druid", "wind_chanter":
			return "support"
		_:
			return "damage"


func _get_roster_item_role(roster_item: Dictionary) -> String:
	var unit_data: Resource = roster_item.get("unit_data", null) as Resource
	var unit_id: String = str(roster_item.get("unit_id", ""))
	return get_unit_role_from_data(unit_data, unit_id)


func _get_recommended_cells(unit_id: String, role: String, is_player_side: bool, is_boss: bool) -> Array[Vector2i]:
	var player_cells: Array[Vector2i] = []
	if is_boss:
		if role == "support":
			player_cells = [Vector2i(1, 3), Vector2i(0, 3), Vector2i(1, 2), Vector2i(1, 4)]
		elif role == "damage":
			player_cells = [Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 2), Vector2i(0, 4)]
		else:
			player_cells = [Vector2i(6, 3), Vector2i(5, 3), Vector2i(6, 2), Vector2i(6, 4)]
	else:
		player_cells = _get_player_recommended_cells(unit_id, role)

	if is_player_side:
		return player_cells

	var enemy_cells: Array[Vector2i] = []
	for cell: Vector2i in player_cells:
		enemy_cells.append(_mirror_player_cell_to_enemy(cell))
	return enemy_cells


func _get_player_recommended_cells(unit_id: String, role: String) -> Array[Vector2i]:
	match unit_id:
		"warrior":
			return [Vector2i(6, 2), Vector2i(6, 4), Vector2i(5, 2), Vector2i(5, 4), Vector2i(6, 3), Vector2i(5, 3)]
		"greatsword_knight":
			return [Vector2i(5, 2), Vector2i(5, 4), Vector2i(6, 2), Vector2i(6, 4), Vector2i(5, 3), Vector2i(6, 3)]
		"tank":
			return [Vector2i(6, 3), Vector2i(6, 2), Vector2i(6, 4), Vector2i(5, 3), Vector2i(5, 2), Vector2i(5, 4)]
		"guardian_captain":
			return [Vector2i(6, 3), Vector2i(5, 3), Vector2i(6, 2), Vector2i(6, 4), Vector2i(5, 2), Vector2i(5, 4)]
		"enemy_shield_guard":
			return [Vector2i(6, 2), Vector2i(6, 4), Vector2i(5, 2), Vector2i(5, 4), Vector2i(6, 3), Vector2i(5, 3)]
		"enemy_stoneback_beast", "enemy_elite_iron_warden", "enemy_elite_iron_bulwark", "enemy_elite_mirror_carapace_beetle", "enemy_boss_earthbreaker_colossus", "enemy_boss_treant_overlord", "enemy_boss_swamp_devourer", "enemy_boss_lava_colossus":
			return [Vector2i(6, 3), Vector2i(5, 3), Vector2i(6, 2), Vector2i(6, 4), Vector2i(5, 2), Vector2i(5, 4)]
		"enemy_common_slime", "enemy_frost_slime", "enemy_flame_slime", "enemy_venom_slime", "enemy_giant_slime":
			return [Vector2i(6, 3), Vector2i(6, 2), Vector2i(6, 4), Vector2i(5, 3), Vector2i(5, 2), Vector2i(5, 4)]
		"archer":
			return [Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 2), Vector2i(1, 4), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)]
		"bomb_thrower":
			return [Vector2i(0, 1), Vector2i(0, 5), Vector2i(1, 1), Vector2i(1, 5), Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 3)]
		"enemy_crossbow_raider":
			return [Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 2), Vector2i(1, 4), Vector2i(0, 3), Vector2i(1, 3)]
		"assassin":
			return [Vector2i(4, 1), Vector2i(4, 5), Vector2i(3, 1), Vector2i(3, 5), Vector2i(4, 2), Vector2i(4, 4), Vector2i(3, 3)]
		"enemy_elite_shadow_reaper":
			return [Vector2i(4, 1), Vector2i(4, 5), Vector2i(3, 1), Vector2i(3, 5), Vector2i(4, 2), Vector2i(4, 4)]
		"mage":
			return [Vector2i(1, 3), Vector2i(0, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(0, 2), Vector2i(0, 4), Vector2i(2, 3)]
		"alchemist":
			return [Vector2i(1, 3), Vector2i(0, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(0, 2), Vector2i(0, 4), Vector2i(2, 3)]
		"plague_caster":
			return [Vector2i(1, 3), Vector2i(0, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(2, 3), Vector2i(0, 2), Vector2i(0, 4)]
		"enemy_flame_imp", "enemy_boss_crystal_cannon":
			return [Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 2), Vector2i(1, 4)]
		"priest":
			return [Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(2, 3)]
		"cleric":
			return [Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(2, 3), Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 4)]
		"forest_druid":
			return [Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(2, 3)]
		"enemy_dark_acolyte", "enemy_elite_blood_oracle", "enemy_elite_frost_thorn_witch":
			return [Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 4)]
		"bard":
			return [Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 4), Vector2i(2, 3)]
		"wind_chanter":
			return [Vector2i(1, 3), Vector2i(0, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(0, 2), Vector2i(0, 4), Vector2i(2, 3)]
		"enemy_war_drummer", "enemy_elite_blood_banner_warlord", "enemy_boss_goblin_high_priest", "enemy_boss_scourge_lord", "enemy_boss_faelord_of_the_grove":
			return [Vector2i(1, 3), Vector2i(0, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(0, 2), Vector2i(0, 4)]
		_:
			return _get_default_player_cells_for_role(role)


func _get_default_player_cells_for_role(role: String) -> Array[Vector2i]:
	match role:
		"tank":
			return [Vector2i(6, 3), Vector2i(6, 2), Vector2i(6, 4), Vector2i(5, 3), Vector2i(5, 2), Vector2i(5, 4)]
		"support":
			return [Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 4), Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 4)]
		_:
			return [Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 2), Vector2i(3, 4), Vector2i(4, 2), Vector2i(4, 4)]


func _get_fallback_cells(unit_id: String, role: String, is_player_side: bool) -> Array[Vector2i]:
	var player_columns: Array[int] = _get_player_fallback_columns(unit_id, role)
	var rows: Array[int] = [3, 2, 4, 1, 5, 0, 6]
	var fallback_cells: Array[Vector2i] = []
	for column: int in player_columns:
		for row: int in rows:
			var player_cell: Vector2i = Vector2i(column, row)
			fallback_cells.append(player_cell if is_player_side else _mirror_player_cell_to_enemy(player_cell))

	return fallback_cells


func _get_player_fallback_columns(unit_id: String, role: String) -> Array[int]:
	if role == "tank" or unit_id == "warrior" or unit_id == "tank" or unit_id == "greatsword_knight":
		return [6, 5]

	if unit_id == "guardian_captain":
		return [6, 5]

	if unit_id == "enemy_common_slime" \
		or unit_id == "enemy_frost_slime" \
		or unit_id == "enemy_flame_slime" \
		or unit_id == "enemy_venom_slime" \
		or unit_id == "enemy_giant_slime" \
		or unit_id == "enemy_elite_iron_bulwark" \
		or unit_id == "enemy_elite_mirror_carapace_beetle":
		return [6, 5]

	if unit_id == "assassin" or unit_id == "enemy_elite_shadow_reaper":
		return [4, 3]

	if role == "support" \
		or unit_id == "archer" \
		or unit_id == "mage" \
		or unit_id == "priest" \
		or unit_id == "bard" \
		or unit_id == "forest_druid" \
		or unit_id == "plague_caster" \
		or unit_id == "wind_chanter" \
		or unit_id == "bomb_thrower" \
		or unit_id == "cleric" \
		or unit_id == "alchemist" \
		or unit_id == "enemy_crossbow_raider" \
		or unit_id == "enemy_flame_imp" \
		or unit_id == "enemy_boss_crystal_cannon":
		return [0, 1, 2]

	return [3, 4]


func _mirror_player_cell_to_enemy(player_cell: Vector2i) -> Vector2i:
	return Vector2i(COLUMN_COUNT - 1 - player_cell.x, player_cell.y)


func _is_valid_side_cell(cell: Vector2i, is_player_side: bool) -> bool:
	return is_valid_player_cell(cell) if is_player_side else is_valid_enemy_cell(cell)


func _is_cell_in_list(cell: Vector2i, cells: Array[Vector2i]) -> bool:
	for existing_cell: Vector2i in cells:
		if existing_cell == cell:
			return true

	return false


func _did_layout_change(old_board_origin: Vector2, old_cell_size: float) -> bool:
	return old_board_origin.distance_to(board_origin) > 0.01 or absf(old_cell_size - cell_size) > 0.01
