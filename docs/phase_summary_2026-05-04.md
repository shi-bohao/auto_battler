# 阶段性总结 - 2026-05-04

> 历史记录：本文档是 2026-05-04 附近的阶段快照，部分内容已被英雄、召唤、羁绊、图鉴、镜像挑战和后续 UI 调整扩展。当前项目状态以 `docs/project_status.md` 为准，当前单位/遗物数值以 `docs/content_reference.md` 为准。

本文档记录当前 Godot 4.6 肉鸽自走棋 Demo 的阶段进展、已落地系统、主要文件状态和后续风险点。它用于替代早期 `project_status.md` 中已经滞后的项目状态描述，并同步截至 2026-05-06 的 30 波流程、主菜单、限时状态效果、4 个新玩家单位、10 格分类商店、单位解锁/升星提醒、中文 UI 和单位技能描述展示。

## 1. 当前阶段判断

项目已经从“单场自动战斗原型”推进到“可多轮推进、带局内经济和内容池的可玩原型”：

- 已有主菜单、准备阶段、战斗阶段、结算阶段、奖励阶段、下一轮准备、局内菜单、重新开始和结束返回主菜单流程。
- 已有 30 波局内流程，普通战、每 5 波精英战和每 10 波 Boss 战规则均已接入。
- 已有 7x15 棋盘、玩家布阵区、敌方生成区、15 格备战席、拖拽部署、拖拽出售、阵容升星和站位保存。
- 已有 10 格分类商店：前 5 格刷新已解锁单位，后 2 格用于解锁新单位，最后 3 格刷新遗物；支持金币购买、刷新、售罄状态、已拥有遗物禁购、稀有度定价、商品详情和可升星提醒。
- 已有 11 个玩家单位、12 个敌人单位、21 个遗物资源。
- 已有自动索敌、移动、普通攻击、防御、暴击、护盾、治疗、魔力、主动技能、被动技能、限时状态效果和战斗加时机制。
- 已有战后自动弹出的奖励三选一、遗物奖励池去重、精英战遗物奖励倾向、遗物持有显示和遗物详情查看。
- 已有单位中文详情文本，商店简介和单位详情均可展示被动技能、主动技能和基础属性。
- 已有战斗统计，包含伤害、承伤、击杀、治疗、护盾、魔力恢复、攻击次数、生存时间和战斗总时长。

当前最值得继续投入的方向不是大拆结构，而是持续做可玩性验证、数值曲线调试、UI 可读性打磨、技能一致性检查和自动化验收。

### 结构重构状态（2026-05-06 更新）

截至本次更新，`docs/refactor_plan_2026-05-06.md` 中规划的 6 个重构阶段已经完成：

- UI 展示逻辑已拆入 `scripts/ui/` 控制器，稀有度显示拆入 `scripts/formatters/rarity_formatter.gd`。
- 局内状态、波次推进和金币经济已拆入 `scripts/game/`。
- 单位目录、星级缩放、站位推荐和升星逻辑已拆入 `scripts/catalog/` 与 `scripts/roster/`。
- 敌人目录、波次规则、遭遇生成、敌人数值缩放和默认遭遇构建已拆入 `scripts/encounter/`。
- 状态效果工厂、被动解析器、主动技能施放器以及遗物库存/奖励池/触发分发/效果执行均已拆分完成。
- `scenes/main.tscn` 已改为轻量装配场景，菜单、商店、奖励、单位详情、遗物栏、遗物详情、阵容面板、出售区、遭遇信息和统计面板均已迁入 `scenes/ui/` 子场景。
- `main.gd` 当前仍作为主流程协调器存在，保留管理器初始化、signal 连接、准备阶段拖拽协调、HUD 刷新和整体状态切换。

## 2. 核心流程

### PREPARE

- 玩家初始拥有 Warrior（战士）、Archer（弓手）、Assassin（刺客）和 8 金币。
- 每轮准备阶段自动刷新商店，并展示当前遭遇信息。
- 玩家可从商店购买单位或遗物；单位进入上场阵容或备战席，遗物进入持有列表。
- 页面右下角显示 `开始战斗` 按钮，点击后进入战斗阶段并隐藏准备期操作。
- 顶部菜单按钮可打开局内菜单，菜单中提供返回主菜单、重开和继续。
- 玩家可拖拽上场单位调整棋盘站位。
- 玩家可在上场区和备战席之间拖拽调度单位。
- 玩家可把上场单位或备战席单位拖到左下角出售区域出售并返还金币。
- 主界面显示当前拥有遗物的单行 `RelicBar`。

