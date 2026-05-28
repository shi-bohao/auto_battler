class_name ActiveSkillCaster
extends RefCounted


const DEBUG_LOG_SCRIPT: Script = preload("res://scripts/debug_log.gd")
const StatusEffectFactory: Script = preload("res://scripts/combat/status_effect_factory.gd")
const PassiveResolver: Script = preload("res://scripts/combat/passive_resolver.gd")
const AoeResolver: Script = preload("res://scripts/combat/aoe_resolver.gd")
const SKELETON_SUMMON_DATA: Resource = preload("res://data/summons/skeleton.tres")
const SOUL_PUPPET_SUMMON_DATA: Resource = preload("res://data/summons/soul_puppet.tres")
const BONE_GOLEM_SUMMON_DATA: Resource = preload("res://data/summons/bone_golem.tres")
const BONE_DRAGON_SUMMON_DATA: Resource = preload("res://data/summons/bone_dragon.tres")

const SKILL_GUARD_BARRIER: String = "guard_barrier"
const SKILL_PIERCING_ARROW: String = "piercing_arrow"
const SKILL_SHADOW_STRIKE: String = "shadow_strike"
const SKILL_STONE_GUARD: String = "stone_guard"
const SKILL_FIREBALL: String = "fireball"
const SKILL_HOLY_LIGHT: String = "holy_light"
const SKILL_INSPIRING_SONG: String = "inspiring_song"
const SKILL_REGROWTH: String = "regrowth"
const SKILL_TOXIC_CLOUD: String = "toxic_cloud"
const SKILL_IRON_ORDER: String = "iron_order"
const SKILL_HASTE_SONG: String = "haste_song"
const SKILL_SWEEPING_SLASH: String = "sweeping_slash"
const SKILL_EXPLOSIVE_BARRAGE: String = "explosive_barrage"
const SKILL_SANCTUARY: String = "sanctuary"
const SKILL_ACID_FIELD: String = "acid_field"
const SKILL_RAISE_SKELETONS: String = "raise_skeletons"
const SKILL_PUPPET_MARK: String = "puppet_mark"
const SKILL_SUMMONED_BONE_SLASH: String = "summoned_bone_slash"
const SKILL_SUMMONED_PUPPET_GUARD: String = "summoned_puppet_guard"
const SKILL_HERO_COMMANDING_ORDER: String = "hero_commanding_order"
const SKILL_HERO_ARCANE_STORM: String = "hero_arcane_storm"
const SKILL_HERO_BLOODSHADOW_ASSAULT: String = "hero_bloodshadow_assault"
const SKILL_HERO_BONE_GOLEM: String = "hero_bone_golem"
const SKILL_SUMMONED_GOLEM_SMASH: String = "summoned_golem_smash"
const SKILL_SUMMONED_DRAGON_BARRAGE: String = "summoned_dragon_barrage"
const SKILL_ENEMY_GUARD_STANCE: String = "enemy_guard_stance"
const SKILL_ENEMY_HARDEN: String = "enemy_harden"
const SKILL_ENEMY_FORTIFY_ALLIES: String = "enemy_fortify_allies"
const SKILL_ENEMY_EARTHBREAKER_BARRIER: String = "enemy_earthbreaker_barrier"
const SKILL_ENEMY_POWER_SHOT: String = "enemy_power_shot"
const SKILL_ENEMY_FIREBOLT: String = "enemy_firebolt"
const SKILL_ENEMY_SHADOW_CLEAVE: String = "enemy_shadow_cleave"
const SKILL_ENEMY_VOID_BEAM: String = "enemy_void_beam"
const SKILL_ENEMY_DARK_HEAL: String = "enemy_dark_heal"
const SKILL_ENEMY_DRUM_SHIELD: String = "enemy_drum_shield"
const SKILL_ENEMY_ORACLE_BLESSING: String = "enemy_oracle_blessing"
const SKILL_ENEMY_MASS_BENEDICTION: String = "enemy_mass_benediction"
const SKILL_ENEMY_RAISE_SKELETONS: String = "enemy_raise_skeletons"
const SKILL_ENEMY_PUPPET_MARK: String = "enemy_puppet_mark"
const SKILL_BINDING_RITE: String = "binding_rite"
const SKILL_ASTRAL_BULWARK: String = "astral_bulwark"
const SKILL_ARCANE_BARRAGE: String = "arcane_barrage"
const SKILL_FEAST_OF_VENOM: String = "feast_of_venom"
const SKILL_BELL_OF_SANCTUARY: String = "bell_of_sanctuary"
const SKILL_REAPING_COMMAND: String = "reaping_command"
const SKILL_BLOOD_DEBT_SLASH: String = "blood_debt_slash"
const SKILL_FOCUS_BEAM: String = "focus_beam"
const SKILL_SEPTIC_SPIT: String = "septic_spit"
const SKILL_PUTRID_TIDE: String = "putrid_tide"

const REGROWTH_DURATION: float = 5.0
const REGROWTH_HEAL_BASE: float = 18.0
const REGROWTH_ATTACK_RATIO: float = 0.65
const REGROWTH_HEAL_BASE_STAR_3: float = 28.0
const REGROWTH_ATTACK_RATIO_STAR_3: float = 0.9
const TOXIC_CLOUD_DURATION: float = 5.0
const TOXIC_CLOUD_DURATION_STAR_3: float = 6.0
const TOXIC_CLOUD_DAMAGE_BASE: float = 15.0
const TOXIC_CLOUD_ATTACK_RATIO: float = 0.45
const TOXIC_CLOUD_DAMAGE_BASE_STAR_3: float = 24.0
const TOXIC_CLOUD_ATTACK_RATIO_STAR_3: float = 0.6
const IRON_ORDER_DURATION: float = 5.0
const IRON_ORDER_DURATION_STAR_3: float = 6.0
const IRON_ORDER_DEFENSE: float = 30.0
const IRON_ORDER_DEFENSE_STAR_3: float = 50.0
const IRON_ORDER_SHIELD_STAR_3: int = 35
const HASTE_SONG_DURATION: float = 5.0
const HASTE_SONG_DURATION_STAR_3: float = 6.0
const HASTE_SONG_ATTACK_INTERVAL_MULTIPLIER: float = 0.84
const HASTE_SONG_ATTACK_INTERVAL_MULTIPLIER_STAR_3: float = 0.74
const HASTE_SONG_MANA_REGEN_MULTIPLIER: float = 1.20
const HASTE_SONG_MANA_REGEN_MULTIPLIER_STAR_3: float = 1.32
const STATUS_EFFECT_TICK_INTERVAL: float = 1.0
const EFFECT_REGROWTH: String = "regrowth_hot"
const EFFECT_TOXIC_CLOUD: String = "toxic_cloud_dot"
const EFFECT_IRON_ORDER: String = "iron_order_defense"
const EFFECT_HASTE_SONG_ATTACK: String = "haste_song_attack_interval"
const EFFECT_HASTE_SONG_MANA: String = "haste_song_mana_regen"
const EFFECT_SANCTUARY: String = "sanctuary_hot"
const EFFECT_PUPPET_MARK_VULNERABILITY: String = "puppet_mark_vulnerability"
const PUPPET_MARK_META: String = "summon_puppet_marked"
const PUPPET_MARK_VULNERABILITY_DURATION: float = 8.0
const PUPPET_MARK_VULNERABILITY_DURATION_STAR_3: float = 10.0
const PUPPET_MARK_VULNERABILITY_MULTIPLIER: float = 1.15
const PUPPET_MARK_VULNERABILITY_MULTIPLIER_STAR_3: float = 1.25
const SUMMONED_BONE_SLASH_DAMAGE_MULTIPLIER: float = 1.6
const SUMMONED_BONE_SLASH_DAMAGE_MULTIPLIER_STAR_3: float = 2.1
const SUMMONED_PUPPET_GUARD_BASE_SHIELD: int = 25
const SUMMONED_PUPPET_GUARD_BASE_SHIELD_STAR_3: int = 40
const SUMMONED_PUPPET_GUARD_MAX_HP_RATIO: float = 0.18
const SUMMONED_PUPPET_GUARD_MAX_HP_RATIO_STAR_3: float = 0.25
const SEPTIC_SPIT_DAMAGE_MULTIPLIER: float = 1.2
const SEPTIC_SPIT_VENOM_DURATION: float = 5.0
const SEPTIC_SPIT_VENOM_STACKS: int = 2
const SEPTIC_SPIT_MARK_DURATION: float = 6.0
const PUTRID_TIDE_DAMAGE_MULTIPLIER: float = 1.4
const PUTRID_TIDE_SECTOR_RADIUS: float = 130.0
const PUTRID_TIDE_SECTOR_ANGLE: float = 90.0
const PUTRID_TIDE_MARK_BONUS_MULTIPLIER: float = 1.25
const PUTRID_TIDE_VENOM_DURATION: float = 4.0
const PUTRID_TIDE_VENOM_STACKS: int = 2
const PUTRID_TIDE_MARK_DURATION: float = 5.0
const EFFECT_PUTRID_MARK: String = "putrid_mark"
const PUTRID_TIDE_VISUAL_COLOR: Color = Color(0.42, 0.82, 0.28, 0.22)

const SWEEPING_SLASH_DAMAGE_MULTIPLIER: float = 1.6
const SWEEPING_SLASH_DAMAGE_MULTIPLIER_STAR_3: float = 2.0
const SWEEPING_SLASH_SHIELD_STAR_3: int = 20
const EXPLOSIVE_BARRAGE_RADIUS: float = 100.0
const EXPLOSIVE_BARRAGE_RADIUS_STAR_3: float = 120.0
const EXPLOSIVE_BARRAGE_DAMAGE_MULTIPLIER: float = 1.7
const EXPLOSIVE_BARRAGE_DAMAGE_MULTIPLIER_STAR_3: float = 2.1
const EXPLOSIVE_BARRAGE_MANA_RESTORE_STAR_3: float = 20.0
const EXPLOSIVE_BARRAGE_MANA_RESTORE_MIN_HITS: int = 3
const SANCTUARY_RADIUS: float = 120.0
const SANCTUARY_RADIUS_STAR_3: float = 140.0
const SANCTUARY_BASE_HEAL: float = 35.0
const SANCTUARY_ATTACK_RATIO: float = 1.2
const SANCTUARY_BASE_HEAL_STAR_3: float = 55.0
const SANCTUARY_ATTACK_RATIO_STAR_3: float = 1.5
const SANCTUARY_SHIELD_STAR_3: int = 15
const SANCTUARY_DURATION: float = 3.0
const SANCTUARY_TICK_INTERVAL: float = 1.0
const ACID_FIELD_RADIUS: float = 100.0
const ACID_FIELD_RADIUS_STAR_3: float = 120.0
const ACID_FIELD_DURATION: float = 5.0
const ACID_FIELD_DURATION_STAR_3: float = 6.0
const ACID_FIELD_TICK_INTERVAL: float = 1.0
const ACID_FIELD_DAMAGE_BASE: float = 10.0
const ACID_FIELD_ATTACK_RATIO: float = 0.35
const ACID_FIELD_DAMAGE_BASE_STAR_3: float = 16.0
const ACID_FIELD_ATTACK_RATIO_STAR_3: float = 0.45

