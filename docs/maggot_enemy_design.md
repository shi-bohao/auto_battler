# 巨型蛆虫 / 蛆虫聚合体 设计（v2 — 统一剧毒，无新增持续伤害）

基于 v1 改写：不接入 `rot` 或其他新的持续伤害效果，所有持续掉血统一复用已有 `venom_stack`（剧毒）；增伤改为独立 debuff `putrid_mark`（腐痕）。`putrid_mark` 本身不造成持续伤害，只修改 `damage_taken_multiplier`。

---

## 一、巨型蛆虫 / Giant Maggot

```
unit_name = "Giant Maggot"
unit_name_cn = "巨型蛆虫"
description_cn = "普通敌人，死亡自爆并施加剧毒与腐痕，主动技能喷吐毒液。"
unit_type = "enemy_giant_maggot"
role = "damage"
enemy_tier = "NORMAL"
star = 1
price = 0
basic_attack_type = "melee"
```

**基础属性：**
```
max_hp = 160
attack_damage = 14
crit_chance = 0.0
crit_damage_multiplier = 1.5
defense = 8
attack_interval = 1.35
attack_range = 55.0
search_range = 999.0
move_speed = 55.0
target_mode = "NEAREST"
retarget_interval = 0.4
lowest_hp_switch_threshold = 0.1
passive_id = "maggot_death_burst"
active_skill_id = "septic_spit"
max_mana = 85
mana_regen_per_second = 10.0
```

### 被动：腐爆 / maggot_death_burst

**触发**：巨型蛆虫死亡时。

**AoE 伤害**：半径 90，`35 + max_hp * 0.08`（取整），不暴击。

**施加效果**：
| 效果 | 参数 |
|------|------|
| venom_stack | 1 层，3 秒，5/s |
| putrid_mark | 5 秒 |

### 主动：腐蚀喷吐 / septic_spit

**触发**：魔力满时对当前目标释放。

**直接伤害**：`attack_damage * 1.2` × `skill_power`（取整），不暴击。

**施加效果**：
| 效果 | 参数 |
|------|------|
| venom_stack | 2 层，5 秒，5/s per stack |
| putrid_mark | 6 秒 |

---

## 二、蛆虫聚合体 / Maggot Amalgam

```
unit_name = "Maggot Amalgam"
unit_name_cn = "蛆虫聚合体"
description_cn = "精英坦克敌人，死亡分裂召唤巨型蛆虫，主动技能释放扇形腐潮。"
unit_type = "enemy_elite_maggot_amalgam"
role = "tank"
enemy_tier = "ELITE"
star = 1
price = 0
basic_attack_type = "melee"
```

**基础属性：**
```
max_hp = 520
attack_damage = 18
crit_chance = 0.0
crit_damage_multiplier = 1.5
defense = 28
attack_interval = 1.45
attack_range = 65.0
search_range = 999.0
move_speed = 42.0
target_mode = "NEAREST"
retarget_interval = 0.4
lowest_hp_switch_threshold = 0.1
passive_id = "amalgam_split_birth"
active_skill_id = "putrid_tide"
max_mana = 110
mana_regen_per_second = 9.0
```

### 被动：分裂繁殖 / amalgam_split_birth

同 v1：死亡时召唤 4 只 giant_maggot，走 `summon_manager.handle_unit_death()` 调度。

### 主动：腐潮 / putrid_tide

**触发**：魔力满时对当前目标方向释放。

**扇形 AoE**：半径 130，角度 90°，以自身为起点朝目标方向。

**直接伤害**：`attack_damage * 1.4` × `skill_power`（取整），不暴击。

**增伤判定**：对命中单位逐一检查是否存在 `putrid_mark`，若有则本击伤害 ×1.25。

**施加效果**：
| 效果 | 参数 |
|------|------|
| venom_stack | 2 层，4 秒，5/s per stack |
| putrid_mark | 5 秒（刷新） |

