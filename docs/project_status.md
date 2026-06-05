# 自动对战 Demo 项目状态总览

更新时间：2026-06-02（含新 BOSS、新精英敌人、史莱姆系列敌人、导出资源修复、玩家单位/遗物素材改为数据资源显式引用、图鉴导出资源扫描兼容）

> 文档导航见 `docs/README.md`。本文档作为当前项目进度入口；单位、英雄、敌人、召唤物和遗物的数值核对以 `docs/content_reference.md` 为准。各系统分别参考对应专题文档：`docs/systems/` 下为系统规则，`docs/content/` 下为设计意图，`docs/pipeline/` 下为素材与测试流程。历史设计记录和更早的更新日志见 `docs/archive/`。

## 项目概览

本项目是一个 Godot 4 + GDScript 制作的 2D 肉鸽自走棋 Demo。

当前 Demo 已经从最初的单场自动战斗，扩展为包含主菜单、英雄选择、准备阶段、自动战斗、战斗加速、加时赛提示、30 波推进、奖励三选一、10 格分类商店、单位解锁与升星提醒、遗物系统、英雄系统、羁绊系统、召唤系统、Buff/Debuff 堆叠体系、运行时属性修饰器、图鉴、Boss 阵容快照、镜像挑战、远程普攻真实弹道、非圆形瞬时 AoE、常驻光环遗物、本局永久属性成长、英雄与玩家单位静态美术资源、主菜单/战斗背景图库切换、中文文本、战斗统计、路径选择系统（6 种节点类型）和结束回主菜单流程的可玩原型。

当前项目仍然聚焦在自动战斗与局内成长循环验证，路线地图、装备背包、战斗回放和存档系统仍未纳入当前 Demo 范围。

截至当前版本，早期 6 阶段结构重构已经完成：UI 控制器、流程/经济、阵容服务、遭遇生成、技能/遗物效果和 UI 子场景均已完成拆分。过期阶段总结和重构计划已从当前文档集中移除，目录和职责以本文档下方说明为准。

当前统计：**30 个玩家单位、4 个英雄、32 个敌方单位、8 个召唤物、43 个遗物**。

## 2026-06-02 新 BOSS 与新精英敌人

本轮新增 5 个 BOSS 与 4 个精英敌人，并接入敌方单位池、推荐站位、技能系统、被动触发、场地效果、召唤物、图鉴/内容总览和测试：

- **新 BOSS（5 个）**：树妖领主（恢复/控制）、沼泽吞噬者（吞噬成长）、熔岩巨人（AoE/燃烧场地）、天灾领主（亡灵召唤）、森精灵之王（AoE/治疗增幅）。详细机制见 `docs/content/enemy_design.md`。
- **新精英敌人（4 个）**：铁甲巨卫（承伤/护盾）、冰棘女巫（控制/冻结）、血旗督军（团队光环）、反射甲虫（反制/反射）。详细机制见 `docs/content/enemy_design.md`。
- **召唤物补充**：新增骷髅弓箭手、骷髅法师、骷髅战士，供天灾领主和后续亡灵召唤逻辑使用。
- **系统接入**：`EnemyCatalog`、`BattleBoard`、`ActiveSkillCaster`、`PassiveResolver`、`CombatResolver`、`FieldEffectManager`、`SummonManager`、`UnitCombat` 等接入 BOSS/精英技能、反射、状态场地、吞噬、亡灵召唤和护盾判定。
- **文档与测试**：`docs/content_reference.md` 已重新生成。新增 `scripts/tests/test_boss_units.gd`、`scripts/tests/test_elite_enemies.gd`。

## 2026-06-01 史莱姆系列敌人

本轮新增 5 个史莱姆系列敌人，并接入敌人池、技能系统、状态场地、分裂召唤和内容总览：