const GUARD_BARRIER_BASE_SHIELD: int = 30
const GUARD_BARRIER_BASE_SHIELD_STAR_3: int = 50
const GUARD_BARRIER_MAX_HP_RATIO: float = 0.25
const GUARD_BARRIER_MAX_HP_RATIO_STAR_3: float = 0.35
const GUARD_BARRIER_ALLY_RATIO: float = 0.4
const PIERCING_ARROW_DAMAGE_MULTIPLIER: float = 1.8
const PIERCING_ARROW_DAMAGE_MULTIPLIER_STAR_3: float = 2.3
const SHADOW_STRIKE_DAMAGE_MULTIPLIER: float = 2.6
const SHADOW_STRIKE_DAMAGE_MULTIPLIER_STAR_3: float = 3.4
const SHADOW_STRIKE_KILL_HEAL: int = 35
const SHADOW_STRIKE_KILL_HEAL_STAR_3: int = 60
const STONE_GUARD_BASE_SHIELD: int = 40
const STONE_GUARD_BASE_SHIELD_STAR_3: int = 70
const STONE_GUARD_MAX_HP_RATIO: float = 0.30
const STONE_GUARD_MAX_HP_RATIO_STAR_3: float = 0.40
const FIREBALL_DAMAGE_MULTIPLIER: float = 3.0
const FIREBALL_DAMAGE_MULTIPLIER_STAR_3: float = 4.0
const HOLY_LIGHT_BASE_HEAL: int = 35
const HOLY_LIGHT_BASE_HEAL_STAR_3: int = 60
const HOLY_LIGHT_ATTACK_RATIO: float = 1.5
const HOLY_LIGHT_ATTACK_RATIO_STAR_3: float = 2.0
const HOLY_LIGHT_SELF_HEAL_RATIO_STAR_3: float = 0.5
const INSPIRING_SONG_BASE_SHIELD: int = 15
const INSPIRING_SONG_BASE_SHIELD_STAR_3: int = 25
const INSPIRING_SONG_ATTACK_RATIO: float = 0.8
const INSPIRING_SONG_ATTACK_RATIO_STAR_3: float = 1.2
const ENEMY_GUARD_STANCE_BASE_SHIELD: int = 25
const ENEMY_GUARD_STANCE_MAX_HP_RATIO: float = 0.15
const ENEMY_HARDEN_SHIELD: int = 40
const ENEMY_FORTIFY_SELF_SHIELD: int = 60
const ENEMY_FORTIFY_ALLY_SHIELD: int = 20
const ENEMY_EARTHBREAKER_BASE_SHIELD: int = 100
const ENEMY_EARTHBREAKER_MAX_HP_RATIO: float = 0.12
const ENEMY_EARTHBREAKER_DAMAGE_MULTIPLIER: float = 1.8
const ENEMY_POWER_SHOT_DAMAGE_MULTIPLIER: float = 1.8
const ENEMY_FIREBOLT_DAMAGE_MULTIPLIER: float = 2.5
const ENEMY_SHADOW_CLEAVE_DAMAGE_MULTIPLIER: float = 2.6
const ENEMY_SHADOW_CLEAVE_KILL_HEAL: int = 30
const ENEMY_VOID_BEAM_DAMAGE_MULTIPLIER: float = 3.2
const ENEMY_VOID_BEAM_LOW_HP_RATIO: float = 0.50
const ENEMY_VOID_BEAM_LOW_HP_MULTIPLIER: float = 1.25
const ENEMY_DARK_HEAL_BASE: int = 30
const ENEMY_DARK_HEAL_ATTACK_RATIO: float = 1.3
const ENEMY_DRUM_SHIELD_AMOUNT: int = 15
const ENEMY_ORACLE_HEAL_BASE: int = 50
const ENEMY_ORACLE_HEAL_ATTACK_RATIO: float = 1.5
const ENEMY_ORACLE_SHIELD: int = 20
const ENEMY_MASS_BENEDICTION_HEAL_BASE: int = 25
const ENEMY_MASS_BENEDICTION_ATTACK_RATIO: float = 1.2
const ENEMY_MASS_BENEDICTION_SHIELD: int = 50
const INSTANT_AOE_VISUAL_DURATION: float = 0.45
const SWEEPING_SLASH_VISUAL_COLOR: Color = Color(1.0, 0.76, 0.28, 0.24)
const EXPLOSIVE_BARRAGE_VISUAL_COLOR: Color = Color(1.0, 0.34, 0.14, 0.24)
const SANCTUARY_VISUAL_COLOR: Color = Color(0.35, 0.78, 1.0, 0.24)
const HERO_COMMANDING_ORDER_DURATION: float = 5.0
const HERO_COMMANDING_ORDER_DURATION_LV4: float = 6.0
const HERO_ARCANE_STORM_RADIUS: float = 120.0
const HERO_ARCANE_STORM_RADIUS_LV4: float = 150.0
const HERO_ARCANE_STORM_DAMAGE_MULTIPLIER: float = 2.2
const HERO_ARCANE_STORM_DAMAGE_MULTIPLIER_LV4: float = 2.8
const HERO_ARCANE_STORM_MANA_RESTORE_MIN_HITS: int = 3
const HERO_ARCANE_STORM_MANA_RESTORE_LV4: float = 15.0
const HERO_BLOODSHADOW_DAMAGE_MULTIPLIER: float = 2.6
const HERO_BLOODSHADOW_DAMAGE_MULTIPLIER_LV4: float = 3.2
const HERO_BLOODSHADOW_LOW_HP_RATIO: float = 0.50
const HERO_BLOODSHADOW_LOW_HP_MULTIPLIER: float = 1.30
const HERO_BLOODSHADOW_KILL_MANA: float = 50.0
const HERO_BONE_GOLEM_HP_SCALING: float = 1.5
const HERO_BONE_GOLEM_ATK_SCALING: float = 0.8
const HERO_BONE_DRAGON_HP_SCALING: float = 0.8
const HERO_BONE_DRAGON_ATK_SCALING: float = 1.5
const HERO_BONE_SUMMON_DURATION: float = 15.0
const GOLEM_SMASH_DAMAGE_MULTIPLIER: float = 2.0
const GOLEM_SMASH_DAMAGE_MULTIPLIER_STAR_3: float = 2.6
const DRAGON_BARRAGE_DAMAGE_MULTIPLIER: float = 1.5
const DRAGON_BARRAGE_DAMAGE_MULTIPLIER_STAR_3: float = 2.0
const DRAGON_BARRAGE_RADIUS: float = 100.0
const DRAGON_BARRAGE_RADIUS_STAR_3: float = 130.0


const HERO_ARCANE_STORM_VISUAL_COLOR: Color = Color(0.42, 0.56, 1.0, 0.24)
const BINDING_RITE_MARK_META: String = "soul_binding_marked"
const BINDING_RITE_SOURCE_ID_META: String = "soul_binding_source_unit_id"
const BINDING_RITE_TEAM_ID_META: String = "soul_binding_team_id"
const BINDING_RITE_RATIO: float = 0.50
const BINDING_RITE_RATIO_STAR_3: float = 1.0
const BINDING_RITE_DURATION: float = 10.0
const BINDING_RITE_DURATION_STAR_3: float = 15.0
const ASTRAL_BULWARK_BASE_SHIELD: int = 80
const ASTRAL_BULWARK_BASE_SHIELD_STAR_3: int = 120
const ASTRAL_BULWARK_MAX_HP_RATIO: float = 0.20
const ASTRAL_BULWARK_MAX_HP_RATIO_STAR_3: float = 0.30
const ASTRAL_BULWARK_ALLY_RATIO: float = 0.20
const ASTRAL_BULWARK_ALLY_RATIO_STAR_3: float = 0.35
const ASTRAL_BULWARK_REDUCTION_STAR_3: float = 0.15
const ASTRAL_BULWARK_REDUCTION_DURATION_STAR_3: float = 5.0
const ARCANE_BARRAGE_RADIUS: float = 120.0
const ARCANE_BARRAGE_RADIUS_STAR_3: float = 145.0
const ARCANE_BARRAGE_DAMAGE_MULTIPLIER: float = 2.4
const ARCANE_BARRAGE_DAMAGE_MULTIPLIER_STAR_3: float = 3.6
const ARCANE_BARRAGE_MANA_PER_HIT: float = 2.0
const ARCANE_BARRAGE_MANA_STAR_3: float = 15.0
const FEAST_OF_VENOM_DAMAGE_RATIO: float = 0.30
const FEAST_OF_VENOM_DAMAGE_RATIO_STAR_3: float = 0.50
const FEAST_OF_VENOM_STACKS: int = 1
const FEAST_OF_VENOM_STACKS_STAR_3: int = 3
const VENOM_STACK_EFFECT: String = "venom_stack"
const VENOM_STACK_DURATION: float = 6.0
const VENOM_STACK_DAMAGE: float = 5.0
const BELL_OF_SANCTUARY_BASE_HEAL: int = 40
const BELL_OF_SANCTUARY_BASE_HEAL_STAR_3: int = 100
const BELL_OF_SANCTUARY_MAX_HP_RATIO: float = 0.15
const BELL_OF_SANCTUARY_MAX_HP_RATIO_STAR_3: float = 0.25
const BELL_OF_SANCTUARY_SHIELD: int = 30
const BELL_OF_SANCTUARY_SHIELD_STAR_3: int = 60
const BELL_OF_SANCTUARY_MANA_STAR_3: float = 30.0
const REAPING_COMMAND_DAMAGE_MULTIPLIER: float = 3.6
const REAPING_COMMAND_DAMAGE_MULTIPLIER_STAR_3: float = 5.0
const REAPING_COMMAND_MANA: float = 20.0
const REAPING_COMMAND_MANA_STAR_3: float = 35.0
const REAPING_COMMAND_CRIT_DAMAGE_BONUS: float = 0.50
const REAPING_COMMAND_CRIT_DAMAGE_BONUS_STAR_3: float = 1.0
const REAPING_COMMAND_CRIT_CHANCE_BONUS_STAR_3: float = 0.15
const REAPING_COMMAND_BUFF_DURATION: float = 5.0
const BLOOD_DEBT_HP_COST_RATIO: float = 0.10
const BLOOD_DEBT_HP_COST_RATIO_STAR_3: float = 0.08
const BLOOD_DEBT_DAMAGE_MULTIPLIER: float = 2.5
const BLOOD_DEBT_DAMAGE_MULTIPLIER_STAR_3: float = 3.2
const BLOOD_DEBT_HEAL_RATIO: float = 0.35
const BLOOD_DEBT_HEAL_RATIO_STAR_3: float = 0.70
const FOCUS_BEAM_DURATION: float = 5.0
const FOCUS_BEAM_DURATION_STAR_3: float = 7.0
const FOCUS_BEAM_SKILL_POWER: float = 0.50
const FOCUS_BEAM_SKILL_POWER_STAR_3: float = 0.80
const FOCUS_BEAM_CRIT_CHANCE: float = 0.10
const FOCUS_BEAM_CRIT_CHANCE_STAR_3: float = 0.20
const FOCUS_BEAM_MANA_STAR_3: float = 25.0
const ARCANE_BARRAGE_VISUAL_COLOR: Color = Color(0.48, 0.52, 1.0, 0.24)
const FEAST_OF_VENOM_VISUAL_COLOR: Color = Color(0.35, 0.95, 0.32, 0.22)

