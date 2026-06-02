# 状态效果系统设计

更新时间：2026-06-02

本文档覆盖 Buff/Debuff、DoT/HoT、属性修饰、燃烧、剧毒等状态效果，以及已实现的五类控制系统（Slow/Root/Stun/Freeze/Taunt）。

---

## 一、基础状态效果系统

### 核心架构

```
StatusEffect (data)
    ↓
UnitEffectController (lifecycle: apply/refresh/stack/expire/remove/clear)
    ↓
Unit._process() → update effects → update attack/target/skill/movement
```

关键文件：
- `scripts/status_effect.gd` — 状态效果数据结构，支持 HoT、DoT、属性加算/乘算、持续时间模式、正负性、分类、多种叠层策略
- `scripts/unit_effect_controller.gd` — 状态效果生命周期管理
- `scripts/combat/status_effect_factory.gd` — 统一创建/施加状态效果入口
- `scripts/combat/unit_stat_controller.gd` — 属性修饰器分层计算管道

### 已支持的效果类型

| 类型 | 说明 |
| --- | --- |
| `EFFECT_HEAL_OVER_TIME` | 持续治疗 |
| `EFFECT_DAMAGE_OVER_TIME` | 持续伤害（燃烧 burning、剧毒 venom_stack） |
| `EFFECT_STAT_ADD` / `EFFECT_STAT_MULTIPLY` | 属性加成/乘算 |
| `EFFECT_SHIELD` | 护盾 |
| `EFFECT_CONTROL` | 控制效果（Slow/Root/Stun/Freeze/Taunt） |
| MARK | `putrid_mark` 等标记类效果 |

### 叠层策略

项目已实现 13 种叠层策略，由 `UnitEffectController.apply_effect()` 根据 `stack_policy` 字段分发处理。详见下文"叠层策略详解"章节。

### 燃烧 / burning

- 普攻、技能、死亡场地均可施加
- 标准 DoT 生命周期，单位死亡时清理

### 剧毒 / venom_stack

- 单状态记录层数，每层 `5/s`
- 刷新持续时间，过期后每秒衰减 5 层
- 剧毒羁绊已通过 `StatusEffectFactory` 修改状态数据

### 叠层策略详解

所有策略按 `stack_group_key` 分组判断（默认等于 `stack_key` 或 `effect_id`，`PER_SOURCE` 模式下追加来源标识）。

| # | 策略常量 | 策略名 | 核心行为 | 适用场景 |
| --- | --- | --- | --- | --- |
| 1 | `REFRESH_ONLY` | 仅刷新 | 同组已存在 → `refresh()` 完全替换字段并重置持续时间；不存在 → 新建 | 常规 Buff/Debuff |
| 2 | `IGNORE_IF_ACTIVE` | 激活时忽略 | 同组已存在 → 不做任何事；不存在 → 新建 | 一次性事件标记 |
| 3 | `EXTEND_DURATION` | 延长持续时间 | 同组已存在 → 累加持续时间（可设 `max_duration` 上限）；不存在 → 新建 | 连续命中延长效果 |
| 4 | `STACK_REFRESH_DURATION` | 堆叠+刷新全组 | 可多层共存，新建后刷新全组所有实例的持续时间 | 共享持续时间的叠加减益 |
| 5 | `STACK_INDEPENDENT_DURATION` | 堆叠+独立计时 | 可多层共存，各层独立计时，不刷新其他实例 | 多来源独立 DoT |
| 6 | `UNIQUE_PER_SOURCE_REFRESH` | 每来源唯一 | 每来源上限 1（`group_key` 含来源标识），同来源刷新，不同来源共存 | 来源唯一标记 |
| 7 | `UNIQUE_PER_SOURCE_INDEPENDENT` | 每来源唯一（独立） | 与上者行为一致，同来源刷新 | — |
| 8 | `STACK_PER_SOURCE_CAP_REFRESH` | 每来源上限堆叠+刷新 | 每来源上限 `max_stacks_per_source`（默认 3），达上限后溢出处理，新建后刷新全组 | 同来源可叠加但有上限 |
| 9 | `STACK_PER_SOURCE_CAP_INDEPENDENT` | 每来源上限堆叠+独立 | 每来源上限默认 3，达上限后溢出处理，不刷新全组 | 同来源有上限且独立计时 |
| 10 | `PERMANENT_STACK` | 永久堆叠 | 可多层共存，强制 `duration_mode = NONE`（永久持续） | 永久标记/被动叠加 |
| 11 | `STRONGEST_WINS` | 强者胜出 | 同组只保留最强；新效果更强 → 完全替换，更弱 → 只刷新持续时间 | 护盾值取最大 |
| 12 | `REFRESH_LONGER_DURATION` | 仅当更长时刷新 | 新 `duration` > 已有 `remaining_time` 才刷新，否则忽略 | 防止短持续覆盖长持续 |
| 13 | `REPLACE_BY_LAST` | 后覆盖 | 同组已存在 → `expire()` + 移除旧效果，新建替换 | 嘲讽等后施加覆盖旧效果 |