- **普通史莱姆 / Common Slime**（NORMAL, tank）：`slime_body` 只降低普通攻击伤害；主动 `slime_bounce` 对当前目标造成技能伤害。
- **冰霜史莱姆 / Frost Slime**（NORMAL, support）：死亡冻结周围目标并生成寒霜区域；主动 `frost_explosion` 范围伤害+迟缓。
- **火焰史莱姆 / Flame Slime**（NORMAL, damage）：普攻、主动和死亡熔岩区域均接入 `burning`。
- **毒液史莱姆 / Venom Slime**（NORMAL, damage）：普攻、主动、死亡爆发和毒液区域均接入 `venom_stack`。
- **巨型史莱姆 / Giant Slime**（ELITE, tank）：死亡分裂为 2 个巨型史莱姆，`slime_split_count` 限制分裂链深度。
- **状态场地扩展**：`FieldEffectManager` 新增 `FIELD_TYPE_STATUS` 与 `create_status_field()`。
- **AoE 范围反馈补齐**：龙息溅射、蛆虫死亡爆发和史莱姆死亡爆发显示瞬时/持续范围提示。
- **敌人池接入**：`EnemyCatalog` 新增 5 个敌人，遭遇生成模板补充史莱姆权重。

## 2026-06-01 导出资源与美术接入修复

- **导出资源扫描兼容**：`UnitCatalog` 和 `EncyclopediaCatalog` 兼容 `.tres.remap` 文件名。
- **玩家单位/遗物素材接入**：30 个单位的 `data/units/*.tres` 和 43 个遗物的 `data/relics/*.tres` 显式引用贴图。
- **导出包图标修复**：删除 `assets/processed/.gdignore`，仅保留 `assets/processed/ui/.gdignore`。
- **分类内稳定排序 ID**：新增 `catalog_id`，用于图鉴、内容总览和素材切图的稳定排序。
- **图标加载兜底**：`UnitArtHelper` 与 `RelicIconHelper` 保留动态路径加载兜底。

## 2026-05-31 美术资源、背景图库与棋盘显示

- **背景图库统一接入**：新增 `scripts/ui/background_catalog.gd`，17 张背景共用同一份列表。
- **主菜单/战斗背景切换**：两处 `OptionButton` 共用同一套中文名列表。
- **棋盘显示调整**：战斗场景不再依赖旧棋盘贴图，棋盘和备战席由 `BattleBoard` 直接渲染网格边框。
- **遗物图标 UI**：遗物栏和展开面板改为显示 64×64 图标按钮，边框按稀有度着色。
- **血条颜色区分**：己方单位绿色，敌方单位红色。

## 2026-05-29 控制效果系统

- **控制效果系统**：减速/禁锢/眩晕/冻结/嘲讽五类控制，通过 `StatusEffectFactory.apply_control_effect()` 统一施加，`UnitControlState` 聚合最终行动能力。
- **StatusEffect 扩展**：新增 `EFFECT_CONTROL`、`CATEGORY_CONTROL`、控制字段和新叠层策略。
- **UnitControlState**（`scripts/combat/unit_control_state.gd`）：布尔聚合 can_move/attack/cast/retarget。
- **UnitData / Unit 扩展**：新增 `control_duration_multiplier`、`hard_control_duration_multiplier`、`control_immunity_tags`。
- **行动系统接入**：`UnitTargeting`、`Unit`、`UnitSkill`、`ActiveSkillCaster`、`CombatResolver` 均已接入控制状态读取。
- **5 个控制测试单位**：霜箭哨手、藤缚卫士、震锤先锋、冰棱术士、挑衅旗手。
- 后续已在这套控制系统基础上实现冰棘女巫（ELITE）和树妖领主（BOSS）的冻结/眩晕。

---

> 更早的更新记录已移至 `docs/archive/changelog.md`。

## 当前目录结构

