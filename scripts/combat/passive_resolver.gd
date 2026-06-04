class_name PassiveResolver
extends RefCounted


const DEBUG_LOG_SCRIPT: Script = preload("res://scripts/debug_log.gd")
const StatusEffectFactory: Script = preload("res://scripts/combat/status_effect_factory.gd")
const AoeResolver: Script = preload("res://scripts/combat/aoe_resolver.gd")
const SKELETON_WARRIOR_SUMMON_DATA: Resource = preload("res://data/summons/skeleton_warrior.tres")
const SKELETON_ARCHER_SUMMON_DATA: Resource = preload("res://data/summons/skeleton_archer.tres")
const SKELETON_MAGE_SUMMON_DATA: Resource = preload("res://data/summons/skeleton_mage.tres")

const PASSIVE_ARMOR: String = "armor"
const PASSIVE_LONG_SHOT: String = "long_shot"
const PASSIVE_EXECUTE: String = "execute"
const PASSIVE_FORTRESS: String = "fortress"
const PASSIVE_ARCANE_FOCUS: String = "arcane_focus"
const PASSIVE_BENEVOLENCE: String = "benevolence"
const PASSIVE_BATTLE_SONG: String = "battle_song"
const PASSIVE_NATURE_TOUCH: String = "nature_touch"
const PASSIVE_POISON_BLADE: String = "poison_blade"
const PASSIVE_DEFENSIVE_COMMAND: String = "defensive_command"
const PASSIVE_WIND_RHYTHM: String = "wind_rhythm"
const PASSIVE_CLEAVING_EDGE: String = "cleaving_edge"
const PASSIVE_UNSTABLE_BOMB: String = "unstable_bomb"
const PASSIVE_HEALING_AURA: String = "healing_aura"
const PASSIVE_CORROSIVE_FLASK: String = "corrosive_flask"
const PASSIVE_HERO_IRON_OATH_COMMANDER: String = "hero_iron_oath_commander"
const PASSIVE_HERO_ARCANE_MENTOR: String = "hero_arcane_mentor"
const PASSIVE_HERO_BLOODSHADOW_HUNTER: String = "hero_bloodshadow_hunter"
const PASSIVE_HERO_BONEWEAVER: String = "hero_boneweaver"
const PASSIVE_SUMMONED_GOLEM_BODY: String = "summoned_golem_body"
const PASSIVE_SUMMONED_DRAGON_BREATH: String = "summoned_dragon_breath"
const PASSIVE_ENEMY_SHIELD_WALL: String = "enemy_shield_wall"
const PASSIVE_ENEMY_STONE_SKIN: String = "enemy_stone_skin"
const PASSIVE_ENEMY_IRON_BODY: String = "enemy_iron_body"
const PASSIVE_ENEMY_COLOSSUS_CORE: String = "enemy_colossus_core"
const PASSIVE_ENEMY_STEADY_AIM: String = "enemy_steady_aim"
const PASSIVE_ENEMY_FLAME_FOCUS: String = "enemy_flame_focus"
const PASSIVE_ENEMY_REAPER_EXECUTE: String = "enemy_reaper_execute"
const PASSIVE_ENEMY_CRYSTAL_CHARGE: String = "enemy_crystal_charge"
const PASSIVE_ENEMY_DARK_BLESSING: String = "enemy_dark_blessing"
const PASSIVE_ENEMY_WAR_RHYTHM: String = "enemy_war_rhythm"
const PASSIVE_ENEMY_BLOOD_RITUAL: String = "enemy_blood_ritual"
const PASSIVE_ENEMY_GOBLIN_CHANT: String = "enemy_goblin_chant"
const PASSIVE_MAGGOT_DEATH_BURST: String = "maggot_death_burst"
const PASSIVE_AMALGAM_SPLIT_BIRTH: String = "amalgam_split_birth"
const PASSIVE_SUMMONED_BONE_EDGE: String = "summoned_bone_edge"
const PASSIVE_SUMMONED_BONE_ARROW: String = "summoned_bone_arrow"
const PASSIVE_SUMMONED_WARRIOR_GUARD: String = "summoned_warrior_guard"
const PASSIVE_SUMMONED_PUPPET_BODY: String = "summoned_puppet_body"
const PASSIVE_SOUL_THREAD: String = "soul_thread"
const PASSIVE_STARFORGED_BODY: String = "starforged_body"
const PASSIVE_OVERLOAD_CORE: String = "overload_core"
const PASSIVE_VENOM_BROOD: String = "venom_brood"
const PASSIVE_DAWNBELL_ECHO: String = "dawnbell_echo"
const PASSIVE_NIGHTBLADE_ORDER: String = "nightblade_order"
const PASSIVE_BLOODBOUND_RAGE: String = "bloodbound_rage"
const PASSIVE_PRISM_REFRACTION: String = "prism_refraction"
const PASSIVE_FROST_ARROW: String = "frost_arrow"
const PASSIVE_TANGLED_GROWTH: String = "tangled_growth"
const PASSIVE_CONCUSSIVE_ARMOR: String = "concussive_armor"
const PASSIVE_SHATTER_FOCUS: String = "shatter_focus"
const PASSIVE_BANNER_GUARD: String = "banner_guard"
const PASSIVE_SLIME_BODY: String = "slime_body"
const PASSIVE_FROST_BURST: String = "frost_burst"
const PASSIVE_FLAME_BURST: String = "flame_burst"
const PASSIVE_VENOM_POOL: String = "venom_pool"
const PASSIVE_SLIME_SPLIT: String = "slime_split"
const PASSIVE_BOSS_ANCIENT_VITALITY: String = "boss_ancient_vitality"
const PASSIVE_BOSS_CORPSE_DEVOUR: String = "boss_corpse_devour"
const PASSIVE_BOSS_MOLTEN_BODY: String = "boss_molten_body"
const PASSIVE_BOSS_RAISE_THE_FALLEN: String = "boss_raise_the_fallen"
const PASSIVE_BOSS_GROVE_RESONANCE: String = "boss_grove_resonance"
const PASSIVE_ENEMY_IRON_BULWARK: String = "enemy_iron_bulwark"
const PASSIVE_ENEMY_FROST_MARK: String = "enemy_frost_mark"
const PASSIVE_ENEMY_BLOOD_BANNER_AURA: String = "enemy_blood_banner_aura"
const PASSIVE_ENEMY_MIRROR_CARAPACE: String = "enemy_mirror_carapace"
const PASSIVE_ENEMY_GOBLIN_OPPORTUNIST: String = "enemy_goblin_opportunist"

const ARMOR_DAMAGE_MULTIPLIER: float = 0.85
const ARMOR_DAMAGE_MULTIPLIER_STAR_3: float = 0.75
const LONG_SHOT_DISTANCE_RATIO: float = 0.6
const LONG_SHOT_DAMAGE_MULTIPLIER: float = 1.15
const LONG_SHOT_DAMAGE_MULTIPLIER_STAR_3: float = 1.25
const EXECUTE_HP_RATIO: float = 0.4
const EXECUTE_HP_RATIO_STAR_3: float = 0.5
const EXECUTE_DAMAGE_MULTIPLIER: float = 1.35
const EXECUTE_DAMAGE_MULTIPLIER_STAR_3: float = 1.6
const FORTRESS_DAMAGE_MULTIPLIER: float = 0.8
const FORTRESS_DAMAGE_MULTIPLIER_STAR_3: float = 0.7
const FORTRESS_LOW_HP_RATIO: float = 0.4
const FORTRESS_LOW_HP_DEFENSE_BONUS: int = 20
const FORTRESS_LOW_HP_DEFENSE_BONUS_STAR_3: int = 40
const ARCANE_FOCUS_SKILL_DAMAGE_MULTIPLIER: float = 1.15
const ARCANE_FOCUS_SKILL_DAMAGE_MULTIPLIER_STAR_3: float = 1.3
const BENEVOLENCE_HEAL_MULTIPLIER: float = 1.2
const BENEVOLENCE_HEAL_MULTIPLIER_STAR_3: float = 1.4
const BATTLE_SONG_ATTACK_BONUS: float = 0.08
const BATTLE_SONG_ATTACK_BONUS_STAR_3: float = 0.12
const BATTLE_SONG_MANA_REGEN_BONUS_STAR_3: float = 0.10
const NATURE_TOUCH_ATTACKS: int = 3
const NATURE_TOUCH_DURATION: float = 3.0
const NATURE_TOUCH_HEAL: float = 12.0
const NATURE_TOUCH_HEAL_STAR_3: float = 20.0
const POISON_BLADE_DURATION: float = 4.0
const POISON_BLADE_DAMAGE: float = 8.0
const POISON_BLADE_DAMAGE_STAR_3: float = 14.0
const DEFENSIVE_COMMAND_DEFENSE: float = 16.0
const DEFENSIVE_COMMAND_DEFENSE_STAR_3: float = 30.0
const WIND_RHYTHM_MANA_REGEN_MULTIPLIER: float = 1.12
const WIND_RHYTHM_MANA_REGEN_MULTIPLIER_STAR_3: float = 1.22
const CLEAVING_EDGE_SECTOR_ANGLE: float = 120.0
const CLEAVING_EDGE_DAMAGE_RATIO: float = 0.35
const CLEAVING_EDGE_DAMAGE_RATIO_STAR_3: float = 0.50
const UNSTABLE_BOMB_ATTACKS: int = 3
const UNSTABLE_BOMB_ATTACKS_STAR_3: int = 2
const UNSTABLE_BOMB_RADIUS: float = 75.0
const UNSTABLE_BOMB_RADIUS_STAR_3: float = 85.0
const UNSTABLE_BOMB_DAMAGE_RATIO: float = 0.40
const UNSTABLE_BOMB_DAMAGE_RATIO_STAR_3: float = 0.55
const HEALING_AURA_INTERVAL: float = 4.0
const HEALING_AURA_INTERVAL_STAR_3: float = 3.0
const HEALING_AURA_RADIUS: float = 100.0
const HEALING_AURA_RADIUS_STAR_3: float = 120.0
const HEALING_AURA_BASE_HEAL: float = 8.0
const HEALING_AURA_ATTACK_RATIO: float = 0.30
const HEALING_AURA_BASE_HEAL_STAR_3: float = 12.0
const HEALING_AURA_ATTACK_RATIO_STAR_3: float = 0.40
const CORROSIVE_FLASK_DURATION: float = 3.0
const FROST_ARROW_DURATION: float = 2.0
const FROST_ARROW_SPEED: float = 0.70
const FROST_ARROW_SPEED_2STAR: float = 0.65
const FROST_ARROW_DURATION_3STAR: float = 3.0
const CONCUSSIVE_ARMOR_SHIELDED_DAMAGE_MULTIPLIER: float = 0.90
const CONCUSSIVE_ARMOR_SHIELDED_DAMAGE_MULTIPLIER_STAR_3: float = 0.85
const CONCUSSIVE_ARMOR_STUNNED_DAMAGE_MULTIPLIER: float = 1.20
const SHATTER_FOCUS_SKILL_DAMAGE_MULTIPLIER: float = 1.20
const SHATTER_FOCUS_KILL_MANA_RESTORE_STAR_3: float = 30.0
const BANNER_GUARD_TAUNTED_DAMAGE_MULTIPLIER: float = 0.88
const BANNER_GUARD_SHIELD_POWER_PER_TAUNT: int = 4
const BANNER_GUARD_MAX_TAUNT_COUNT: int = 4
const BANNER_GUARD_TAUNT_ATTACK_MANA_RESTORE_STAR_3: float = 3.0
const CORROSIVE_FLASK_DURATION_STAR_3: float = 4.0
const CORROSIVE_FLASK_DAMAGE: float = 4.0
const CORROSIVE_FLASK_DAMAGE_STAR_3: float = 7.0
const STATUS_EFFECT_TICK_INTERVAL: float = 1.0
const BATTLE_LONG_EFFECT_DURATION: float = 9999.0
const EFFECT_NATURE_TOUCH: String = "nature_touch_hot"
const EFFECT_POISON_BLADE: String = "poison_blade_dot"
const EFFECT_DEFENSIVE_COMMAND: String = "defensive_command_defense"
const EFFECT_WIND_RHYTHM: String = "wind_rhythm_mana_regen"
const EFFECT_CORROSIVE_FLASK: String = "corrosive_flask_dot"
const EFFECT_PUTRID_MARK: String = "putrid_mark"
const PUTRID_MARK_DURATION: float = 5.0
const PUTRID_MARK_VALUE: float = 1.25
const MAGGOT_DEATH_BURST_RADIUS: float = 90.0
const MAGGOT_DEATH_BURST_BASE_DAMAGE: float = 35.0
const MAGGOT_DEATH_BURST_HP_RATIO: float = 0.08
const MAGGOT_DEATH_BURST_VENOM_DURATION: float = 3.0
const MAGGOT_DEATH_BURST_VENOM_STACKS: int = 1
const META_HEALING_AURA_TIMER: String = "healing_aura_timer"
const ENEMY_STONE_SKIN_DEFENSE_BONUS: int = 10
const ENEMY_STONE_SKIN_LOW_HP_RATIO: float = 0.50
const ENEMY_STONE_SKIN_LOW_HP_DEFENSE_BONUS: int = 15
const ENEMY_SHIELD_WALL_DAMAGE_MULTIPLIER: float = 0.90
const ENEMY_IRON_BODY_DAMAGE_MULTIPLIER: float = 0.82
const ENEMY_COLOSSUS_CORE_DAMAGE_MULTIPLIER: float = 0.75
const ENEMY_COLOSSUS_THRESHOLD_SHIELD: int = 120
const ENEMY_STEADY_AIM_DISTANCE_RATIO: float = 0.6
const ENEMY_STEADY_AIM_DAMAGE_MULTIPLIER: float = 1.10
const ENEMY_REAPER_EXECUTE_HP_RATIO: float = 0.45
const ENEMY_REAPER_EXECUTE_DAMAGE_MULTIPLIER: float = 1.35
const ENEMY_GOBLIN_OPPORTUNIST_HP_RATIO: float = 0.50
const ENEMY_GOBLIN_OPPORTUNIST_DAMAGE_MULTIPLIER: float = 1.15
const ENEMY_FLAME_FOCUS_SKILL_DAMAGE_MULTIPLIER: float = 1.10
const ENEMY_DARK_BLESSING_HEAL_MULTIPLIER: float = 1.15
const ENEMY_WAR_RHYTHM_ATTACK_BONUS: float = 0.06
const ENEMY_GOBLIN_CHANT_SHIELD: int = 30
const ENEMY_GOBLIN_CHANT_MANA_REGEN_BONUS: float = 0.10
const ENEMY_CRYSTAL_CHARGE_MANA: float = 8.0
const ENEMY_BLOOD_RITUAL_HEAL: int = 25
const SUMMONED_BONE_EDGE_HP_RATIO: float = 0.50
const SUMMONED_BONE_EDGE_DAMAGE_MULTIPLIER: float = 1.20
const SUMMONED_BONE_EDGE_DAMAGE_MULTIPLIER_STAR_3: float = 1.35
const SUMMONED_BONE_ARROW_HP_RATIO: float = 0.50
const SUMMONED_BONE_ARROW_DAMAGE_MULTIPLIER: float = 1.20
const SUMMONED_BONE_ARROW_DAMAGE_MULTIPLIER_STAR_3: float = 1.35
const SUMMONED_WARRIOR_GUARD_DAMAGE_MULTIPLIER: float = 0.90
const SUMMONED_WARRIOR_GUARD_DAMAGE_MULTIPLIER_STAR_3: float = 0.82
const SUMMONED_PUPPET_BODY_DAMAGE_MULTIPLIER: float = 0.90
const SUMMONED_PUPPET_BODY_DAMAGE_MULTIPLIER_STAR_3: float = 0.82
const INSTANT_AOE_VISUAL_DURATION: float = 0.35
const CLEAVING_EDGE_VISUAL_COLOR: Color = Color(1.0, 0.72, 0.22, 0.20)
const UNSTABLE_BOMB_VISUAL_COLOR: Color = Color(1.0, 0.32, 0.10, 0.22)
const HEALING_AURA_VISUAL_COLOR: Color = Color(0.35, 0.9, 0.65, 0.20)
const HERO_META_IS_HERO: String = "is_hero"
const HERO_META_HERO_ID: String = "hero_id"
const HERO_META_HERO_LEVEL: String = "hero_level"
const HERO_META_UPGRADE_IDS: String = "hero_upgrade_ids"
const HERO_ID_IRON_OATH_COMMANDER: String = "iron_oath_commander"
const HERO_ID_ARCANE_MENTOR: String = "arcane_mentor"
const HERO_ID_BLOODSHADOW_HUNTER: String = "bloodshadow_hunter"
const HERO_ID_BONEWEAVER: String = "boneweaver"
const HERO_BATTLE_LONG_EFFECT_ID: String = "hero_battle_long"
const HERO_IRON_FRONTLINE_DEFENSE_EFFECT: String = "hero_iron_frontline_defense"
const HERO_IRON_GUARD_SYNERGY_EFFECT: String = "hero_iron_guard_synergy"
const HERO_IRON_UNBROKEN_LINE_META: String = "hero_iron_unbroken_line_triggered"
const HERO_IRON_LINE_ECHO_ENABLED_META: String = "hero_iron_line_echo_enabled"
const HERO_IRON_LINE_ECHO_AMOUNT_META: String = "hero_iron_line_echo_amount"
const HERO_IRON_LINE_ECHO_COOLDOWN_META: String = "hero_iron_line_echo_cooldown"
const HERO_SHIELD_RECEIVED_MULTIPLIER_META: String = "shield_received_multiplier"
const HERO_BLOOD_MARK_META: String = "hero_hunt_marked"
const HERO_BLOOD_MARK_TEAM_META: String = "hero_hunt_mark_team_id"
const HERO_BLOOD_MARK_DEFENSE_META: String = "hero_hunt_mark_defense_down"
const HERO_BLOOD_MARK_DEFENSE_EFFECT: String = "hero_blood_mark_defense_down"
const HERO_BLOOD_HARVEST_CRIT_EFFECT: String = "hero_blood_harvest_crit"
const HERO_BLOOD_HARVEST_HASTE_EFFECT: String = "hero_blood_harvest_haste"
const BONEWEAVER_BONE_TIDE_HP_BONUS: float = 0.15
const BONEWEAVER_BONE_TIDE_ATK_BONUS: float = 0.15
const BONEWEAVER_BONE_TIDE_DAMAGE_PER_SUMMON: float = 0.05
const BONEWEAVER_BONE_TIDE_DAMAGE_CAP: float = 0.25
const BONEWEAVER_UNDYING_INVINCIBILITY_DURATION: float = 2.0
const BONEWEAVER_UNDYING_INVINCIBILITY_DURATION_UPGRADED: float = 4.0
const BONEWEAVER_UNDYING_TRIGGERED_META: String = "hero_boneweaver_undying_triggered"
const BONEWEAVER_UNDYING_INVINCIBLE_META: String = "hero_boneweaver_undying_invincible"
const GOLEM_BODY_DAMAGE_MULTIPLIER: float = 0.85
const DRAGON_BREATH_SPLASH_RATIO: float = 0.30
const DRAGON_BREATH_SPLASH_RADIUS: float = 80.0