#### 溢出处理

堆叠策略达到上限时，由 `overflow_policy` 控制：

| 溢出策略 | 行为 |
| --- | --- |
| `DROP_NEW`（默认） | 丢弃新效果 |
| `REFRESH_OLDEST` | 刷新最旧实例的数据 |
| `REPLACE_OLDEST` | 移除最旧实例，创建新效果 |
| `REPLACE_WEAKEST` | 移除最弱实例，创建新效果 |

#### 特殊效果硬编码

**剧毒 `venom_stack`** 和 **燃烧 `burning`** 不走普通叠层策略，有专用处理：

- **剧毒**：同 effect_id 查找 → 调用 `add_venom_stacks()` 叠加层数并刷新持续时间；持续时间结束后进入衰减模式，每秒衰减 5 层直到层数清零。
- **燃烧**：同 effect_id 查找 → 调用 `add_burning_damage()` 将新伤害值**相加**到 `value`，持续时间取当前剩余时间与新持续时间的**较大值**。

---

## 二、控制效果系统（已实现）

`scripts/combat/unit_control_state.gd` 保存单位当前最终控制状态，从 `UnitEffectController.effects` 重建，提供安全查询。控制系统已接入移动、普攻、施法、索敌和伤害结算。

### 控制类型

| 控制 | 移动 | 普攻 | 施法 | 索敌 | 说明 |
| --- | --- | --- | --- | --- | --- |
| Slow / 减速 | 降速 | ✅ | ✅ | ✅ | `move_speed_multiplier` / `attack_cooldown_rate_multiplier` / `mana_regen_multiplier` 均取最小值，保底 0.20 |
| Root / 禁锢 | ❌ | ✅ | ✅ | ✅ | 范围内可攻击，不在范围原地等 |
| Stun / 眩晕 | ❌ | ❌ | ❌ | - | 魔力保留，攻击冷却继续计时，不取消已发射弹道 |
| Freeze / 冻结 | ❌ | ❌ | ❌ | - | 等同眩晕；`skill_damage_taken_multiplier` 只增强技能伤害 |
| Taunt / 嘲讽 | ✅ | ✅ | ✅ | ❌ | 强制以嘲讽者为目标，后施加覆盖旧嘲讽 |

### 控制效果的叠层策略

控制效果通过 `StatusEffectFactory.apply_control_effect()` 统一施加，不同控制类型使用不同的默认叠层策略：

| 控制类型 | 默认叠层策略 | 行为说明 |
| --- | --- | --- |
| SLOW / ROOT / STUN / FREEZE | `REFRESH_LONGER_DURATION` | 新持续时间 > 已有剩余时间时才刷新；否则保留原有效果。防止短控覆盖长控。 |
| TAUNT | `REPLACE_BY_LAST` | 后施加的嘲讽完全替换前一个（移除旧效果，新建替换）。确保同一时刻只有一个有效嘲讽目标。 |

**分组规则**：控制效果的 `stack_group_key` 默认按 `control_type` 分组（如所有 `SLOW` 共享一个组）。这意味着：
- 同一目标身上的多个减速效果按策略竞争/合并，最终由 `UnitControlState.rebuild()` 聚合为单一行动状态
- 不同来源的同类控制（如两个单位的 SLOW）会根据策略决定是叠加实例还是互相覆盖

**SLOW 的特殊聚合**：减速效果在 `UnitControlState` 中按字段分别聚合：
- `move_speed_multiplier` = min(所有减速实例)
- `attack_cooldown_rate_multiplier` = min(所有减速实例)
- `mana_regen_multiplier` = min(所有减速实例)

即使多个 SLOW 效果共存（如 0.5× 和 0.7×），最终取最强的 0.5×。强减速过期后，若弱减速仍在，自动回落到 0.7×。

### 行动能力聚合

```
can_move     = 无 root/stun/freeze
can_attack   = 无 stun/freeze
can_cast     = 无 stun/freeze
can_retarget = 无 taunt
move_speed_multiplier = min(所有 slow 的 move_speed_multiplier)
attack_cooldown_rate_multiplier = min(所有 slow 的 attack_cooldown_rate_multiplier)
mana_regen_multiplier = min(所有 slow 的 mana_regen_multiplier)
skill_damage_taken_multiplier = max(所有 freeze)，默认 1.0
```

