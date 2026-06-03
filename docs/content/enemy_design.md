# 敌人设计文档

更新时间：2026-06-02

本文档统一记录所有敌人（普通、精英、BOSS）的设计定位、机制和实现入口。精确数值以 `data/enemies/*.tres` 和 `docs/content_reference.md` 为准。

---

## 一、普通敌人

### 史莱姆系列

设计目标：提供低门槛、易识别的敌方变体，覆盖前排承伤、控制、燃烧、剧毒和分裂占场。复用现有 `StatusEffectFactory`、`UnitControlState`、`burning`、`venom_stack`、`FieldEffectManager` 与 `SummonManager`。

| 单位 | unit_type | 阶等 | 定位 | 被动 | 主动 |
| --- | --- | --- | --- | --- | --- |
| 普通史莱姆 / Common Slime | `enemy_common_slime` | NORMAL | 前排小怪 | `slime_body` | `slime_bounce` |
| 冰霜史莱姆 / Frost Slime | `enemy_frost_slime` | NORMAL | 控制辅助 | `frost_burst` | `frost_explosion` |
| 火焰史莱姆 / Flame Slime | `enemy_flame_slime` | NORMAL | 持续伤害 | `flame_burst` | `fire_splash` |
| 毒液史莱姆 / Venom Slime | `enemy_venom_slime` | NORMAL | 剧毒叠层 | `venom_pool` | `toxic_blob` |

#### 技能要点

**普通史莱姆**：`slime_body` 使受到的普通攻击伤害降低 8%（三星 15%），只在 `CombatResolver.resolve_basic_attack_hit()` 中处理。`slime_bounce` 对当前目标造成 160%/200% 攻击力技能伤害。

**冰霜史莱姆**：`frost_burst` 死亡时冻结周围目标并生成 3 秒寒霜区域，每秒施加 SLOW（80%/70% 行动速率）。`frost_explosion` 以目标为中心范围伤害+迟缓。

**火焰史莱姆**：`flame_burst` 普攻施加 burning，死亡爆燃+3 秒熔岩区域。`fire_splash` 范围伤害+燃烧。

**毒液史莱姆**：`venom_pool` 普攻施加 venom_stack，死亡爆发+5 秒毒液区域。`toxic_blob` 范围伤害+剧毒。

### 基础普通敌人

以下敌人构成遭遇池的基础变体，覆盖前排承伤、远程输出、法术爆发、治疗和团队增益等定位。

| 单位 | unit_type | 定位 | 被动 | 主动 |
| --- | --- | --- | --- | --- |
| 盾卫 / Shield Guard | `enemy_shield_guard` | tank | `enemy_shield_wall` | `enemy_guard_stance` |
| 石背巨兽 / Stoneback Beast | `enemy_stoneback_beast` | tank | `enemy_stone_skin` | `enemy_harden` |
| 弩手掠袭者 / Crossbow Raider | `enemy_crossbow_raider` | damage | `enemy_steady_aim` | `enemy_power_shot` |
| 哥布林杂兵 / Goblin Grunt | `enemy_goblin_grunt` | damage | `enemy_goblin_opportunist` | `enemy_dirty_stab` |
| 烈焰小鬼 / Flame Imp | `enemy_flame_imp` | damage | `enemy_flame_focus` | `enemy_firebolt` |
| 黑暗侍僧 / Dark Acolyte | `enemy_dark_acolyte` | support | `enemy_dark_blessing` | `enemy_dark_heal` |
| 战鼓手 / War Drummer | `enemy_war_drummer` | support | `enemy_war_rhythm` | `enemy_drum_shield` |
| 唤墓者 / Grave Caller | `enemy_grave_caller` | support | `enemy_grave_command` | `enemy_raise_skeletons` |
| 运骨者 / Bone Carrier | `enemy_bone_carrier` | tank | `enemy_death_summons_skeletons` | `enemy_harden` |
| 傀儡缚师 / Puppet Binder | `enemy_puppet_binder` | support | `enemy_kill_summons_skeletons` | `enemy_puppet_mark` |

**设计要点**：
- **盾卫**：基础前排，护盾减伤，教学玩家穿透护盾或集火。
- **石背巨兽**：高生命高防御低移速，50% 血以下防御大幅提升，考验持续输出能力。
- **弩手掠袭者**：基础远程 DPS，射程 150，使用真实弹道。
- **哥布林杂兵**：基础近战杂兵，低生命高移速，普攻低生命目标时伤害提高，主动技能为单体脏刺。
- **烈焰小鬼**：玻璃大炮法师，生命低但爆发高，优先击杀教学。
- **黑暗侍僧**：基础敌方治疗，无防御，优先击杀降低敌方续航。
- **战鼓手**：全队攻击/护盾增益，高优先级目标。
- **唤墓者**：召唤型辅助，召唤骷髅制造数量压力，AoE/顺劈为有效反制。
- **运骨者**：死亡触发召唤（2 骷髅），前排坦克转化型。
- **傀儡缚师**：标记型召唤辅助，标记目标死亡后召唤傀儡并施加 +15% 承伤 debuff。

