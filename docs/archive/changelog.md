# 历史更新日志

> 本文档记录 2026-05-28 及更早的更新。最新更新见 `docs/project_status.md`。

---

## 2026-05-28 文档整理

- 新增根目录 `README.md`，用于 GitHub 首页展示。
- `docs/README.md` 重写为维护索引，明确"代码 > content_reference.md > project_status.md > 专题文档 > 历史记录"的优先级。
- `docs/future_features.md` 改名为 `docs/archive/feature_design_log.md`。
- 移除过期文档：`phase_summary_2026-05-04.md`、`refactor_plan_2026-05-06.md`、`unit_skill_design.md`、`unit_design_with_new_units.md`；旧版 `enemy_design.md` 合并重写为 `docs/content/enemy_design.md`。

## 2026-05-28 性能与稳定性修复

- 战斗死亡链路优化：状态效果静默批量清理，死亡/召唤/列表更新改为批量请求。
- 动态金币光环刷新优化：无动态金币光环时不触发全队属性刷新，同帧内多次变化 deferred 合并。
- 动态 modifier 批量重算：`RelicEffectResolver.refresh_dynamic_gold_relics_to_unit()` 先筛选→批量移除/添加→一次 recalculate。
- 日志开关：`debug_log.gd`，通过 ProjectSettings 控制，默认关闭。
- 商店单位购买卡顿修复：`BattleManager.refresh_player_and_bench_units()` 按 roster_id 复用预览节点。
- 复用节点安全重置：`Unit.reset_prepare_preview()`、`UnitStatController.clear_runtime_state()`。

## 2026-05-28 羁绊UI、波次过渡、战斗统计与细节修复

- 波次过渡动画：新建 `transition_panel.tscn` + `transition_panel_controller.gd`。
- 羁绊面板修复：子节点 remove_child+queue_free，布局 call_deferred 延迟，动态高度。
- 羁绊详情成员展示：`BondManager.get_bond_member_info()` 遍历全单位/英雄。
- 单位详情面板羁绊标签：彩色按钮，点击弹出详情。
- 图鉴新增羁绊分类：`CATEGORY_BONDS`，展示全部 6 个羁绊。
- 战斗统计弹窗：按 team_id 分离，固定列宽，居中弹窗。
- 商人悬浮提示、弹窗 z_index 与背景修复、开场秘典修正（仅 restore_mana(20)）。

## 2026-05-27 路径选择系统

战斗胜利后新增路径选择面板：从 3 个候选节点中选择下一回合内容，替代线性推进。

6 种节点类型全部实现：
- **NORMAL**：普通战斗，权重 5
- **ELITE**：精英战斗，权重 2，round>=5
- **MERCHANT**：双栏货架（遗物+奇货），人口可重复购买（价格翻倍），8 个全局强化，权重 2，冷却 2
- **TRAINING**：限时击杀木桩，掉落金币/遗物/升星券/永久属性，权重 1，冷却 2
- **EVENT**：6 个硬编码事件（迷途旅人/神秘祭坛/流浪商人/诅咒箱/受伤的战士/奥术异象），权重 2，冷却 1
- **TREASURE**：宝箱遗物（RARE 50%/EPIC 35%/LEGENDARY 15%），权重 1，冷却 2

Boss 锁定 round 10/20/30，保护期 round 1-2 固定 NORMAL。

新增文件：`path_selection_manager.gd`、`merchant_manager.gd`、`training_manager.gd`、`event_manager.gd` 及对应 UI 控制器/场景。修改 `game_state.gd`（5 个新状态）、`run_controller.gd`、`encounter_generator.gd`、`encounter_manager.gd`、`roster_manager.gd`、`battle_manager.gd` 等。

后续 bug 修复：人口可重复购买/价格翻倍/上限20、商人遗物去重、高稀有度单位池改为稀有度筛选、弹窗系统复用事件面板、弹道修复/AoE 技能修复。

## 2026-05-25 难度曲线、敌方阶等与蛆虫族敌人

- `UnitData` 新增 `enemy_tier` 字段（NORMAL/ELITE/BOSS）。
- 图鉴新增稀有度/类型筛选。
- 新增巨型蛆虫（NORMAL）和蛆虫聚合体（ELITE）。
- 新增 putrid_mark（腐痕）debuff：damage_taken_multiplier=1.25。
- 蛆虫族持续伤害统一使用 venom_stack。
- 新增 burning（燃烧）：同目标只保留一个，新燃烧伤害相加、时间取较长。
- 难度曲线全面调整：普通 HP×0.06/数量上限12，精英 HP 基础 1.40/数量上限9，Boss HP 分段大幅提高。

## 2026-05-25 属性修饰器与动态金币光环

