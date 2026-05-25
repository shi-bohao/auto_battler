class_name BattleManager
extends RefCounted

signal battle_ended(result_text: String, player_won: bool)
signal overtime_started()

const OVERTIME_START_TIME: float = 60.0
const OVERTIME_DAMAGE_PER_SECOND: int = 10
const FIELD_EFFECT_MANAGER_SCRIPT: Script = preload("res://scripts/combat/field_effect_manager.gd")
const SUMMON_MANAGER_SCRIPT: Script = preload("res://scripts/summon_manager.gd")
const UNIT_SCALING_SERVICE_SCRIPT: Script = preload("res://scripts/roster/unit_scaling_service.gd")
const BOND_MANAGER_SCRIPT: Script = preload("res://scripts/bond_manager.gd")
const PROJECTILE_MANAGER_SCRIPT: Script = preload("res://scripts/combat/projectile_manager.gd")

var battle_root: Node = null
var unit_scene: PackedScene = null
var stats_manager: Variant = null
var relic_manager: RelicManager = null
var enemy_relic_manager: RelicManager = null
var battle_board: Variant = null
var prepare_drop_handler: Callable = Callable()
var hero_manager: Variant = null
var roster_manager: Variant = null
var bond_manager: Variant = BOND_MANAGER_SCRIPT.new()
var summon_manager: Variant = SUMMON_MANAGER_SCRIPT.new()
var summon_unit_scaling_service: Variant = UNIT_SCALING_SERVICE_SCRIPT.new()
var projectile_manager: Variant = PROJECTILE_MANAGER_SCRIPT.new()

var left_units: Array[Unit] = []
var right_units: Array[Unit] = []
var bench_units: Array[Unit] = []
var all_units: Array[Unit] = []
var is_battle_active: bool = false
var next_unit_id: int = 1
var battle_speed_multiplier: float = 1.0
var battle_elapsed_time: float = 0.0
var is_overtime_active: bool = false
var overtime_elapsed_time: float = 0.0
var overtime_damage_timer: float = 0.0
var overtime_damage_second: int = 0
var is_resolving_overtime_damage: bool = false
var field_effect_manager: Variant = FIELD_EFFECT_MANAGER_SCRIPT.new()


func setup(
	configured_battle_root: Node,
	configured_unit_scene: PackedScene,
	configured_stats_manager: Variant,
	configured_relic_manager: RelicManager,
	configured_battle_board: Variant = null,
	configured_prepare_drop_handler: Callable = Callable(),
	configured_hero_manager: Variant = null,
	configured_bond_manager: Variant = null
) -> void:
	battle_root = configured_battle_root
	unit_scene = configured_unit_scene
	stats_manager = configured_stats_manager
	relic_manager = configured_relic_manager
	if relic_manager != null:
		relic_manager.set_owner_team_id(1)
	battle_board = configured_battle_board
	prepare_drop_handler = configured_prepare_drop_handler
	hero_manager = configured_hero_manager
	if configured_bond_manager != null:
		bond_manager = configured_bond_manager
	field_effect_manager.setup(configured_battle_root)
	summon_manager.setup(self)
	projectile_manager.setup(configured_battle_root)


func set_hero_manager(configured_hero_manager: Variant) -> void:
	hero_manager = configured_hero_manager


func set_roster_manager(configured_roster_manager: Variant) -> void:
	roster_manager = configured_roster_manager


func set_enemy_relic_manager(configured_enemy_relic_manager: RelicManager) -> void:
	enemy_relic_manager = configured_enemy_relic_manager
	if enemy_relic_manager != null:
		enemy_relic_manager.set_owner_team_id(2)


func set_battle_speed_multiplier(value: float) -> void:
	battle_speed_multiplier = maxf(value, 0.01)
	for unit: Unit in all_units:
		if is_instance_valid(unit):
			unit.set_battle_time_scale(battle_speed_multiplier)
	for unit: Unit in bench_units:
		if is_instance_valid(unit):
			unit.set_battle_time_scale(battle_speed_multiplier)


