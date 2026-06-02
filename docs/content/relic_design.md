# 遗物设计文档

更新时间：2026-05-25

本文档记录当前遗物系统的数据结构、奖励池规则、已实现遗物、UI 展示和验证方式。新增遗物时应先补充本文档，再同步资源文件和 `RelicManager` 逻辑。

## 1. 数据结构

遗物使用 Godot `Resource` 管理：

- 脚本：`res://scripts/relic_data.gd`
- 资源位置：`res://data/relics/<relic_id>.tres`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `relic_id` | `String` | 遗物唯一 ID，用于去重和逻辑匹配 |
| `catalog_id` | `int` | 遗物分类内稳定排序 ID，仅用于图鉴、内容总览、奖励池和素材切图顺序 |
| `relic_name` | `String` | 英文名称 / 显示回退名称 |
| `relic_name_cn` | `String` | 中文显示名称；非空时 UI 优先显示该字段 |
| `description` | `String` | 英文描述 |
| `description_cn` | `String` | 中文描述；非空时 `get_relic_description()` 优先返回该字段 |
| `rarity` | `String` | 稀有度 |
| `trigger_type` | `String` | 触发类型 |
| `value` | `float` | 遗物主数值 |

当前稀有度枚举：

| 枚举 | 中文显示 | 奖励 UI 底色 |
| --- | --- | --- |
| `COMMON` | 普通 | 灰白 |
| `FINE` | 精良 | 绿色 |
| `RARE` | 稀有 | 蓝色 |
| `EPIC` | 史诗 | 紫色 |
| `LEGENDARY` | 传说 | 橙色 |
| `MYTHIC` | 神话 | 金色 |

当前已实现遗物暂未全部使用 6 档稀有度，但资源枚举和奖励 UI 已支持。

## 2. 系统入口

遗物持有与触发逻辑集中在：

- `res://scripts/relic_manager.gd`

玩家当前拥有的遗物：

- `RelicManager.get_player_relics()`

Restart 时调用：

- `RelicManager.clear_relics()`

触发入口：

| 入口 | 调用位置 | 用途 |
| --- | --- | --- |
| `apply_always_on_relics_to_runtime_unit(unit)` | `BattleManager` 生成玩家单位、英雄或召唤物后 | 常驻光环类遗物 |
| `trigger_battle_start_relics(player_units)` | `BattleManager.start_battle()` | 战斗开始类遗物 |
| `trigger_attack_relics(attacker, target)` | `BattleManager._on_unit_attack_landed()` | 普通攻击命中类遗物 |
| `trigger_kill_relics(attacker, target, roster_manager, hero_manager)` | `BattleManager._on_unit_killed_target()` | 击杀类遗物；后两个参数用于永久属性成长（如血誓杯叠加 `permanent_stat_bonuses`） |
| `trigger_death_relics(dead_unit, enemy_units, is_battle_active, player_units)` | `BattleManager._on_unit_died()` | 死亡类遗物 |

通用规则：

- 所有遗物默认只对玩家单位生效。
- 已拥有遗物不会重复进入奖励池。
- 去重依据为 `relic_id`。
- 战斗开始类遗物只修改本场战斗中的运行时单位，不永久修改原始 `UnitData`。
- 伤害类遗物需要明确是否暴击；除非特别说明，遗物额外伤害不暴击。
- 临时属性、光环属性和动态属性增益优先通过 `UnitStatController` 的 modifier 系统接入，避免直接改写字段后互相覆盖；详细层级见 `docs/stat_modifier_system_design.md`。
- 本局永久属性成长不写回 `.tres`，而是写入 `RosterManager` 或 `HeroManager` 的 `permanent_stat_bonuses`，由后续单位生成流程重新应用。

## 3. 当前遗物池

当前可获得遗物共 43 个。