```text
res://
├── data/
│   ├── units/*.tres                # 玩家普通单位资源
│   ├── heroes/*.tres               # 英雄对应 UnitData 资源
│   ├── enemies/*.tres              # 敌人单位资源
│   ├── summons/*.tres              # 召唤物资源
│   └── relics/*.tres               # 遗物资源
├── assets/
│   ├── game/ui/backgrounds/*.png    # 背景图库
│   ├── game/units/heroes/*.png      # 英雄美术资源
│   ├── processed/player_units/*.png # 玩家单位透明图标
│   └── processed/relics/*.png       # 遗物透明图标
├── docs/
│   ├── README.md                   # 文档目录与权威层级
│   ├── content_reference.md        # 自动生成：数值/技能/遗物唯一权威来源
│   ├── project_status.md           # 当前文档
│   ├── systems/
│   │   ├── bond_system.md
│   │   ├── combat_system.md        # 索敌与目标控制
│   │   ├── hero_system.md
│   │   ├── progression_system.md   # 路径选择系统
│   │   ├── relic_system.md
│   │   ├── snapshot_and_mirror.md  # 阵容快照 + 镜像挑战
│   │   ├── stat_modifier_system.md
│   │   ├── status_effect_system.md # Buff/Debuff + 控制效果
│   │   ├── summon_system.md
│   │   └── ui_system.md            # UI 分层、主界面、商店、奖励
│   ├── content/
│   │   ├── enemy_design.md         # 普通/精英/BOSS 统一敌人设计
│   │   ├── hero_design.md
│   │   ├── relic_design.md
│   │   ├── summon_design.md
│   │   └── unit_design.md
│   ├── pipeline/
│   │   ├── asset_pipeline.md
│   │   └── testing.md
│   └── archive/
│       ├── changelog.md            # 历史更新日志
│       └── feature_design_log.md   # 历史设计记录
├── scenes/
│   ├── main.tscn
│   ├── unit.tscn
│   ├── combat/projectile.tscn
│   └── ui/*.tscn
└── scripts/
    ├── catalog/
    ├── combat/
    │   ├── active_skill_caster.gd
    │   ├── aoe_resolver.gd / aoe_shape_visual.gd / shape_geometry.gd
    │   ├── attack_payload.gd / combat_resolver.gd
    │   ├── field_effect_manager.gd / field_effect_visual.gd
    │   ├── passive_resolver.gd
    │   ├── projectile.gd / projectile_manager.gd
    │   ├── stat_modifier.gd / unit_stat_controller.gd
    │   ├── status_effect_factory.gd
    │   └── unit_control_state.gd
    ├── encounter/
    ├── formatters/
    ├── game/
    ├── relic/
    ├── roster/
    ├── ui/
    ├── main.gd / battle_manager.gd / battle_time_manager.gd
    ├── bond_manager.gd / encounter_manager.gd
    ├── hero_data.gd / hero_manager.gd / hero_upgrade_data.gd
    ├── lineup_snapshot_manager.gd
    ├── reward_manager.gd / roster_manager.gd / shop_manager.gd
    ├── summon_manager.gd / relic_manager.gd / stats_manager.gd
    ├── status_effect.gd / summon_data.gd
    ├── unit_text_formatter.gd
    ├── unit.gd / unit_combat.gd / unit_targeting.gd
    ├── unit_feedback.gd / unit_drag_controller.gd
    ├── unit_data_applier.gd / unit_data.gd / relic_data.gd
    └── tests/
        ├── test_bond_manager.gd
        ├── test_boss_units.gd
        ├── test_elite_enemies.gd
        ├── test_slime_enemies.gd
        ├── test_summon_system.gd
        ├── test_stat_modifier_system.gd
        └── ...（共 22 个，完整清单见 `docs/pipeline/testing.md`）
```

## 场景职责

### `scenes/main.tscn`

主场景。负责承载：主控制脚本 `main.gd`、`BoardBackground`、`UI CanvasLayer`、HUD 基础标签、基础按钮，以及 `scenes/ui/` 下各 UI 子场景实例。

当前不再直接承载完整商店、奖励、遗物、单位详情、统计等面板的静态节点树，这些面板已拆为独立 `.tscn`。

### `scenes/unit.tscn`

单位场景。包含 `Unit Node2D`、`Body ColorRect`、`HPBar ProgressBar`。行为由 `unit.gd` 和拆分后的辅助脚本实现。

