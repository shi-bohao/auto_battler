# 项目文档目录

更新时间：2026-05-23

本文档用于说明 `docs/` 目录下各文档的用途、新旧关系和维护入口。后续新增系统时，优先更新“当前维护文档”和对应专题文档；历史文档只在需要保留开发脉络时追加备注。

## 当前维护文档

| 文档 | 用途 | 维护建议 |
| --- | --- | --- |
| `project_status.md` | 当前项目进度、系统范围、目录结构和验证命令入口 | 每次完成系统级功能后更新 |
| `future_features.md` | 功能规划与实现记录；当前记录远程普攻真实弹道与非圆形瞬时 AoE，二者均已于 2026-05-23 完成 | 后续新功能先在此文档记录设计，再拆分实现；完成后保留实现入口 |
| `content_reference.md` | 当前玩家单位、英雄、敌人、召唤物和遗物的数值、技能、羁绊总览 | 通过 `scripts/tools/generate_content_reference.gd` 重新生成 |
| `relic_design.md` | 遗物系统结构、当前遗物池、触发入口和新增流程 | 新增或调整遗物时更新 |
| `bond_system.md` | 羁绊成员、档位效果、战斗接入、UI 和验证方式 | 新增羁绊或调整羁绊数值时更新 |
| `hero_design.md` | 英雄系统设计、英雄成长和强化规则 | 新增英雄或调整英雄升级/强化时更新 |
| `lineup_snapshot_design.md` | Boss 胜利阵容快照保存与还原规则 | 调整快照字段或用途时更新 |
| `mirror_challenge_design.md` | 镜像挑战模式规则和快照接入 | 调整新模式流程时更新 |

## UI 与流程专题文档

这些文档记录当前 UI/流程设计中的一部分，仍有参考价值，但局部内容可能已被后续迭代扩展。查看时应同时核对 `project_status.md` 和实际代码。

| 文档 | 当前状态 |
| --- | --- |
| `shop_ui_design.md` | 商店栏位、购买状态和遗物详情规则基本仍可参考；按钮样式以当前代码生成像素风 UI 为准 |
| `reward_ui_design.md` | 奖励三选一规则仍可参考；当前实现已加入悬停详情、单位技能详情和英雄强化复用 |
| `ui_and_stats_design.md` | 主 UI、单位详情、遗物栏、统计面板的历史设计说明；当前主菜单和战斗 HUD 已改为统一代码生成像素风 |
| `索敌设计.md` | 寻敌与索敌规则设计文档，仍可作为目标选择逻辑参考 |

## 历史记录与已完成计划

这些文档用于保留阶段开发背景，不应作为当前规格的唯一来源。

| 文档 | 说明 |
| --- | --- |
| `phase_summary_2026-05-04.md` | 2026-05-04 阶段快照，已被后续系统迭代扩展 |
| `refactor_plan_2026-05-06.md` | 已完成的结构重构计划和过程记录 |

## 已过期或草案性质文档

这些文档中的内容已经被当前实现和新文档覆盖，仅保留为设计草稿或历史上下文。

| 文档 | 替代入口 |
| --- | --- |
| `unit_skill_design.md` | 当前单位技能请看 `content_reference.md`；实现入口看 `scripts/combat/` |
| `unit_design_with_new_units.md` | 新单位已实现，当前数值请看 `content_reference.md` 和 `unit_design.md` |
| `enemy_design.md` | 敌人当前数值请看 `content_reference.md`；该文档更多作为敌人设计草案 |
| `提示词.md` | 历史占位文件，不作为项目规格来源 |

## 常用维护命令

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tools/generate_content_reference.gd
```

`generate_content_reference.gd` 会扫描 `data/units`、`data/heroes`、`data/enemies`、`data/summons` 和 `data/relics`，并重写 `docs/content_reference.md`。