const HERO_IRON_BATTLE_LONG_DURATION: float = 9999.0
const HERO_ARCANE_REFLOW_MANA: float = 8.0
const HERO_ARCANE_REFLOW_SKILL_UNIT_BONUS: float = 4.0
const HERO_SPELL_RESONANCE_MULTIPLIER: float = 1.10
const HERO_SPELL_RESONANCE_UPGRADED_MULTIPLIER: float = 1.18
const HERO_BLOOD_MARK_DAMAGE_MULTIPLIER: float = 1.15
const HERO_BLOOD_HARVEST_HEAL: int = 20
const HERO_BLOOD_HARVEST_MANA: float = 15.0
const HERO_BLOOD_HARVEST_HEAL_UPGRADED: int = 35
const HERO_BLOOD_HARVEST_MANA_UPGRADED: float = 25.0
const HERO_BLOOD_HARVEST_CRIT_BONUS: float = 0.10
const HERO_BLOOD_HARVEST_DURATION: float = 5.0
const SOUL_THREAD_SUMMON_MANA: float = 12.0
const SOUL_THREAD_SUMMON_MANA_STAR_3: float = 18.0
const SOUL_THREAD_UNIT_MANA: float = 25.0
const SOUL_THREAD_UNIT_MANA_STAR_3: float = 35.0
const SOUL_THREAD_UNIT_SHIELD: int = 30
const SOUL_THREAD_UNIT_SHIELD_STAR_3: int = 45
const STARFORGED_DEFENSE_PER_STAR_2: float = 6.0
const STARFORGED_DEFENSE_PER_STAR_2_STAR_3: float = 10.0
const STARFORGED_DEFENSE_PER_STAR_3: float = 12.0
const STARFORGED_DEFENSE_PER_STAR_3_STAR_3: float = 20.0
const STARFORGED_SHIELD_PER_STAR_3: int = 25
const STARFORGED_SHIELD_PER_STAR_3_STAR_3: int = 40
const OVERLOAD_CORE_CHANCE: float = 0.25
const OVERLOAD_CORE_CHANCE_STAR_3: float = 0.50
const OVERLOAD_CORE_MANA: float = 8.0
const OVERLOAD_CORE_MANA_STAR_3: float = 12.0
const VENOM_BROOD_DAMAGE_COUNT: int = 4
const VENOM_BROOD_DAMAGE_COUNT_STAR_3: int = 2
const VENOM_STACK_EFFECT: String = "venom_stack"
const VENOM_STACK_DURATION: float = 6.0
const VENOM_STACK_DAMAGE: float = 5.0
const VENOM_STACK_DECAY_PER_TICK: int = 5
const SLIME_BODY_BASIC_ATTACK_MULTIPLIER: float = 0.92
const SLIME_BODY_BASIC_ATTACK_MULTIPLIER_STAR_3: float = 0.85
const FROST_SLIME_DEATH_RADIUS: float = 115.0
const FROST_SLIME_DEATH_RADIUS_STAR_3: float = 140.0
const FROST_SLIME_DEATH_FREEZE_DURATION: float = 1.5
const FROST_SLIME_DEATH_FREEZE_DURATION_STAR_3: float = 2.0
const FROST_SLIME_FIELD_DURATION: float = 3.0
const FROST_SLIME_FIELD_TICK_INTERVAL: float = 1.0
const FROST_SLIME_FIELD_SLOW_DURATION: float = 2.0
const FROST_SLIME_FIELD_SLOW_DURATION_STAR_3: float = 2.5
const FROST_SLIME_FIELD_SLOW_SPEED: float = 0.80
const FROST_SLIME_FIELD_SLOW_SPEED_STAR_3: float = 0.70
const FLAME_SLIME_ATTACK_BURN_DURATION: float = 4.0
const FLAME_SLIME_ATTACK_BURN_DAMAGE_RATIO: float = 0.20
const FLAME_SLIME_ATTACK_BURN_DAMAGE_RATIO_STAR_3: float = 0.30
const FLAME_SLIME_DEATH_RADIUS: float = 120.0
const FLAME_SLIME_DEATH_RADIUS_STAR_3: float = 145.0
const FLAME_SLIME_DEATH_DAMAGE_RATIO: float = 1.0
const FLAME_SLIME_DEATH_DAMAGE_RATIO_STAR_3: float = 1.3
const FLAME_SLIME_FIELD_DURATION: float = 3.0
const FLAME_SLIME_FIELD_TICK_INTERVAL: float = 1.0
const VENOM_SLIME_DEATH_RADIUS: float = 120.0
const VENOM_SLIME_DEATH_RADIUS_STAR_3: float = 145.0
const VENOM_SLIME_DEATH_STACKS: int = 3
const VENOM_SLIME_DEATH_STACKS_STAR_3: int = 5
const VENOM_SLIME_FIELD_DURATION: float = 5.0
const VENOM_SLIME_FIELD_TICK_INTERVAL: float = 1.0
const VENOM_SLIME_FIELD_STACKS: int = 1
const VENOM_SLIME_FIELD_STACKS_STAR_3: int = 2
const FROST_SLIME_VISUAL_COLOR: Color = Color(0.45, 0.78, 1.0, 0.24)
const FLAME_SLIME_VISUAL_COLOR: Color = Color(1.0, 0.28, 0.08, 0.24)
const VENOM_SLIME_VISUAL_COLOR: Color = Color(0.45, 1.0, 0.25, 0.22)
const MAGGOT_BURST_VISUAL_COLOR: Color = Color(0.42, 0.82, 0.28, 0.22)
const DRAGON_BREATH_VISUAL_COLOR: Color = Color(0.55, 0.95, 1.0, 0.20)
const BOSS_ANCIENT_VITALITY_INTERVAL: float = 4.0
const BOSS_ANCIENT_VITALITY_HEAL_BASE: float = 35.0
const BOSS_ANCIENT_VITALITY_HEAL_MAX_HP_RATIO: float = 0.03
const BOSS_ANCIENT_VITALITY_LOW_HP_MULTIPLIER: float = 1.6
const BOSS_ANCIENT_VITALITY_LOW_HP_RATIO: float = 0.50
const BOSS_ANCIENT_VITALITY_SHIELD_HP_RATIO: float = 0.15
const BOSS_ANCIENT_VITALITY_SHIELD_BASE: int = 180
const BOSS_ANCIENT_VITALITY_SHIELD_TRIGGER_RATIO: float = 0.30
const BOSS_CORPSE_DEVOUR_MAX_LAYERS: int = 20
const BOSS_CORPSE_DEVOUR_STAT_RATIO: float = 0.10
const BOSS_MOLTEN_BODY_CHANCE: float = 0.25
const BOSS_MOLTEN_BODY_LOW_HP_CHANCE: float = 0.45
const BOSS_MOLTEN_BODY_LOW_HP_RATIO: float = 0.50
const BOSS_MOLTEN_BODY_REFLECT_RATIO: float = 0.35
const BOSS_MOLTEN_BODY_BURN_DURATION: float = 4.0
const BOSS_MOLTEN_BODY_BURN_RATIO: float = 0.20
const BOSS_MOLTEN_BODY_LOW_HP_BURN_RATIO: float = 0.30
const BOSS_RAISE_THE_FALLEN_CHANCE: float = 0.35
const BOSS_RAISE_THE_FALLEN_CAP: int = 6
const BOSS_GROVE_RESONANCE_HEAL_BASE: float = 25.0
const BOSS_GROVE_RESONANCE_HEAL_ATTACK_RATIO: float = 0.80
const BOSS_GROVE_RESONANCE_SHIELD_BASE: int = 60
const BOSS_GROVE_RESONANCE_SHIELD_HP_RATIO: float = 0.10
const BOSS_GROVE_RESONANCE_SHIELD_TRIGGER_RATIO: float = 0.30
const ENEMY_IRON_BULWARK_START_SHIELD_BASE: int = 120
const ENEMY_IRON_BULWARK_START_SHIELD_BASE_STAR_3: int = 160
const ENEMY_IRON_BULWARK_START_SHIELD_HP_RATIO: float = 0.15
const ENEMY_IRON_BULWARK_START_SHIELD_HP_RATIO_STAR_3: float = 0.20
const ENEMY_IRON_BULWARK_SHIELDED_DAMAGE_MULTIPLIER: float = 0.80
const ENEMY_IRON_BULWARK_SHIELDED_DAMAGE_MULTIPLIER_STAR_3: float = 0.70
const ENEMY_IRON_BULWARK_BREAK_DEFENSE: float = 10.0
const ENEMY_IRON_BULWARK_BREAK_DEFENSE_STAR_3: float = 18.0
const ENEMY_IRON_BULWARK_BREAK_DURATION: float = 4.0
const ENEMY_FROST_MARK_DURATION: float = 5.0
const ENEMY_FROST_MARK_DURATION_STAR_3: float = 6.0
const ENEMY_FROST_MARK_FREEZE_DURATION: float = 1.2
const ENEMY_FROST_MARK_FREEZE_DURATION_STAR_3: float = 1.6
const ENEMY_BLOOD_BANNER_AURA_DURATION: float = 0.6
const ENEMY_BLOOD_BANNER_ATTACK_INTERVAL_MULTIPLIER: float = 0.90
const ENEMY_BLOOD_BANNER_ATTACK_INTERVAL_MULTIPLIER_STAR_3: float = 0.84
const ENEMY_BLOOD_BANNER_MANA_MULTIPLIER: float = 1.10
const ENEMY_BLOOD_BANNER_MANA_MULTIPLIER_STAR_3: float = 1.16
const ENEMY_BLOOD_BANNER_ATTACK_MULTIPLIER_STAR_3: float = 1.08
const ENEMY_MIRROR_CARAPACE_START_SHIELD_BASE: int = 100
const ENEMY_MIRROR_CARAPACE_START_SHIELD_BASE_STAR_3: int = 140
const ENEMY_MIRROR_CARAPACE_START_SHIELD_HP_RATIO: float = 0.12
const ENEMY_MIRROR_CARAPACE_START_SHIELD_HP_RATIO_STAR_3: float = 0.18
const ENEMY_MIRROR_CARAPACE_REFLECT_RATIO: float = 0.25
const ENEMY_MIRROR_CARAPACE_REFLECT_RATIO_STAR_3: float = 0.35
const ENEMY_MIRROR_CARAPACE_COOLDOWN: float = 1.0
const ENEMY_MIRROR_CARAPACE_COOLDOWN_STAR_3: float = 0.6
const ENEMY_REFRACTION_ATTACK_MULTIPLIER: float = 1.35
const ENEMY_REFRACTION_ATTACK_MULTIPLIER_STAR_3: float = 1.50
const ENEMY_REFRACTION_ATTACK_MANA: float = 10.0
const DAWNBELL_OVERHEAL_SHIELD_RATIO: float = 0.70
const DAWNBELL_OVERHEAL_SHIELD_RATIO_STAR_3: float = 1.50
const DAWNBELL_REDEMPTION_META: String = "dawnbell_redemption_count"
const DAWNBELL_REDEMPTION_LIMIT: int = 1
const DAWNBELL_REDEMPTION_LIMIT_STAR_3: int = 3
const DAWNBELL_REDEMPTION_HP_RATIO: float = 0.50
const DAWNBELL_REDEMPTION_HP_RATIO_STAR_3: float = 1.0
const DAWNBELL_REDEMPTION_SHIELD: int = 100
const DAWNBELL_REDEMPTION_SHIELD_STAR_3: int = 250
const DEATH_PREVENTION_TRIGGERED_META: String = "death_prevention_triggered"
const NIGHTBLADE_CRIT_EFFECT: String = "nightblade_order_crit"
const NIGHTBLADE_CRIT_BONUS: float = 0.15
const NIGHTBLADE_CRIT_BONUS_STAR_3: float = 0.25
const NIGHTBLADE_LOW_HP_RATIO: float = 0.50
const NIGHTBLADE_LOW_HP_DAMAGE_MULTIPLIER: float = 1.25
const NIGHTBLADE_LOW_HP_DAMAGE_MULTIPLIER_STAR_3: float = 1.60
const BLOODBOUND_RAGE_HP_RATIO: float = 0.50
const BLOODBOUND_RAGE_DEEP_HP_RATIO: float = 0.25
const BLOODBOUND_RAGE_HP_RATIO_STAR_3: float = 0.70
const BLOODBOUND_RAGE_DEEP_HP_RATIO_STAR_3: float = 0.30
const BLOODBOUND_RAGE_ATTACK_MULTIPLIER: float = 1.20
const BLOODBOUND_RAGE_ATTACK_MULTIPLIER_DEEP: float = 1.35
const BLOODBOUND_RAGE_ATTACK_MULTIPLIER_STAR_3: float = 1.40
const BLOODBOUND_RAGE_ATTACK_MULTIPLIER_DEEP_STAR_3: float = 1.70
const BLOODBOUND_RAGE_LIFE_STEAL: float = 0.10
const BLOODBOUND_RAGE_LIFE_STEAL_DEEP: float = 0.20
const BLOODBOUND_RAGE_LIFE_STEAL_STAR_3: float = 0.20
const BLOODBOUND_RAGE_LIFE_STEAL_DEEP_STAR_3: float = 0.35
const PRISM_REFRACTION_CHANCE: float = 0.40
const PRISM_REFRACTION_CHANCE_STAR_3: float = 0.70
const PRISM_REFRACTION_MULTIPLIER: float = 1.25
const PRISM_REFRACTION_MULTIPLIER_STAR_3: float = 1.50