## 脚本职责划分

### `main.gd`
整体流程协调器。负责：初始化各 Manager 与 UI Controller、连接主流程 signal、协调 `RunController` 状态、拖拽部署/备战席调度/出售入口、HUD/商店/奖励/遗物/详情 UI 刷新、接收战斗结束信号、调用各 Manager 完成局内流程串联。不再直接负责单位生成、胜负判断、死亡处理、奖励应用、遗物触发、战斗细节、经济公式、技能效果。

### `battle_manager.gd`
单场战斗管理器。负责：清理战场、生成双方单位、分配队伍/位置/数据、连接单位信号、托管 `SummonManager`、启动/停止战斗、分配敌方列表、监听单位死亡、判断胜负、保存统计、转发事件给遗物系统。

### `reward_manager.gd`
奖励生成与选择应用入口。区分 STAT/UNIT/RELIC 类型；按波次、遭遇类型和幸运值抽取稀有度；属性奖励覆盖 5 个稀有度；单位奖励从当前本局可获取单位池动态生成，并兼容英雄专属单位过滤。

### `run_modifier_manager.gd`
本局运行修正管理器。当前保存 `luck` 幸运值，供奖励稀有度概率计算使用；Restart 时清空，可通过快照接口保存/还原。

### `roster_manager.gd`
玩家阵容与成长管理器。管理全队生命/攻击倍率、本局永久属性 `permanent_stat_bonuses`、攻速属性奖励、英雄专属单位池过滤、新增单位、升星、Restart 恢复。

### `relic_manager.gd`
遗物持有与效果触发管理器。触发类型：`AURA`（常驻光环）、`BATTLE_START`（一次性增益）、`ON_ATTACK`、`ON_KILL`、`ON_DEATH`、`ON_ROUND_REWARD`。当前 43 件遗物。

### `stats_manager.gd`
战斗统计管理器。记录伤害/承伤/攻击次数/击杀/存活状态，保存死亡单位快照。

### `unit.gd`
单位对外接口与生命周期协调器。在 `_process` 中协调冷却、索敌、移动、攻击、卡住检查。

### `unit_combat.gd`
单位战斗数值结算。受伤（护盾先扣）、死亡处理、击杀归属、治疗、护盾。

### `unit_targeting.gd`
单位索敌和追击。支持 `NEAREST` / `LOWEST_HP`，目标合法性检查、卡住检测、被控状态读取。

### `unit_feedback.gd` / `unit_drag_controller.gd` / `unit_data_applier.gd`
战斗反馈（攻击缩放/受伤闪烁/伤害数字/死亡淡出）、准备阶段拖拽控制、UnitData 应用到单位实例。

## 当前主流程

```text
MAIN_MENU → HERO_SELECTION → PREPARE → BATTLE → RESULT → REWARD → NEXT_PREPARE
                                                                      ↓
MIRROR_CHALLENGE (总波次相同，Boss 波用历史镜像替换)               GAME_OVER
```

英雄选择完成后进入准备阶段；玩家可拖动普通单位和英雄调整站位；英雄只能放在玩家棋盘内，不可下阵或出售。

## 已完成功能

### 战斗基础
- 双方单位生成、自动索敌、直线移动、自动攻击
- 远程真实弹道：发射飞行物→追踪目标→命中结算（快照机制）
- 近战即时命中
- 圆形/矩形/扇形瞬时 AoE 命中与范围视觉
- 攻击冷却、死亡淡出、伤害数字、受伤闪烁、攻击反馈

### 索敌
- `NEAREST` / `LOWEST_HP` 策略
- 嘲讽强制目标通过 `UnitControlState.forced_target` 接入索敌
- 目标死亡/无效/不可选中/超出搜索范围后的重新索敌
- 卡住检测