### BATTLE

- 战斗开始时根据阵容数据生成玩家运行时单位、备战席预览单位和敌方运行时单位。
- 战斗开始后备战席隐藏，上场单位停止拖拽。
- 单位自动寻敌、移动、攻击、回复魔力并自动释放技能。
- 战斗开始类被动和遗物只修改本场运行时单位，不永久修改 `UnitData`。
- 通用 `StatusEffect` 系统会在战斗中更新持续时间、周期跳数、属性加成和属性还原。
- 敌方单位只从 `data/enemies/` 中的敌人资源生成。
- 战斗超过 100 秒会进入 Overtime：存活单位攻击力翻倍、攻击间隔减半，并承受逐秒递增伤害。
- 战斗中仍可查看遗物详情和单位详情面板，不暂停战斗。

### RESULT / REWARD

- 战斗结束后展示胜负、金币奖励和统计。
- 普通胜利金币为 `5 + floor(current_round / 2)`。
- 精英胜利在普通金币基础上额外 +8。
- 第 10 / 20 波 Boss 胜利在普通金币基础上额外 +12，第 30 波 Boss 胜利直接通关，不再发放金币。
- 非最终胜利会直接弹出居中的奖励三选一面板，不再需要额外点击奖励按钮。
- 奖励池包含团队属性、单位奖励和未拥有遗物奖励；精英战有 60% 概率优先抽遗物奖励。
- 单位奖励会在获得后可触发合成时显示可升星提醒。
- 奖励按钮支持长描述换行和裁剪，不再溢出主面板。
- 奖励按稀有度显示底色：普通、精良、稀有、史诗、传说、神话。
- 选择奖励后进入下一轮准备阶段。

### GAME_OVER / Restart

- 失败、平局或通关进入结束状态。
- 失败或通关弹出结束信息，点击确认后回到主菜单。
- Restart 会清理战场、统计、阵容、商店、奖励和遗物持有列表。
- RelicBar 与 RelicDetailPanel 会在 Restart 后同步清空或隐藏。

## 3. 内容规模

### 玩家单位

当前玩家单位资源位于 `data/` 根目录，共 11 个：

| 单位 | 中文名 | 资源 | 定位 | 稀有度 | 被动 | 主动技能 |
| --- | --- | --- | --- | --- | --- | --- |
| Warrior | 战士 | `data/units/warrior.tres` | tank | `COMMON` | `armor` | `guard_barrier` |
| Archer | 弓手 | `data/units/archer.tres` | damage | `COMMON` | `long_shot` | `piercing_arrow` |
| Assassin | 刺客 | `data/units/assassin.tres` | damage | `FINE` | `execute` | `shadow_strike` |
| Tank | 重装坦克 | `data/units/tank.tres` | tank | `COMMON` | `fortress` | `stone_guard` |
| Mage | 法师 | `data/units/mage.tres` | damage | `COMMON` | `arcane_focus` | `fireball` |
| Priest | 牧师 | `data/units/priest.tres` | support | `COMMON` | `benevolence` | `holy_light` |
| Bard | 吟游诗人 | `data/units/bard.tres` | support | `COMMON` | `battle_song` | `inspiring_song` |
| Forest Druid | 森林德鲁伊 | `data/units/forest_druid.tres` | support | `FINE` | `nature_touch` | `regrowth` |
| Plague Caster | 瘟疫术士 | `data/units/plague_caster.tres` | damage | `FINE` | `poison_blade` | `toxic_cloud` |
| Guardian Captain | 守护队长 | `data/units/guardian_captain.tres` | tank | `FINE` | `defensive_command` | `iron_order` |
| Wind Chanter | 风语者 | `data/units/wind_chanter.tres` | support | `FINE` | `wind_rhythm` | `haste_song` |

玩家单位已新增 `rarity` 属性和 `unit_name_cn` 中文名字段。`UnitData`、`Unit` 和 `UnitDataApplier` 都已接入稀有度字段，商店、阵容和战斗显示会优先使用中文名。

### 新增限时效果单位

