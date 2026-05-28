# 路径选择系统设计

> 最后更新：2026-05-28。本文档记录战斗胜利后"节点三选一"系统的完整设计、实现细节和数值表，是后续维护和扩展的权威参考。
>
> 已实现：波次过渡动画（全屏淡入/停留/淡出）、所有节点统一消耗 round、强制精英/Boss 节点选择（单选项）、非战斗节点退出回到路径选择。
> 已修复：弹道路由、AoE 重复释放、商人遗物去重、人口可重复购买、高稀有度单位稀有度筛选、事件/宝箱过渡信息错误、round_label 非战斗状态不更新。

## 1. 目标

将线性 30 波改为"30 个可选节点"的随机分支体验：

- 战斗胜利后，玩家从 3 个候选节点中选择下一回合内容。
- 节点类型：普通战斗、精英战斗、商人、训练场、随机事件、宝箱。
- Boss 波次固定不可跳过（round 10/20/30）。
- 选择面板复用奖励三选一视觉风格，无地图 UI。

## 2. 节点类型总览

| 节点 | 标识 | 行为 | 风险 | 收益 |
|---|---|---|---|---|
| 普通战斗 | `NORMAL` | 与现行普通波相同 | 低 | 标准金币 + 三选一奖励 |
| 精英战斗 | `ELITE` | 遭遇生成器强制生成精英遭遇（无视回合数） | 高 | 高金币 + 高稀有度奖励 |
| Boss 战 | `BOSS` | round 10/20/30 固定触发，不出现在选择面板 | 极高 | 推进进度 + Boss 专属奖励 |
| 商人 | `MERCHANT` | 遗物货架（4 格可刷新）+ 奇货货架（4 格不可刷新） | 无 | 购买遗物/高费单位/全局强化/人口提升 |
| 训练场 | `TRAINING` | 打木桩限时战斗，可如常购物后开始 | 无 | 木桩死亡掉落金币/遗物/升星券/永久属性 |
| 随机事件 | `EVENT` | 文本事件面板，2 个选项分支 | 可正可负 | 视事件而定 |
| 宝箱 | `TREASURE` | 展示遗物信息，确认后领取 | 无 | 1 个随机遗物（RARE 50%/EPIC 35%/LEGENDARY 15%） |

## 3. 流程接入

### 3.1 改造后流程

```
Battle End → Reward Panel → Path Select Panel
  → advance_round（所有类型统一消耗 round）
  → 过渡动画（全屏淡入→停留→淡出，展示回合数+节点类型+描述）
  → 进入节点状态
  NORMAL/ELITE → prepare → 战斗
  MERCHANT     → 商人面板 → 离开 → 回到 Path Select
  TRAINING     → 注入训练遭遇 → prepare → 战斗 → 奖励总结 → 回到 Path Select
  EVENT        → 事件面板 → 选择 → 继续 → 回到 Path Select
  TREASURE     → 展示遗物 → 确认 → 回到 Path Select
  BOSS/ELITE   → 强制单选项路径选择 → 同上
```

### 3.2 波次过渡动画

`scenes/ui/transition_panel.tscn` + `scripts/ui/transition_panel_controller.gd`：
- 全屏深色背景 + 居中显示：回合数、节点类型中文名、描述
- 动画：淡入 0.25s → 停留 0.4s → 淡出 0.25s → 回调进入目标状态
- 所有状态入口统一：英雄选择后首轮、路径选择后、Boss 强制推进

### 3.4 GameState 扩展

```gdscript
const PATH_SELECT: int = 8
const MERCHANT: int = 9
const EVENT: int = 10
const TRAINING: int = 11
const TREASURE: int = 12
```

### 3.5 Boss 锁定

`current_round + 1` 在 BOSS_ROUNDS [10, 20, 30] 中时，不显示选择面板，直接进入 Boss 准备。

### 3.6 非战斗节点 UI 清理

进入 PATH_SELECT/MERCHANT/EVENT/TREASURE 状态时，隐藏战斗棋盘、清除战场单位（`clear_battlefield()`）、清空战斗统计文本、隐藏所有战斗相关面板。进入准备阶段时重新显示棋盘。

## 4. 节点生成规则

### 4.1 保护期

Round 1-2：强制 3 个 NORMAL。

### 4.2 权重表

