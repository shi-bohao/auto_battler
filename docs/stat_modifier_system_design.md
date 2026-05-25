# 属性修饰器系统设计

更新时间：2026-05-25

本文档记录当前运行时属性加成的长期维护方案。该系统用于承接常驻光环、动态金币光环、Buff/Debuff 属性修改、羁绊属性、英雄/被动战斗加成和加时赛加成，避免不同系统直接改写同一个 `Unit` 字段后互相覆盖。

## 核心文件

| 文件 | 职责 |
| --- | --- |
| `scripts/combat/stat_modifier.gd` | 单条属性修饰数据，包含来源、属性名、层级、数值、动态计算键和参数 |
| `scripts/combat/unit_stat_controller.gd` | 挂在运行时 `Unit` 上，保存基础属性和所有 modifier，按固定顺序重算最终属性 |
| `scripts/unit.gd` | 对外提供 `add_stat_modifier()`、`remove_stat_modifier()`、`remove_stat_modifiers_by_source()`、`recalculate_stats()` |
| `scripts/relic/relic_effect_resolver.gd` | 遗物光环和动态金币光环的 modifier 接入 |
| `scripts/bond_manager.gd` | 羁绊战斗开始属性加成的 modifier 接入 |
| `scripts/status_effect.gd` | Buff/Debuff 中 `STAT_ADD`、`STAT_MULTIPLY` 的 modifier 接入 |

## 计算层级

`UnitStatController` 按以下顺序计算每个属性：

1. `BASE_OVERRIDE`
2. `PERMANENT_FLAT`
3. `PERMANENT_PERCENT`
4. `RUNTIME_FLAT`
5. `RUNTIME_PERCENT`
6. `FINAL_FLAT`
7. `FINAL_PERCENT`
8. `FINAL_MULTIPLY`

当前公式可以理解为：

```text
base
→ permanent flat
→ permanent percent
→ runtime flat
→ runtime percent
→ final flat
→ final percent
→ final multiply
```

示例：基础攻击 100，永久 +10，永久 +10%，动态 +5，动态 +10%，最终 +100% 攻击属性时，会按层级得到：

```text
(((100 + 10) * 1.10 + 5) * 1.10) * 2.0
```

如果设计文本是“造成的伤害 +100%”，不应放入 `attack_damage` 属性层，而应放到后续的伤害结算层。属性层负责单位面板和战斗属性，伤害层负责最终输出倍率。

## 支持属性

当前已接入的属性包括：

- `max_hp`
- `attack_damage`
- `crit_chance`
- `crit_damage_multiplier`
- `defense`
- `skill_power`
- `healing_power`
- `shield_power`
- `defense_penetration`
- `life_steal`
- `damage_reduction`
- `damage_taken_multiplier`
- `initial_mana`
- `mana_on_attack`
- `mana_on_hit_taken`
- `status_resistance`
- `dodge_chance`
- `attack_range`
- `search_range`
- `move_speed`
- `attack_interval`
- `max_mana`
- `mana_regen_per_second`
- `active_skill_damage_multiplier`
- `active_heal_multiplier`

整数属性会在写回 `Unit` 时取整并做下限保护；百分比类属性会按各自语义 clamp。

## 动态光环

动态属性通过 `dynamic_key + params + context` 计算。当前支持：

| `dynamic_key` | 用途 |
| --- | --- |
| `gold_flat_step_capped` | 每 N 金币获得固定属性，带上限；用于金甲契约 |
| `gold_percent_capped` | 每 1 金币获得百分比，带上限；用于黄金护符 |
| `gold_percent_step` | 每 N 金币获得百分比，无上限；用于贪婪王冠 |

金币变化后，`EconomyManager.gold_changed` 会触发 `main.gd` 刷新 `BattleManager.refresh_dynamic_relic_auras()`，从而对当前玩家单位、备战单位和镜像敌方单位重新计算动态 modifier。准备阶段拖动站位或购买动态光环遗物后，也会主动刷新。

## 来源与移除

每个 modifier 必须提供稳定来源：

- `modifier_id`：单条 modifier 的唯一键。
- `source_key`：同一来源的一组 modifier，例如 `relic:golden_charm`、`bond:arcane`、`status:poison_vulnerable`。

需要整体刷新某类效果时，优先调用 `remove_stat_modifiers_by_source(source_key)`，再按当前上下文重新添加。动态金币遗物就是这样避免重复叠加的。

## 当前接入范围

- 常驻 `AURA` 遗物，包括静态光环和金币动态光环。
- Buff/Debuff 的属性加算和乘算。
- 羁绊的战斗开始属性效果。
- 英雄/单位被动中部分战斗开始属性光环。
- `add_battle_attack_bonus_percent()` 击杀/战斗中攻击力百分比增长。
- 加时赛攻击力和攻速加成。

仍建议后续新增属性类效果优先通过 modifier 接入；只有一次性护盾、治疗、恢复魔力、直接伤害等非属性效果继续走原有即时结算入口。

## 验证入口

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_stat_modifier_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_status_effect_stack_policy.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_kill_relics.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_summon_system.gd
```
