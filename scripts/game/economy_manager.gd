class_name EconomyManager
extends RefCounted

signal gold_changed(new_gold: int, delta: int)

const ENCOUNTER_TYPE_NORMAL: String = "NORMAL"
const ENCOUNTER_TYPE_ELITE: String = "ELITE"
const ENCOUNTER_TYPE_BOSS: String = "BOSS"

var initial_gold: int = 8
var base_win_gold: int = 5
var elite_win_gold_bonus: int = 8
var boss_win_gold_bonus: int = 12
var gold: int = initial_gold


func get_gold() -> int:
	return gold


func reset() -> void:
	var old_gold: int = gold
	gold = initial_gold
	if old_gold != gold:
		gold_changed.emit(gold, gold - old_gold)


func add_gold(amount: int) -> void:
	if amount <= 0:
		return

	gold += amount
	gold_changed.emit(gold, amount)


func can_spend(amount: int) -> bool:
	return amount >= 0 and gold >= amount


func spend_gold(amount: int) -> bool:
	if not can_spend(amount):
		return false

	gold -= amount
	gold_changed.emit(gold, -amount)
	return true


func refund_gold(amount: int) -> void:
	add_gold(amount)


func get_victory_gold_reward(encounter_type: String, current_round: int, max_round: int) -> int:
	if encounter_type == ENCOUNTER_TYPE_BOSS and current_round >= max_round:
		return 0

	var round_bonus: int = floori(float(current_round) / 2.0)
	var reward: int = base_win_gold + round_bonus
	if encounter_type == ENCOUNTER_TYPE_ELITE:
		reward += elite_win_gold_bonus
	elif encounter_type == ENCOUNTER_TYPE_BOSS:
		reward += boss_win_gold_bonus

	return reward


func get_victory_gold_reward_debug_text(encounter_type: String, reward: int) -> String:
	match encounter_type:
		ENCOUNTER_TYPE_NORMAL:
			return "获得金币：" + str(reward)
		ENCOUNTER_TYPE_ELITE:
			return "获得金币：" + str(reward) + "（精英奖励 +" + str(elite_win_gold_bonus) + "）"
		ENCOUNTER_TYPE_BOSS:
			return "获得金币：" + str(reward) + "（Boss 奖励 +" + str(boss_win_gold_bonus) + "）"
		_:
			return "获得金币：" + str(reward)
