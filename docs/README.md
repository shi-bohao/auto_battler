# 项目文档目录

更新时间：2026-06-02

本文档说明 `docs/` 目录下各文档的用途、维护优先级和过期文档处理方式。判断当前项目真实状态时，优先级为：实际代码与资源 > `content_reference.md` > `project_status.md` > 专题设计文档 > 历史设计记录。

## 首选入口

| 文档 | 用途 | 维护方式 |
| --- | --- | --- |
| `../README.md` | GitHub 首页与项目当前状态摘要 | 对外展示前必须保持严格真实 |
| `project_status.md` | 当前项目进度、系统范围、目录结构、近期更新和验证命令 | 完成系统级功能或流程调整后更新 |
| `content_reference.md` | 当前玩家单位、英雄、敌人、召唤物和遗物的数值/技能/羁绊总览 | 通过 `scripts/tools/generate_content_reference.gd` 自动生成，**不手改** |

## 系统规则文档（`systems/`）

| 文档 | 范围 |
| --- | --- |
| `combat_system.md` | 索敌设计：自动索敌、目标合法性、目标黏性和攻击系统协作 |
| `status_effect_system.md` | Buff/Debuff、燃烧、剧毒 + 控制效果系统（Slow/Root/Stun/Freeze/Taunt） |
| `stat_modifier_system.md` | 运行时属性修饰器层级、动态属性、来源移除和验证入口 |
| `summon_system.md` | 召唤物、召唤上限、召唤事件 |
| `bond_system.md` | 6 类羁绊的成员、档位效果、战斗事件接入和 UI 查询 |
| `hero_system.md` | 英雄系统规则 |
| `relic_system.md` | 遗物触发、光环、永久成长 |
| `progression_system.md` | 路径选择、商人、训练、事件、宝箱、波次推进 |
| `snapshot_and_mirror.md` | 阵容快照 + 镜像挑战 |
| `ui_system.md` | UI 分层、主界面 HUD、单位详情、出售区域、战斗统计、商店、奖励选择 |

## 内容设计文档（`content/`）

设计意图文档，不放精确数值长表。数值以 `content_reference.md` 为准。

| 文档 | 范围 |
| --- | --- |
| `unit_design.md` | 玩家单位设计意图和扩展规划 |
| `enemy_design.md` | 普通/精英/BOSS/史莱姆/蛆虫统一敌人设计 |
| `summon_design.md` | 骷髅、傀儡等召唤物设计 |
| `relic_design.md` | 遗物设计意图和扩展规划 |
| `hero_design.md` | 英雄设计意图和强化方向 |

## 素材与测试流程（`pipeline/`）

| 文档 | 范围 |
| --- | --- |
| `asset_pipeline.md` | 美术素材处理、切图、导入导出 |
| `testing.md` | Godot 检查命令、测试脚本、导出验证 |

## 历史文档（`archive/`）

| 文档 | 说明 |
| --- | --- |
| `feature_design_log.md` | 已完成大型功能的设计记录、实现入口和边界条件，只做追溯，不作为当前规格 |
| `changelog.md` | 2026-05-28 及更早的历史更新日志 |

## 已合并或移除的旧文档

以下文档已在 2026-06-02 文档重组中合并或移除：

| 操作 | 文档 | 去向 |
| --- | --- | --- |
| 合并 | `ui_layering_design.md`、`ui_and_stats_design.md`、`shop_ui_design.md`、`reward_ui_design.md` | → `systems/ui_system.md` |
| 合并 | `slime_enemy_design.md`、`maggot_enemy_design.md` | → `content/enemy_design.md` |
| 合并 | `control_effect_system_design.md`、`control_test_units_design.md` | → `systems/status_effect_system.md` |
| 合并 | `lineup_snapshot_design.md`、`mirror_challenge_design.md` | → `systems/snapshot_and_mirror.md` |
| 移动 | `feature_design_log.md` | → `archive/feature_design_log.md` |
| 更名 | `stat_modifier_system_design.md` → `systems/stat_modifier_system.md` | |
| 更名 | `path_selection_design.md` → `systems/progression_system.md` | |
| 更名 | `索敌设计.md` → `systems/combat_system.md` | |
| 提取 | `project_status.md` 中 2026-05-28 及更早更新 | → `archive/changelog.md` |

## 维护规则

1. **数值、技能描述、单位/遗物清单只认 `content_reference.md`，并且只由脚本生成，不手改。**
2. 当前状态 → `project_status.md`
3. 系统规则 → `systems/*.md`
4. 内容设计意图 → `content/*.md`
5. 素材/测试流程 → `pipeline/*.md`
6. 历史方案 → `archive/*.md`
7. 新增系统时同步更新 `project_status.md`，并按需要新增或更新对应专题文档。
8. 旧草案如果与实现不一致，应删除或移入 `archive/`。

## 常用维护命令

```text
# 编译检查
Godot_v4.6.2-stable_win64_console.exe --headless --path . --check-only --script res://scripts/main.gd

# 刷新内容参考文档
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_content_reference.gd
```

`generate_content_reference.gd` 会扫描 `data/units`、`data/heroes`、`data/enemies`、`data/summons` 和 `data/relics`，按 `catalog_id` 稳定排序，并重写 `docs/content_reference.md`。
