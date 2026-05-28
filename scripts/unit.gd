class_name Unit
extends Node2D

signal died(unit: Unit)
signal attack_landed(attacker: Unit, target: Unit)
signal killed_target(attacker: Unit, target: Unit)
signal detail_requested(unit: Unit)

enum TargetMode { NEAREST, LOWEST_HP }
enum UnitState { IDLE, MOVING, ATTACKING, DEAD }

const ATTACK_RANGE_TOLERANCE: float = 4.0
const UNIT_FEEDBACK_SCRIPT: Script = preload("res://scripts/unit_feedback.gd")
const UNIT_DRAG_CONTROLLER_SCRIPT: Script = preload("res://scripts/unit_drag_controller.gd")
const UNIT_DATA_APPLIER_SCRIPT: Script = preload("res://scripts/unit_data_applier.gd")
const UNIT_COMBAT_SCRIPT: Script = preload("res://scripts/unit_combat.gd")
const UNIT_TARGETING_SCRIPT: Script = preload("res://scripts/unit_targeting.gd")
const UNIT_SKILL_SCRIPT: Script = preload("res://scripts/unit_skill.gd")
const UNIT_EFFECT_CONTROLLER_SCRIPT: Script = preload("res://scripts/unit_effect_controller.gd")
const COMBAT_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/combat_resolver.gd")
const ATTACK_PAYLOAD_SCRIPT: Script = preload("res://scripts/combat/attack_payload.gd")
const UNIT_STAT_CONTROLLER_SCRIPT: Script = preload("res://scripts/combat/unit_stat_controller.gd")

@export var team_id: int = 0
@export var max_hp: int = 100
@export var attack_damage: int = 10
@export var crit_chance: float = 0.0
@export var crit_damage_multiplier: float = 1.5
@export var defense: int = 0
@export var skill_power: float = 0.0
@export var healing_power: float = 0.0
@export var shield_power: float = 0.0
@export var defense_penetration: int = 0
@export var life_steal: float = 0.0
@export var damage_reduction: float = 0.0
@export var damage_taken_multiplier: float = 1.0
@export var initial_mana: float = 0.0
@export var mana_on_attack: float = 0.0
@export var mana_on_hit_taken: float = 0.0
@export var status_resistance: float = 0.0
@export var dodge_chance: float = 0.0
@export var attack_range: float = 80.0
@export var search_range: float = 999.0
@export var move_speed: float = 120.0
@export var attack_interval: float = 1.0
@export var unit_data: Resource
@export var unit_type: String = "unit"
@export_enum("tank", "damage", "support") var role: String = "damage"
@export var bond_tags: Array[String] = []
@export var star: int = 1
@export_enum("COMMON", "FINE", "RARE", "EPIC", "LEGENDARY", "MYTHIC") var rarity: String = "COMMON"
@export var passive_id: String = ""
@export var active_skill_id: String = ""
@export var max_mana: int = 0
@export var mana_regen_per_second: float = 0.0
@export_enum("NEAREST", "LOWEST_HP") var target_mode: String = "NEAREST"
@export var target_search_interval: float = 0.1
@export var retarget_interval: float = 0.4
@export var lowest_hp_switch_threshold: float = 0.1
@export_enum("melee", "projectile") var basic_attack_type: String = "melee"
@export var projectile_speed: float = 500.0
@export_enum("arrow", "bolt", "magic", "holy", "flask", "bomb", "dark", "curse") var projectile_visual_type: String = "arrow"
@export var board_sprite: Texture2D = null
@export var portrait_texture: Texture2D = null
@export var icon_texture: Texture2D = null
@export var art_scale: float = 1.0
@export var art_offset: Vector2 = Vector2.ZERO