var status_effect_factory: Variant = StatusEffectFactory.new()
var passive_resolver: Variant = PassiveResolver.new()
var aoe_resolver: Variant = AoeResolver.new()


func setup(passive_resolver_value: Variant) -> void:
	if passive_resolver_value != null:
		passive_resolver = passive_resolver_value


func try_cast_active_skill(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	match unit.active_skill_id:
		SKILL_GUARD_BARRIER:
			return _cast_guard_barrier(unit)
		SKILL_PIERCING_ARROW:
			return _cast_piercing_arrow(unit)
		SKILL_SHADOW_STRIKE:
			return _cast_shadow_strike(unit)
		SKILL_STONE_GUARD:
			return _cast_stone_guard(unit)
		SKILL_FIREBALL:
			return _cast_fireball(unit)
		SKILL_HOLY_LIGHT:
			return _cast_holy_light(unit)
		SKILL_INSPIRING_SONG:
			return _cast_inspiring_song(unit)
		SKILL_REGROWTH:
			return _cast_regrowth(unit)
		SKILL_TOXIC_CLOUD:
			return _cast_toxic_cloud(unit)
		SKILL_IRON_ORDER:
			return _cast_iron_order(unit)
		SKILL_HASTE_SONG:
			return _cast_haste_song(unit)
		SKILL_SWEEPING_SLASH:
			return _cast_sweeping_slash(unit)
		SKILL_EXPLOSIVE_BARRAGE:
			return _cast_explosive_barrage(unit)
		SKILL_SANCTUARY:
			return _cast_sanctuary(unit)
		SKILL_ACID_FIELD:
			return _cast_acid_field(unit)
		SKILL_RAISE_SKELETONS:
			return _cast_raise_skeletons(unit)
		SKILL_PUPPET_MARK:
			return _cast_puppet_mark(unit)
		SKILL_SUMMONED_BONE_SLASH:
			return _cast_summoned_bone_slash(unit)
		SKILL_SUMMONED_PUPPET_GUARD:
			return _cast_summoned_puppet_guard(unit)
		SKILL_HERO_COMMANDING_ORDER:
			return _cast_hero_commanding_order(unit)
		SKILL_HERO_ARCANE_STORM:
			return _cast_hero_arcane_storm(unit)
		SKILL_HERO_BLOODSHADOW_ASSAULT:
			return _cast_hero_bloodshadow_assault(unit)
		SKILL_HERO_BONE_GOLEM:
			return _cast_hero_bone_golem(unit)
		SKILL_SUMMONED_GOLEM_SMASH:
			return _cast_summoned_golem_smash(unit)
		SKILL_SUMMONED_DRAGON_BARRAGE:
			return _cast_summoned_dragon_barrage(unit)
		SKILL_ENEMY_GUARD_STANCE:
			return _cast_enemy_guard_stance(unit)
		SKILL_ENEMY_HARDEN:
			return _cast_enemy_harden(unit)
		SKILL_ENEMY_FORTIFY_ALLIES:
			return _cast_enemy_fortify_allies(unit)
		SKILL_ENEMY_EARTHBREAKER_BARRIER:
			return _cast_enemy_earthbreaker_barrier(unit)
		SKILL_ENEMY_POWER_SHOT:
			return _cast_enemy_direct_damage(unit, ENEMY_POWER_SHOT_DAMAGE_MULTIPLIER, "Power Shot")
		SKILL_ENEMY_FIREBOLT:
			return _cast_enemy_direct_damage(unit, ENEMY_FIREBOLT_DAMAGE_MULTIPLIER, "Firebolt")
		SKILL_ENEMY_SHADOW_CLEAVE:
			return _cast_enemy_shadow_cleave(unit)
		SKILL_ENEMY_VOID_BEAM:
			return _cast_enemy_void_beam(unit)
		SKILL_ENEMY_DARK_HEAL:
			return _cast_enemy_dark_heal(unit)
		SKILL_ENEMY_DRUM_SHIELD:
			return _cast_enemy_drum_shield(unit)
		SKILL_ENEMY_ORACLE_BLESSING:
			return _cast_enemy_oracle_blessing(unit)
		SKILL_ENEMY_MASS_BENEDICTION:
			return _cast_enemy_mass_benediction(unit)
		SKILL_ENEMY_RAISE_SKELETONS:
			return _cast_enemy_raise_skeletons(unit)
		SKILL_ENEMY_PUPPET_MARK:
			return _cast_enemy_puppet_mark(unit)
		SKILL_BINDING_RITE:
			return _cast_binding_rite(unit)
		SKILL_ASTRAL_BULWARK:
			return _cast_astral_bulwark(unit)
		SKILL_ARCANE_BARRAGE:
			return _cast_arcane_barrage(unit)
		SKILL_FEAST_OF_VENOM:
			return _cast_feast_of_venom(unit)
		SKILL_BELL_OF_SANCTUARY:
			return _cast_bell_of_sanctuary(unit)
		SKILL_REAPING_COMMAND:
			return _cast_reaping_command(unit)
		SKILL_BLOOD_DEBT_SLASH:
			return _cast_blood_debt_slash(unit)
		SKILL_FOCUS_BEAM:
			return _cast_focus_beam(unit)
		SKILL_SEPTIC_SPIT:
			return _cast_septic_spit(unit)
		SKILL_PUTRID_TIDE:
			return _cast_putrid_tide(unit)
		_:
			return false


func _cast_guard_barrier(unit: Variant) -> bool:
	var base_shield: int = GUARD_BARRIER_BASE_SHIELD_STAR_3 if _is_star_3(unit) else GUARD_BARRIER_BASE_SHIELD
	var max_hp_ratio: float = GUARD_BARRIER_MAX_HP_RATIO_STAR_3 if _is_star_3(unit) else GUARD_BARRIER_MAX_HP_RATIO
	var self_shield: int = maxi(1, int(round(float(base_shield) + float(unit.max_hp) * max_hp_ratio)))
	self_shield = _scale_active_skill_shield(unit, self_shield)
	var ally_shield: int = maxi(1, int(round(float(self_shield) * GUARD_BARRIER_ALLY_RATIO)))
	var lowest_ally: Variant = _find_lowest_hp_ally(unit)

	unit.add_shield(self_shield, unit)
	if _is_valid_unit(lowest_ally) and lowest_ally.is_alive:
		lowest_ally.add_shield(ally_shield, unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Guard Barrier", unit))
	return true


func _cast_piercing_arrow(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var damage_multiplier: float = PIERCING_ARROW_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else PIERCING_ARROW_DAMAGE_MULTIPLIER
	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))
	target.take_damage(skill_damage, unit)
	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Piercing Arrow", unit))
	return true


func _cast_shadow_strike(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var damage_multiplier: float = SHADOW_STRIKE_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else SHADOW_STRIKE_DAMAGE_MULTIPLIER
	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))
	var kill_heal: int = SHADOW_STRIKE_KILL_HEAL_STAR_3 if _is_star_3(unit) else SHADOW_STRIKE_KILL_HEAL
	kill_heal = maxi(1, int(round(float(kill_heal) * _get_active_skill_heal_multiplier(unit))))
	var target_was_alive: bool = target.is_alive
	target.take_damage(skill_damage, unit)

	if target_was_alive and _is_valid_unit(unit) and unit.is_alive and (not target.is_alive):
		unit.heal(kill_heal, unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Shadow Strike", unit))
	return true


func _cast_stone_guard(unit: Variant) -> bool:
	var base_shield: int = STONE_GUARD_BASE_SHIELD_STAR_3 if _is_star_3(unit) else STONE_GUARD_BASE_SHIELD
	var max_hp_ratio: float = STONE_GUARD_MAX_HP_RATIO_STAR_3 if _is_star_3(unit) else STONE_GUARD_MAX_HP_RATIO
	var self_shield: int = maxi(1, int(round(float(base_shield) + float(unit.max_hp) * max_hp_ratio)))
	self_shield = _scale_active_skill_shield(unit, self_shield)
	unit.add_shield(self_shield, unit)
	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Stone Guard", unit))
	return true


func _cast_fireball(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var damage_multiplier: float = FIREBALL_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else FIREBALL_DAMAGE_MULTIPLIER
	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))
	target.take_damage(skill_damage, unit)
	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Fireball", unit))
	return true