### 控制抗性

| 单位类型 | control_duration_multiplier | hard_control_duration_multiplier |
| --- | --- | --- |
| 普通单位/召唤物 | 1.0 | 1.0 |
| 精英敌人 | 0.8 | 0.6 |
| Boss | 0.6 | 0.35 |

### StatusEffect 控制扩展

`StatusEffect` 已扩展以下字段：
- `EFFECT_CONTROL` / `CATEGORY_CONTROL`
- 控制类型常量：`CONTROL_SLOW` / `CONTROL_ROOT` / `CONTROL_STUN` / `CONTROL_FREEZE` / `CONTROL_TAUNT`
- `move_speed_multiplier`、`attack_cooldown_rate_multiplier`、`mana_regen_multiplier`
- `disable_movement` / `disable_attack` / `disable_cast` / `disable_retarget`
- `forced_target`、`forced_target_unit_id`
- `skill_damage_taken_multiplier`

### UnitControlState 字段

`scripts/combat/unit_control_state.gd`：
- `can_move`、`can_attack`、`can_cast`、`can_retarget`
- `move_speed_multiplier`、`attack_cooldown_rate_multiplier`、`mana_regen_multiplier`
- `forced_target`、`forced_target_unit_id`
- `is_slowed`、`is_rooted`、`is_stunned`、`is_frozen`、`is_taunted`
- `skill_damage_taken_multiplier`
- `active_control_types`

### 已实现接入点

| 系统 | 文件 | 接入方式 |
| --- | --- | --- |
| 移动 | `scripts/unit_targeting.gd` | `can_move` + `move_speed_multiplier` |
| 普攻 | `scripts/unit.gd` | `can_attack` |
| 技能 | `scripts/unit_skill.gd` | `can_cast`，满魔不清空 |
| 索敌 | `scripts/unit_targeting.gd` | 优先 `forced_target`，卡住检测不清空嘲讽目标 |
| 敌方技能目标 | `scripts/combat/active_skill_caster.gd` | `_get_offensive_skill_target()`，治疗/护盾不受嘲讽影响 |
| 冻结增伤 | `scripts/combat/combat_resolver.gd` | `resolve_skill_damage()` 中读取 `skill_damage_taken_multiplier` |
| 状态重建 | `scripts/unit_effect_controller.gd` | 效果创建/刷新/移除/过期后调用 `rebuild_control_state()` |
| UI 标签 | `scripts/combat/unit_control_state.gd` | `get_ui_tags()` 返回中文标签（冻/晕/缚/嘲/缓） |

---

## 三、控制效果测试单位（已实现）

5 个玩家单位已完整实现，每个聚焦一种控制效果：

| 控制 | 单位 | ID | 稀有度 | 定位 | 主动技能 |
| --- | --- | --- | --- | --- | --- |
| 减速 | 霜箭哨手 / Frost Sentry | `frost_sentry` | FINE | 后排软控 | `pinning_frost` |
| 禁锢 | 藤缚卫士 / Vine Binder | `vine_binder` | RARE | 辅助控制 | `vine_snare` |
| 眩晕 | 震锤先锋 / Thundermaul Vanguard | `thundermaul_vanguard` | RARE | 前排硬控 | `hammer_stun` |
| 冻结 | 冰棱术士 / Frost Prism Mage | `frost_prism_mage` | EPIC | 法术硬控 | `frost_prison` |
| 嘲讽 | 挑衅旗手 / Taunt Banneret | `taunt_banneret` | RARE | 前排目标控制 | `challenge_banner` |

主动技能实现位置：`scripts/combat/active_skill_caster.gd`（`_cast_pinning_frost` 至 `_cast_challenge_banner`）。
被动技能实现位置：`scripts/combat/passive_resolver.gd`（`frost_arrow`、`tangled_growth`、`concussive_armor`、`shatter_focus`、`banner_guard`）。

这 5 个单位的数据资源位于 `data/units/*.tres`，已接入 `UnitCatalog`、商店刷新池和内容总览。

---

## 四、边界情况

1. 目标被控期间死亡：清空状态并重置控制状态
2. 控制来源死亡：除嘲讽外，已有控制继续计时
3. 嘲讽来源死亡/不可选中：forced_target 失效，恢复正常索敌
4. 已发射弹道/已生成场地不因施法者被控而取消
5. Boss/精英控制时长缩减已生效
6. 战斗结束/Restart 后控制状态重置
7. 战斗加速下控制持续时间按战斗时间缩放