var unit_id: int = -1
var roster_id: int = -1
var roster_area: String = "active"
var display_name: String = "单位"
var hp: int = 0
var shield: int = 0
var current_mana: float = 0.0
var active_skill_damage_multiplier: float = 1.0
var active_heal_multiplier: float = 1.0
var is_alive: bool = true
var is_targetable: bool = true
var unit_state: int = UnitState.IDLE
var is_battle_active: bool = false
var battle_time_scale: float = 1.0
var battle_elapsed_time: float = 0.0
var enemy_units: Array[Unit] = []
var ally_units: Array[Unit] = []
var current_target: Unit = null
var attack_cooldown: float = 0.0
var target_search_timer: float = 0.0
var retarget_timer: float = 0.0
var stuck_check_timer: float = 0.5
var last_ai_position: Vector2 = Vector2.ZERO
var last_attack_count: int = 0
var attack_count: int = 0
var launch_count: int = 0
var stats_manager: Variant = null
var battle_board: Variant = null
var prepare_drop_handler: Callable = Callable()
var unit_feedback: Variant = UNIT_FEEDBACK_SCRIPT.new()
var drag_controller: Variant = UNIT_DRAG_CONTROLLER_SCRIPT.new()
var unit_data_applier: Variant = UNIT_DATA_APPLIER_SCRIPT.new()
var unit_combat: Variant = UNIT_COMBAT_SCRIPT.new()
var unit_targeting: Variant = UNIT_TARGETING_SCRIPT.new()
var unit_skill: Variant = UNIT_SKILL_SCRIPT.new()
var effect_controller: Variant = UNIT_EFFECT_CONTROLLER_SCRIPT.new()
var combat_resolver: Variant = COMBAT_RESOLVER_SCRIPT.new()
var stat_controller: Variant = UNIT_STAT_CONTROLLER_SCRIPT.new()
var visual_base_position: Vector2 = Vector2(20.0, 20.0)
var visual_motion_time: float = 0.0

@onready var body: ColorRect = $"Body ColorRect"
@onready var visual_root: Node2D = $"VisualRoot"
@onready var visual_animation_root: Node2D = $"VisualRoot/AnimationRoot"
@onready var board_sprite_node: Sprite2D = $"VisualRoot/AnimationRoot/BoardSprite"
@onready var hp_bar: ProgressBar = $"HPBar ProgressBar"
@onready var mana_bar: ProgressBar = $"ManaBar ProgressBar"
@onready var info_label: Label = $"InfoLabel Label"


func _ready() -> void:
	unit_data_applier.apply_unit_data(self, unit_data)
	hp = max_hp
	shield = 0
	current_mana = 0.0
	active_skill_damage_multiplier = 1.0
	active_heal_multiplier = 1.0
	damage_taken_multiplier = maxf(0.0, damage_taken_multiplier)
	stat_controller.capture_base_stats(self)
	is_alive = true
	is_targetable = true
	unit_state = UnitState.IDLE
	is_battle_active = false
	attack_cooldown = 0.0
	target_search_timer = 0.0
	retarget_timer = 0.0
	stuck_check_timer = 0.5
	last_ai_position = global_position
	last_attack_count = attack_count
	_update_hp_bar()
	_update_mana_bar()
	update_info_display()
	unit_skill.reset_mana(self)
	refresh_unit_art()


func reset_prepare_preview(configured_unit_data: Resource, configured_display_name: String) -> void:
	stop_battle()
	clear_status_effects(false, false)
	if stat_controller != null and stat_controller.has_method("clear_runtime_state"):
		stat_controller.clear_runtime_state()
	_clear_prepare_runtime_meta()

	unit_data = configured_unit_data
	display_name = configured_display_name
	unit_data_applier.apply_unit_data(self, unit_data)
	hp = max_hp
	shield = 0
	current_mana = 0.0
	active_skill_damage_multiplier = 1.0
	active_heal_multiplier = 1.0
	damage_taken_multiplier = maxf(0.0, damage_taken_multiplier)
	is_alive = true
	is_targetable = true
	unit_state = UnitState.IDLE
	is_battle_active = false
	current_target = null
	attack_cooldown = 0.0
	target_search_timer = 0.0
	retarget_timer = 0.0
	stuck_check_timer = 0.5
	last_ai_position = global_position
	attack_count = 0
	launch_count = 0
	last_attack_count = 0
	enemy_units.clear()
	ally_units.clear()
	if stat_controller != null:
		stat_controller.capture_base_stats(self)
	_update_hp_bar()
	_update_mana_bar()
	update_info_display()
	unit_skill.reset_mana(self)


