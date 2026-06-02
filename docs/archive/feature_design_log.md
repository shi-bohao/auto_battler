# 功能设计与实现记录

更新时间：2026-05-28

本文档记录已经完成的大型功能设计、实现入口和边界条件，用于后续扩展时回查决策背景。新的待实现功能可以先写入本文档；完成后将标题改为“已完成”，并同步更新 `project_status.md` 与对应专题文档。

## 当前状态

| 功能 | 状态 | 实现日期 |
|------|------|----------|
| ~~控制效果系统~~ | **已完成** | 2026-05-29 |
| ~~控制效果测试单位~~ | **单位资源与主动技能已完成；部分被动待补齐** | 2026-05-29 |
| 金币经济遗物 | **已完成** | 2026-05-25 |
| 远程普攻真实弹道 | **已完成** | 2026-05-23 |
| 非圆形瞬时 AoE（矩形/扇形） | **已完成** | 2026-05-23 |

控制效果系统的详细设计见 `docs/systems/status_effect_system.md`。

已完成的功能设计文档仍保留在下方作为实现参考，标题以 ~~删除线~~ 标记。

## ~~金币经济遗物~~ （已完成）

> 此功能已于 2026-05-25 按本文档设计实现。实现入口见：
> - `scripts/relic/relic_effect_resolver.gd` — 金币遗物数值计算与效果应用
> - `scripts/relic/relic_trigger_dispatcher.gd` — `ON_ROUND_REWARD` 分发与击杀金币接入
> - `scripts/relic_manager.gd` — `set_battle_gold_context()` / `trigger_round_reward_relics()` / `reset_battle_relic_state()`
> - `scripts/main.gd` — 胜利结算接入 `ON_ROUND_REWARD`，金币回调、上下文传递，以及动态金币光环的 deferred 合并刷新
> - `scripts/battle_manager.gd` — 战斗开始时调用 `reset_battle_relic_state()`，并提供动态光环刷新入口
> - `data/relics/` — 9 件新遗物资源文件
>
> 2026-05-28 实现补充：动态金币光环已加入性能保护。没有动态金币光环遗物时，金币变化不会触发全队重算；存在动态金币光环时，同一帧内多次金币变化会合并刷新；单个单位刷新时批量移除/添加 modifier，最后只重算一次属性。

### 原始设计（已按此实现）

### 目标

新增一组围绕金币获取、金币持有量和金币转化战斗属性的遗物，使经济路线可以成为独立构筑方向。

第一版需要覆盖三类效果：

- 胜利结算额外金币：在战斗胜利后的金币结算阶段触发。
- 击杀金币：玩家单位击杀敌人时触发，可带每场战斗上限或概率。
- 持有金币转化属性：通过 `AURA` 与属性修饰器读取实时金币，金币变化后动态刷新玩家运行时单位的本场战斗属性。

### 新增触发类型

需要新增 `ON_ROUND_REWARD`。

推荐语义：

- 只在玩家战斗胜利后触发。
- 在基础胜利金币计算完成后、最终金币写入前统一计算。
- 计算“持有金币”类奖励时，以进入胜利结算瞬间的 `EconomyManager.gold` 为基准。
- 如果本场战斗中通过击杀金币遗物已经获得金币，这些金币已经计入 `EconomyManager.gold`，可以影响本次胜利结算类遗物。
- 第 30 波最终 Boss 当前流程直接通关且基础金币为 0；第一版建议跳过 `ON_ROUND_REWARD`，因为后续没有商店或备战阶段可使用金币。如果后续增加通关后结算展示，可单独扩展。

推荐调用顺序：

```text
战斗胜利
↓
记录 pre_reward_gold = economy_manager.gold
↓
计算基础胜利金币 base_reward
↓
RelicManager.trigger_round_reward_relics(encounter_type, current_round, max_round, pre_reward_gold, base_reward)
↓
得到 extra_reward_gold 与日志明细
↓
economy_manager.add_gold(base_reward + extra_reward_gold)
↓
刷新金币 UI、进入奖励面板或下一流程
```

### 新增遗物清单

