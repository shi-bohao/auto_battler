# UI 系统设计

更新时间：2026-06-02

本文档整合 UI 分层规则、主界面 HUD、单位详情、出售区域、战斗统计、商店与奖励选择等 UI 子系统。

---

## 1. UI 层级系统

实现入口：`res://scripts/ui/ui_layer.gd`

### 核心规则

1. 每个大类使用独立的 100 层级段。
2. 同一大类内部只用 `+10`、`+20` 等小偏移微调。
3. 新增 UI 不直接写裸 `z_index` 数字，优先在 `UILayer` 中增加语义常量。
4. 全屏阻塞类界面必须高于普通 HUD 和功能面板。
5. 临时浮动提示必须高于所有常规界面，但不应承载主要流程。

### 大层级

| 范围 | 常量 | 类型 | 示例 |
| --- | --- | --- | --- |
| -100 ~ -1 | `WORLD_BACKGROUND` / `WORLD_EFFECT` | 战场背景与战斗视觉效果 | 棋盘背景、AoE 视觉 |
| 0 ~ 99 | `HUD_BASE` | 常驻 HUD | 金币、轮次、结果文本、遗物栏、遭遇信息 |
| 100 ~ 199 | `HUD_FLOATING` | HUD 上的操作入口和轻量提示 | 菜单按钮、战斗速度按钮、羁绊摘要、镜像阵容按钮 |
| 200 ~ 299 | `WORKSPACE_PANEL` | 准备阶段工作面板 | 商店、阵容、统计面板 |
| 300 ~ 399 | `DETAIL_PANEL` | 局内详情面板 | 单位详情、遗物详情、羁绊详情、镜像阵容详情 |
| 400 ~ 499 | `FLOW_OVERLAY` | 当前流程阻塞面板 | 英雄选择、奖励三选一 |
| 500 ~ 599 | `APP_OVERLAY` | 主菜单与主菜单派生页面 | 主菜单、图鉴 |
| 600 ~ 699 | `SYSTEM_MODAL` | 系统级弹窗 | 局内菜单、通关/失败弹窗 |
| 900+ | `FLOATING_POPUP` | 浮动提示与 tooltip | 悬停详情、技能弹窗 |

### 当前语义常量

| 常量 | 层级 | 用途 |
| --- | --- | --- |
| `RELIC_BAR` | 0 | 主 HUD 遗物栏 |
| `ENCOUNTER_INFO` | 10 | 遭遇信息 |
| `SELL_ZONE` | 20 | 出售区 |
| `HUD_ACTION_BUTTON` | 100 | 开始、商店、阵容等操作按钮 |
| `MENU_BUTTON` | 110 | 右上角菜单按钮 |
| `BATTLE_SPEED_BUTTON` | 110 | 战斗速度按钮 |
| `BOND_PANEL` | 120 | 羁绊摘要 |
| `MIRROR_INFO_BUTTON` | 110 | 镜像阵容按钮 |
| `SHOP_PANEL` | 200 | 商店面板 |
| `BENCH_PANEL` | 210 | 阵容面板 |
| `STATS_PANEL` | 220 | 统计面板 |
| `UNIT_DETAIL` | 300 | 单位详情 |
| `RELIC_DETAIL` | 310 | 遗物详情 |
| `BOND_DETAIL` | 320 | 羁绊详情 |
| `MIRROR_INFO_PANEL` | 330 | 镜像阵容详情 |
| `HERO_SELECTION` | 400 | 英雄选择 |
| `REWARD_PANEL` | 410 | 战斗胜利奖励 |
| `HERO_SELECTION_POPUP` | 480 | 英雄选择弹窗（技能/强化详情） |
| `MAIN_MENU` | 500 | 主菜单 |
| `ENCYCLOPEDIA` | 520 | 图鉴 |
| `GAMEPLAY_MENU` | 600 | 局内菜单 |
| `GAME_END_DIALOG` | 610 | 结束弹窗 |
| `HOVER_DETAIL` | 900 | 悬停详情 |

### 设计取舍

主菜单是全屏入口，因此高于游戏内 HUD 和流程面板。图鉴从主菜单打开，所以图鉴高于主菜单。

英雄选择与奖励三选一属于流程阻塞界面，必须高于普通详情、商店和阵容面板，但不应高于主菜单或系统级弹窗。

局内菜单和结束弹窗属于系统级弹窗，应高于英雄选择、奖励、图鉴之外的所有常规 UI。若将来需要"确认删除/确认返回"这类更高优先级确认框，应放在 `SYSTEM_MODAL + 50` 或新增更高语义常量。

悬停详情和技能弹窗属于短生命周期浮层，使用 `FLOATING_POPUP` 段。

### 新增 UI 流程

1. 判断它属于哪一个大类。
2. 在 `res://scripts/ui/ui_layer.gd` 中新增语义常量。
3. 在创建节点或初始化控制器时设置 `z_index = UI_LAYER.<NAME>`。
4. 如果是子节点局部弹窗，使用父面板内的局部 `z_index`。
5. 用主菜单、英雄选择、奖励、图鉴、局内菜单至少各打开一次做遮挡检查。

