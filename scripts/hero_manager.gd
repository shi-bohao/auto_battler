class_name HeroManager
extends RefCounted


const HERO_DATA_SCRIPT: Script = preload("res://scripts/hero_data.gd")
const HERO_UPGRADE_DATA_SCRIPT: Script = preload("res://scripts/hero_upgrade_data.gd")

const IRON_OATH_COMMANDER_UNIT: Resource = preload("res://data/heroes/iron_oath_commander_unit.tres")
const ARCANE_MENTOR_UNIT: Resource = preload("res://data/heroes/arcane_mentor_unit.tres")
const BLOODSHADOW_HUNTER_UNIT: Resource = preload("res://data/heroes/bloodshadow_hunter_unit.tres")
const BONEWEAVER_UNIT: Resource = preload("res://data/heroes/boneweaver_unit.tres")

const HERO_ID_IRON_OATH_COMMANDER: String = "iron_oath_commander"
const HERO_ID_ARCANE_MENTOR: String = "arcane_mentor"
const HERO_ID_BLOODSHADOW_HUNTER: String = "bloodshadow_hunter"
const HERO_ID_BONEWEAVER: String = "boneweaver"

const HERO_EXPERIENCE_TO_LEVEL: int = 50
const ENCOUNTER_TYPE_NORMAL: String = "NORMAL"
const ENCOUNTER_TYPE_ELITE: String = "ELITE"
const ENCOUNTER_TYPE_BOSS: String = "BOSS"
const BASE_STAT_UPGRADE_PREFIX: String = "hero_base_stat_"
const INVALID_CELL: Vector2i = Vector2i(-1, -1)

const META_IS_HERO: String = "is_hero"
const META_HERO_ID: String = "hero_id"
const META_HERO_LEVEL: String = "hero_level"
const META_HERO_UPGRADE_IDS: String = "hero_upgrade_ids"
const META_HERO_BASE_STAT_UPGRADE_COUNTS: String = "hero_base_stat_upgrade_counts"

var heroes: Dictionary = {}
var selected_hero: Resource = null
var hero_level: int = 0
var hero_experience: int = 0
var selected_upgrade_ids: Array[String] = []
var base_stat_upgrade_counts: Dictionary = {}
var pending_upgrade_options: Array[Dictionary] = []
var last_level_up_round: int = 0
var last_experience_round: int = 0
var has_saved_hero_position: bool = false
var saved_hero_cell: Vector2i = INVALID_CELL
var saved_hero_position: Vector2 = Vector2.ZERO


func _init() -> void:
	_build_hero_definitions()
	reset_hero()


func reset_hero() -> void:
	selected_hero = null
	hero_level = 0
	hero_experience = 0
	selected_upgrade_ids.clear()
	base_stat_upgrade_counts.clear()
	pending_upgrade_options.clear()
	last_level_up_round = 0
	last_experience_round = 0
	has_saved_hero_position = false
	saved_hero_cell = INVALID_CELL
	saved_hero_position = Vector2.ZERO


func get_available_heroes() -> Array[Resource]:
	var hero_list: Array[Resource] = []
	for hero_id: String in [
		HERO_ID_IRON_OATH_COMMANDER,
		HERO_ID_ARCANE_MENTOR,
		HERO_ID_BLOODSHADOW_HUNTER,
		HERO_ID_BONEWEAVER,
	]:
		var hero: Resource = heroes.get(hero_id, null) as Resource
		if hero != null:
			hero_list.append(hero)

	return hero_list


func has_selected_hero() -> bool:
	return selected_hero != null


func select_hero(hero_id: String) -> bool:
	var hero: Resource = heroes.get(hero_id, null) as Resource
	if hero == null:
		push_warning("Unknown hero id: " + hero_id)
		return false

	selected_hero = hero
	hero_level = 1
	hero_experience = 0
	selected_upgrade_ids.clear()
	base_stat_upgrade_counts.clear()
	pending_upgrade_options.clear()
	last_level_up_round = 0
	last_experience_round = 0
	has_saved_hero_position = false
	saved_hero_cell = INVALID_CELL
	saved_hero_position = Vector2.ZERO
	return true


func get_selected_hero_id() -> String:
	if selected_hero == null:
		return ""

	return str(selected_hero.get("hero_id"))


func get_selected_hero_name() -> String:
	if selected_hero == null:
		return ""

	if selected_hero.has_method("get_display_name"):
		return str(selected_hero.get_display_name())

	return str(selected_hero.get("hero_name"))


