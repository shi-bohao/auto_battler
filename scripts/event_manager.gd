class_name EventManager
extends RefCounted


const EFFECT_GAIN_GOLD: String = "gain_gold"
const EFFECT_LOSE_GOLD: String = "lose_gold"
const EFFECT_GAIN_RELIC: String = "gain_relic"
const EFFECT_RELIC_CHOICE_3: String = "relic_choice_3"
const EFFECT_GAIN_RANDOM_UNIT: String = "gain_random_unit"
const EFFECT_PERMANENT_STAT: String = "permanent_stat"
const EFFECT_RANDOM_OUTCOME: String = "random_outcome"
const EFFECT_NOTHING: String = "nothing"

var relic_manager: Variant = null
var roster_manager: Variant = null
var economy_manager: Variant = null
var used_event_ids: Array[String] = []
var current_event: Dictionary = {}
var pending_relic_choice: bool = false


func setup(relic_mgr: Variant, roster_mgr: Variant, economy_mgr: Variant) -> void:
	relic_manager = relic_mgr
	roster_manager = roster_mgr
	economy_manager = economy_mgr


func reset() -> void:
	used_event_ids.clear()
	current_event = {}
	pending_relic_choice = false


func get_random_event(current_round: int) -> Dictionary:
	var pool: Array[Dictionary] = []
	for event: Dictionary in ALL_EVENTS:
		var event_id: String = event.get("event_id", "")
		if event_id in used_event_ids:
			continue
		var min_round: int = int(event.get("min_round", 1))
		var max_round: int = int(event.get("max_round", 30))
		if current_round < min_round or current_round > max_round:
			continue
		pool.append(event)

	if pool.is_empty():
		used_event_ids.clear()
		pool = ALL_EVENTS.duplicate()

	var selected: Dictionary = pool[randi() % pool.size()]
	current_event = selected
	used_event_ids.append(selected.get("event_id", ""))
	return selected


func get_current_event() -> Dictionary:
	return current_event


func resolve_choice(choice_index: int) -> Dictionary:
	var choices: Array = current_event.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return {"result_text": "无事发生", "effects_applied": []}

	var choice: Dictionary = choices[choice_index]
	var effects: Array = choice.get("effects", [])
	var results: Array[String] = []
	pending_relic_choice = false

	for effect: Dictionary in effects:
		var effect_id: String = effect.get("effect_id", EFFECT_NOTHING)
		var params: Dictionary = effect.get("params", {})
		var result: String = _apply_effect(effect_id, params)
		if result != "":
			results.append(result)

	var result_text: String = choice.get("result_text", "")
	if results.size() > 0:
		result_text += "\n" + "\n".join(results)

	return {"result_text": result_text, "effects_applied": results, "pending_relic_choice": pending_relic_choice}


func _apply_effect(effect_id: String, params: Dictionary) -> String:
	match effect_id:
		EFFECT_GAIN_GOLD:
			var amount: int = int(params.get("amount", 0))
			if economy_manager != null and amount > 0:
				economy_manager.add_gold(amount)
			return "获得 " + str(amount) + " 金币"
		EFFECT_LOSE_GOLD:
			var amount: int = int(params.get("amount", 0))
			if economy_manager != null and amount > 0:
				if economy_manager.can_spend(amount):
					economy_manager.spend_gold(amount)
				else:
					economy_manager.spend_gold(economy_manager.get_gold())
			return "失去 " + str(amount) + " 金币"
		EFFECT_GAIN_RELIC:
			return _apply_gain_relic(params)
		EFFECT_RELIC_CHOICE_3:
			pending_relic_choice = true
			return ""
		EFFECT_GAIN_RANDOM_UNIT:
			return _apply_gain_random_unit(params)
		EFFECT_PERMANENT_STAT:
			return _apply_permanent_stat(params)
		EFFECT_RANDOM_OUTCOME:
			return _apply_random_outcome(params)
		EFFECT_NOTHING:
			return ""
		_:
			return ""


func _apply_gain_relic(params: Dictionary) -> String:
	if relic_manager == null:
		return "无遗物可用"
	var rarity_pool: Array = params.get("rarity_pool", ["RARE"])
	var all_options: Array = relic_manager.get_available_relic_reward_options()
	var filtered: Array[Dictionary] = []
	for option: Dictionary in all_options:
		if str(option.get("rarity", "")) in rarity_pool:
			filtered.append(option)
	if filtered.is_empty():
		if economy_manager != null:
			economy_manager.add_gold(5)
		return "无匹配遗物，获得 5 金币"
	var selected: Dictionary = filtered[randi() % filtered.size()]
	var relic_data: Variant = selected.get("relic_data", null)
	if relic_data != null:
		relic_manager.add_relic(relic_data)
		var name_cn: String = str(relic_data.get("relic_name_cn"))
		if name_cn == "" or name_cn == "<null>":
			name_cn = str(relic_data.get("relic_name"))
		return "获得遗物：" + name_cn
	return ""