| 单位 | 中文名 | 已落地效果 |
| --- | --- | --- |
| Forest Druid | 森林德鲁伊 | 每 3 次攻击给低血量友军施加 `nature_touch_hot`；主动 `regrowth` 给低血量友军施加 5 秒治疗跳数，3 星可影响 2 个目标。 |
| Plague Caster | 瘟疫术士 | 普攻命中施加 `poison_blade_dot`；主动 `toxic_cloud` 对当前目标施加 5/6 秒中毒跳数。 |
| Guardian Captain | 守护队长 | 战斗开始给前排友军施加本场防御加成；主动 `iron_order` 给全体友军施加 5/6 秒防御加成，3 星额外给护盾。 |
| Wind Chanter | 风语者 | 战斗开始给全体友军施加本场魔力回复倍率；主动 `haste_song` 给全体友军施加 5/6 秒攻击间隔倍率和魔力回复倍率。 |

### 敌人单位

当前敌人单位资源位于 `data/enemies/`，共 12 个：

| 类型 | 普通 | 精英 | Boss |
| --- | --- | --- | --- |
| 承伤 | Shield Guard（盾卫）, Stoneback Beast（石背巨兽） | Elite Iron Warden（精英铁壁守卫） | Earthbreaker Colossus（Boss：裂地巨像） |
| 输出 | Crossbow Raider（弩手掠袭者）, Flame Imp（烈焰小鬼） | Elite Shadow Reaper（精英影刃收割者） | Void Cannon（Boss：虚空炮台） |
| 辅助 | Dark Acolyte（黑暗侍僧）, War Drummer（战鼓手） | Elite Blood Oracle（精英血谕者） | Abyss Hierophant（Boss：深渊大祭司） |

敌人不进入玩家商店、玩家单位奖励池或玩家初始阵容，只由 `EncounterManager` 生成。

### 遗物

当前遗物资源位于 `data/` 根目录，共 21 个：

| 触发类型 | 遗物 |
| --- | --- |
| `BATTLE_START` | Battle Banner（战斗旌旗）, Iron Armor Badge（铁甲徽章）, Steel Formation（钢铁阵列）, Sharp Edge（锐刃）, Broken Fang（断牙）, Arcane Core（奥术核心）, First Spark（初始火花）, Guardian Oath（守护誓约）, Mage Lens（法师透镜）, Healing Bell（治愈铃）, Resonance Harp（共鸣竖琴）, Star Crown（星冠）, Crown of Three（三星冠冕）, Backline Scope（后排瞄镜）, Frontline Plate（前线护板） |
| `ON_ATTACK` | Hunter Mark（猎手印记）, Duelist Glove（决斗手套） |
| `ON_KILL` | Blood Pendant（鲜血吊坠） |
| `ON_DEATH` | Vengeance Spark（复仇火花）, Ember Bulwark（余烬壁垒）, Soul Ember（灵魂余烬） |

所有遗物默认只对玩家单位生效，并已新增 `relic_name_cn` 中文名字段。伤害类遗物已经明确是否暴击；当前额外遗物伤害默认不暴击，并尽量走正常防御、护盾、HP 和击杀归属流程。

## 4. 本轮主要新增和优化

### 4.1 通用限时状态效果

- 新增 `scripts/status_effect.gd`。
- 新增 `scripts/unit_effect_controller.gd`。
- `Unit` 持有 `effect_controller`，并提供 `apply_status_effect()`、`update_status_effects()`、`clear_status_effects()` 和 `get_status_effect_debug_lines()`。
- 支持 4 类效果：
  - `HEAL_OVER_TIME`
  - `DAMAGE_OVER_TIME`
  - `STAT_ADD`
  - `STAT_MULTIPLY`
- 支持 `duration`、`remaining_time`、`tick_interval`、`value`、`stat_name`。
- 同一 `effect_id` 重复施加时刷新旧效果，而不是无限新增重复实例。
- 属性类效果开始时修改运行时属性，结束或清理时按原效果类型还原。
- 支持的属性包含 `defense`、`attack_damage`、`attack_interval`、`mana_regen_per_second`、`move_speed`、`crit_chance`、`crit_damage_multiplier`、`active_skill_damage_multiplier`、`active_heal_multiplier`。
- 死亡、战斗停止、战斗重新开始都会清理状态效果。
- 单位详情面板会显示当前状态效果和剩余时间。

### 4.2 四个新玩家单位