func get_state_snapshot() -> Dictionary:
	return {
		"selected_hero_id": get_selected_hero_id(),
		"hero_level": hero_level,
		"hero_experience": hero_experience,
		"hero_experience_to_next_level": get_experience_to_next_level(),
		"selected_upgrade_ids": selected_upgrade_ids.duplicate(),
		"base_stat_upgrade_counts": base_stat_upgrade_counts.duplicate(),
		"pending_upgrade_options": pending_upgrade_options.duplicate(true),
		"last_level_up_round": last_level_up_round,
		"last_experience_round": last_experience_round,
		"has_saved_hero_position": has_saved_hero_position,
		"saved_hero_cell": saved_hero_cell,
		"saved_hero_position": saved_hero_position,
	}


func get_selected_upgrade_ids() -> Array[String]:
	return selected_upgrade_ids.duplicate()


func has_selected_upgrade(upgrade_id: String) -> bool:
	return selected_upgrade_ids.has(upgrade_id)


func save_hero_cell(cell: Vector2i, position: Vector2) -> void:
	if selected_hero == null:
		return

	has_saved_hero_position = true
	saved_hero_cell = cell
	saved_hero_position = position


func clear_saved_hero_position() -> void:
	has_saved_hero_position = false
	saved_hero_cell = INVALID_CELL
	saved_hero_position = Vector2.ZERO


func get_reserved_hero_cell(battle_board: Variant) -> Vector2i:
	if selected_hero == null:
		return INVALID_CELL

	if battle_board == null or not is_instance_valid(battle_board):
		return INVALID_CELL

	if not has_saved_hero_position or saved_hero_cell == INVALID_CELL:
		return INVALID_CELL

	if battle_board.has_method("is_valid_player_cell") and battle_board.is_valid_player_cell(saved_hero_cell):
		return saved_hero_cell

	return INVALID_CELL


func get_experience_to_next_level() -> int:
	return HERO_EXPERIENCE_TO_LEVEL


func get_experience_progress_ratio() -> float:
	if HERO_EXPERIENCE_TO_LEVEL <= 0:
		return 0.0

	return clampf(float(hero_experience) / float(HERO_EXPERIENCE_TO_LEVEL), 0.0, 1.0)


func get_experience_reward_for_encounter(encounter_type: String) -> int:
	match encounter_type:
		ENCOUNTER_TYPE_ELITE:
			return 20
		ENCOUNTER_TYPE_BOSS:
			return 30
		_:
			return 10


func get_hero_battle_unit_config(battle_board: Variant, player_units: Array[Unit]) -> Dictionary:
	if selected_hero == null:
		return {}

	var hero_unit_data: Resource = create_hero_battle_unit_data()
	if hero_unit_data == null:
		return {}

	var hero_cell: Vector2i = _choose_hero_cell(battle_board, player_units)
	var hero_position: Vector2 = _get_fallback_hero_position()
	if battle_board != null and is_instance_valid(battle_board) and hero_cell != INVALID_CELL:
		hero_position = battle_board.grid_to_world(hero_cell)

	return {
		"unit_data": hero_unit_data,
		"position": hero_position,
		"display_name": _build_hero_display_name(),
		"roster_id": -1,
		"roster_area": "hero",
		"cell": hero_cell,
		"is_hero": true,
		"hero_id": get_selected_hero_id(),
		"hero_level": hero_level,
		"hero_upgrade_ids": selected_upgrade_ids.duplicate(),
		"hero_base_stat_upgrade_counts": base_stat_upgrade_counts.duplicate(),
	}


func create_hero_battle_unit_data() -> Resource:
	if selected_hero == null:
		return null

	var base_data: Resource = selected_hero.get("hero_unit_data") as Resource
	if base_data == null:
		return null

	var configured_data: Resource = base_data.duplicate(true) as Resource
	_apply_level_growth(configured_data)
	_apply_unit_data_upgrades(configured_data)
	_apply_base_stat_upgrades(configured_data)
	configured_data.set("unit_name", _build_hero_display_name())
	configured_data.set("unit_name_cn", _build_hero_display_name())
	configured_data.set("star", 1)
	return configured_data


func apply_hero_runtime_state(unit: Unit, unit_config: Dictionary) -> void:
	if unit == null or not is_instance_valid(unit):
		return

	if not bool(unit_config.get("is_hero", false)):
		return

	unit.roster_area = "hero"
	unit.roster_id = -1
	unit.display_name = str(unit_config.get("display_name", _build_hero_display_name()))
	unit.set_can_drag(true)
	unit.set_meta(META_IS_HERO, true)
	unit.set_meta(META_HERO_ID, str(unit_config.get("hero_id", get_selected_hero_id())))
	unit.set_meta(META_HERO_LEVEL, int(unit_config.get("hero_level", hero_level)))
	unit.set_meta(META_HERO_UPGRADE_IDS, _string_array_from_variant(unit_config.get("hero_upgrade_ids", [])))
	unit.set_meta(META_HERO_BASE_STAT_UPGRADE_COUNTS, unit_config.get("hero_base_stat_upgrade_counts", {}).duplicate())
	_apply_runtime_upgrades(unit)
	unit.update_info_display()