func _cast_holy_light(unit: Variant) -> bool:
	var heal_target: Variant = _find_lowest_hp_ratio_damaged_ally(unit)
	if not _is_valid_unit(heal_target):
		heal_target = unit

	var base_heal: int = HOLY_LIGHT_BASE_HEAL_STAR_3 if _is_star_3(unit) else HOLY_LIGHT_BASE_HEAL
	var attack_ratio: float = HOLY_LIGHT_ATTACK_RATIO_STAR_3 if _is_star_3(unit) else HOLY_LIGHT_ATTACK_RATIO
	var raw_heal: int = maxi(1, int(round(float(base_heal) + float(unit.attack_damage) * attack_ratio)))
	var final_heal: int = maxi(1, int(round(float(raw_heal) * _get_active_skill_heal_multiplier(unit))))
	heal_target.heal(final_heal, unit)

	if _is_star_3(unit) and heal_target != unit and _is_valid_unit(unit) and unit.is_alive:
		var self_heal: int = maxi(1, int(round(float(final_heal) * HOLY_LIGHT_SELF_HEAL_RATIO_STAR_3)))
		unit.heal(self_heal, unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Holy Light", unit))
	return true


func _cast_inspiring_song(unit: Variant) -> bool:
	var base_shield: int = INSPIRING_SONG_BASE_SHIELD_STAR_3 if _is_star_3(unit) else INSPIRING_SONG_BASE_SHIELD
	var attack_ratio: float = INSPIRING_SONG_ATTACK_RATIO_STAR_3 if _is_star_3(unit) else INSPIRING_SONG_ATTACK_RATIO
	var shield_amount: int = maxi(1, int(round(float(base_shield) + float(unit.attack_damage) * attack_ratio)))
	shield_amount = _scale_active_skill_shield(unit, shield_amount)

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive:
			ally.add_shield(shield_amount, unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Inspiring Song", unit))
	return true


func _cast_regrowth(unit: Variant) -> bool:
	var duration: float = REGROWTH_DURATION
	var heal_base: float = REGROWTH_HEAL_BASE_STAR_3 if _is_star_3(unit) else REGROWTH_HEAL_BASE
	var attack_ratio: float = REGROWTH_ATTACK_RATIO_STAR_3 if _is_star_3(unit) else REGROWTH_ATTACK_RATIO
	var heal_amount: float = heal_base + float(unit.attack_damage) * attack_ratio
	heal_amount *= _get_active_skill_heal_multiplier(unit)
	var target_count: int = 2 if _is_star_3(unit) else 1
	var targets: Array = _find_lowest_hp_ratio_allies(unit, target_count, true)
	if targets.is_empty():
		targets.append(unit)

	for target: Variant in targets:
		if _is_valid_unit(target) and target.is_alive:
			_apply_status_effect(target, EFFECT_REGROWTH, StatusEffectFactory.EFFECT_TYPE_HEAL_OVER_TIME, unit, duration, STATUS_EFFECT_TICK_INTERVAL, heal_amount, "", {
				"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
				"polarity": StatusEffectFactory.POLARITY_POSITIVE,
				"category": StatusEffectFactory.CATEGORY_HOT,
			})

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Regrowth", unit))
	return true


func _cast_toxic_cloud(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var duration: float = TOXIC_CLOUD_DURATION_STAR_3 if _is_star_3(unit) else TOXIC_CLOUD_DURATION
	var damage_base: float = TOXIC_CLOUD_DAMAGE_BASE_STAR_3 if _is_star_3(unit) else TOXIC_CLOUD_DAMAGE_BASE
	var attack_ratio: float = TOXIC_CLOUD_ATTACK_RATIO_STAR_3 if _is_star_3(unit) else TOXIC_CLOUD_ATTACK_RATIO
	var damage_amount: float = damage_base + float(unit.attack_damage) * attack_ratio
	damage_amount *= _get_active_skill_damage_multiplier(unit)
	_apply_status_effect(target, EFFECT_TOXIC_CLOUD, StatusEffectFactory.EFFECT_TYPE_DAMAGE_OVER_TIME, unit, duration, STATUS_EFFECT_TICK_INTERVAL, damage_amount, "", {
		"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
		"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
		"category": StatusEffectFactory.CATEGORY_DOT,
	})
	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Toxic Cloud", unit))
	return true


func _cast_iron_order(unit: Variant) -> bool:
	var duration: float = IRON_ORDER_DURATION_STAR_3 if _is_star_3(unit) else IRON_ORDER_DURATION
	var defense_bonus: float = IRON_ORDER_DEFENSE_STAR_3 if _is_star_3(unit) else IRON_ORDER_DEFENSE
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		_apply_status_effect(ally, EFFECT_IRON_ORDER, StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, duration, 0.0, defense_bonus, "defense", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_STAT,
		})
		if _is_star_3(unit):
			ally.add_shield(_scale_active_skill_shield(unit, IRON_ORDER_SHIELD_STAR_3), unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Iron Order", unit))
	return true


func _cast_haste_song(unit: Variant) -> bool:
	var duration: float = HASTE_SONG_DURATION_STAR_3 if _is_star_3(unit) else HASTE_SONG_DURATION
	var attack_interval_multiplier: float = HASTE_SONG_ATTACK_INTERVAL_MULTIPLIER_STAR_3 if _is_star_3(unit) else HASTE_SONG_ATTACK_INTERVAL_MULTIPLIER
	var mana_multiplier: float = HASTE_SONG_MANA_REGEN_MULTIPLIER_STAR_3 if _is_star_3(unit) else HASTE_SONG_MANA_REGEN_MULTIPLIER
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		_apply_status_effect(ally, EFFECT_HASTE_SONG_ATTACK, StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, unit, duration, 0.0, attack_interval_multiplier, "attack_interval", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_STAT,
		})
		_apply_status_effect(ally, EFFECT_HASTE_SONG_MANA, StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, unit, duration, 0.0, mana_multiplier, "mana_regen_per_second", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_STAT,
		})

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Haste Song", unit))
	return true


func _cast_sweeping_slash(unit: Variant) -> bool:

	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var attack_range: float = maxf(1.0, float(unit.attack_range))
	var rect_length: float = attack_range * 2.0
	var rect_width: float = attack_range
	var damage_multiplier: float = SWEEPING_SLASH_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else SWEEPING_SLASH_DAMAGE_MULTIPLIER
	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))

	var direction: Vector2 = (target.global_position - unit.global_position).normalized()
	var shape_data: Dictionary = {
		"shape_type": "rect",
		"origin": unit.global_position,
		"direction": direction,
		"length": rect_length,
		"width": rect_width,
		"anchor": "forward",
	}
	var targets: Array = aoe_resolver.get_enemy_units_in_shape(unit, shape_data)
	var hit_count: int = aoe_resolver.deal_aoe_damage(unit, targets, skill_damage, true)

	# Always show visual for player feedback
	_create_aoe_shape_visual(unit, shape_data, INSTANT_AOE_VISUAL_DURATION, SWEEPING_SLASH_VISUAL_COLOR)
	DEBUG_LOG_SCRIPT.combat(unit.display_name + " sweeping slash: " + str(hit_count) + " targets hit for " + str(skill_damage) + " damage each")

	if hit_count <= 0:
		return false

	if _is_star_3(unit):
		unit.add_shield(_scale_active_skill_shield(unit, SWEEPING_SLASH_SHIELD_STAR_3), unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Sweeping Slash", unit))
	return true


func _cast_explosive_barrage(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var radius: float = EXPLOSIVE_BARRAGE_RADIUS_STAR_3 if _is_star_3(unit) else EXPLOSIVE_BARRAGE_RADIUS
	var damage_multiplier: float = EXPLOSIVE_BARRAGE_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else EXPLOSIVE_BARRAGE_DAMAGE_MULTIPLIER
	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))
	var targets: Array = aoe_resolver.get_enemy_units_in_radius(unit, target.global_position, radius)
	var hit_count: int = aoe_resolver.deal_aoe_damage(unit, targets, skill_damage, true)
	if hit_count <= 0:
		return false

	_create_visual_field(unit, target.global_position, radius, INSTANT_AOE_VISUAL_DURATION, EXPLOSIVE_BARRAGE_VISUAL_COLOR)
	if _is_star_3(unit) and hit_count >= EXPLOSIVE_BARRAGE_MANA_RESTORE_MIN_HITS:
		unit.set_meta("post_skill_mana_restore", EXPLOSIVE_BARRAGE_MANA_RESTORE_STAR_3)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Explosive Barrage", unit))
	return true


func _cast_sanctuary(unit: Variant) -> bool:
	var center_ally: Variant = _find_lowest_hp_ratio_ally(unit)
	if not _is_valid_unit(center_ally):
		return false

	var radius: float = SANCTUARY_RADIUS_STAR_3 if _is_star_3(unit) else SANCTUARY_RADIUS
	var base_heal: float = SANCTUARY_BASE_HEAL_STAR_3 if _is_star_3(unit) else SANCTUARY_BASE_HEAL
	var attack_ratio: float = SANCTUARY_ATTACK_RATIO_STAR_3 if _is_star_3(unit) else SANCTUARY_ATTACK_RATIO
	var raw_heal: int = maxi(1, int(round(base_heal + float(unit.attack_damage) * attack_ratio)))
	var final_heal: int = maxi(1, int(round(float(raw_heal) * _get_active_skill_heal_multiplier(unit))))
	var targets: Array = aoe_resolver.get_ally_units_in_radius(unit, center_ally.global_position, radius)
	if targets.is_empty():
		return false

	var tick_values: Array[int] = _split_total_into_ticks(final_heal, int(SANCTUARY_DURATION / SANCTUARY_TICK_INTERVAL))
	var field_id: int = _create_heal_field(
		unit,
		center_ally,
		center_ally.global_position,
		radius,
		SANCTUARY_DURATION,
		SANCTUARY_TICK_INTERVAL,
		tick_values,
		SANCTUARY_VISUAL_COLOR
	)
	if field_id < 0:
		return false

	if _is_star_3(unit):
		for target_value: Variant in targets:
			var target: Variant = target_value
			if _is_valid_unit(target) and target.is_alive:
				target.add_shield(_scale_active_skill_shield(unit, SANCTUARY_SHIELD_STAR_3), unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Sanctuary", unit))
	return true


func _cast_acid_field(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var radius: float = ACID_FIELD_RADIUS_STAR_3 if _is_star_3(unit) else ACID_FIELD_RADIUS
	var duration: float = ACID_FIELD_DURATION_STAR_3 if _is_star_3(unit) else ACID_FIELD_DURATION
	var damage_base: float = ACID_FIELD_DAMAGE_BASE_STAR_3 if _is_star_3(unit) else ACID_FIELD_DAMAGE_BASE
	var attack_ratio: float = ACID_FIELD_ATTACK_RATIO_STAR_3 if _is_star_3(unit) else ACID_FIELD_ATTACK_RATIO
	var damage_per_tick: int = maxi(1, int(round((damage_base + float(unit.attack_damage) * attack_ratio) * _get_active_skill_damage_multiplier(unit))))
	var field_id: int = _create_damage_field(unit, target.global_position, radius, duration, ACID_FIELD_TICK_INTERVAL, damage_per_tick)
	if field_id < 0:
		return false

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Acid Field", unit))
	return true


func _cast_raise_skeletons(unit: Variant) -> bool:
	var summon_count: int = 4 if _is_star_3(unit) else 2
	_summon_units(unit, SKELETON_SUMMON_DATA, summon_count, {})
	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Raise Skeletons", unit))
	return true


func _cast_puppet_mark(unit: Variant) -> bool:
	var target: Variant = _find_puppet_mark_target(unit)
	if not _is_valid_unit(target) or not target.is_alive:
		return false

	_mark_puppet_target(unit, target)
	_apply_puppet_mark_vulnerability(unit, target)
	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Puppet Mark", unit))
	return true


func _cast_summoned_bone_slash(unit: Variant) -> bool:
	var damage_multiplier: float = SUMMONED_BONE_SLASH_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else SUMMONED_BONE_SLASH_DAMAGE_MULTIPLIER
	if not _deal_skill_damage_to_current_target(unit, damage_multiplier):
		return false

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Bone Slash", unit))
	return true


func _cast_summoned_puppet_guard(unit: Variant) -> bool:
	var base_shield: int = SUMMONED_PUPPET_GUARD_BASE_SHIELD_STAR_3 if _is_star_3(unit) else SUMMONED_PUPPET_GUARD_BASE_SHIELD
	var hp_ratio: float = SUMMONED_PUPPET_GUARD_MAX_HP_RATIO_STAR_3 if _is_star_3(unit) else SUMMONED_PUPPET_GUARD_MAX_HP_RATIO
	var shield_amount: int = maxi(1, int(round(float(base_shield) + float(unit.max_hp) * hp_ratio)))
	unit.add_shield(_scale_active_skill_shield(unit, shield_amount), unit)
	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Puppet Guard", unit))
	return true


func _cast_hero_commanding_order(unit: Variant) -> bool:
	var hero_level: int = _get_hero_level(unit)
	var is_level_4: bool = hero_level >= 4
	var duration: float = HERO_COMMANDING_ORDER_DURATION_LV4 if is_level_4 else HERO_COMMANDING_ORDER_DURATION
	var shield_amount: int = 0
	var defense_bonus: float = 0.0
	if is_level_4:
		shield_amount = maxi(1, int(round(40.0 + 1.5 * float(unit.defense) + 0.2 * float(unit.max_hp))))
		defense_bonus = 35.0 + 0.2 * float(unit.defense)
	else:
		shield_amount = maxi(1, int(round(25.0 + float(unit.defense) + 0.1 * float(unit.max_hp))))
		defense_bonus = 20.0 + 0.1 * float(unit.defense)
	shield_amount = _scale_active_skill_shield(unit, shield_amount)

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		ally.add_shield(shield_amount, unit)
		if _is_frontline_ally(unit, ally) or (_hero_has_upgrade(unit, "iron_wall_spread") and _is_midline_ally(unit, ally)):
			_apply_status_effect(ally, "hero_commanding_order_defense", StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, duration, 0.0, defense_bonus, "defense", {
				"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
				"polarity": StatusEffectFactory.POLARITY_POSITIVE,
				"category": StatusEffectFactory.CATEGORY_STAT,
			})
			if _hero_has_upgrade(unit, "iron_hold_horn"):
				var missing_hp: int = maxi(0, int(ally.max_hp) - int(ally.hp))
				var heal_amount: int = maxi(0, int(round(float(missing_hp) * 0.10)))
				heal_amount = maxi(0, int(round(float(heal_amount) * _get_active_skill_heal_multiplier(unit))))
				if heal_amount > 0:
					ally.heal(heal_amount, unit)

	unit.unit_feedback.play_skill_feedback(unit, "Commanding Order")
	return true


func _cast_hero_arcane_storm(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		target = _find_nearest_enemy(unit)
	if not _is_valid_unit(target) or not target.is_alive:
		return false

	var is_level_4: bool = _get_hero_level(unit) >= 4
	var radius: float = HERO_ARCANE_STORM_RADIUS_LV4 if is_level_4 else HERO_ARCANE_STORM_RADIUS
	var damage_multiplier: float = HERO_ARCANE_STORM_DAMAGE_MULTIPLIER_LV4 if is_level_4 else HERO_ARCANE_STORM_DAMAGE_MULTIPLIER
	var targets: Array = aoe_resolver.get_enemy_units_in_radius(unit, target.global_position, radius)
	if targets.is_empty():
		return false

	if _hero_has_upgrade(unit, "arcane_shattering_storm"):
		var extra_hit_count: int = maxi(0, targets.size() - 1)
		var bonus: float = minf(float(extra_hit_count) * 0.05, 0.25)
		damage_multiplier *= 1.0 + bonus

	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))
	var hit_count: int = aoe_resolver.deal_aoe_damage(unit, targets, skill_damage, true)
	if hit_count <= 0:
		return false

	_create_visual_field(unit, target.global_position, radius, INSTANT_AOE_VISUAL_DURATION, HERO_ARCANE_STORM_VISUAL_COLOR)
	if is_level_4 and hit_count >= HERO_ARCANE_STORM_MANA_RESTORE_MIN_HITS:
		for ally_value: Variant in unit.ally_units:
			var ally: Variant = ally_value
			if _is_valid_unit(ally) and ally.is_alive:
				ally.restore_mana(HERO_ARCANE_STORM_MANA_RESTORE_LV4, unit)

	unit.unit_feedback.play_skill_feedback(unit, "Arcane Storm")
	return true


func _cast_hero_bloodshadow_assault(unit: Variant) -> bool:
	var target: Variant = _find_lowest_hp_ratio_enemy(unit)
	if not _is_valid_unit(target):
		return false

	var is_level_4: bool = _get_hero_level(unit) >= 4
	var damage_multiplier: float = HERO_BLOODSHADOW_DAMAGE_MULTIPLIER_LV4 if is_level_4 else HERO_BLOODSHADOW_DAMAGE_MULTIPLIER
	if target.max_hp > 0 and float(target.hp) / float(target.max_hp) < HERO_BLOODSHADOW_LOW_HP_RATIO:
		damage_multiplier *= HERO_BLOODSHADOW_LOW_HP_MULTIPLIER

	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))
	var target_position: Vector2 = target.global_position
	var target_was_alive: bool = target.is_alive
	target.take_damage(skill_damage, unit)
	var did_kill: bool = target_was_alive and _is_valid_unit(unit) and unit.is_alive and (not target.is_alive)
	if did_kill:
		unit.set_meta("post_skill_mana_restore", HERO_BLOODSHADOW_KILL_MANA)
		if _hero_has_upgrade(unit, "blood_shadow_chain"):
			_cast_bloodshadow_chain_assault(unit, target_position, skill_damage)

	unit.unit_feedback.play_skill_feedback(unit, "Bloodshadow Assault")
	return true