---

## 2. 主界面 HUD

### 单位头顶信息

单位场景：`res://scenes/unit.tscn`
单位逻辑：`res://scripts/unit.gd`

- 单位上方只显示单位名称与星级。
- 名称字号已放大，便于战斗中识别。
- 信息显示位置整体向下移动。
- 生命值使用红色进度条，魔力值使用蓝色进度条，均有边框。
- 详细数值不堆在单位头顶，避免画面拥挤。

### 单位详细信息 UI

入口：右键点击单位。

展示内容：名称、被动/主动技能描述、基础属性（HP/护盾/攻击力/防御/攻击间隔/攻击范围/魔力/魔力回复/暴击率/暴击伤害）、简介、设定（职责/稀有度/星级/类型/索敌模式）、队伍/状态/阵容位置、移动速度、技能伤害倍率/治疗倍率、当前状态效果、运行状态（坐标/格子/当前目标/攻击冷却）、战斗统计快照。

设计原则：
- 头顶 UI 只保留快速识别信息。
- 复杂属性进入详情 UI。
- 详情 UI 优先展示技能与基础属性，其次简介、设定、状态效果、运行状态和统计。
- 技能展示使用中文效果描述。
- 详情 UI 只查看，不修改单位。
- 战斗中查看详情不暂停战斗。

### 遗物显示 UI

- `RelicBarPanel` 显示当前已有遗物，主界面只显示一行，默认最多 8 个槽位；超出时最后一个槽位显示 `+N`。
- `RelicDetailPanel` 显示全部已拥有遗物，点击后展示名称、稀有度、触发类型、数值和描述。

### 出售区域

出售交互为拖拽：准备阶段拖动上场单位或备战席单位到左下角出售区域即可出售，返还金币。

相关代码：`res://scripts/main.gd`、`res://scripts/roster_manager.gd`、`res://scenes/main.tscn`

主要函数：
| 函数 | 说明 |
| --- | --- |
| `_try_sell_unit_from_drop()` | 处理拖拽出售 |
| `_is_unit_in_sell_zone()` | 判断单位是否落入出售区域 |
| `_set_sell_zone_visible()` | 控制出售区域显示 |
| `sell_active_unit_by_id()` | 出售上场单位 |
| `sell_bench_unit_by_id()` | 出售备战席单位 |

### 英雄选择 UI

- 底部头像轮播使用英雄头像资源。
- 左右按钮位于头像选择框两侧，每次移动一个头像位置。
- 点击头像只刷新详情，点击确认后才选择英雄。
- 详情区使用英雄立绘/头像、基础属性、技能按钮和强化按钮展示。
- 英雄选择面板高于普通 HUD。

### 战斗统计

统计逻辑：`res://scripts/stats_manager.gd`

统计字段：`damage_dealt`、`damage_taken`、`kill_count`、`healing_done`、`shield_given`、`mana_restored`、`battle_duration`

展示内容：战斗总时长、最高伤害/承伤/击杀/治疗/护盾/魔力恢复、每个单位的详细统计、遗物伤害总量。

实现原则：
- 死亡单位保留统计快照。
- 治疗量按实际恢复量统计，不统计溢出。
- 护盾按添加量统计。
- 魔力恢复按实际恢复值统计。
- 技能、遗物、被动、近战普攻和远程弹道命中尽量纳入统计。

---

## 3. 商店 UI

商店用于准备阶段购买单位和遗物。

### 栏位结构

当前商店共 10 个商品栏位：

| 栏位 | 类型 | 刷新池 |
| --- | --- | --- |
| 1-5 | 已解锁单位 | `RosterManager.get_unlocked_unit_pool()` |
| 6-7 | 新单位解锁 | `RosterManager.get_locked_unit_pool()` |
| 8-10 | 遗物 | `RelicManager.get_available_relic_reward_options()` |

初始已解锁单位为战士、弓手和刺客。

### 显示文本

单位商品：
```
单位名  可选：可升至N星
分类 - 稀有度 - 价格
单位简介 / 被动技能 / 主动技能
```

遗物商品：
```
遗物名
遗物 - 稀有度 - 价格
遗物描述
```

### 交互状态

| 状态 | 按钮文本 | 说明 |
| --- | --- | --- |
| 可购买普通单位 | `购买` | 添加单位到阵容 |
| 可触发升星 | `升星` | 购买后会合成 2 星或 3 星 |
| 新单位解锁 | `解锁` | 购买后解锁并获得该单位 |
| 已售出 | `已售` | 当前刷新周期内不可再次购买 |
| 阵容已满 | `已满` | 单位数量达到上限 |
| 已拥有遗物 | `已拥有` | 遗物不会重复购买 |
| 空栏位 | `-` | 无可用商品 |

可升星单位会在商品名中显示 `【可升至2星】` 或 `【可升至3星】`，并使用更醒目的边框。

### 相关代码