func process_victory_round(round_number: int) -> bool:
	return process_victory_encounter(round_number, ENCOUNTER_TYPE_NORMAL)


func process_victory_encounter(round_number: int, encounter_type: String) -> bool:
	pending_upgrade_options.clear()
	if selected_hero == null:
		return false

	if round_number > 0 and last_experience_round == round_number:
		return false

	last_experience_round = round_number
	var experience_reward: int = get_experience_reward_for_encounter(encounter_type)
	if experience_reward <= 0:
		return false

	var leveled_up: bool = gain_experience(experience_reward)
	if leveled_up:
		last_level_up_round = round_number
	return not pending_upgrade_options.is_empty()


func gain_experience(amount: int) -> bool:
	if selected_hero == null or amount <= 0:
		return false

	hero_experience += amount
	var leveled_up: bool = false
	while hero_experience >= HERO_EXPERIENCE_TO_LEVEL:
		hero_experience -= HERO_EXPERIENCE_TO_LEVEL
		hero_level += 1
		leveled_up = true

	if leveled_up:
		pending_upgrade_options = generate_hero_upgrade_options(3)

	return leveled_up and not pending_upgrade_options.is_empty()


func generate_hero_upgrade_options(option_count: int = 3) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if selected_hero == null:
		return options

	var candidate_upgrades: Array[Resource] = []
	var upgrade_pool: Array = selected_hero.get("upgrade_pool") as Array
	for upgrade_value: Variant in upgrade_pool:
		var upgrade: Resource = upgrade_value as Resource
		if upgrade == null:
			continue

		var upgrade_id: String = str(upgrade.get("upgrade_id"))
		if selected_upgrade_ids.has(upgrade_id):
			continue

		if int(upgrade.get("required_level")) > hero_level:
			continue

		candidate_upgrades.append(upgrade)

	candidate_upgrades.shuffle()
	var safe_count: int = mini(maxi(0, option_count), candidate_upgrades.size())
	for index: int in range(safe_count):
		var upgrade_data: Resource = candidate_upgrades[index]
		if upgrade_data.has_method("to_reward_option"):
			options.append(upgrade_data.to_reward_option())

	if options.size() < option_count:
		var stat_options: Array[Dictionary] = _generate_base_stat_upgrade_options(option_count - options.size())
		options.append_array(stat_options)

	return options


func get_pending_upgrade_options() -> Array[Dictionary]:
	return pending_upgrade_options.duplicate(true)


func apply_hero_upgrade(upgrade: Dictionary) -> bool:
	var upgrade_id: String = str(upgrade.get("upgrade_id", ""))
	if upgrade_id == "":
		return false

	if selected_hero == null:
		return false

	if _is_base_stat_upgrade_id(upgrade_id):
		_apply_base_stat_upgrade_choice(upgrade)
		pending_upgrade_options.clear()
		return true

	if selected_upgrade_ids.has(upgrade_id):
		return false

	var upgrade_data: Resource = _get_upgrade_by_id(upgrade_id)
	if upgrade_data == null:
		return false

	if int(upgrade_data.get("required_level")) > hero_level:
		return false

	selected_upgrade_ids.append(upgrade_id)
	pending_upgrade_options.clear()
	return true


func apply_hero_death_effect(dead_unit: Unit, player_units: Array[Unit]) -> void:
	if selected_hero == null or dead_unit == null or not is_instance_valid(dead_unit):
		return

	if not bool(dead_unit.get_meta(META_IS_HERO, false)):
		return

	if str(dead_unit.get_meta(META_HERO_ID, "")) != HERO_ID_IRON_OATH_COMMANDER:
		return

	if not selected_upgrade_ids.has("iron_final_defense"):
		return

	var shield_amount: int = maxi(1, 100 + int(dead_unit.defense))
	for unit: Unit in player_units:
		if unit != null and is_instance_valid(unit) and unit.is_alive and unit != dead_unit:
			unit.add_shield(shield_amount, dead_unit)