| 节点 | 基础权重 | 条件 |
|---|---|---|
| NORMAL | 5 | 始终 |
| ELITE | 2 | round >= 5 |
| MERCHANT | 2 | 冷却 2 回合 |
| EVENT | 2 | 冷却 1 回合 |
| TREASURE | 1 | 冷却 2 回合 |
| TRAINING | 1 | 冷却 2 回合 |

### 4.3 约束

1. 至少 1 个战斗节点（NORMAL 或 ELITE）。
2. 同种非战斗节点最多 1 个。
3. 候选不足 3 个时用 NORMAL 补齐。

## 5. 精英战斗（ELITE）

选择精英路径时，`encounter_manager.forced_encounter_type = "ELITE"` 强制 `encounter_generator.create_random_encounter()` 生成精英遭遇，不依赖 `wave_rule.get_encounter_type_for_round()` 的回合 % 5 判定。避免路径选择后因回合数不对应仍生成普通遭遇。

## 6. 商人节点（MERCHANT）

### 6.1 定位

与战前普通商店区分：主打高稀有度遗物、高费单位、全局强化和人口提升。

### 6.2 货架结构（两栏 4+4）

**上栏 — 遗物货架（4 格，可刷新）**
- 池子：RARE/EPIC/LEGENDARY（无 COMMON/FINE）。
- 权重：RARE 50% / EPIC 35% / LEGENDARY 15%。
- 刷新费：独立计数，2 / 4 / 8 / 16 ...（指数递增）。
- 价格：RARE=8 / EPIC=12 / LEGENDARY=16。

**下栏 — 奇货货架（4 格，不可刷新）**
- Slot 0：高稀有度单位（3 费及以上），价格 = `unit_price × 1.5` 向上取整。
- Slot 1：人口提升（始终出现，可重复购买）。
- Slot 2-3：全局强化（从 8 个中随机，不可重复购买）。

### 6.3 人口提升

- 全局上限 20，初始 10。
- 每次进入新商人节点 `population_buy_count` 重置为 0，价格重置为 3。
- 同一节点内可重复购买，价格递增：3 / 6 / 12 / 24 / 48 ...（`3 × 2^次数`）。
- 购买后立即更新货架条目（新价格和当前人口数），不标记为"已售出"。
- 达到上限 20 时条目变为"人口已达上限"并禁用。
- `max_active_units` 增加时同步更新 `max_total_units = max_active_units + max_bench_units`。

### 6.4 全局强化清单

| 名称 | 效果 | 价格 | stat | ratio | mode |
|---|---|---|---|---|---|
| 战旗誓言 | 全队普攻伤害 +10% | 8 | attack_damage | 0.10 | percent |
| 秘术结晶 | 全队技能伤害 +12% | 10 | skill_damage_bonus | 0.12 | percent |
| 牢固铸造 | 全队最大生命 +15% | 9 | max_hp | 0.15 | percent |
| 锐利刻印 | 全队暴击率 +6% | 11 | crit_chance | 0.06 | flat |
| 神速节拍 | 全队攻击间隔 -10% | 12 | attack_interval | -0.10 | percent |
| 神圣启示 | 全队治疗效果 +25% | 9 | healing_power | 0.25 | percent |
| 不竭脉络 | 全队魔力回复 +15% | 11 | mana_regen_per_second | 0.15 | percent |
| 永恒誓约 | 战斗内首次致死保留 1HP | 15 | death_prevention | 1.0 | special |

全局强化通过 `roster_manager.global_stat_bonuses` 存储，在 `unit_scaling_service.create_scaled_unit_data()` 中应用到所有战斗单位。`death_prevention` 标记存储在 `roster_manager.has_death_prevention`（战斗中实际拦截逻辑待后续接入）。

### 6.5 流程

```
PATH_SELECT → MERCHANT
  → 清除战场UI、隐藏棋盘
  → 显示 MerchantPanel
  → 购买/刷新/离开 → advance_round + 进入准备
```

## 7. 训练场节点（TRAINING）

### 7.1 流程

```
PATH_SELECT → TRAINING
  → advance_round + 注入训练场遭遇数据到 encounter_manager
  → 进入准备状态（可购物、调整阵容、查看遭遇信息）
  → 点击"开始战斗" → 检测 TRAINING 遭遇 → 进入训练战斗
  → 木桩死亡时通过 enemy_unit_died 信号触发掉落
  → 计时结束或全灭 → 显示奖励总结列表 → 确认
  → 路径选择（下下回合）
```

