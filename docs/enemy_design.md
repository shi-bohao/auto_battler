# Enemy Design Document

> 维护提示：本文档前半部分保留敌人设计原案与数值设定；第 9 节记录 2026-05-04 的实际接入状态。后续又加入召唤敌人、镜像挑战、高稀有度内容和蛆虫族敌人，因此当前敌人资源与技能数值请优先查看 `docs/content_reference.md` 和 `docs/maggot_enemy_design.md`。本文档更多作为敌人设计草案和历史脉络。

本文档用于记录当前自动战斗项目中的敌方怪物设计。敌人按照定位分为三类：

- 承伤类：负责吸收伤害、保护后排、拖延战斗时间。
- 输出类：负责制造伤害压力，威胁玩家前排或后排。
- 辅助类：负责治疗、护盾、团队增幅或续航。

当前敌人体系已经扩展到 17 个敌人资源，包括普通敌人、精英敌人、Boss、召唤相关敌人和蛆虫族敌人。早期设计目标如下，后续新增敌人可继续沿用这些原则：

1. 每一类敌人暂时设计 2 种普通怪、1 种精英怪、1 种 Boss 怪。
2. 敌人不进入玩家商店和玩家奖励池，只由 EncounterManager / 敌方遭遇系统生成。
3. 敌人仍然使用当前项目的 UnitData 字段、伤害规则、魔力规则和技能释放规则。
4. 敌人技能优先保持简单，避免引入复杂 Buff 系统。
5. 普通怪用于丰富普通波次；精英怪用于精英关；Boss 怪用于 Boss 关。

---

## 1. 设计原则

### 1.1 敌人与玩家单位的区别

敌人可以复用玩家单位的底层战斗系统，但不应该只是玩家单位换皮。

区别建议：

- 敌人更偏向“关卡压力来源”。
- 普通怪机制简单，容易理解。
- 精英怪具有更强的队伍影响能力。
- Boss 怪有明显主题和较高压迫感。

### 1.2 敌人资源建议

建议将敌方单位资源放在：

```text
res://data/enemies/
```

例如：

```text
res://data/enemies/shield_guard.tres
res://data/enemies/elite_iron_warden.tres
res://data/enemies/boss_earthbreaker_colossus.tres
```

### 1.3 敌人命名规范

普通怪：

```text
enemy_<monster_name>
```

精英怪：

```text
enemy_elite_<monster_name>
```

Boss 怪：

```text
enemy_boss_<monster_name>
```

当前实现使用 `enemy_tier` 字段（NORMAL / ELITE / BOSS）作为敌人阶等主判定依据。`EnemyCatalog.is_elite_enemy_id()` 优先读取 `enemy_tier`，仅在该字段为空时回退到 `unit_type` 前缀匹配。新增敌人时建议同时配置 `enemy_tier` 并继续遵循 `unit_type` 前缀命名，方便人工阅读和兼容旧逻辑。

---

# 2. 承伤类怪物

## 2.1 Shield Guard

Role: basic frontline tank.

Resource path:

```text
res://data/enemies/shield_guard.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Shield Guard` |
| `unit_name_cn` | `盾卫` |
| `unit_type` | `enemy_shield_guard` |
| `role` | `tank` |
| `price` | `0` |
| `max_hp` | `210` |
| `attack_damage` | `8` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `18` |
| `attack_interval` | `1.25` |
| `attack_range` | `50.0` |
| `search_range` | `999.0` |
| `move_speed` | `60.0` |
| `passive_id` | `enemy_shield_wall` |
| `active_skill_id` | `enemy_guard_stance` |
| `max_mana` | `100` |
| `mana_regen_per_second` | `8.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_shield_wall`
- effect: Incoming HP damage after shield is reduced by `10%`.

Active skill:

- id: `enemy_guard_stance`
- mana: `100`
- effect: Gain shield equal to `25 + max_hp * 0.15`.

Design purpose:

- Basic enemy frontline.
- Protects enemy backline damage and support units.
- Good for early and mid-game normal encounters.

Recommended position:

- Enemy frontline.
- If using 7×15 board, prioritize enemy cells around `(8, 2)`, `(8, 4)`, `(9, 2)`, `(9, 4)`.

---

## 2.2 Stoneback Beast

Role: high-health defensive monster.

Resource path:

```text
res://data/enemies/stoneback_beast.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Stoneback Beast` |
| `unit_name_cn` | `石背巨兽` |
| `unit_type` | `enemy_stoneback_beast` |
| `role` | `tank` |
| `price` | `0` |
| `max_hp` | `280` |
| `attack_damage` | `6` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `25` |
| `attack_interval` | `1.5` |
| `attack_range` | `45.0` |
| `search_range` | `999.0` |
| `move_speed` | `45.0` |
| `passive_id` | `enemy_stone_skin` |
| `active_skill_id` | `enemy_harden` |
| `max_mana` | `120` |
| `mana_regen_per_second` | `7.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_stone_skin`
- effect:
  - Defense is increased by `10`.
  - If current HP ratio is below or equal to `50%`, gain an additional `15` defense.

Active skill:

- id: `enemy_harden`
- mana: `120`
- effect: Gain `40` shield.

Design purpose:

- Very durable but low damage.
- Used to delay the player and protect enemy damage dealers.
- Useful in mid-game normal encounters and defensive enemy formations.

Recommended position:

- Enemy frontline center or side-front.
- If using 7×15 board, prioritize `(8, 3)`, `(9, 3)`, `(8, 2)`, `(8, 4)`.

---

## 2.3 Elite Iron Warden

Role: elite tank core.

Resource path:

```text
res://data/enemies/elite_iron_warden.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Elite Iron Warden` |
| `unit_name_cn` | `精英铁壁守卫` |
| `unit_type` | `enemy_elite_iron_warden` |
| `role` | `tank` |
| `price` | `0` |
| `max_hp` | `420` |
| `attack_damage` | `12` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `45` |
| `attack_interval` | `1.2` |
| `attack_range` | `55.0` |
| `search_range` | `999.0` |
| `move_speed` | `60.0` |
| `passive_id` | `enemy_iron_body` |
| `active_skill_id` | `enemy_fortify_allies` |
| `max_mana` | `110` |
| `mana_regen_per_second` | `9.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_iron_body`
- effect: Incoming HP damage after shield is reduced by `18%`.

Active skill:

- id: `enemy_fortify_allies`
- mana: `110`
- effect:
  - Self gains `60` shield.
  - All enemy units gain `20` shield.

Design purpose:

- Elite tank that protects the whole enemy team.
- Useful in elite defensive encounters.
- Forces the player to either burst through shields or eliminate backline first.

Recommended position:

- Enemy frontline center.
- If using 7×15 board, prioritize `(8, 3)`, `(9, 3)`, `(8, 2)`, `(8, 4)`.

---

## 2.4 Boss: Earthbreaker Colossus

Role: tank Boss.

Resource path:

```text
res://data/enemies/boss_earthbreaker_colossus.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Boss: Earthbreaker Colossus` |
| `unit_name_cn` | `Boss：裂地巨像` |
| `unit_type` | `enemy_boss_earthbreaker_colossus` |
| `role` | `tank` |
| `price` | `0` |
| `max_hp` | `900` |
| `attack_damage` | `18` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `70` |
| `attack_interval` | `1.35` |
| `attack_range` | `60.0` |
| `search_range` | `999.0` |
| `move_speed` | `42.0` |
| `passive_id` | `enemy_colossus_core` |
| `active_skill_id` | `enemy_earthbreaker_barrier` |
| `max_mana` | `130` |
| `mana_regen_per_second` | `8.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_colossus_core`
- effect:
  - Incoming HP damage after shield is reduced by `25%`.
  - When HP drops below `70%`, `40%`, and `20%`, gain `120` shield.
  - Each threshold triggers only once.

Active skill:

- id: `enemy_earthbreaker_barrier`
- mana: `130`
- effect:
  - Self gains shield equal to `100 + max_hp * 0.12`.
  - Deals `attack_damage * 1.8` direct skill damage to current target.

Design purpose:

- Durable tank Boss.
- Tests player’s sustained damage output.
- Should not kill players too quickly; pressure comes from durability and repeated shielding.

Recommended position:

- Enemy frontline center.
- If using 7×15 board, prioritize `(8, 3)` or `(9, 3)`.

---

# 3. 输出类怪物

## 3.1 Crossbow Raider

Role: basic ranged physical damage dealer.

Resource path:

```text
res://data/enemies/crossbow_raider.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Crossbow Raider` |
| `unit_name_cn` | `弩手掠袭者` |
| `unit_type` | `enemy_crossbow_raider` |
| `role` | `damage` |
| `price` | `0` |
| `max_hp` | `90` |
| `attack_damage` | `20` |
| `crit_chance` | `0.08` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `0` |
| `attack_interval` | `1.15` |
| `attack_range` | `150.0` |
| `search_range` | `999.0` |
| `move_speed` | `90.0` |
| `passive_id` | `enemy_steady_aim` |
| `active_skill_id` | `enemy_power_shot` |
| `max_mana` | `75` |
| `mana_regen_per_second` | `12.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_steady_aim`
- effect: If target distance is greater than or equal to `attack_range * 0.6`, basic attack damage is increased by `10%`.

Active skill:

- id: `enemy_power_shot`
- mana: `75`
- effect: Deals `attack_damage * 1.8` direct skill damage to current target.

Design purpose:

- Basic enemy ranged DPS.
- Similar to a weaker enemy-side archer.
- Good for early and mid-game backline pressure.

Recommended position:

- Enemy backline.
- If using 7×15 board, prioritize `(14, 2)`, `(14, 4)`, `(13, 2)`, `(13, 4)`.

---

## 3.2 Flame Imp

Role: skill burst damage dealer.

Resource path:

```text
res://data/enemies/flame_imp.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Flame Imp` |
| `unit_name_cn` | `烈焰小鬼` |
| `unit_type` | `enemy_flame_imp` |
| `role` | `damage` |
| `price` | `0` |
| `max_hp` | `75` |
| `attack_damage` | `24` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `0` |
| `attack_interval` | `1.45` |
| `attack_range` | `130.0` |
| `search_range` | `999.0` |
| `move_speed` | `95.0` |
| `passive_id` | `enemy_flame_focus` |
| `active_skill_id` | `enemy_firebolt` |
| `max_mana` | `80` |
| `mana_regen_per_second` | `15.0` |
| `target_mode` | `LOWEST_HP` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_flame_focus`
- effect: Active skill damage is increased by `10%`.

Active skill:

- id: `enemy_firebolt`
- mana: `80`
- effect: Deals `attack_damage * 2.5` direct skill damage to current target.

Design purpose:

- Low-health, high-burst skill enemy.
- Pressures the player to eliminate enemy backline quickly.
- Works well behind Shield Guard or Stoneback Beast.

Recommended position:

- Enemy backline.
- If using 7×15 board, prioritize `(14, 3)`, `(13, 3)`, `(14, 2)`, `(14, 4)`.

---

## 3.3 Elite Shadow Reaper

Role: elite burst assassin.

Resource path:

```text
res://data/enemies/elite_shadow_reaper.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Elite Shadow Reaper` |
| `unit_name_cn` | `精英影刃收割者` |
| `unit_type` | `enemy_elite_shadow_reaper` |
| `role` | `damage` |
| `price` | `0` |
| `max_hp` | `180` |
| `attack_damage` | `32` |
| `crit_chance` | `0.18` |
| `crit_damage_multiplier` | `1.8` |
| `defense` | `5` |
| `attack_interval` | `0.85` |
| `attack_range` | `65.0` |
| `search_range` | `999.0` |
| `move_speed` | `155.0` |
| `passive_id` | `enemy_reaper_execute` |
| `active_skill_id` | `enemy_shadow_cleave` |
| `max_mana` | `90` |
| `mana_regen_per_second` | `13.0` |
| `target_mode` | `LOWEST_HP` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_reaper_execute`
- effect: When attacking a target with HP ratio below or equal to `45%`, basic attack damage is increased by `35%`.

Active skill:

- id: `enemy_shadow_cleave`
- mana: `90`
- effect:
  - Deals `attack_damage * 2.6` direct skill damage to current target.
  - If this skill kills the target, heal self for `30` HP.

Design purpose:

- Elite assassin-type enemy.
- Threatens backline and low HP units.
- Good for elite assassin encounters and late normal encounters.

Recommended position:

- Enemy middle row / side lane.
- If using 7×15 board, prioritize `(10, 1)`, `(10, 5)`, `(11, 1)`, `(11, 5)`.

---

## 3.4 Boss: Void Cannon

Role: damage Boss.

Resource path:

```text
res://data/enemies/boss_void_cannon.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Boss: Void Cannon` |
| `unit_name_cn` | `Boss：虚空炮台` |
| `unit_type` | `enemy_boss_void_cannon` |
| `role` | `damage` |
| `price` | `0` |
| `max_hp` | `620` |
| `attack_damage` | `42` |
| `crit_chance` | `0.15` |
| `crit_damage_multiplier` | `1.8` |
| `defense` | `20` |
| `attack_interval` | `1.6` |
| `attack_range` | `170.0` |
| `search_range` | `999.0` |
| `move_speed` | `55.0` |
| `passive_id` | `enemy_void_charge` |
| `active_skill_id` | `enemy_void_beam` |
| `max_mana` | `120` |
| `mana_regen_per_second` | `12.0` |
| `target_mode` | `LOWEST_HP` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_void_charge`
- effect: After each basic attack lands, gain `8` mana.

Active skill:

- id: `enemy_void_beam`
- mana: `120`
- effect:
  - Deals `attack_damage * 3.2` direct skill damage to current target.
  - If target HP ratio is below `50%`, skill damage is increased by `25%`.

Design purpose:

- High-burst damage Boss.
- Tests the player’s ability to survive burst and reach enemy backline.
- Should usually be paired with at least one frontline guard.

Recommended position:

- Enemy backline or mid-backline.
- If using 7×15 board, prioritize `(14, 3)`, `(13, 3)`, `(14, 2)`, `(14, 4)`.

---

# 4. 辅助类怪物

## 4.1 Dark Acolyte

Role: basic healing support.

Resource path:

```text
res://data/enemies/dark_acolyte.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Dark Acolyte` |
| `unit_name_cn` | `黑暗侍僧` |
| `unit_type` | `enemy_dark_acolyte` |
| `role` | `support` |
| `price` | `0` |
| `max_hp` | `100` |
| `attack_damage` | `10` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `0` |
| `attack_interval` | `1.35` |
| `attack_range` | `120.0` |
| `search_range` | `999.0` |
| `move_speed` | `85.0` |
| `passive_id` | `enemy_dark_blessing` |
| `active_skill_id` | `enemy_dark_heal` |
| `max_mana` | `80` |
| `mana_regen_per_second` | `12.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_dark_blessing`
- effect: Healing effects from this unit are increased by `15%`.