func _build_hero_definitions() -> void:
	heroes.clear()
	_register_hero(_create_iron_oath_commander())
	_register_hero(_create_arcane_mentor())
	_register_hero(_create_bloodshadow_hunter())
	_register_hero(_create_boneweaver())


func _register_hero(hero: Resource) -> void:
	if hero == null:
		return

	var hero_id: String = str(hero.get("hero_id"))
	if hero_id == "":
		return

	heroes[hero_id] = hero


func _create_iron_oath_commander() -> Resource:
	var hero: Resource = HERO_DATA_SCRIPT.new()
	hero.hero_id = HERO_ID_IRON_OATH_COMMANDER
	hero.hero_name = "Iron Oath Commander"
	hero.hero_name_cn = "铁誓统帅"
	hero.hero_unit_data = IRON_OATH_COMMANDER_UNIT
	hero.description = "防御 / 前排 / 护盾构筑。开战时强化前排，主动技能为全队构筑护盾。"
	hero.role_tags = PackedStringArray(["防御", "前排", "护盾构筑"])
	hero.base_passive_ids = PackedStringArray(["iron_oath_legion", "unbroken_line"])
	hero.base_active_skill_id = "hero_commanding_order"
	hero.recommended_cells = _create_cell_list([
		Vector2i(6, 3),
		Vector2i(6, 2),
		Vector2i(6, 4),
		Vector2i(5, 3),
		Vector2i(5, 2),
		Vector2i(5, 4),
	])
	hero.upgrade_pool = _create_upgrade_pool([
		_create_upgrade("iron_unshakable", "坚不可摧", "英雄自身防御 +50。", hero.hero_id, "STAT", "defense", 50.0, 2),
		_create_upgrade("iron_guard_synergy", "护卫协同", "每有 1 个承伤单位，全队防御 +10。", hero.hero_id, "TEAM_BATTLE_START", "guard_synergy", 10.0, 2),
		_create_upgrade("iron_heavy_formation", "重甲阵列", "所有前排单位获得最大生命值 +20%。", hero.hero_id, "TEAM_BATTLE_START", "frontline_max_hp", 0.20, 2),
		_create_upgrade("iron_shield_training", "护盾训练", "玩家单位获得的护盾值提高 15%。", hero.hero_id, "TEAM_BATTLE_START", "shield_received_multiplier", 0.15, 2),
		_create_upgrade("iron_wall_spread", "铁壁扩散", "统帅号令的防御加成也影响中排单位。", hero.hero_id, "ACTIVE_MOD", "command_midline", 1.0, 3),
		_create_upgrade("iron_line_echo", "战线回响", "玩家单位获得护盾时恢复 10 魔力，每个单位每 2 秒最多触发一次。", hero.hero_id, "TEAM_BATTLE_START", "shield_mana_echo", 10.0, 3),
		_create_upgrade("iron_hold_horn", "坚守号角", "统帅号令额外治疗前排单位 10% 已损生命。", hero.hero_id, "ACTIVE_MOD", "command_frontline_heal", 0.10, 4),
		_create_upgrade("iron_final_defense", "最终防线", "英雄死亡时，所有玩家单位获得 100 + 英雄防御的护盾。", hero.hero_id, "DEATH", "final_defense", 100.0, 4),
	])
	return hero