func _cast_hero_bone_golem(unit: Variant) -> bool:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return false

	var hero_atk: int = maxi(1, unit.attack_damage)
	var golem_bonus_hp: int = int(round(float(hero_atk) * HERO_BONE_GOLEM_HP_SCALING))
	var golem_bonus_atk: int = int(round(float(hero_atk) * HERO_BONE_GOLEM_ATK_SCALING))
	var golem_context: Dictionary = {
		"source_key": "bone_golem",
		"summon_cap": 1,
		"duration": HERO_BONE_SUMMON_DURATION,
		"bonus_max_hp": golem_bonus_hp,
		"bonus_attack_damage": golem_bonus_atk,
	}
	_summon_units(unit, BONE_GOLEM_SUMMON_DATA, 1, golem_context)

	var is_level_4: bool = _get_hero_level(unit) >= 4
	if is_level_4 and _hero_has_upgrade(unit, "bone_dragon"):
		var dragon_bonus_hp: int = int(round(float(hero_atk) * HERO_BONE_DRAGON_HP_SCALING))
		var dragon_bonus_atk: int = int(round(float(hero_atk) * HERO_BONE_DRAGON_ATK_SCALING))
		var dragon_context: Dictionary = {
			"source_key": "bone_dragon",
			"summon_cap": 1,
			"duration": HERO_BONE_SUMMON_DURATION,
			"bonus_max_hp": dragon_bonus_hp,
			"bonus_attack_damage": dragon_bonus_atk,
		}
		_summon_units(unit, BONE_DRAGON_SUMMON_DATA, 1, dragon_context)

	unit.unit_feedback.play_skill_feedback(unit, "骨巨人召唤")
	return true


func _cast_summoned_golem_smash(unit: Variant) -> bool:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return false

	var target: Variant = unit.current_target
	if not _is_valid_unit(target) or not target.is_alive:
		return false

	var smash_mult: float = GOLEM_SMASH_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else GOLEM_SMASH_DAMAGE_MULTIPLIER
	var damage: int = maxi(1, int(round(float(unit.attack_damage) * smash_mult)))
	target.take_damage(damage, unit)
	unit.unit_feedback.play_skill_feedback(unit, "巨人重击")
	return true


func _cast_summoned_dragon_barrage(unit: Variant) -> bool:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return false

	var target: Variant = unit.current_target
	if not _is_valid_unit(target) or not target.is_alive:
		return false

	var radius: float = DRAGON_BARRAGE_RADIUS_STAR_3 if _is_star_3(unit) else DRAGON_BARRAGE_RADIUS
	var barrage_mult: float = DRAGON_BARRAGE_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else DRAGON_BARRAGE_DAMAGE_MULTIPLIER
	var enemies: Array[Variant] = aoe_resolver.get_enemy_units_in_radius(unit, target.global_position, radius)
	var damage: int = maxi(1, int(round(float(unit.attack_damage) * barrage_mult)))

	for enemy_value: Variant in enemies:
		var enemy: Variant = enemy_value
		if _is_valid_unit(enemy) and enemy.is_alive:
			enemy.take_damage(damage, unit)

	unit.unit_feedback.play_skill_feedback(unit, "龙息弹幕")
	return true


func _cast_bloodshadow_chain_assault(unit: Variant, origin_position: Vector2, original_damage: int) -> void:
	var target: Variant = _find_nearest_enemy_to_position(unit, origin_position)
	if not _is_valid_unit(target):
		return
	
		var chain_damage: int = maxi(1, int(round(float(original_damage) * 0.60)))
		target.take_damage(chain_damage, unit)


func _cast_enemy_guard_stance(unit: Variant) -> bool:
	var shield_amount: int = maxi(1, int(round(float(ENEMY_GUARD_STANCE_BASE_SHIELD) + float(unit.max_hp) * ENEMY_GUARD_STANCE_MAX_HP_RATIO)))
	shield_amount = _scale_active_skill_shield(unit, shield_amount)
	unit.add_shield(shield_amount, unit)
	unit.unit_feedback.play_skill_feedback(unit, "Guard Stance")
	return true


func _cast_enemy_harden(unit: Variant) -> bool:
	unit.add_shield(_scale_active_skill_shield(unit, ENEMY_HARDEN_SHIELD), unit)
	unit.unit_feedback.play_skill_feedback(unit, "Harden")
	return true


func _cast_enemy_fortify_allies(unit: Variant) -> bool:
	unit.add_shield(_scale_active_skill_shield(unit, ENEMY_FORTIFY_SELF_SHIELD), unit)
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive:
			ally.add_shield(_scale_active_skill_shield(unit, ENEMY_FORTIFY_ALLY_SHIELD), unit)

	unit.unit_feedback.play_skill_feedback(unit, "Fortify Allies")
	return true


func _cast_enemy_earthbreaker_barrier(unit: Variant) -> bool:
	var shield_amount: int = maxi(1, int(round(float(ENEMY_EARTHBREAKER_BASE_SHIELD) + float(unit.max_hp) * ENEMY_EARTHBREAKER_MAX_HP_RATIO)))
	shield_amount = _scale_active_skill_shield(unit, shield_amount)
	unit.add_shield(shield_amount, unit)
	var did_damage: bool = _deal_skill_damage_to_current_target(unit, ENEMY_EARTHBREAKER_DAMAGE_MULTIPLIER)
	unit.unit_feedback.play_skill_feedback(unit, "Earthbreaker Barrier")
	return did_damage or shield_amount > 0


func _cast_enemy_direct_damage(unit: Variant, damage_multiplier: float, feedback_name: String) -> bool:
	if not _deal_skill_damage_to_current_target(unit, damage_multiplier):
		return false

	unit.unit_feedback.play_skill_feedback(unit, feedback_name)
	return true