var status_effect_factory: Variant = StatusEffectFactory.new()
var aoe_resolver: Variant = AoeResolver.new()
var death_prevention_enabled: bool = false


func apply_battle_start_passives(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	if unit.has_meta(DEATH_PREVENTION_TRIGGERED_META):
		unit.remove_meta(DEATH_PREVENTION_TRIGGERED_META)

	match unit.passive_id:
		PASSIVE_BATTLE_SONG:
			var attack_bonus: float = BATTLE_SONG_ATTACK_BONUS_STAR_3 if _is_star_3(unit) else BATTLE_SONG_ATTACK_BONUS
			var mana_regen_bonus: float = BATTLE_SONG_MANA_REGEN_BONUS_STAR_3 if _is_star_3(unit) else 0.0
			_apply_ally_attack_and_mana_regen_bonus(unit, attack_bonus, mana_regen_bonus)
			DEBUG_LOG_SCRIPT.combat(unit.display_name + " battle song applied.")
		PASSIVE_DEFENSIVE_COMMAND:
			var defense_bonus: float = DEFENSIVE_COMMAND_DEFENSE_STAR_3 if _is_star_3(unit) else DEFENSIVE_COMMAND_DEFENSE
			for ally_value: Variant in unit.ally_units:
				var ally: Variant = ally_value
				if _is_valid_unit(ally) and ally.is_alive and _is_frontline_ally(unit, ally):
					_apply_status_effect(ally, EFFECT_DEFENSIVE_COMMAND, StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, BATTLE_LONG_EFFECT_DURATION, 0.0, defense_bonus, "defense", {
						"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
						"polarity": StatusEffectFactory.POLARITY_POSITIVE,
						"category": StatusEffectFactory.CATEGORY_AURA,
					})
			DEBUG_LOG_SCRIPT.combat(unit.display_name + " defensive command applied.")
		PASSIVE_WIND_RHYTHM:
			var mana_multiplier: float = WIND_RHYTHM_MANA_REGEN_MULTIPLIER_STAR_3 if _is_star_3(unit) else WIND_RHYTHM_MANA_REGEN_MULTIPLIER
			for ally_value: Variant in unit.ally_units:
				var ally: Variant = ally_value
				if _is_valid_unit(ally) and ally.is_alive:
					_apply_status_effect(ally, EFFECT_WIND_RHYTHM, StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, unit, BATTLE_LONG_EFFECT_DURATION, 0.0, mana_multiplier, "mana_regen_per_second", {
						"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
						"polarity": StatusEffectFactory.POLARITY_POSITIVE,
						"category": StatusEffectFactory.CATEGORY_AURA,
					})
			DEBUG_LOG_SCRIPT.combat(unit.display_name + " wind rhythm applied.")
		PASSIVE_HEALING_AURA:
			unit.set_meta(META_HEALING_AURA_TIMER, _get_healing_aura_interval(unit))
		PASSIVE_HERO_IRON_OATH_COMMANDER:
			_apply_iron_oath_battle_start(unit)
		PASSIVE_HERO_ARCANE_MENTOR:
			_apply_arcane_mentor_battle_start(unit)
		PASSIVE_HERO_BLOODSHADOW_HUNTER:
			_apply_bloodshadow_hunter_battle_start(unit)
		PASSIVE_HERO_BONEWEAVER:
			_apply_boneweaver_battle_start(unit)
		PASSIVE_STARFORGED_BODY:
			_apply_starforged_body(unit)
		PASSIVE_NIGHTBLADE_ORDER:
			_apply_nightblade_order(unit)
		PASSIVE_ENEMY_WAR_RHYTHM:
			_apply_ally_attack_and_mana_regen_bonus(unit, ENEMY_WAR_RHYTHM_ATTACK_BONUS, 0.0)
			DEBUG_LOG_SCRIPT.combat(unit.display_name + " war rhythm applied.")
		PASSIVE_ENEMY_GOBLIN_CHANT:
			for ally_value: Variant in unit.ally_units:
				var ally: Variant = ally_value
				if _is_valid_unit(ally) and ally.is_alive:
					ally.add_shield(ENEMY_GOBLIN_CHANT_SHIELD, unit)
			_apply_ally_attack_and_mana_regen_bonus(unit, 0.0, ENEMY_GOBLIN_CHANT_MANA_REGEN_BONUS)
			DEBUG_LOG_SCRIPT.combat(unit.display_name + " goblin chant applied.")
		PASSIVE_ENEMY_IRON_BULWARK:
			_apply_enemy_iron_bulwark_start(unit)
		PASSIVE_ENEMY_MIRROR_CARAPACE:
			_apply_enemy_mirror_carapace_start(unit)


func update_periodic_passives(unit: Variant, delta: float) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive or delta <= 0.0:
		return

	match unit.passive_id:
		PASSIVE_HEALING_AURA:
			_update_healing_aura(unit, delta)
		PASSIVE_ENEMY_BLOOD_BANNER_AURA:
			_update_enemy_blood_banner_aura(unit)
		PASSIVE_BOSS_ANCIENT_VITALITY:
			_update_boss_ancient_vitality(unit, delta)
		PASSIVE_BOSS_GROVE_RESONANCE:
			_update_boss_grove_resonance(unit)


func get_effective_defense_bonus(unit: Variant) -> int:
	if not _is_valid_unit(unit):
		return 0

	match unit.passive_id:
		PASSIVE_FORTRESS:
			if unit.max_hp <= 0:
				return 0

			var fortress_hp_ratio: float = float(unit.hp) / float(unit.max_hp)
			if fortress_hp_ratio > FORTRESS_LOW_HP_RATIO:
				return 0

			return FORTRESS_LOW_HP_DEFENSE_BONUS_STAR_3 if _is_star_3(unit) else FORTRESS_LOW_HP_DEFENSE_BONUS
		PASSIVE_ENEMY_STONE_SKIN:
			var defense_bonus: int = ENEMY_STONE_SKIN_DEFENSE_BONUS
			if unit.max_hp > 0:
				var stone_hp_ratio: float = float(unit.hp) / float(unit.max_hp)
				if stone_hp_ratio <= ENEMY_STONE_SKIN_LOW_HP_RATIO:
					defense_bonus += ENEMY_STONE_SKIN_LOW_HP_DEFENSE_BONUS
			return defense_bonus
		_:
			return 0


func apply_incoming_life_damage_passives(unit: Variant, life_damage: int) -> int:
	if not _is_valid_unit(unit):
		return life_damage

	if life_damage <= 0:
		return 0

	var resolved_damage: int = life_damage
	match unit.passive_id:
		PASSIVE_DAWNBELL_ECHO:
			resolved_damage = life_damage
		PASSIVE_ARMOR:
			var armor_multiplier: float = ARMOR_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else ARMOR_DAMAGE_MULTIPLIER
			resolved_damage = maxi(0, int(round(float(life_damage) * armor_multiplier)))
		PASSIVE_FORTRESS:
			var fortress_multiplier: float = FORTRESS_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else FORTRESS_DAMAGE_MULTIPLIER
			resolved_damage = maxi(0, int(round(float(life_damage) * fortress_multiplier)))
		PASSIVE_ENEMY_SHIELD_WALL:
			resolved_damage = maxi(0, int(round(float(life_damage) * ENEMY_SHIELD_WALL_DAMAGE_MULTIPLIER)))
		PASSIVE_ENEMY_IRON_BODY:
			resolved_damage = maxi(0, int(round(float(life_damage) * ENEMY_IRON_BODY_DAMAGE_MULTIPLIER)))
		PASSIVE_ENEMY_COLOSSUS_CORE:
			var reduced_damage: int = maxi(0, int(round(float(life_damage) * ENEMY_COLOSSUS_CORE_DAMAGE_MULTIPLIER)))
			_apply_enemy_colossus_threshold_shields(unit, reduced_damage)
			resolved_damage = reduced_damage
		PASSIVE_ENEMY_IRON_BULWARK:
			resolved_damage = _apply_enemy_iron_bulwark_life_damage(unit, life_damage)
		PASSIVE_SUMMONED_PUPPET_BODY:
			var puppet_multiplier: float = SUMMONED_PUPPET_BODY_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else SUMMONED_PUPPET_BODY_DAMAGE_MULTIPLIER
			resolved_damage = maxi(0, int(round(float(life_damage) * puppet_multiplier)))
		PASSIVE_SUMMONED_WARRIOR_GUARD:
			var warrior_guard_multiplier: float = SUMMONED_WARRIOR_GUARD_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else SUMMONED_WARRIOR_GUARD_DAMAGE_MULTIPLIER
			resolved_damage = maxi(0, int(round(float(life_damage) * warrior_guard_multiplier)))
		PASSIVE_SUMMONED_GOLEM_BODY:
			resolved_damage = maxi(0, int(round(float(life_damage) * GOLEM_BODY_DAMAGE_MULTIPLIER)))
		PASSIVE_CONCUSSIVE_ARMOR:
			var had_shield: bool = bool(unit.get_meta("incoming_damage_had_shield", false))
			if had_shield:
				var multiplier: float = CONCUSSIVE_ARMOR_SHIELDED_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else CONCUSSIVE_ARMOR_SHIELDED_DAMAGE_MULTIPLIER
				resolved_damage = maxi(0, int(round(float(life_damage) * multiplier)))
			else:
				resolved_damage = life_damage
		PASSIVE_BANNER_GUARD:
			if _has_enemy_taunted_by(unit):
				resolved_damage = maxi(0, int(round(float(life_damage) * BANNER_GUARD_TAUNTED_DAMAGE_MULTIPLIER)))
			else:
				resolved_damage = life_damage
		_:
			resolved_damage = life_damage

	resolved_damage = _try_apply_undying_thralls(unit, resolved_damage)
	resolved_damage = _apply_undying_invincibility(unit, resolved_damage)
	if _try_apply_dawnbell_redemption(unit, resolved_damage):
		return 0
	resolved_damage = _try_apply_death_prevention(unit, resolved_damage)
	_apply_iron_unbroken_line(unit, resolved_damage)
	return resolved_damage


func get_basic_attack_damage(unit: Variant, target: Variant, base_damage: int) -> int:
	if not _is_valid_unit(unit):
		return base_damage

	if not _is_valid_unit(target):
		return base_damage

	var damage_multiplier: float = 1.0

	match unit.passive_id:
		PASSIVE_LONG_SHOT:
			var distance_to_target: float = unit.global_position.distance_to(target.global_position)
			var trigger_distance: float = unit.attack_range * LONG_SHOT_DISTANCE_RATIO
			if distance_to_target >= trigger_distance:
				damage_multiplier = LONG_SHOT_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else LONG_SHOT_DAMAGE_MULTIPLIER
		PASSIVE_EXECUTE:
			if target.max_hp > 0:
				var hp_ratio: float = float(target.hp) / float(target.max_hp)
				var execute_hp_ratio: float = EXECUTE_HP_RATIO_STAR_3 if _is_star_3(unit) else EXECUTE_HP_RATIO
				if hp_ratio <= execute_hp_ratio:
					damage_multiplier = EXECUTE_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else EXECUTE_DAMAGE_MULTIPLIER
		PASSIVE_ENEMY_STEADY_AIM:
			var enemy_distance_to_target: float = unit.global_position.distance_to(target.global_position)
			var enemy_trigger_distance: float = unit.attack_range * ENEMY_STEADY_AIM_DISTANCE_RATIO
			if enemy_distance_to_target >= enemy_trigger_distance:
				damage_multiplier = ENEMY_STEADY_AIM_DAMAGE_MULTIPLIER
		PASSIVE_ENEMY_REAPER_EXECUTE:
			if target.max_hp > 0:
				var enemy_hp_ratio: float = float(target.hp) / float(target.max_hp)
				if enemy_hp_ratio <= ENEMY_REAPER_EXECUTE_HP_RATIO:
					damage_multiplier = ENEMY_REAPER_EXECUTE_DAMAGE_MULTIPLIER
		PASSIVE_ENEMY_GOBLIN_OPPORTUNIST:
			if target.max_hp > 0:
				var goblin_target_hp_ratio: float = float(target.hp) / float(target.max_hp)
				if goblin_target_hp_ratio <= ENEMY_GOBLIN_OPPORTUNIST_HP_RATIO:
					damage_multiplier = ENEMY_GOBLIN_OPPORTUNIST_DAMAGE_MULTIPLIER
		PASSIVE_SUMMONED_BONE_EDGE:
			if target.max_hp > 0:
				var bone_edge_hp_ratio: float = float(target.hp) / float(target.max_hp)
				if bone_edge_hp_ratio <= SUMMONED_BONE_EDGE_HP_RATIO:
					damage_multiplier = SUMMONED_BONE_EDGE_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else SUMMONED_BONE_EDGE_DAMAGE_MULTIPLIER
		PASSIVE_SUMMONED_BONE_ARROW:
			if target.max_hp > 0:
				var bone_arrow_hp_ratio: float = float(target.hp) / float(target.max_hp)
				if bone_arrow_hp_ratio <= SUMMONED_BONE_ARROW_HP_RATIO:
					damage_multiplier = SUMMONED_BONE_ARROW_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else SUMMONED_BONE_ARROW_DAMAGE_MULTIPLIER
		PASSIVE_BLOODBOUND_RAGE:
			damage_multiplier *= get_bloodbound_rage_attack_multiplier(unit)
		PASSIVE_ENEMY_MIRROR_CARAPACE:
			damage_multiplier *= get_enemy_refraction_attack_multiplier(unit)

	if _has_nightblade_order_bonus(unit, target):
		damage_multiplier *= _get_nightblade_order_damage_multiplier(unit)

	if unit.passive_id == PASSIVE_CONCUSSIVE_ARMOR and _is_valid_unit(target) and target.control_state != null and target.control_state.is_stunned:
		damage_multiplier *= CONCUSSIVE_ARMOR_STUNNED_DAMAGE_MULTIPLIER

	return maxi(1, int(round(float(base_damage) * damage_multiplier)))


func apply_attack_landed_passives(unit: Variant, target: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	match unit.passive_id:
		PASSIVE_NATURE_TOUCH:
			if unit.attack_count > 0 and unit.attack_count % NATURE_TOUCH_ATTACKS == 0:
				var heal_target: Variant = _find_lowest_hp_ratio_damaged_ally(unit)
				if not _is_valid_unit(heal_target):
					heal_target = unit
				var heal_amount: float = NATURE_TOUCH_HEAL_STAR_3 if _is_star_3(unit) else NATURE_TOUCH_HEAL
				_apply_status_effect(heal_target, EFFECT_NATURE_TOUCH, StatusEffectFactory.EFFECT_TYPE_HEAL_OVER_TIME, unit, NATURE_TOUCH_DURATION, STATUS_EFFECT_TICK_INTERVAL, heal_amount, "", {
					"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
					"polarity": StatusEffectFactory.POLARITY_POSITIVE,
					"category": StatusEffectFactory.CATEGORY_HOT,
				})
				unit.unit_feedback.play_skill_feedback(unit, "Nature Touch")
		PASSIVE_POISON_BLADE:
			if _is_valid_unit(target) and target.is_alive:
				var poison_damage: float = POISON_BLADE_DAMAGE_STAR_3 if _is_star_3(unit) else POISON_BLADE_DAMAGE
				_apply_status_effect(target, EFFECT_POISON_BLADE, StatusEffectFactory.EFFECT_TYPE_DAMAGE_OVER_TIME, unit, POISON_BLADE_DURATION, STATUS_EFFECT_TICK_INTERVAL, poison_damage, "", {
					"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
					"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
					"category": StatusEffectFactory.CATEGORY_DOT,
				})
		PASSIVE_CLEAVING_EDGE:
			_apply_cleaving_edge(unit, target)
		PASSIVE_SUMMONED_DRAGON_BREATH:
			if _is_valid_unit(target) and target.is_alive:
				_apply_dragon_breath_splash(unit, target)
		PASSIVE_CORROSIVE_FLASK:
			if _is_valid_unit(target) and target.is_alive:
				var corrosive_duration: float = CORROSIVE_FLASK_DURATION_STAR_3 if _is_star_3(unit) else CORROSIVE_FLASK_DURATION
				var corrosive_damage: float = CORROSIVE_FLASK_DAMAGE_STAR_3 if _is_star_3(unit) else CORROSIVE_FLASK_DAMAGE
				_apply_status_effect(target, EFFECT_CORROSIVE_FLASK, StatusEffectFactory.EFFECT_TYPE_DAMAGE_OVER_TIME, unit, corrosive_duration, STATUS_EFFECT_TICK_INTERVAL, corrosive_damage, "", {
					"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
					"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
					"category": StatusEffectFactory.CATEGORY_DOT,
				})
		PASSIVE_FROST_ARROW:
			if _is_valid_unit(target) and target.is_alive:
				_apply_frost_arrow(unit, target)
		PASSIVE_FLAME_BURST:
			if _is_valid_unit(target) and target.is_alive:
				var burn_ratio: float = FLAME_SLIME_ATTACK_BURN_DAMAGE_RATIO_STAR_3 if _is_star_3(unit) else FLAME_SLIME_ATTACK_BURN_DAMAGE_RATIO
				status_effect_factory.apply_burning(target, unit, FLAME_SLIME_ATTACK_BURN_DURATION, maxf(1.0, float(unit.attack_damage) * burn_ratio))
		PASSIVE_VENOM_POOL:
			if _is_valid_unit(target) and target.is_alive:
				_apply_maggot_venom_stacks(unit, target, 1, VENOM_STACK_DURATION)
		PASSIVE_ENEMY_CRYSTAL_CHARGE:
			unit.restore_mana(ENEMY_CRYSTAL_CHARGE_MANA, unit)
		PASSIVE_ENEMY_FROST_MARK:
			if _is_valid_unit(target) and target.is_alive:
				_apply_enemy_frost_mark(unit, target, 1)
		PASSIVE_ENEMY_MIRROR_CARAPACE:
			_apply_enemy_refraction_attack(unit)

	_apply_boss_molten_body_counter(target, unit)
	_apply_blood_mark_attack_landed(unit, target)


func apply_kill_passives(attacker: Variant, target: Variant) -> void:
	if not _is_valid_unit(attacker) or not _is_valid_unit(target):
		return

	if attacker.team_id == 1 and target.team_id == 2:
		if attacker.passive_id == PASSIVE_SHATTER_FOCUS and _is_star_3(attacker):
			var was_frozen: bool = bool(target.get_meta("was_frozen_on_death", false))
			if was_frozen:
				attacker.restore_mana(SHATTER_FOCUS_KILL_MANA_RESTORE_STAR_3, attacker)
		_apply_bloodshadow_harvest(attacker, target)
		return

	if attacker.team_id != 2 or target.team_id != 1:
		return

	for ally_value: Variant in attacker.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive and ally.passive_id == PASSIVE_ENEMY_BLOOD_RITUAL:
			attacker.heal(ENEMY_BLOOD_RITUAL_HEAL, ally)
			return


func notify_active_skill_cast(caster: Variant) -> void:
	if not _is_valid_unit(caster) or not caster.is_alive:
		return

	if caster.passive_id == PASSIVE_BOSS_GROVE_RESONANCE:
		_apply_boss_grove_resonance_heal(caster)

	if caster.team_id != 1:
		return

	var arcane_hero: Variant = _find_team_hero(caster, HERO_ID_ARCANE_MENTOR)
	if not _is_valid_unit(arcane_hero):
		return

	var mana_restore: float = HERO_ARCANE_REFLOW_MANA
	if _is_skill_damage_unit(caster):
		mana_restore += HERO_ARCANE_REFLOW_SKILL_UNIT_BONUS
	arcane_hero.restore_mana(mana_restore, arcane_hero)

	if _hero_has_upgrade(arcane_hero, "arcane_mana_shield"):
		caster.add_shield(10, arcane_hero)

	if caster == arcane_hero and _hero_has_upgrade(arcane_hero, "arcane_chain_casting"):
		var ally: Variant = _find_random_alive_ally(caster, true)
		if _is_valid_unit(ally):
			ally.restore_mana(30.0, arcane_hero)


func get_active_skill_damage_multiplier(unit: Variant) -> float:
	if not _is_valid_unit(unit):
		return 1.0

	var multiplier: float = maxf(0.0, float(unit.active_skill_damage_multiplier))
	if unit.passive_id == PASSIVE_ARCANE_FOCUS:
		multiplier *= ARCANE_FOCUS_SKILL_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else ARCANE_FOCUS_SKILL_DAMAGE_MULTIPLIER
	elif unit.passive_id == PASSIVE_ENEMY_FLAME_FOCUS:
		multiplier *= ENEMY_FLAME_FOCUS_SKILL_DAMAGE_MULTIPLIER

	multiplier *= 1.0 + maxf(0.0, float(unit.skill_power))
	multiplier *= _get_hero_active_skill_damage_multiplier(unit)
	multiplier *= _get_prism_refraction_multiplier(unit)
	return multiplier


func get_bloodbound_rage_attack_multiplier(unit: Variant) -> float:
	if not _is_valid_unit(unit) or unit.passive_id != PASSIVE_BLOODBOUND_RAGE or unit.max_hp <= 0:
		return 1.0

	var hp_ratio: float = float(unit.hp) / float(unit.max_hp)
	if _is_star_3(unit):
		if hp_ratio <= BLOODBOUND_RAGE_DEEP_HP_RATIO_STAR_3:
			return BLOODBOUND_RAGE_ATTACK_MULTIPLIER_DEEP_STAR_3
		if hp_ratio <= BLOODBOUND_RAGE_HP_RATIO_STAR_3:
			return BLOODBOUND_RAGE_ATTACK_MULTIPLIER_STAR_3
	else:
		if hp_ratio <= BLOODBOUND_RAGE_DEEP_HP_RATIO:
			return BLOODBOUND_RAGE_ATTACK_MULTIPLIER_DEEP
		if hp_ratio <= BLOODBOUND_RAGE_HP_RATIO:
			return BLOODBOUND_RAGE_ATTACK_MULTIPLIER

	return 1.0


func get_unstable_bomb_enhanced_data(unit: Variant) -> Dictionary:
	if not _is_valid_unit(unit):
		return {}

	var is_3_star: bool = _is_star_3(unit)
	var trigger_attacks: int = UNSTABLE_BOMB_ATTACKS_STAR_3 if is_3_star else UNSTABLE_BOMB_ATTACKS
	var launch_count_val: int = int(unit.launch_count) if "launch_count" in unit else 0

	if trigger_attacks <= 0 or launch_count_val <= 0 or launch_count_val % trigger_attacks != 0:
		return {}

	var radius: float = UNSTABLE_BOMB_RADIUS_STAR_3 if is_3_star else UNSTABLE_BOMB_RADIUS
	var damage_ratio: float = UNSTABLE_BOMB_DAMAGE_RATIO_STAR_3 if is_3_star else UNSTABLE_BOMB_DAMAGE_RATIO
	var damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_ratio)))
	var visual_color: Color = UNSTABLE_BOMB_VISUAL_COLOR

	return {
		"radius": radius,
		"damage": damage,
		"visual_color": visual_color,
	}


