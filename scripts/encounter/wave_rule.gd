class_name WaveRule
extends RefCounted

const ENCOUNTER_TYPE_NORMAL: String = "NORMAL"
const ENCOUNTER_TYPE_ELITE: String = "ELITE"
const ENCOUNTER_TYPE_BOSS: String = "BOSS"


func get_encounter_type_for_round(current_round: int) -> String:
	if current_round > 0 and current_round % 10 == 0:
		return ENCOUNTER_TYPE_BOSS

	if current_round > 0 and current_round % 5 == 0:
		return ENCOUNTER_TYPE_ELITE

	return ENCOUNTER_TYPE_NORMAL


func get_normal_enemy_count(current_round: int) -> int:
	var round_steps: int = floori(float(maxi(current_round - 1, 0)) / 2.0)
	return clampi(2 + round_steps, 2, 12)


func get_normal_multipliers(current_round: int) -> Dictionary:
	return create_multipliers(
		1.0 + float(current_round) * 0.06,
		1.0 + float(current_round) * 0.03,
		floori(float(current_round) / 3.0) * 3,
		1.0
	)


func get_elite_multipliers(current_round: int) -> Dictionary:
	return create_multipliers(
		1.40 + float(current_round) * 0.08,
		1.15 + float(current_round) * 0.04,
		10 + floori(float(current_round) / 2.0) * 3,
		1.10
	)


func get_boss_multipliers(current_round: int) -> Dictionary:
	var boss_tier: int = clampi(floori(float(maxi(current_round - 10, 0)) / 10.0), 0, 2)
	return create_multipliers(
		1.30 + float(boss_tier) * 1.35,
		1.05 + float(boss_tier) * 0.525,
		boss_tier * 15,
		1.0 + float(boss_tier) * 0.10
	)


func create_multipliers(
	hp_multiplier: float,
	attack_multiplier: float,
	defense_bonus: int,
	mana_regen_multiplier: float
) -> Dictionary:
	return {
		"hp_multiplier": hp_multiplier,
		"attack_multiplier": attack_multiplier,
		"defense_bonus": defense_bonus,
		"mana_regen_multiplier": mana_regen_multiplier,
	}


func roll_star(current_round: int, encounter_type: String) -> int:
	var probabilities: Dictionary = get_star_probabilities(current_round)
	if encounter_type == ENCOUNTER_TYPE_ELITE:
		probabilities = boost_elite_star_probabilities(probabilities)

	var roll: float = randf()
	var one_star_chance: float = float(probabilities[1])
	var two_star_chance: float = float(probabilities[2])
	if roll < one_star_chance:
		return 1

	if roll < one_star_chance + two_star_chance:
		return 2

	return 3


func get_star_probabilities(current_round: int) -> Dictionary:
	if current_round <= 2:
		return {1: 1.0, 2: 0.0, 3: 0.0}
	if current_round <= 4:
		return {1: 0.8, 2: 0.2, 3: 0.0}
	if current_round == 5:
		return {1: 0.5, 2: 0.5, 3: 0.0}
	if current_round <= 7:
		return {1: 0.4, 2: 0.55, 3: 0.05}
	if current_round == 8:
		return {1: 0.25, 2: 0.65, 3: 0.10}
	if current_round == 9:
		return {1: 0.10, 2: 0.70, 3: 0.20}
	if current_round <= 14:
		return {1: 0.0, 2: 0.45, 3: 0.55}
	if current_round <= 19:
		return {1: 0.0, 2: 0.35, 3: 0.65}
	if current_round <= 24:
		return {1: 0.0, 2: 0.25, 3: 0.75}
	if current_round <= 29:
		return {1: 0.0, 2: 0.10, 3: 0.90}

	return {1: 0.0, 2: 0.0, 3: 1.0}


func boost_elite_star_probabilities(probabilities: Dictionary) -> Dictionary:
	var one_star: float = float(probabilities[1])
	var two_star: float = float(probabilities[2]) + 0.20
	var three_star: float = float(probabilities[3]) + 0.10
	var total: float = one_star + two_star + three_star
	if total <= 0.0:
		return {1: 0.0, 2: 0.7, 3: 0.3}

	return {
		1: one_star / total,
		2: two_star / total,
		3: three_star / total,
	}


func get_boss_star(current_round: int) -> int:
	return clampi(1 + floori(float(maxi(current_round - 10, 0)) / 10.0), 1, 3)


func get_boss_guard_star(current_round: int) -> int:
	return clampi(1 + floori(float(maxi(current_round - 10, 0)) / 10.0), 1, 3)