### 7.2 木桩单位

`data/enemies/training_dummy.tres`：

| 属性 | 值 |
|---|---|
| unit_type | training_dummy |
| enemy_tier | NORMAL（不计入敌人池） |
| max_hp | 120 + round × 20 |
| attack_damage | 0 |
| defense | 0 |
| attack_interval | 999 |
| move_speed | 0（原地不动） |
| passive_id | ""（无被动） |
| active_skill_id | ""（无技能） |

### 7.3 数量与时间

| Round | 木桩数 | 计时 |
|---|---|---|
| 1-9 | 3 | 18s |
| 10-19 | 4 | 20s |
| 20-29 | 5 | 22s |

### 7.4 掉落池（每个木桩独立掷）

| 类型 | 权重 | 内容 |
|---|---|---|
| 金币 | 35 | 3-8 金币 |
| 普通遗物 | 25 | COMMON/FINE 池 1 个 |
| 稀有遗物 | 15 | RARE 池 1 个 |
| 史诗遗物 | 5 | EPIC 池 1 个 |
| 升星券 | 8 | 随机场上 1 星单位 → 2 星；无 1 星回退 8 金币 |
| 永久属性 | 12 | 全队随机属性提升（见 7.5） |

### 7.5 永久属性掉落表

| 效果 | 概率 |
|---|---|
| 全队 HP +5% | 30% |
| 全队 ATK +5% | 30% |
| 全队防御 +5 | 20% |
| 全队技能伤害 +5% | 10% |
| 全队暴击率 +3% | 10% |

### 7.6 奖励总结

训练结束后展示所有掉落的详细列表，玩家确认后进入路径选择。不触发正常战斗的胜负/金币/英雄经验逻辑，倍速按钮在训练战斗中可用。

## 8. 事件节点（EVENT）

### 8.1 实现说明

首批 6 个事件直接硬编码在 `event_manager.gd` 的 `ALL_EVENTS` 数组中，不依赖外部 .tres 资源。`EventData` 类和各字段（min_round/max_round/required_history_tags）已在代码中定义，后续需要时可迁移到资源文件。

### 8.2 首批 6 个事件

| ID | 名称 | 文本 | 选项 A | 选项 B |
|---|---|---|---|---|
| lost_traveler | 迷途旅人 | 一名旅人请求一点援助。 | 给 3 金币 → RARE 遗物 | 拒绝 → 无事 |
| mysterious_altar | 神秘祭坛 | 祭坛低语着...... | 献祭 5 金币 → 全队随机属性 +12% | 不献祭 → 无事 |
| wandering_merchant | 流浪商人 | 我有一些便宜货...... | 8 金币 → EPIC 遗物三选一 | 离开 → 无事 |
| cursed_chest | 诅咒箱 | 箱子上有诅咒铭文。 | 50% LEGENDARY 遗物 / 50% 全队(含英雄)HP -8% | 不开 → 5 金币 |
| wounded_warrior | 受伤的战士 | 他愿意加入，但需要医治。 | 3 金币 → 随机 3 费单位 | 拒绝 → 无事 |
| arcane_anomaly | 奥术异象 | 空气中弥漫着魔力。 | 全队魔力回复 +15% | 离开 → 8 金币 |

### 8.3 效果解析器

```gdscript
EFFECT_GAIN_GOLD          # params: {amount: int}
EFFECT_LOSE_GOLD          # params: {amount: int}（不足时扣至 0）
EFFECT_GAIN_RELIC         # params: {rarity_pool: Array[String]}
EFFECT_RELIC_CHOICE_3     # params: {rarity_pool: Array[String]} → 弹 reward_panel 三选一
EFFECT_GAIN_RANDOM_UNIT   # params: {price_filter: int}
EFFECT_PERMANENT_STAT     # params: {stat: String, ratio: float, mode: "percent"/"flat"}
EFFECT_RANDOM_OUTCOME     # params: {outcomes: Array[{weight, effect_id, params}]}
EFFECT_NOTHING            # 无事
```