### 多阶段/多轮战斗
- 准备→战斗→结果→奖励→下一轮→结束
- 30 个节点推进：Boss 固定 10/20/30；精英战由路径选择节点或强制精英节点触发
- 敌方强度随波次/遭遇类型/星级递增
- 路径选择系统（6 种节点类型：普通/精英/商人/训练/事件/宝箱）
- 商人全局强化中的 `death_prevention` 当前保存为全局标记，致死拦截逻辑尚未接入战斗结算
- Restart 重置整局

### 英雄系统
- 4 名英雄：铁誓统帅、奥术导师、血影猎手、织骨者
- 英雄作为特殊单位上场，不占用普通单位上场数，不可购买/出售/升星/下阵
- 50 经验升级（普通+10/精英+20/Boss+30），升级时强化三选一

### 阵容快照与镜像挑战
- Boss 胜利后保存阵容快照（单位/遗物/全局效果/永久属性）
- 镜像挑战开局锁定历史 Boss 通关阵容替换 Boss 波
- 镜像挑战入口与基础替换流程已存在，但快照还原细节（永久属性还原、随机选择规则等）仍暂缓校准，剩余问题见 `docs/audit_issues_draft.md`

### 奖励/遗物/召唤/统计系统
- 三选一奖励（属性/单位/遗物），悬停详情；稀有度受波次、遭遇类型和幸运值影响
- 属性奖励覆盖生命百分比、攻击百分比、攻速百分比、防御、幸运，COMMON/FINE/RARE/EPIC/LEGENDARY 数值为 5/10/15/20/25
- 单位奖励从当前可获取玩家单位池动态生成，英雄专属单位只在选择对应英雄后出现
- 43 件遗物，6 种触发类型
- 召唤系统：召唤物参与胜负，独立/共享上限，限时/永续
- 战斗统计：伤害/承伤/击杀/治疗/护盾/回蓝，死亡单位快照

### UI 与交互
- 像素风统一 UI、背景图库切换、代码渲染棋盤网格
- 拖拽出售、单位详情、英雄选择预览确认、悬停缩放动画
- 完整 UI 分层系统（`scripts/ui/ui_layer.gd`）

## 当前结构评价

当前结构已经完成重构，具备继续扩展内容和调数的基础。

优点：
- `main.gd` 已从战斗细节、经济公式、遭遇生成、技能效果和遗物效果中解耦
- `battle_manager.gd`、`reward_manager.gd`、`roster_manager.gd`、`relic_manager.gd`、`encounter_manager.gd`、`stats_manager.gd` 均已拆为独立领域服务
- `unit.gd` 已瘦身，细节拆到辅助类
- 数据资源、脚本服务和 UI 场景资源分离

需要注意：
- `scripts/` 下文件数量已多，但目录边界清晰
- 不建议继续做大范围搬迁，后续应按实际新增功能小步调整

## 后续建议

### 短期
1. 优先可玩性验证、数值曲线和 UI 可读性，而非继续大拆结构。
2. 新增系统放入现有目录边界，避免逻辑塞回 `main.gd`。
3. 新增单位技能放入 `active_skill_caster.gd` 或 `passive_resolver.gd`。
4. 新增遗物效果放入 `relic_effect_resolver.gd`。
5. 新增 UI 面板时新增 `scenes/ui/*.tscn` 和 `scripts/ui/*_controller.gd`。
6. 控制效果系统已实现；后续扩展沉默/缴械/恐惧等控制类型时，继续使用 `StatusEffectFactory.apply_control_effect()` 和 `UnitControlState`。

### 中期可考虑
- `scripts/game/prepare_phase_controller.gd`：统一准备阶段按钮显隐、拖拽调度、出售入口
- Godot headless 流程测试脚本，覆盖主菜单→商店→部署→战斗→奖励→结束完整流程

### 暂缓
- 路线地图、装备背包、战斗回放、存档系统

### 验证命令

```text
# 编译检查
Godot_v4.6.2-stable_win64_console.exe --headless --path . --check-only --script res://scripts/main.gd

# 测试套件
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_slime_enemies.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_boss_units.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_elite_enemies.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_summon_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_stat_modifier_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_bond_manager.gd

# 刷新内容参考文档
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_content_reference.gd
```