func get_bloodbound_rage_life_steal_bonus(unit: Variant) -> float:
	if not _is_valid_unit(unit) or unit.passive_id != PASSIVE_BLOODBOUND_RAGE or unit.max_hp <= 0:
		return 0.0

	var hp_ratio: float = float(unit.hp) / float(unit.max_hp)
	if _is_star_3(unit):
		if hp_ratio <= BLOODBOUND_RAGE_DEEP_HP_RATIO_STAR_3:
			return BLOODBOUND_RAGE_LIFE_STEAL_DEEP_STAR_3
		if hp_ratio <= BLOODBOUND_RAGE_HP_RATIO_STAR_3:
			return BLOODBOUND_RAGE_LIFE_STEAL_STAR_3
	else:
		if hp_ratio <= BLOODBOUND_RAGE_DEEP_HP_RATIO:
			return BLOODBOUND_RAGE_LIFE_STEAL_DEEP
		if hp_ratio <= BLOODBOUND_RAGE_HP_RATIO:
			return BLOODBOUND_RAGE_LIFE_STEAL

	return 0.0


func notify_mana_restored(unit: Variant, amount: float, source: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive or amount <= 0.0:
		return
	if unit.passive_id != PASSIVE_OVERLOAD_CORE:
		return
	if source == unit or bool(unit.get_meta("overload_core_resolving", false)):
		return

	var chance: float = OVERLOAD_CORE_CHANCE_STAR_3 if _is_star_3(unit) else OVERLOAD_CORE_CHANCE
	if randf() > chance:
		return

	unit.set_meta("overload_core_resolving", true)
	var extra_mana: float = OVERLOAD_CORE_MANA_STAR_3 if _is_star_3(unit) else OVERLOAD_CORE_MANA
	unit.restore_mana(extra_mana, unit)
	unit.set_meta("overload_core_resolving", false)
	if unit.unit_feedback != null:
		unit.unit_feedback.play_skill_feedback(unit, "Overload Core")


func notify_damage_dealt(attacker: Variant, target: Variant, amount: int) -> void:
	if not _is_valid_unit(attacker) or not _is_valid_unit(target) or amount <= 0:
		return
	if attacker.team_id != 1 or target.team_id != 2:
		return

	var venom_source: Variant = _find_alive_ally_with_passive(attacker, PASSIVE_VENOM_BROOD)
	if not _is_valid_unit(venom_source):
		return

	var threshold: int = VENOM_BROOD_DAMAGE_COUNT_STAR_3 if _is_star_3(venom_source) else VENOM_BROOD_DAMAGE_COUNT
	var meta_key: String = "venom_brood_hit_count_team_" + str(attacker.team_id)
	var hit_count: int = int(target.get_meta(meta_key, 0)) + 1
	if hit_count >= threshold:
		hit_count = 0
		_apply_venom_stack(venom_source, target, 1)
	target.set_meta(meta_key, hit_count)


func notify_ally_died(unit: Variant, dead_ally: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive or not _is_valid_unit(dead_ally):
		return
	if unit.passive_id != PASSIVE_SOUL_THREAD:
		return

	var is_summon: bool = bool(dead_ally.get_meta("is_summon", false))
	if is_summon:
		unit.restore_mana(SOUL_THREAD_SUMMON_MANA_STAR_3 if _is_star_3(unit) else SOUL_THREAD_SUMMON_MANA, unit)
		return

	unit.restore_mana(SOUL_THREAD_UNIT_MANA_STAR_3 if _is_star_3(unit) else SOUL_THREAD_UNIT_MANA, unit)
	var shield_amount: int = SOUL_THREAD_UNIT_SHIELD_STAR_3 if _is_star_3(unit) else SOUL_THREAD_UNIT_SHIELD
	var target_count: int = 2 if _is_star_3(unit) else 1
	var targets: Array = _find_lowest_hp_ratio_allies(unit, target_count)
	for target_value: Variant in targets:
		var target: Variant = target_value
		if _is_valid_unit(target) and target.is_alive:
			target.add_shield(shield_amount, unit)


func notify_unit_died(unit: Variant, dead_unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive or not _is_valid_unit(dead_unit):
		return
	if unit == dead_unit:
		return

	match unit.passive_id:
		PASSIVE_BOSS_CORPSE_DEVOUR:
			_apply_boss_corpse_devour_bonus(unit)
		PASSIVE_BOSS_RAISE_THE_FALLEN:
			_try_boss_raise_the_fallen(unit, dead_unit)


func apply_corpse_devour_bonus(unit: Variant) -> void:
	_apply_boss_corpse_devour_bonus(unit)


func notify_heal_overflow(target: Variant, overflow_amount: int, source: Variant) -> void:
	if not _is_valid_unit(target) or not target.is_alive or overflow_amount <= 0:
		return

	var dawnbell: Variant = _find_alive_ally_with_passive(target, PASSIVE_DAWNBELL_ECHO)
	if not _is_valid_unit(dawnbell):
		return

	var ratio: float = DAWNBELL_OVERHEAL_SHIELD_RATIO_STAR_3 if _is_star_3(dawnbell) else DAWNBELL_OVERHEAL_SHIELD_RATIO
	var shield_amount: int = maxi(1, int(round(float(overflow_amount) * ratio)))
	target.add_shield(shield_amount, dawnbell)


func _update_boss_ancient_vitality(unit: Variant, delta: float) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	var timer: float = float(unit.get_meta("boss_ancient_vitality_timer", BOSS_ANCIENT_VITALITY_INTERVAL)) - delta
	if timer <= 0.0:
		timer += BOSS_ANCIENT_VITALITY_INTERVAL
		var heal_amount: int = maxi(1, int(round(BOSS_ANCIENT_VITALITY_HEAL_BASE + float(unit.max_hp) * BOSS_ANCIENT_VITALITY_HEAL_MAX_HP_RATIO)))
		if unit.max_hp > 0 and float(unit.hp) / float(unit.max_hp) <= BOSS_ANCIENT_VITALITY_LOW_HP_RATIO:
			heal_amount = maxi(1, int(round(float(heal_amount) * BOSS_ANCIENT_VITALITY_LOW_HP_MULTIPLIER)))
		unit.heal(heal_amount, unit)

	if not bool(unit.get_meta("boss_ancient_vitality_shielded", false)) and unit.max_hp > 0:
		var hp_ratio: float = float(unit.hp) / float(unit.max_hp)
		if hp_ratio <= BOSS_ANCIENT_VITALITY_SHIELD_TRIGGER_RATIO:
			unit.set_meta("boss_ancient_vitality_shielded", true)
			var shield_amount: int = maxi(1, int(round(float(BOSS_ANCIENT_VITALITY_SHIELD_BASE) + float(unit.max_hp) * BOSS_ANCIENT_VITALITY_SHIELD_HP_RATIO)))
			unit.add_shield(shield_amount, unit)

	unit.set_meta("boss_ancient_vitality_timer", timer)


func _apply_boss_corpse_devour_bonus(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return
	if unit.passive_id != PASSIVE_BOSS_CORPSE_DEVOUR:
		return

	var layer: int = int(unit.get_meta("boss_corpse_devour_layers", 0))
	if layer >= BOSS_CORPSE_DEVOUR_MAX_LAYERS:
		return

	if not unit.has_meta("boss_corpse_devour_base_attack"):
		unit.set_meta("boss_corpse_devour_base_attack", unit.attack_damage)
		unit.set_meta("boss_corpse_devour_base_defense", unit.defense)
		unit.set_meta("boss_corpse_devour_base_max_hp", unit.max_hp)

	layer += 1
	unit.set_meta("boss_corpse_devour_layers", layer)
	var stat_index: int = (layer - 1) % 3
	match stat_index:
		0:
			var attack_gain: int = maxi(1, int(round(float(unit.get_meta("boss_corpse_devour_base_attack", unit.attack_damage)) * BOSS_CORPSE_DEVOUR_STAT_RATIO)))
			unit.attack_damage += attack_gain
		1:
			var defense_gain: int = maxi(1, int(round(float(unit.get_meta("boss_corpse_devour_base_defense", unit.defense)) * BOSS_CORPSE_DEVOUR_STAT_RATIO)))
			unit.defense += defense_gain
		_:
			var hp_gain: int = maxi(1, int(round(float(unit.get_meta("boss_corpse_devour_base_max_hp", unit.max_hp)) * BOSS_CORPSE_DEVOUR_STAT_RATIO)))
			unit.max_hp += hp_gain
			unit.hp += maxi(1, int(round(float(hp_gain) * 0.5)))
			unit.hp = mini(unit.hp, unit.max_hp)

	unit._update_hp_bar()
	unit.update_info_display()


func _apply_boss_molten_body_counter(boss: Variant, attacker: Variant) -> void:
	if not _is_valid_unit(boss) or not boss.is_alive:
		return
	if not _is_valid_unit(attacker) or not attacker.is_alive:
		return
	if boss.passive_id != PASSIVE_BOSS_MOLTEN_BODY:
		return
	if int(boss.team_id) == int(attacker.team_id):
		return
	if str(attacker.basic_attack_type) != "melee":
		return

	var hp_ratio: float = float(boss.hp) / float(maxi(1, boss.max_hp))
	var chance: float = BOSS_MOLTEN_BODY_LOW_HP_CHANCE if hp_ratio <= BOSS_MOLTEN_BODY_LOW_HP_RATIO else BOSS_MOLTEN_BODY_CHANCE
	if randf() > chance:
		return

	var reflect_damage: int = maxi(1, int(round(float(boss.attack_damage) * BOSS_MOLTEN_BODY_REFLECT_RATIO)))
	attacker.take_damage(reflect_damage, boss, false)
	if _is_valid_unit(attacker) and attacker.is_alive:
		var burn_ratio: float = BOSS_MOLTEN_BODY_LOW_HP_BURN_RATIO if hp_ratio <= BOSS_MOLTEN_BODY_LOW_HP_RATIO else BOSS_MOLTEN_BODY_BURN_RATIO
		status_effect_factory.apply_burning(attacker, boss, BOSS_MOLTEN_BODY_BURN_DURATION, maxf(1.0, float(boss.attack_damage) * burn_ratio))


func _try_boss_raise_the_fallen(unit: Variant, dead_unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return
	if unit.passive_id != PASSIVE_BOSS_RAISE_THE_FALLEN:
		return
	if not _is_valid_unit(dead_unit) or int(dead_unit.team_id) == int(unit.team_id):
		return
	if randf() > BOSS_RAISE_THE_FALLEN_CHANCE:
		return

	var context: Dictionary = {
		"source_type": "unit",
		"source_key": "boss_raise_the_fallen:" + str(unit.unit_id),
		"summon_cap": BOSS_RAISE_THE_FALLEN_CAP,
		"position": dead_unit.position,
		"team_id": unit.team_id,
		"spawn_radius": 38.0,
	}
	_summon_units(unit, _get_random_boss_undead_summon_data(), 1, context)


func _update_boss_grove_resonance(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive or ally.max_hp <= 0:
			continue
		var meta_key: String = "boss_grove_resonance_shielded_by_" + str(unit.unit_id)
		if bool(ally.get_meta(meta_key, false)):
			continue
		if float(ally.hp) / float(ally.max_hp) > BOSS_GROVE_RESONANCE_SHIELD_TRIGGER_RATIO:
			continue
		ally.set_meta(meta_key, true)
		var shield_amount: int = maxi(1, int(round(float(BOSS_GROVE_RESONANCE_SHIELD_BASE) + float(ally.max_hp) * BOSS_GROVE_RESONANCE_SHIELD_HP_RATIO)))
		ally.add_shield(shield_amount, unit)


func _apply_boss_grove_resonance_heal(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	var heal_amount: int = maxi(1, int(round(BOSS_GROVE_RESONANCE_HEAL_BASE + float(unit.attack_damage) * BOSS_GROVE_RESONANCE_HEAL_ATTACK_RATIO)))
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive:
			ally.heal(heal_amount, unit)


func _apply_enemy_iron_bulwark_start(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	var shield_base: int = ENEMY_IRON_BULWARK_START_SHIELD_BASE_STAR_3 if _is_star_3(unit) else ENEMY_IRON_BULWARK_START_SHIELD_BASE
	var shield_ratio: float = ENEMY_IRON_BULWARK_START_SHIELD_HP_RATIO_STAR_3 if _is_star_3(unit) else ENEMY_IRON_BULWARK_START_SHIELD_HP_RATIO
	unit.add_shield(maxi(1, int(round(float(shield_base) + float(unit.max_hp) * shield_ratio))), unit)


func _apply_enemy_iron_bulwark_life_damage(unit: Variant, life_damage: int) -> int:
	if not _is_valid_unit(unit) or life_damage <= 0:
		return life_damage

	var had_shield: bool = bool(unit.get_meta("incoming_damage_had_shield", false))
	var resolved_damage: int = life_damage
	if had_shield:
		var multiplier: float = ENEMY_IRON_BULWARK_SHIELDED_DAMAGE_MULTIPLIER_STAR_3 if _is_star_3(unit) else ENEMY_IRON_BULWARK_SHIELDED_DAMAGE_MULTIPLIER
		resolved_damage = maxi(0, int(round(float(life_damage) * multiplier)))

	if had_shield and int(unit.shield) <= 0 and not bool(unit.get_meta("enemy_iron_bulwark_break_triggered", false)):
		unit.set_meta("enemy_iron_bulwark_break_triggered", true)
		var defense_bonus: float = ENEMY_IRON_BULWARK_BREAK_DEFENSE_STAR_3 if _is_star_3(unit) else ENEMY_IRON_BULWARK_BREAK_DEFENSE
		_apply_status_effect(unit, "enemy_iron_bulwark_break_defense", StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, ENEMY_IRON_BULWARK_BREAK_DURATION, 0.0, defense_bonus, "defense", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_STAT,
		})

	return resolved_damage


func _apply_enemy_mirror_carapace_start(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	var shield_base: int = ENEMY_MIRROR_CARAPACE_START_SHIELD_BASE_STAR_3 if _is_star_3(unit) else ENEMY_MIRROR_CARAPACE_START_SHIELD_BASE
	var shield_ratio: float = ENEMY_MIRROR_CARAPACE_START_SHIELD_HP_RATIO_STAR_3 if _is_star_3(unit) else ENEMY_MIRROR_CARAPACE_START_SHIELD_HP_RATIO
	unit.add_shield(maxi(1, int(round(float(shield_base) + float(unit.max_hp) * shield_ratio))), unit)


func _update_enemy_blood_banner_aura(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	var attack_interval_multiplier: float = ENEMY_BLOOD_BANNER_ATTACK_INTERVAL_MULTIPLIER_STAR_3 if _is_star_3(unit) else ENEMY_BLOOD_BANNER_ATTACK_INTERVAL_MULTIPLIER
	var mana_multiplier: float = ENEMY_BLOOD_BANNER_MANA_MULTIPLIER_STAR_3 if _is_star_3(unit) else ENEMY_BLOOD_BANNER_MANA_MULTIPLIER
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue
		_apply_status_effect(ally, "enemy_blood_banner_aura_attack_interval", StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, unit, ENEMY_BLOOD_BANNER_AURA_DURATION, 0.0, attack_interval_multiplier, "attack_interval", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_AURA,
		})
		_apply_status_effect(ally, "enemy_blood_banner_aura_mana", StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, unit, ENEMY_BLOOD_BANNER_AURA_DURATION, 0.0, mana_multiplier, "mana_regen_per_second", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_AURA,
		})
		if _is_star_3(unit):
			_apply_status_effect(ally, "enemy_blood_banner_aura_attack", StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, unit, ENEMY_BLOOD_BANNER_AURA_DURATION, 0.0, ENEMY_BLOOD_BANNER_ATTACK_MULTIPLIER_STAR_3, "attack_damage", {
				"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
				"polarity": StatusEffectFactory.POLARITY_POSITIVE,
				"category": StatusEffectFactory.CATEGORY_AURA,
			})


func _apply_enemy_frost_mark(unit: Variant, target: Variant, count: int = 1) -> void:
	if not _is_valid_unit(unit) or not _is_valid_unit(target) or count <= 0:
		return

	var duration: float = ENEMY_FROST_MARK_DURATION_STAR_3 if _is_star_3(unit) else ENEMY_FROST_MARK_DURATION
	for _index: int in range(count):
		_apply_status_effect(target, "enemy_frost_mark", StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, duration, 0.0, 0.0, "", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_STACK_INDEPENDENT_DURATION,
			"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
			"category": StatusEffectFactory.CATEGORY_MARK,
			"stack_group_key": "enemy_frost_mark_" + str(target.unit_id),
		})

	if target.get_status_effect_count("enemy_frost_mark") < 3:
		return

	target.remove_status_effect("enemy_frost_mark")
	status_effect_factory.apply_control_effect(target, "FREEZE", unit, ENEMY_FROST_MARK_FREEZE_DURATION_STAR_3 if _is_star_3(unit) else ENEMY_FROST_MARK_FREEZE_DURATION, {
		"effect_id": "enemy_frost_mark_freeze",
		"stack_group_key": "freeze",
		"source_key": "enemy_frost_mark",
	})


func _apply_enemy_refraction_attack(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	var remaining_attacks: int = int(unit.get_meta("enemy_refraction_shell_attacks", 0))
	if remaining_attacks <= 0:
		return

	unit.set_meta("enemy_refraction_shell_attacks", remaining_attacks - 1)
	unit.restore_mana(ENEMY_REFRACTION_ATTACK_MANA, unit)


func get_enemy_refraction_attack_multiplier(unit: Variant) -> float:
	if not _is_valid_unit(unit) or unit.passive_id != PASSIVE_ENEMY_MIRROR_CARAPACE:
		return 1.0
	if int(unit.get_meta("enemy_refraction_shell_attacks", 0)) <= 0:
		return 1.0
	return ENEMY_REFRACTION_ATTACK_MULTIPLIER_STAR_3 if _is_star_3(unit) else ENEMY_REFRACTION_ATTACK_MULTIPLIER


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


func _get_random_boss_undead_summon_data() -> Resource:
	var pool: Array[Resource] = [
		SKELETON_WARRIOR_SUMMON_DATA,
		SKELETON_ARCHER_SUMMON_DATA,
		SKELETON_MAGE_SUMMON_DATA,
	]
	return pool[randi_range(0, pool.size() - 1)]


func _apply_starforged_body(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	var star_2_count: int = 0
	var star_3_count: int = 0
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue
		if int(ally.star) >= 2:
			star_2_count += 1
		if int(ally.star) >= 3:
			star_3_count += 1

	var defense_per_star_2: float = STARFORGED_DEFENSE_PER_STAR_2_STAR_3 if _is_star_3(unit) else STARFORGED_DEFENSE_PER_STAR_2
	var defense_per_star_3: float = STARFORGED_DEFENSE_PER_STAR_3_STAR_3 if _is_star_3(unit) else STARFORGED_DEFENSE_PER_STAR_3
	var defense_bonus: float = float(star_2_count) * defense_per_star_2 + float(star_3_count) * defense_per_star_3
	if defense_bonus > 0.0:
		_apply_status_effect(unit, "starforged_body_defense", StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, BATTLE_LONG_EFFECT_DURATION, 0.0, defense_bonus, "defense", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_AURA,
		})

	var shield_per_star_3: int = STARFORGED_SHIELD_PER_STAR_3_STAR_3 if _is_star_3(unit) else STARFORGED_SHIELD_PER_STAR_3
	if star_3_count > 0:
		unit.add_shield(star_3_count * shield_per_star_3, unit)


func _apply_nightblade_order(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return

	var crit_bonus: float = NIGHTBLADE_CRIT_BONUS_STAR_3 if _is_star_3(unit) else NIGHTBLADE_CRIT_BONUS
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue
		if not (_is_assassin_unit(ally) or _is_archer_unit(ally)):
			continue
		_apply_status_effect(ally, NIGHTBLADE_CRIT_EFFECT, StatusEffectFactory.EFFECT_TYPE_STAT_ADD, unit, BATTLE_LONG_EFFECT_DURATION, 0.0, crit_bonus, "crit_chance", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_AURA,
		})


func _try_apply_dawnbell_redemption(target: Variant, incoming_life_damage: int) -> bool:
	if not _is_valid_unit(target) or not target.is_alive or incoming_life_damage <= 0:
		return false
	if int(target.hp) - incoming_life_damage > 0:
		return false

	var dawnbell: Variant = _find_alive_ally_with_passive(target, PASSIVE_DAWNBELL_ECHO)
	if not _is_valid_unit(dawnbell):
		return false

	var limit: int = DAWNBELL_REDEMPTION_LIMIT_STAR_3 if _is_star_3(dawnbell) else DAWNBELL_REDEMPTION_LIMIT
	var used_count: int = int(dawnbell.get_meta(DAWNBELL_REDEMPTION_META, 0))
	if used_count >= limit:
		return false

	dawnbell.set_meta(DAWNBELL_REDEMPTION_META, used_count + 1)
	var hp_ratio: float = DAWNBELL_REDEMPTION_HP_RATIO_STAR_3 if _is_star_3(dawnbell) else DAWNBELL_REDEMPTION_HP_RATIO
	target.hp = clampi(int(round(float(target.max_hp) * hp_ratio)), 1, int(target.max_hp))
	target._update_hp_bar()
	target.update_info_display()
	var shield_amount: int = DAWNBELL_REDEMPTION_SHIELD_STAR_3 if _is_star_3(dawnbell) else DAWNBELL_REDEMPTION_SHIELD
	target.add_shield(shield_amount, dawnbell)
	if dawnbell.unit_feedback != null:
		dawnbell.unit_feedback.play_skill_feedback(dawnbell, "One-Time Redemption")
	return true


func _apply_venom_stack(source: Variant, target: Variant, count: int) -> void:
	if not _is_valid_unit(source) or not _is_valid_unit(target) or count <= 0:
		return

	_apply_status_effect(target, VENOM_STACK_EFFECT, StatusEffectFactory.EFFECT_TYPE_DAMAGE_OVER_TIME, source, VENOM_STACK_DURATION, STATUS_EFFECT_TICK_INTERVAL, VENOM_STACK_DAMAGE, "", {
		"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
		"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
		"category": StatusEffectFactory.CATEGORY_DOT,
		"stack_count": count,
		"stack_decay_after_duration": true,
		"stack_decay_per_tick": VENOM_STACK_DECAY_PER_TICK,
	})


func _get_prism_refraction_multiplier(unit: Variant) -> float:
	if not _is_valid_unit(unit) or unit.team_id != 1:
		return 1.0

	var prism: Variant = _find_strongest_alive_ally_with_passive(unit, PASSIVE_PRISM_REFRACTION)
	if not _is_valid_unit(prism):
		return 1.0

	var chance: float = PRISM_REFRACTION_CHANCE_STAR_3 if _is_star_3(prism) else PRISM_REFRACTION_CHANCE
	if randf() > chance:
		return 1.0

	if prism.unit_feedback != null:
		prism.unit_feedback.play_skill_feedback(prism, "Prism Refraction")
	return PRISM_REFRACTION_MULTIPLIER_STAR_3 if _is_star_3(prism) else PRISM_REFRACTION_MULTIPLIER


func _has_nightblade_order_bonus(attacker: Variant, target: Variant) -> bool:
	if not _is_valid_unit(attacker) or not _is_valid_unit(target):
		return false
	if attacker.team_id != 1 or target.team_id != 2:
		return false
	if not (_is_assassin_unit(attacker) or _is_archer_unit(attacker)):
		return false
	if target.max_hp <= 0 or float(target.hp) / float(target.max_hp) >= NIGHTBLADE_LOW_HP_RATIO:
		return false

	return _is_valid_unit(_find_alive_ally_with_passive(attacker, PASSIVE_NIGHTBLADE_ORDER))


func _get_nightblade_order_damage_multiplier(attacker: Variant) -> float:
	var nightblade: Variant = _find_alive_ally_with_passive(attacker, PASSIVE_NIGHTBLADE_ORDER)
	if _is_star_3(nightblade):
		return NIGHTBLADE_LOW_HP_DAMAGE_MULTIPLIER_STAR_3
	return NIGHTBLADE_LOW_HP_DAMAGE_MULTIPLIER


func _find_alive_ally_with_passive(unit: Variant, passive_id: String) -> Variant:
	if not _is_valid_unit(unit):
		return null

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive and str(ally.passive_id) == passive_id:
			return ally

	return null


func _find_strongest_alive_ally_with_passive(unit: Variant, passive_id: String) -> Variant:
	if not _is_valid_unit(unit):
		return null

	var best_ally: Variant = null
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive or str(ally.passive_id) != passive_id:
			continue
		if best_ally == null or int(ally.star) > int(best_ally.star):
			best_ally = ally

	return best_ally


func _find_lowest_hp_ratio_allies(unit: Variant, count: int) -> Array:
	var selected_allies: Array = []
	var safe_count: int = maxi(0, count)
	if not _is_valid_unit(unit) or safe_count <= 0:
		return selected_allies

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive or ally.max_hp <= 0:
			continue
		var insert_index: int = selected_allies.size()
		var ratio: float = float(ally.hp) / float(ally.max_hp)
		for index: int in range(selected_allies.size()):
			var existing: Variant = selected_allies[index]
			if not _is_valid_unit(existing):
				insert_index = index
				break
			var existing_ratio: float = float(existing.hp) / float(existing.max_hp)
			if ratio < existing_ratio:
				insert_index = index
				break
		selected_allies.insert(insert_index, ally)
		while selected_allies.size() > safe_count:
			selected_allies.remove_at(selected_allies.size() - 1)

	return selected_allies


func get_outgoing_heal_multiplier(unit: Variant) -> float:
	if not _is_valid_unit(unit):
		return 1.0

	var multiplier: float = maxf(0.0, float(unit.active_heal_multiplier))
	if unit.passive_id == PASSIVE_BENEVOLENCE:
		multiplier *= BENEVOLENCE_HEAL_MULTIPLIER_STAR_3 if _is_star_3(unit) else BENEVOLENCE_HEAL_MULTIPLIER
	elif unit.passive_id == PASSIVE_ENEMY_DARK_BLESSING:
		multiplier *= ENEMY_DARK_BLESSING_HEAL_MULTIPLIER

	return multiplier


func get_active_skill_heal_multiplier(unit: Variant) -> float:
	if not _is_valid_unit(unit):
		return 1.0

	return get_outgoing_heal_multiplier(unit) * (1.0 + maxf(0.0, float(unit.skill_power)))


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


func _apply_ally_attack_and_mana_regen_bonus(unit: Variant, attack_bonus: float, mana_regen_bonus: float) -> void:
	var source_key: String = _get_modifier_source_key("passive:" + str(unit.passive_id) + ":ally_bonus", unit)
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		if attack_bonus != 0.0:
			_apply_runtime_percent_modifier(ally, source_key, "attack_damage", attack_bonus)
		if mana_regen_bonus != 0.0:
			_apply_runtime_percent_modifier(ally, source_key, "mana_regen_per_second", mana_regen_bonus)
		ally.update_info_display()


func _apply_runtime_flat_modifier(unit: Variant, source_key: String, stat_name: String, value: float) -> void:
	_apply_runtime_stat_modifier(unit, source_key, stat_name, StatModifier.STAGE_RUNTIME_FLAT, value)


func _apply_runtime_percent_modifier(unit: Variant, source_key: String, stat_name: String, value: float) -> void:
	_apply_runtime_stat_modifier(unit, source_key, stat_name, StatModifier.STAGE_RUNTIME_PERCENT, value)


func _apply_runtime_stat_modifier(unit: Variant, source_key: String, stat_name: String, stage: String, value: float) -> void:
	if not _is_valid_unit(unit) or stat_name.strip_edges() == "":
		return

	if is_zero_approx(value):
		return

	var clean_source: String = source_key.strip_edges()
	if clean_source == "":
		clean_source = "passive:runtime"

	if unit.has_method("add_stat_modifier"):
		unit.add_stat_modifier({
			"modifier_id": clean_source + ":" + stat_name + ":" + stage,
			"source_key": clean_source,
			"stat_name": stat_name,
			"stage": stage,
			"value": value,
		})
		return

	var current_value: Variant = unit.get(stat_name)
	if current_value == null:
		return

	match stage:
		StatModifier.STAGE_RUNTIME_FLAT:
			unit.set(stat_name, float(current_value) + value)
		StatModifier.STAGE_RUNTIME_PERCENT:
			unit.set(stat_name, float(current_value) * (1.0 + value))


func _get_modifier_source_key(prefix: String, source_unit: Variant) -> String:
	var source_id: String = ""
	if _is_valid_unit(source_unit):
		source_id = str(source_unit.unit_id)
		if source_id == "" or source_id == "0":
			source_id = str(source_unit.get_instance_id())

	return prefix + ":" + source_id


func _apply_iron_oath_battle_start(hero: Variant) -> void:
	if not _is_valid_unit(hero) or not hero.is_alive:
		return

	var defense_bonus: float = 15.0 + 0.1 * float(hero.defense)
	var tank_shield_base: float = 20.0 + float(hero.defense)
	for ally_value: Variant in hero.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		if _is_frontline_ally(hero, ally):
			_apply_status_effect(ally, HERO_IRON_FRONTLINE_DEFENSE_EFFECT, StatusEffectFactory.EFFECT_TYPE_STAT_ADD, hero, HERO_IRON_BATTLE_LONG_DURATION, 0.0, defense_bonus, "defense", {
				"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
				"polarity": StatusEffectFactory.POLARITY_POSITIVE,
				"category": StatusEffectFactory.CATEGORY_AURA,
			})
			if _hero_has_upgrade(hero, "iron_heavy_formation"):
				_increase_runtime_max_hp(ally, 0.20)
			if _is_tank_like_unit(ally):
				var shield_amount: int = maxi(1, int(round(tank_shield_base + 0.1 * float(ally.max_hp))))
				ally.add_shield(shield_amount, hero)

		if _hero_has_upgrade(hero, "iron_shield_training"):
			ally.set_meta(HERO_SHIELD_RECEIVED_MULTIPLIER_META, 1.15)
		if _hero_has_upgrade(hero, "iron_line_echo"):
			ally.set_meta(HERO_IRON_LINE_ECHO_ENABLED_META, true)
			ally.set_meta(HERO_IRON_LINE_ECHO_AMOUNT_META, 10.0)
			ally.set_meta(HERO_IRON_LINE_ECHO_COOLDOWN_META, 2.0)

	if _hero_has_upgrade(hero, "iron_guard_synergy"):
		var guard_count: int = _count_tank_like_allies(hero)
		if guard_count > 0:
			for ally_value: Variant in hero.ally_units:
				var ally: Variant = ally_value
				if _is_valid_unit(ally) and ally.is_alive:
					_apply_status_effect(ally, HERO_IRON_GUARD_SYNERGY_EFFECT, StatusEffectFactory.EFFECT_TYPE_STAT_ADD, hero, HERO_IRON_BATTLE_LONG_DURATION, 0.0, float(guard_count * 10), "defense", {
						"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
						"polarity": StatusEffectFactory.POLARITY_POSITIVE,
						"category": StatusEffectFactory.CATEGORY_AURA,
					})


func _apply_arcane_mentor_battle_start(hero: Variant) -> void:
	if not _is_valid_unit(hero) or not hero.is_alive:
		return

	for ally_value: Variant in hero.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		if _hero_has_upgrade(hero, "arcane_mana_surge"):
			_apply_runtime_percent_modifier(ally, _get_modifier_source_key("hero_upgrade:arcane_mana_surge", hero), "mana_regen_per_second", 0.10)
		if _hero_has_upgrade(hero, "arcane_elemental_overload") and _is_elemental_overload_unit(ally):
			ally.add_battle_attack_bonus_percent(0.12)
		ally.update_info_display()


func _apply_bloodshadow_hunter_battle_start(hero: Variant) -> void:
	if not _is_valid_unit(hero) or not hero.is_alive:
		return

	for ally_value: Variant in hero.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		if _hero_has_upgrade(hero, "blood_lethal_instinct"):
			_apply_runtime_flat_modifier(ally, _get_modifier_source_key("hero_upgrade:blood_lethal_instinct", hero), "crit_chance", 0.08)
		if _hero_has_upgrade(hero, "blood_hunter_instinct") and (_is_assassin_unit(ally) or _is_archer_unit(ally)):
			_apply_runtime_flat_modifier(ally, _get_modifier_source_key("hero_upgrade:blood_hunter_instinct", hero), "crit_damage_multiplier", 0.30)
		ally.update_info_display()

		_mark_bloodshadow_target(hero)


		if not _is_valid_unit(hero) or not hero.is_alive:
			return

	for ally_value: Variant in hero.ally_units:
			var ally: Variant = ally_value
			if not _is_valid_unit(ally) or not ally.is_alive:
				continue

			if _is_summon_unit(ally):
				_increase_runtime_max_hp(ally, BONEWEAVER_BONE_TIDE_HP_BONUS)
				ally.add_battle_attack_bonus_percent(BONEWEAVER_BONE_TIDE_ATK_BONUS)
				if _hero_has_upgrade(hero, "skeleton_vigor"):
					_increase_runtime_max_hp(ally, 0.25)
				if _hero_has_upgrade(hero, "bone_spike_armor"):
					ally.set_meta("bone_thorns_ratio", 0.10)
				if _hero_has_upgrade(hero, "skeletal_fortitude"):
					ally.set_meta("summon_aoe_defense", 0.20)

			ally.update_info_display()

			if _hero_has_upgrade(hero, "grave_caller"):
				hero.set_meta("summon_cap_bonus", int(hero.get_meta("summon_cap_bonus", 0)) + 1)



func _apply_iron_unbroken_line(unit: Variant, incoming_life_damage: int) -> void:
	if not _is_valid_unit(unit) or incoming_life_damage <= 0:
		return

	if unit.team_id != 1 or unit.max_hp <= 0:
		return

	if not _is_frontline_ally(unit, unit):
		return

	if bool(unit.get_meta(HERO_IRON_UNBROKEN_LINE_META, false)):
		return

	var iron_hero: Variant = _find_team_hero(unit, HERO_ID_IRON_OATH_COMMANDER)
	if not _is_valid_unit(iron_hero):
		return

	var old_ratio: float = float(unit.hp) / float(unit.max_hp)
	var new_ratio: float = float(maxi(unit.hp - incoming_life_damage, 0)) / float(unit.max_hp)
	if old_ratio > 0.40 and new_ratio <= 0.40:
		unit.set_meta(HERO_IRON_UNBROKEN_LINE_META, true)
		var missing_after_damage: int = maxi(0, int(unit.max_hp) - maxi(unit.hp - incoming_life_damage, 0))
		unit.add_shield(missing_after_damage, iron_hero)
		if _hero_has_upgrade(iron_hero, "iron_line_echo"):
			unit.restore_mana(30.0, iron_hero)


func _apply_blood_mark_attack_landed(attacker: Variant, target: Variant) -> void:
	if not _is_valid_unit(attacker) or not _is_valid_unit(target):
		return

	if attacker.team_id != 1 or target.team_id != 2:
		return

	var blood_hero: Variant = _find_team_hero(attacker, HERO_ID_BLOODSHADOW_HUNTER)
	if not _is_valid_unit(blood_hero):
		return

	if not _is_marked_by_team(target, attacker.team_id):
		return

	if _hero_has_upgrade(blood_hero, "blood_hunt_pace"):
		attacker.restore_mana(5.0, blood_hero)


func _apply_bloodshadow_harvest(attacker: Variant, target: Variant) -> void:
	var blood_hero: Variant = _find_team_hero(attacker, HERO_ID_BLOODSHADOW_HUNTER)
	if not _is_valid_unit(blood_hero):
		return

	var upgraded_harvest: bool = _hero_has_upgrade(blood_hero, "blood_continuous_harvest")
	var heal_amount: int = HERO_BLOOD_HARVEST_HEAL_UPGRADED if upgraded_harvest else HERO_BLOOD_HARVEST_HEAL
	var mana_amount: float = HERO_BLOOD_HARVEST_MANA_UPGRADED if upgraded_harvest else HERO_BLOOD_HARVEST_MANA
	attacker.heal(heal_amount, blood_hero)
	attacker.restore_mana(mana_amount, blood_hero)

	if _is_assassin_unit(attacker) or _is_archer_unit(attacker):
		_apply_status_effect(attacker, HERO_BLOOD_HARVEST_CRIT_EFFECT, StatusEffectFactory.EFFECT_TYPE_STAT_ADD, blood_hero, HERO_BLOOD_HARVEST_DURATION, 0.0, HERO_BLOOD_HARVEST_CRIT_BONUS, "crit_chance", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_STAT,
		})
		if _hero_has_upgrade(blood_hero, "blood_shadow_shelter"):
			attacker.add_shield(25, blood_hero)

	if _hero_has_upgrade(blood_hero, "blood_continuous_harvest"):
		_apply_status_effect(attacker, HERO_BLOOD_HARVEST_HASTE_EFFECT, StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, blood_hero, HERO_BLOOD_HARVEST_DURATION, 0.0, 0.85, "attack_interval", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_POSITIVE,
			"category": StatusEffectFactory.CATEGORY_STAT,
		})

	if _is_marked_by_team(target, attacker.team_id) and _hero_has_upgrade(blood_hero, "blood_mark_retarget"):
		_mark_bloodshadow_target(blood_hero)


func _get_hero_active_skill_damage_multiplier(unit: Variant) -> float:
	if not _is_valid_unit(unit) or unit.team_id != 1:
		return 1.0

	var multiplier: float = 1.0
	var arcane_hero: Variant = _find_team_hero(unit, HERO_ID_ARCANE_MENTOR)
	if _is_valid_unit(arcane_hero):
		multiplier *= HERO_SPELL_RESONANCE_MULTIPLIER
		if _hero_has_upgrade(arcane_hero, "arcane_spell_piercing"):
			multiplier *= 1.10
		if _hero_has_upgrade(arcane_hero, "arcane_alchemical_resonance") and _is_field_skill_unit(unit):
			multiplier *= 1.20
		if _hero_has_upgrade(arcane_hero, "arcane_spell_resonance"):
			multiplier *= HERO_SPELL_RESONANCE_UPGRADED_MULTIPLIER / HERO_SPELL_RESONANCE_MULTIPLIER

	return multiplier


func _update_healing_aura(unit: Variant, delta: float) -> void:
	var interval: float = _get_healing_aura_interval(unit)
	var timer: float = interval
	if unit.has_meta(META_HEALING_AURA_TIMER):
		timer = float(unit.get_meta(META_HEALING_AURA_TIMER))

	timer -= delta
	while timer <= 0.0:
		_apply_healing_aura(unit)
		timer += interval

	unit.set_meta(META_HEALING_AURA_TIMER, timer)


func _apply_healing_aura(unit: Variant) -> void:
	var radius: float = HEALING_AURA_RADIUS_STAR_3 if _is_star_3(unit) else HEALING_AURA_RADIUS
	var base_heal: float = HEALING_AURA_BASE_HEAL_STAR_3 if _is_star_3(unit) else HEALING_AURA_BASE_HEAL
	var attack_ratio: float = HEALING_AURA_ATTACK_RATIO_STAR_3 if _is_star_3(unit) else HEALING_AURA_ATTACK_RATIO
	var heal_amount: int = maxi(1, int(round(base_heal + float(unit.attack_damage) * attack_ratio)))
	var targets: Array = aoe_resolver.get_ally_units_in_radius(unit, unit.global_position, radius)
	aoe_resolver.heal_aoe(unit, targets, heal_amount)
	if not targets.is_empty():
		_create_visual_field(unit, unit.global_position, radius, INSTANT_AOE_VISUAL_DURATION, HEALING_AURA_VISUAL_COLOR)
	if unit.unit_feedback != null:
		unit.unit_feedback.play_skill_feedback(unit, "Healing Aura")


func _apply_cleaving_edge(unit: Variant, target: Variant) -> void:
	if not _is_valid_unit(target):
		return


	var attack_range: float = maxf(1.0, float(unit.attack_range))
	var sector_radius: float = attack_range
	var damage_ratio: float = CLEAVING_EDGE_DAMAGE_RATIO_STAR_3 if _is_star_3(unit) else CLEAVING_EDGE_DAMAGE_RATIO
	var cleave_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_ratio)))

	var direction: Vector2 = (target.global_position - unit.global_position).normalized()
	var shape_data: Dictionary = {
		"shape_type": "sector",
		"origin": unit.global_position,
		"direction": direction,
		"radius": sector_radius,
		"angle_degrees": CLEAVING_EDGE_SECTOR_ANGLE,
	}
	var targets: Array = aoe_resolver.get_enemy_units_in_shape(unit, shape_data, [target])

	# Always show visual for player feedback, even if no extra targets hit
	_create_aoe_shape_visual(unit, shape_data, INSTANT_AOE_VISUAL_DURATION, CLEAVING_EDGE_VISUAL_COLOR)

	if targets.is_empty():
		return

	var hit_count: int = aoe_resolver.deal_aoe_damage(unit, targets, cleave_damage, true)
	DEBUG_LOG_SCRIPT.combat(unit.display_name + " cleaving edge: " + str(hit_count) + " targets hit for " + str(cleave_damage) + " damage each")
	if hit_count > 0 and unit.unit_feedback != null:
		unit.unit_feedback.play_skill_feedback(unit, "Cleaving Edge")

	if unit.unit_feedback != null:
		unit.unit_feedback.play_skill_feedback(unit, "Cleaving Edge")


func _apply_unstable_bomb(unit: Variant, target: Variant) -> void:
	if not _is_valid_unit(target):
		return

	var trigger_attacks: int = UNSTABLE_BOMB_ATTACKS_STAR_3 if _is_star_3(unit) else UNSTABLE_BOMB_ATTACKS
	if trigger_attacks <= 0 or int(unit.attack_count) <= 0 or int(unit.attack_count) % trigger_attacks != 0:
		return

	var radius: float = UNSTABLE_BOMB_RADIUS_STAR_3 if _is_star_3(unit) else UNSTABLE_BOMB_RADIUS
	var damage_ratio: float = UNSTABLE_BOMB_DAMAGE_RATIO_STAR_3 if _is_star_3(unit) else UNSTABLE_BOMB_DAMAGE_RATIO
	var splash_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_ratio)))
	var targets: Array = aoe_resolver.get_enemy_units_in_radius(unit, target.global_position, radius, [target])
	if targets.is_empty():
		return

	_create_visual_field(unit, target.global_position, radius, INSTANT_AOE_VISUAL_DURATION, UNSTABLE_BOMB_VISUAL_COLOR)
	if aoe_resolver.deal_aoe_damage(unit, targets, splash_damage, true) <= 0:
		return

	if unit.unit_feedback != null:
		unit.unit_feedback.play_skill_feedback(unit, "Unstable Bomb")


