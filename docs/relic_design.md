# 遗物设计文档

本文档记录当前遗物系统的数据结构、奖励池规则、已实现遗物、UI 展示和验证方式。新增遗物时应先补充本文档，再同步资源文件和 `RelicManager` 逻辑。

## 1. 数据结构

遗物使用 Godot `Resource` 管理：

- 脚本：`res://scripts/relic_data.gd`
- 资源位置：`res://data/relics/<relic_id>.tres`

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `relic_id` | `String` | 遗物唯一 ID，用于去重和逻辑匹配 |
| `relic_name` | `String` | 英文名称 / 显示回退名称 |
| `relic_name_cn` | `String` | 中文显示名称；非空时 UI 优先显示该字段 |
| `description` | `String` | UI 和奖励详情显示描述 |
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

- `RelicManager.player_relics`

Restart 时调用：

- `RelicManager.clear_relics()`

触发入口：

| 入口 | 调用位置 | 用途 |
| --- | --- | --- |
| `trigger_battle_start_relics(player_units)` | `BattleManager.start_battle()` | 战斗开始类遗物 |
| `trigger_attack_relics(attacker, target)` | `BattleManager._on_unit_attack_landed()` | 普通攻击命中类遗物 |
| `trigger_kill_relics(attacker, target)` | `BattleManager._on_unit_killed_target()` | 击杀类遗物 |
| `trigger_death_relics(dead_unit, enemy_units, is_battle_active, player_units)` | `BattleManager._on_unit_died()` | 死亡类遗物 |

通用规则：

- 所有遗物默认只对玩家单位生效。
- 已拥有遗物不会重复进入奖励池。
- 去重依据为 `relic_id`。
- 战斗开始类遗物只修改本场战斗中的运行时单位，不永久修改原始 `UnitData`。
- 伤害类遗物需要明确是否暴击；除非特别说明，遗物额外伤害不暴击。
- 临时属性增益优先使用运行时属性加成方式，不引入复杂 Buff 系统。

## 3. 当前遗物池

当前可获得遗物共 33 个。

| 遗物 | 中文名 | `relic_id` | 稀有度 | 触发 | `value` | 效果摘要 |
| --- | --- | --- | --- | --- | --- | --- |
| Battle Banner | 战斗旌旗 | `battle_banner` | `COMMON` | `BATTLE_START` | `0.1` | 玩家全队本场攻击力 +10% |
| Iron Armor Badge | 铁甲徽章 | `iron_armor_badge` | `COMMON` | `BATTLE_START` | `30.0` | 玩家全队获得 30 护盾 |
| Blood Pendant | 鲜血吊坠 | `blood_pendant` | `RARE` | `ON_KILL` | `35.0` | 玩家单位击杀后恢复 35 HP |
| Soul Lantern | 收魂灯 | `soul_lantern` | `RARE` | `ON_KILL` | `25.0` | 玩家单位击杀后恢复 25 魔力 |
| Executioner Sigil | 处刑徽记 | `executioner_sigil` | `EPIC` | `ON_KILL` | `0.12` | 玩家单位击杀后，本场战斗攻击力提高 12% |
| Victory Drum | 凯歌战鼓 | `victory_drum` | `EPIC` | `ON_KILL` | `12.0` | 玩家单位击杀后，所有存活玩家单位获得 12 护盾 |
| Hunter Mark | 猎手印记 | `hunter_mark` | `RARE` | `ON_ATTACK` | `0.75` | 玩家弓手每 3 次普通攻击追加 75% 攻击力伤害 |
| Vengeance Spark | 复仇火花 | `vengeance_spark` | `RARE` | `ON_DEATH` | `50.0` | 玩家单位死亡时对最近敌人造成 50 遗物伤害 |
| Steel Formation | 钢铁阵列 | `steel_formation` | `COMMON` | `BATTLE_START` | `12.0` | 玩家全队本场防御 +12 |
| Sharp Edge | 锐刃 | `sharp_edge` | `COMMON` | `BATTLE_START` | `0.1` | 玩家全队本场暴击率 +10%，限制在 0 到 1 |
| Broken Fang | 断牙 | `broken_fang` | `RARE` | `BATTLE_START` | `0.55` | 玩家弓手和刺客本场暴击伤害 +55% |
| Arcane Core | 奥术核心 | `arcane_core` | `RARE` | `BATTLE_START` | `0.25` | 玩家全队本场魔力回复速度 +25% |
| First Spark | 初始火花 | `first_spark` | `RARE` | `BATTLE_START` | `50.0` | 玩家全队获得 50 初始魔力，不超过 `max_mana` |
| Guardian Oath | 守护誓约 | `guardian_oath` | `RARE` | `BATTLE_START` | `70.0` | 玩家防御最高单位获得 70 护盾和 +25 防御 |
| Last Stand | 背水一战 | `last_stand` | `EPIC` | `ON_DEATH` | `60.0` | 玩家单位死亡时，其他存活玩家单位获得 60 护盾 |
| Soul Ember | 灵魂余烬 | `soul_ember` | `EPIC` | `ON_DEATH` | `45.0` | 玩家单位死亡时，其他存活玩家单位恢复 45 魔力 |
| Gravebone Charm | 骸骨坠饰 | `gravebone_charm` | `RARE` | `ON_DEATH` | `3.0` | 友方非召唤单位死亡时召唤 1 个骷髅；最多同时维持 3 个骷髅，召唤物死亡不触发 |
| Duelist Glove | 决斗手套 | `duelist_glove` | `RARE` | `ON_ATTACK` | `0.35` | 玩家刺客攻击低于 50% HP 的目标时追加 35% 攻击力伤害 |
| Mage Lens | 法师透镜 | `mage_lens` | `RARE` | `BATTLE_START` | `0.35` | 玩家法师本场主动技能伤害 +35% |
| Healing Bell | 治愈铃 | `healing_bell` | `RARE` | `BATTLE_START` | `0.4` | 玩家牧师本场主动技能治疗 +40% |
| Resonance Harp | 共鸣竖琴 | `resonance_harp` | `EPIC` | `BATTLE_START` | `0.18` | 场上有玩家游吟诗人时，玩家全队攻击力 +18% |
| Star Crown | 星冠 | `star_crown` | `EPIC` | `BATTLE_START` | `0.25` | 玩家 2 星及以上单位攻击力 +25%，防御 +18 |
| Crown of Three | 三星冠冕 | `crown_of_three` | `LEGENDARY` | `BATTLE_START` | `0.45` | 玩家 3 星单位攻击力 +45%，魔力回复速度 +40% |
| Backline Scope | 后排瞄镜 | `backline_scope` | `COMMON` | `BATTLE_START` | `0.12` | 玩家后排单位攻击力 +12% |
| Frontline Plate | 前线护板 | `frontline_plate` | `COMMON` | `BATTLE_START` | `15.0` | 玩家前排单位防御 +15，护盾 +20 |
| Arcane Prism | 奥术棱镜 | `arcane_prism` | `FINE` | `BATTLE_START` | `0.15` | 玩家全队本场技能强度 +15% |
| Mercy Censer | 慈悲香炉 | `mercy_censer` | `RARE` | `BATTLE_START` | `0.20` | 玩家全队本场治疗强度 +20%，护盾强度 +20% |
| Piercing Whetstone | 防御穿透磨石 | `piercing_whetstone` | `COMMON` | `BATTLE_START` | `8.0` | 玩家全队本场防御穿透 +8 |
| Bloodglass Charm | 血玻璃护符 | `bloodglass_charm` | `FINE` | `BATTLE_START` | `0.08` | 玩家全队本场吸血 +8% |
| Bulwark Rune | 壁垒符文 | `bulwark_rune` | `RARE` | `BATTLE_START` | `0.08` | 玩家前排单位本场伤害减免 +8%，状态抗性 +15% |
| Opening Tome | 开场秘典 | `opening_tome` | `FINE` | `BATTLE_START` | `20.0` | 玩家全队本场初始魔力 +20，并立刻恢复等量魔力 |
| Dynamo Needle | 充能针 | `dynamo_needle` | `RARE` | `BATTLE_START` | `4.0` | 玩家全队本场普攻回魔 +4，受击回魔 +4 |
| Mirage Cloak | 幻影披风 | `mirage_cloak` | `RARE` | `BATTLE_START` | `0.10` | 玩家后排单位本场闪避 +10%，状态抗性 +10% |