func _clear_prepare_runtime_meta() -> void:
	for meta_name_value: Variant in get_meta_list():
		var meta_name: String = str(meta_name_value)
		if meta_name.begins_with("always_on_relic_"):
			remove_meta(meta_name)


func _input(event: InputEvent) -> void:
	if _handle_detail_input(event):
		return

	drag_controller.handle_input(event, self, body, is_battle_active, is_alive)


func _process(delta: float) -> void:
	if not is_alive or not is_battle_active:
		return

	var battle_delta: float = maxf(delta, 0.0) * maxf(battle_time_scale, 0.01)
	battle_elapsed_time += battle_delta
	update_status_effects(battle_delta)
	if not is_alive:
		return

	attack_cooldown = maxf(attack_cooldown - battle_delta, 0.0)
	_update_targeting(battle_delta)
	unit_skill.update(self, battle_delta)

	if not _is_valid_target(current_target):
		unit_state = UnitState.IDLE
		_update_visual_motion(battle_delta)
		return

	if _is_current_target_in_range():
		unit_state = UnitState.ATTACKING
		_attack_current_target()
	else:
		unit_state = UnitState.MOVING
		_move_toward_current_target(battle_delta)

	_check_targeting_stuck(battle_delta)
	_update_visual_motion(battle_delta)


func set_enemy_units(units: Array[Unit]) -> void:
	enemy_units.clear()
	for unit in units:
		if is_instance_valid(unit):
			enemy_units.append(unit)

	if not _is_valid_target(current_target):
		current_target = null
		target_search_timer = 0.0


func set_ally_units(units: Array[Unit]) -> void:
	ally_units.clear()
	for unit in units:
		if is_instance_valid(unit):
			ally_units.append(unit)


func set_can_drag(value: bool) -> void:
	drag_controller.set_can_drag(value)


func set_battle_time_scale(value: float) -> void:
	battle_time_scale = maxf(value, 0.01)


func start_battle() -> void:
	is_battle_active = true
	is_targetable = true
	set_can_drag(false)
	clear_status_effects()
	current_target = null
	battle_elapsed_time = 0.0
	attack_cooldown = 0.0
	target_search_timer = 0.0
	retarget_timer = 0.0
	stuck_check_timer = 0.5
	last_ai_position = global_position
	shield = 0
	active_skill_damage_multiplier = 1.0
	active_heal_multiplier = 1.0
	unit_state = UnitState.IDLE
	attack_count = 0
	launch_count = 0
	last_attack_count = attack_count
	if stats_manager != null:
		stats_manager.start_unit_battle(self)
	unit_skill.reset_mana(self)


func stop_battle() -> void:
	is_battle_active = false
	set_can_drag(false)
	clear_status_effects()
	current_target = null
	unit_state = UnitState.IDLE
	_reset_visual_motion()


func finish_battle() -> void:
	if stats_manager != null:
		stats_manager.finish_unit_battle(self)
	stop_battle()
	update_info_display()


func take_damage(amount: int, attacker: Unit = null, can_crit: bool = true) -> int:
	return unit_combat.take_damage(self, amount, attacker, can_crit)


func record_damage_dealt(amount: int) -> void:
	unit_combat.record_damage_dealt(self, amount)


func record_kill() -> void:
	unit_combat.record_kill(self)