func _get_healing_aura_interval(unit: Variant) -> float:
	return HEALING_AURA_INTERVAL_STAR_3 if _is_star_3(unit) else HEALING_AURA_INTERVAL


func _create_visual_field(unit: Variant, center_position: Vector2, radius: float, duration: float, color: Color) -> int:
	if not _is_valid_unit(unit):
		return -1

	var battle_root: Node = unit.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return -1

	if not battle_root.has_method("create_visual_field"):
		return -1

	return int(battle_root.create_visual_field(center_position, radius, duration, color))


func _create_status_field(unit: Variant, center_position: Vector2, radius: float, duration: float, tick_interval: float, status_data: Dictionary, color: Color) -> int:
	if not _is_valid_unit(unit):
		return -1

	var battle_root: Node = unit.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return -1

	if not battle_root.has_method("create_status_field"):
		return -1

	return int(battle_root.create_status_field(unit, center_position, radius, duration, tick_interval, status_data, color))


func _create_aoe_shape_visual(unit: Variant, shape_data: Dictionary, duration: float, color: Color) -> void:
	if not _is_valid_unit(unit):
		return
	var battle_root: Node = unit.get_parent() as Node
	if battle_root == null or not is_instance_valid(battle_root):
		return
	if not battle_root.has_method("create_aoe_shape_visual"):
		return
	battle_root.create_aoe_shape_visual(shape_data, color, duration)


