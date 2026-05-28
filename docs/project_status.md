# 自动对战 Demo 项目状态总览

更新时间：2026-05-28（含路径选择系统、蛆虫族敌人、属性修饰器动态光环性能优化、死亡链路优化、商店单位购买预览复用）

> 文档导航与新旧关系见 `docs/README.md`。本文档作为当前项目进度入口；单位、英雄、敌人、召唤物和遗物的数值核对以 `docs/content_reference.md` 为准；羁绊、英雄、镜像挑战、阵容快照等系统分别参考对应专题文档；已完成或待规划的功能设计与实现入口见 `docs/future_features.md`。路径选择系统的完整设计和数值表见 `docs/path_selection_design.md`。

## 项目概览

本项目是一个 Godot 4 + GDScript 制作的 2D 肉鸽自走棋 Demo。

当前 Demo 已经从最初的单场自动战斗，扩展为包含主菜单、英雄选择、准备阶段、自动战斗、战斗加速、加时赛提示、30 波推进、奖励三选一、10 格分类商店、单位解锁与升星提醒、遗物系统、英雄系统、羁绊系统、召唤系统、Buff/Debuff 堆叠体系、运行时属性修饰器、图鉴、Boss 阵容快照、镜像挑战、远程普攻真实弹道、非圆形瞬时 AoE、常驻光环遗物、本局永久属性成长、英雄美术资源、中文文本、战斗统计、路径选择系统（6 种节点类型）和结束回主菜单流程的可玩原型。

当前项目仍然聚焦在自动战斗与局内成长循环验证，路线地图、装备背包、战斗回放和存档系统仍未纳入当前 Demo 范围。

截至 2026-05-06，`docs/refactor_plan_2026-05-06.md` 中的 6 阶段结构重构已经完成：UI 控制器、流程/经济、阵容服务、遭遇生成、技能/遗物效果和 UI 子场景均已完成拆分。本文档仍保留早期说明口径，但以下目录和职责已同步到当前结构。

## 2026-05-28 性能与稳定性修复

近期完成并通过 headless 检查的内容：

- **战斗死亡链路优化**：死亡时状态效果改为静默批量清理，避免每层 Buff/Debuff 过期都刷新单位详情或触发中间属性重算；死亡、召唤和敌我列表更新改为批量请求，在批次末尾统一刷新。
- **动态金币光环刷新优化**：`EconomyManager.gold_changed` 现在先检查是否拥有动态金币光环遗物；没有 `golden_armor_contract`、`golden_charm` 或 `crown_of_greed` 时不触发全队属性刷新。存在动态金币光环时，`main.gd` 使用 deferred 刷新合并同一帧内多次金币变化。
- **动态 modifier 批量重算**：`RelicEffectResolver.refresh_dynamic_gold_relics_to_unit()` 会先筛选实际拥有的动态金币遗物，再批量移除/添加同来源 modifier，最后只执行一次 `recalculate_stats()`，并通过 `preserve_base_stats` 避免把旧动态加成写成新的基础属性。
- **日志开关**：新增 `scripts/debug_log.gd`，通过 `ProjectSettings` 中的 `auto_battler/debug/combat_log_enabled` 和 `auto_battler/debug/info_log_enabled` 控制战斗日志与普通信息日志，默认关闭，避免后期大量输出造成卡顿。
- **商店单位购买卡顿修复**：购买单位后刷新备战预览时，不再销毁并重建所有上场、英雄和备战单位节点。`BattleManager.refresh_player_and_bench_units()` 现在按 `roster_id` 复用预览单位，并通过 `prepare_unit_signature` 跳过未变化单位的完整重配置。
- **复用节点安全重置**：`Unit.reset_prepare_preview()` 清理运行时战斗状态、目标、状态效果和常驻遗物 meta；`UnitStatController.clear_runtime_state()` 为复用预览节点提供统一状态清理；`UnitDataApplier` 在应用资源前重置可选美术和弹道字段，避免复用节点残留旧图标或旧 projectile 配置。
- **性能排查结论**：战斗后期卡顿主要来自死亡链路的状态清理、召唤刷新和单位列表重建；商店购买单位卡顿主要来自购买后整队预览节点销毁重建。当前分别改为静默清理、批量刷新和节点复用。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/battle_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/unit.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/unit_data_applier.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/combat/unit_stat_controller.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_stat_modifier_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_summon_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_hero_battle_spawn.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_hero_position_reservation.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 2026-05-27 路径选择系统

近期完成并通过 headless 检查的内容：

- 战斗胜利后新增路径选择面板：从 3 个候选节点中选择下一回合内容，替代线性推进。
- **6 种节点类型全部实现**：
  - **普通战斗（NORMAL）**：与原有遭遇生成一致，权重 5。
  - **精英战斗（ELITE）**：通过 `forced_encounter_type` 机制强制生成精英遭遇，不再依赖回合 % 5 判定；权重 2，round >= 5 出现。
  - **商人（MERCHANT）**：两栏 4+4 货架。上栏遗物（RARE+ 池，可指数增长刷新），下栏奇货货架（高费单位/全局强化/人口提升）。人口始终出现在 slot 1，可重复购买，价格 3→6→12→24→48...，上限 20。8 个全局强化通过 `global_stat_bonuses` → `unit_scaling_service` 应用到所有战斗单位。权重 2，冷却 2 回合。
  - **训练场（TRAINING）**：注入训练遭遇到 encounter_manager → 正常准备阶段（可购物）→ 手动开始战斗 → 限时击杀木桩 → 木桩死亡掉落金币/遗物/升星券/永久属性 → 训练结束展示奖励总结。权重 1，冷却 2 回合。
  - **随机事件（EVENT）**：6 个硬编码事件（迷途旅人/神秘祭坛/流浪商人/诅咒箱/受伤的战士/奥术异象），含效果解析器（金币增减/遗物获取/三选一/随机单位/永久属性/随机结果）。流浪商人的遗物三选一通过 `reward_panel_controller.show_custom_options()` 复用奖励面板。权重 2，冷却 1 回合。
  - **宝箱（TREASURE）**：展示遗物名称/稀有度/描述，确认后领取。权重 RARE 50%/EPIC 35%/LEGENDARY 15%。权重 1，冷却 2 回合。
- **Boss 锁定**：round 10/20/30 不出现选择面板，直接进入 Boss 准备。
- **保护期**：round 1-2 固定 3 个 NORMAL。
- **非战斗节点 UI 清理**：进入路径选择/商人/事件/宝箱时隐藏战斗棋盘、清除战场单位、清空统计文本、隐藏无关面板。进入准备时恢复显示。
- **新增文件**：
  - `scripts/path_selection_manager.gd` — 候选生成、冷却、权重、约束
  - `scripts/merchant_manager.gd` — 货架生成、刷洗、购买、人口提升、全局强化
  - `scripts/training_manager.gd` — 木桩遭遇生成、计时、掉落池、升星券
  - `scripts/event_manager.gd` — 事件加载、抽取、效果解析（6 个事件硬编码）
  - `scripts/ui/path_selection_panel_controller.gd` + `scenes/ui/path_selection_panel.tscn`
  - `scripts/ui/merchant_panel_controller.gd` + `scenes/ui/merchant_panel.tscn`
  - `scripts/ui/event_panel_controller.gd` + `scenes/ui/event_panel.tscn`
  - `data/enemies/training_dummy.tres` — 木桩单位数据