Active skill:

- id: `enemy_dark_heal`
- mana: `80`
- effect:
  - Heal the enemy unit with the lowest HP ratio.
  - Healing amount is `30 + attack_damage * 1.3`.

Design purpose:

- Basic enemy healer.
- Extends fight duration.
- Works well with durable frontline enemies.

Recommended position:

- Enemy backline.
- If using 7×15 board, prioritize `(14, 3)`, `(14, 2)`, `(14, 4)`, `(13, 3)`.

---

## 4.2 War Drummer

Role: team amplification support.

Resource path:

```text
res://data/enemies/war_drummer.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `War Drummer` |
| `unit_name_cn` | `战鼓手` |
| `unit_type` | `enemy_war_drummer` |
| `role` | `support` |
| `price` | `0` |
| `max_hp` | `120` |
| `attack_damage` | `8` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `5` |
| `attack_interval` | `1.4` |
| `attack_range` | `115.0` |
| `search_range` | `999.0` |
| `move_speed` | `90.0` |
| `passive_id` | `enemy_war_rhythm` |
| `active_skill_id` | `enemy_drum_shield` |
| `max_mana` | `95` |
| `mana_regen_per_second` | `10.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_war_rhythm`
- effect: At battle start, all enemy units gain `+6%` attack damage.

Active skill:

- id: `enemy_drum_shield`
- mana: `95`
- effect: All enemy units gain `15` shield.

Design purpose:

- Low personal damage, but improves enemy team durability and output.
- Encourages the player to prioritize enemy support units.

Recommended position:

- Enemy backline or mid-backline.
- If using 7×15 board, prioritize `(13, 3)`, `(14, 3)`, `(13, 2)`, `(13, 4)`.

---

## 4.3 Elite Blood Oracle

Role: elite healing support.

Resource path:

```text
res://data/enemies/elite_blood_oracle.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Elite Blood Oracle` |
| `unit_name_cn` | `精英血谕者` |
| `unit_type` | `enemy_elite_blood_oracle` |
| `role` | `support` |
| `price` | `0` |
| `max_hp` | `220` |
| `attack_damage` | `16` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `12` |
| `attack_interval` | `1.25` |
| `attack_range` | `130.0` |
| `search_range` | `999.0` |
| `move_speed` | `85.0` |
| `passive_id` | `enemy_blood_ritual` |
| `active_skill_id` | `enemy_oracle_blessing` |
| `max_mana` | `90` |
| `mana_regen_per_second` | `14.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_blood_ritual`
- effect: When an enemy unit kills a player unit, the killer heals for `25` HP.