func _apply_enemy_colossus_threshold_shields(unit: Variant, incoming_damage: int) -> void:
	if incoming_damage <= 0 or unit.max_hp <= 0:
		return

	var old_ratio: float = float(unit.hp) / float(unit.max_hp)
	var new_ratio: float = float(maxi(unit.hp - incoming_damage, 0)) / float(unit.max_hp)
	_apply_enemy_colossus_threshold_shield(unit, old_ratio, new_ratio, 0.70, "enemy_colossus_threshold_70")
	_apply_enemy_colossus_threshold_shield(unit, old_ratio, new_ratio, 0.40, "enemy_colossus_threshold_40")
	_apply_enemy_colossus_threshold_shield(unit, old_ratio, new_ratio, 0.20, "enemy_colossus_threshold_20")


func _apply_enemy_colossus_threshold_shield(unit: Variant, old_ratio: float, new_ratio: float, threshold: float, meta_key: String) -> void:
	if old_ratio <= threshold or new_ratio > threshold:
		return

	if unit.has_meta(meta_key) and bool(unit.get_meta(meta_key)):
		return

	unit.set_meta(meta_key, true)
	unit.add_shield(ENEMY_COLOSSUS_THRESHOLD_SHIELD, unit)


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


func _find_team_hero(unit: Variant, hero_id: String) -> Variant:
	if not _is_valid_unit(unit):
		return null

	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		if not bool(ally.get_meta(HERO_META_IS_HERO, false)):
			continue

		if str(ally.get_meta(HERO_META_HERO_ID, "")) == hero_id:
			return ally

	return null


