extends RefCounted

const AOE_RESOLVER_SCRIPT: Script = preload("res://scripts/combat/aoe_resolver.gd")
const PASSIVE_SLIME_BODY: String = "slime_body"
const PASSIVE_ENEMY_MIRROR_CARAPACE: String = "enemy_mirror_carapace"
const SLIME_BODY_BASIC_ATTACK_MULTIPLIER: float = 0.92
const SLIME_BODY_BASIC_ATTACK_MULTIPLIER_STAR_3: float = 0.85
const MIRROR_CARAPACE_REFLECT_RATIO: float = 0.25
const MIRROR_CARAPACE_REFLECT_RATIO_STAR_3: float = 0.35
const MIRROR_CARAPACE_REFLECT_COOLDOWN: float = 1.0
const MIRROR_CARAPACE_REFLECT_COOLDOWN_STAR_3: float = 0.6

var aoe_resolver: Variant = AOE_RESOLVER_SCRIPT.new()


func resolve_basic_attack_hit(attacker: Variant, target: Variant, payload: Variant = null) -> int:
	if not _is_valid_unit(attacker) or not _is_valid_unit(target):
		return 0

	if not target.is_alive:
		return 0

	var is_payload: bool = payload != null and is_instance_valid(payload)

	# Validate teams are still opposed
	if is_payload:
		if int(target.team_id) == int(payload.source_team_id):
			return 0
	else:
		if not attacker.is_alive or not attacker.is_battle_active:
			return 0

	# Record attack count on hit (not on launch, for projectile case)
	if attacker.stats_manager != null and is_instance_valid(attacker.stats_manager):
		attacker.attack_count = attacker.stats_manager.record_attack(attacker)
	else:
		attacker.attack_count += 1

	# Capture effective values before potential override
	var effective_lifesteal: float
	var effective_mana_on_attack: float

	# Save and override attacker combat stats for take_damage if using payload
	var saved_crit_chance: float = 0.0
	var saved_crit_damage_multiplier: float = 1.5
	var saved_defense_penetration: int = 0
	var did_override: bool = false

	if is_payload and _is_valid_unit(attacker):
		saved_crit_chance = float(attacker.crit_chance)
		saved_crit_damage_multiplier = float(attacker.crit_damage_multiplier)
		saved_defense_penetration = int(attacker.defense_penetration)

		attacker.crit_chance = clampf(float(payload.crit_chance), 0.0, 1.0)
		attacker.crit_damage_multiplier = maxf(1.0, float(payload.crit_damage_multiplier))
		attacker.defense_penetration = maxi(0, int(payload.defense_penetration))
		did_override = true

		# Use snapshotted values for post-hit rewards
		effective_lifesteal = clampf(float(payload.lifesteal), 0.0, 1.0)
		effective_mana_on_attack = 0.0
	else:
		effective_lifesteal = clampf(float(attacker.life_steal), 0.0, 1.0)
		effective_mana_on_attack = float(attacker.mana_on_attack)

	# Calculate base damage (passives already applied at launch for projectiles)
	var base_damage: int
	if is_payload:
		base_damage = int(payload.base_damage)
	else:
		base_damage = int(attacker.unit_skill.get_basic_attack_damage(attacker, target, attacker.attack_damage))
	base_damage = _apply_target_basic_attack_mitigation(target, base_damage)

	# Apply damage through standard take_damage path
	var actual_damage: int = target.take_damage(base_damage, attacker)

	# Restore original combat stats
	if did_override and _is_valid_unit(attacker):
		attacker.crit_chance = saved_crit_chance
		attacker.crit_damage_multiplier = saved_crit_damage_multiplier
		attacker.defense_penetration = saved_defense_penetration

	if actual_damage > 0:
		# Emit attack_landed (only if attacker still valid)
		if is_instance_valid(attacker):
			attacker.attack_landed.emit(attacker, target)
			if attacker.unit_skill != null and attacker.unit_skill.has_method("apply_attack_landed_passives"):
				attacker.unit_skill.apply_attack_landed_passives(attacker, target)

		# Lifesteal and mana-on-attack only if attacker still alive
		if is_instance_valid(attacker) and attacker.is_alive:
			if effective_lifesteal > 0.0:
				var life_steal_bonus: float = 0.0
				if attacker.unit_skill != null and attacker.unit_skill.passive_resolver != null and attacker.unit_skill.passive_resolver.has_method("get_bloodbound_rage_life_steal_bonus"):
					life_steal_bonus = float(attacker.unit_skill.passive_resolver.get_bloodbound_rage_life_steal_bonus(attacker))
				var total_life_steal: float = clampf(effective_lifesteal + life_steal_bonus, 0.0, 1.0)
				if total_life_steal > 0.0:
					var heal_amount: int = maxi(1, int(round(float(actual_damage) * total_life_steal)))
					attacker.heal(heal_amount, attacker)

			if effective_mana_on_attack > 0.0:
				attacker.restore_mana(effective_mana_on_attack, attacker)

		# Handle enhanced attack AoE (e.g. Bomb Thrower every 3rd launch)
		if is_payload and payload.is_enhanced and payload.enhanced_radius > 0.0 and payload.enhanced_damage > 0:
			_apply_enhanced_aoe(attacker, target, payload)

	return actual_damage