| 稀有度 | 遗物 | 英文名 | `relic_id` | 触发 | 效果 |
| --- | --- | --- | --- | --- | --- |
| COMMON | 旧钱袋 | Old Coin Pouch | `old_coin_pouch` | `ON_ROUND_REWARD` | 每次战斗胜利后，额外获得 1 金币。 |
| FINE | 战利品账本 | Spoils Ledger | `spoils_ledger` | `ON_ROUND_REWARD` | 每次战斗胜利后，额外获得 2 金币；如果是 Boss 战胜利，额外获得 4 金币。 |
| FINE | 赏金匕首 | Bounty Dagger | `bounty_dagger` | `ON_KILL` | 玩家单位每击杀 3 个敌人，获得 1 金币；每场战斗最多获得 3 金币。 |
| FINE | 投资账本 | Investment Ledger | `investment_ledger` | `ON_ROUND_REWARD` | 战斗胜利结算时，每持有 10 金币，额外获得 1 金币，最多 3 金币。 |
| FINE | 金甲契约 | Golden Armor Contract | `golden_armor_contract` | `AURA` | 光环：每拥有 2 金币，所有玩家前排单位获得 1 防御，最多 25 防御。（实现时改为 AURA 类型） |
| RARE | 黄金护符 | Golden Charm | `golden_charm` | `AURA` | 光环：每拥有 1 金币，所有玩家单位攻击力提高 1%，最多 20%。（实现时改为 AURA 类型） |
| EPIC | 猎金契约 | Goldhunter Contract | `goldhunter_contract` | `ON_KILL` | 玩家单位击杀敌人时，有 35% 概率获得 1 金币；每场战斗不设上限。 |
| EPIC | 复利核心 | Compound Core | `compound_core` | `ON_ROUND_REWARD` | 战斗胜利结算时，每持有 8 金币，额外获得 1 金币，不设上限。 |
| LEGENDARY | 贪婪王冠 | Crown of Greed | `crown_of_greed` | `AURA` | 光环：每拥有 5 金币，所有玩家单位获得攻击力 +3%、技能强度 +3%、治疗强度 +3%，不设上限。（实现时改为 AURA 类型） |

### 资源配置建议

每个遗物新增一个资源文件：

```text
data/relics/old_coin_pouch.tres
data/relics/spoils_ledger.tres
data/relics/bounty_dagger.tres
data/relics/investment_ledger.tres
data/relics/golden_armor_contract.tres
data/relics/golden_charm.tres
data/relics/goldhunter_contract.tres
data/relics/compound_core.tres
data/relics/crown_of_greed.tres
```

沿用 `RelicData` 当前字段：

```gdscript
relic_id = "old_coin_pouch"
relic_name = "Old Coin Pouch"
relic_name_cn = "旧钱袋"
description = "After each victorious battle, gain 1 extra gold."
description_cn = "每次战斗胜利后，额外获得 1 金币。"
rarity = "COMMON"
trigger_type = "ON_ROUND_REWARD"
value = 1.0
```

多参数遗物第一版可以继续只用 `value` 存主数值，其他数值写入 `RelicEffectResolver` 常量，避免立刻扩展 `RelicData` 结构。

推荐主数值：

| `relic_id` | `value` | 其他常量 |
| --- | --- | --- |
| `old_coin_pouch` | `1.0` | 无 |
| `spoils_ledger` | `2.0` | `SPOILS_LEDGER_BOSS_BONUS = 4` |
| `bounty_dagger` | `3.0` | `BOUNTY_DAGGER_GOLD = 1`, `BOUNTY_DAGGER_BATTLE_CAP = 3` |
| `investment_ledger` | `10.0` | `INVESTMENT_LEDGER_GOLD_PER_STEP = 1`, `INVESTMENT_LEDGER_CAP = 3` |
| `golden_armor_contract` | `2.0` | `GOLDEN_ARMOR_CONTRACT_DEFENSE_PER_STEP = 1`, `GOLDEN_ARMOR_CONTRACT_CAP = 25` |
| `golden_charm` | `0.01` | `GOLDEN_CHARM_CAP = 0.20` |
| `goldhunter_contract` | `0.35` | `GOLDHUNTER_CONTRACT_GOLD = 1` |
| `compound_core` | `8.0` | `COMPOUND_CORE_GOLD_PER_STEP = 1` |
| `crown_of_greed` | `5.0` | `CROWN_OF_GREED_BONUS_PER_STEP = 0.03` |

### 代码接入点

需要修改或新增的主要入口：

