# 羁绊系统设计与实现记录

更新时间：2026-05-28

本文档记录第一版羁绊系统的成员、档位效果、运行时规则和验证方式，方便后续扩展新单位或调整数值。

2026-05-28 更新：面板尺寸修复（remove_child + call_deferred）、羁绊详情添加成员列表（单位+英雄）、单位详情面板添加彩色羁绊标签按钮（左键点击查看详情弹窗）、图鉴新增羁绊分类栏。

## 数据字段

`UnitData` 新增字段：

```gdscript
@export var bond_tags: Array[String] = []
```

运行时 `Unit` 同步保留 `bond_tags`，由 `UnitDataApplier` 从资源复制。英雄对应的 UnitData 资源同样可以配置 `bond_tags`。

## 统计规则

统计入口集中在 `scripts/bond_manager.gd`。

- 只统计当前上场普通单位和已选英雄。
- 不统计备战席。
- 不统计召唤物。
- 同一种 `unit_type` 只计 1 次。
- 一个单位拥有多个 `bond_tags` 时，会同时为多个羁绊计数。
- 资源不存在或未配置标签时跳过，不报错。
- 每场战斗重新统计，羁绊加成只写入运行时 `Unit`，不永久修改 `UnitData`。

## 羁绊成员

| 羁绊 | ID | 成员 |
| --- | --- | --- |
| 铁壁 | `iron_wall` | `warrior`、`tank`、`guardian_captain`、`greatsword_knight`、`starforged_vanguard`、`iron_oath_commander` |
| 猎手 | `hunter` | `archer`、`assassin`、`greatsword_knight`、`bomb_thrower`、`nightblade_captain`、`bloodbound_berserker`、`bloodshadow_hunter` |
| 奥术 | `arcane` | `mage`、`alchemist`、`bomb_thrower`、`arcane_artillerist`、`prism_weaver`、`wind_chanter`、`arcane_mentor` |
| 圣疗 | `divine` | `priest`、`cleric`、`forest_druid`、`bard`、`dawnbell_saint` |
| 召唤 | `summon` | `necromancer`、`puppet_warlock`、`soul_binder`、`hero_boneweaver`（织骨者英雄） |
| 剧毒 | `venom` | `plague_caster`、`alchemist`、`venom_matriarch` |

召唤物如 `summoned_skeleton`、`summoned_puppet` 不配置召唤羁绊计数标签。

## 档位效果

### 铁壁 `iron_wall`

只影响拥有 `iron_wall` 标签的玩家单位。

| 档位 | 效果 |
| --- | --- |
| 2 | 成员防御 +10 |
| 4 | 成员防御 +20；战斗开始成员获得 30 护盾 |
| 6 | 成员防御 +35；战斗开始成员获得 60 护盾；成员受到生命伤害降低 15% |

### 猎手 `hunter`

只影响拥有 `hunter` 标签的玩家单位。

| 档位 | 效果 |
| --- | --- |
| 2 | 成员暴击率 +8% |
| 4 | 成员暴击率 +15%；暴击伤害倍率 +0.25 |

### 奥术 `arcane`

| 档位 | 效果 |
| --- | --- |
| 2 | 全体玩家单位技能强度 +10% |
| 4 | 全体玩家单位技能强度 +18%；奥术成员魔力回复速度 +15% |
| 6 | 全体玩家单位技能强度 +28%；奥术成员魔力回复速度 +25%；奥术成员获得 30 初始魔力，不超过上限 |

### 圣疗 `divine`

| 档位 | 效果 |
| --- | --- |
| 2 | 全体玩家单位治疗强度 +15% |
| 4 | 全体玩家单位治疗强度 +25%；护盾强度 +15% |
| 6 | 全体玩家单位治疗强度 +35%；护盾强度 +25%；战斗开始获得固定 25 护盾 |

### 召唤 `summon`

| 档位 | 效果 |
| --- | --- |
| 2 | 玩家召唤物攻击力 +15%，最大生命 +15% |
| 3 | 玩家召唤物攻击力 +25%，最大生命 +25%；友方召唤单位死亡时，随机 1 个存活非召唤玩家单位获得 30 护盾和 20 魔力 |

新生成的玩家召唤物会通过 `BondManager.apply_bonds_to_summoned_unit(unit)` 立即获得当前召唤羁绊加成。每个召唤物死亡事件最多触发一次 3 召唤奖励。

### 剧毒 `venom`

| 档位 | 效果 |
| --- | --- |
| 2 | 玩家单位施加的剧毒每跳伤害 +4 |
| 3 | 玩家单位施加的剧毒每跳伤害 +8；施加剧毒时额外增加 1 层，同一目标 2 秒冷却 |

剧毒入口统一经过 `StatusEffectFactory.apply_status_effect()`，再由 `BattleManager.modify_status_effect_data_for_bonds()` 转发给 `BondManager.modify_status_effect_data()`。

## 战斗接入

当前顺序：

1. `BattleManager` 生成玩家单位、英雄单位和敌方单位。
2. `BattleManager.start_battle()` 启动运行时单位状态。
3. `BondManager.apply_battle_start_bonds(left_units)` 统计并应用战斗开始羁绊。
4. 被动与遗物继续按既有流程触发。
5. 召唤物生成后调用 `apply_bonds_to_summoned_unit()`。
6. 单位死亡时调用 `handle_unit_died()` 处理 3 召唤事件。
7. 剧毒施加时调用 `modify_status_effect_data()` 处理剧毒伤害和额外层数。

## UI

主界面由 `main.gd` 动态创建羁绊面板。

显示规则：

- 只显示已激活羁绊。
- 没有激活羁绊时显示 `羁绊：无`。
- 羁绊以可点击名称按钮展示，格式示例：`铁壁 2/6`、`猎手 4/4`、`召唤 3/3`。
- 点击某个羁绊名称后，显示该羁绊当前计数、当前激活档位和各档效果说明。
- 当前已选中的羁绊按钮会高亮；再次点击同一羁绊会关闭详情。
- 面板位于商店按钮下方；商店打开时隐藏，关闭商店后恢复刷新，避免重叠。
- 准备阶段上阵/下阵、英雄选择后刷新。
- 战斗开始时使用当前上场阵容对应的统计结果。

## 验证清单

自动测试：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_bond_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_summon_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_status_effect_stack_policy.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_hero_battle_spawn.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

手工验证重点：

1. 准备阶段只上阵 `archer`、`archer`、`assassin`，猎手计数应为 2。
2. 将 `bomb_thrower` 上阵后，猎手显示应提升为 3 计数但仍激活 2 档。
3. 选择血影猎手后，猎手计数应包含英雄。
4. 上阵铁壁成员，确认铁壁只给铁壁成员加防御和护盾。
5. 上阵猎手成员，确认暴击加成只给猎手成员。
6. 上阵奥术成员，确认技能强度全队生效，魔力回复和初始魔力只给奥术成员。
7. 上阵圣疗成员，确认治疗强度和护盾强度全队生效。
8. 上阵召唤成员并生成召唤物，确认新召唤物攻击和生命提高。
9. 达成 3 召唤后让友方召唤物死亡，确认存活非召唤友军获得护盾和魔力。
10. 达成 3 剧毒后施加剧毒，确认伤害提升并在 2 秒冷却允许时追加 1 层。
