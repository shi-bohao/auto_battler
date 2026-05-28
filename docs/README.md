# 项目文档目录

更新时间：2026-05-28

本文档说明 `docs/` 目录下各文档的用途、维护优先级和过期文档处理方式。判断当前项目真实状态时，优先级为：实际代码与资源 > `content_reference.md` > `project_status.md` > 专题设计文档 > 历史设计记录。

## 首选入口

| 文档 | 用途 | 维护方式 |
| --- | --- | --- |
| `../README.md` | GitHub 首页与项目当前状态摘要 | 对外展示前必须保持严格真实 |
| `project_status.md` | 当前项目进度、系统范围、目录结构、近期修复和验证命令 | 完成系统级功能或流程调整后更新 |
| `content_reference.md` | 当前玩家单位、英雄、敌人、召唤物和遗物的数值/技能/羁绊总览 | 通过 `scripts/tools/generate_content_reference.gd` 重新生成 |
| `feature_design_log.md` | 已完成大型功能的设计记录、实现入口和边界条件 | 新功能完成后补充实现入口；不再使用“待实现”旧口径 |

## 当前专题文档

| 文档 | 维护范围 |
| --- | --- |
| `unit_design.md` | 玩家单位、扩展属性、星级成长和高稀有度单位设计参考；当前精确数值以 `content_reference.md` 为准 |
| `hero_design.md` | 英雄系统、英雄成长、强化规则、英雄选择 UI 和英雄素材接入 |
| `relic_design.md` | 遗物结构、触发类型、当前遗物池、常驻光环、金币遗物和永久成长遗物 |
| `bond_system.md` | 6 类羁绊的成员、档位效果、战斗事件接入和 UI 查询 |
| `stat_modifier_system_design.md` | 运行时属性修饰器层级、动态属性、来源移除和验证入口 |
| `path_selection_design.md` | 波次路径选择、商人、训练场、事件、宝箱、Boss 锁定和过渡动画 |
| `lineup_snapshot_design.md` | Boss 胜利阵容快照保存、结构和还原入口 |
| `mirror_challenge_design.md` | 镜像挑战入口、快照选择和 Boss 替换规则 |
| `maggot_enemy_design.md` | 蛆虫族敌人设计；当前实现使用剧毒 `venom_stack`，腐痕 `putrid_mark` 不是持续伤害 |
| `ui_layering_design.md` | UI 大层级、语义 `z_index` 常量和新增 UI 分层规则 |
| `ui_and_stats_design.md` | 单位详情、遗物显示、奖励详情、出售区域、战斗统计和 UI 性能规则 |
| `shop_ui_design.md` | 商店栏位、购买状态、详情提示和购买单位后的预览复用策略 |
| `reward_ui_design.md` | 奖励三选一结构、文本、稀有度颜色和悬停详情规则 |
| `索敌设计.md` | 自动索敌、目标合法性、目标黏性和攻击系统协作设计 |

## 已合并或移除的旧文档

以下文档已从当前文档集移除，原因是内容被现有入口覆盖，继续保留容易误导后续维护。需要历史内容时可通过 Git 历史查看。

| 已移除文档 | 替代入口 |
| --- | --- |
| `phase_summary_2026-05-04.md` | `project_status.md` |
| `refactor_plan_2026-05-06.md` | `project_status.md` 的目录结构与脚本职责章节 |
| `unit_skill_design.md` | `content_reference.md`、`unit_design.md`、`scripts/combat/` |
| `unit_design_with_new_units.md` | `unit_design.md`、`content_reference.md` |
| `enemy_design.md` | `content_reference.md`、`maggot_enemy_design.md`、`scripts/catalog/enemy_catalog.gd` |
| `future_features.md` | 已改名为 `feature_design_log.md` |

## 维护规则

- README 只写已经实现且当前可验证的内容，不写愿景式承诺。
- 新增单位、敌人、召唤物、英雄或遗物后，优先运行内容总览生成脚本。
- 新增系统时同步更新 `project_status.md`，并按需要新增或更新专题文档。
- 已完成的大型功能设计保留在 `feature_design_log.md`，但不要再把它当作待办清单。
- 旧草案如果与实现不一致，应删除或在本文件中明确标注替代入口。

## 常用维护命令

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\main_check.log --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\content_reference.log --script res://scripts/tools/generate_content_reference.gd
```

`generate_content_reference.gd` 会扫描 `data/units`、`data/heroes`、`data/enemies`、`data/summons` 和 `data/relics`，并重写 `docs/content_reference.md`。