### 蛆虫系列

设计目标：统一使用 `venom_stack` 做持续伤害，`putrid_mark` 做增伤标记，不新增 DoT 类型。

#### 巨型蛆虫 / Giant Maggot

- **定位**：NORMAL 输出
- **被动 `maggot_death_burst`**：死亡 AoE（半径 90，`35 + max_hp * 0.08`）+ venom_stack 1 层 + putrid_mark 5 秒
- **主动 `septic_spit`**：直接伤害 `attack_damage * 1.2 * skill_power` + venom_stack 2 层 + putrid_mark 6 秒

#### 腐痕 Debuff：putrid_mark

非持续伤害标记，`effect_type = STAT_MULTIPLY`，`stat_name = damage_taken_multiplier`，`value = 1.25`。同源刷新持续时间。蛆虫族技能施加，所有来源伤害受益。

---

## 二、精英敌人

### 巨型史莱姆 / Giant Slime

- **unit_type**：`enemy_giant_slime`
- **阶等**：ELITE
- **定位**：高生命前排坦克
- **被动 `slime_split`**：死亡分裂为 2 个巨型史莱姆，继承 30%/40% 最大生命，攻防减半。`slime_split_count` 限制分裂链深度（2/3 次）。
- **主动 `heavy_bounce`**：140%/170% 攻击力技能伤害 + 8%/12% 最大生命护盾。

### 蛆虫聚合体 / Maggot Amalgam

- **unit_type**：`enemy_elite_maggot_amalgam`
- **阶等**：ELITE
- **定位**：坦克
- **被动 `amalgam_split_birth`**：死亡召唤 4 只 giant_maggot。
- **主动 `putrid_tide`**：扇形 AoE（半径 130，角度 90°），伤害 `attack_damage * 1.4 * skill_power`，有 putrid_mark 目标 ×1.25，施加 venom_stack 2 层 + putrid_mark 5 秒。

### 铁甲巨卫 / Iron Bulwark

- **阶等**：ELITE
- **定位**：承伤前排
- **机制**：开局护盾、护盾破裂减伤、短暂防御提升
- **主动 `enemy_bulwark_slam`**：周围范围伤害 + 短暂眩晕 + 自身加盾

### 冰棘女巫 / Frost Thorn Witch

- **阶等**：ELITE
- **定位**：控制法师
- **机制**：普攻叠加寒霜印记，三层触发冻结
- **主动 `enemy_frost_thorn_burst`**：范围冰伤，冻结目标受到更高伤害

### 血旗督军 / Blood Banner Warlord

- **阶等**：ELITE
- **定位**：团队辅助
- **机制**：存活时提供敌方攻速/回魔光环
- **主动 `enemy_crimson_banner`**：短时间进一步强化全体敌方单位

### 反射甲虫 / Mirror Carapace Beetle

- **阶等**：ELITE
- **定位**：反制精英
- **机制**：护盾存在时反射主动技能伤害
- **主动 `enemy_refraction_shell`**：重新获得护盾并强化接下来数次普攻

### 铁壁守卫 / Elite Iron Warden

- **阶等**：ELITE
- **定位**：承伤前排
- **被动 `enemy_iron_body`**：受到护盾后的生命伤害降低 18%
- **主动 `enemy_fortify_allies`**：自身获得 60 护盾，所有友军获得 20 护盾
- **设计要点**：精英前排+团队护盾，高防御（45）高生命（420），破盾或穿透防御是关键

### 影刃收割者 / Elite Shadow Reaper

- **阶等**：ELITE
- **定位**：收割刺客
- **被动 `enemy_reaper_execute`**：攻击生命低于 45% 的目标时普攻伤害提高 35%
- **主动 `enemy_shadow_cleave`**：造成 260% 攻击力技能伤害，击杀恢复 30 生命
- **设计要点**：高移速（155）高攻速（0.85s），索敌模式 LOWEST_HP，高暴击（18% / x1.80），对低血量单位威胁极大

### 血谕者 / Elite Blood Oracle

