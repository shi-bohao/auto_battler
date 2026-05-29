class_name UnitControlState
extends RefCounted


const STATUS_EFFECT_SCRIPT: Script = preload("res://scripts/status_effect.gd")

var can_move: bool = true
var can_attack: bool = true
var can_cast: bool = true
var can_retarget: bool = true

var move_speed_multiplier: float = 1.0
var attack_cooldown_rate_multiplier: float = 1.0
var mana_regen_multiplier: float = 1.0
var forced_target: Variant = null
var forced_target_unit_id: int = -1

var is_slowed: bool = false
var is_rooted: bool = false
var is_stunned: bool = false
var is_frozen: bool = false
var is_taunted: bool = false

var skill_damage_taken_multiplier: float = 1.0
var active_control_types: Array[String] = []


func reset() -> void:
	can_move = true
	can_attack = true
	can_cast = true
	can_retarget = true
	move_speed_multiplier = 1.0
	attack_cooldown_rate_multiplier = 1.0
	mana_regen_multiplier = 1.0
	forced_target = null
	forced_target_unit_id = -1
	is_slowed = false
	is_rooted = false
	is_stunned = false
	is_frozen = false
	is_taunted = false
	skill_damage_taken_multiplier = 1.0
	active_control_types.clear()


func rebuild(owner_unit: Variant, effects: Array) -> bool:
	var old_can_move: bool = can_move
	var old_can_attack: bool = can_attack
	var old_can_cast: bool = can_cast
	var old_can_retarget: bool = can_retarget
	var old_move_speed_multiplier: float = move_speed_multiplier
	var old_attack_cooldown_rate_multiplier: float = attack_cooldown_rate_multiplier
	var old_mana_regen_multiplier: float = mana_regen_multiplier
	var old_skill_mult: float = skill_damage_taken_multiplier
	var old_forced_target_unit_id: int = forced_target_unit_id
	var old_control_types: Array[String] = active_control_types.duplicate()

	reset()

	var slow_multipliers: Array[float] = []
	var freeze_skill_mults: Array[float] = []

	for effect_value: Variant in effects:
		var effect: StatusEffect = effect_value as StatusEffect
		if effect == null:
			continue
		if effect.is_expired or effect.effect_type != StatusEffect.EFFECT_CONTROL:
			continue

		if effect.disable_movement:
			can_move = false
		if effect.disable_attack:
			can_attack = false
		if effect.disable_cast:
			can_cast = false
		if effect.disable_retarget and effect.control_type != StatusEffect.CONTROL_TAUNT:
			can_retarget = false

		match effect.control_type:
			StatusEffect.CONTROL_SLOW:
				is_slowed = true
				slow_multipliers.append(effect.move_speed_multiplier)
			StatusEffect.CONTROL_ROOT:
				is_rooted = true
			StatusEffect.CONTROL_STUN:
				is_stunned = true
			StatusEffect.CONTROL_FREEZE:
				is_frozen = true
				freeze_skill_mults.append(effect.skill_damage_taken_multiplier)
			StatusEffect.CONTROL_TAUNT:
				if _is_valid_target(owner_unit, effect.forced_target):
					is_taunted = true
					can_retarget = false
					forced_target = effect.forced_target
					forced_target_unit_id = effect.forced_target_unit_id

	# Slow: take minimum multiplier
	if slow_multipliers.size() > 0:
		var min_mult: float = 1.0
		for m: float in slow_multipliers:
			min_mult = minf(min_mult, m)
		var slow_rate: float = clampf(min_mult, 0.20, 1.0)
		move_speed_multiplier = slow_rate
		attack_cooldown_rate_multiplier = slow_rate
		mana_regen_multiplier = slow_rate

	if freeze_skill_mults.size() > 0:
		for m: float in freeze_skill_mults:
			skill_damage_taken_multiplier = maxf(skill_damage_taken_multiplier, m)

	# Populate active types list
	active_control_types.clear()
	if is_frozen:
		active_control_types.append(StatusEffect.CONTROL_FREEZE)
	if is_stunned:
		active_control_types.append(StatusEffect.CONTROL_STUN)
	if is_rooted:
		active_control_types.append(StatusEffect.CONTROL_ROOT)
	if is_taunted:
		active_control_types.append(StatusEffect.CONTROL_TAUNT)
	if is_slowed:
		active_control_types.append(StatusEffect.CONTROL_SLOW)

	return old_can_move != can_move \
		or old_can_attack != can_attack \
		or old_can_cast != can_cast \
		or old_can_retarget != can_retarget \
		or not is_equal_approx(old_move_speed_multiplier, move_speed_multiplier) \
		or not is_equal_approx(old_attack_cooldown_rate_multiplier, attack_cooldown_rate_multiplier) \
		or not is_equal_approx(old_mana_regen_multiplier, mana_regen_multiplier) \
		or not is_equal_approx(old_skill_mult, skill_damage_taken_multiplier) \
		or old_forced_target_unit_id != forced_target_unit_id \
		or not _are_string_arrays_equal(old_control_types, active_control_types)


func get_valid_forced_target(owner_unit: Variant) -> Variant:
	if not is_taunted:
		return null
	if _is_valid_target(owner_unit, forced_target):
		return forced_target
	return null


func has_hard_control() -> bool:
	return is_stunned or is_frozen


func get_ui_tags() -> Array[Dictionary]:
	var tags: Array[Dictionary] = []
	if is_frozen:
		tags.append(_make_ui_tag(StatusEffect.CONTROL_FREEZE, "冻", "冻结", Color(0.5, 0.8, 1.0), 50))
	if is_stunned:
		tags.append(_make_ui_tag(StatusEffect.CONTROL_STUN, "晕", "眩晕", Color(1.0, 0.9, 0.2), 40))
	if is_rooted:
		tags.append(_make_ui_tag(StatusEffect.CONTROL_ROOT, "缚", "禁锢", Color(0.3, 0.9, 0.3), 30))
	if is_taunted:
		tags.append(_make_ui_tag(StatusEffect.CONTROL_TAUNT, "嘲", "嘲讽", Color(1.0, 0.3, 0.3), 20))
	if is_slowed:
		tags.append(_make_ui_tag(StatusEffect.CONTROL_SLOW, "缓", "减速", Color(0.4, 0.6, 1.0), 10))
	return tags


func _make_ui_tag(control_type: String, label: String, display_name: String, color: Color, priority: int) -> Dictionary:
	return {
		"type": control_type,
		"text": control_type,
		"label": label,
		"name": display_name,
		"color": color,
		"priority": priority,
	}


func _are_string_arrays_equal(a: Array[String], b: Array[String]) -> bool:
	if a.size() != b.size():
		return false
	for index: int in range(a.size()):
		if a[index] != b[index]:
			return false
	return true


func _is_valid_target(owner_unit: Variant, target: Variant) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not (target is Node2D):
		return false
	if not bool(target.get("is_alive")):
		return false
	if bool(target.get("is_targetable")) == false:
		return false
	if owner_unit != null and is_instance_valid(owner_unit):
		var owner_team: Variant = owner_unit.get("team_id")
		var target_team: Variant = target.get("team_id")
		if owner_team != null and target_team != null and int(owner_team) == int(target_team):
			return false
	return true