| 遗物 | 中文名 | `relic_id` | 稀有度 | 触发 | `value` | 效果摘要 |
| --- | --- | --- | --- | --- | --- | --- |
| Battle Banner | 战斗旌旗 | `battle_banner` | `COMMON` | `AURA` | `0.1` | 光环：玩家全队攻击力 +10% |
| Iron Armor Badge | 铁甲徽章 | `iron_armor_badge` | `COMMON` | `BATTLE_START` | `30.0` | 玩家全队获得 30 护盾 |
| Blood Pendant | 鲜血吊坠 | `blood_pendant` | `RARE` | `ON_KILL` | `35.0` | 玩家单位击杀后恢复 35 HP |
| Soul Lantern | 收魂灯 | `soul_lantern` | `RARE` | `ON_KILL` | `25.0` | 玩家单位击杀后恢复 25 魔力 |
| Executioner Sigil | 处刑徽记 | `executioner_sigil` | `EPIC` | `ON_KILL` | `0.12` | 玩家单位击杀后，本场战斗攻击力提高 12% |
| Victory Drum | 凯歌战鼓 | `victory_drum` | `EPIC` | `ON_KILL` | `12.0` | 玩家单位击杀后，所有存活玩家单位获得 12 护盾 |
| Blood Oath Chalice | 血誓杯 | `vitality_trophy` | `RARE` | `ON_KILL` | `5.0` | 友方非召唤单位击杀后，本局永久获得 +5 最大生命值 |
| Hunter Mark | 猎手印记 | `hunter_mark` | `RARE` | `ON_ATTACK` | `0.75` | 玩家弓手每 3 次普通攻击追加 75% 攻击力伤害 |
| Vengeance Spark | 复仇火花 | `vengeance_spark` | `RARE` | `ON_DEATH` | `50.0` | 玩家单位死亡时对最近敌人造成 50 遗物伤害 |
| Steel Formation | 钢铁阵列 | `steel_formation` | `COMMON` | `AURA` | `12.0` | 光环：玩家全队防御 +12 |
| Sharp Edge | 锐刃 | `sharp_edge` | `COMMON` | `AURA` | `0.1` | 光环：玩家全队暴击率 +10%，限制在 0 到 1 |
| Broken Fang | 断牙 | `broken_fang` | `RARE` | `AURA` | `0.55` | 光环：玩家弓手和刺客暴击伤害 +55% |
| Arcane Core | 奥术核心 | `arcane_core` | `RARE` | `AURA` | `0.25` | 光环：玩家全队魔力回复速度 +25% |
| First Spark | 初始火花 | `first_spark` | `RARE` | `BATTLE_START` | `50.0` | 玩家全队获得 50 初始魔力，不超过 `max_mana` |
| Guardian Oath | 守护誓约 | `guardian_oath` | `RARE` | `BATTLE_START` | `70.0` | 玩家防御最高单位获得 70 护盾和 +25 防御 |
| Ember Bulwark | 余烬壁垒 | `last_stand` | `EPIC` | `ON_DEATH` | `60.0` | 玩家单位死亡时，其他存活玩家单位获得 60 护盾 |
| Soul Ember | 灵魂余烬 | `soul_ember` | `EPIC` | `ON_DEATH` | `45.0` | 玩家单位死亡时，其他存活玩家单位恢复 45 魔力 |
| Gravebone Charm | 骸骨坠饰 | `gravebone_charm` | `RARE` | `ON_DEATH` | `3.0` | 友方非召唤单位死亡时召唤 1 个骷髅；最多同时维持 3 个骷髅，召唤物死亡不触发 |
| Duelist Glove | 决斗手套 | `duelist_glove` | `RARE` | `ON_ATTACK` | `0.35` | 玩家刺客攻击低于 50% HP 的目标时追加 35% 攻击力伤害 |
| Mage Lens | 法师透镜 | `mage_lens` | `RARE` | `AURA` | `0.35` | 光环：玩家法师主动技能伤害 +35% |
| Healing Bell | 治愈铃 | `healing_bell` | `RARE` | `AURA` | `0.4` | 光环：玩家牧师主动技能治疗 +40% |
| Resonance Harp | 共鸣竖琴 | `resonance_harp` | `EPIC` | `BATTLE_START` | `0.18` | 场上有玩家游吟诗人时，玩家全队攻击力 +18% |
| Star Crown | 星冠 | `star_crown` | `EPIC` | `AURA` | `0.25` | 光环：玩家 2 星及以上单位攻击力 +25%，防御 +18 |
| Crown of Three | 三星冠冕 | `crown_of_three` | `LEGENDARY` | `AURA` | `0.45` | 光环：玩家 3 星单位攻击力 +45%，魔力回复速度 +40% |
| Backline Scope | 后排瞄镜 | `backline_scope` | `COMMON` | `BATTLE_START` | `0.12` | 玩家后排单位攻击力 +12% |
| Frontline Plate | 前线护板 | `frontline_plate` | `COMMON` | `BATTLE_START` | `15.0` | 玩家前排单位防御 +15，护盾 +20 |
| Arcane Prism | 奥术棱镜 | `arcane_prism` | `FINE` | `AURA` | `0.15` | 光环：玩家全队技能强度 +15% |
| Mercy Censer | 慈悲香炉 | `mercy_censer` | `RARE` | `AURA` | `0.20` | 光环：玩家全队治疗强度 +20%，护盾强度 +20% |
| Armorbreaker Whetstone | 破甲砺石 | `piercing_whetstone` | `COMMON` | `AURA` | `8.0` | 光环：玩家全队防御穿透 +8 |
| Bloodglass Charm | 血玻璃护符 | `bloodglass_charm` | `FINE` | `AURA` | `0.08` | 光环：玩家全队吸血 +8% |
| Bulwark Rune | 壁垒符文 | `bulwark_rune` | `RARE` | `BATTLE_START` | `0.08` | 玩家前排单位本场伤害减免 +8%，状态抗性 +15% |
| Opening Tome | 开场秘典 | `opening_tome` | `FINE` | `BATTLE_START` | `20.0` | 玩家全队本场初始魔力 +20，并立刻恢复等量魔力 |
| Dynamo Needle | 充能针 | `dynamo_needle` | `RARE` | `AURA` | `4.0` | 光环：玩家全队普攻回魔 +4，受击回魔 +4 |
| Mirage Cloak | 幻影披风 | `mirage_cloak` | `RARE` | `BATTLE_START` | `0.10` | 玩家后排单位本场闪避 +10%，状态抗性 +10% |
| Old Coin Pouch | 旧钱袋 | `old_coin_pouch` | `COMMON` | `ON_ROUND_REWARD` | `1.0` | 每次战斗胜利后，额外获得 1 金币 |
| Spoils Ledger | 战利品账本 | `spoils_ledger` | `FINE` | `ON_ROUND_REWARD` | `2.0` | 每次战斗胜利后额外 +2 金币；Boss 战胜利额外 +4 金币 |
| Bounty Dagger | 赏金匕首 | `bounty_dagger` | `FINE` | `ON_KILL` | `3.0` | 玩家单位每击杀 3 个敌人获得 1 金币，每场战斗最多 3 金币 |
| Investment Ledger | 投资账本 | `investment_ledger` | `FINE` | `ON_ROUND_REWARD` | `10.0` | 战斗胜利时每持有 10 金币额外 +1，最多 3 金币 |
| Golden Armor Contract | 金甲契约 | `golden_armor_contract` | `FINE` | `AURA` | `2.0` | 光环：每 2 金币前排 +1 防御，最多 +25 防御 |
| Golden Charm | 黄金护符 | `golden_charm` | `RARE` | `AURA` | `0.01` | 光环：每 1 金币全队 +1% 攻击，最多 +20% |
| Goldhunter Contract | 猎金契约 | `goldhunter_contract` | `EPIC` | `ON_KILL` | `0.35` | 玩家单位击杀敌人时 35% 概率获得 1 金币，无上限 |
| Compound Core | 复利核心 | `compound_core` | `EPIC` | `ON_ROUND_REWARD` | `8.0` | 战斗胜利时每持有 8 金币额外 +1，不设上限 |
| Crown of Greed | 贪婪王冠 | `crown_of_greed` | `LEGENDARY` | `AURA` | `5.0` | 光环：每 5 金币全队 +3% 攻击/技能强度/治疗强度，不设上限 |