- **阶等**：ELITE
- **定位**：团队续航
- **被动 `enemy_blood_ritual`**：存活时敌方单位击杀玩家单位会使击杀者恢复 25 生命
- **主动 `enemy_oracle_blessing`**：治疗低生命友军 50 + 150% 攻击力并提供 20 护盾
- **设计要点**：精英治疗+击杀惩罚，持久战中的高优先级目标

---

## 三、BOSS

### 树妖领主 / Treant Overlord

- **定位**：高生命、恢复与控制型 BOSS
- **被动 `boss_ancient_vitality`**：周期恢复、低血强化恢复、首次低血护盾
- **主动 `boss_root_sweep`**：大范围扇形根须，造成技能伤害并眩晕

### 沼泽吞噬者 / Swamp Devourer

- **定位**：吞噬死亡单位、越战越强型 BOSS
- **被动 `boss_corpse_devour`**：根据场上死亡叠加吞噬层，循环提高攻击、防御、最大生命
- **主动 `boss_mire_engulf`**：生成泥沼场地，持续伤害并施加迟缓

### 熔岩巨人 / Lava Colossus

- **定位**：高 AoE、燃烧和场地压制型 BOSS
- **被动 `boss_molten_body`**：受到近战普攻时概率反伤并施加燃烧
- **主动 `boss_magma_fissure`**：生成矩形岩浆裂缝，持续伤害并施加燃烧

### 天灾领主 / Scourge Lord

- **定位**：亡灵召唤型 BOSS
- **被动 `boss_raise_the_fallen`**：将阵亡敌对单位概率转化为随机亡灵
- **主动 `boss_undead_warband`**：召唤骷髅战士、骷髅弓箭手、骷髅法师组成的亡灵小队

### 森精灵之王 / Faelord of the Grove

- **定位**：范围 AoE、治疗与自然增幅型 BOSS
- **被动 `boss_grove_resonance`**：释放主动后治疗敌方单位，首次低血敌方单位提供护盾
- **主动 `boss_starleaf_storm`**：对玩家单位造成范围伤害，同时治疗范围内敌方单位并按命中数量回魔

### 裂地巨像 / Earthbreaker Colossus

- **定位**：极限承伤型 BOSS
- **被动 `enemy_colossus_core`**：受到护盾后的生命伤害降低 25%；承受重击后获得护盾
- **主动 `enemy_earthbreaker_barrier`**：自身获得护盾（100 + 12% 最大生命）并造成 180% 攻击力伤害
- **设计要点**：极高生命（900）和防御（70），护盾反制爆发，需要持续输出或穿盾机制

### 虚空炮台 / Void Cannon

- **定位**：远程爆发型 BOSS
- **被动 `enemy_void_charge`**：普攻命中时额外恢复 8 魔力，高频技能释放
- **主动 `enemy_void_beam`**：造成 320% 攻击力技能伤害，对半血以下目标伤害提高
- **设计要点**：高攻击（42）高暴击（15% / x1.80），射程 170，低生命（620）适合刺客切入；快速回魔导致技能频率极高

### 深渊大祭司 / Abyss Hierophant

- **定位**：团队续航与增幅型 BOSS
- **被动 `enemy_abyss_chant`**：战斗开始时敌方全队获得 30 护盾和 +10% 魔力回复
- **主动 `enemy_mass_benediction`**：敌方全队治疗 25 + 120% 攻击力并获得 50 护盾
- **设计要点**：辅助 BOSS，全队治疗+护盾+回魔增益，持久战核心威胁，需要优先压制或控制

---

## 四、实现入口

| 内容 | 文件 |
| --- | --- |
| 单位资源 | `data/enemies/*.tres` |
| 敌方池接入 | `scripts/catalog/enemy_catalog.gd` |
| 遭遇权重 | `scripts/encounter/encounter_generator.gd` |
| 主动技能 | `scripts/combat/active_skill_caster.gd` |
| 被动技能 / 死亡效果 | `scripts/combat/passive_resolver.gd` |
| 状态区域 | `scripts/combat/field_effect_manager.gd`、`scripts/battle_manager.gd` |
| 分裂/召唤 | `scripts/summon_manager.gd` |
| 技能说明 | `scripts/unit_text_formatter.gd` |
| 推荐站位 | `scripts/battle_board.gd` |
| 反射/护盾判定 | `scripts/combat/combat_resolver.gd`、`scripts/unit_combat.gd` |

## 五、验证命令

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file test_slime.log --script res://scripts/tests/test_slime_enemies.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file test_boss.log --script res://scripts/tests/test_boss_units.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file test_elite.log --script res://scripts/tests/test_elite_enemies.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file test_summon.log --script res://scripts/tests/test_summon_system.gd
```