- **修改文件**：
  - `scripts/game/game_state.gd` — 新增 5 个状态常量
  - `scripts/game/run_controller.gd` — 新增 enter_* 方法、path_history、is_next_round_boss()
  - `scripts/encounter/encounter_generator.gd` — `create_random_encounter()` 新增 `forced_type` 参数
  - `scripts/encounter_manager.gd` — 新增 `forced_encounter_type`、`set_override_encounter()`
  - `scripts/roster_manager.gd` — `max_active_units` 改为实例变量；新增 `apply_permanent_percent_bonus()`/`apply_permanent_flat_bonus()`、`global_stat_bonuses`、`set_unit_star_by_roster_id()`、`has_death_prevention`
  - `scripts/roster/unit_scaling_service.gd` — 新增 `_apply_global_stat_bonuses()`
  - `scripts/battle_manager.gd` — 新增 `enemy_unit_died` 信号、`force_end_battle()`
  - `scripts/lineup_snapshot_manager.gd` — 快照持久化全局 buff 和 death_prevention
  - `scripts/ui/reward_panel_controller.gd` — 新增 `show_custom_options()`
  - `scripts/main.gd` — 接入全部 6 种节点流程、UI 切换、全局强化和高费单位添加；弹窗系统（`_show_popup` 复用事件面板居中展示）
- **后续 bug 修复与迭代**：
  - 人口提升改为可重复购买，每次价格翻倍（3→6→12→24→48），上限 20 封顶，显示实时人口数。
  - 商人遗物货架新增去重逻辑，稀有度从遗物资源读取，剩余不足 4 个自然缩减不补重复。
  - 高稀有度单位池改为稀有度筛选（rarity ≥ RARE），涵盖 14 个高稀有度单位含未解锁，选中后自动解锁。事件「受伤的战士」同步更新。
  - 弹窗系统复用事件面板（居中面板 + 结果文本 + 继续按钮），训练场/商人/事件/宝箱统一使用。
  - 事件面板按钮添加 PixelUI 样式，遗物选择时隐藏下层事件面板避免重叠。
  - 训练场掉落记录改为具体内容（遗物名、升星单位名）。
  - **弹道修复**：`spawn_basic_attack_projectile` 路由到 `battle_manager.projectile_manager`，补齐缺失的 `projectile_speed` 参数。
  - **AoE 技能修复**：`unit_skill.update()` 中技能未命中时仍消耗魔力，防止每帧重复释放。
  - `scenes/main.tscn` — 新增 3 个面板实例

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
```

## 2026-05-25 难度曲线、敌方阶等与蛆虫族敌人

近期完成并通过 headless 检查的内容：

- 为 `UnitData` 新增 `enemy_tier` 字段（NORMAL / ELITE / BOSS），替代仅靠 `unit_type` 前缀判定敌方单位阶等的旧方式。
- 17 个敌方 `.tres` 文件已配置 `enemy_tier`；`EnemyCatalog.is_elite_enemy_id()` 和 `EncyclopediaCatalog._get_enemy_type_key()` 优先读取该字段，旧前缀逻辑保留为兜底。
- 图鉴新增稀有度/类型筛选功能：友方单位与遗物按 COMMON/FINE/RARE/EPIC/LEGENDARY/MYTHIC 过滤，敌方单位按普通敌人/精英/BOSS 过滤，默认显示"全部"。
- 新增两个敌方单位：
  - **巨型蛆虫 / Giant Maggot**（NORMAL, damage）：近战，死亡自爆 AoE + 施加剧毒与腐痕，主动技能喷吐毒液。
  - **蛆虫聚合体 / Maggot Amalgam**（ELITE, tank）：近战，死亡分裂召唤 4 只巨型蛆虫，主动技能扇形腐潮（若目标有腐痕则增伤）。
- 新增 Debuff **putrid_mark（腐痕）**：`STAT_MULTIPLY` 类型，`damage_taken_multiplier = 1.25`（承伤 +25%），由蛆虫族所有技能施加，腐潮检测后 ×1.25 增伤并刷新。
- 蛆虫族所有持续伤害统一使用已有 `venom_stack`（剧毒），通过层数区分强度：死亡自爆 1 层、喷吐 2 层、腐潮 2 层。
- 蛆虫族接入 `EnemyCatalog` 池（NORMAL_DAMAGE + ELITE_TANK），并在遭遇生成器模板权重中配置出现频率。
- **难度曲线全面调整**：
  - 普通 HP 每波 ×0.04 → ×0.06，数量上限 6 → 12。
  - 精英 HP 基础 1.25 → 1.40，每波 +0.05 → +0.08，数量上限 5 → 9。攻击乘数不变。
  - Boss HP 分段成长大幅提高：T0 ×1.30 / T1 ×2.65 / T2 ×4.00，护卫数按 Tier 递增（4/5/6）。攻击仅微调，防御从 +12→+15、+24→+30。
  - 精英遭遇拆分精英/普通单位：精英数量 = floor(波次/5)，其余为普通单位，各自使用对应星级概率表。
  - Boss 遭遇新增精英单位：数量 = floor(波次/5)，使用精英池和精英星级概率。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tools/generate_content_reference.gd
```

## 2026-05-25 属性修饰器与动态金币光环

近期完成并通过 headless 检查的内容：

- 新增 `scripts/combat/stat_modifier.gd` 与 `scripts/combat/unit_stat_controller.gd`，为运行时单位提供统一属性修饰器系统。
- 属性修饰器按 `BASE_OVERRIDE → PERMANENT_FLAT → PERMANENT_PERCENT → RUNTIME_FLAT → RUNTIME_PERCENT → FINAL_FLAT → FINAL_PERCENT → FINAL_MULTIPLY` 顺序结算，避免遗物、羁绊、Buff/Debuff、英雄被动和加时赛直接改写同一字段后互相覆盖。
- `Unit` 新增 `add_stat_modifier()`、`remove_stat_modifier()`、`remove_stat_modifiers_by_source()`、`recalculate_stats()`，作为其他系统接入属性加成的统一入口。
- 静态 `AURA` 遗物、金币动态光环、Buff/Debuff 属性效果、羁绊战斗开始属性、部分英雄/单位战斗开始被动和加时赛加成已接入 modifier 系统。
- 金币转化属性遗物（金甲契约、黄金护符、贪婪王冠）不再只按开战金币固定结算，而是通过动态 modifier 读取实时金币；拥有动态金币光环时，金币变化、购买遗物、调整站位和单位生成都会刷新当前加成。
- `EconomyManager` 新增 `gold_changed` 信号；`main.gd` 监听后会先通过 `RelicManager.has_dynamic_gold_relics()` 判断是否需要刷新，存在动态金币光环时再 deferred 合并调用 `BattleManager.refresh_dynamic_relic_auras()`，刷新当前玩家单位、备战单位和镜像敌方单位。
- 召唤物生成时会先标记 `is_summon` 再应用遗物光环，避免开战型旧光环误套到召唤物；动态金币光环仍可按当前规则刷新。
- 新增 `scripts/tests/test_stat_modifier_system.gd`，覆盖属性层级结算和金币动态光环在金币/站位变化后的重算。
- 详细设计见 `docs/stat_modifier_system_design.md`。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_stat_modifier_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_status_effect_stack_policy.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_kill_relics.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_summon_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_bond_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 2026-05-25 稳定性修复