func spawn_battle(player_unit_configs: Array[Dictionary], enemy_unit_configs: Array[Dictionary], bench_unit_configs: Array[Dictionary] = []) -> void:
	clear_battlefield()
	_spawn_player_team(player_unit_configs)
	_spawn_player_hero()
	_spawn_enemy_team(enemy_unit_configs)
	_spawn_bench_team(bench_unit_configs)
	_assign_enemy_lists()


func start_battle() -> void:
	is_battle_active = true
	_reset_overtime_state()
	_clear_bench_units()
	if stats_manager != null and stats_manager.has_method("start_battle_timer"):
		stats_manager.start_battle_timer()

	for unit in all_units:
		if is_instance_valid(unit):
			unit.set_battle_time_scale(battle_speed_multiplier)
			unit.start_battle()

	var battle_start_units: Array[Unit] = []
	battle_start_units.append_array(all_units)

	if bond_manager != null and bond_manager.has_method("apply_battle_start_bonds"):
		bond_manager.apply_battle_start_bonds(left_units)

	for unit in battle_start_units:
		if is_instance_valid(unit) and unit.is_alive:
			unit.unit_skill.apply_battle_start_passives(unit)

	if relic_manager != null:
		relic_manager.reset_battle_relic_state()
		relic_manager.trigger_battle_start_relics(_get_non_summon_units(left_units))
	if enemy_relic_manager != null:
		enemy_relic_manager.trigger_battle_start_relics(_get_non_summon_units(right_units))


func update(delta: float) -> void:
	if not is_battle_active:
		return

	if stats_manager != null and stats_manager.has_method("advance_battle_timer"):
		stats_manager.advance_battle_timer(delta)

	battle_elapsed_time += delta
	if not is_overtime_active and battle_elapsed_time >= OVERTIME_START_TIME:
		_enter_overtime()

	if is_overtime_active:
		_update_overtime_damage(delta)

	if summon_manager != null and summon_manager.has_method("update"):
		summon_manager.update(delta)

	field_effect_manager.update_fields(delta)


func clear_battlefield() -> void:
	is_battle_active = false
	_reset_overtime_state()
	field_effect_manager.clear_all_fields()

	for unit in all_units:
		if is_instance_valid(unit):
			unit.stop_battle()
			unit.queue_free()
	_clear_bench_units()

	left_units.clear()
	right_units.clear()
	all_units.clear()
	if stats_manager != null:
		stats_manager.clear()
	if summon_manager != null and summon_manager.has_method("clear"):
		summon_manager.clear()
	if bond_manager != null and bond_manager.has_method("clear"):
		bond_manager.clear()
	if projectile_manager != null and projectile_manager.has_method("clear_all"):
		projectile_manager.clear_all()
	next_unit_id = 1


func finish_battle() -> void:
	is_battle_active = false
	field_effect_manager.clear_all_fields()
	if projectile_manager != null and projectile_manager.has_method("clear_all"):
		projectile_manager.clear_all()
	if stats_manager != null and stats_manager.has_method("finish_battle_timer"):
		stats_manager.finish_battle_timer()

	for unit in all_units:
		if is_instance_valid(unit):
			unit.finish_battle()
			if stats_manager != null:
				stats_manager.capture_unit_snapshot(unit)
	if summon_manager != null and summon_manager.has_method("clear"):
		summon_manager.clear()


func get_left_units() -> Array[Unit]:
	return left_units


func get_right_units() -> Array[Unit]:
	return right_units


func get_all_units() -> Array[Unit]:
	return all_units


func get_bench_units() -> Array[Unit]:
	return bench_units


func create_damage_field(
	source_unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	damage_per_tick: int
) -> int:
	return field_effect_manager.create_damage_field(source_unit, center_position, radius, duration, tick_interval, damage_per_tick)


func create_visual_field(center_position: Vector2, radius: float, duration: float, color: Color) -> int:
	return field_effect_manager.create_visual_field(center_position, radius, duration, color)


func create_follow_visual_field(follow_unit: Variant, center_position: Vector2, radius: float, duration: float, color: Color) -> int:
	return field_effect_manager.create_follow_visual_field(follow_unit, center_position, radius, duration, color)