效果文本由 `event_manager.resolve_choice()` 生成完整 result_text，`event_panel_controller` 仅负责展示，不做二次拼接。

### 8.4 RELIC_CHOICE_3 特殊处理

事件触发 `RELIC_CHOICE_3` 时，`_show_event_relic_choice()` 从指定稀有度池中随机抽 3 个遗物，调用 `reward_panel_controller.show_custom_options()` 展示在 reward_panel 中。玩家选择后通过 `RewardManager.apply_reward()` 自动添加遗物。reward type 使用大写 `"RELIC"` 匹配 `REWARD_TYPE_RELIC` 常量。

### 8.5 流程

```
PATH_SELECT → EVENT
  → 清除战场UI、隐藏棋盘
  → 显示 EventPanel（事件文本 + 两个选项按钮）
  → 玩家选择 → 显示结果文本 + "继续"按钮
  → 点击继续 → advance_round + 进入准备
```

## 9. 宝箱节点（TREASURE）

### 9.1 流程

```
PATH_SELECT → TREASURE
  → 清除战场UI、隐藏棋盘
  → 抽取遗物 → 在 stats_label 中展示遗物名称/稀有度/描述
  → 玩家点击"确认" → 实际获得遗物（或金币补偿）
  → advance_round + 进入准备
```

### 9.2 抽取规则

权重：RARE 50% / EPIC 35% / LEGENDARY 15%。与现有遗物去重逻辑一致（调用 `relic_manager.get_available_relic_reward_options()`）。无可用遗物时补偿 10 金币。

## 10. 文件接入点

| 文件 | 改动 |
|---|---|
| `scripts/game/game_state.gd` | 新增 PATH_SELECT/MERCHANT/EVENT/TRAINING/TREASURE |
| `scripts/game/run_controller.gd` | 新增 enter_*/path_history/is_next_round_boss()/record_path_choice() |
| `scripts/path_selection_manager.gd` | **新建** 候选生成、冷却、权重、约束 |
| `scripts/merchant_manager.gd` | **新建** 货架生成、刷新、购买、人口提升、全局强化应用 |
| `scripts/training_manager.gd` | **新建** 木桩遭遇生成、计时、掉落池、升星券 |
| `scripts/event_manager.gd` | **新建** 事件加载、抽取、效果解析、6 个硬编码事件 |
| `scripts/encounter/encounter_generator.gd` | create_random_encounter() 新增 forced_type 参数 |
| `scripts/encounter_manager.gd` | 新增 forced_encounter_type / set_override_encounter() |
| `scripts/roster_manager.gd` | max_active_units 改为实例变量；新增 apply_permanent_percent_bonus/flat_bonus、global_stat_bonuses、set_unit_star_by_roster_id()、has_death_prevention |
| `scripts/roster/unit_scaling_service.gd` | create_scaled_unit_data() 新增 global_bonuses 参数和 _apply_global_stat_bonuses() |
| `scripts/battle_manager.gd` | 新增 enemy_unit_died 信号、force_end_battle() |
| `scripts/lineup_snapshot_manager.gd` | 快照新增 global_stat_bonuses/has_death_prevention |
| `scripts/ui/path_selection_panel_controller.gd` | **新建** 三选一节点面板 |
| `scenes/ui/path_selection_panel.tscn` | **新建** |
| `scripts/ui/merchant_panel_controller.gd` | **新建** 商人面板 |
| `scenes/ui/merchant_panel.tscn` | **新建** |
| `scripts/ui/event_panel_controller.gd` | **新建** 事件面板 |
| `scenes/ui/event_panel.tscn` | **新建** |
| `scripts/ui/reward_panel_controller.gd` | 新增 show_custom_options() |
| `scripts/ui/transition_panel_controller.gd` | **新建** 波次过渡动画控制器 |
| `scenes/ui/transition_panel.tscn` | **新建** |
| `scripts/stats_manager.gd` | 新增 build_statistics_by_team() 敌我分离统计 |
| `data/enemies/training_dummy.tres` | **新建** 木桩单位 |
| `scripts/main.gd` | 接入全部 6 种节点流程、过渡动画、UI 切换、战斗统计按钮、弹窗系统、全局强化、高费单位 |
| `scenes/main.tscn` | 新增 PathSelectionPanel/MerchantPanel/EventPanel 实例 |