近期修复并通过 headless 检查的内容：

- 修复骨龙普攻溅射、骨龙主动弹幕和织骨者召唤死亡回响仍按旧参数顺序调用 `AoeResolver.get_enemy_units_in_radius()` 的问题。当前统一使用 `source_unit, center_position, radius, excluded_units` 顺序，避免运行时报 `Cannot convert argument 2 from float to Vector2`。
- 修复召唤羁绊给召唤物增加最大生命后当前生命超过最大生命的问题。原因是 `apply_runtime_stat_bonus("max_hp", ..., true)` 已经补过一次 HP，后续又按新旧最大生命比例重复缩放；当前只保留一次补血并 clamp 到 `max_hp`。
- `scripts/tests/test_bond_manager.gd` 已补充断言，确认 2/3 召唤羁绊增强新召唤物后 `hp == max_hp`，防止生命溢出回归。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/combat/passive_resolver.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/combat/active_skill_caster.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_bond_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_summon_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_high_rarity_units.gd
```

## 2026-05-25 金币经济遗物

近期完成并通过 headless 检查的内容：

- 新增 9 件金币经济遗物：旧钱袋、战利品账本、赏金匕首、投资账本、金甲契约、黄金护符、猎金契约、复利核心、贪婪王冠。
- 新增触发类型 `ON_ROUND_REWARD`：在战斗胜利金币结算阶段触发，参考 `pre_reward_gold` 计算额外金币，第 30 波最终 Boss 跳过。
- `RelicManager` 新增 `set_battle_gold_context()`、`trigger_round_reward_relics()`、`reset_battle_relic_state()`、`_add_battle_gold()` 和 `gold_add_callback` 回调机制。
- 击杀金币遗物（赏金匕首、猎金契约）通过现有 `ON_KILL` 入口触发，通过 `RelicEffectResolver` 累积金币，回调 `main.gd` 即时写入 `EconomyManager`。
- 金币转化属性遗物（金甲契约、黄金护符、贪婪王冠）已改为 `AURA` 光环类型，并接入动态属性修饰器，通过 `RelicManager.get_live_gold()` → `EconomyManager.get_gold()` 读取实时金币；拥有动态金币光环时，金币变化会触发合并后的属性刷新。
- `BattleManager.start_battle()` 调用 `relic_manager.reset_battle_relic_state()` 清零每场战斗的击杀计数和金币累积。
- `main.gd` 的 `_on_battle_ended()` 已接入 `trigger_round_reward_relics()`，在基础胜利金币计算完成后合并额外金币并输出日志。
- 遗物奖励池扩展至 43 件。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --check-only --script res://scripts/relic/relic_effect_resolver.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_content_reference.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit
```

## 2026-05-25 永久成长、光环遗物、英雄素材与 UI 分层

近期完成并通过 headless 检查的内容：

- 新增遗物 **血誓杯 (Blood Oath Chalice)**：友方非召唤玩家单位击杀敌人后，该单位本局永久获得 +5 最大生命值；召唤物击杀不会触发。
- `RosterManager` 与 `HeroManager` 新增 `permanent_stat_bonuses` 状态，用于保存本局永久属性成长；普通单位按 `roster_id` 写回阵容项，英雄写回当前英雄状态。
- `UnitScalingService`、`MergeService` 与 `HeroManager` 已接入永久属性成长：后续战斗重新生成单位时会重新应用这些加成；同类型单位升星合成时会合并永久属性加成。
- `LineupSnapshotManager` 已保存并还原 `permanent_stat_bonuses`，后续镜像挑战或其他基于阵容快照的模式可以保留这类本局成长结果。
- 遗物系统新增常驻 `AURA` 触发类型：光环不再只在战斗开始时结算，而是在玩家运行时单位、英雄生成后立即应用；召唤物生成时会先标记身份，再按规则应用允许作用于召唤物的动态光环。
- 已接入 `AURA` 的遗物包括：战斗旌旗、钢铁阵列、锐刃、断牙、奥术核心、法师透镜、治愈铃、星冠、三星冠冕、奥术棱镜、慈悲香炉、破甲砺石、血玻璃护符、充能针。
- `BattleManager` 在普通单位、英雄和召唤物生成后调用 `RelicManager.apply_always_on_relics_to_runtime_unit()`；`BATTLE_START` 入口会跳过已标记为常驻光环的遗物，避免同一效果重复结算。
- 四名英雄已接入美术资源：`assets/game/units/heroes/` 下包含头像、棋盘图标、图标和立绘资源；`UnitData` 的 `board_sprite`、`portrait_texture`、`icon_texture`、`art_scale`、`art_offset` 用于区分棋盘显示与 UI 显示。
- 棋盘英雄图标已改为 96×96 显示，并使用裁切后的 `*_board_icon.png`，减少不同英雄在图标内部留白不同导致的体感尺寸不一致。
- 英雄选择界面继续优化：底部页码已移除，左右按钮位于头像选择框两侧，每次点击使头像窗口移动一格；点击头像只切换详情，确认按钮用于最终选择英雄。
- 遗物栏保持在英雄详情面板下层，不再遮挡英雄选择详情；局内菜单按钮和弹出的菜单面板提高 `z_index`，在英雄选择界面打开菜单时可以正常显示。
- 新增 UI 分层系统设计与实现入口：`scripts/ui/ui_layer.gd` 定义 HUD、功能面板、详情、流程遮罩、主菜单/图鉴、系统弹窗、浮动提示等大层级；`docs/ui_layering_design.md` 记录新增 UI 的分层规则。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/ui/menu_panel_controller.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_kill_relics.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_hero_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_lineup_snapshot_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 2026-05-23 非圆形瞬时 AoE

近期完成并通过 headless 检查的内容：

- 新增 `scripts/combat/shape_geometry.gd`：纯工具类，生成圆形/矩形/扇形的绘制顶点数组（`get_circle_points`、`get_rect_points`、`get_sector_points`），不涉及战斗逻辑。
- 改造 `scripts/combat/aoe_resolver.gd`：新增 `get_units_in_shape()`（统一形状查询）、`get_enemy_units_in_shape()`、`get_ally_units_in_shape()`；新增 `is_point_in_shape()` 分发器和 `is_point_in_circle/rect/sector()` 判定方法。旧 `get_units_in_radius()` 保留为兼容包装，内部委托到 `get_units_in_shape()`。
- 新增 `scripts/combat/aoe_shape_visual.gd`：瞬时 AoE 视觉节点，使用 `ShapeGeometry` 生成顶点并通过 `_draw()` 绘制；支持 alpha 淡出后自动 `queue_free`。通过 `BattleManager.create_aoe_shape_visual()` 创建。
- 巨剑骑士被动 `cleaving_edge`（裂刃）已改为前方扇形：半径=攻击范围，角度=120°，方向=指向目标。
- 巨剑骑士主动 `sweeping_slash`（横扫斩）已改为前方矩形：方向=指向目标，长度=2×攻击范围，宽度=攻击范围，anchor=forward。
- 旧技能（healing_aura、explosive_barrage、sanctuary 等）仍使用圆形，不受影响；`create_visual_field()` 保留不变。
- `docs/future_features.md` 中非圆形瞬时 AoE 已标记为已完成。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/tests/test_bond_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/tests/test_high_rarity_units.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 2026-05-23 弹道系统

