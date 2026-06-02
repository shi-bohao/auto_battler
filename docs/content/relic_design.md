# 遗物设计文档

> 维护提示：当前遗物列表与数值以自动生成的 `docs/content_reference.md` 为权威来源。触发类型与效果路径以 `docs/systems/relic_system.md` 为准。UI 展示规则见 `docs/systems/ui_system.md`。本文档保留遗物设计意图、奖励池规则、新增遗物流程和验证清单。

## 遗物分类思路

遗物按触发方式分为 6 类，对应不同的构筑方向：

| 触发类型 | 构筑方向 | 典型遗物 |
| --- | --- | --- |
| `AURA` | 常驻增益，全局属性加强 | 战斗旌旗 (攻击)、钢铁阵列 (防御)、三星冠冕 (高星) |
| `BATTLE_START` | 开局爆发，一次性优势 | 初始火花 (魔力)、前线护板 (前排)、壁垒符文 (减伤) |
| `ON_ATTACK` | 普攻联动，适合高频攻击阵容 | 猎手印记 (弓手)、决斗手套 (刺客) |
| `ON_KILL` | 滚雪球收割，击杀收益 | 处刑徽记 (攻击)、血誓杯 (永久HP)、赏金匕首 (金币) |
| `ON_DEATH` | 阵亡补偿，容错机制 | 余烬壁垒 (护盾)、骸骨坠饰 (召唤骷髅) |
| `ON_ROUND_REWARD` | 经济运营，金币积累 | 旧钱袋、复利核心 |

## 稀有度设计原则

| 稀有度 | 设计定位 | 示例 |
| --- | --- | --- |
| `COMMON` | 通用基础属性，无职业限制 | 战斗旌旗、铁甲徽章、后排瞄镜 |
| `FINE` | 轻量经济或条件增益 | 赏金匕首、开场秘典、奥术棱镜 |
| `RARE` | 职业联动或特定触发条件 | 猎手印记、决斗手套、黄金护符 |
| `EPIC` | 强力效果，可定义构筑方向 | 处刑徽记、复利核心、猎金契约 |
| `LEGENDARY` | 构筑核心，改变玩法 | 三星冠冕、贪婪王冠 |

> `MYTHIC` 稀有度已在枚举中预留，当前无已实现遗物。

## 遗物数据结构

遗物使用 Godot `Resource` 管理（`scripts/relic_data.gd`），资源文件位于 `data/relics/*.tres`：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `relic_id` | `String` | 唯一 ID，用于去重和逻辑匹配 |
| `catalog_id` | `int` | 分类内稳定排序 ID |
| `relic_name` | `String` | 英文名 |
| `relic_name_cn` | `String` | 中文显示名 |
| `description` / `description_cn` | `String` | 效果描述 |
| `rarity` | `String` | COMMON/FINE/RARE/EPIC/LEGENDARY/MYTHIC |
| `trigger_type` | `String` | AURA/BATTLE_START/ON_ATTACK/ON_KILL/ON_DEATH/ON_ROUND_REWARD |
| `value` | `float` | 主数值 |

## 奖励池规则

- 每个遗物资源在 `scripts/relic/relic_reward_pool.gd` 中 preload 并按 `catalog_id` 排序
- 奖励池跳过已拥有的 `relic_id`（不可重复获得）
- 普通战胜利后有机率出现遗物奖励
- 精英战胜利后遗物奖励概率提高
- 第 30 波最终 Boss 胜利后直接通关，不再进入后续经营奖励阶段；中途 Boss（第 10/20 波）的奖励流程以当前主流程为准

## 新增遗物流程

1. 在本文档补充设计意图
2. 新建 `data/relics/<relic_id>.tres`，使用 `scripts/relic_data.gd` 作为脚本
3. 填写 `relic_id`、`catalog_id`、名称、描述、`rarity`、`trigger_type`、`value`
4. 在 `scripts/relic/relic_reward_pool.gd` 中 preload 并加入奖励池
5. 在 `scripts/relic/relic_trigger_dispatcher.gd` 中根据 `trigger_type` 接入触发条件
6. 在 `scripts/relic/relic_effect_resolver.gd` 中实现具体效果；
   常驻光环由 `RelicManager.apply_always_on_relics_to_runtime_unit()` 统一应用；
   战斗开始类效果通过 `RelicManager.trigger_battle_start_relics()` 统一分发，
   具体单件遗物逻辑由 `relic_trigger_dispatcher.gd` / `relic_effect_resolver.gd` 处理
7. 若新增触发类型，先在战斗或 UI 系统中增加统一事件入口，再由 `RelicManager` 对外转发

## 验证清单

### AURA
1. 获得任意 AURA 遗物，备战阶段查看单位详情确认属性已提高
2. 开始战斗后确认 BATTLE_START 入口不会叠加同一光环
3. 战斗中召唤友方召唤物，确认新生成单位不会吃开战型旧 Buff；动态金币光环按当前金币计算

### BATTLE_START
1. 获得战斗开始类遗物，开始战斗检查运行时单位属性/护盾是否变化
2. 战斗结束后回到准备阶段，确认原始单位数据没有永久修改
3. First Spark 额外确认满魔力单位能按现有逻辑自动释放技能

### ON_ATTACK
1. 获得 Hunter Mark 或 Duelist Glove，使用对应职业攻击
2. 确认额外伤害出现且不暴击，计入伤害统计和击杀归属

### ON_KILL
1. 获得 Blood Pendant/Soul Lantern/Executioner Sigil/Victory Drum/Blood Oath Chalice
2. 击杀敌人后确认恢复不超上限、攻击力提升只影响本场、全队类效果只作用于存活单位
3. Blood Oath Chalice 确认永久属性写回阵容，召唤物击杀不触发

### ON_DEATH
1. 获得 Vengeance Spark/Ember Bulwark/Soul Ember/Gravebone Charm
2. 单位死亡后确认对应触发，死亡单位自身不获得死亡后护盾/魔力
3. Gravebone Charm 确认非召唤单位死亡才召唤骷髅，召唤物死亡不递归触发

### ON_ROUND_REWARD
1. 普通/精英/Boss 胜利后确认额外金币按设计触发
2. Investment Ledger / Compound Core 使用 `pre_reward_gold` 计算，多个 `ON_ROUND_REWARD` 遗物不互相递归
3. 第 30 波最终 Boss 若跳过结算，确认不会错误触发经济遗物