func add_battle_attack_bonus_percent(percent: float) -> void:
	unit_combat.add_battle_attack_bonus_percent(self, percent)


func add_shield(amount: int, source: Unit = null) -> void:
	unit_combat.add_shield(self, amount, source)


func heal(amount: int, source: Unit = null) -> void:
	unit_combat.heal(self, amount, source)


func restore_mana(amount: float, source: Unit = null) -> float:
	if amount <= 0.0 or max_mana <= 0 or not is_alive:
		return 0.0

	var old_mana: float = current_mana
	current_mana = minf(float(max_mana), current_mana + amount)
	var restored_mana: float = current_mana - old_mana
	if restored_mana <= 0.0:
		return 0.0

	var stat_source: Unit = source if source != null else self
	if stat_source != null and is_instance_valid(stat_source) and stat_source.stats_manager != null:
		stat_source.stats_manager.record_mana_restored(stat_source, restored_mana)

	_update_mana_bar()
	update_info_display()
	if unit_skill != null and unit_skill.has_method("notify_mana_restored"):
		unit_skill.notify_mana_restored(self, restored_mana, stat_source)
	return restored_mana


func apply_runtime_stat_bonus(stat_name: String, amount: float, should_fill_current_hp: bool = false) -> void:
	if stat_name.strip_edges() == "" or is_zero_approx(amount):
		return

	if stat_controller != null and stat_controller.has_method("add_base_stat_bonus"):
		stat_controller.add_base_stat_bonus(self, stat_name, amount, should_fill_current_hp)
		return

	match stat_name:
		"max_hp":
			var hp_bonus: int = int(round(amount))
			if hp_bonus == 0:
				return
			max_hp = maxi(1, max_hp + hp_bonus)
			if should_fill_current_hp:
				hp = clampi(hp + hp_bonus, 0, max_hp)
			else:
				hp = clampi(hp, 0, max_hp)
			_update_hp_bar()
		"attack_damage":
			attack_damage = maxi(1, int(round(float(attack_damage) + amount)))
		"defense":
			defense = maxi(0, int(round(float(defense) + amount)))
		"defense_penetration":
			defense_penetration = maxi(0, int(round(float(defense_penetration) + amount)))
		"crit_chance":
			crit_chance = clampf(crit_chance + amount, 0.0, 1.0)
		"crit_damage_multiplier":
			crit_damage_multiplier = maxf(1.0, crit_damage_multiplier + amount)
		"life_steal":
			life_steal = clampf(life_steal + amount, 0.0, 1.0)
		"damage_reduction":
			damage_reduction = clampf(damage_reduction + amount, 0.0, 1.0)
		"damage_taken_multiplier":
			damage_taken_multiplier = maxf(0.05, damage_taken_multiplier + amount)
		"status_resistance":
			status_resistance = clampf(status_resistance + amount, 0.0, 1.0)
		"dodge_chance":
			dodge_chance = clampf(dodge_chance + amount, 0.0, 1.0)
		"attack_interval":
			attack_interval = maxf(0.05, attack_interval + amount)
		"move_speed":
			move_speed = maxf(1.0, move_speed + amount)
		"skill_power":
			skill_power += amount
		"healing_power":
			healing_power += amount
		"shield_power":
			shield_power += amount
		"initial_mana":
			initial_mana = maxf(0.0, initial_mana + amount)
			_update_mana_bar()
		"mana_on_attack":
			mana_on_attack = maxf(0.0, mana_on_attack + amount)
		"mana_on_hit_taken":
			mana_on_hit_taken = maxf(0.0, mana_on_hit_taken + amount)
		"mana_regen_per_second":
			mana_regen_per_second = maxf(0.0, mana_regen_per_second + amount)

	update_info_display()


func add_stat_modifier(modifier_data: Dictionary, context: Dictionary = {}) -> void:
	if stat_controller == null:
		return

	stat_controller.add_modifier(self, modifier_data, context)