近期完成并通过 headless 检查的内容：

- 远程普攻真实弹道已按 `docs/future_features.md` 设计完整实现：近战单位保持即时命中，远程单位发射飞行物并在命中后结算。
- 新增 `scripts/combat/combat_resolver.gd`：统一普攻命中结算入口，近战即时调用，远程由飞行物到达时调用；处理攻击计数、伤害、attack_landed 信号、被动、吸血、普攻回魔。
- 新增 `scripts/combat/attack_payload.gd`：发射时快照攻击者战斗属性（暴击率、暴伤、防御穿透、吸血、基础伤害等），飞行物命中时使用快照值结算，不受飞行期间属性变化影响。
- 新增 `scripts/combat/projectile_manager.gd` + `scripts/combat/projectile.gd` + `scenes/combat/projectile.tscn`：飞行物管理、追踪目标移动、命中判定、超时/战斗结束清理。
- `UnitData` 与运行时 `Unit` 新增 `basic_attack_type`（melee/projectile）、`projectile_speed`、`projectile_visual_type` 字段；`UnitDataApplier` 同步这些字段。
- 玩家远程单位（archer、mage、priest、bard、forest_druid、plague_caster、alchemist、bomb_thrower、cleric、necromancer、puppet_warlock、wind_chanter、arcane_artillerist、venom_matriarch、dawnbell_saint、soul_binder、prism_weaver、arcane_mentor）均已配置 projectile 类型和视觉参数。
- 敌方远程单位（boss_void_cannon、boss_abyss_hierophant、crossbow_raider、flame_imp、grave_caller、puppet_binder、dark_acolyte、war_drummer、elite_blood_oracle）同样配置 projectile 类型。
- 新增 `launch_count` 字段到 Unit：发射时递增，与 `attack_count`（命中时递增）分离，为后期多重射击、跳弹等发射触发机制预留扩展空间。
- 爆弹投手的"不稳定炸弹"已改为发射时检测（每 3 次发动触发），AoE 伤害使用发射时快照值；强化飞行物有视觉差异（尺寸 +50%、橙红色）。
- 近战单位的普攻命中被动（cleaving_edge、nature_touch 等）保持不变，仍通过 `apply_attack_landed_passives` 即时触发。
- 已处理的边界情况：目标飞行中死亡→飞行物销毁不造成伤害；攻击者飞行中死亡→飞行物继续飞行并造成伤害（归属正确），但跳过吸血/回魔；战斗结束→清理所有飞行物；飞行物超时→自动销毁。
- `docs/future_features.md` 中的远程普攻真实弹道与非圆形瞬时 AoE 均已标记为已完成。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/tests/test_bond_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/tests/test_extended_unit_attributes.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/tests/test_high_rarity_units.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/tests/test_kill_relics.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/tests/test_summon_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 2026-05-23 织骨者英雄与新召唤物

近期完成并通过 headless 检查的内容：

- 新增第四名英雄 **织骨者 (Boneweaver)**：召唤/亡灵主题，远程弹道（暗影系），羁绊标签 summon。
  - 被动 **骨潮**：战斗开始时所有召唤单位 +15%攻击/+15%生命；场上每个召唤单位使召唤伤害 +5%（上限25%）。
  - 被动 **不灭仆从**：召唤单位首次致死时保留1HP并获得无敌（默认2秒，升级后4秒），每单位每场限1次。
  - 主动 **骨巨人召唤**（120魔）：召唤骨巨人（近战肉盾），攻击=18+80%英雄攻击，生命=200+150%英雄攻击，防御20，持续15秒。Lv.4起额外召唤骨龙（远程AOE）。
  - 8个英雄强化（Lv.2×4/Lv.3×2/Lv.4×2）：骸骨活力、骨刺护甲、亡者回响、墓穴召唤、骨巨人狂怒、骸骨坚韧、骨龙降临、永恒仆从。
  - 英雄数据：`data/heroes/boneweaver_unit.tres`；定义：`scripts/hero_manager.gd`。
- 新增召唤物 **骨巨人 (Bone Golem)**：近战肉盾，HP200/ATK18/DEF20，攻速1.3s，被动巨人之躯（减伤15%），主动巨人重击（200%/260%伤害）。
- 新增召唤物 **骨龙 (Bone Dragon)**：远程AOE，HP100/ATK30/DEF5，攻速1.5s，射程140，被动龙息溅射（普攻30%溅射），主动龙息弹幕（150%/200%伤害，范围100/130）。
- 召唤物数据：`data/summons/bone_golem.tres`、`data/summons/bone_dragon.tres`。
- 骨巨人与骨龙各自独立召唤上限（各1），通过 `source_key` 区分；属性采用基础值+英雄攻击比例加成的混合方式。
- 英雄选择界面重构为战斗单位详情样式：头像框、名称/定位、四列属性网格、技能按钮（点击弹窗详情）、英雄强化按钮（三列，点击弹窗详情）、翻页轮播头像。
- 信息弹窗自动关闭：点击面板空白处或切换英雄时关闭。
- 羁绊面板改为根据激活数量动态调整高度，不再使用固定尺寸。
- 按钮全局添加 hover/press 缩放补间动画（`PixelUITheme.apply_button_style` 自动集成）。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_summon_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_hero_battle_spawn.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --quit
```

## 2026-05-23 增量进度

近期完成并通过 headless 检查的内容：

- 主菜单与战斗 HUD 已统一为代码生成的像素风 UI：按钮、金币框、遗物栏、遭遇信息框、出售区、阵容面板等框体与按钮均通过 `scripts/ui/pixel_ui_theme.gd` 生成样式，不再使用图片按钮资源。
- 主菜单仍保留背景图作为场景美术；开始游戏、镜像挑战、图鉴三个入口按钮现在同组排列、尺寸一致，并使用统一像素风按钮样式。
- 出售区恢复并固定显示 `出售` 与 `拖拽单位到这里出售`，文字使用像素风描边样式。
- 战斗背景与 7 格棋盘仍保留为场景素材；按钮和 UI 框体的图片皮肤已移除，最终状态以代码样式为准。
- 新增 `docs/future_features.md`，整理远程普攻真实弹道和非圆形瞬时 AoE 的功能设计、实现入口、数据结构、推荐步骤和边界情况。
- 整理 `docs/README.md`，将文档分为当前维护文档、UI/流程专题、历史记录和过期草案，避免把旧设计误当成当前规格。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/ui/menu_panel_controller.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_unit_detail_panel_ui.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_encyclopedia_catalog.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 2026-05-20 增量进度

近期新增并通过 headless 检查的内容：
- 羁绊 UI 已从纯文本显示优化为可交互面板：准备/战斗阶段在商店按钮下方显示已激活羁绊，点击具体羁绊名称后查看该羁绊的当前计数、已激活档位和各档详细效果。
- 羁绊面板会在商店打开时隐藏，关闭商店后恢复刷新，避免与商店面板重叠。
- `BondManager` 新增按单个羁绊生成详情文本的查询接口，主界面只负责显示和交互，不承载羁绊数值规则。
- `docs/content_reference.md` 已重新生成，更新时间同步到 2026-05-20，并在玩家单位与英雄表格中新增羁绊标签列。
- 新增 `docs/README.md` 作为文档目录，区分当前维护文档、专题设计文档、历史阶段记录和已过期草案。
- 为明显过期或已被实现替代的文档添加历史说明，避免后续把旧设计误当成当前规格。

本轮常用验证命令：
```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_bond_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tools/generate_content_reference.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 2026-05-17 增量进度