- 新增 `stat_modifier.gd` 与 `unit_stat_controller.gd`，8 层结算管道。
- `Unit` 新增 add/remove/recalculate 统一入口。
- 静态 AURA 遗物、金币动态光环、Buff/Debuff、羁绊战斗属性、英雄被动、加时赛加成全部接入 modifier。
- 金币转化遗物改为动态 modifier 读取实时金币。
- `EconomyManager.gold_changed` 信号 + deferred 合并刷新。

## 2026-05-25 稳定性修复

- 修复骨龙 AoE 和织骨者召唤参数顺序问题。
- 修复召唤羁绊导致生命值超过最大生命的问题。
- 补充 test_bond_manager 断言。

## 2026-05-25 金币经济遗物

新增 9 件金币经济遗物：旧钱袋、战利品账本、赏金匕首、投资账本、金甲契约、黄金护符、猎金契约、复利核心、贪婪王冠。

新增触发类型 `ON_ROUND_REWARD`。`RelicManager` 新增 `set_battle_gold_context()`、`trigger_round_reward_relics()` 等。

## 2026-05-25 永久成长、光环遗物、英雄素材与 UI 分层

- 新增遗物血誓杯（Blood Oath Chalice）：击杀后本局永久+5最大生命。
- `RosterManager`/`HeroManager` 新增 `permanent_stat_bonuses`。
- `UnitScalingService`/`MergeService` 接入永久属性成长。
- `LineupSnapshotManager` 保存并还原 permanent_stat_bonuses。
- 遗物系统新增 `AURA` 触发类型：常驻光环，单位/英雄/召唤物生成后立即应用。
- 4 名英雄接入美术资源，棋盘英雄图标改为 96×96。
- UI 分层系统：`scripts/ui/ui_layer.gd`。

## 2026-05-23 非圆形瞬时 AoE

- 新增 `shape_geometry.gd`：纯工具类，生成圆形/矩形/扇形顶点。
- 改造 `aoe_resolver.gd`：新增 `get_units_in_shape()`，旧 `get_units_in_radius()` 兼容包装。
- 新增 `aoe_shape_visual.gd`：瞬时 AoE 视觉节点。
- 巨剑骑士 cleaving_edge（裂刃）改为前方扇形，sweeping_slash（横扫斩）改为前方矩形。

## 2026-05-23 弹道系统

远程普攻真实弹道完整实现：
- 新增 `combat_resolver.gd`：统一普攻命中结算入口。
- 新增 `attack_payload.gd`：发射时快照战斗属性。
- 新增 `projectile_manager.gd` + `projectile.gd` + `projectile.tscn`。
- `UnitData`/`Unit` 新增 `basic_attack_type`、`projectile_speed`、`projectile_visual_type`。
- 18 个玩家远程单位和 8 个敌方远程单位已配置 projectile 参数。
- 新增 `launch_count` 字段，与 `attack_count` 分离。
- 边界情况：目标死亡/攻击者死亡/战斗结束/超时均已处理。

## 2026-05-23 织骨者英雄与新召唤物

- 新增第四名英雄织骨者（Boneweaver）：召唤/亡灵主题，远程弹道。
- 新增召唤物骨巨人（Bone Golem）和骨龙（Bone Dragon）。
- 英雄选择界面重构为战斗单位详情样式。
- 羁绊面板动态高度，按钮 hover/press 缩放动画。

## 2026-05-20 增量进度

- 羁绊 UI 优化为可交互面板。
- `BondManager` 新增按单个羁绊生成详情文本接口。
- `docs/content_reference.md` 重新生成，新增羁绊标签列。

## 2026-05-17 增量进度

- 新增第一版羁绊系统：铁壁、猎手、奥术、圣疗、召唤、剧毒 6 类。
- `UnitData`/`Unit` 新增 `bond_tags`，同一 unit_type 只计 1 次。
- 战斗开始时应用羁绊效果，召唤物生成/死亡和剧毒施加入口接入羁绊事件。

## 2026-05-16 增量进度

- 新增 8 件扩展战斗属性遗物：奥术棱镜、慈悲香炉、破甲砺石、血玻璃护符、壁垒符文、开场秘典、充能针、幻影披风。
- 覆盖技能强度、治疗强度、护盾强度、防御穿透、吸血、伤害减免、初始魔力、普攻回魔、受击回魔、状态抗性和闪避。

## 2026-05-15 增量进度

- 新增第一版英雄系统：4 名英雄，开局选择 1 名，作为特殊单位上场。
- 英雄使用经验升级（50 经验），升级时强化三选一。
- 英雄可在准备阶段拖动调整站位。
- 新增 Boss 胜利阵容快照。
- 新增镜像挑战模式。
- 新增击杀遗物、AOE 单位和范围显示。
- 神官技能改为 3 秒持续治疗。