func _cast_enemy_shadow_cleave(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var target_was_alive: bool = target.is_alive
	var did_damage: bool = _deal_skill_damage_to_current_target(unit, ENEMY_SHADOW_CLEAVE_DAMAGE_MULTIPLIER)
	if target_was_alive and _is_valid_unit(unit) and unit.is_alive and (not target.is_alive):
		var kill_heal: int = maxi(1, int(round(float(ENEMY_SHADOW_CLEAVE_KILL_HEAL) * _get_active_skill_heal_multiplier(unit))))
		unit.heal(kill_heal, unit)

	unit.unit_feedback.play_skill_feedback(unit, "Shadow Cleave")
	return did_damage


func _cast_enemy_void_beam(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var damage_multiplier: float = ENEMY_VOID_BEAM_DAMAGE_MULTIPLIER
	if target.max_hp > 0:
		var hp_ratio: float = float(target.hp) / float(target.max_hp)
		if hp_ratio < ENEMY_VOID_BEAM_LOW_HP_RATIO:
			damage_multiplier *= ENEMY_VOID_BEAM_LOW_HP_MULTIPLIER

	var did_damage: bool = _deal_skill_damage_to_current_target(unit, damage_multiplier)
	unit.unit_feedback.play_skill_feedback(unit, "Void Beam")
	return did_damage


func _cast_enemy_dark_heal(unit: Variant) -> bool:
	var heal_target: Variant = _find_lowest_hp_ratio_ally(unit)
	if not _is_valid_unit(heal_target):
		return false

	var raw_heal: int = maxi(1, int(round(float(ENEMY_DARK_HEAL_BASE) + float(unit.attack_damage) * ENEMY_DARK_HEAL_ATTACK_RATIO)))
	var final_heal: int = maxi(1, int(round(float(raw_heal) * _get_active_skill_heal_multiplier(unit))))
	heal_target.heal(final_heal, unit)
	unit.unit_feedback.play_skill_feedback(unit, "Dark Heal")
	return true


func _cast_enemy_drum_shield(unit: Variant) -> bool:
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive:
			ally.add_shield(_scale_active_skill_shield(unit, ENEMY_DRUM_SHIELD_AMOUNT), unit)

	unit.unit_feedback.play_skill_feedback(unit, "Drum Shield")
	return true


func _cast_enemy_oracle_blessing(unit: Variant) -> bool:
	var target: Variant = _find_lowest_hp_ratio_ally(unit)
	if not _is_valid_unit(target):
		return false

	var raw_heal: int = maxi(1, int(round(float(ENEMY_ORACLE_HEAL_BASE) + float(unit.attack_damage) * ENEMY_ORACLE_HEAL_ATTACK_RATIO)))
	var final_heal: int = maxi(1, int(round(float(raw_heal) * _get_active_skill_heal_multiplier(unit))))
	target.heal(final_heal, unit)
	target.add_shield(_scale_active_skill_shield(unit, ENEMY_ORACLE_SHIELD), unit)
	unit.unit_feedback.play_skill_feedback(unit, "Oracle Blessing")
	return true


func _cast_enemy_mass_benediction(unit: Variant) -> bool:
	var raw_heal_amount: int = maxi(1, int(round(float(ENEMY_MASS_BENEDICTION_HEAL_BASE) + float(unit.attack_damage) * ENEMY_MASS_BENEDICTION_ATTACK_RATIO)))
	var heal_amount: int = maxi(1, int(round(float(raw_heal_amount) * _get_active_skill_heal_multiplier(unit))))
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive:
			ally.heal(heal_amount, unit)

	var shield_target: Variant = _find_lowest_hp_ratio_ally(unit)
	if _is_valid_unit(shield_target):
		shield_target.add_shield(_scale_active_skill_shield(unit, ENEMY_MASS_BENEDICTION_SHIELD), unit)

	unit.unit_feedback.play_skill_feedback(unit, "Mass Benediction")
	return true


func _cast_enemy_raise_skeletons(unit: Variant) -> bool:
	_summon_units(unit, SKELETON_SUMMON_DATA, 2, {})
	unit.unit_feedback.play_skill_feedback(unit, "Raise Skeletons")
	return true


func _cast_enemy_puppet_mark(unit: Variant) -> bool:
	var target: Variant = _find_puppet_mark_target(unit)
	if not _is_valid_unit(target) or not target.is_alive:
		return false

	_mark_puppet_target(unit, target)
	_apply_puppet_mark_vulnerability(unit, target)
	unit.unit_feedback.play_skill_feedback(unit, "Puppet Mark")
	return true


func _cast_binding_rite(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		target = _find_lowest_hp_ratio_enemy(unit)
	if not _is_valid_unit(target) or not target.is_alive:
		return false

	target.set_meta(BINDING_RITE_MARK_META, true)
	target.set_meta(BINDING_RITE_SOURCE_ID_META, int(unit.unit_id))
	target.set_meta(BINDING_RITE_TEAM_ID_META, int(unit.team_id))
	var duration: float = BINDING_RITE_DURATION_STAR_3 if _is_star_3(unit) else BINDING_RITE_DURATION
	target.set_meta("soul_binding_expires_at", float(target.battle_elapsed_time) + duration)
	_apply_status_effect(target, "binding_rite_mark", StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, unit, duration, 0.0, 1.0, "damage_taken_multiplier", {
		"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
		"polarity": StatusEffectFactory.POLARITY_NEUTRAL,
		"category": StatusEffectFactory.CATEGORY_MARK,
	})
	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Binding Rite", unit))
	return true


func _cast_astral_bulwark(unit: Variant) -> bool:
	var base_shield: int = ASTRAL_BULWARK_BASE_SHIELD_STAR_3 if _is_star_3(unit) else ASTRAL_BULWARK_BASE_SHIELD
	var hp_ratio: float = ASTRAL_BULWARK_MAX_HP_RATIO_STAR_3 if _is_star_3(unit) else ASTRAL_BULWARK_MAX_HP_RATIO
	var self_shield: int = maxi(1, int(round(float(base_shield) + float(unit.max_hp) * hp_ratio)))
	self_shield = _scale_active_skill_shield(unit, self_shield)
	unit.add_shield(self_shield, unit)

	if _is_star_3(unit) or _has_star_3_ally(unit):
		var ally_ratio: float = ASTRAL_BULWARK_ALLY_RATIO_STAR_3 if _is_star_3(unit) else ASTRAL_BULWARK_ALLY_RATIO
		var ally_shield: int = maxi(1, int(round(float(self_shield) * ally_ratio)))
		for ally_value: Variant in unit.ally_units:
			var ally: Variant = ally_value
			if not _is_valid_unit(ally) or not ally.is_alive:
				continue
			ally.add_shield(ally_shield, unit)
			if _is_star_3(unit) and int(ally.star) >= 3:
				_apply_status_effect(ally, "astral_bulwark_damage_reduction", StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, ASTRAL_BULWARK_REDUCTION_DURATION_STAR_3, 0.0, ASTRAL_BULWARK_REDUCTION_STAR_3, "damage_reduction", {
					"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
					"polarity": StatusEffectFactory.POLARITY_POSITIVE,
					"category": StatusEffectFactory.CATEGORY_STAT,
				})

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Astral Bulwark", unit))
	return true


func _cast_arcane_barrage(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		target = _find_lowest_hp_ratio_enemy(unit)
	if not _is_valid_unit(target) or not target.is_alive:
		return false

	var radius: float = ARCANE_BARRAGE_RADIUS_STAR_3 if _is_star_3(unit) else ARCANE_BARRAGE_RADIUS
	var damage_multiplier: float = ARCANE_BARRAGE_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else ARCANE_BARRAGE_DAMAGE_MULTIPLIER
	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))
	var targets: Array = aoe_resolver.get_enemy_units_in_radius(unit, target.global_position, radius)
	var hit_count: int = aoe_resolver.deal_aoe_damage(unit, targets, skill_damage, true)
	if hit_count <= 0:
		return false

	_create_visual_field(unit, target.global_position, radius, INSTANT_AOE_VISUAL_DURATION, ARCANE_BARRAGE_VISUAL_COLOR)
	var mana_restore: float = float(hit_count) * ARCANE_BARRAGE_MANA_PER_HIT
	if _is_star_3(unit) and hit_count >= 3:
		mana_restore = ARCANE_BARRAGE_MANA_STAR_3
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive:
			ally.restore_mana(mana_restore, unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Arcane Barrage", unit))
	return true


func _cast_feast_of_venom(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		target = _find_lowest_hp_ratio_enemy(unit)
	if not _is_valid_unit(target) or not target.is_alive:
		return false

	var stacks_to_apply: int = FEAST_OF_VENOM_STACKS_STAR_3 if _is_star_3(unit) else FEAST_OF_VENOM_STACKS
	for enemy_value: Variant in unit.enemy_units:
		var enemy: Variant = enemy_value
		if _is_valid_unit(enemy) and enemy.is_alive:
			_apply_venom_stacks(unit, enemy, stacks_to_apply)

	if _is_star_3(unit):
		var current_stacks: int = _get_venom_stack_count(target)
		if current_stacks > 0:
			_apply_venom_stacks(unit, target, current_stacks)

	var venom_stacks: int = _get_venom_stack_count(target)
	var ratio: float = FEAST_OF_VENOM_DAMAGE_RATIO_STAR_3 if _is_star_3(unit) else FEAST_OF_VENOM_DAMAGE_RATIO
	var damage_multiplier: float = _get_active_skill_damage_multiplier(unit)
	var burst_damage: int = maxi(1, int(round(float(venom_stacks) * float(unit.attack_damage) * ratio * damage_multiplier)))
	target.take_damage(burst_damage, unit, false)
	_create_visual_field(unit, target.global_position, 120.0, INSTANT_AOE_VISUAL_DURATION, FEAST_OF_VENOM_VISUAL_COLOR)
	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Feast of Venom", unit))
	return true


func _cast_bell_of_sanctuary(unit: Variant) -> bool:
	var base_heal: int = BELL_OF_SANCTUARY_BASE_HEAL_STAR_3 if _is_star_3(unit) else BELL_OF_SANCTUARY_BASE_HEAL
	var hp_ratio: float = BELL_OF_SANCTUARY_MAX_HP_RATIO_STAR_3 if _is_star_3(unit) else BELL_OF_SANCTUARY_MAX_HP_RATIO
	var shield_amount: int = BELL_OF_SANCTUARY_SHIELD_STAR_3 if _is_star_3(unit) else BELL_OF_SANCTUARY_SHIELD
	shield_amount = _scale_active_skill_shield(unit, shield_amount)
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue
		var heal_amount: int = maxi(1, int(round(float(base_heal) + float(ally.max_hp) * hp_ratio)))
		heal_amount = maxi(1, int(round(float(heal_amount) * _get_active_skill_heal_multiplier(unit))))
		ally.heal(heal_amount, unit)
		ally.add_shield(shield_amount, unit)
		if _is_star_3(unit):
			ally.restore_mana(BELL_OF_SANCTUARY_MANA_STAR_3, unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Bell of Sanctuary", unit))
	return true


func _cast_reaping_command(unit: Variant) -> bool:
	var target: Variant = _find_lowest_hp_ratio_enemy(unit)
	if not _is_valid_unit(target):
		return false

	var damage_multiplier: float = REAPING_COMMAND_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else REAPING_COMMAND_DAMAGE_MULTIPLIER
	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))
	var was_alive: bool = target.is_alive
	target.take_damage(skill_damage, unit)
	var did_kill: bool = was_alive and _is_valid_unit(unit) and unit.is_alive and not target.is_alive
	if did_kill:
		_apply_reaping_command_buffs(unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Reaping Command", unit))
	return true


func _cast_blood_debt_slash(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var cost_ratio: float = BLOOD_DEBT_HP_COST_RATIO_STAR_3 if _is_star_3(unit) else BLOOD_DEBT_HP_COST_RATIO
	var hp_cost: int = mini(maxi(0, int(round(float(unit.hp) * cost_ratio))), maxi(0, int(unit.hp) - 1))
	if hp_cost > 0:
		unit.hp = maxi(1, int(unit.hp) - hp_cost)
		unit._update_hp_bar()
		unit.update_info_display()

	var damage_multiplier: float = BLOOD_DEBT_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else BLOOD_DEBT_DAMAGE_MULTIPLIER
	if passive_resolver != null and passive_resolver.has_method("get_bloodbound_rage_attack_multiplier"):
		damage_multiplier *= float(passive_resolver.get_bloodbound_rage_attack_multiplier(unit))
	damage_multiplier *= _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_multiplier)))
	var actual_damage: int = int(target.take_damage(skill_damage, unit))
	var heal_ratio: float = BLOOD_DEBT_HEAL_RATIO_STAR_3 if _is_star_3(unit) else BLOOD_DEBT_HEAL_RATIO
	if actual_damage > 0:
		var heal_amount: int = maxi(1, int(round(float(actual_damage) * heal_ratio)))
		unit.heal(heal_amount, unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Blood Debt Slash", unit))
	return true


func _cast_focus_beam(unit: Variant) -> bool:
	var target: Variant = _find_highest_skill_power_ally(unit)
	if not _is_valid_unit(target):
		return false

	var duration: float = FOCUS_BEAM_DURATION_STAR_3 if _is_star_3(unit) else FOCUS_BEAM_DURATION
	var skill_power_bonus: float = FOCUS_BEAM_SKILL_POWER_STAR_3 if _is_star_3(unit) else FOCUS_BEAM_SKILL_POWER
	var crit_bonus: float = FOCUS_BEAM_CRIT_CHANCE_STAR_3 if _is_star_3(unit) else FOCUS_BEAM_CRIT_CHANCE
	_apply_status_effect(target, "focus_beam_skill_power", StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, duration, 0.0, skill_power_bonus, "skill_power", {
		"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
		"polarity": StatusEffectFactory.POLARITY_POSITIVE,
		"category": StatusEffectFactory.CATEGORY_STAT,
	})
	_apply_status_effect(target, "focus_beam_crit", StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, duration, 0.0, crit_bonus, "crit_chance", {
		"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
		"polarity": StatusEffectFactory.POLARITY_POSITIVE,
		"category": StatusEffectFactory.CATEGORY_STAT,
	})
	if _is_star_3(unit):
		target.restore_mana(FOCUS_BEAM_MANA_STAR_3, unit)

	unit.unit_feedback.play_skill_feedback(unit, _get_skill_feedback_name("Focus Beam", unit))
	return true


func _deal_skill_damage_to_current_target(unit: Variant, damage_multiplier: float) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var final_multiplier: float = damage_multiplier * _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * final_multiplier)))
	target.take_damage(skill_damage, unit)
	return true