func _apply_gain_random_unit(params: Dictionary) -> String:
	if roster_manager == null:
		return ""
	var min_rarity: String = str(params.get("min_rarity", "RARE"))
	var pool: Array[Resource] = roster_manager.get_high_rarity_unit_pool(min_rarity)
	if pool.is_empty():
		pool = roster_manager.get_all_unit_pool()
	if pool.is_empty():
		return "无可用单位"
	var selected: Resource = pool[randi() % pool.size()]
	if not roster_manager.is_unit_unlocked(selected):
		roster_manager.unlock_unit_data(selected)
	roster_manager.add_unit(selected)
	var name_cn: String = str(selected.get("unit_name_cn"))
	if name_cn == "" or name_cn == "<null>":
		name_cn = str(selected.get("unit_name"))
	return "获得单位：" + name_cn


func _apply_permanent_stat(params: Dictionary) -> String:
	if roster_manager == null:
		return ""
	var stat: String = params.get("stat", "")
	var ratio: float = float(params.get("ratio", 0.0))
	var mode: String = params.get("mode", "percent")
	if stat == "":
		var stat_pool: Array[Dictionary] = [
			{"stat": "max_hp", "ratio": ratio, "mode": "percent"},
			{"stat": "attack_damage", "ratio": ratio, "mode": "percent"},
			{"stat": "defense", "ratio": ratio * 50.0, "mode": "flat"},
			{"stat": "skill_damage_bonus", "ratio": ratio, "mode": "percent"},
		]
		var picked: Dictionary = stat_pool[randi() % stat_pool.size()]
		stat = picked["stat"]
		ratio = float(picked["ratio"])
		mode = picked["mode"]
	if mode == "percent":
		roster_manager.apply_permanent_percent_bonus(stat, ratio)
		return _get_stat_display_name(stat) + " +" + str(int(ratio * 100.0)) + "%"
	elif mode == "flat":
		roster_manager.apply_permanent_flat_bonus(stat, ratio)
		return _get_stat_display_name(stat) + " +" + str(int(ratio))
	return ""


func _apply_random_outcome(params: Dictionary) -> String:
	var outcomes: Array = params.get("outcomes", [])
	if outcomes.is_empty():
		return ""
	var total_weight: int = 0
	for outcome: Dictionary in outcomes:
		total_weight += int(outcome.get("weight", 1))
	var roll: int = randi() % total_weight
	var cumulative: int = 0
	for outcome: Dictionary in outcomes:
		cumulative += int(outcome.get("weight", 1))
		if roll < cumulative:
			var sub_effect_id: String = outcome.get("effect_id", EFFECT_NOTHING)
			var sub_params: Dictionary = outcome.get("params", {})
			return _apply_effect(sub_effect_id, sub_params)
	return ""


func _get_stat_display_name(stat: String) -> String:
	match stat:
		"max_hp":
			return "全队生命"
		"attack_damage":
			return "全队攻击"
		"defense":
			return "全队防御"
		"skill_damage_bonus":
			return "全队技能伤害"
		"crit_chance":
			return "全队暴击率"
		"mana_regen_per_second":
			return "全队魔力回复"
		_:
			return stat