近期新增并通过 headless 检查的内容：
- 新增第一版羁绊系统，核心逻辑集中在 `scripts/bond_manager.gd`，当前支持铁壁、猎手、奥术、圣疗、召唤、剧毒 6 类羁绊。
- `UnitData` 与运行时 `Unit` 新增 `bond_tags: Array[String]`，玩家单位与英雄单位资源已按当前设计配置羁绊标签；召唤物默认不计入召唤羁绊数量。
- `BondManager` 按当前上场阵容和已选英雄统计羁绊，同一 `unit_type` 只计 1 次，不统计备战席和召唤物；Restart 与战场清理时会清空羁绊运行时状态。
- 战斗开始时会根据当前统计结果应用羁绊：铁壁/猎手只影响对应标签成员，奥术/圣疗可影响全体玩家单位，召唤会增强玩家召唤物，剧毒会增强玩家施加的剧毒效果。
- 召唤物生成、召唤物死亡和剧毒施加入口已经接入羁绊事件：新生成玩家召唤物会吃召唤羁绊属性；3 召唤会在友方召唤物死亡时给存活非召唤友军护盾和魔力；3 剧毒会在冷却允许时额外追加 1 层剧毒。
- 主界面新增初版羁绊显示，准备阶段上阵/下阵和英雄选择后刷新，战斗开始使用当前显示对应的羁绊统计；该 UI 已在 2026-05-20 优化为可点击羁绊名称查看详情。
- 羁绊档位、成员、事件接入和验证方式整理到 `docs/bond_system.md`。

本轮常用验证命令：
```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_bond_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_summon_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_status_effect_stack_policy.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_hero_battle_spawn.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 2026-05-16 增量进度

近期新增并通过 headless 检查的内容：
- 新增 8 件围绕扩展战斗属性设计的遗物，并接入 `RelicRewardPool` 与 `RelicEffectResolver`：奥术棱镜、慈悲香炉、破甲砺石、血玻璃护符、壁垒符文、开场秘典、充能针、幻影披风。
- 新遗物覆盖技能强度、治疗强度、护盾强度、防御穿透、吸血、伤害减免、初始魔力、普攻回魔、受击回魔、状态抗性和闪避等扩展属性。
- 新属性遗物初版以战斗开始类临时效果为主；后续已将适合常驻生效的部分接入 `AURA` 光环系统，仍只修改运行时 `Unit` 字段，不永久写回 `UnitData`。
- `scripts/tests/test_extended_unit_attributes.gd` 已补充新遗物验证，确认全队、前排、后排和魔力相关效果可以正确写入新属性。

本轮常用验证命令：
```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_extended_unit_attributes.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_kill_relics.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 2026-05-15 增量进度

近期已完成并通过 headless 检查的主要增量：

- 新增第一版英雄系统：开局选择 1 名英雄，英雄作为特殊单位上场，不占用普通 `max_active_units`，不可购买、出售、升星或下阵。
- 已实现 4 名英雄：铁誓统帅、奥术导师、血影猎手、织骨者，均拥有独立被动、主动技能、推荐站位和本局强化池。
- 英雄升级改为经验条：50 经验升级；普通关 +10、精英关 +20、Boss 关 +30。每次升级弹出英雄强化三选一，专属强化不足 3 个时用随机基础属性强化补齐。
- 英雄拥有等级成长曲线，生成战斗单位时随等级提高生命、攻击、防御和魔力回复；可重复基础属性强化会继续叠加。
- 英雄现在可在准备阶段拖动调整站位，但只能放置在玩家棋盘内，不能拖入备战席或出售区。
- 新增英雄选择界面：按钮展示英雄名和一句简介；点击英雄后在详情区展示简介、基础数值、技能效果和经验成长规则，再点击确认按钮进入游戏。
- 战斗单位详情支持英雄专属信息：英雄被动、主动技能、当前等级强化、已选英雄强化和可重复属性强化层数会单独展示。
- 奖励三选一界面新增悬停详情面板：奖励按钮保持简洁，悬停时展示详细说明；单位奖励详情会显示被动和主动技能。
- 新增 Boss 胜利阵容快照：保存玩家通关 Boss 时的上场单位、备战单位、遗物与全局效果，可解析并还原。
- 新增镜像挑战模式：主菜单提供入口；该模式会在开局锁定历史 Boss 快照，并将 Boss 波替换为玩家历史通关阵容。
- 新增并接入击杀相关遗物；击杀触发效果已接入统一遗物触发路径。
- 新增 AOE 单位和范围显示：主动技能、普攻 AOE 与持续治疗范围均可显示范围效果；神官技能改为 3 秒持续治疗，总治疗量保持不变。
- 主菜单背景、战斗背景和棋盘素材已接入；按钮和 UI 框体后来统一改为代码生成像素风样式。棋盘最终使用 7 格素材，遗物显示对齐已修复。