func remove_stat_modifier(modifier_id: String, context: Dictionary = {}) -> void:
	if stat_controller == null:
		return

	stat_controller.remove_modifier(self, modifier_id, context)


func remove_stat_modifiers_by_source(source_key: String, context: Dictionary = {}) -> void:
	if stat_controller == null:
		return

	stat_controller.remove_modifiers_by_source(self, source_key, context)


func recalculate_stats(context: Dictionary = {}) -> void:
	if stat_controller == null:
		return

	stat_controller.recalculate(self, context)


func get_stat_modifier_count() -> int:
	if stat_controller == null or not stat_controller.has_method("get_modifier_count"):
		return 0

	return int(stat_controller.get_modifier_count())


func apply_status_effect(effect_data: Dictionary) -> StatusEffect:
	if effect_controller == null:
		return null

	return effect_controller.apply_effect(self, effect_data)


func update_status_effects(delta: float) -> void:
	if effect_controller == null:
		return

	effect_controller.update_effects(self, delta)


func clear_status_effects(should_update_display: bool = true, should_recalculate_stats: bool = true) -> void:
	if effect_controller == null:
		return

	effect_controller.clear_effects(self, should_update_display, should_recalculate_stats)
	if should_update_display:
		update_info_display()


func remove_status_effect(effect_id: String) -> int:
	if effect_controller == null:
		return 0

	var removed_count: int = int(effect_controller.remove_effects_by_id(effect_id))
	update_info_display()
	return removed_count


func get_status_effect_debug_lines() -> Array[String]:
	if effect_controller == null:
		var empty_lines: Array[String] = []
		return empty_lines

	return effect_controller.get_debug_lines()


func get_status_effect_count(effect_id: String) -> int:
	if effect_controller == null or not effect_controller.has_method("get_effect_count"):
		return 0

	return int(effect_controller.get_effect_count(effect_id))


func get_stats_snapshot() -> Dictionary:
	if stats_manager != null:
		return stats_manager.get_unit_snapshot(self)

	return {
		"unit_id": unit_id,
		"display_name": display_name,
		"team_id": team_id,
		"unit_type": unit_type,
		"shield": shield,
		"damage_dealt": 0,
		"damage_taken": 0,
		"healing_done": 0,
		"shield_given": 0,
		"mana_restored": 0.0,
		"kill_count": 0,
		"attack_count": attack_count,
		"survival_time": 0.0,
		"is_alive_at_end": is_alive,
	}


func emit_died_signal() -> void:
	died.emit(self)


func emit_killed_target_signal(target: Unit) -> void:
	killed_target.emit(self, target)


func _update_targeting(delta: float) -> void:
	unit_targeting.update_targeting(self, delta)


func _check_targeting_stuck(delta: float) -> void:
	unit_targeting.check_targeting_stuck(self, delta)


func _is_valid_target(target: Variant) -> bool:
	return unit_targeting.is_valid_target(self, target)


func _move_toward_current_target(delta: float) -> void:
	unit_targeting.move_toward_current_target(self, delta)


func _is_current_target_in_range() -> bool:
	return unit_targeting.is_current_target_in_range(self)


func _is_target_in_range(target: Variant) -> bool:
	return unit_targeting.is_target_in_range(self, target)