- `Forest Druid`（森林德鲁伊）：治疗跳数型辅助。
- `Plague Caster`（瘟疫术士）：持续伤害型后排输出。
- `Guardian Captain`（守护队长）：前排防御指挥和全体限时防御增益。
- `Wind Chanter`（风语者）：全体攻速与魔力回复节奏辅助。
- 四个新单位已接入 `main.tscn`、`Main` 导出资源、`RosterManager`、`ShopManager`、`RewardManager`、站位推荐、升星成长和单位奖励池。

### 4.3 玩家单位稀有度

- `UnitData` 新增中文名字段 `unit_name_cn` 和 6 档稀有度枚举：`COMMON`、`FINE`、`RARE`、`EPIC`、`LEGENDARY`、`MYTHIC`。
- `Unit` 运行时也持有 `rarity`。
- `UnitDataApplier` 会从单位资源复制稀有度到运行时单位。
- 单位详情面板展示 `Rarity`。
- 商店和阵容出售基价使用稀有度公式。
- 当前玩家单位稀有度分布：
  - `COMMON`：Warrior（战士）, Archer（弓手）, Tank（重装坦克）, Mage（法师）, Priest（牧师）, Bard（吟游诗人）
  - `FINE`：Assassin（刺客）, Forest Druid（森林德鲁伊）, Plague Caster（瘟疫术士）, Guardian Captain（守护队长）, Wind Chanter（风语者）

### 4.4 商店内容更新

- 商店由 5 个已解锁单位格、2 个新单位解锁格和 3 个遗物格组成，共 10 格。
- 已解锁单位格只从当前已解锁单位池刷新；新单位解锁格只从未解锁单位池刷新。
- 通过商店、奖励或随机获得单位时，会同步解锁该单位，使其后续进入已解锁单位刷新池。
- 单位商品和单位奖励会在获得后可触发合成时显示可升星提醒；商店商品名会显示 `【可升至2星/3星】`，购买按钮会显示 `升星`。
- 遗物格从未拥有遗物奖励池中抽取，并避免同一轮商店内重复遗物。
- 已拥有遗物在 UI 上显示 `已拥有` 并禁购。
- 阵容满时单位购买按钮显示 `已满` 并禁用。
- 商店 UI 显示物品类型、名称、稀有度、金币价格和描述。
- 单位商品简介会追加被动技能与主动技能的中文描述。
- 遗物商品支持点击卡片打开遗物详情面板。
- 商店面板已扩展以容纳 10 个商品栏位和刷新按钮，避免底部越界。
- 刷新商店消耗 1 金币。
- 单位和遗物价格都按稀有度计算：`2 + rarity_index * 2`。

| 稀有度 | 价格 |
| --- | --- |
| `COMMON` | 2 |
| `FINE` | 4 |
| `RARE` | 6 |
| `EPIC` | 8 |
| `LEGENDARY` | 10 |
| `MYTHIC` | 12 |

### 4.5 遗物显示 UI

- 新增主界面 `RelicBarPanel`。
- 主界面只显示一行遗物，默认最多显示前 5 个。
- 遗物数量超出时显示 `+N` 按钮。
- 点击遗物或 `+N` 打开 `RelicDetailPanel`。
- 详情面板显示全部已拥有遗物，点击列表项后显示名称、稀有度、触发类型、数值和描述。

### 4.6 单位信息展示

- 单位上方只保留名称和星级。
- 名称字号增大。
- 单位头顶信息位置整体下移，减少遮挡。
- 新增红色生命条、蓝色魔力条，并加边框。
- 右键点击单位弹出详细信息 UI，优先展示技能与基础属性，再展示简介、设定、状态效果、运行状态和战斗统计快照。
- 单位详情中的被动和主动技能使用中文效果描述，不再只展示技能 ID。
- 商店单位简介与单位详情共用 `UnitTextFormatter` 的技能描述，降低不同 UI 之间的文本漂移。

### 4.7 出售与阵容交互

- 出售从按钮交互改为拖拽交互。
- 玩家在准备阶段拖动上场单位或备战席单位到左下角出售区域，即可出售。
- 出售价格为该单位购买基价乘以星级折算数量：1 星 x1、2 星 x3、3 星 x9。
- 准备阶段支持上场单位拖到备战席、备战席单位拖到棋盘部署。
- 出售、部署和移入备战席后会刷新战场、阵容、金币和 UI。