func _create_arcane_mentor() -> Resource:
	var hero: Resource = HERO_DATA_SCRIPT.new()
	hero.hero_id = HERO_ID_ARCANE_MENTOR
	hero.hero_name = "Arcane Mentor"
	hero.hero_name_cn = "奥术导师"
	hero.hero_unit_data = ARCANE_MENTOR_UNIT
	hero.description = "技能 / 魔力 / 法术构筑。友方释放主动技能会为导师回蓝，并提高全队主动技能伤害。"
	hero.role_tags = PackedStringArray(["技能", "魔力", "法术构筑"])
	hero.base_passive_ids = PackedStringArray(["arcane_reflow", "spell_resonance"])
	hero.base_active_skill_id = "hero_arcane_storm"
	hero.recommended_cells = _create_cell_list([
		Vector2i(1, 3),
		Vector2i(1, 2),
		Vector2i(1, 4),
		Vector2i(0, 3),
		Vector2i(0, 2),
		Vector2i(0, 4),
		Vector2i(2, 3),
	])
	hero.upgrade_pool = _create_upgrade_pool([
		_create_upgrade("arcane_mana_surge", "魔力涌动", "所有玩家单位魔力回复速度 +10%。", hero.hero_id, "TEAM_BATTLE_START", "mana_regen_multiplier", 0.10, 2),
		_create_upgrade("arcane_spell_piercing", "法术穿透", "玩家主动技能伤害额外提高 10%。", hero.hero_id, "DAMAGE_MOD", "active_skill_damage", 0.10, 2),
		_create_upgrade("arcane_mana_shield", "魔力护盾", "玩家单位释放主动技能后获得 10 护盾。", hero.hero_id, "SKILL_CAST", "mana_shield", 10.0, 2),
		_create_upgrade("arcane_elemental_overload", "元素过载", "法师、炼金术士、爆弹投手攻击力 +12%。", hero.hero_id, "TEAM_BATTLE_START", "elemental_attack", 0.12, 2),
		_create_upgrade("arcane_chain_casting", "连锁施法", "奥术导师释放主动技能后，随机友方单位恢复 30 魔力。", hero.hero_id, "SKILL_CAST", "chain_mana", 30.0, 3),
		_create_upgrade("arcane_alchemical_resonance", "炼金共振", "场地持续伤害类技能伤害 +20%。", hero.hero_id, "DAMAGE_MOD", "field_skill_damage", 0.20, 3),
		_create_upgrade("arcane_shattering_storm", "爆裂奥术", "奥术风暴每额外命中 1 个敌人，伤害提高 5%，最多 25%。", hero.hero_id, "ACTIVE_MOD", "storm_bonus_per_hit", 0.05, 3),
		_create_upgrade("arcane_quick_chanting", "快速吟唱", "奥术导师最大魔力 -15，但技能伤害降低 8%。", hero.hero_id, "STAT", "quick_chanting", 1.0, 4),
	])
	return hero


func _create_bloodshadow_hunter() -> Resource:
	var hero: Resource = HERO_DATA_SCRIPT.new()
	hero.hero_id = HERO_ID_BLOODSHADOW_HUNTER
	hero.hero_name = "Bloodshadow Hunter"
	hero.hero_name_cn = "血影猎手"
	hero.hero_unit_data = BLOODSHADOW_HUNTER_UNIT
	hero.description = "暴击 / 刺杀 / 收割构筑。开战标记后排目标，击杀会转化为治疗、回蓝和暴击节奏。"
	hero.role_tags = PackedStringArray(["暴击", "刺杀", "收割构筑"])
	hero.base_passive_ids = PackedStringArray(["hunt_mark", "bloodshadow_harvest"])
	hero.base_active_skill_id = "hero_bloodshadow_assault"
	hero.recommended_cells = _create_cell_list([
		Vector2i(4, 1),
		Vector2i(4, 5),
		Vector2i(3, 1),
		Vector2i(3, 5),
		Vector2i(4, 2),
		Vector2i(4, 4),
		Vector2i(3, 3),
	])
	hero.upgrade_pool = _create_upgrade_pool([
		_create_upgrade("blood_lethal_instinct", "致命预感", "全队暴击率 +8%。", hero.hero_id, "TEAM_BATTLE_START", "crit_chance", 0.08, 2),
		_create_upgrade("blood_hunter_instinct", "猎手本能", "刺客和弓手暴击伤害 +30%。", hero.hero_id, "TEAM_BATTLE_START", "assassin_archer_crit_damage", 0.30, 2),
		_create_upgrade("blood_weakness_exposed", "弱点暴露", "被标记目标防御 -20。", hero.hero_id, "MARK_MOD", "marked_defense_down", 20.0, 2),
		_create_upgrade("blood_hunt_pace", "追猎节奏", "被标记目标受到攻击时，攻击者恢复 5 魔力。", hero.hero_id, "ATTACK_MARK", "marked_attack_mana", 5.0, 2),
		_create_upgrade("blood_continuous_harvest", "连续收割", "玩家单位击杀后攻击间隔降低 15%，持续 5 秒。", hero.hero_id, "KILL", "harvest_haste", 0.85, 3),
		_create_upgrade("blood_mark_retarget", "猎手追踪", "标记目标死亡后，重新标记 1 个敌人。", hero.hero_id, "MARK_MOD", "retarget_mark", 1.0, 3),
		_create_upgrade("blood_wounded_hunter", "残血猎杀", "玩家单位攻击生命比例低于 35% 的敌人时，伤害 +12%。", hero.hero_id, "DAMAGE_MOD", "low_hp_damage", 0.12, 3),
		_create_upgrade("blood_shadow_shelter", "暗影庇护", "刺客和弓手击杀后获得 25 护盾。", hero.hero_id, "KILL", "assassin_archer_shield", 25.0, 3),
		_create_upgrade("blood_shadow_chain", "血影连斩", "英雄主动技能击杀后，可对最近敌人追加一次 60% 威力的突袭。", hero.hero_id, "ACTIVE_MOD", "assault_chain", 0.60, 4),
	])
	return hero