## 4. 触发类型说明

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

实现要点：

- 技能击杀只要走现有伤害归属流程，也能触发。
- 治疗量不超过 `max_hp`。
- 魔力恢复不超过 `max_mana`。
- 击杀者攻击力增益只修改本场运行时属性，战斗结束后随单位刷新重置。
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
- 死亡单位自身不获得 `Last Stand` 护盾或 `Soul Ember` 魔力。
- `Last Stand` 可以和 `Vengeance Spark` 同时触发。
- `Gravebone Charm` 只响应非召唤玩家单位死亡；召唤物死亡不会递归触发。

## 5. 奖励池规则

遗物奖励由 `RelicManager.get_available_relic_reward_options()` 提供给 `RewardManager`。

规则：

- 每个遗物资源在 `scripts/relic/relic_reward_pool.gd` 中 preload，并加入奖励池列表。
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
4. 填写 `relic_id`、`relic_name`、`relic_name_cn`、`description`、`rarity`、`trigger_type`、`value`。
5. 在 `RelicManager` 中添加常量和 preload。
6. 在 `get_available_relic_reward_options()` 中加入奖励池。
7. 根据 `trigger_type` 在对应触发函数中接入效果。
8. 如新增触发类型，先在战斗或 UI 系统中增加统一事件入口。

## 8. 简单验证清单

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

1. 获得 `Blood Pendant`、`Soul Lantern`、`Executioner Sigil` 或 `Victory Drum`。
2. 让玩家单位击杀敌人。
3. 检查击杀者恢复生命或魔力时不超过上限。
4. 检查 `Executioner Sigil` 的攻击力提升只影响本场战斗。
5. 检查 `Victory Drum` 只给存活玩家单位添加护盾。

### ON_DEATH

1. 获得 `Vengeance Spark`、`Last Stand`、`Soul Ember` 或 `Gravebone Charm`。
2. 让玩家单位在战斗中死亡。
3. 检查对应死亡遗物触发。
4. 确认死亡单位自身不会获得死亡后护盾或魔力。
5. 对 `Gravebone Charm` 额外确认：非召唤单位死亡会在死亡位置召唤骷髅，召唤物死亡不会再次召唤。