### 4.8 敌人单位与敌方生成

- 根据 `docs/enemy_design.md` 落地 12 个敌人资源。
- `EncounterManager` 的随机遭遇和固定遭遇都改为只生成 `enemy_*` 单位。
- 默认启用随机遭遇。
- 普通战只抽普通敌人。
- 精英战至少包含 1 个 `enemy_elite_*` 单位，并保证至少 1 个 2 星敌人。
- Boss 战至少包含 1 个 `enemy_boss_*` 单位。
- `BattleBoard` 为不同敌人类型补充推荐站位。
- `UnitSkill` 已接入敌人被动、主动技能、攻击命中被动和击杀被动。

### 4.9 奖励 UI 与奖励池

- `RewardPanel` 改为画面中央显示。
- 战斗胜利后直接弹出奖励面板，不再保留独立奖励按钮。
- 奖励按钮变宽变高，长描述自动换行并裁剪。
- 奖励文字改为包含稀有度显示。
- 奖励池包含 11 个玩家单位的指定单位奖励。
- 指定单位奖励带有 `unit_id`，UI 可根据当前阵容判断获得后是否触发升星提醒。
- 新增单位奖励使用 `FINE` 稀有度。
- 不同稀有度使用不同底色：
  - 普通 / `COMMON`：灰白
  - 精良 / `FINE`：绿色
  - 稀有 / `RARE`：蓝色
  - 史诗 / `EPIC`：紫色
  - 传说 / `LEGENDARY`：橙色
  - 神话 / `MYTHIC`：金色

### 4.10 战斗统计

- 统计战斗总时长。
- 统计治疗量 `healing_done`。
- 统计护盾量 `shield_given`。
- 统计魔力恢复总量 `mana_restored`。
- 统计攻击次数、击杀数和生存时间。
- 统计面板显示最高伤害、最高承伤、最高治疗、最高护盾、最高魔力恢复和最高击杀。
- 死亡单位会保留统计快照，避免结算时数据丢失。

### 4.11 战斗加时

- `BattleManager` 新增 Overtime。
- 战斗持续 100 秒后触发。
- 触发时所有存活单位攻击力 x2，攻击间隔 x0.5。
- 加时后每秒对所有存活单位造成递增伤害，第一秒 10，第二秒 20，之后继续递增。
- `Main` 会在 UI 上显示 `Overtime`。

## 5. 主要文件状态

| 文件 | 当前职责 |
| --- | --- |
| `scripts/main.gd` | 主状态机、主菜单/结束弹窗、准备期开始按钮、局内菜单、UI 刷新、商店、奖励、遗物栏、单位详情、出售区域、金币和轮次流程 |
| `scripts/battle_manager.gd` | 战斗生成、开始、结束、单位事件转发、备战席预览、100 秒加时 |
| `scripts/encounter_manager.gd` | 敌方遭遇生成、敌人池、随机遭遇、普通/精英/Boss 规则 |
| `scripts/battle_board.gd` | 7x15 棋盘、玩家/敌方区域、15 格备战席、站位推荐与拖拽落点 |
| `scripts/roster_manager.gd` | 玩家阵容、备战席、升星、出售、站位保存、已解锁单位池、可升星提示判断、单位稀有度价格、11 个玩家单位池 |
| `scripts/shop_manager.gd` | 5 已解锁单位格 + 2 新单位解锁格 + 3 遗物格商店、稀有度定价、遗物去重、售罄状态 |
| `scripts/reward_manager.gd` | 奖励池、奖励应用、11 个单位奖励、精英战遗物倾向 |
| `scripts/relic_manager.gd` | 遗物持有、去重、奖励池、商店遗物来源、触发效果 |
| `scripts/stats_manager.gd` | 战斗统计、死亡快照、MVP 文本、单位统计文本 |
| `scripts/unit.gd` | 单位运行时状态、攻击、魔力、拖拽、详情请求、状态效果入口 |
| `scripts/unit_combat.gd` | 伤害、护盾、治疗、防御、暴击和统计记录 |
| `scripts/unit_skill.gd` | 玩家和敌人的主动技能、被动技能、限时状态效果施加 |
| `scripts/unit_text_formatter.gd` | 单位简介、被动技能和主动技能的中文展示文本 |
| `scripts/status_effect.gd` | 单个限时状态效果的持续、跳数、属性修改和还原 |
| `scripts/unit_effect_controller.gd` | 单位身上的状态效果列表、刷新、更新和清理 |
| `scripts/unit_data.gd` | 单位资源结构，包含稀有度、战斗属性、被动和主动技能 |
| `scripts/unit_data_applier.gd` | 从 `UnitData` 复制运行时属性，包含稀有度 |
| `scenes/main.tscn` | 主 UI、开始战斗按钮、菜单按钮、10 格分类商店、奖励面板、单位详情、遗物栏、遗物详情、出售区域、11 个玩家单位资源引用 |
| `scenes/unit.tscn` | 单位节点、名称星级、生命条、魔力条 |