func _attack_current_target() -> void:
	if attack_cooldown > 0.0:
		return

	if not _is_current_target_in_range():
		return

	var attacked_target: Unit = current_target
	launch_count += 1

	if basic_attack_type == "projectile":
		# Ranged: snapshot damage, spawn projectile, set cooldown.
		# Hit resolution (stats, passives, relics, lifesteal) happens on projectile arrival.
		var damage: int = unit_skill.get_basic_attack_damage(self, attacked_target, attack_damage)
		var payload: Variant = ATTACK_PAYLOAD_SCRIPT.from_attacker(self, attacked_target, damage, battle_elapsed_time)

		# Check for enhanced attack (e.g. Bomb Thrower every 3rd launch)
		if passive_id == "unstable_bomb" and unit_skill.passive_resolver != null and unit_skill.passive_resolver.has_method("get_unstable_bomb_enhanced_data"):
			var enhanced_data: Dictionary = unit_skill.passive_resolver.get_unstable_bomb_enhanced_data(self)
			if not enhanced_data.is_empty():
				payload.is_enhanced = true
				payload.enhanced_radius = float(enhanced_data.get("radius", 0.0))
				payload.enhanced_damage = int(enhanced_data.get("damage", 0))
				payload.enhanced_visual_color = enhanced_data.get("visual_color", Color.WHITE)

		_spawn_basic_attack_projectile(attacked_target, payload)
		unit_feedback.play_attack_feedback(self)
		attack_cooldown = attack_interval
	else:
		# Melee: instant hit via unified resolver
		combat_resolver.resolve_basic_attack_hit(self, attacked_target, null)
		unit_feedback.play_attack_feedback(self)
		attack_cooldown = attack_interval

	if not _is_valid_target(current_target):
		current_target = null


func _spawn_basic_attack_projectile(target: Unit, payload: Variant) -> void:
	var battle_root: Node = get_parent()
	if battle_root == null or not is_instance_valid(battle_root):
		return
	if not battle_root.has_method("spawn_basic_attack_projectile"):
		return
	battle_root.spawn_basic_attack_projectile(self, target, payload, projectile_speed)


func refresh_unit_art() -> void:
	if visual_root == null or board_sprite_node == null or body == null:
		return

	visual_base_position = Vector2(20.0, 20.0) + art_offset
	visual_root.position = visual_base_position
	visual_animation_root.scale = Vector2.ONE
	board_sprite_node.modulate = Color.WHITE

	if board_sprite != null:
		board_sprite_node.texture = board_sprite
		board_sprite_node.visible = true
		var texture_size: Vector2 = board_sprite.get_size()
		var max_dimension: float = maxf(texture_size.x, texture_size.y)
		var fit_scale: float = 1.0
		if max_dimension > 0.0:
			fit_scale = 96.0 / max_dimension
		board_sprite_node.scale = Vector2.ONE * fit_scale * maxf(0.05, art_scale)
		body.modulate.a = 0.0
	else:
		board_sprite_node.texture = null
		board_sprite_node.visible = false
		body.modulate.a = 1.0


func has_board_art() -> bool:
	return board_sprite_node != null and board_sprite_node.texture != null


func get_feedback_target() -> Node2D:
	if has_board_art() and visual_animation_root != null:
		return visual_animation_root

	return self


func get_flash_target() -> CanvasItem:
	if has_board_art() and board_sprite_node != null:
		return board_sprite_node

	return body


func _update_visual_motion(delta: float) -> void:
	if visual_root == null:
		return

	if unit_state == UnitState.MOVING and has_board_art():
		visual_motion_time += delta
		visual_root.position = visual_base_position + Vector2(0.0, sin(visual_motion_time * 14.0) * 1.5)
		return

	if visual_root.position != visual_base_position:
		var t: float = clampf(delta * 12.0, 0.0, 1.0)
		visual_root.position = visual_root.position.lerp(visual_base_position, t)


func _reset_visual_motion() -> void:
	visual_motion_time = 0.0
	if visual_root != null:
		visual_root.position = visual_base_position
	if visual_animation_root != null:
		visual_animation_root.scale = Vector2.ONE