| 文件 | 改动 |
| --- | --- |
| `scripts/relic/relic_reward_pool.gd` | preload 9 个新遗物资源，并加入奖励池。 |
| `scripts/relic/relic_trigger_dispatcher.gd` | 新增 `RELIC_TRIGGER_ROUND_REWARD = "ON_ROUND_REWARD"`，新增 `trigger_round_reward_relics(...)`，并在击杀入口接入 `bounty_dagger`、`goldhunter_contract`。 |
| `scripts/relic/relic_effect_resolver.gd` | 实现金币奖励计算、击杀金币、根据金币转换战斗属性。 |
| `scripts/relic_manager.gd` | 对外新增 `trigger_round_reward_relics(...)`，返回金币增量与日志明细。 |
| `scripts/game/economy_manager.gd` | 新增 `gold_changed` 信号，金币变化后通知上层判断是否需要动态属性光环刷新。 |
| `scripts/main.gd` | 在胜利结算处接入 `ON_ROUND_REWARD`，把额外金币并入最终发放并刷新 UI；监听金币变化，先检查动态金币光环是否存在，再 deferred 合并刷新动态光环。 |
| `scripts/battle_manager.gd` | 战斗开始时重置每场金币遗物状态，并提供 `refresh_dynamic_relic_auras()` 刷新当前运行时单位。 |

推荐不要让 `RelicEffectResolver` 直接持有 `EconomyManager` 强引用。金币变动可以由触发函数返回给 `main.gd` 统一调用 `economy_manager.add_gold()`，这样 UI 刷新、日志和流程控制仍集中在经济入口。

### 结算数据结构

`ON_ROUND_REWARD` 推荐返回 Dictionary：

```gdscript
{
    "extra_gold": 0,
    "logs": PackedStringArray()
}
```

`RelicManager.trigger_round_reward_relics()` 推荐签名：

```gdscript
func trigger_round_reward_relics(
    encounter_type: String,
    current_round: int,
    max_round: int,
    pre_reward_gold: int,
    base_reward_gold: int
) -> Dictionary
```

`RelicTriggerDispatcher` 只负责判断玩家是否拥有对应遗物，具体数值计算交给 `RelicEffectResolver`。

### 每件遗物的实现规则

#### Old Coin Pouch / 旧钱袋

触发：`ON_ROUND_REWARD`

规则：

- 任意非最终通关战斗胜利后触发。
- 额外金币固定 +1。
- 与其他胜利结算遗物叠加。

#### Spoils Ledger / 战利品账本

触发：`ON_ROUND_REWARD`

规则：

- 普通战、精英战胜利：额外 +2 金币。
- Boss 战胜利：额外 +4 金币。
- 推荐 Boss 分支直接返回 4，不再叠加基础 +2，避免文本“额外获得 4 金币”出现歧义。
- 如果后续希望 Boss 为 +2 再额外 +4，需要改描述为“如果是 Boss 战胜利，再额外 +4”。

#### Bounty Dagger / 赏金匕首

触发：`ON_KILL`

规则：

- 只响应玩家单位击杀敌人。
- 召唤物是否触发：沿用当前击杀遗物默认规则。若当前 `trigger_kill_relics()` 对玩家召唤物也会触发，则第一版允许召唤物计入，除非后续设计明确排除。
- 每场战斗独立计数击杀数。
- 每 3 次击杀获得 1 金币。
- 每场战斗最多获得 3 金币，也就是最多响应 9 次有效击杀。
- 需要在每场战斗开始时重置 `bounty_dagger_kill_count` 与 `bounty_dagger_gold_gained_this_battle`。

推荐状态保存位置：

- `RelicManager` 或 `RelicTriggerDispatcher` 保存每场战斗临时状态。
- `BattleManager.start_battle()` 调用 `relic_manager.reset_battle_relic_state()`。
- Restart 和进入新战斗都需要清空该状态。

#### Investment Ledger / 投资账本

触发：`ON_ROUND_REWARD`

规则：

- 使用 `pre_reward_gold` 计算。
- `extra_gold = min(floor(pre_reward_gold / 10), 3)`。
- 10 金币：+1；20 金币：+2；30 金币及以上：+3。
- 不使用发放后的金币计算，避免和基础胜利金币或其他结算遗物互相递归。

#### Golden Armor Contract / 金甲契约

触发：`AURA`

规则：