## 6. 设定文档同步状态

本次扫描后的状态：

- `docs/phase_summary_2026-05-04.md` 已更新为当前项目总览。
- `docs/relic_design.md` 已基本匹配当前 21 个遗物、6 档稀有度、RelicBar/RelicDetailPanel 和验证清单。
- `docs/enemy_design.md` 已说明 12 个敌人已全部接入、生成规则已切换为敌人池。
- `docs/reward_ui_design.md` 已记录奖励 UI 与稀有度颜色规范、单位奖励升星提醒。
- `docs/shop_ui_design.md` 已记录 10 格分类商店、单位解锁池、升星提醒、遗物详情和验证清单。
- `docs/ui_and_stats_design.md` 已同步单位详情顺序、技能中文描述和当前主 UI 交互。
- `docs/demo_spec.md` 已从早期单场战斗 Demo 说明更新为当前可玩原型范围。
- `docs/refactor_plan_2026-05-06.md` 已记录当前结构体检结果、已完成系统范围和后续分阶段重构计划。

仍可后续整理：

- `docs/project_status.md` 是早期状态文档，部分内容已被本文档取代。
- `docs/unit_design.md` 和 `docs/unit_design_with_new_units.md` 有重叠，可后续合并为一份玩家单位设定总表。
- `docs/unit_skill_design.md` 中“未来扩展魔力奖励/遗物”和 Buff 管理器相关描述已经被当前实现推进，可在下一轮集中更新。
- `docs/project_status.md` 仍保留早期结构说明，后续可选择压缩为历史记录或指向本文档。

## 7. 风险与待验证

- 当前环境没有可用的 `git` 命令，无法通过 Git 状态辅助区分历史改动和未提交改动。
- 当前环境没有可用的 `godot` 命令行，本文档更新未运行 Godot 工程级验证。
- 通用 `StatusEffect` 已接入，但 Tank 的 `stone_guard` 临时防御和 Bard 的 `inspiring_song` 临时攻击/魔力部分仍未在代码中接入；当前限时效果主要服务四个新单位。
- 属性类状态效果通过直接修改运行时属性并在结束时反向还原，后续需要实机验证多效果叠加、刷新和与遗物增益混用时的顺序稳定性。
- 商店和奖励池现在已经同时提供单位与遗物，但稀有度目前主要影响显示和价格，还没有完整抽取权重体系。
- 敌人、遗物、奖励和商店都有随机性，后续需要加入可复现种子或调试日志，方便数值验证。
- 加时机制对长战斗有强干预，Boss、精英怪和高回复阵容需要实机观察强度。
- RelicBar 当前采用固定最多 5 个主界面显示，后续可改为按容器宽度动态计算。
- 战斗统计已覆盖治疗、护盾和魔力恢复，但如后续加入伤害来源细分，需要扩展统计字段。

## 8. 建议下一步

1. 做一轮手工验收：购买单位、购买遗物、刷新、拖拽部署、拖到备战席、拖拽出售、战斗、奖励、遗物详情、单位详情、Restart。
2. 专门验收 10 格商店：前 5 格已解锁单位、后 2 格新单位、后 3 格遗物、可升星提醒、遗物详情和底部边框。
3. 用固定阵容分别测试普通、精英和 Boss 战，记录敌人强度曲线。
4. 专门验证四个新单位的限时效果：持续时间、刷新逻辑、跳数、属性还原和单位详情显示。
5. 为商店和奖励池加入稀有度权重、轮次权重和调试日志。
6. 对齐 `stone_guard`、`inspiring_song` 的设计文档与当前代码，决定是接入限时效果还是修订技能描述。
7. 合并玩家单位设定文档，减少多份设计文档之间的漂移。