## 4. 触发类型说明

### AURA

用于常驻光环类遗物。单位在备战阶段生成、进入战斗或战斗中被召唤出来时，都会根据当前拥有的光环遗物获得对应运行时属性加成。

当前遗物：
- `battle_banner`
- `steel_formation`
- `sharp_edge`
- `broken_fang`
- `arcane_core`
- `mage_lens`
- `healing_bell`
- `star_crown`
- `crown_of_three`
- `arcane_prism`
- `mercy_censer`
- `piercing_whetstone`
- `bloodglass_charm`
- `dynamo_needle`
- `golden_armor_contract`
- `golden_charm`
- `crown_of_greed`

实现要点：
- 光环通过运行时 modifier 作用于当前单位，不永久修改原始 `UnitData`。
- 新生成的玩家单位会在生成后立刻应用当前光环；召唤物会在生成时标记 `is_summon`，避免吃已定义为开战型旧 Buff 的光环。
- 已接入光环的遗物不会再通过 `BATTLE_START` 入口重复叠加。
- 每个运行时单位会记录已应用的光环 `meta`，避免同一光环重复应用。
- 金币类光环通过 `RelicManager.get_live_gold()` 读取实时金币数，并通过动态 modifier 在金币变化、购买遗物、调整站位和单位生成后重新计算；无动态金币光环遗物时，金币变化不会触发全队属性刷新。

### BATTLE_START

用于战斗开始时的临时属性、护盾、初始魔力和条件增益。

实现要点：