Active skill:

- id: `enemy_oracle_blessing`
- mana: `90`
- effect:
  - Heal the enemy unit with the lowest HP ratio.
  - Healing amount is `50 + attack_damage * 1.5`.
  - Also add `20` shield to that target.

Design purpose:

- Elite support that significantly improves enemy sustain.
- Works well in elite defensive or attrition encounters.
- Can also be used as a Boss guard.

Recommended position:

- Enemy backline.
- If using 7×15 board, prioritize `(14, 3)`, `(13, 3)`, `(14, 2)`, `(14, 4)`.

---

## 4.4 Boss: Abyss Hierophant

Role: support Boss.

Resource path:

```text
res://data/enemies/boss_abyss_hierophant.tres
```

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Boss: Abyss Hierophant` |
| `unit_name_cn` | `Boss：深渊大祭司` |
| `unit_type` | `enemy_boss_abyss_hierophant` |
| `role` | `support` |
| `price` | `0` |
| `max_hp` | `720` |
| `attack_damage` | `20` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `35` |
| `attack_interval` | `1.2` |
| `attack_range` | `140.0` |
| `search_range` | `999.0` |
| `move_speed` | `65.0` |
| `passive_id` | `enemy_abyss_chant` |
| `active_skill_id` | `enemy_mass_benediction` |
| `max_mana` | `120` |
| `mana_regen_per_second` | `11.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `enemy_abyss_chant`
- effect:
  - At battle start, all enemy units gain `30` shield.
  - While this unit is alive, all enemy units gain `+10%` mana regen.

Active skill:

- id: `enemy_mass_benediction`
- mana: `120`
- effect:
  - Heal all enemy units.
  - Healing amount is `25 + attack_damage * 1.2`.
  - Also add `50` shield to the enemy unit with the lowest HP ratio.

Design purpose:

- Support Boss focused on sustain and team amplification.
- Does not burst the player down quickly, but makes the enemy team difficult to finish.
- Works well with high-damage or high-defense guards.

Recommended position:

- Enemy backline or center-backline.
- If using 7×15 board, prioritize `(13, 3)`, `(14, 3)`, `(13, 2)`, `(13, 4)`.

---

# 5. 敌方怪物汇总表

| Category | Type | Monster | Chinese Name | Role | Core Threat |
| --- | --- | --- | --- | --- | --- |
| Tank | Normal | Shield Guard | 盾卫 | tank | Basic shield frontline |
| Tank | Normal | Stoneback Beast | 石背巨兽 | tank | High HP and defense |
| Tank | Elite | Elite Iron Warden | 精英铁壁守卫 | tank | Team shielding elite tank |
| Tank | Boss | Earthbreaker Colossus | Boss：裂地巨像 | tank | Extremely durable Boss |
| Damage | Normal | Crossbow Raider | 弩手掠袭者 | damage | Ranged physical damage |
| Damage | Normal | Flame Imp | 烈焰小鬼 | damage | Skill burst damage |
| Damage | Elite | Elite Shadow Reaper | 精英影刃收割者 | damage | Burst cleanup assassin |
| Damage | Boss | Void Cannon | Boss：虚空炮台 | damage | High skill burst Boss |
| Support | Normal | Dark Acolyte | 黑暗侍僧 | support | Single target healing |
| Support | Normal | War Drummer | 战鼓手 | support | Team attack and shield support |
| Support | Elite | Elite Blood Oracle | 精英血谕者 | support | Strong healing and shield elite |
| Support | Boss | Abyss Hierophant | Boss：深渊大祭司 | support | Team sustain and mana support Boss |

---

# 6. 推荐接入方式

## 6.1 不进入玩家池

这些敌人不应该进入：