func _create_boneweaver() -> Resource:
	var hero: Resource = HERO_DATA_SCRIPT.new()
	hero.hero_id = HERO_ID_BONEWEAVER
	hero.hero_name = "Boneweaver"
	hero.hero_name_cn = "织骨者"
	hero.hero_unit_data = BONEWEAVER_UNIT
	hero.description = "召唤 / 亡灵 / 数量压制。强化全队召唤单位，主动技能召唤骨巨人辅助战斗。"
	hero.role_tags = PackedStringArray(["召唤", "亡灵", "数量压制"])
	hero.base_passive_ids = PackedStringArray(["bone_tide", "undying_thralls"])
	hero.base_active_skill_id = "hero_bone_golem"
	hero.recommended_cells = _create_cell_list([
		Vector2i(0, 2),
		Vector2i(0, 3),
		Vector2i(0, 4),
		Vector2i(1, 2),
		Vector2i(1, 3),
		Vector2i(1, 4),
		Vector2i(2, 3),
	])
	hero.upgrade_pool = _create_upgrade_pool([
		_create_upgrade("skeleton_vigor", "骸骨活力", "所有召唤单位最大生命 +25%。", hero.hero_id, "TEAM_BATTLE_START", "summon_max_hp", 0.25, 2),
		_create_upgrade("bone_spike_armor", "骨刺护甲", "召唤单位获得 10% 伤害反弹。", hero.hero_id, "TEAM_BATTLE_START", "summon_thorns", 0.10, 2),
		_create_upgrade("death_echo", "亡者回响", "召唤单位死亡时对周围 80 内敌人造成 60% 攻击力的伤害。", hero.hero_id, "SUMMON_DEATH", "death_echo_damage", 0.60, 2),
		_create_upgrade("grave_caller", "墓穴召唤", "玩家召唤单位上限 +1。", hero.hero_id, "TEAM_BATTLE_START", "summon_cap", 1.0, 2),
		_create_upgrade("bone_golem_fury", "骨巨人狂怒", "骨巨人（近战肉盾）攻击力 +30%，攻击速度 +20%。", hero.hero_id, "SUMMON_MOD", "golem_fury", 1.0, 3),
		_create_upgrade("skeletal_fortitude", "骸骨坚韧", "召唤单位受到的范围伤害 -20%。", hero.hero_id, "TEAM_BATTLE_START", "summon_aoe_reduction", 0.20, 3),
		_create_upgrade("bone_dragon", "骨龙降临", "额外召唤一只骨龙（远程范围输出），与骨巨人召唤上限分开计算。", hero.hero_id, "ACTIVE_MOD", "bone_dragon", 1.0, 4),
		_create_upgrade("eternal_thralls", "永恒仆从", "不灭仆从无敌时间从 2 秒延长至 4 秒。", hero.hero_id, "PASSIVE_MOD", "thralls_duration", 4.0, 4),
	])
	return hero


func _create_cell_list(cells: Array) -> Array[Vector2i]:
	var typed_cells: Array[Vector2i] = []
	for cell_value: Variant in cells:
		typed_cells.append(cell_value as Vector2i)

	return typed_cells


func _create_upgrade_pool(upgrades: Array) -> Array[Resource]:
	var typed_upgrades: Array[Resource] = []
	for upgrade_value: Variant in upgrades:
		var upgrade: Resource = upgrade_value as Resource
		if upgrade != null:
			typed_upgrades.append(upgrade)

	return typed_upgrades


func _create_upgrade(
	upgrade_id: String,
	upgrade_name: String,
	description: String,
	hero_id: String,
	effect_type: String,
	effect_key: String,
	value: float,
	required_level: int
) -> Resource:
	var upgrade: Resource = HERO_UPGRADE_DATA_SCRIPT.new()
	upgrade.upgrade_id = upgrade_id
	upgrade.upgrade_name = upgrade_name
	upgrade.description = description
	upgrade.hero_id = hero_id
	upgrade.effect_type = effect_type
	upgrade.effect_key = effect_key
	upgrade.value = value
	upgrade.required_level = required_level
	return upgrade