const ALL_EVENTS: Array[Dictionary] = [
	{
		"event_id": "lost_traveler",
		"event_name_cn": "迷途旅人",
		"event_text_cn": "一名旅人挡住了你的去路，请求一点小小的援助。他看起来风尘仆仆，身上似乎有些有趣的东西。",
		"min_round": 1, "max_round": 30, "weight": 1.0,
		"choices": [
			{
				"label_cn": "给予 3 金币",
				"description_cn": "帮助旅人，获得一件稀有遗物。",
				"result_text": "旅人感激地留下了一件遗物。",
				"effects": [
					{"effect_id": "lose_gold", "params": {"amount": 3}},
					{"effect_id": "gain_relic", "params": {"rarity_pool": ["RARE"]}},
				],
			},
			{
				"label_cn": "拒绝",
				"description_cn": "无视旅人的请求。",
				"result_text": "你无视了旅人，继续前行。",
				"effects": [{"effect_id": "nothing", "params": {}}],
			},
		],
	},
	{
		"event_id": "mysterious_altar",
		"event_name_cn": "神秘祭坛",
		"event_text_cn": "前方矗立着一座古老的祭坛，上面刻满了神秘的符文。祭坛低语着，似乎在邀请你献上祭品。",
		"min_round": 3, "max_round": 30, "weight": 1.0,
		"choices": [
			{
				"label_cn": "献祭 5 金币",
				"description_cn": "向祭坛献上金币，获得全队永久属性提升。",
				"result_text": "祭坛发出耀眼光芒，力量涌入你的队伍！",
				"effects": [
					{"effect_id": "lose_gold", "params": {"amount": 5}},
					{"effect_id": "permanent_stat", "params": {"stat": "", "ratio": 0.12, "mode": "percent"}},
				],
			},
			{
				"label_cn": "不献祭",
				"description_cn": "离开祭坛。",
				"result_text": "你离开了祭坛。",
				"effects": [{"effect_id": "nothing", "params": {}}],
			},
		],
	},
	{
		"event_id": "wandering_merchant",
		"event_name_cn": "流浪商人",
		"event_text_cn": "一名神秘的流浪商人出现在你面前。「我有一些好东西……价格公道。」他微笑着展开了货物。",
		"min_round": 5, "max_round": 30, "weight": 1.0,
		"choices": [
			{
				"label_cn": "花费 8 金币",
				"description_cn": "从商人处购买，获得史诗遗物三选一。",
				"result_text": "商人展开了三件史诗遗物供你挑选。",
				"effects": [
					{"effect_id": "lose_gold", "params": {"amount": 8}},
					{"effect_id": "relic_choice_3", "params": {"rarity_pool": ["EPIC"]}},
				],
			},
			{
				"label_cn": "离开",
				"description_cn": "不购买任何东西。",
				"result_text": "你礼貌地拒绝了商人。",
				"effects": [{"effect_id": "nothing", "params": {}}],
			},
		],
	},
	{
		"event_id": "cursed_chest",
		"event_name_cn": "诅咒箱",
		"event_text_cn": "一只漆黑的箱子出现在道路中央，上面刻满了诅咒铭文。箱子散发着诱人却危险的气息。",
		"min_round": 5, "max_round": 30, "weight": 1.0,
		"choices": [
			{
				"label_cn": "强行打开",
				"description_cn": "50% 获得传说遗物，50% 全队生命永久 -8%。",
				"result_text": "",
				"effects": [
					{"effect_id": "random_outcome", "params": {"outcomes": [
						{"weight": 50, "effect_id": "gain_relic", "params": {"rarity_pool": ["LEGENDARY"]}},
						{"weight": 50, "effect_id": "permanent_stat", "params": {"stat": "max_hp", "ratio": -0.08, "mode": "percent"}},
					]}},
				],
			},
			{
				"label_cn": "不打开",
				"description_cn": "绕过箱子，获得 5 金币。",
				"result_text": "你明智地绕过了箱子。",
				"effects": [{"effect_id": "gain_gold", "params": {"amount": 5}}],
			},
		],
	},
	{
		"event_id": "wounded_warrior",
		"event_name_cn": "受伤的战士",
		"event_text_cn": "一名受伤的战士倒在路旁。他恳求道：「如果你能帮我治伤，我愿意为你效力。」",
		"min_round": 1, "max_round": 30, "weight": 1.0,
		"choices": [
			{
				"label_cn": "花费 3 金币治疗",
				"description_cn": "治疗战士，获得一个随机 3 费单位。",
				"result_text": "战士恢复了精神，加入了你的队伍！",
				"effects": [
					{"effect_id": "lose_gold", "params": {"amount": 3}},
					{"effect_id": "gain_random_unit", "params": {"min_rarity": "RARE"}},
				],
			},
			{
				"label_cn": "拒绝",
				"description_cn": "离开受伤的战士。",
				"result_text": "你遗憾地离开了。",
				"effects": [{"effect_id": "nothing", "params": {}}],
			},
		],
	},
	{
		"event_id": "arcane_anomaly",
		"event_name_cn": "奥术异象",
		"event_text_cn": "空气中弥漫着浓郁的魔力波动，一团奥术能量悬浮在半空中，散发着蓝紫色的光芒。",
		"min_round": 3, "max_round": 30, "weight": 1.0,
		"choices": [
			{
				"label_cn": "接触奥术能量",
				"description_cn": "全队魔力回复永久 +15%。",
				"result_text": "奥术能量涌入你的队伍，增强了魔力循环！",
				"effects": [
					{"effect_id": "permanent_stat", "params": {"stat": "mana_regen_per_second", "ratio": 0.15, "mode": "percent"}},
				],
			},
			{
				"label_cn": "远离",
				"description_cn": "安全离开，获得 8 金币。",
				"result_text": "你谨慎地远离了异象，在附近找到了一些金币。",
				"effects": [{"effect_id": "gain_gold", "params": {"amount": 8}}],
			},
		],
	},
]