- 只处理玩家运行时单位数组。
- 不直接修改 `.tres` 中的原始 `UnitData`。
- 对 `mana_regen_per_second`、攻击、暴击、暴击伤害、技能强度、治疗强度、护盾强度、防御穿透、吸血、伤害减免、初始魔力、攻受击回魔、状态抗性和闪避等运行时字段做临时调整。
- `First Spark` 和 `Soul Ember` 恢复魔力后，如果达到满魔力，应继续使用当前已有自动释放技能逻辑。

### ON_ATTACK

用于普通攻击命中后的追加效果。

当前遗物：

- `hunter_mark`
- `duelist_glove`

实现要点：

- 只对玩家攻击者生效。
- 追加伤害默认不暴击。
- 追加伤害走正常防御、护盾、HP、统计和击杀归属流程。

### ON_KILL

用于玩家单位击杀目标后的效果。

当前遗物：

- `blood_pendant`
- `soul_lantern`
- `executioner_sigil`
- `victory_drum`
- `vitality_trophy`

实现要点：

- 技能击杀只要走现有伤害归属流程，也能触发。
- 治疗量不超过 `max_hp`。
- 魔力恢复不超过 `max_mana`。
- 击杀者攻击力增益只修改本场运行时属性，战斗结束后随单位刷新重置。
- `Blood Oath Chalice` 会把永久最大生命值写回阵容项或当前英雄状态，召唤物击杀不触发。
- 全队类效果只作用于当前存活的玩家单位。

### ON_DEATH

用于玩家单位死亡时的效果。

当前遗物：

- `vengeance_spark`
- `last_stand`
- `soul_ember`
- `gravebone_charm`

实现要点：

- 只在战斗中触发。
- 死亡单位自身不获得 `Ember Bulwark` 护盾或 `Soul Ember` 魔力。
- `Ember Bulwark` 可以和 `Vengeance Spark` 同时触发。
- `Gravebone Charm` 只响应非召唤玩家单位死亡；召唤物死亡不会递归触发。

### ON_ROUND_REWARD

用于战斗胜利结算时的金币奖励效果。

当前遗物：
- `old_coin_pouch`
- `spoils_ledger`
- `investment_ledger`
- `compound_core`

实现要点：

- 只在玩家战斗胜利后触发。
- 在基础胜利金币计算完成后、最终金币写入前统一计算。
- 以进入胜利结算瞬间的 `EconomyManager.gold` 为基准（此时击杀金币遗物已经通过回调写入）。
- 第 30 波最终 Boss 跳过 `ON_ROUND_REWARD`，因为后续没有商店或备战阶段可使用金币。
- 多个 `ON_ROUND_REWARD` 遗物使用同一个 `pre_reward_gold` 计算，不互相递归。
- 返回 Dictionary：`{"extra_gold": int, "logs": PackedStringArray}`。

### ON_KILL（金币扩展）

击杀金币遗物通过现有 `ON_KILL` 入口触发，新增：

- `bounty_dagger`
- `goldhunter_contract`

实现要点：

- 击杀金币通过 `RelicManager._add_battle_gold()` 累积，内部通过 `gold_add_callback` 即时回调 `main.gd` 写入 `EconomyManager`。
- `Bounty Dagger` 每场战斗独立计数击杀数（3 次击杀 → 1 金币），每场最多 3 金币；新战斗开始后通过 `reset_battle_relic_state()` 清零。
- `Goldhunter Contract` 每次有效击杀独立进行 35% 概率判定，无上限。

### AURA（金币扩展）

金币转化属性遗物已接入 `AURA` 光环系统：

- `golden_armor_contract`
- `golden_charm`
- `crown_of_greed`

实现要点：

- 通过 `RelicManager.get_live_gold()` → `EconomyManager.get_gold()` 读取实时金币数。
- 在单位生成时（备战、战斗召唤）注册动态 modifier，并在金币变化、购买遗物和站位变化时刷新。
- 与现有 AURA 遗物同一入口（`apply_always_on_relics_to_unit`），但动态金币光环会先移除同来源 modifier 再按当前上下文重建。
- `main.gd` 会先通过 `RelicManager.has_dynamic_gold_relics()` 过滤无关金币变化；存在动态金币光环时，再 deferred 合并当前帧内的多次金币变化，统一刷新运行时单位。
- 单个单位刷新动态金币光环时，会批量移除和添加 modifier，并使用 `skip_recalculate` / `preserve_base_stats` 让中间步骤不反复重算，最后只重算一次。
- 金甲契约依赖前排判定，单位拖动到前排或离开前排后会刷新防御加成。

## 5. 奖励池规则

遗物奖励由 `RelicManager.get_available_relic_reward_options()` 提供给 `RewardManager`。