const AOE_SHAPE_VISUAL_SCRIPT: Script = preload("res://scripts/combat/aoe_shape_visual.gd")


func create_aoe_shape_visual(shape_data: Dictionary, color: Color, duration: float = 0.25) -> void:
	const UNIT_BODY_HALF: float = 20.0

	if battle_root == null or not is_instance_valid(battle_root):
		return

	# Determine visual anchor position from shape_data.
	# Units have Body ColorRect at (0,0)-(40,40), so node origin is top-left.
	# Offset by half body size so visuals appear visually centered.
	var shape_type: String = str(shape_data.get("shape_type", "circle"))
	var anchor: Vector2 = Vector2.ZERO
	if shape_type == "circle":
		anchor = shape_data.get("center", Vector2.ZERO) as Vector2
	else:
		anchor = shape_data.get("origin", Vector2.ZERO) as Vector2

	anchor += Vector2(UNIT_BODY_HALF, UNIT_BODY_HALF)

	var visual: Node2D = AOE_SHAPE_VISUAL_SCRIPT.new() as Node2D
	visual.global_position = anchor
	battle_root.add_child(visual)
	if visual.has_method("setup"):
		visual.setup(shape_data, color, duration, battle_speed_multiplier)
func create_heal_field(
	source_unit: Variant,
	follow_unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	heal_tick_values: Array[int],
	color: Color
) -> int:
	return field_effect_manager.create_heal_field(source_unit, follow_unit, center_position, radius, duration, tick_interval, heal_tick_values, color)


func summon_units(source_unit: Unit, summon_unit_data: Resource, count: int, context: Dictionary = {}) -> Array[Unit]:
	if summon_manager == null or not summon_manager.has_method("summon_units"):
		var empty_units: Array[Unit] = []
		return empty_units

	return summon_manager.summon_units(source_unit, summon_unit_data, count, context)


func spawn_summoned_unit(source_unit: Unit, summon_unit_data: Resource, spawn_position: Vector2, context: Dictionary = {}) -> Unit:
	if summon_unit_data == null:
		return null

	var team_id: int = int(context.get("team_id", source_unit.team_id if source_unit != null and is_instance_valid(source_unit) else 1))
	var runtime_summon_data: Resource = _create_summon_unit_data(source_unit, summon_unit_data, context)
	var display_name: String = str(context.get("display_name", _get_unit_display_name(team_id, runtime_summon_data)))
	var summoned_unit: Unit = _spawn_unit(team_id, runtime_summon_data, spawn_position, display_name, -1, "summon")
	if summoned_unit == null:
		return null

	summoned_unit.set_can_drag(false)
	summoned_unit.is_targetable = true
	if is_battle_active:
		summoned_unit.set_battle_time_scale(battle_speed_multiplier)
		summoned_unit.start_battle()
		if is_overtime_active:
			_apply_overtime_to_unit(summoned_unit)
	var initial_shield: int = int(context.get("initial_shield", 0))
	if initial_shield > 0:
		summoned_unit.add_shield(initial_shield, source_unit)
	if bond_manager != null and bond_manager.has_method("apply_bonds_to_summoned_unit"):
		bond_manager.apply_bonds_to_summoned_unit(summoned_unit)

	_assign_enemy_lists()
	return summoned_unit


func refresh_dynamic_relic_auras() -> void:
	if relic_manager != null and relic_manager.has_method("refresh_dynamic_relic_auras_for_units"):
		var player_units: Array[Unit] = []
		player_units.append_array(left_units)
		player_units.append_array(bench_units)
		relic_manager.refresh_dynamic_relic_auras_for_units(player_units)

	if enemy_relic_manager != null and enemy_relic_manager.has_method("refresh_dynamic_relic_auras_for_units"):
		enemy_relic_manager.refresh_dynamic_relic_auras_for_units(right_units)