- 使用当前实时金币数，金币变化后通过动态 modifier 刷新。
- `defense_bonus = min(floor(current_gold / 2), 25)`。
- 只影响玩家前排单位。
- 前排判定沿用现有 `Bulwark Rune` 或前排遗物使用的筛选规则，避免新增一套坐标判断。
- 只修改本场运行时单位，不写回 `UnitData`、阵容永久属性或英雄成长。
- 召唤物不会吃开战型旧 Buff；动态金币光环按当前 AURA 规则处理。

#### Golden Charm / 黄金护符

触发：`AURA`

规则：

- 使用当前实时金币数，金币变化后通过动态 modifier 刷新。
- `attack_bonus = min(current_gold * 0.01, 0.20)`。
- 所有玩家单位攻击力提高对应百分比。
- 当前实现通过 `UnitStatController` 的 `RUNTIME_PERCENT` 动态 modifier 处理，避免重复叠加或覆盖其他来源。

#### Goldhunter Contract / 猎金契约

触发：`ON_KILL`

规则：

- 玩家单位击杀敌人时触发。
- 每次有效击杀独立进行 35% 概率判定。
- 成功时获得 1 金币。
- 每场战斗不设上限。
- 推荐使用 Godot 当前随机源；如果后续要可复现战斗，需要接入统一 RNG。
- 与 `Bounty Dagger` 可以同时触发，同一次击杀可以分别结算概率金币和计数金币。

#### Compound Core / 复利核心

触发：`ON_ROUND_REWARD`

规则：

- 使用 `pre_reward_gold` 计算。
- `extra_gold = floor(pre_reward_gold / 8)`。
- 不设上限。
- 与 `Investment Ledger` 可以叠加。
- 不使用其他 `ON_ROUND_REWARD` 遗物产生的金币继续计算，避免循环放大。

#### Crown of Greed / 贪婪王冠

触发：`AURA`

规则：

- 使用当前实时金币数，金币变化后通过动态 modifier 刷新。
- `steps = floor(current_gold / 5)`。
- `bonus = steps * 0.03`。
- 不设上限。
- 所有玩家单位获得：
  - 攻击力乘算：`attack_damage *= 1.0 + bonus`
  - 技能强度加算：`skill_power += bonus`
  - 治疗强度加算：`healing_power += bonus`
- 只影响本场运行时单位。
- 与 `Golden Charm` 同时存在时，两个攻击力百分比效果在同一属性层级内加算后结算，避免互相覆盖。

### UI 与日志

金币遗物会改变玩家对收益的预期，建议第一版至少补充清晰日志：

- 胜利结算时显示基础金币与遗物额外金币。
- 如果有多件 `ON_ROUND_REWARD` 遗物，日志逐条列出贡献。
- 金币 UI 只在最终 `economy_manager.add_gold(total_reward)` 后刷新一次，避免快速跳动。
- 击杀金币遗物可以即时刷新金币 UI，但需要避免每次击杀都刷出过长结果文本。第一版可只打印日志，UI 保持金币数字更新即可。

示例日志：

```text
获得金币：12（Boss 奖励 +12）
遗物额外金币：旧钱袋 +1，战利品账本 +4，投资账本 +2
金币 +19，当前金币：42
```

### 测试建议

新增测试脚本建议：

```text
scripts/tests/test_gold_relics.gd
```

测试清单：

1. `Old Coin Pouch` 普通胜利后额外 +1。
2. `Spoils Ledger` 普通/精英胜利后 +2，Boss 胜利后 +4。
3. `Investment Ledger` 在 0/9/10/19/20/29/30 金币时分别得到 0/0/1/1/2/2/3。
4. `Compound Core` 在 0/7/8/15/16/40 金币时分别得到 0/0/1/1/2/5。
5. 多个 `ON_ROUND_REWARD` 遗物同时存在时，使用同一个 `pre_reward_gold` 计算，不互相递归。
6. `Bounty Dagger` 每 3 次有效击杀 +1，每场最多 +3。
7. `Bounty Dagger` 新战斗开始后计数和本场获得金币数清零。
8. `Goldhunter Contract` 概率触发可用固定 RNG 或 mock 方式验证成功与失败分支。
9. `Golden Armor Contract` 在 0/1/2/50/80 金币时分别给前排 +0/+0/+1/+25/+25 防御。
10. `Golden Armor Contract` 只影响前排玩家单位，不影响后排或敌人；召唤物按当前 AURA 规则处理。
11. `Golden Charm` 在 0/10/20/30 金币时分别给全队 +0%/+10%/+20%/+20% 攻击。
12. `Crown of Greed` 在 0/4/5/10/25 金币时分别给全队 +0%/+0%/+3%/+6%/+15% 攻击、技能强度和治疗强度。
13. 金币动态光环不会永久写回 `UnitData` 或阵容，金币归零或失去前排条件后会恢复基础属性。
14. Restart 后击杀计数、临时战斗状态和金币遗物状态全部清空。
15. 商店、奖励三选一、遗物去重和遗物详情显示新遗物正常。