func _create_damage_field(
	unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	damage_per_tick: int
) -> int:
	if not _is_valid_unit(unit):
		return -1

	var battle_root: Node = unit.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return -1

	if not battle_root.has_method("create_damage_field"):
		return -1

	return int(battle_root.create_damage_field(unit, center_position, radius, duration, tick_interval, damage_per_tick))


func _create_visual_field(unit: Variant, center_position: Vector2, radius: float, duration: float, color: Color) -> int:
	if not _is_valid_unit(unit):
		return -1

	var battle_root: Node = unit.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return -1

	if not battle_root.has_method("create_visual_field"):
		return -1

	return int(battle_root.create_visual_field(center_position, radius, duration, color))


func _create_aoe_shape_visual(unit: Variant, shape_data: Dictionary, duration: float, color: Color) -> void:
	if not _is_valid_unit(unit):
		return
	var battle_root: Node = unit.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return
	if not battle_root.has_method("create_aoe_shape_visual"):
		return
	battle_root.create_aoe_shape_visual(shape_data, color, duration)



func _create_heal_field(
	unit: Variant,
	follow_unit: Variant,
	center_position: Vector2,
	radius: float,
	duration: float,
	tick_interval: float,
	heal_tick_values: Array[int],
	color: Color
) -> int:
	if not _is_valid_unit(unit):
		return -1

	var battle_root: Node = unit.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return -1

	if not battle_root.has_method("create_heal_field"):
		return -1

	return int(battle_root.create_heal_field(unit, follow_unit, center_position, radius, duration, tick_interval, heal_tick_values, color))


func _summon_units(unit: Variant, summon_unit_data: Resource, count: int, context: Dictionary = {}) -> Array[Unit]:
	var empty_units: Array[Unit] = []
	if not _is_valid_unit(unit) or summon_unit_data == null or count <= 0:
		return empty_units

	var battle_root: Node = unit.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return empty_units
	if not battle_root.has_method("summon_units"):
		return empty_units

	return battle_root.summon_units(unit, summon_unit_data, count, context)


func _mark_puppet_target(unit: Variant, target: Variant) -> bool:
	if not _is_valid_unit(unit) or not _is_valid_unit(target):
		return false

	var battle_root: Node = unit.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return false
	if not battle_root.has_method("mark_puppet_summon_target"):
		return false

	return bool(battle_root.mark_puppet_summon_target(unit, target))


func _apply_puppet_mark_vulnerability(unit: Variant, target: Variant) -> void:
	if not _is_valid_unit(unit) or not _is_valid_unit(target):
		return

	var duration: float = PUPPET_MARK_VULNERABILITY_DURATION_STAR_3 if _is_star_3(unit) else PUPPET_MARK_VULNERABILITY_DURATION
	var multiplier: float = PUPPET_MARK_VULNERABILITY_MULTIPLIER_STAR_3 if _is_star_3(unit) else PUPPET_MARK_VULNERABILITY_MULTIPLIER
	_apply_status_effect(
		target,
		EFFECT_PUPPET_MARK_VULNERABILITY,
		StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY,
		unit,
		duration,
		0.0,
		multiplier,
		"damage_taken_multiplier",
		{
			"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
			"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
			"category": StatusEffectFactory.CATEGORY_MARK,
		}
	)


func _apply_status_effect(
	target: Variant,
	effect_id: String,
	effect_type: String,
	source: Variant,
	duration: float,
	tick_interval: float,
	value: float,
	stat_name: String,
	options: Dictionary = {}
) -> void:
	status_effect_factory.apply_status_effect(
		target,
		effect_id,
		effect_type,
		source,
		duration,
		tick_interval,
		value,
		stat_name,
		options
	)


func _apply_status_effect_with_tick_values(
	target: Variant,
	effect_id: String,
	effect_type: String,
	source: Variant,
	duration: float,
	tick_interval: float,
	tick_values: Array[int],
	stat_name: String,
	options: Dictionary = {}
) -> void:
	if not status_effect_factory.has_method("apply_status_effect_with_tick_values"):
		return

	status_effect_factory.apply_status_effect_with_tick_values(
		target,
		effect_id,
		effect_type,
		source,
		duration,
		tick_interval,
		tick_values,
		stat_name,
		options
	)


func _find_lowest_hp_ratio_ally(unit: Variant) -> Variant:
	var lowest_ally: Variant = null
	var lowest_hp_ratio: float = 0.0

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally):
			continue

		if not ally.is_alive or ally.max_hp <= 0:
			continue

		var hp_ratio: float = float(ally.hp) / float(ally.max_hp)
		if lowest_ally == null or hp_ratio < lowest_hp_ratio:
			lowest_ally = ally
			lowest_hp_ratio = hp_ratio

	return lowest_ally


func _find_lowest_hp_ally(unit: Variant) -> Variant:
	var lowest_ally: Variant = null
	var lowest_hp: int = 0

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally):
			continue

		if ally == unit or not ally.is_alive:
			continue

		if lowest_ally == null or ally.hp < lowest_hp:
			lowest_ally = ally
			lowest_hp = ally.hp

	return lowest_ally


func _find_lowest_hp_ratio_damaged_ally(unit: Variant) -> Variant:
	var lowest_ally: Variant = null
	var lowest_hp_ratio: float = 1.0

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally):
			continue

		if not ally.is_alive or ally.max_hp <= 0 or ally.hp >= ally.max_hp:
			continue

		var hp_ratio: float = float(ally.hp) / float(ally.max_hp)
		if lowest_ally == null or hp_ratio < lowest_hp_ratio:
			lowest_ally = ally
			lowest_hp_ratio = hp_ratio

	return lowest_ally


func _find_lowest_hp_ratio_allies(unit: Variant, count: int, damaged_only: bool) -> Array:
	var selected_allies: Array = []
	var safe_count: int = maxi(0, count)
	if safe_count <= 0:
		return selected_allies

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive or ally.max_hp <= 0:
			continue

		if damaged_only and ally.hp >= ally.max_hp:
			continue

		_insert_ally_by_low_hp_ratio(selected_allies, ally, safe_count)

	return selected_allies


func _insert_ally_by_low_hp_ratio(selected_allies: Array, ally: Variant, max_count: int) -> void:
	var ally_ratio: float = float(ally.hp) / float(ally.max_hp)
	var insert_index: int = selected_allies.size()
	for index: int in range(selected_allies.size()):
		var existing_ally: Variant = selected_allies[index]
		if not _is_valid_unit(existing_ally) or existing_ally.max_hp <= 0:
			insert_index = index
			break

		var existing_ratio: float = float(existing_ally.hp) / float(existing_ally.max_hp)
		if ally_ratio < existing_ratio:
			insert_index = index
			break

		if is_equal_approx(ally_ratio, existing_ratio) and int(ally.unit_id) < int(existing_ally.unit_id):
			insert_index = index
			break

	selected_allies.insert(insert_index, ally)
	while selected_allies.size() > max_count:
		selected_allies.remove_at(selected_allies.size() - 1)


func _get_active_skill_damage_multiplier(unit: Variant) -> float:
	return passive_resolver.get_active_skill_damage_multiplier(unit)


func _get_active_skill_heal_multiplier(unit: Variant) -> float:
	if passive_resolver != null and passive_resolver.has_method("get_active_skill_heal_multiplier"):
		return float(passive_resolver.get_active_skill_heal_multiplier(unit))

	var skill_power: float = maxf(0.0, float(unit.skill_power)) if _is_valid_unit(unit) else 0.0
	return _get_outgoing_heal_multiplier(unit) * (1.0 + skill_power)


func _get_outgoing_heal_multiplier(unit: Variant) -> float:
	return passive_resolver.get_outgoing_heal_multiplier(unit)


func _get_active_skill_shield_multiplier(unit: Variant) -> float:
	if not _is_valid_unit(unit):
		return 1.0

	return 1.0 + maxf(0.0, float(unit.skill_power))


func _scale_active_skill_shield(unit: Variant, amount: int) -> int:
	return maxi(1, int(round(float(amount) * _get_active_skill_shield_multiplier(unit))))


func _split_total_into_ticks(total_value: int, tick_count: int) -> Array[int]:
	var values: Array[int] = []
	var safe_tick_count: int = maxi(1, tick_count)
	var safe_total: int = maxi(0, total_value)
	var base_value: int = int(safe_total / safe_tick_count)
	var remainder: int = safe_total % safe_tick_count
	for index: int in range(safe_tick_count):
		values.append(base_value + (1 if index < remainder else 0))

	return values


func _find_nearest_enemy(unit: Variant) -> Variant:
	if not _is_valid_unit(unit):
		return null

	var best_target: Variant = null
	var best_distance: float = INF
	var best_unit_id: int = 2147483647
	for enemy_value: Variant in unit.enemy_units:
		var enemy: Variant = enemy_value
		if not _is_valid_unit(enemy) or not enemy.is_alive:
			continue

		var distance: float = unit.global_position.distance_to(enemy.global_position)
		if best_target == null or distance < best_distance:
			best_target = enemy
			best_distance = distance
			best_unit_id = int(enemy.unit_id)
		elif is_equal_approx(distance, best_distance) and int(enemy.unit_id) < best_unit_id:
			best_target = enemy
			best_unit_id = int(enemy.unit_id)

	return best_target