- 玩家商店池
- 玩家奖励三选一单位池
- 玩家初始阵容
- 玩家备战席系统

它们应该只由敌方遭遇系统生成。

## 6.2 接入 EncounterManager

建议将敌人加入 EncounterManager 的敌方单位池：

```text
tank_enemy_pool:
- enemy_shield_guard
- enemy_stoneback_beast
- enemy_elite_iron_warden
- enemy_boss_earthbreaker_colossus

damage_enemy_pool:
- enemy_crossbow_raider
- enemy_flame_imp
- enemy_elite_shadow_reaper
- enemy_boss_void_cannon

support_enemy_pool:
- enemy_dark_acolyte
- enemy_war_drummer
- enemy_elite_blood_oracle
- enemy_boss_abyss_hierophant
```

普通战建议只抽普通怪。

精英战建议至少包含一个精英怪。

Boss 战建议固定包含一个 Boss 怪，再搭配普通或精英护卫。

## 6.3 第一批实现建议

如果一次性实现 12 个怪物压力太大，建议先实现以下 9 个：

```text
Shield Guard
Crossbow Raider
Dark Acolyte
Elite Iron Warden
Elite Shadow Reaper
Elite Blood Oracle
Earthbreaker Colossus
Void Cannon
Abyss Hierophant
```

第二批再加入：

```text
Stoneback Beast
Flame Imp
War Drummer
```

---

# 7. 实现注意事项

1. 敌人技能可以复用现有 UnitSkill 框架。
2. 如果当前技能系统默认只处理玩家单位，需要确保敌方单位也能释放敌方技能。
3. 敌人治疗和护盾目标应选择敌方阵营单位，而不是玩家单位。
4. 敌人击杀回血类效果应只对敌方单位生效。
5. 敌人团队增益应只影响敌方单位。
6. 敌人 Boss 不应进入商店或奖励池。
7. 敌人 `price` 可以设置为 `0`，避免被出售或购买逻辑误用。
8. 如果项目中有 role 字段，敌人也应填写 role，方便随机遭遇生成和站位分配。
9. 如果项目中使用 7×15 棋盘，敌人必须生成在敌方区域。
10. Boss 怪建议在 UI 中显示 Boss 标识。

---

# 8. 后续扩展方向

后续可以继续扩展：

1. 敌人专属词缀，例如燃烧、毒、反伤。
2. Boss 阶段机制，例如 70% / 40% 血量触发特殊技能。
3. 特殊精英组合，例如双刺客队、法术爆发队、铁壁治疗队。
4. 敌人稀有度和生成权重。
5. 关卡主题，例如荒野、遗迹、深渊、机械军团。
6. 敌人图鉴 UI。

---

# 9. 实现状态 - 2026-05-04

本节记录当前项目中已经接入的敌人内容，便于区分“设计设想”和“已落地实现”。

## 9.1 已实现资源

12 个敌人资源已经全部落地，统一放在：

```text
res://data/enemies/
```

| 敌人 | 中文名 | 资源 | `unit_type` |
| --- | --- | --- | --- |
| Shield Guard | 盾卫 | `shield_guard.tres` | `enemy_shield_guard` |
| Stoneback Beast | 石背巨兽 | `stoneback_beast.tres` | `enemy_stoneback_beast` |
| Elite Iron Warden | 精英铁壁守卫 | `elite_iron_warden.tres` | `enemy_elite_iron_warden` |
| Earthbreaker Colossus | Boss：裂地巨像 | `boss_earthbreaker_colossus.tres` | `enemy_boss_earthbreaker_colossus` |
| Crossbow Raider | 弩手掠袭者 | `crossbow_raider.tres` | `enemy_crossbow_raider` |
| Flame Imp | 烈焰小鬼 | `flame_imp.tres` | `enemy_flame_imp` |
| Elite Shadow Reaper | 精英影刃收割者 | `elite_shadow_reaper.tres` | `enemy_elite_shadow_reaper` |
| Void Cannon | Boss：虚空炮台 | `boss_void_cannon.tres` | `enemy_boss_void_cannon` |
| Dark Acolyte | 黑暗侍僧 | `dark_acolyte.tres` | `enemy_dark_acolyte` |
| War Drummer | 战鼓手 | `war_drummer.tres` | `enemy_war_drummer` |
| Elite Blood Oracle | 精英血谕者 | `elite_blood_oracle.tres` | `enemy_elite_blood_oracle` |
| Abyss Hierophant | Boss：深渊大祭司 | `boss_abyss_hierophant.tres` | `enemy_boss_abyss_hierophant` |