规则：

- 每个遗物资源在 `scripts/relic/relic_reward_pool.gd` 中 preload，并加入奖励池列表；展示和奖励池稳定顺序按 `catalog_id` 排序。
- 奖励池会跳过已经拥有的 `relic_id`。
- 奖励项包含 `id`、`name`、`description`、`rarity` 和 `relic_data`。
- 普通战胜利后有机会正常出现遗物奖励。
- 精英战胜利后，`RewardManager` 会提高遗物奖励出现概率。
- Boss 战胜利后直接通关，不进入奖励阶段。

## 6. UI 展示

### RelicBar

主界面遗物显示位于：

- `scenes/main.tscn`：`RelicBarPanel`
- `scripts/main.gd`：`_refresh_relic_bar()`

规则：

- 在主界面只占用一行。
- 默认最多显示前 5 个遗物。
- 超出数量显示 `+N` 按钮。
- 点击遗物按钮或 `+N` 打开遗物详情面板。
- Restart 后随着 `RelicManager.clear_relics()` 清空显示。

### RelicDetailPanel

详情面板位于：

- `scenes/main.tscn`：`RelicDetailPanel`
- `scripts/main.gd`：`_show_relic_detail_panel()`、`_rebuild_relic_detail_list()`、`_show_relic_detail_info()`

规则：

- 显示全部已拥有遗物。
- 每个遗物为可点击项。
- 点击后显示名称、稀有度、触发类型、数值和描述。
- 面板只用于查看，不修改、不删除遗物。
- 战斗阶段打开时不暂停战斗。

## 7. 新增遗物流程

1. 在本文档补充设计。
2. 新建 `res://data/relics/<relic_id>.tres`。
3. 使用 `res://scripts/relic_data.gd` 作为脚本。
4. 填写 `relic_id`、`catalog_id`、`relic_name`、`relic_name_cn`、`description`、`rarity`、`trigger_type`、`value`。
5. 在 `scripts/relic/relic_reward_pool.gd` 中添加 preload，并加入奖励池。
6. 在 `scripts/relic/relic_trigger_dispatcher.gd` 中根据 `trigger_type` 接入触发条件。
7. 在 `scripts/relic/relic_effect_resolver.gd` 中实现具体效果；常驻光环优先接入 `apply_always_on_relics_to_unit()`，战斗开始一次性效果接入 `apply_battle_start_relic()`。
8. 如新增触发类型，先在战斗或 UI 系统中增加统一事件入口，再由 `RelicManager` 对外转发。

## 8. 简单验证清单

### AURA

1. 获得任意 `AURA` 遗物。
2. 在备战阶段查看玩家单位详情，确认对应运行时属性已经提高。
3. 开始战斗后确认 `BATTLE_START` 入口不会让同一光环重复叠加。
4. 战斗中召唤友方召唤物，确认新生成单位不会吃开战型旧 Buff；若拥有动态金币光环，则按当前金币重新计算。

### BATTLE_START

1. 通过调试或奖励获得一个战斗开始类遗物。
2. 开始战斗，检查玩家运行时单位属性或护盾是否变化。
3. 战斗结束后回到准备阶段，确认原始单位数据没有永久增加。
4. 对 `First Spark` 额外确认满魔力单位能按现有技能逻辑自动释放技能。

### ON_ATTACK

1. 获得 `Hunter Mark` 或 `Duelist Glove`。
2. 使用对应职业单位攻击敌人。
3. 检查额外伤害是否出现，且不会暴击。
4. 确认额外伤害计入攻击者伤害统计和击杀归属。

### ON_KILL

1. 获得 `Blood Pendant`、`Soul Lantern`、`Executioner Sigil`、`Victory Drum` 或 `Blood Oath Chalice`。
2. 让玩家单位击杀敌人。
3. 检查击杀者恢复生命或魔力时不超过上限。
4. 检查 `Executioner Sigil` 的攻击力提升只影响本场战斗。
5. 检查 `Victory Drum` 只给存活玩家单位添加护盾。
6. 检查 `Blood Oath Chalice` 会把击杀者最大生命永久写回本局阵容，且召唤物击杀不触发。

### ON_DEATH

1. 获得 `Vengeance Spark`、`Ember Bulwark`、`Soul Ember` 或 `Gravebone Charm`。
2. 让玩家单位在战斗中死亡。
3. 检查对应死亡遗物触发。
4. 确认死亡单位自身不会获得死亡后护盾或魔力。
5. 对 `Gravebone Charm` 额外确认：非召唤单位死亡会在死亡位置召唤骷髅，召唤物死亡不会再次召唤。