func _find_lowest_hp_ratio_enemy(unit: Variant, require_unmarked: bool = false) -> Variant:
	if not _is_valid_unit(unit):
		return null

	var best_target: Variant = null
	var best_ratio: float = INF
	var best_unit_id: int = 2147483647
	for enemy_value: Variant in unit.enemy_units:
		var enemy: Variant = enemy_value
		if not _is_valid_unit(enemy) or not enemy.is_alive or enemy.max_hp <= 0:
			continue
		if require_unmarked and _is_puppet_marked(enemy):
			continue

		var hp_ratio: float = float(enemy.hp) / float(enemy.max_hp)
		if best_target == null or hp_ratio < best_ratio:
			best_target = enemy
			best_ratio = hp_ratio
			best_unit_id = int(enemy.unit_id)
		elif is_equal_approx(hp_ratio, best_ratio) and int(enemy.unit_id) < best_unit_id:
			best_target = enemy
			best_unit_id = int(enemy.unit_id)

	return best_target


func _find_puppet_mark_target(unit: Variant) -> Variant:
	if not _is_valid_unit(unit):
		return null

	var current_target: Variant = unit.current_target
	if unit._is_valid_target(current_target) and not _is_puppet_marked(current_target):
		return current_target

	var unmarked_target: Variant = _find_lowest_hp_ratio_enemy(unit, true)
	if _is_valid_unit(unmarked_target):
		return unmarked_target

	if unit._is_valid_target(current_target):
		return current_target

	return _find_lowest_hp_ratio_enemy(unit)


func _apply_venom_stacks(unit: Variant, target: Variant, count: int) -> void:
	if not _is_valid_unit(unit) or not _is_valid_unit(target) or count <= 0:
		return

	for _index: int in range(count):
		_apply_status_effect(target, VENOM_STACK_EFFECT, StatusEffectFactory.EFFECT_TYPE_DAMAGE_OVER_TIME, unit, VENOM_STACK_DURATION, STATUS_EFFECT_TICK_INTERVAL, VENOM_STACK_DAMAGE, "", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_STACK_INDEPENDENT_DURATION,
			"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
			"category": StatusEffectFactory.CATEGORY_DOT,
		})


func _get_venom_stack_count(target: Variant) -> int:
	if not _is_valid_unit(target) or not target.has_method("get_status_effect_count"):
		return 0

	return int(target.get_status_effect_count(VENOM_STACK_EFFECT))


func _has_star_3_ally(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive and int(ally.star) >= 3:
			return true

	return false


func _apply_reaping_command_buffs(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	var mana_restore: float = REAPING_COMMAND_MANA_STAR_3 if _is_star_3(unit) else REAPING_COMMAND_MANA
	var crit_damage_bonus: float = REAPING_COMMAND_CRIT_DAMAGE_BONUS_STAR_3 if _is_star_3(unit) else REAPING_COMMAND_CRIT_DAMAGE_BONUS
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue
		if not _is_assassin_or_archer(ally):
			continue
		ally.restore_mana(mana_restore, unit)
		_apply_status_effect(ally, "reaping_command_crit_damage", StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, REAPING_COMMAND_BUFF_DURATION, 0.0, crit_damage_bonus, "crit_damage_multiplier", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_STAT,
		})
		if _is_star_3(unit):
			_apply_status_effect(ally, "reaping_command_crit_chance", StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, REAPING_COMMAND_BUFF_DURATION, 0.0, REAPING_COMMAND_CRIT_CHANCE_BONUS_STAR_3, "crit_chance", {
				"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
				"polarity": StatusEffectFactory.POLARITY_POSITIVE,
				"category": StatusEffectFactory.CATEGORY_STAT,
			})


func _find_highest_skill_power_ally(unit: Variant) -> Variant:
	if not _is_valid_unit(unit):
		return null

	var best_ally: Variant = null
	var best_skill_power: float = -INF
	var best_attack_damage: int = -2147483648
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue
		var skill_power: float = float(ally.skill_power)
		var attack_damage: int = int(ally.attack_damage)
		if best_ally == null or skill_power > best_skill_power:
			best_ally = ally
			best_skill_power = skill_power
			best_attack_damage = attack_damage
		elif is_equal_approx(skill_power, best_skill_power) and attack_damage > best_attack_damage:
			best_ally = ally
			best_attack_damage = attack_damage

	return best_ally


func _is_assassin_or_archer(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	var unit_type: String = str(unit.unit_type).to_lower()
	return unit_type == "assassin" or unit_type == "archer"


func _is_puppet_marked(target: Variant) -> bool:
	return _is_valid_unit(target) and bool(target.get_meta(PUPPET_MARK_META, false))


func _find_nearest_enemy_to_position(unit: Variant, origin_position: Vector2) -> Variant:
	if not _is_valid_unit(unit):
		return null

	var best_target: Variant = null
	var best_distance: float = INF
	var best_unit_id: int = 2147483647
	for enemy_value: Variant in unit.enemy_units:
		var enemy: Variant = enemy_value
		if not _is_valid_unit(enemy) or not enemy.is_alive:
			continue

		var distance: float = origin_position.distance_to(enemy.global_position)
		if best_target == null or distance < best_distance:
			best_target = enemy
			best_distance = distance
			best_unit_id = int(enemy.unit_id)
		elif is_equal_approx(distance, best_distance) and int(enemy.unit_id) < best_unit_id:
			best_target = enemy
			best_unit_id = int(enemy.unit_id)

	return best_target


func _get_hero_level(unit: Variant) -> int:
	if not _is_valid_unit(unit):
		return 1

	if unit.has_meta("hero_level"):
		return maxi(1, int(unit.get_meta("hero_level")))

	return 1


func _hero_has_upgrade(unit: Variant, upgrade_id: String) -> bool:
	if not _is_valid_unit(unit) or upgrade_id == "":
		return false

	if not unit.has_meta("hero_upgrade_ids"):
		return false

	var upgrade_ids: Variant = unit.get_meta("hero_upgrade_ids")
	if not (upgrade_ids is Array):
		return false

	var upgrade_array: Array = upgrade_ids as Array
	return upgrade_array.has(upgrade_id)


func _is_frontline_ally(source: Variant, ally: Variant) -> bool:
	return _is_ally_in_columns(source, ally, [5, 6])


func _is_midline_ally(source: Variant, ally: Variant) -> bool:
	return _is_ally_in_columns(source, ally, [3, 4])


func _is_ally_in_columns(source: Variant, ally: Variant, columns: Array[int]) -> bool:
	if not _is_valid_unit(source) or not _is_valid_unit(ally):
		return false

	if ally.battle_board != null and is_instance_valid(ally.battle_board) and ally.battle_board.has_method("world_to_grid"):
		var cell: Vector2i = ally.battle_board.world_to_grid(ally.position)
		if ally.team_id == 1:
			return columns.has(cell.x)

		for player_column: int in columns:
			if 14 - player_column == cell.x:
				return true

	return str(ally.role) == "tank"


func _get_source_scoped_effect_id(effect_id: String, unit: Variant) -> String:
	if not _is_valid_unit(unit):
		return effect_id

	return effect_id + "_" + str(unit.unit_id)




func _cast_septic_spit(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var damage_multiplier: float = _get_active_skill_damage_multiplier(unit)
	var skill_damage: int = maxi(1, int(round(float(unit.attack_damage) * SEPTIC_SPIT_DAMAGE_MULTIPLIER * damage_multiplier)))
	if not target.is_alive:
		return false

	target.take_damage(skill_damage, unit, false)
	_apply_venom_stacks_with_duration(unit, target, SEPTIC_SPIT_VENOM_STACKS, SEPTIC_SPIT_VENOM_DURATION)
	_apply_putrid_mark_effect(unit, target, SEPTIC_SPIT_MARK_DURATION)
	unit.unit_feedback.play_skill_feedback(unit, "Septic Spit")
	DEBUG_LOG_SCRIPT.combat(unit.display_name + " septic spit: " + str(skill_damage) + " damage to " + target.display_name)
	return true


func _cast_putrid_tide(unit: Variant) -> bool:
	var target: Variant = unit.current_target
	if not unit._is_valid_target(target):
		return false

	var damage_multiplier: float = _get_active_skill_damage_multiplier(unit)
	var base_damage: int = maxi(1, int(round(float(unit.attack_damage) * PUTRID_TIDE_DAMAGE_MULTIPLIER * damage_multiplier)))
	var direction: Vector2 = (target.global_position - unit.global_position).normalized()
	var shape_data: Dictionary = {
		"shape_type": "sector",
		"origin": unit.global_position,
		"direction": direction,
		"radius": PUTRID_TIDE_SECTOR_RADIUS,
		"angle_degrees": PUTRID_TIDE_SECTOR_ANGLE,
	}
	var targets: Array = aoe_resolver.get_enemy_units_in_shape(unit, shape_data)

	_create_aoe_shape_visual(unit, shape_data, INSTANT_AOE_VISUAL_DURATION, PUTRID_TIDE_VISUAL_COLOR)

	if targets.is_empty():
		return false

	var hit_count: int = 0
	for target_value: Variant in targets:
		var enemy: Variant = target_value
		if not _is_valid_unit(enemy) or not enemy.is_alive:
			continue
		var final_damage: int = base_damage
		if _has_putrid_mark(enemy):
			final_damage = maxi(1, int(round(float(base_damage) * PUTRID_TIDE_MARK_BONUS_MULTIPLIER)))
		enemy.take_damage(final_damage, unit, false)
		_apply_venom_stacks_with_duration(unit, enemy, PUTRID_TIDE_VENOM_STACKS, PUTRID_TIDE_VENOM_DURATION)
		_apply_putrid_mark_effect(unit, enemy, PUTRID_TIDE_MARK_DURATION)
		hit_count += 1

	unit.unit_feedback.play_skill_feedback(unit, "Putrid Tide")
	DEBUG_LOG_SCRIPT.combat(unit.display_name + " putrid tide: " + str(hit_count) + " targets hit for up to " + str(base_damage) + " base damage")
	return hit_count > 0


func _apply_venom_stacks_with_duration(unit: Variant, target: Variant, count: int, duration: float) -> void:
	if not _is_valid_unit(unit) or not _is_valid_unit(target) or count <= 0:
		return
	for _index: int in range(count):
		_apply_status_effect(target, VENOM_STACK_EFFECT, StatusEffectFactory.EFFECT_TYPE_DAMAGE_OVER_TIME, unit, duration, STATUS_EFFECT_TICK_INTERVAL, VENOM_STACK_DAMAGE, "", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_STACK_INDEPENDENT_DURATION,
			"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
			"category": StatusEffectFactory.CATEGORY_DOT,
		})


func _apply_putrid_mark_effect(unit: Variant, target: Variant, duration: float) -> void:
	if not _is_valid_unit(unit) or not _is_valid_unit(target):
		return
	_apply_status_effect(target, EFFECT_PUTRID_MARK, StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, unit, duration, 0.0, PUTRID_TIDE_MARK_BONUS_MULTIPLIER, "damage_taken_multiplier", {
		"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
		"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
		"category": StatusEffectFactory.CATEGORY_MARK,
	})


func _has_putrid_mark(target: Variant) -> bool:
	if not _is_valid_unit(target) or not target.is_alive:
		return false
	if target.has_method("get_status_effect_count"):
		return int(target.get_status_effect_count(EFFECT_PUTRID_MARK)) > 0
	return false
func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)


func _is_star_3(unit: Variant) -> bool:
	return _is_valid_unit(unit) and int(unit.star) == 3


func _get_skill_feedback_name(skill_name: String, unit: Variant) -> String:
	if _is_star_3(unit):
		return "Enhanced " + skill_name

	return skill_name