func _hero_has_upgrade(hero: Variant, upgrade_id: String) -> bool:
	if not _is_valid_unit(hero) or upgrade_id == "":
		return false

	if not hero.has_meta(HERO_META_UPGRADE_IDS):
		return false

	var upgrade_ids: Variant = hero.get_meta(HERO_META_UPGRADE_IDS)
	if not (upgrade_ids is Array):
		return false

	var upgrade_array: Array = upgrade_ids as Array
	return upgrade_array.has(upgrade_id)


func _increase_runtime_max_hp(unit: Variant, percent: float) -> void:
	if not _is_valid_unit(unit) or percent <= 0.0:
		return

	var hp_bonus: int = maxi(1, int(round(float(unit.max_hp) * percent)))
	if unit.has_method("apply_runtime_stat_bonus"):
		unit.apply_runtime_stat_bonus("max_hp", float(hp_bonus), true)
	else:
		unit.max_hp += hp_bonus
		unit.hp += hp_bonus
		unit._update_hp_bar()
		unit.update_info_display()


func _count_tank_like_allies(hero: Variant) -> int:
	if not _is_valid_unit(hero):
		return 0

	var count: int = 0
	for ally_value: Variant in hero.ally_units:
		var ally: Variant = ally_value
		if _is_valid_unit(ally) and ally.is_alive and _is_tank_like_unit(ally):
			count += 1

	return count


func _mark_bloodshadow_target(hero: Variant) -> void:
	if not _is_valid_unit(hero):
		return

	var target: Variant = _find_bloodshadow_mark_target(hero)
	if not _is_valid_unit(target):
		return

	_clear_bloodshadow_marks(hero)
	target.set_meta(HERO_BLOOD_MARK_META, true)
	target.set_meta(HERO_BLOOD_MARK_TEAM_META, int(hero.team_id))
	if _hero_has_upgrade(hero, "blood_weakness_exposed"):
		_apply_status_effect(target, HERO_BLOOD_MARK_DEFENSE_EFFECT, StatusEffectFactory.EFFECT_TYPE_STAT_ADD, hero, -1.0, 0.0, -20.0, "defense", {
			"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
			"duration_mode": StatusEffectFactory.DURATION_MODE_NONE,
			"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
			"category": StatusEffectFactory.CATEGORY_MARK,
		})
		target.set_meta(HERO_BLOOD_MARK_DEFENSE_META, true)
	if hero.unit_feedback != null:
		hero.unit_feedback.play_skill_feedback(hero, "Hunt Mark")


func _clear_bloodshadow_marks(hero: Variant) -> void:
	if not _is_valid_unit(hero):
		return

	for enemy_value: Variant in hero.enemy_units:
		var enemy: Variant = enemy_value
		if not _is_valid_unit(enemy):
			continue

		if _is_marked_by_team(enemy, hero.team_id):
			enemy.set_meta(HERO_BLOOD_MARK_META, false)
			enemy.remove_meta(HERO_BLOOD_MARK_TEAM_META)
			if enemy.has_method("remove_status_effect"):
				enemy.remove_status_effect(HERO_BLOOD_MARK_DEFENSE_EFFECT)
			if enemy.has_meta(HERO_BLOOD_MARK_DEFENSE_META):
				enemy.remove_meta(HERO_BLOOD_MARK_DEFENSE_META)


func _find_bloodshadow_mark_target(hero: Variant) -> Variant:
	var candidates: Array = []
	for enemy_value: Variant in hero.enemy_units:
		var enemy: Variant = enemy_value
		if not _is_valid_unit(enemy) or not enemy.is_alive:
			continue
		if _is_marked_by_team(enemy, hero.team_id):
			continue

		candidates.append(enemy)

	if candidates.is_empty():
		return null

	candidates.sort_custom(Callable(self, "_sort_mark_targets"))
	var top_band: Array = []
	var best_rank: int = _get_enemy_backline_rank(candidates[0])
	for candidate: Variant in candidates:
		if _get_enemy_backline_rank(candidate) == best_rank:
			top_band.append(candidate)

	if top_band.is_empty():
		return candidates[0]

	return top_band[randi_range(0, top_band.size() - 1)]


func _sort_mark_targets(a: Variant, b: Variant) -> bool:
	var rank_a: int = _get_enemy_backline_rank(a)
	var rank_b: int = _get_enemy_backline_rank(b)
	if rank_a == rank_b:
		return int(a.unit_id) < int(b.unit_id)

	return rank_a < rank_b


func _get_enemy_backline_rank(enemy: Variant) -> int:
	if not _is_valid_unit(enemy):
		return 999

	if enemy.battle_board != null and is_instance_valid(enemy.battle_board) and enemy.battle_board.has_method("world_to_grid"):
		var cell: Vector2i = enemy.battle_board.world_to_grid(enemy.position)
		return abs(14 - cell.x)

	return int(round(-enemy.position.x))


func _is_marked_by_team(target: Variant, team_id: int) -> bool:
	if not _is_valid_unit(target):
		return false

	return bool(target.get_meta(HERO_BLOOD_MARK_META, false)) and int(target.get_meta(HERO_BLOOD_MARK_TEAM_META, -1)) == team_id


func _find_random_alive_ally(unit: Variant, include_self: bool) -> Variant:
	if not _is_valid_unit(unit):
		return null

	var candidates: Array = []
	for ally_value: Variant in unit.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue
		if not include_self and ally == unit:
			continue
		candidates.append(ally)

	if candidates.is_empty():
		return null

	return candidates[randi_range(0, candidates.size() - 1)]