## 9.2 生成规则

敌人生成逻辑位于：

- `res://scripts/encounter_manager.gd`

当前规则：

- 固定遭遇和随机遭遇都只生成 `enemy_*` 单位。
- 敌人不会进入玩家商店、玩家奖励池或玩家初始阵容。
- 普通战只从普通敌人池中抽取。
- 精英战会确保至少出现 1 个 `enemy_elite_*` 单位。
- Boss 战会确保至少出现 1 个 `enemy_boss_*` 单位。
- Boss 战可额外搭配普通或精英护卫。

敌人池按职责拆分：

| 池 | 普通 | 精英 | Boss |
| --- | --- | --- | --- |
| 承伤 | `enemy_shield_guard`, `enemy_stoneback_beast` | `enemy_elite_iron_warden` | `enemy_boss_earthbreaker_colossus` |
| 输出 | `enemy_crossbow_raider`, `enemy_flame_imp` | `enemy_elite_shadow_reaper` | `enemy_boss_void_cannon` |
| 辅助 | `enemy_dark_acolyte`, `enemy_war_drummer` | `enemy_elite_blood_oracle` | `enemy_boss_abyss_hierophant` |

## 9.3 站位规则

站位逻辑位于：

- `res://scripts/battle_board.gd`
- `res://scripts/encounter_manager.gd`

敌人注册、池配置与遭遇生成位于：

- `res://scripts/catalog/enemy_catalog.gd` — 敌人 ID 常量、数据预加载、按角色/类型分池、`enemy_tier` 判定
- `res://scripts/encounter/encounter_generator.gd` — 随机遭遇模板、单位权重、Boss/精英阵容构建
- `res://scripts/encounter/default_encounter_builder.gd` — 前 10 波手写遭遇

当前实现：

- 7x15 棋盘中，敌方有效区域为 `col = 8..14`。
- `BattleBoard.choose_enemy_cell_for_unit()` 为不同敌人 ID 提供推荐格子。
- Boss 优先使用中路核心位置。
- 刺客型敌人和远程敌人有单独的推荐站位。
- 如果无法取得有效 grid cell，会回退到当前已有站位坐标逻辑。

## 9.4 技能接入

敌人技能逻辑位于：

- `res://scripts/unit_skill.gd`（委托至 `scripts/combat/passive_resolver.gd`）
- `res://scripts/combat/active_skill_caster.gd` — 敌人主动技能调度与实现
- `res://scripts/combat/passive_resolver.gd` — 敌人被动效果（减伤、击杀触发、死亡触发等）

已接入内容：

- 17 个敌人被动 ID（包含新增的 `maggot_death_burst`、`amalgam_split_birth`）。
- 17 个敌人主动技能 ID（包含新增的 `septic_spit`、`putrid_tide`）。
- 敌人战斗开始被动。
- 敌人受伤减伤或阈值触发。
- 敌人攻击命中被动。
- 敌人击杀被动。
- 敌方治疗、护盾、团队增益会选择敌方阵营单位。

特殊说明：

- `enemy_colossus_core` 已实现 70% / 40% / 20% 生命阈值护盾，因此“Boss 阶段机制”已部分落地。
- `enemy_abyss_chant` 的团队魔力回复提升按当前运行时属性加成方式处理，不引入复杂 Buff 系统。
- 敌方技能伤害、治疗和护盾复用当前单位战斗与统计流程。

## 9.5 验证建议

1. 开启随机遭遇，连续开始多轮战斗，确认敌方阵容中不出现玩家单位 ID。
2. 检查普通战阵容，不应出现 `enemy_elite_*` 或 `enemy_boss_*`。
3. 检查精英战阵容，至少应出现 1 个 `enemy_elite_*`。
4. 检查 Boss 战阵容，至少应出现 1 个 `enemy_boss_*`。
5. 使用右键单位详情查看敌人属性，确认资源、星级和站位正常。
6. 观察辅助敌人释放技能时，只治疗或护盾敌方单位。
7. 对 Earthbreaker Colossus 造成伤害，确认 70% / 40% / 20% 附近会触发阈值护盾。
