class_name RarityRollService
extends RefCounted


const RARITY_ORDER: Array[String] = ["COMMON", "FINE", "RARE", "EPIC", "LEGENDARY"]
const RARITY_ROLL_ORDER: Array[String] = ["LEGENDARY", "EPIC", "RARE", "FINE", "COMMON"]

const BASE_RARITY_CHANCE: Dictionary = {
	"COMMON": 70.0,
	"FINE": 20.0,
	"RARE": 9.0,
	"EPIC": 1.0,
	"LEGENDARY": 0.0,
}

const RARITY_CHANCE_PER_ROUND: Dictionary = {
	"COMMON": 0.0,
	"FINE": 5.0,
	"RARE": 2.0,
	"EPIC": 1.0,
	"LEGENDARY": 0.5,
}

const ENCOUNTER_BONUS: Dictionary = {
	"NORMAL": 0.0,
	"ELITE": 10.0,
	"BOSS": 20.0,
	"SHOP": 0.0,
}


func get_modified_chances(current_round: int, encounter_type: String, luck: float) -> Dictionary:
	var round_index: int = maxi(0, current_round - 1)
	var encounter_bonus: float = float(ENCOUNTER_BONUS.get(encounter_type, 0.0))

	var modified: Dictionary = {}
	for rarity: String in RARITY_ORDER:
		var base: float = float(BASE_RARITY_CHANCE.get(rarity, 0.0))
		var per_round: float = float(RARITY_CHANCE_PER_ROUND.get(rarity, 0.0))
		var raw: float = base + round_index * per_round + encounter_bonus
		modified[rarity] = minf(raw * (1.0 + luck / 100.0), 100.0)

	return modified


func get_final_chances(current_round: int, encounter_type: String, luck: float) -> Dictionary:
	var modified: Dictionary = get_modified_chances(current_round, encounter_type, luck)

	var final_chances: Dictionary = {}
	var remaining: float = 100.0
	for rarity: String in RARITY_ROLL_ORDER:
		var chance: float = minf(float(modified.get(rarity, 0.0)), remaining)
		final_chances[rarity] = chance
		remaining -= chance

	return final_chances


func roll_rarity(current_round: int, encounter_type: String = "NORMAL", luck: float = 0.0) -> String:
	var final_chances: Dictionary = get_final_chances(current_round, encounter_type, luck)

	var roll: float = randf() * 100.0
	var cumulative: float = 0.0
	for rarity: String in RARITY_ROLL_ORDER:
		cumulative += float(final_chances.get(rarity, 0.0))
		if roll < cumulative:
			return rarity

	return "COMMON"


func pick_by_rarity(pool: Array, target_rarity: String, rarity_getter: Callable) -> Variant:
	var candidates: Array = []
	for item: Variant in pool:
		if rarity_getter.call(item) == target_rarity:
			candidates.append(item)

	if not candidates.is_empty():
		return candidates[randi_range(0, candidates.size() - 1)]

	# 未知稀有度回退到 COMMON
	var rarity_index: int = RARITY_ORDER.find(target_rarity)
	if rarity_index == -1:
		rarity_index = RARITY_ORDER.find("COMMON")
		if rarity_index == -1:
			rarity_index = 0

	# 空池兜底：先向低稀有度查找，再向高稀有度查找
	for i: int in range(rarity_index - 1, -1, -1):
		var lower_rarity: String = RARITY_ORDER[i]
		for item: Variant in pool:
			if rarity_getter.call(item) == lower_rarity:
				candidates.append(item)
		if not candidates.is_empty():
			return candidates[randi_range(0, candidates.size() - 1)]

	for i: int in range(rarity_index + 1, RARITY_ORDER.size()):
		var higher_rarity: String = RARITY_ORDER[i]
		for item: Variant in pool:
			if rarity_getter.call(item) == higher_rarity:
				candidates.append(item)
		if not candidates.is_empty():
			return candidates[randi_range(0, candidates.size() - 1)]

	return null