func _apply_level_growth(unit_data: Resource) -> void:
	var level_steps: int = maxi(0, hero_level - 1)
	if level_steps <= 0:
		return

	var curve_steps: float = float(level_steps)
	var accelerating_steps: float = float(level_steps * maxi(0, level_steps - 1))
	var max_hp_multiplier: float = 1.0 + 0.10 * curve_steps + 0.012 * accelerating_steps
	var attack_multiplier: float = 1.0 + 0.07 * curve_steps + 0.008 * accelerating_steps
	var defense_bonus: int = int(round(4.0 * curve_steps + 1.2 * accelerating_steps))
	var mana_regen_multiplier: float = 1.0 + 0.035 * curve_steps
	unit_data.set("max_hp", maxi(1, int(round(float(unit_data.get("max_hp")) * max_hp_multiplier))))
	unit_data.set("attack_damage", maxi(1, int(round(float(unit_data.get("attack_damage")) * attack_multiplier))))
	unit_data.set("defense", maxi(0, int(unit_data.get("defense")) + defense_bonus))
	unit_data.set("mana_regen_per_second", maxf(0.0, float(unit_data.get("mana_regen_per_second")) * mana_regen_multiplier))


func _apply_unit_data_upgrades(unit_data: Resource) -> void:
	if selected_upgrade_ids.has("iron_unshakable"):
		unit_data.set("defense", int(unit_data.get("defense")) + 50)

	if selected_upgrade_ids.has("arcane_quick_chanting"):
		unit_data.set("max_mana", maxi(1, int(unit_data.get("max_mana")) - 15))


func _apply_base_stat_upgrades(unit_data: Resource) -> void:
	var max_hp_count: int = _get_base_stat_upgrade_count("hero_base_stat_max_hp")
	if max_hp_count > 0:
		var max_hp_multiplier: float = pow(1.12, float(max_hp_count))
		unit_data.set("max_hp", maxi(1, int(round(float(unit_data.get("max_hp")) * max_hp_multiplier))))

	var attack_count: int = _get_base_stat_upgrade_count("hero_base_stat_attack_damage")
	if attack_count > 0:
		var attack_multiplier: float = pow(1.10, float(attack_count))
		unit_data.set("attack_damage", maxi(1, int(round(float(unit_data.get("attack_damage")) * attack_multiplier))))

	var defense_count: int = _get_base_stat_upgrade_count("hero_base_stat_defense")
	if defense_count > 0:
		unit_data.set("defense", maxi(0, int(unit_data.get("defense")) + 8 * defense_count))

	var mana_regen_count: int = _get_base_stat_upgrade_count("hero_base_stat_mana_regen")
	if mana_regen_count > 0:
		var mana_regen_multiplier: float = pow(1.12, float(mana_regen_count))
		unit_data.set("mana_regen_per_second", maxf(0.0, float(unit_data.get("mana_regen_per_second")) * mana_regen_multiplier))


func _apply_runtime_upgrades(unit: Unit) -> void:
	if selected_upgrade_ids.has("arcane_quick_chanting"):
		unit.active_skill_damage_multiplier *= 0.92


func _choose_hero_cell(battle_board: Variant, player_units: Array[Unit]) -> Vector2i:
	if battle_board == null or not is_instance_valid(battle_board):
		return INVALID_CELL

	var occupied_cells: Array[Vector2i] = _get_occupied_player_cells(battle_board, player_units)
	if has_saved_hero_position and saved_hero_cell != INVALID_CELL:
		if battle_board.is_valid_player_cell(saved_hero_cell) and not _is_cell_in_list(saved_hero_cell, occupied_cells):
			return saved_hero_cell

	var recommended_cells: Array = selected_hero.get("recommended_cells") as Array
	for cell_value: Variant in recommended_cells:
		var cell: Vector2i = cell_value as Vector2i
		if battle_board.is_valid_player_cell(cell) and not _is_cell_in_list(cell, occupied_cells):
			return cell

	var unit_data: Resource = selected_hero.get("hero_unit_data") as Resource
	if unit_data != null:
		var unit_id: String = str(unit_data.get("unit_type"))
		var role: String = str(unit_data.get("role"))
		var fallback_cell: Vector2i = battle_board.get_recommended_cell_for_unit(unit_id, role, true, occupied_cells, false)
		if fallback_cell != INVALID_CELL:
			return fallback_cell

	return INVALID_CELL


func _get_occupied_player_cells(battle_board: Variant, player_units: Array[Unit]) -> Array[Vector2i]:
	var occupied_cells: Array[Vector2i] = []
	for unit: Unit in player_units:
		if unit == null or not is_instance_valid(unit) or not unit.is_alive:
			continue

		var cell: Vector2i = battle_board.world_to_grid(unit.position)
		if battle_board.is_valid_player_cell(cell) and not _is_cell_in_list(cell, occupied_cells):
			occupied_cells.append(cell)

	return occupied_cells