### 实现步骤

1. 新增 9 个 `data/relics/*.tres` 资源。
2. 在 `RelicRewardPool` 中 preload 并加入奖励池。
3. 在 `RelicTriggerDispatcher` 中新增 `ON_ROUND_REWARD` 分发入口。
4. 在 `RelicManager` 中暴露 `trigger_round_reward_relics()` 与 `reset_battle_relic_state()`。
5. 在 `RelicEffectResolver` 中实现每件遗物的数值计算和战斗属性应用。
6. 在 `main.gd` 胜利金币结算处接入 `ON_ROUND_REWARD`。
7. 接入 `EconomyManager.gold_changed` 与 `BattleManager.refresh_dynamic_relic_auras()`；实际实现已增加 `has_dynamic_gold_relics()` 过滤和 deferred 合并刷新，供金币转属性遗物动态刷新。
8. 为 `Bounty Dagger` 和 `Goldhunter Contract` 接入击杀入口，并处理每场战斗临时状态。
9. 更新 `docs/relic_design.md` 和 `docs/content_reference.md`。
10. 新增并运行 `scripts/tests/test_stat_modifier_system.gd`，再跑 `main.gd --check-only` 与项目启动退出检查。

## ~~1. 远程普攻真实弹道~~ （已完成）

> 此功能已于 2026-05-23 按本文档设计实现。实现入口见：
> - `scripts/combat/combat_resolver.gd` — 统一命中结算
> - `scripts/combat/attack_payload.gd` — 发射时快照
> - `scripts/combat/projectile_manager.gd` — 飞行物管理
> - `scripts/combat/projectile.gd` — 飞行物节点
> - `scenes/combat/projectile.tscn` — 飞行物场景
> - `scripts/unit.gd` — `launch_count` / `basic_attack_type` 分流
> - `scripts/battle_manager.gd` — ProjectileManager 集成与清理

### 原始设计（已按此实现）

### 目标

立项时普通攻击在 `Unit._attack_current_target()` 中即时结算：攻击间隔到达后，检查目标、立即造成伤害、触发 `attack_landed`、普攻被动、攻击遗物、吸血、普攻回魔和统计。

计划改为远程单位使用真实弹道：

```text
攻击间隔到
检查目标是否合法
发射 projectile
projectile 飞行
projectile 命中
再次检查目标是否合法
结算伤害
触发 attack_landed
触发普攻被动 / 遗物 / 吸血 / 回魔 / 击杀统计
```

关键原则：只有 projectile 命中后，才算一次真正的普通攻击命中。

因此以下逻辑必须延后到命中时：

- `attack_landed` 信号。
- 普攻命中被动。
- `ON_ATTACK` 遗物。
- 吸血。
- 普攻回魔。
- 伤害统计。
- 击杀归属。
- Hunter Mark、`unstable_bomb`、`cleaving_edge`、Duelist Glove 等依赖普攻命中次数的效果。

### 近战与远程分流

不要用 `attack_range` 自动推断是否远程。部分近战单位可能拥有较大的攻击范围，辅助单位也可能需要远程表现。第一版使用显式字段。

计划在 `UnitData` 中新增：

```gdscript
@export_enum("melee", "projectile") var basic_attack_type: String = "melee"
@export var projectile_speed: float = 500.0
@export_enum("arrow", "bolt", "magic", "holy", "flask", "bomb", "dark", "curse") var projectile_visual_type: String = "arrow"
```

推荐配置：

| 类型 | 单位 |
| --- | --- |
| `melee` | `warrior`, `tank`, `assassin`, `greatsword_knight`, `guardian_captain`, `bloodbound_berserker`, `summoned_skeleton`, `summoned_puppet` |
| `projectile` | `archer`, `mage`, `priest`, `bard`, `forest_druid`, `plague_caster`, `alchemist`, `bomb_thrower`, `cleric`, `necromancer`, `puppet_warlock`, `wind_chanter`, `arcane_mentor` |