func _is_tank_like_unit(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	var unit_type: String = str(unit.unit_type).to_lower()
	return str(unit.role) == "tank" \
		or unit_type == "warrior" \
		or unit_type == "tank" \
		or unit_type == "greatsword_knight" \
		or unit_type == "guardian_captain" \
		or unit_type == "starforged_vanguard" \
		or unit_type == "hero_iron_oath_commander"


func _is_archer_unit(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	return str(unit.unit_type).to_lower() == "archer"


func _is_assassin_unit(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	var unit_type: String = str(unit.unit_type).to_lower()
	return unit_type == "assassin" or unit_type == "nightblade_captain"


func _is_skill_damage_unit(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	var unit_type: String = str(unit.unit_type).to_lower()
	return unit_type == "mage" \
		or unit_type == "alchemist" \
		or unit_type == "bomb_thrower" \
		or unit_type == "plague_caster" \
		or unit_type == "wind_chanter" \
		or unit_type == "arcane_artillerist" \
		or unit_type == "venom_matriarch" \
		or unit_type == "prism_weaver" \
		or unit_type == "hero_arcane_mentor"


func _is_field_skill_unit(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	var active_skill_id: String = str(unit.active_skill_id)
	return active_skill_id == "acid_field" or active_skill_id == "toxic_cloud"


func _is_elemental_overload_unit(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false

	var unit_type: String = str(unit.unit_type).to_lower()
	return unit_type == "mage" or unit_type == "alchemist" or unit_type == "bomb_thrower"


func _is_frontline_ally(source: Variant, ally: Variant) -> bool:
	if not _is_valid_unit(source) or not _is_valid_unit(ally):
		return false

	if ally.battle_board != null and is_instance_valid(ally.battle_board) and ally.battle_board.has_method("world_to_grid"):
		var cell: Vector2i = ally.battle_board.world_to_grid(ally.position)
		if ally.team_id == 1:
			return cell.x == 5 or cell.x == 6
		if ally.team_id == 2:
			return cell.x == 8 or cell.x == 9

	return str(ally.role) == "tank"


func _is_valid_unit(unit: Variant) -> bool:
	return unit != null and is_instance_valid(unit)


func _is_star_3(unit: Variant) -> bool:
	return _is_valid_unit(unit) and int(unit.star) == 3


func _apply_boneweaver_battle_start(hero: Variant) -> void:
	if not _is_valid_unit(hero) or not hero.is_alive:
		return

	for ally_value: Variant in hero.ally_units:
		var ally: Variant = ally_value
		if not _is_valid_unit(ally) or not ally.is_alive:
			continue

		if _is_summon_unit(ally):
			_increase_runtime_max_hp(ally, BONEWEAVER_BONE_TIDE_HP_BONUS)
			ally.add_battle_attack_bonus_percent(BONEWEAVER_BONE_TIDE_ATK_BONUS)
			if _hero_has_upgrade(hero, "skeleton_vigor"):
				_increase_runtime_max_hp(ally, 0.25)
			if _hero_has_upgrade(hero, "bone_spike_armor"):
				ally.set_meta("bone_thorns_ratio", 0.10)
			if _hero_has_upgrade(hero, "skeletal_fortitude"):
				ally.set_meta("summon_aoe_defense", 0.20)

		ally.update_info_display()

	if _hero_has_upgrade(hero, "grave_caller"):
		hero.set_meta("summon_cap_bonus", int(hero.get_meta("summon_cap_bonus", 0)) + 1)


func _is_summon_unit(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false
	return bool(unit.get_meta("is_summon", false))


func _try_apply_undying_thralls(unit: Variant, resolved_damage: int) -> int:
	if not _is_valid_unit(unit) or resolved_damage <= 0:
		return resolved_damage

	if unit.hp <= 0:
		return resolved_damage

	if resolved_damage < unit.hp:
		return resolved_damage

	if not _is_summon_unit(unit):
		return resolved_damage

	if bool(unit.get_meta(BONEWEAVER_UNDYING_TRIGGERED_META, false)):
		return resolved_damage

	var bone_hero: Variant = _find_team_hero(unit, HERO_ID_BONEWEAVER)
	if not _is_valid_unit(bone_hero):
		return resolved_damage

	unit.set_meta(BONEWEAVER_UNDYING_TRIGGERED_META, true)
	var invinc_duration: float = BONEWEAVER_UNDYING_INVINCIBILITY_DURATION
	if _hero_has_upgrade(bone_hero, "eternal_thralls"):
		invinc_duration = BONEWEAVER_UNDYING_INVINCIBILITY_DURATION_UPGRADED
	unit.set_meta(BONEWEAVER_UNDYING_INVINCIBLE_META, unit.battle_elapsed_time + invinc_duration)

	return maxi(0, unit.hp - 1)


func _apply_undying_invincibility(unit: Variant, resolved_damage: int) -> int:
	if not _is_valid_unit(unit):
		return resolved_damage

	if not bool(unit.get_meta(BONEWEAVER_UNDYING_INVINCIBLE_META, false)):
		return resolved_damage

	var invinc_until: float = float(unit.get_meta(BONEWEAVER_UNDYING_INVINCIBLE_META, 0.0))
	if unit.battle_elapsed_time < invinc_until:
		return 0

	return resolved_damage


func _try_apply_death_prevention(unit: Variant, resolved_damage: int) -> int:
	if not death_prevention_enabled:
		return resolved_damage
	if not _is_valid_unit(unit) or resolved_damage <= 0:
		return resolved_damage
	if unit.team_id != 1:
		return resolved_damage
	if unit.hp <= 0:
		return resolved_damage
	if resolved_damage < unit.hp:
		return resolved_damage
	if bool(unit.get_meta(DEATH_PREVENTION_TRIGGERED_META, false)):
		return resolved_damage

	unit.set_meta(DEATH_PREVENTION_TRIGGERED_META, true)
	if unit.unit_feedback != null:
		unit.unit_feedback.play_skill_feedback(unit, "永恒誓约")
	return maxi(0, unit.hp - 1)


func _has_enemy_taunted_by(unit: Variant) -> bool:
	if not _is_valid_unit(unit):
		return false
	for enemy_value: Variant in unit.enemy_units:
		var enemy: Variant = enemy_value
		if not _is_valid_unit(enemy):
			continue
		if enemy.control_state != null and enemy.control_state.forced_target == unit:
			return true
	return false


func _get_banner_guard_taunt_count(unit: Variant) -> int:
	if not _is_valid_unit(unit) or unit.passive_id != PASSIVE_BANNER_GUARD:
		return 0
	var count: int = 0
	for enemy_value: Variant in unit.enemy_units:
		var enemy: Variant = enemy_value
		if not _is_valid_unit(enemy):
			continue
		if enemy.control_state != null and enemy.control_state.forced_target == unit:
			count += 1
	return mini(count, BANNER_GUARD_MAX_TAUNT_COUNT)


func _get_boneweaver_summon_damage_bonus(unit: Variant) -> float:
	if not _is_valid_unit(unit) or not _is_summon_unit(unit):
		return 0.0

	var bone_hero: Variant = _find_team_hero(unit, HERO_ID_BONEWEAVER)
	if not _is_valid_unit(bone_hero):
		return 0.0

	var summon_count: int = 0
	for ally_value: Variant in bone_hero.ally_units:
		var ally: Variant = ally_value
		if _is_summon_unit(ally) and ally.is_alive:
			summon_count += 1

	return minf(float(summon_count) * BONEWEAVER_BONE_TIDE_DAMAGE_PER_SUMMON, BONEWEAVER_BONE_TIDE_DAMAGE_CAP)


func _apply_summon_death_echo(unit: Variant) -> void:
	if not _is_valid_unit(unit) or not _is_summon_unit(unit):
		return

	var bone_hero: Variant = _find_team_hero(unit, HERO_ID_BONEWEAVER)
	if not _is_valid_unit(bone_hero):
		return

	if not _hero_has_upgrade(bone_hero, "death_echo"):
		return

	var damage: int = maxi(1, int(round(float(unit.attack_damage) * 0.60)))
	var enemies: Array[Variant] = aoe_resolver.get_enemy_units_in_radius(bone_hero, unit.global_position, 80.0)
	for enemy_value: Variant in enemies:
		var enemy: Variant = enemy_value
		if _is_valid_unit(enemy) and enemy.is_alive:
			enemy.take_damage(damage, bone_hero)


func _apply_dragon_breath_splash(unit: Variant, target: Variant) -> void:
	if not _is_valid_unit(unit) or not unit.is_alive:
		return
	if not _is_valid_unit(target) or not target.is_alive:
		return

	var splash_damage: int = maxi(1, int(round(float(unit.attack_damage) * DRAGON_BREATH_SPLASH_RATIO)))
	var enemies: Array[Variant] = aoe_resolver.get_enemy_units_in_radius(unit, target.global_position, DRAGON_BREATH_SPLASH_RADIUS, [target])
	_create_visual_field(unit, target.global_position, DRAGON_BREATH_SPLASH_RADIUS, INSTANT_AOE_VISUAL_DURATION, DRAGON_BREATH_VISUAL_COLOR)
	for enemy_value: Variant in enemies:
		var enemy: Variant = enemy_value
		if _is_valid_unit(enemy) and enemy.is_alive:
			enemy.take_damage(splash_damage, unit)


func apply_maggot_death_burst(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	var death_position: Vector2 = unit.global_position
	var burst_damage: int = maxi(1, int(round(MAGGOT_DEATH_BURST_BASE_DAMAGE + float(unit.max_hp) * MAGGOT_DEATH_BURST_HP_RATIO)))
	var targets: Array = aoe_resolver.get_enemy_units_in_radius(unit, death_position, MAGGOT_DEATH_BURST_RADIUS)
	_create_visual_field(unit, death_position, MAGGOT_DEATH_BURST_RADIUS, INSTANT_AOE_VISUAL_DURATION, MAGGOT_BURST_VISUAL_COLOR)
	var hit_count: int = aoe_resolver.deal_aoe_damage(unit, targets, burst_damage, false)
	DEBUG_LOG_SCRIPT.combat(unit.display_name + " death burst: " + str(hit_count) + " targets hit for " + str(burst_damage))

	for target_value: Variant in targets:
		var target: Variant = target_value
		if not _is_valid_unit(target) or not target.is_alive:
			continue
		_apply_putrid_mark(unit, target, PUTRID_MARK_DURATION)
		_apply_maggot_venom_stacks(unit, target, MAGGOT_DEATH_BURST_VENOM_STACKS, MAGGOT_DEATH_BURST_VENOM_DURATION)


func apply_frost_slime_death_burst(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	var death_position: Vector2 = unit.global_position
	var radius: float = FROST_SLIME_DEATH_RADIUS_STAR_3 if _is_star_3(unit) else FROST_SLIME_DEATH_RADIUS
	var freeze_duration: float = FROST_SLIME_DEATH_FREEZE_DURATION_STAR_3 if _is_star_3(unit) else FROST_SLIME_DEATH_FREEZE_DURATION
	var slow_duration: float = FROST_SLIME_FIELD_SLOW_DURATION_STAR_3 if _is_star_3(unit) else FROST_SLIME_FIELD_SLOW_DURATION
	var slow_speed: float = FROST_SLIME_FIELD_SLOW_SPEED_STAR_3 if _is_star_3(unit) else FROST_SLIME_FIELD_SLOW_SPEED
	var targets: Array = aoe_resolver.get_enemy_units_in_radius(unit, death_position, radius)
	_create_visual_field(unit, death_position, radius, INSTANT_AOE_VISUAL_DURATION, FROST_SLIME_VISUAL_COLOR)
	for target_value: Variant in targets:
		var target: Variant = target_value
		if _is_valid_unit(target) and target.is_alive:
			status_effect_factory.apply_control_effect(target, "FREEZE", unit, freeze_duration, {
				"effect_id": "frost_slime_death_freeze",
				"stack_group_key": "freeze",
				"source_key": "frost_slime_death",
			})

	_create_status_field(unit, death_position, radius, FROST_SLIME_FIELD_DURATION, FROST_SLIME_FIELD_TICK_INTERVAL, {
		"mode": "control",
		"control_type": "SLOW",
		"duration": slow_duration,
		"options": {
			"effect_id": "frost_slime_field_slow",
			"move_speed_multiplier": slow_speed,
			"stack_group_key": "slow",
			"source_key": "frost_slime_field",
		},
	}, FROST_SLIME_VISUAL_COLOR)


func apply_flame_slime_death_burst(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	var death_position: Vector2 = unit.global_position
	var radius: float = FLAME_SLIME_DEATH_RADIUS_STAR_3 if _is_star_3(unit) else FLAME_SLIME_DEATH_RADIUS
	var damage_ratio: float = FLAME_SLIME_DEATH_DAMAGE_RATIO_STAR_3 if _is_star_3(unit) else FLAME_SLIME_DEATH_DAMAGE_RATIO
	var burn_ratio: float = FLAME_SLIME_ATTACK_BURN_DAMAGE_RATIO_STAR_3 if _is_star_3(unit) else FLAME_SLIME_ATTACK_BURN_DAMAGE_RATIO
	var burst_damage: int = maxi(1, int(round(float(unit.attack_damage) * damage_ratio)))
	var burn_damage: float = maxf(1.0, float(unit.attack_damage) * burn_ratio)
	var targets: Array = aoe_resolver.get_enemy_units_in_radius(unit, death_position, radius)
	_create_visual_field(unit, death_position, radius, INSTANT_AOE_VISUAL_DURATION, FLAME_SLIME_VISUAL_COLOR)
	aoe_resolver.deal_aoe_damage(unit, targets, burst_damage, false)
	_create_status_field(unit, death_position, radius, FLAME_SLIME_FIELD_DURATION, FLAME_SLIME_FIELD_TICK_INTERVAL, {
		"mode": "burning",
		"duration": FLAME_SLIME_ATTACK_BURN_DURATION,
		"damage_per_second": burn_damage,
	}, FLAME_SLIME_VISUAL_COLOR)


func apply_venom_slime_death_pool(unit: Variant) -> void:
	if not _is_valid_unit(unit):
		return

	var death_position: Vector2 = unit.global_position
	var radius: float = VENOM_SLIME_DEATH_RADIUS_STAR_3 if _is_star_3(unit) else VENOM_SLIME_DEATH_RADIUS
	var death_stacks: int = VENOM_SLIME_DEATH_STACKS_STAR_3 if _is_star_3(unit) else VENOM_SLIME_DEATH_STACKS
	var field_stacks: int = VENOM_SLIME_FIELD_STACKS_STAR_3 if _is_star_3(unit) else VENOM_SLIME_FIELD_STACKS
	var targets: Array = aoe_resolver.get_enemy_units_in_radius(unit, death_position, radius)
	_create_visual_field(unit, death_position, radius, INSTANT_AOE_VISUAL_DURATION, VENOM_SLIME_VISUAL_COLOR)
	for target_value: Variant in targets:
		var target: Variant = target_value
		if _is_valid_unit(target) and target.is_alive:
			_apply_maggot_venom_stacks(unit, target, death_stacks, VENOM_STACK_DURATION)

	_create_status_field(unit, death_position, radius, VENOM_SLIME_FIELD_DURATION, VENOM_SLIME_FIELD_TICK_INTERVAL, {
		"effect_id": VENOM_STACK_EFFECT,
		"effect_type": StatusEffectFactory.EFFECT_TYPE_DAMAGE_OVER_TIME,
		"duration": VENOM_STACK_DURATION,
		"tick_interval": STATUS_EFFECT_TICK_INTERVAL,
		"value": VENOM_STACK_DAMAGE,
		"options": {
			"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
			"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
			"category": StatusEffectFactory.CATEGORY_DOT,
			"stack_count": field_stacks,
			"stack_decay_after_duration": true,
			"stack_decay_per_tick": VENOM_STACK_DECAY_PER_TICK,
		},
	}, VENOM_SLIME_VISUAL_COLOR)


func _apply_maggot_venom_stacks(source: Variant, target: Variant, count: int, duration: float) -> void:
	_apply_status_effect(target, VENOM_STACK_EFFECT, StatusEffectFactory.EFFECT_TYPE_DAMAGE_OVER_TIME, source, duration, STATUS_EFFECT_TICK_INTERVAL, VENOM_STACK_DAMAGE, "", {
		"stack_policy": StatusEffectFactory.STACK_POLICY_REFRESH_ONLY,
		"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
		"category": StatusEffectFactory.CATEGORY_DOT,
		"stack_count": count,
		"stack_decay_after_duration": true,
		"stack_decay_per_tick": VENOM_STACK_DECAY_PER_TICK,
	})


func _apply_putrid_mark(source: Variant, target: Variant, duration: float) -> void:
	_apply_status_effect(target, EFFECT_PUTRID_MARK, StatusEffectFactory.EFFECT_TYPE_STAT_MULTIPLY, source, duration, 0.0, PUTRID_MARK_VALUE, "damage_taken_multiplier", {
		"stack_policy": StatusEffectFactory.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH,
		"polarity": StatusEffectFactory.POLARITY_NEGATIVE,
		"category": StatusEffectFactory.CATEGORY_MARK,
	})


func has_putrid_mark(target: Variant) -> bool:
	if not _is_valid_unit(target) or not target.is_alive:
		return false
	if target.has_method("get_status_effect_count"):
		return int(target.get_status_effect_count(EFFECT_PUTRID_MARK)) > 0
	return false


func _apply_frost_arrow(unit: Variant, target: Variant) -> void:
	var dur: float = FROST_ARROW_DURATION_3STAR if _is_star_3(unit) else FROST_ARROW_DURATION
	var speed_mult: float = FROST_ARROW_SPEED_2STAR if int(unit.star) >= 2 else FROST_ARROW_SPEED
	status_effect_factory.apply_control_effect(target, "SLOW", unit, dur, {
		"effect_id": "frost_arrow_slow", "move_speed_multiplier": speed_mult,
		"stack_group_key": "slow", "source_key": "frost_arrow_passive",
	})