func remove_summoned_unit(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	unit.stop_battle()
	unit.is_alive = false
	unit.is_targetable = false
	left_units.erase(unit)
	right_units.erase(unit)
	all_units.erase(unit)
	unit.queue_free()
	_assign_enemy_lists()
	_check_battle_result()


func _create_summon_unit_data(source_unit: Unit, summon_unit_data: Resource, context: Dictionary) -> Resource:
	var source_star: int = source_unit.star if source_unit != null and is_instance_valid(source_unit) else 1
	var summon_star: int = clampi(int(context.get("summon_star", source_star)), 1, 3)
	var unit_id: String = _get_unit_id(summon_unit_data)
	var display_name: String = _get_unit_display_name(1, summon_unit_data)
	var roster_item: Dictionary = {
		"unit_data": summon_unit_data,
		"unit_id": unit_id,
		"display_name": display_name,
		"star": summon_star,
	}
	var runtime_data: Resource = summon_unit_scaling_service.create_scaled_unit_data(roster_item, 1.0, 1.0)
	if runtime_data == null:
		return runtime_data

	var bonus_max_hp: int = int(context.get("bonus_max_hp", 0))
	if bonus_max_hp != 0:
		runtime_data.set("max_hp", maxi(1, int(runtime_data.get("max_hp")) + bonus_max_hp))

	var bonus_attack_damage: int = int(context.get("bonus_attack_damage", 0))
	if bonus_attack_damage != 0:
		runtime_data.set("attack_damage", maxi(1, int(runtime_data.get("attack_damage")) + bonus_attack_damage))

	return runtime_data


func add_player_unit(unit_data: Resource) -> void:
	if unit_data == null:
		return

	var unit_index: int = left_units.size()
	_spawn_unit(1, unit_data, _get_player_unit_position(unit_index), _get_unit_display_name(1, unit_data))
	_assign_enemy_lists()
	_reset_prepare_stats_registration()


func refresh_player_team(player_unit_configs: Array[Dictionary]) -> void:
	refresh_player_and_bench_units(player_unit_configs, [])


func refresh_player_and_bench_units(player_unit_configs: Array[Dictionary], bench_unit_configs: Array[Dictionary]) -> void:
	if is_battle_active:
		return

	_clear_left_units()
	_clear_bench_units()

	left_units.clear()
	_spawn_player_team(player_unit_configs)
	_spawn_player_hero()
	_spawn_bench_team(bench_unit_configs)
	_assign_enemy_lists()
	_reset_prepare_stats_registration()


func _spawn_player_team(player_unit_configs: Array[Dictionary]) -> void:
	if unit_scene == null or battle_root == null:
		return

	for index: int in range(player_unit_configs.size()):
		var unit_config: Dictionary = player_unit_configs[index]
		var unit_data: Resource = unit_config.get("unit_data", null) as Resource
		if unit_data == null:
			continue

		var position: Vector2 = unit_config.get("position", _get_player_unit_position(index)) as Vector2
		var display_name: String = str(unit_config.get("display_name", _get_unit_display_name(1, unit_data)))
		var roster_id: int = int(unit_config.get("roster_id", -1))
		_spawn_unit(1, unit_data, position, display_name, roster_id, "active")


func _spawn_player_hero() -> void:
	if unit_scene == null or battle_root == null:
		return

	if hero_manager == null:
		return

	if not hero_manager.has_method("get_hero_battle_unit_config"):
		return

	var hero_config: Dictionary = hero_manager.get_hero_battle_unit_config(battle_board, left_units)
	if hero_config.is_empty():
		return

	var unit_data: Resource = hero_config.get("unit_data", null) as Resource
	if unit_data == null:
		return

	var position: Vector2 = hero_config.get("position", _get_player_unit_position(left_units.size())) as Vector2
	var display_name: String = str(hero_config.get("display_name", _get_unit_display_name(1, unit_data)))
	var hero_unit: Unit = _spawn_unit(1, unit_data, position, display_name, -1, "hero")
	if hero_unit != null and hero_manager.has_method("apply_hero_runtime_state"):
		hero_manager.apply_hero_runtime_state(hero_unit, hero_config)


func _spawn_bench_team(bench_unit_configs: Array[Dictionary]) -> void:
	if unit_scene == null or battle_root == null:
		return

	for index: int in range(bench_unit_configs.size()):
		var unit_config: Dictionary = bench_unit_configs[index]
		var unit_data: Resource = unit_config.get("unit_data", null) as Resource
		if unit_data == null:
			continue

		var position: Vector2 = unit_config.get("position", Vector2.ZERO) as Vector2
		var display_name: String = str(unit_config.get("display_name", _get_unit_display_name(1, unit_data)))
		var roster_id: int = int(unit_config.get("roster_id", -1))
		_spawn_bench_unit(unit_data, position, display_name, roster_id)


func _spawn_enemy_team(enemy_unit_configs: Array[Dictionary]) -> void:
	if unit_scene == null or battle_root == null:
		return

	var occupied_cells: Array[Vector2i] = []
	for index: int in range(enemy_unit_configs.size()):
		var unit_config: Dictionary = enemy_unit_configs[index]
		var unit_data: Resource = unit_config.get("unit_data", null) as Resource
		if unit_data == null:
			continue

		var position: Vector2 = unit_config.get("position", _get_enemy_unit_position(index)) as Vector2
		var unit_id: String = str(unit_config.get("unit_id", _get_unit_id(unit_data)))
		var role: String = _get_unit_role(unit_data, unit_id)
		var is_boss: bool = bool(unit_config.get("is_boss", false))
		if battle_board != null and is_instance_valid(battle_board):
			var enemy_cell: Vector2i = unit_config.get("cell", Vector2i(-1, -1)) as Vector2i
			if enemy_cell != Vector2i(-1, -1):
				if battle_board.has_method("is_valid_enemy_cell") and not battle_board.is_valid_enemy_cell(enemy_cell):
					enemy_cell = Vector2i(-1, -1)
				elif _is_cell_in_list(enemy_cell, occupied_cells):
					enemy_cell = Vector2i(-1, -1)

			if enemy_cell == Vector2i(-1, -1):
				enemy_cell = battle_board.choose_enemy_cell_for_unit(unit_id, role, occupied_cells, is_boss)
			if enemy_cell != Vector2i(-1, -1):
				position = battle_board.grid_to_world(enemy_cell)
				occupied_cells.append(enemy_cell)

		var display_name: String = str(unit_config.get("display_name", _get_unit_display_name(2, unit_data)))
		_spawn_unit(2, unit_data, position, display_name)


func _spawn_unit(team_id: int, unit_data: Resource, spawn_position: Vector2, display_name: String, roster_id: int = -1, roster_area: String = "active") -> Unit:
	var unit: Unit = unit_scene.instantiate() as Unit
	unit.team_id = team_id
	unit.unit_id = next_unit_id
	unit.roster_id = roster_id
	unit.roster_area = roster_area
	next_unit_id += 1
	unit.position = spawn_position
	unit.unit_data = unit_data
	unit.display_name = display_name
	unit.stats_manager = stats_manager
	unit.battle_board = battle_board
	unit.prepare_drop_handler = prepare_drop_handler
	if roster_area == "summon":
		unit.set_meta("is_summon", true)
	unit.set_battle_time_scale(battle_speed_multiplier)
	unit.died.connect(_on_unit_died)
	unit.attack_landed.connect(_on_unit_attack_landed)
	unit.killed_target.connect(_on_unit_killed_target)
	if battle_root != null and battle_root.has_method("_on_unit_detail_requested"):
		unit.detail_requested.connect(Callable(battle_root, "_on_unit_detail_requested"))

	var body: ColorRect = unit.get_node("Body ColorRect") as ColorRect
	if team_id == 1 and roster_area == "hero":
		body.color = Color(0.95, 0.65, 0.22)
	elif roster_area == "summon":
		body.color = Color(0.36, 0.82, 0.95) if team_id == 1 else Color(0.72, 0.35, 0.88)
	else:
		body.color = Color(0.2, 0.55, 1.0) if team_id == 1 else Color(1.0, 0.35, 0.25)

	battle_root.add_child(unit)
	_apply_always_on_relics_to_unit(unit)
	if stats_manager != null:
		stats_manager.register_unit(unit)
	unit.stop_battle()
	unit.set_can_drag(team_id == 1)
	all_units.append(unit)
	if team_id == 1:
		left_units.append(unit)
	else:
		right_units.append(unit)
	return unit


func _spawn_bench_unit(unit_data: Resource, spawn_position: Vector2, display_name: String, roster_id: int) -> void:
	var unit: Unit = unit_scene.instantiate() as Unit
	unit.team_id = 1
	unit.unit_id = next_unit_id
	unit.roster_id = roster_id
	unit.roster_area = "bench"
	next_unit_id += 1
	unit.position = spawn_position
	unit.unit_data = unit_data
	unit.display_name = display_name
	unit.stats_manager = null
	unit.battle_board = battle_board
	unit.prepare_drop_handler = prepare_drop_handler
	unit.set_battle_time_scale(battle_speed_multiplier)
	if battle_root != null and battle_root.has_method("_on_unit_detail_requested"):
		unit.detail_requested.connect(Callable(battle_root, "_on_unit_detail_requested"))

	var body: ColorRect = unit.get_node("Body ColorRect") as ColorRect
	body.color = Color(0.25, 0.45, 0.75, 0.75)

	battle_root.add_child(unit)
	_apply_always_on_relics_to_unit(unit)
	unit.stop_battle()
	unit.is_targetable = false
	unit.set_can_drag(true)
	bench_units.append(unit)


func _clear_left_units() -> void:
	for unit in left_units:
		all_units.erase(unit)
		if is_instance_valid(unit):
			unit.stop_battle()
			unit.queue_free()

	left_units.clear()


func _clear_bench_units() -> void:
	for unit in bench_units:
		if is_instance_valid(unit):
			unit.stop_battle()
			unit.queue_free()

	bench_units.clear()


func _assign_enemy_lists() -> void:
	for unit in left_units:
		unit.set_enemy_units(right_units)
		unit.set_ally_units(left_units)

	for unit in right_units:
		unit.set_enemy_units(left_units)
		unit.set_ally_units(right_units)


func _reset_prepare_stats_registration() -> void:
	if is_battle_active or stats_manager == null:
		return

	stats_manager.clear()
	for unit in all_units:
		if is_instance_valid(unit):
			stats_manager.register_unit(unit)


func _on_unit_died(unit: Unit) -> void:
	if stats_manager != null:
		stats_manager.capture_unit_snapshot(unit)

	_notify_ally_death_passives(unit)

	if hero_manager != null and hero_manager.has_method("apply_hero_death_effect"):
		hero_manager.apply_hero_death_effect(unit, left_units)

	if summon_manager != null and summon_manager.has_method("handle_unit_death"):
		summon_manager.handle_unit_death(unit)

	if bond_manager != null and bond_manager.has_method("handle_unit_died"):
		bond_manager.handle_unit_died(unit, left_units)

	if unit.team_id == 1 and relic_manager != null:
		relic_manager.trigger_death_relics(unit, right_units, is_battle_active, left_units)
	elif unit.team_id == 2 and enemy_relic_manager != null:
		enemy_relic_manager.trigger_death_relics(unit, left_units, is_battle_active, right_units)

	left_units.erase(unit)
	right_units.erase(unit)
	all_units.erase(unit)
	_assign_enemy_lists()
	_check_battle_result()


func modify_status_effect_data_for_bonds(effect_data: Dictionary) -> Dictionary:
	if bond_manager != null and bond_manager.has_method("modify_status_effect_data"):
		return bond_manager.modify_status_effect_data(effect_data)

	return effect_data


func _notify_ally_death_passives(dead_unit: Unit) -> void:
	if dead_unit == null or not is_instance_valid(dead_unit):
		return

	var allies: Array[Unit] = left_units if dead_unit.team_id == 1 else right_units
	for ally: Unit in allies:
		if ally == null or not is_instance_valid(ally) or not ally.is_alive:
			continue
		if ally.unit_skill != null and ally.unit_skill.has_method("notify_ally_died"):
			ally.unit_skill.notify_ally_died(ally, dead_unit)


func _on_unit_attack_landed(attacker: Unit, target: Unit) -> void:
	if attacker != null and is_instance_valid(attacker) and attacker.team_id == 2 and enemy_relic_manager != null:
		enemy_relic_manager.trigger_attack_relics(attacker, target)
	elif relic_manager != null:
		relic_manager.trigger_attack_relics(attacker, target)


func _on_unit_killed_target(attacker: Unit, target: Unit) -> void:
	if attacker != null and is_instance_valid(attacker):
		attacker.unit_skill.apply_kill_passives(attacker, target)

	if summon_manager != null and summon_manager.has_method("handle_unit_killed_target"):
		summon_manager.handle_unit_killed_target(attacker, target)

	if attacker != null and is_instance_valid(attacker) and attacker.team_id == 2 and enemy_relic_manager != null:
		enemy_relic_manager.trigger_kill_relics(attacker, target)
	elif relic_manager != null:
		relic_manager.trigger_kill_relics(attacker, target, roster_manager, hero_manager)


func _apply_always_on_relics_to_unit(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var target_relic_manager: RelicManager = enemy_relic_manager if unit.team_id == 2 else relic_manager
	if target_relic_manager == null:
		return

	if target_relic_manager.has_method("apply_always_on_relics_to_runtime_unit"):
		target_relic_manager.apply_always_on_relics_to_runtime_unit(unit)


func _check_battle_result() -> void:
	if not is_battle_active:
		return

	if is_resolving_overtime_damage:
		return

	var left_alive_count: int = _get_alive_count(left_units)
	var right_alive_count: int = _get_alive_count(right_units)

	if left_alive_count > 0 and right_alive_count > 0:
		return

	if left_alive_count == 0 and right_alive_count == 0:
		_end_battle("Draw", false)
	elif left_alive_count == 0:
		_end_battle("Right Team Wins", false)
	else:
		_end_battle("Left Team Wins", true)


func _end_battle(result_text: String, player_won: bool) -> void:
	finish_battle()
	battle_ended.emit(result_text, player_won)


func _enter_overtime() -> void:
	is_overtime_active = true
	overtime_elapsed_time = 0.0
	overtime_damage_timer = 0.0
	overtime_damage_second = 0
	print("Overtime started.")

	for unit in all_units:
		if not is_instance_valid(unit) or not unit.is_alive:
			continue

		_apply_overtime_to_unit(unit)

	overtime_started.emit()


func _update_overtime_damage(delta: float) -> void:
	overtime_elapsed_time += delta
	overtime_damage_timer += delta

	while overtime_damage_timer >= 1.0 and is_battle_active:
		overtime_damage_timer -= 1.0
		overtime_damage_second += 1
		var damage: int = overtime_damage_second * OVERTIME_DAMAGE_PER_SECOND
		_apply_overtime_damage(damage)


func _apply_overtime_damage(damage: int) -> void:
	if damage <= 0:
		return

	is_resolving_overtime_damage = true
	var damage_targets: Array[Unit] = []
	for unit in all_units:
		damage_targets.append(unit)

	for unit in damage_targets:
		if is_instance_valid(unit) and unit.is_alive:
			unit.take_damage(damage, null, false)

	is_resolving_overtime_damage = false
	_check_battle_result()


func _reset_overtime_state() -> void:
	battle_elapsed_time = 0.0
	is_overtime_active = false
	overtime_elapsed_time = 0.0
	overtime_damage_timer = 0.0
	overtime_damage_second = 0
	is_resolving_overtime_damage = false


func _get_alive_count(units: Array[Unit]) -> int:
	var count: int = 0

	for unit in units:
		if is_instance_valid(unit) and unit.is_alive and _unit_affects_battle_result(unit):
			count += 1

	return count


func _apply_overtime_to_unit(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	if unit.has_method("add_stat_modifier"):
		unit.add_stat_modifier({
			"modifier_id": "system:overtime:attack_damage",
			"source_key": "system:overtime",
			"stat_name": "attack_damage",
			"stage": StatModifier.STAGE_FINAL_MULTIPLY,
			"value": 2.0,
		})
		unit.add_stat_modifier({
			"modifier_id": "system:overtime:attack_interval",
			"source_key": "system:overtime",
			"stat_name": "attack_interval",
			"stage": StatModifier.STAGE_FINAL_MULTIPLY,
			"value": 0.5,
		})
	else:
		unit.attack_damage = maxi(1, unit.attack_damage * 2)
		unit.attack_interval = maxf(0.05, unit.attack_interval * 0.5)
	unit.attack_cooldown = minf(unit.attack_cooldown, unit.attack_interval)


func _unit_affects_battle_result(unit: Unit) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false

	return bool(unit.get_meta("summon_affects_result", true))


func _get_non_summon_units(units: Array[Unit]) -> Array[Unit]:
	var filtered_units: Array[Unit] = []
	for unit in units:
		if unit == null or not is_instance_valid(unit):
			continue
		if bool(unit.get_meta("is_summon", false)):
			continue
		filtered_units.append(unit)

	return filtered_units


func _is_cell_in_list(cell: Vector2i, cells: Array[Vector2i]) -> bool:
	for existing_cell: Vector2i in cells:
		if existing_cell == cell:
			return true

	return false


func _get_player_unit_position(index: int) -> Vector2:
	var default_positions: Array[Vector2] = []
	default_positions.append(Vector2(160, 220))
	default_positions.append(Vector2(120, 320))
	default_positions.append(Vector2(180, 420))

	if index < default_positions.size():
		return default_positions[index]

	var extra_index: int = index - default_positions.size()
	var row: int = extra_index % 3
	var column: int = int(float(extra_index) / 3.0)
	var x_offset: float = float(column) * 70.0
	var y_offset: float = float(row) * 100.0

	return Vector2(80.0 - x_offset, 220.0 + y_offset)


func _get_enemy_unit_position(index: int) -> Vector2:
	var default_positions: Array[Vector2] = []
	default_positions.append(Vector2(760, 220))
	default_positions.append(Vector2(800, 320))
	default_positions.append(Vector2(740, 420))

	if index < default_positions.size():
		return default_positions[index]

	var extra_index: int = index - default_positions.size()
	var row: int = extra_index % 3
	var column: int = int(float(extra_index) / 3.0)
	var x_offset: float = float(column) * 70.0
	var y_offset: float = float(row) * 100.0

	return Vector2(820.0 + x_offset, 220.0 + y_offset)


func _get_unit_display_name(team_id: int, unit_data: Resource) -> String:
	var unit_name: String = "单位"

	if unit_data != null:
		var configured_cn_name: Variant = unit_data.get("unit_name_cn")
		if configured_cn_name != null and str(configured_cn_name).strip_edges() != "":
			unit_name = str(configured_cn_name)
			return unit_name

		var configured_name: Variant = unit_data.get("unit_name")
		if configured_name != null:
			unit_name = str(configured_name)

	return unit_name


func _get_unit_id(unit_data: Resource) -> String:
	if unit_data == null:
		return ""

	var configured_type: Variant = unit_data.get("unit_type")
	if configured_type != null and str(configured_type).strip_edges() != "":
		return str(configured_type)

	var configured_name: Variant = unit_data.get("unit_name")
	if configured_name != null and str(configured_name).strip_edges() != "":
		return str(configured_name).to_lower()

	return ""


func _get_unit_role(unit_data: Resource, unit_id: String) -> String:
	if battle_board != null and is_instance_valid(battle_board):
		return battle_board.get_unit_role_from_data(unit_data, unit_id)

	if unit_data != null:
		var configured_role: Variant = unit_data.get("role")
		if configured_role != null and str(configured_role).strip_edges() != "":
			return str(configured_role)

	match unit_id:
		"warrior", "tank":
			return "tank"
		"priest", "bard":
			return "support"
		_:
			return "damage"