| 文件 | 职责 |
| --- | --- |
| `res://scripts/shop_manager.gd` | 生成 10 格商品、区分已解锁单位/新单位/遗物、遗物去重、定价 |
| `res://scripts/roster_manager.gd` | 维护已解锁单位池、判断可升星目标 |
| `res://scripts/ui/shop_panel_controller.gd` | 商店面板 UI 刷新、按钮状态与交互 |
| `res://scripts/main.gd` | 购买流程、金币扣除、阵容/遗物写入、刷新调用、商店开关、遗物详情入口 |
| `res://scripts/battle_manager.gd` | 备战预览单位刷新；按 `roster_id` 复用节点 |
| `res://scripts/unit.gd` | `reset_prepare_preview()` 为被复用的备战预览单位清理运行时状态 |
| `res://scripts/combat/unit_stat_controller.gd` | `clear_runtime_state()` 清理复用节点的运行时属性 |
| `res://scripts/unit_text_formatter.gd` | 为单位商品简介提供被动和主动技能描述 |

### 性能说明

- 购买单位、出售单位、上下阵和合成后由 `main.gd` 调用 `_refresh_player_preview_from_roster()` 刷新棋盘预览。
- `BattleManager.refresh_player_and_bench_units()` 按 `roster_id` 查找可复用节点，跳过无变化节点的完整重配置。
- 遗物购买不刷新整队棋盘预览，只刷新对应光环和遗物 UI。

---

## 4. 奖励选择 UI

奖励选择 UI 用于在玩家战斗胜利后展示三选一奖励。

### 场景结构

```
UI CanvasLayer
└── RewardPanel Panel
    ├── RewardTitle Label
    ├── RewardButton1 Button
    ├── RewardButton2 Button
    ├── RewardButton3 Button
    └── HoverDetailPanel Panel
        └── HoverDetailText RichTextLabel
```

主要逻辑：
- `res://scripts/ui/reward_panel_controller.gd` — 面板展示、按钮交互、稀有度样式
- `res://scripts/reward_manager.gd` — 奖励生成（三选一抽取）
- `res://scripts/main.gd` — 流程调度

### 布局规则

- `RewardPanel` 使用居中锚点。
- 面板尺寸扩大，避免三项奖励挤在一起。
- 奖励按钮宽高固定，文字启用自动换行和裁剪。
- 完整描述保留在 `tooltip_text` 中。

### 奖励文字格式

```
奖励名称  [稀有度]

奖励描述

可选：可升星提示
```

### 稀有度颜色

| 中文 | 标准枚举 | 兼容输入 | 底色 |
| --- | --- | --- | --- |
| 普通 | `COMMON` | `NORMAL`, `普通` | 灰白 |
| 精良 | `FINE` | `UNCOMMON`, `精良` | 绿色 |
| 稀有 | `RARE` | `稀有` | 蓝色 |
| 史诗 | `EPIC` | `史诗` | 紫色 |
| 传说 | `LEGENDARY` | `传说` | 橙色 |
| 神话 | `MYTHIC` | `MYTHICAL`, `神话` | 金色 |

未识别稀有度回退为 `COMMON`。

### 奖励类型

| 类型 | 来源 | 稀有度 |
| --- | --- | --- |
| 属性奖励 | `RewardManager._build_stat_rewards()` | COMMON/FINE/RARE/EPIC/LEGENDARY，对应数值 5/10/15/20/25 |
| 单位奖励 | `RewardManager._build_unit_rewards()` | 读取单位 `rarity`，只展示本局可获取单位 |
| 遗物奖励 | `RelicManager.get_available_relic_reward_options()` | 读取遗物资源 `rarity` |

奖励稀有度抽取规则由 `RewardManager` 维护，受当前波次、遭遇类型和 `RunModifierManager.luck` 影响。UI 只负责展示已抽出的奖励项，不在面板层重新计算概率。

---

## 5. 死亡与刷新性能

- 死亡单位保留统计快照，保证离场单位数据可查。
- `UnitCombat._handle_death()` 在单个单位死亡时调用 `clear_status_effects(false, false)`，逐单位静默清理状态效果。
- `BattleManager` 对死亡、召唤和单位列表变化使用批量刷新请求。
- 只有仍有效的单位参与后续目标列表和状态更新。

---

## 6. 验证清单

1. 单位头顶应只显示名称、星级、生命条和魔力条。
2. 右键单位应打开详情 UI，优先看到技能描述和基础属性。
3. 拖动单位到左下角出售区域应出售并返还金币。
4. 战斗结束统计中应显示战斗时间和各项统计。
5. 英雄选择界面左右按钮应每次移动一格头像，确认前不进入游戏。
6. 英雄选择界面点击菜单按钮时，应能看到局内菜单。
7. 初始商店前 5 格只刷新已解锁单位，6-7 格刷新未解锁单位，8-10 格刷新遗物。
8. 购买第三个同名 1 星单位时，应显示升星提醒。
9. 遗物商品点击后应打开详情面板。
10. 战斗胜利后奖励面板应在画面中央，三个按钮全部在面板内。
11. 不同稀有度奖励应显示不同底色。
12. 连续购买单位不应出现随阵容规模增长的整队重建卡顿。