func resolve_skill_damage(caster: Variant, target: Variant, amount: int, _context: Dictionary = {}) -> int:
	if not _is_valid_unit(target) or not target.is_alive:
		return 0
	if target.control_state != null and not is_equal_approx(target.control_state.skill_damage_taken_multiplier, 1.0):
		amount = maxi(1, int(round(float(amount) * target.control_state.skill_damage_taken_multiplier)))
	var had_shield: bool = int(target.shield) > 0
	var actual_damage: int = target.take_damage(amount, caster)
	_try_reflect_skill_damage(caster, target, actual_damage, had_shield)
	return actual_damage


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)


func _try_reflect_skill_damage(caster: Variant, target: Variant, actual_damage: int, had_shield: bool) -> void:
	if actual_damage <= 0 or not had_shield:
		return
	if not _is_valid_unit(caster) or not caster.is_alive:
		return
	if not _is_valid_unit(target) or not target.is_alive:
		return
	if int(caster.team_id) == int(target.team_id):
		return
	if str(target.passive_id) != PASSIVE_ENEMY_MIRROR_CARAPACE:
		return

	var now: float = float(target.battle_elapsed_time)
	var cooldown: float = MIRROR_CARAPACE_REFLECT_COOLDOWN_STAR_3 if int(target.star) >= 3 else MIRROR_CARAPACE_REFLECT_COOLDOWN
	var next_allowed: float = float(target.get_meta("mirror_carapace_reflect_ready_at", 0.0))
	if now < next_allowed:
		return

	target.set_meta("mirror_carapace_reflect_ready_at", now + cooldown)
	var reflect_ratio: float = MIRROR_CARAPACE_REFLECT_RATIO_STAR_3 if int(target.star) >= 3 else MIRROR_CARAPACE_REFLECT_RATIO
	var reflect_damage: int = maxi(1, int(round(float(actual_damage) * reflect_ratio)))
	caster.take_damage(reflect_damage, target, false)
	if target.unit_feedback != null:
		target.unit_feedback.play_skill_feedback(target, "Mirror Carapace")


func _apply_target_basic_attack_mitigation(target: Variant, damage: int) -> int:
	if not _is_valid_unit(target) or damage <= 0:
		return damage

	if str(target.passive_id) != PASSIVE_SLIME_BODY:
		return damage

	var multiplier: float = SLIME_BODY_BASIC_ATTACK_MULTIPLIER_STAR_3 if int(target.star) >= 3 else SLIME_BODY_BASIC_ATTACK_MULTIPLIER
	return maxi(1, int(round(float(damage) * multiplier)))


func _apply_enhanced_aoe(attacker: Variant, primary_target: Variant, payload: Variant) -> void:
	if not _is_valid_unit(attacker) or not _is_valid_unit(primary_target):
		return

	var radius: float = float(payload.enhanced_radius)
	var damage: int = int(payload.enhanced_damage)

	var targets: Array = aoe_resolver.get_enemy_units_in_radius(attacker, primary_target.global_position, radius, [primary_target])
	if targets.is_empty():
		return

	var hit_count: int = aoe_resolver.deal_aoe_damage(attacker, targets, damage, true)
	if hit_count <= 0:
		return

	var visual_color: Color = payload.enhanced_visual_color as Color
	if visual_color == Color.WHITE:
		visual_color = Color(1.0, 0.32, 0.10, 0.22)

	var battle_root: Node = attacker.get_parent() as Node
	if battle_root != null and is_instance_valid(battle_root) and battle_root.has_method("create_visual_field"):
		battle_root.create_visual_field(primary_target.global_position, radius, 0.35, visual_color)

	if attacker.unit_feedback != null:
		attacker.unit_feedback.play_skill_feedback(attacker, "Unstable Bomb")