远程表现建议：

| 单位 | `projectile_visual_type` | `projectile_speed` |
| --- | --- | --- |
| Archer | `arrow` | 600 |
| Mage | `magic` | 480 |
| Priest | `holy` | 420 |
| Alchemist | `flask` | 450 |
| Bomb Thrower | `bomb` | 380 |
| Necromancer | `dark` | 430 |
| Puppet Warlock | `curse` | 430 |

第一版不要求真实抛物线，爆弹投手也可以先用直线飞行。后续可单独扩展弧线弹道。

### AttackPayload

新增一次攻击的快照数据，避免 projectile 飞行期间完全依赖实时单位节点。

建议新增 `AttackPayload` 或使用统一 Dictionary：

```gdscript
{
    "source_unit_ref": attacker,
    "source_unit_id": attacker.unit_id,
    "source_team_id": attacker.team_id,
    "source_display_name": attacker.display_name,
    "source_unit_type": attacker.unit_type,
    "source_passive_id": attacker.passive_id,
    "source_bond_tags": attacker.bond_tags.duplicate(),
    "source_star": attacker.star,

    "target_unit_ref": target,
    "target_unit_id": target.unit_id,
    "target_team_id": target.team_id,

    "base_damage": damage,
    "crit_chance": attacker.crit_chance,
    "crit_damage_multiplier": attacker.crit_damage_multiplier,
    "defense_penetration": attacker.defense_penetration,
    "lifesteal": attacker.life_steal,
    "basic_attack_type": attacker.basic_attack_type,
    "can_crit": true,
    "is_basic_attack": true,

    "created_time": battle_time,
    "max_lifetime": 2.0
}
```

Projectile 飞行期间可能发生：

- 攻击者死亡。
- 攻击者被 `queue_free`。
- 攻击者属性变化。
- 目标死亡。
- 目标移动。
- 战斗结束。

因此至少基础伤害、暴击率、暴击伤害、来源 ID 和来源阵营要在发射时保存。

### 命中规则

第一版使用追踪型目标弹道，不做物理碰撞。

发射时：

1. 攻击者拥有合法目标。
2. 目标存活。
3. 目标是敌方。
4. 目标在攻击范围内。
5. 创建 projectile。
6. 攻击者进入下一次攻击冷却。

飞行时：

- Projectile 每帧向目标当前位置移动。
- 如果目标仍然存活，则追踪目标当前位置。
- 如果目标死亡或无效，则 projectile 失效。

命中时：

- 当 projectile 距离目标小于命中阈值，例如 `8` 或 `12`，触发命中结算。
- 命中前再次检查战斗仍在进行、目标仍有效、目标仍存活、目标阵营仍与来源阵营敌对。
- 如果检查失败，projectile 直接销毁，不造成伤害，不触发 `attack_landed`，不触发遗物。

### 攻击者和目标失效规则

目标在飞行中死亡：

- Projectile 失效。
- 不重新寻敌。
- 不造成伤害。
- 不触发攻击命中。

攻击者在飞行中死亡：

- Projectile 继续飞行。
- 命中后仍然造成伤害。
- 伤害归属使用发射时保存的 `source_unit_id`。
- 吸血、自身回魔、攻击者自身回血、攻击者身上的 on-hit 被动只在攻击者仍然有效且存活时触发。
- 伤害统计、击杀归属、部分全局遗物可以根据 `source_unit_id` 记录。

战斗结束时：

- 清理所有 projectile。
- 不再触发命中。
- 覆盖胜负已判定、Restart、进入奖励阶段、进入 Game Over、切换关卡等流程。

### 攻击计数

远程单位发射 projectile 不增加 `attack_count`。

Projectile 命中成功后才增加 `attack_count`。

这样可以避免：

- 箭还没命中，Hunter Mark 已经触发。
- 目标已死但攻击计数增加。
- 未命中也触发攻击遗物。

### 统一结算入口

不要让 projectile 自己实现复杂战斗逻辑。

推荐先抽出统一方法：

```gdscript
resolve_basic_attack_hit(attacker, target, payload = null)
```

或放到独立服务：

```gdscript
CombatResolver.resolve_basic_attack_hit(payload, target)
```

统一入口负责：