func _get_fallback_hero_position() -> Vector2:
	if has_saved_hero_position:
		return saved_hero_position

	match get_selected_hero_id():
		HERO_ID_IRON_OATH_COMMANDER:
			return Vector2(360.0, 320.0)
		HERO_ID_ARCANE_MENTOR:
			return Vector2(160.0, 320.0)
		HERO_ID_BLOODSHADOW_HUNTER:
			return Vector2(300.0, 240.0)
		_:
			return Vector2(240.0, 320.0)


func _build_hero_display_name() -> String:
	if selected_hero == null:
		return "英雄"

	return get_selected_hero_name() + " Lv." + str(maxi(1, hero_level))


func _get_upgrade_by_id(upgrade_id: String) -> Resource:
	for hero_value: Variant in heroes.values():
		var hero: Resource = hero_value as Resource
		if hero == null:
			continue

		var upgrade_pool: Array = hero.get("upgrade_pool") as Array
		for upgrade_value: Variant in upgrade_pool:
			var upgrade: Resource = upgrade_value as Resource
			if upgrade != null and str(upgrade.get("upgrade_id")) == upgrade_id:
				return upgrade

	return null


func _has_selected_all_hero_specific_upgrades() -> bool:
	if selected_hero == null:
		return false

	var upgrade_pool: Array = selected_hero.get("upgrade_pool") as Array
	if upgrade_pool.is_empty():
		return true

	for upgrade_value: Variant in upgrade_pool:
		var upgrade: Resource = upgrade_value as Resource
		if upgrade == null:
			continue

		var upgrade_id: String = str(upgrade.get("upgrade_id"))
		if upgrade_id != "" and not selected_upgrade_ids.has(upgrade_id):
			return false

	return true


func _generate_base_stat_upgrade_options(option_count: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	if option_count <= 0:
		return options

	var templates: Array[Dictionary] = [
		_create_base_stat_upgrade_option(
			"hero_base_stat_max_hp",
			"英雄体魄",
			"英雄最大生命 +12%。可重复选择。",
			"max_hp_multiplier",
			0.12
		),
		_create_base_stat_upgrade_option(
			"hero_base_stat_attack_damage",
			"英雄武训",
			"英雄攻击力 +10%。可重复选择。",
			"attack_damage_multiplier",
			0.10
		),
		_create_base_stat_upgrade_option(
			"hero_base_stat_defense",
			"英雄护甲",
			"英雄防御 +8。可重复选择。",
			"defense_flat",
			8.0
		),
		_create_base_stat_upgrade_option(
			"hero_base_stat_mana_regen",
			"英雄聚能",
			"英雄魔力回复速度 +12%。可重复选择。",
			"mana_regen_multiplier",
			0.12
		),
	]
	templates.shuffle()

	var safe_count: int = mini(option_count, templates.size())
	for index: int in range(safe_count):
		options.append(templates[index])

	return options


func _create_base_stat_upgrade_option(
	upgrade_id: String,
	upgrade_name: String,
	description: String,
	effect_key: String,
	value: float
) -> Dictionary:
	var current_count: int = _get_base_stat_upgrade_count(upgrade_id)
	var final_description: String = description + " 当前层数：" + str(current_count) + "。"
	return {
		"type": "HERO_UPGRADE",
		"upgrade_id": upgrade_id,
		"name": upgrade_name,
		"description": final_description,
		"rarity": "RARE",
		"hero_id": get_selected_hero_id(),
		"effect_type": "BASE_STAT",
		"effect_key": effect_key,
		"value": value,
		"required_level": hero_level,
		"is_repeatable": true,
	}


func _is_base_stat_upgrade_id(upgrade_id: String) -> bool:
	return upgrade_id.begins_with(BASE_STAT_UPGRADE_PREFIX)


func _apply_base_stat_upgrade_choice(upgrade: Dictionary) -> void:
	var upgrade_id: String = str(upgrade.get("upgrade_id", ""))
	if not _is_base_stat_upgrade_id(upgrade_id):
		return

	base_stat_upgrade_counts[upgrade_id] = _get_base_stat_upgrade_count(upgrade_id) + 1


func _get_base_stat_upgrade_count(upgrade_id: String) -> int:
	return maxi(0, int(base_stat_upgrade_counts.get(upgrade_id, 0)))


func _string_array_from_variant(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not (value is Array):
		return result

	for item: Variant in value:
		var text: String = str(item)
		if text != "":
			result.append(text)

	return result


func _is_cell_in_list(cell: Vector2i, cells: Array[Vector2i]) -> bool:
	for existing_cell: Vector2i in cells:
		if existing_cell == cell:
			return true

	return false