func _apply_basic_attack_attribute_rewards(actual_damage: int) -> void:
	if actual_damage <= 0 or not is_alive:
		return

	if mana_on_attack > 0.0:
		restore_mana(mana_on_attack, self)

	var life_steal_bonus: float = 0.0
	if unit_skill != null and unit_skill.passive_resolver != null and unit_skill.passive_resolver.has_method("get_bloodbound_rage_life_steal_bonus"):
		life_steal_bonus = float(unit_skill.passive_resolver.get_bloodbound_rage_life_steal_bonus(self))
	var life_steal_ratio: float = clampf(life_steal + life_steal_bonus, 0.0, 1.0)
	if life_steal_ratio > 0.0:
		var heal_amount: int = maxi(1, int(round(float(actual_damage) * life_steal_ratio)))
		heal(heal_amount, self)


func _update_hp_bar() -> void:
	if hp_bar == null:
		return

	hp_bar.max_value = max_hp
	hp_bar.value = hp


func _update_mana_bar() -> void:
	if mana_bar == null:
		return

	mana_bar.max_value = maxf(float(max_mana), 1.0)
	mana_bar.value = clampf(current_mana, 0.0, float(max_mana))
	mana_bar.visible = max_mana > 0


func update_info_display() -> void:
	if info_label == null:
		return

	info_label.text = _get_compact_display_name()


func _handle_detail_input(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton):
		return false

	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_RIGHT or not mouse_button.pressed:
		return false

	if not is_alive:
		return false

	if _is_mouse_over_blocking_ui():
		return false

	if not _is_mouse_over_body(get_global_mouse_position()):
		return false

	detail_requested.emit(self)
	get_viewport().set_input_as_handled()
	return true


func _is_mouse_over_body(mouse_position: Vector2) -> bool:
	if body == null:
		return false

	var local_position: Vector2 = to_local(mouse_position)
	var body_rect: Rect2 = Rect2(body.position, body.size)
	return body_rect.has_point(local_position)


func _is_mouse_over_blocking_ui() -> bool:
	var viewport: Viewport = get_viewport()
	if viewport == null or not viewport.has_method("gui_get_hovered_control"):
		return false

	var hovered_control: Control = viewport.gui_get_hovered_control() as Control
	if hovered_control == null:
		return false

	if is_ancestor_of(hovered_control):
		return false

	return hovered_control.mouse_filter != Control.MOUSE_FILTER_IGNORE


func _get_compact_display_name() -> String:
	return _strip_team_prefix(_strip_star_marks(_get_info_display_name())) + " " + _get_star_text()


func _get_info_display_name() -> String:
	var configured_display_name: String = display_name.strip_edges()
	if configured_display_name != "" and configured_display_name != "Unit" and configured_display_name != "单位":
		return configured_display_name

	if unit_data != null:
		var configured_cn_name: Variant = unit_data.get("unit_name_cn")
		if configured_cn_name != null and str(configured_cn_name).strip_edges() != "":
			return str(configured_cn_name)

		var configured_unit_name: Variant = unit_data.get("unit_name")
		if configured_unit_name != null and str(configured_unit_name).strip_edges() != "":
			return str(configured_unit_name)

	if unit_type.strip_edges() != "":
		return unit_type

	return "单位"


func _strip_team_prefix(name: String) -> String:
	var stripped_name: String = name.strip_edges()
	var prefixes: Array[String] = ["蓝方 ", "红方 ", "蓝队 ", "红队 "]
	for prefix: String in prefixes:
		if stripped_name.begins_with(prefix):
			return stripped_name.substr(prefix.length()).strip_edges()

	return stripped_name


func _get_role_display_name() -> String:
	match role:
		"tank":
			return "坦克"
		"support":
			return "辅助"
		_:
			return "输出"


func _get_star_text() -> String:
	var safe_star: int = maxi(star, 1)
	var star_text: String = ""
	for _index: int in range(safe_star):
		star_text += "*"

	return star_text


func _strip_star_marks(value: String) -> String:
	return value.replace("*", "").strip_edges()


func _join_info_lines(lines: Array[String]) -> String:
	var joined_text: String = ""

	for index: int in range(lines.size()):
		if index > 0:
			joined_text += "\n"
		joined_text += lines[index]

	return joined_text