1. 根据 payload 计算基础伤害。
2. 判定暴击。
3. 计算防御、减伤、护盾和生命伤害。
4. 调用 `target.take_damage()` 或对应低层结算。
5. 记录伤害统计。
6. 判断击杀归属。
7. 触发 `attack_landed`。
8. 触发普通攻击被动。
9. 触发 `ON_ATTACK` 遗物。
10. 触发吸血。
11. 触发普攻回魔。
12. 刷新 UI。

近战和远程都调用同一个入口：

```text
近战：
try_attack()
resolve_basic_attack_hit()

远程：
try_attack()
spawn_projectile()
projectile hit
resolve_basic_attack_hit()
```

### ProjectileManager

建议新增：

- `res://scripts/combat/projectile_manager.gd`
- `res://scripts/combat/projectile.gd`
- `res://scenes/combat/projectile.tscn`

`ProjectileManager` 职责：

1. 创建 projectile。
2. 保存所有 active projectiles。
3. 战斗结束时清理 projectile。
4. 提供 `spawn_basic_attack_projectile()`。
5. 根据 `projectile_visual_type` 设置样式。

`Projectile` 节点职责：

1. 按速度移动。
2. 追踪 target。
3. 判断命中。
4. 超时销毁。
5. 命中后回调统一结算入口。

Projectile 不应该知道遗物、羁绊、吸血、Hunter Mark 或伤害统计。

## ~~2. 非圆形瞬时 AoE~~ （已完成）

> 此功能已于 2026-05-23 按本文档设计实现。实现入口见：
> - `scripts/combat/shape_geometry.gd` — 形状顶点生成
> - `scripts/combat/aoe_resolver.gd` — 统一形状查询与判定
> - `scripts/combat/aoe_shape_visual.gd` — 瞬时形状视觉
> - `scripts/battle_manager.gd` — `create_aoe_shape_visual()` 入口
> - 巨剑骑士被动（扇形）+ 主动（矩形）为示例技能

### 原始设计（已按此实现）

### 目标

立项时范围攻击主要使用 `center_position + radius` 的圆形模型。此设计用于支持矩形、扇形等非圆形范围，用于剑气、冲击波、喷火、前方斩击、直线炮击等技能。

第一版只实现瞬时矩形和瞬时扇形，不实现持续非圆形区域。

### shape_data

建议将范围数据升级为统一结构：

```gdscript
{
    "shape_type": "circle", # circle / rect / sector
    "center": Vector2.ZERO,
    "origin": Vector2.ZERO,
    "direction": Vector2.RIGHT,
    "radius": 100.0,
    "width": 80.0,
    "length": 160.0,
    "angle_degrees": 90.0,
    "anchor": "center" # center / forward
}
```

### AoeResolver

新增或改造：

```gdscript
AoeResolver.get_units_in_shape(units, shape_data, excluded_units = [])
```

内部根据 `shape_type` 分发：

- `circle` -> `is_point_in_circle()`
- `rect` -> `is_point_in_rect()`
- `sector` -> `is_point_in_sector()`

保留旧接口：

```gdscript
get_units_in_radius(units, center, radius)
```

但内部改成：

```gdscript
return get_units_in_shape(units, {
    "shape_type": "circle",
    "center": center,
    "radius": radius
})
```

这样旧技能不需要大改。

### 矩形 AoE 判定

矩形应支持朝向矩形，而不是只能水平或垂直。

推荐参数：

- `origin`：通常是施法者位置。
- `direction`：从施法者指向目标。
- `length`：矩形向前延伸长度。
- `width`：矩形宽度。
- `anchor = "forward"`。

Forward 矩形判定：

```text
to_point = point - origin
forward_dist = dot(to_point, direction)
side_dist = dot(to_point, perpendicular)

命中条件：
forward_dist >= 0
forward_dist <= length
abs(side_dist) <= width / 2
```

适合技能：

- 剑气。
- 冲击波。
- 直线炮击。
- 火焰喷射。

### 扇形 AoE 判定

扇形参数：

- `origin`
- `direction`
- `radius`
- `angle_degrees`

判定方式：

```text
to_point = point - origin
distance <= radius
angle_between(direction, to_point) <= angle_degrees / 2
```

注意：

- `direction` 必须 normalize。
- `to_point` 长度接近 0 时可视为命中。

适合技能：

- 扇形斩击。
- 喷火。
- 前方冲击。
- 战吼。

### 瞬时 AoE 流程