本轮常用验证命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_hero_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --script res://scripts/tests/test_hero_battle_spawn.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ... --quit
```

## 当前目录结构

```text
res://
├── data/
│   ├── units/*.tres                # 玩家普通单位资源
│   ├── heroes/*.tres               # 英雄对应 UnitData 资源
│   ├── enemies/*.tres              # 敌人单位资源
│   ├── summons/*.tres              # 召唤物（骷髅/傀儡/魂偶/骨巨人/骨龙）
│   └── relics/*.tres               # 遗物资源
├── assets/
│   └── game/units/heroes/*.png      # 英雄头像、棋盘图标、图标和立绘资源
├── docs/
│   ├── README.md                   # 文档目录与新旧关系
│   ├── bond_system.md
│   ├── content_reference.md        # 当前单位、英雄、敌人、召唤物和遗物数值总览
│   ├── future_features.md          # 功能规划与实现记录
│   ├── hero_design.md
│   ├── lineup_snapshot_design.md
│   ├── mirror_challenge_design.md
│   ├── phase_summary_2026-05-04.md
│   ├── refactor_plan_2026-05-06.md
│   ├── stat_modifier_system_design.md
│   ├── ui_layering_design.md
│   ├── 索敌设计.md
│   └── project_status.md
├── scenes/
│   ├── main.tscn
│   ├── unit.tscn
│   ├── combat/
│   │   └── projectile.tscn
│   └── ui/
│       ├── main_menu_panel.tscn
│       ├── gameplay_menu_panel.tscn
│       ├── game_end_panel.tscn
│       ├── shop_panel.tscn
│       ├── reward_panel.tscn
│       ├── hero_selection_panel.tscn
│       ├── encyclopedia_panel.tscn
│       ├── unit_detail_panel.tscn
│       ├── relic_bar_panel.tscn
│       ├── relic_detail_panel.tscn
│       ├── bench_panel.tscn
│       ├── sell_zone_panel.tscn
│       ├── encounter_info_panel.tscn
│       └── stats_panel.tscn
└── scripts/
    ├── catalog/
    ├── combat/
    │   ├── active_skill_caster.gd
    │   ├── aoe_resolver.gd
    │   ├── aoe_shape_visual.gd
    │   ├── attack_payload.gd
    │   ├── combat_resolver.gd
    │   ├── field_effect_manager.gd
    │   ├── field_effect_visual.gd
    │   ├── passive_resolver.gd
    │   ├── projectile.gd
    │   ├── projectile_manager.gd
    │   ├── shape_geometry.gd
    │   ├── stat_modifier.gd
    │   ├── status_effect_factory.gd
    │   └── unit_stat_controller.gd
    ├── encounter/
    ├── formatters/
    ├── game/
    ├── relic/
    ├── roster/
    ├── ui/
    ├── main.gd
    ├── battle_manager.gd
    ├── battle_time_manager.gd
    ├── bond_manager.gd
    ├── encounter_manager.gd
    ├── hero_data.gd
    ├── hero_manager.gd
    ├── hero_upgrade_data.gd
    ├── lineup_snapshot_manager.gd
    ├── reward_manager.gd
    ├── roster_manager.gd
    ├── shop_manager.gd
    ├── summon_manager.gd
    ├── relic_manager.gd
    ├── stats_manager.gd
    ├── status_effect.gd
    ├── summon_data.gd
    ├── unit_text_formatter.gd
    ├── unit.gd
    ├── unit_combat.gd
    ├── unit_targeting.gd
    ├── unit_feedback.gd
    ├── unit_drag_controller.gd
    ├── unit_data_applier.gd
    ├── unit_data.gd
    └── relic_data.gd
```

## 场景职责

### `scenes/main.tscn`

主场景。

负责承载：
- 主控制脚本 `main.gd`
- `BoardBackground Node2D`
- `UI CanvasLayer`
- Result / Round / Gold 等 HUD 基础标签
- 开始战斗、菜单、商店等基础按钮
- `scenes/ui/` 下各 UI 子场景实例

当前不再直接承载完整商店、奖励、遗物、单位详情、统计等面板的静态节点树，这些面板已拆为独立 `.tscn`。

### `scenes/unit.tscn`

单位场景。

当前包含：
- `Unit Node2D`
- `Body ColorRect`
- `HPBar ProgressBar`

单位本身的行为由 `unit.gd` 和拆分后的 Unit 辅助脚本实现。

## 脚本职责划分

### `main.gd`

当前定位：整体流程协调器。

主要负责：
- 初始化各个 Manager 与 UI Controller
- 连接主流程 signal
- 协调 `RunController` 的主菜单、准备、战斗、奖励和结束状态
- 协调准备阶段拖拽部署、备战席调度和出售入口
- 控制 HUD、商店、奖励、遗物、单位详情等 UI 的显示刷新
- 接收 `BattleManager` 的战斗结束信号
- 调用 `EncounterManager`、`RosterManager`、`BattleManager`、`RewardManager`、`RelicManager` 完成局内流程串联

当前不再直接负责：
- 单位生成
- 单位数组维护
- 胜负判断
- 单位死亡处理
- 奖励具体应用
- 遗物具体触发
- 单位战斗细节
- 金币经济公式
- 波次上限和 Boss/精英规则
- 主动/被动技能具体效果
- 遗物具体效果
- 商店商品刷新规则

### `battle_manager.gd`

当前定位：单场战斗管理器。

主要负责：
- 清理战场
- 生成双方单位
- 给单位分配队伍、位置、数据、显示名
- 连接单位信号
- 启动战斗
- 给单位分配敌方列表
- 监听单位死亡
- 判断胜负
- 战斗结束时停止单位并保存统计
- 转发攻击、击杀、死亡事件给遗物系统
- 托管 `SummonManager`，支持战斗中生成召唤单位、胜负计数、限时召唤扩展和召唤物清理

### `reward_manager.gd`

当前定位：奖励生成与奖励选择应用入口。

主要负责：
- 生成三选一奖励
- 区分奖励类型：
  - `STAT`
  - `UNIT`
  - `RELIC`
- 属性奖励转发给 `RosterManager`
- 单位奖励转发给 `RosterManager`
- 遗物奖励转发给 `RelicManager`

### `roster_manager.gd`

当前定位：玩家阵容与玩家成长管理器。

主要负责：
- 保存玩家当前阵容 `player_roster`
- 管理全队生命倍率
- 管理全队攻击倍率
- 应用全队生命奖励
- 应用全队攻击奖励
- 新增随机单位
- 新增指定单位
- 为下一场战斗生成已经应用成长后的玩家单位数据
- Restart 后恢复初始阵容

### `relic_manager.gd`

当前定位：遗物持有与遗物效果触发管理器。

主要负责：
- 保存玩家当前拥有遗物
- 添加遗物
- 清空遗物
- 防止重复获得同名遗物
- 生成可用遗物奖励选项
- 触发战斗开始遗物
- 应用常驻光环遗物
- 触发攻击遗物
- 触发击杀遗物
- 触发死亡遗物
- 统计遗物伤害

当前完整遗物池以 `docs/content_reference.md` 和 `docs/relic_design.md` 为准。当前触发类型包括：
- `AURA`：常驻光环，单位生成后应用，适用于备战阶段、战斗开始和战斗中召唤物。
- `BATTLE_START`：战斗开始时的一次性临时增益、护盾或初始魔力。
- `ON_ATTACK`：普通攻击命中后触发。
- `ON_KILL`：玩家单位击杀目标后触发，支持 `Blood Oath Chalice / 血誓杯` 这类本局永久属性成长。
- `ON_DEATH`：玩家单位死亡时触发，支持 `Gravebone Charm / 骸骨坠饰` 这类遗物召唤效果。

### `stats_manager.gd`

当前定位：战斗统计管理器。

主要负责：
- 注册单位
- 记录造成伤害
- 记录承受伤害
- 记录攻击次数
- 记录击杀数
- 记录死亡时间
- 记录战斗结束时是否存活
- 保存死亡单位统计快照
- 生成统计面板文本

### `unit.gd`

当前定位：单位对外接口与单位生命周期协调器。

主要负责：
- 保存单位运行时状态
- 暴露对外方法：
  - `take_damage`
  - `heal`
  - `add_shield`
  - `add_battle_attack_bonus_percent`
  - `set_enemy_units`
  - `set_can_drag`
  - `start_battle`
  - `stop_battle`
  - `finish_battle`
- 在 `_process` 中协调：
  - 冷却更新
  - 索敌
  - 移动
  - 攻击
  - 卡住检查
- 发出单位信号：
  - `died`
  - `attack_landed`
  - `killed_target`

具体行为已经拆分到多个辅助脚本。

### `unit_combat.gd`

当前定位：单位战斗数值结算。

主要负责：
- 受伤结算
- shield 先扣除
- 实际伤害计算
- 承伤统计
- 造成伤害统计
- 死亡处理
- 击杀归属
- 治疗
- 添加护盾
- 战斗中攻击力加成

### `unit_targeting.gd`

当前定位：单位索敌和追击逻辑。

主要负责：
- 目标合法性检查
- 当前目标维护
- 搜索目标
- `NEAREST` 策略
- `LOWEST_HP` 策略
- 低血量策略定期重新评估
- 卡住检测
- 攻击范围判断
- 直线追击移动

当前索敌策略：
- `NEAREST`：最近敌人优先，距离相同时选择当前血量更低者，再按 unit_id 稳定排序
- `LOWEST_HP`：血量百分比最低优先，百分比相同看当前血量，再看距离，再按 unit_id 稳定排序

### `unit_feedback.gd`

当前定位：单位战斗反馈。

主要负责：
- 攻击缩放反馈
- 受伤闪烁
- 伤害数字
- 死亡淡出
- 死亡淡出后 `queue_free`

### `unit_drag_controller.gd`

当前定位：准备阶段拖拽控制。

主要负责：
- 左方单位拖拽
- 鼠标命中检测
- 拖拽偏移记录
- 战斗阶段禁止拖拽

### `unit_data_applier.gd`

当前定位：把 `UnitData` 应用到单位实例。

主要负责读取：
- `unit_name_cn`
- `max_hp`
- `attack_damage`
- `attack_interval`
- `attack_range`
- `search_range`
- `move_speed`
- `unit_type`
- `target_mode`
- `retarget_interval`
- `lowest_hp_switch_threshold`
- `basic_attack_type`
- `projectile_speed`
- `projectile_visual_type`
- `board_sprite`
- `portrait_texture`
- `icon_texture`
- `art_scale`
- `art_offset`

同时兼容旧字段：
- `target_strategy`

### `unit_data.gd`

单位配置资源脚本。

当前主要数值以 `docs/content_reference.md` 为准；单位资源已支持中文名、羁绊标签、扩展战斗属性、远程弹道配置和静态美术资源字段。

### `relic_data.gd`

遗物配置资源脚本。

当前字段包括：
- `relic_id`
- `relic_name`
- `relic_name_cn`
- `description`
- `rarity`
- `trigger_type`
- `value`

## 当前主流程

```text
MAIN_MENU
  玩家选择普通模式或镜像挑战

HERO_SELECTION
  玩家选择 1 名英雄
  英雄选择完成后进入准备阶段

PREPARE
  玩家可以拖动普通单位和英雄调整站位
  英雄只能放在玩家棋盘内，不可下阵或出售
  点击 Start

BATTLE
  双方单位自动索敌、移动、攻击
  单位死亡后检查胜负

RESULT
  显示胜负结果和战斗统计
  Boss 胜利时保存玩家阵容快照
  英雄经验足够时先进入英雄强化选择

REWARD
  玩家胜利时显示三选一奖励
  玩家选择奖励

NEXT_PREPARE
  进入下一轮准备阶段

GAME_OVER
  玩家失败或通关后结束

MIRROR_CHALLENGE
  总波次与普通模式相同
  Boss 波使用开局锁定的历史 Boss 通关阵容替换
```

## 已完成功能

### 战斗基础

- 双方单位生成
- 单位基础属性
- HPBar 更新
- 自动寻敌
- 直线移动
- 自动攻击
- 远程单位使用真实弹道：发射飞行物→追踪目标→命中结算（2026-05-23 实现）
- 近战单位保持即时命中
- 普通攻击的计数被动（如 unstable_bomb）改为发射时检测（launch_count），采用快照机制
- 攻击冷却
- 死亡淡出
- 伤害数字
- 受伤闪烁
- 攻击反馈
- 主动技能 AOE 范围显示
- 普攻 AOE 范围显示
- 持续治疗范围显示
- 圆形、矩形、扇形瞬时 AoE 命中与范围视觉已支持；持续伤害/治疗区域仍以圆形为主，后续扩展可继续参考 `docs/future_features.md`
- 神官范围治疗改为 3 秒持续治疗，总治疗量保持不变

### 索敌

- 支持 `NEAREST`
- 支持 `LOWEST_HP`
- 支持目标合法性检查
- 支持目标死亡、无效、不可选中、超出搜索范围后的重新索敌
- 支持目标离开攻击范围但仍在搜索范围内时继续追击
- 支持卡住检测

### 多阶段流程

- 准备阶段
- 战斗阶段
- 结果阶段
- 奖励阶段
- 下一轮准备
- 游戏结束

### 多轮战斗

- `RunController.current_round`
- `RunController.max_round = 30`
- 普通战、每 5 波精英、每 10 波 Boss
- 第 30 波 Boss 胜利后通关
- 敌方强度随波次、遭遇类型和星级规则递增
- 通关判断
- 失败判断
- Restart 重置整局

### 英雄系统

- 开局选择 1 名英雄
- 已接入铁誓统帅、奥术导师、血影猎手、织骨者
- 英雄作为特殊单位加入玩家队伍
- 英雄上场参与战斗，不占用普通单位最大上场数量
- 英雄不能购买、出售、升星或下阵
- 英雄死亡只影响当前战斗，下一场会重新生成
- 英雄可在准备阶段拖动调整站位，站位保存在当前局 `HeroManager` 状态中
- 英雄拥有专属被动、主动技能和强化池
- 英雄使用 50 经验升级：普通关 +10，精英关 +20，Boss 关 +30
- 英雄升级时弹出强化三选一，选项不足 3 个时用随机基础属性强化补齐
- 英雄等级会按成长曲线提高基础属性
- Restart 后清空英雄选择、等级、经验和强化

### 阵容快照与镜像挑战

- Boss 胜利后保存玩家阵容快照
- 快照包含上场单位、备战单位、遗物和全局效果
- 快照可解析并还原为阵容与遗物状态
- 新增镜像挑战模式入口
- 镜像挑战开局时随机锁定历史 Boss 通关阵容
- 镜像挑战中的 Boss 波会替换为历史玩家阵容
- 镜像 Boss 仍沿用 Boss 遭遇类型，因此胜利奖励、快照和通关判断保持一致

### 奖励系统

- 三选一奖励
- 属性奖励
- 单位奖励
- 遗物奖励
- 遗物不重复出现
- 奖励影响后续战斗
- 奖励按钮保持简洁文本
- 奖励悬停详情面板显示完整说明
- 单位奖励悬停详情会显示被动和主动技能
- 英雄升级时复用奖励面板显示英雄强化三选一

### 玩家阵容成长

- 玩家阵容持久化
- 全队生命倍率
- 全队攻击倍率
- 单位本局永久属性加成 `permanent_stat_bonuses`
- 升星合成时合并本局永久属性加成
- 新增单位进入后续战斗
- Restart 后恢复初始阵容

### 遗物系统

- 遗物数据结构
- 玩家遗物列表
- 战斗开始触发遗物
- 攻击触发遗物
- 击杀触发遗物
- 死亡触发遗物
- 遗物伤害统计
- 新增 `Gravebone Charm / 骸骨坠饰`：友方非召唤单位死亡时召唤 1 个骷髅，遗物自身最多同时维持 3 个骷髅，召唤物死亡不会触发

### 召唤系统

- 新增 `SummonData` 和 `SummonManager`
- 召唤物默认存活到本场战斗结束，并预留 `duration` 支持后续限时召唤物
- 召唤位置支持显式指定；默认生成在召唤者身边
- 召唤物默认影响胜负结算
- 单位自身召唤效果默认最多同时维持 3 个召唤物，可通过单位 meta 或被动调整
- 遗物召唤上限独立计算，由遗物效果提供
- 召唤物可触发攻击、击杀、死亡类遗物，但不会吃本场已经结算过的战斗开始类 Buff；新生成的玩家召唤物会先标记 `is_summon`，再按规则刷新允许作用于召唤物的动态光环
- 已新增玩家单位：`Necromancer / 亡灵法师`，主动技能召唤骷髅
- 已新增玩家单位：`Puppet Warlock / 傀儡术士`，标记敌人，标记目标死亡时召唤傀儡
- 已新增召唤型敌人：`Grave Caller / 唤墓者`、`Bone Carrier / 运骨者`、`Puppet Binder / 傀儡缚师`
- 已新增英雄召唤物：`Bone Golem / 骨巨人`（近战肉盾）、`Bone Dragon / 骨龙`（远程AOE），由织骨者主动技能召唤

### 战斗统计

- 造成伤害
- 承受伤害
- 攻击次数
- 击杀数
- 存活时间
- 战斗结束是否存活
- 死亡单位统计不丢失
- 结果面板显示 MVP 和单位列表

### UI 与交互

- 主菜单使用像素风背景图，开始游戏、镜像挑战、图鉴三个入口按钮同组排列、尺寸一致。
- 战斗背景与 7 格棋盘保留为场景素材。
- 按钮、金币框、遗物栏、遭遇信息框、出售区、阵容面板等 UI 框体统一使用代码生成的像素风样式，不再使用图片按钮和图片框体皮肤。
- 出售区显示 `出售` 与 `拖拽单位到这里出售`，并使用统一像素风文字样式。
- 遗物栏显示对齐和超过 5 个后的展开按钮位置已修复。
- 英雄选择界面支持先预览再确认：底部方形头像轮播，左右按钮每次移动一格；点击头像展示完整英雄详情（头像框、四列属性、技能按钮弹窗详情、三列强化按钮、经验成长），确认/返回按钮在面板底部。
- 英雄选择界面已接入英雄头像/立绘；棋盘英雄显示使用裁切后的 96×96 棋盘图标。
- 局内菜单按钮和菜单面板层级高于英雄选择面板，选择界面中点击菜单可以正常看到菜单。
- 单位详情支持点击单位打开，点击空白位置关闭。
- 英雄单位详情会显示专属技能、等级强化和已选强化。
- 按钮全局 hover/press 缩放补间动画（`PixelUITheme` 自动集成）。

## 当前结构评价

当前结构已经完成 2026-05-06 重构计划，具备继续扩展内容和调数的基础。

优点：
- `main.gd` 已经从战斗细节、经济公式、遭遇生成、技能效果和遗物效果中解耦，主要负责流程协调和 UI 装配
- `battle_manager.gd` 负责单场战斗，边界更清楚
- `reward_manager.gd`、`roster_manager.gd`、`relic_manager.gd`、`shop_manager.gd`、`encounter_manager.gd`、`stats_manager.gd` 均已拆出部分领域服务
- `unit.gd` 已经瘦身，保留对外接口，细节拆到辅助类
- 数据资源、脚本服务和 UI 场景资源分离
- `scenes/main.tscn` 已改为轻量装配场景，主要 UI 面板位于 `scenes/ui/`

需要注意：
- `scripts/` 下文件数量已经变多，但目录边界已经比较清晰
- 不建议继续做大范围搬迁；后续应按实际新增功能小步调整
- `main.gd` 仍保留准备阶段拖拽、部署、出售和 HUD 刷新协调，后续若继续瘦身可优先拆准备阶段交互协调器

## 后续建议

### 短期建议

1. 优先做可玩性验证、数值曲线和 UI 可读性，而不是继续大拆结构。
2. 每次新增系统时优先放入现有目录边界，避免把逻辑塞回 `main.gd`。
3. 每次新增单位技能时优先放入 `scripts/combat/active_skill_caster.gd` 或 `scripts/combat/passive_resolver.gd`。
4. 每次新增遗物效果时优先放入 `scripts/relic/relic_effect_resolver.gd`，触发条件放入 `scripts/relic/relic_trigger_dispatcher.gd`。
5. 每次新增 UI 面板时优先新增 `scenes/ui/*.tscn` 和 `scripts/ui/*_controller.gd`。
6. 远程普攻真实弹道和非圆形瞬时 AoE 已完成并保留在 `docs/future_features.md` 作为实现参考；后续扩展抛物线弹道、持续非圆形区域或新 shape 时，继续沿用 CombatResolver、ProjectileManager、AoeResolver.get_units_in_shape() 和 AoEShapeVisual 的现有边界。

### 中期可考虑

如果准备阶段交互继续复杂化，可以新增：
- `scripts/game/prepare_phase_controller.gd`

用于统一：
- 准备阶段按钮显隐
- 棋盘/备战席拖拽调度
- 出售区命中与出售结算入口
- 准备阶段 UI 刷新顺序

如果需要自动化验收，可以新增：
- Godot headless 流程测试脚本

用于覆盖：
- 主菜单开始游戏
- 商店购买/刷新
- 单位部署/出售
- 开始战斗
- 战斗结束奖励
- 失败或通关返回主菜单

### 后续暂缓

当前阶段已经补入商店、单位解锁、稀有度、复杂技能描述和奖励弹窗等系统，仍暂缓加入：
- 路线地图
- 装备背包
- 战斗回放
- 存档系统

这些系统会显著增加状态复杂度，建议等当前 30 波推进、商店与奖励循环进一步稳定后再做。

### 高稀有度联动单位

- 新增 8 个玩家单位数据资源：`Soul Binder / 缚魂祭司`、`Starforged Vanguard / 星铸禁卫`、`Arcane Artillerist / 奥术炮师`、`Venom Matriarch / 剧毒女王`、`Dawnbell Saint / 晨钟圣徒`、`Nightblade Captain / 夜刃统领`、`Bloodbound Berserker / 血契狂战`、`Prism Weaver / 棱镜术师`。
- 新增召唤物 `Soul Puppet / 魂偶`，由缚魂祭司的 `Binding Rite / 缚魂仪式` 标记击杀生成，并继承目标部分生命与攻击。
- `UnitCatalog` 已改为扫描 `res://data/units`，后续新增单位资源会自动进入单位目录、商店/解锁池和图鉴。
- 已接入新单位星级成长、主动技能、被动技能、技能说明与内容总览文档。
- `Dawnbell Saint / 晨钟圣徒` 的阻止死亡判定已调整为在单位自身减伤被动结算之后执行，避免战士等自带减伤单位绕过救赎。
- 新增 `scripts/tests/test_high_rarity_units.gd`，覆盖新单位加载、成长、关键主动/被动和魂偶召唤链路。