**伤害计算顺序**（每个命中单位独立）：
1. 基础伤害 = `attack_damage * 1.4 * skill_multiplier`
2. 若目标有 `putrid_mark` → 基础伤害 × 1.25
3. 结算伤害（走防御→护盾→HP）
4. 施加 / 刷新 `putrid_mark`
5. 施加 2 层 `venom_stack`

---

## 三、腐痕 Debuff：putrid_mark（非持续伤害）

| 字段 | 值 | 说明 |
|------|-----|------|
| effect_id | `"putrid_mark"` | |
| effect_type | `STAT_MULTIPLY` | |
| stat_name | `"damage_taken_multiplier"` | 受到的伤害倍率 |
| value | `1.25` | 即 +25% 承伤 |
| stack_policy | `UNIQUE_PER_SOURCE_REFRESH` | 同源刷新持续时间 |
| polarity | `NEGATIVE` | |
| category | `MARK` | 与血影猎手的 hunt_mark 同类 |
| duration | 5 秒 | 各来源可覆写不同时长 |

当前实现中，蛆虫族只有 `venom_stack` 会产生持续跳伤；`putrid_mark` 只提供承伤倍率，不属于 DoT。

**战术含义**：

```
巨型蛆虫死亡自爆 / 喷吐
  → 玩家单位染上 剧毒 (持续掉血) + 腐痕 (承伤+25%)
  → 蛆虫聚合体腐潮命中
  → 有腐痕 → 本次伤害 ×1.25 → 刷新腐痕
  → 无腐痕 → 基础伤害 → 施加腐痕（下次腐潮将获得增伤）
```

- 腐痕只被蛆虫族技能施加，不与剧毒羁绊/剧毒女王产生意外联动
- 增伤是通用的 `damage_taken_multiplier`，所有来源伤害均受影响（即玩家的其他敌人、其他 DoT 也受益）
- 玩家应对方式：被标记单位需要治疗/护盾保护，或尽快击杀蛆虫来源

---

## 四、与 v1 差异总结

| 项目 | v1 | v2 |
|------|----|----|
| 持续伤害类型 | 新建 rot（STRONGEST_WINS） | 复用 venom_stack（STACK_INDEPENDENT_DURATION） |
| 死亡自爆 DoT | rot 5/s × 3s | venom_stack 1层 5/s × 3s |
| 喷吐 DoT | rot 6+ATK×0.25 ≈ 9.5/s × 5s | venom_stack 2层 = 10/s × 5s |
| 腐潮 DoT | rot 8/s × 4s | venom_stack 2层 = 10/s × 4s |
| 增伤机制 | 检测 rot 或 venom 存在 → +25% | 独立 debuff putrid_mark，被标记者承伤 +25% |
| 新增持续伤害实现 | 新建 rot 状态/逻辑 | 不新增 DoT；持续伤害全部复用已有 `venom_stack` |
| 新增标记实现 | 无独立承伤标记 | 不新增独立状态文件，复用 `StatusEffectFactory` 在技能中施加 `putrid_mark` |

---

## 五、实现清单

| # | 内容 | 文件 |
|---|------|------|
| 1 | 巨型蛆虫 UnitData | `data/enemies/giant_maggot.tres` |
| 2 | 蛆虫聚合体 UnitData | `data/enemies/maggot_amalgam.tres` |
| 3 | 死亡 AoE 被动（maggot_death_burst） | `scripts/combat/passive_resolver.gd` |
| 4 | 死亡分裂被动调度（amalgam_split_birth），直接使用 `data/enemies/giant_maggot.tres` 作为召唤单位数据 | `scripts/summon_manager.gd` |
| 5 | septic_spit + putrid_tide 主动技能 | `scripts/combat/active_skill_caster.gd` |
| 6 | putrid_mark 施加调用（复用 `_apply_status_effect`） | 各被动/技能中 |
| 7 | 敌方单位池接入 | `scripts/catalog/enemy_catalog.gd` |
| 8 | 编译检查 + 内容参考刷新 | 验证命令 |