```text
技能释放
生成 shape_data
AoeResolver.get_enemy_units_in_shape()
deal_aoe_damage()
生成 0.15 到 0.30 秒 AoE 视觉提示
结束
```

第一版不做持续非圆形区域。持续区域后续会涉及每 tick 重新判定、区域是否跟随施法者、方向是否更新、单位进出区域和视觉持续。

### AoE 视觉

建议新增：

- `AoeShapeVisual`

支持：

- `circle`
- `rect`
- `sector`

第一版只做短暂显示：

- `duration = 0.2`
- alpha 淡出。

矩形视觉可用 `draw_polygon()` 画 4 个点：

```gdscript
p1 = origin + perpendicular * width / 2
p2 = origin - perpendicular * width / 2
p3 = origin + direction * length - perpendicular * width / 2
p4 = origin + direction * length + perpendicular * width / 2
```

扇形视觉可用 16 段近似：

```gdscript
points = [origin]
for i in steps:
    angle = -half_angle 到 +half_angle
    point = origin + rotated_direction * radius
    points.append(point)
```

### 技能使用示例

横向剑气：

```gdscript
shape_data = {
    "shape_type": "rect",
    "origin": caster.global_position,
    "direction": (target.global_position - caster.global_position).normalized(),
    "length": 160.0,
    "width": 70.0,
    "anchor": "forward"
}
```

扇形斩击：

```gdscript
shape_data = {
    "shape_type": "sector",
    "origin": caster.global_position,
    "direction": (target.global_position - caster.global_position).normalized(),
    "radius": 120.0,
    "angle_degrees": 90.0
}
```

圆形爆炸：

```gdscript
shape_data = {
    "shape_type": "circle",
    "center": target.global_position,
    "radius": 100.0
}
```

## 3. 推荐实现步骤

1. 抽出普攻命中结算。
   - 先不做 projectile。
   - 将当前 `unit.gd` 中的普通攻击直接命中逻辑抽成统一方法。
   - 近战和远程仍然即时命中。
   - 验证所有被动、遗物、统计保持正常。

2. 新增 AttackPayload。
   - 封装一次攻击所需快照信息。
   - 验证使用 payload 后普通攻击结算结果和以前一致。

3. 新增 ProjectileManager 和 Projectile。
   - 先只接入 `archer`。
   - 验证 Archer 伤害变成命中后结算。
   - 验证 Hunter Mark、`ON_ATTACK`、吸血和回魔都在命中后触发。
   - 验证目标提前死亡时 projectile 消失。

4. 所有远程单位接入 projectile。
   - 给 `UnitData` 增加 `basic_attack_type`、`projectile_speed`、`projectile_visual_type`。
   - 近战单位保持即时命中。

5. 战斗结束清理 projectile。
   - 胜利、失败、Restart、进入奖励阶段和切换关卡都要清理。
   - 验证战斗结束后飞行物不会继续命中。

6. 抽象 `shape_data`。
   - 改造 `aoe_resolver.gd`。
   - 保留 `get_units_in_radius()` 作为兼容包装。
   - 验证原有圆形 AoE 技能不受影响。

7. 实现瞬时矩形 AoE。
   - 验证矩形前方单位命中，矩形外单位不命中。
   - 验证矩形可以随施法方向旋转。

8. 实现瞬时扇形 AoE。
   - 验证扇形内单位命中，扇形外单位不命中。
   - 验证角度和半径调整有效。

9. 新增 AoEShapeVisual。
   - 支持圆形、矩形和扇形短暂显示。
   - 第一版只做瞬时显示和淡出。

## 4. 边界情况清单

远程弹道必须处理：

1. 目标飞行中死亡。
2. 目标被 `queue_free`。
3. 攻击者飞行中死亡。
4. Projectile 飞行中战斗结束。
5. Projectile 超时。
6. 目标移动。
7. 目标不再是敌方。
8. Projectile 命中同一帧目标死亡。
9. 多个 projectile 同时命中同一目标。
10. 击杀后统计和遗物只触发一次。

AoE 必须处理：

1. 命中多个敌人。
2. 不命中死亡单位。
3. 不命中友方。
4. 不重复命中同一单位。
5. 单位在边界线上是否命中。
6. 矩形方向为零向量时回退。
7. 扇形方向为零向量时回退。
8. 圆形旧技能兼容。
9. AoE 击杀归属正确。
10. AoE 伤害统计正确。
