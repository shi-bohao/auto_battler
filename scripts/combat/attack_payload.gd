extends RefCounted

## Snapshot of attack data captured at projectile launch time.
## Used by CombatResolver to resolve the hit using launch-time values,
## even if the attacker's stats have changed or the attacker has died.

var source_unit_ref: Variant = null
var source_unit_id: int = -1
var source_team_id: int = 0
var source_display_name: String = ""
var source_unit_type: String = ""
var source_passive_id: String = ""
var source_bond_tags: Array[String] = []
var source_star: int = 1

var target_unit_id: int = -1
var target_team_id: int = 0

var base_damage: int = 0
var crit_chance: float = 0.0
var crit_damage_multiplier: float = 1.5
var defense_penetration: int = 0
var lifesteal: float = 0.0
var basic_attack_type: String = "melee"
var can_crit: bool = true
var is_basic_attack: bool = true

var created_time: float = 0.0
var max_lifetime: float = 2.0

# Enhanced attack (e.g. Bomb Thrower every 3rd launch)
var is_enhanced: bool = false
var enhanced_radius: float = 0.0
var enhanced_damage: int = 0
var enhanced_visual_color: Color = Color.WHITE


static func from_attacker(attacker: Variant, target: Variant, damage: int, battle_time: float) -> Variant:
	var payload: Variant = new()
	if attacker == null or not is_instance_valid(attacker):
		return payload

	payload.source_unit_ref = attacker
	payload.source_unit_id = int(attacker.unit_id)
	payload.source_team_id = int(attacker.team_id)
	payload.source_display_name = str(attacker.display_name)
	payload.source_unit_type = str(attacker.unit_type)
	payload.source_passive_id = str(attacker.passive_id)
	if attacker.bond_tags is Array:
		payload.source_bond_tags = attacker.bond_tags.duplicate()
	payload.source_star = int(attacker.star)

	if target != null and is_instance_valid(target):
		payload.target_unit_id = int(target.unit_id)
		payload.target_team_id = int(target.team_id)

	payload.base_damage = maxi(1, damage)
	payload.crit_chance = clampf(float(attacker.crit_chance), 0.0, 1.0)
	payload.crit_damage_multiplier = maxf(1.0, float(attacker.crit_damage_multiplier))
	payload.defense_penetration = maxi(0, int(attacker.defense_penetration))
	payload.lifesteal = clampf(float(attacker.life_steal), 0.0, 1.0)
	payload.basic_attack_type = str(attacker.basic_attack_type)
	payload.can_crit = true
	payload.is_basic_attack = true

	payload.created_time = maxf(0.0, battle_time)
	payload.max_lifetime = 2.0

	return payload
