# 重构计划与当前结构记录

更新时间：2026-05-06

本文档记录当前项目结构体检结果、已经完成的系统范围，以及后续建议的分阶段重构计划。目标是在不改变现有玩法行为的前提下，逐步降低 `main.gd` 和几个大型管理类的职责密度，让后续继续扩展单位、遗物、商店、奖励和波次内容时更稳定。

## 1. 当前已完成系统

当前 Demo 已经从早期单场自动战斗扩展为可玩的肉鸽自走棋原型，主要完成内容包括：

- 主菜单流程：启动后进入主菜单，点击开始游戏进入局内。
- 游戏结束流程：失败或第 30 波通关后弹出结果信息，确认后返回主菜单。
- 局内状态流转：准备阶段、战斗阶段、奖励阶段、下一波准备和游戏结束。
- 30 波遭遇：每 5 波精英，每 10 波 Boss，第 30 波 Boss 胜利后通关。
- 准备阶段操作：右下角开始战斗按钮、菜单按钮、商店按钮、出售区域。
- 棋盘与备战席：支持拖拽部署、拖入备战席、出售单位，并在界面缩放后重映射单位位置。
- 10 格分类商店：前 5 格刷新已解锁单位，第 6-7 格刷新新单位解锁，第 8-10 格刷新遗物。
- 单位解锁：购买、奖励或随机获得单位时同步解锁该单位。
- 升星提醒：商店与单位奖励可以显示可升至 2 星或 3 星的提示。
- 奖励系统：战斗胜利后自动弹出奖励三选一。
- 遗物系统：支持遗物奖励、商店遗物、遗物栏和遗物详情。
- 中文文本：单位、遗物、商店、奖励、菜单、重开和单位详情等界面已支持中文显示。
- 单位详情：优先展示被动/主动技能中文描述和基础属性，再展示简介、设定、状态效果、运行状态和战斗统计。
- 战斗统计：记录并展示伤害、承伤、治疗、护盾、魔力恢复、击杀和攻击次数等信息。

## 2. 结构体检结果

脚本/场景体量较大的文件如下（阶段 6 完成后重新统计）：

| 文件 | 约行数 | 当前主要职责 |
| --- | ---: | --- |
| `scripts/main.gd` | 1054 | 游戏流程协调、准备阶段拖拽、UI 控制器装配和局内状态刷新 |
| `scripts/combat/active_skill_caster.gd` | 486 | 主动技能分发、玩家/敌人主动技能实现、主动技能目标选择和主动技能数值常量 |
| `scripts/roster_manager.gd` | 388 | active/bench 阵容、出售、单位解锁、战斗配置组装，并委托单位目录、缩放、站位和升星服务 |
| `scripts/battle_manager.gd` | 386 | 战斗启动、战斗循环、单位死亡/攻击事件、胜负判定和遗物触发入口 |
| `scripts/relic/relic_effect_resolver.gd` | 334 | 具体遗物战斗效果、单位筛选、数值应用和遗物伤害统计回写 |
| `scripts/combat/passive_resolver.gd` | 306 | 玩家/敌人被动分发、被动数值修正、攻击命中/击杀被动和主动技能倍率修正 |
| `scripts/shop_manager.gd` | 300 | 10 格商店刷新、已解锁/新单位/遗物栏位规则和商店商品状态 |
| `scripts/reward_manager.gd` | 246 | 战斗奖励池、奖励抽取、奖励应用和遗物奖励接入 |
| `scripts/encounter_manager.gd` | 142 | 遭遇缓存、对外查询、debug 文本和敌方战斗配置组装 |
| `scripts/relic_manager.gd` | 115 | 遗物元数据读取、库存/奖励池委托和战斗触发入口转发 |
| `scenes/main.tscn` | 101 | 主场景根节点、棋盘、HUD 基础按钮/标签和 UI 子场景实例装配 |
| `scripts/unit_skill.gd` | 44 | 单位技能总入口、回蓝更新、主动技能委托和被动入口转发 |
| `scripts/combat/status_effect_factory.gd` | 54 | 状态效果类型常量、效果字典创建和目标应用保护 |

主要问题：

- `main.gd` 仍是总流程协调入口，继续承载准备阶段拖拽和若干 HUD 状态刷新；后续如果继续降复杂度，可优先拆准备阶段交互协调器。
- `battle_manager.gd` 与 `roster_manager.gd` 已明显瘦身，但仍是战斗/阵容的领域入口，后续更适合按功能增量继续小步拆分。
- 技能、遗物、遭遇和经济已经完成计划内拆分，新增内容时应优先放入对应 `combat/`、`relic/`、`encounter/`、`catalog/` 服务，而不是回填到总入口文件。
- `main.tscn` 已经从大块静态 UI 节点改为轻量子场景装配，但 HUD 基础标签、按钮、棋盘和子场景实例仍由主场景承载。

## 3. 目标结构

建议逐步整理为以下目录和职责边界：

```text
scripts/
  game/          # 游戏状态、波次推进、胜负结算、金币经济
  ui/            # 主菜单、商店、奖励、遗物、单位详情等界面控制器
  roster/        # 阵容、备战席、出售、升星
  catalog/       # 单位、遗物、敌人资源查询；稀有度、价格、名称等基础数据
  encounter/     # 波次规则、遭遇生成、敌人缩放
  combat/        # 战斗、单位、技能、状态效果
  relic/         # 遗物库存、奖励池、触发分发、遗物效果
  formatters/    # 中文文本、详情文本、稀有度显示、通用格式化
  utils/         # 颜色、资源属性读取、通用小工具
```

最终希望 `main.gd` 只保留以下职责：

- 创建和注入核心服务。
- 连接主要 signal。
- 按当前游戏状态协调各控制器。
- 将少量全局事件转发给对应模块。

## 4. 分阶段重构计划

### 阶段 1：抽离 UI 控制器

优先级：最高  
风险：低到中  
目标：在不改变玩法逻辑的前提下，先让 `main.gd` 减少 700-1000 行。

建议新增：

- `scripts/ui/shop_panel_controller.gd`
- `scripts/ui/reward_panel_controller.gd`
- `scripts/ui/relic_panel_controller.gd`
- `scripts/ui/unit_detail_panel_controller.gd`
- `scripts/ui/menu_panel_controller.gd`
- `scripts/formatters/rarity_formatter.gd`
- `scripts/formatters/ui_text_formatter.gd`

拆分内容：

- 商店按钮绑定、商品卡片文字、背景颜色、购买按钮状态和遗物详情入口。
- 奖励按钮文字、tooltip、稀有度颜色和升星提示展示。
- 遗物栏、遗物详情列表和商店遗物详情。
- 单位详情文本构建。
- 主菜单、局内菜单和游戏结束弹窗的创建与显示。
- 稀有度中文名、稀有度颜色、文本颜色、颜色加深/变浅等通用函数。

验收标准：

- 主菜单开始游戏正常。
- 准备阶段按钮、菜单、商店和出售区正常。
- 商店 10 个栏位分类、刷新、购买、升星提示和遗物详情正常。
- 战斗胜利后奖励自动弹出，奖励选择正常。
- 单位详情和遗物详情显示内容不变。
- 重开、返回主菜单、通关/失败确认流程正常。

### 阶段 2：抽离游戏流程与经济

优先级：高  
风险：中  
目标：让状态切换、波次推进和金币规则从 `main.gd` 中独立。

建议新增：

- `scripts/game/run_controller.gd`
- `scripts/game/economy_manager.gd`
- `scripts/game/game_state.gd`

拆分内容：

- `MAIN_MENU / PREPARE / BATTLE / REWARD / GAME_OVER` 状态切换。
- 当前波次、最大波次、通关判断。
- 胜利金币、精英奖励、Boss 奖励、刷新消耗、购买消耗和出售返还。
- 战斗结果到奖励或结束界面的跳转规则。

验收标准：

- 当前 30 波流程行为不变。
- 第 10、20 波 Boss 胜利后继续游戏，第 30 波 Boss 胜利后通关。
- 失败后进入失败弹窗。
- 金币增减与现有版本一致。

### 阶段 3：拆分阵容、单位池与升星

优先级：高  
风险：中到高  
目标：降低 `roster_manager.gd` 的职责密度，统一单位数据读取和升星规则。

建议新增：

- `scripts/catalog/unit_catalog.gd`
- `scripts/roster/roster_manager.gd`
- `scripts/roster/merge_service.gd`
- `scripts/roster/unit_scaling_service.gd`
- `scripts/roster/roster_position_service.gd`

拆分内容：

- 单位资源池、单位 ID、中文名、稀有度、价格读取放入 `UnitCatalog`。
- active/bench 阵容移动、出售和数量限制保留在 `RosterManager`。
- 升星候选、升星提示、合成执行放入 `MergeService`。
- 星级成长和战斗用 `UnitData` 复制放入 `UnitScalingService`。
- 推荐站位、保存格子和备战席位置放入 `RosterPositionService`。

验收标准：

- 购买、奖励和随机获得单位都能正确解锁。
- 三合一升星行为不变。
- 商店和奖励升星提示不变。
- 部署、拖入备战席、出售和保存站位不变。

### 阶段 4：拆分遭遇生成

优先级：中  
风险：中  
目标：让波次规则、敌人资源表、随机模板和数值缩放可独立维护。

建议新增：

- `scripts/catalog/enemy_catalog.gd`
- `scripts/encounter/wave_rule.gd`
- `scripts/encounter/encounter_generator.gd`
- `scripts/encounter/enemy_scaling_service.gd`
- `scripts/encounter/enemy_position_service.gd`

拆分内容：

- 敌人资源、敌人角色、Boss/精英分类放入 `EnemyCatalog`。
- 每 5 波精英、每 10 波 Boss、30 波上限放入 `WaveRule`。
- 随机遭遇模板和敌人组成放入 `EncounterGenerator`。
- 星级概率和敌人数值倍率放入 `EnemyScalingService`。
- 敌方站位推荐放入 `EnemyPositionService`。

验收标准：

- 30 波类型分布不变。
- 普通、精英、Boss 强度递增趋势不变。
- 敌人站位和显示名称不变。
- 遭遇调试文本仍能正确输出。

### 阶段 5：拆分技能与遗物效果

优先级：中  
风险：高  
目标：把堆叠式效果逻辑拆成更容易新增内容的结构。

建议新增：

- `scripts/combat/passive_resolver.gd`
- `scripts/combat/active_skill_caster.gd`
- `scripts/combat/status_effect_factory.gd`
- `scripts/relic/relic_inventory.gd`
- `scripts/relic/relic_reward_pool.gd`
- `scripts/relic/relic_trigger_dispatcher.gd`
- `scripts/relic/relic_effect_resolver.gd`

拆分内容：

- 玩家和敌人的被动效果分发。
- 主动技能释放和目标选择。
- 状态效果数据创建。
- 遗物持有列表和去重。
- 遗物奖励池。
- 战斗开始、攻击命中、击杀、死亡等触发分发。
- 具体遗物效果实现。

验收标准：

- 所有现有玩家单位技能表现不变。
- 所有现有敌人技能表现不变。
- 所有遗物触发条件和数值不变。
- 状态效果持续、tick 和属性修正不变。

### 阶段 6：拆分场景文件

优先级：中到低  
风险：中  
目标：让 `main.tscn` 不再承载所有 UI 节点，便于单独维护界面。

建议新增：

- `scenes/ui/main_menu_panel.tscn`
- `scenes/ui/gameplay_menu_panel.tscn`
- `scenes/ui/game_end_panel.tscn`
- `scenes/ui/shop_panel.tscn`
- `scenes/ui/reward_panel.tscn`
- `scenes/ui/relic_bar_panel.tscn`
- `scenes/ui/relic_detail_panel.tscn`
- `scenes/ui/unit_detail_panel.tscn`
- `scenes/ui/bench_panel.tscn`
- `scenes/ui/sell_zone_panel.tscn`
- `scenes/ui/encounter_info_panel.tscn`
- `scenes/ui/stats_panel.tscn`

拆分顺序：

1. 先拆主菜单、局内菜单和游戏结束弹窗。
2. 再拆奖励面板和单位详情。
3. 最后拆商店、遗物面板和 HUD 支撑面板。

验收标准：

- `main.tscn` 节点更轻，但所有 UI 显示和交互保持一致。
- 控制器通过导出 NodePath 或初始化参数绑定节点，不依赖长路径硬编码。
- 不引入新的布局溢出或缩放错位问题。

## 5. 当前重构结论

截至 2026-05-06，本计划中的 6 个阶段均已完成。当前结构已经完成 UI 控制器抽离、流程/经济抽离、阵容/目录/升星服务抽离、遭遇生成抽离、技能与遗物效果抽离，以及主场景 UI 子场景拆分。

后续如果继续做结构优化，建议按实际新增功能小步推进，而不是继续大范围搬迁。优先级较高的后续方向：

1. 从 `main.gd` 中继续抽出准备阶段拖拽/部署/出售协调器。
2. 为关键流程补充可重复的自动化验收脚本，覆盖开始游戏、购买、部署、开战、胜利奖励、失败/通关回主菜单。
3. 在继续新增单位/遗物时，优先使用现有 `catalog/`、`combat/`、`relic/` 和 `encounter/` 服务，避免新的效果逻辑回流到入口文件。
4. 如果 UI 继续增长，再考虑给拆出的 `.tscn` 面板绑定轻量场景脚本或导出 NodePath，减少 `main.gd` 中的长路径绑定。

本轮重构完成后仍建议保留本清单作为回归基准。

## 6. 回归检查清单

每个阶段完成后至少检查：

- 打开游戏进入主菜单，开始游戏正常。
- 准备阶段显示开始战斗、菜单和商店。
- 商店 10 格分类正确，商品未超出底部边框。
- 商店购买单位、解锁单位、购买遗物、刷新商店正常。
- 商店和奖励可以显示升星提醒。
- 拖拽单位部署、拖入备战席、出售单位正常。
- 界面缩放后单位仍对齐棋盘方格。
- 点击开始战斗后进入战斗，准备阶段 UI 隐藏。
- 战斗胜利后奖励自动弹出。
- 失败和通关后弹窗确认返回主菜单。
- 单位详情显示技能、基础属性、简介和运行状态。
- 遗物栏和遗物详情显示正常。

## 7. 执行进度

### 2026-05-06 阶段 1 / 步骤 1：稀有度格式化抽离

状态：已完成。

变更：

- 新增 `scripts/formatters/rarity_formatter.gd`。
- 将稀有度标准化、中文显示名、稀有度颜色、文本颜色、颜色加深和颜色变浅逻辑集中到 `RarityFormatter`。
- `main.gd` 暂时保留原 `_get_reward_rarity_display_name()`、`_get_reward_rarity_color()`、`_normalize_reward_rarity()`、`_get_reward_text_color()`、`_lighten_color()`、`_darken_color()` 包装函数，以降低第一步对商店、奖励和菜单样式调用点的影响。

验证：

- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\godot_check.log --path . --quit` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\script_check.log --check-only --script res://scripts/main.gd --path .` 通过。

备注：

- 当前命令需要显式传入 `--log-file`，否则 Godot 在默认 `user://logs` 写入日志时会崩溃。
- 当前目录未检测到 `.git`，因此无法使用 `git status` 记录差异。

### 2026-05-06 阶段 1 / 步骤 2：单位详情控制器抽离

状态：已完成。

变更：

- 新增 `scripts/ui/unit_detail_panel_controller.gd`。
- 将单位详情面板显示、关闭、刷新、面板位置限制和详情文本构建逻辑从 `main.gd` 移入 `UnitDetailPanelController`。
- 单位详情仍保持原展示顺序：技能、基础属性、简介、设定、状态效果、运行状态、战斗统计。
- `main.gd` 只保留 `_show_unit_detail_panel()`、`_hide_unit_detail_panel()`、`_refresh_unit_detail_panel_if_open()` 这三个薄包装，用于接收原有事件并转发给控制器。
- `main.gd` 体量从约 2500 行下降到约 1758 行。

验证：

- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_detail_controller_check.log --check-only --script res://scripts/ui/unit_detail_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_unit_detail.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_unit_detail.log --path . --quit` 通过。

备注：

- 项目启动检查仍会输出 `Failed to read the root certificate store`，这是当前 Windows/Godot 环境警告，本次重构未涉及网络或证书能力。

### 2026-05-06 阶段 1 / 步骤 3：遗物面板控制器抽离

状态：已完成。

变更：

- 新增 `scripts/ui/relic_panel_controller.gd`。
- 将遗物栏刷新、遗物按钮创建、更多遗物入口、已拥有遗物详情、商店遗物详情、遗物详情文本构建和容器清理逻辑从 `main.gd` 移入 `RelicPanelController`。
- `RelicPanelController` 持有商店遗物详情状态，`main.gd` 在关闭商店或刷新商店时只查询控制器并关闭对应详情面板。
- `main.gd` 只保留 `_refresh_relic_bar()`、`_show_relic_detail_panel()`、`_hide_relic_detail_panel()`、`_show_shop_relic_detail_panel()` 等薄包装，以保持现有调用点稳定。
- `main.gd` 体量从约 1758 行下降到约 1629 行。

验证：

- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_controller_check.log --check-only --script res://scripts/ui/relic_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_relic.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_relic.log --path . --quit` 通过。

备注：

- 遗物详情内的稀有度中文显示复用 `RarityFormatter`。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 1 / 步骤 4：奖励面板控制器抽离

状态：已完成。

变更：

- 新增 `scripts/ui/reward_panel_controller.gd`。
- 将奖励选项缓存、奖励按钮绑定、奖励按钮文本、tooltip、稀有度样式、单位升星提示和奖励应用逻辑从 `main.gd` 移入 `RewardPanelController`。
- `RewardPanelController` 应用奖励后通过 `reward_applied` signal 通知 `main.gd`，由 `main.gd` 继续负责刷新遗物栏并进入下一波准备。
- `main.gd` 移除 `reward_options` 状态，只保留 `_show_reward_panel()`、`_hide_reward_panel()` 和 `_on_reward_applied()` 作为流程协调入口。
- `main.gd` 体量从约 1629 行下降到约 1537 行。

验证：

- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\reward_controller_check.log --check-only --script res://scripts/ui/reward_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_reward.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_reward.log --path . --quit` 通过。

备注：

- 奖励按钮的稀有度中文显示、颜色和文字颜色复用 `RarityFormatter`。
- 奖励选择后的阶段切换仍留在 `main.gd`，避免 UI 控制器直接掌握局内状态机。

### 2026-05-06 阶段 1 / 步骤 5：商店面板控制器抽离

状态：已完成。

变更：

- 新增 `scripts/ui/shop_panel_controller.gd`。
- 将商店商品刷新显示、商品卡片文本、tooltip、商品背景、按钮状态、按钮样式、卡片点击和遗物详情入口从 `main.gd` 移入 `ShopPanelController`。
- `ShopPanelController` 通过 `buy_requested`、`refresh_requested`、`relic_detail_requested` signal 通知 `main.gd`。
- 金币扣除、购买单位、购买遗物、刷新商店消耗和结果文本仍保留在 `main.gd`，避免本步同时改动经济与阵容规则。
- `main.gd` 只保留 `_refresh_shop_panel()` 薄包装和购买/刷新结算逻辑。
- `main.gd` 体量从约 1537 行下降到约 1265 行。

验证：

- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\shop_controller_check.log --check-only --script res://scripts/ui/shop_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_shop.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_shop.log --path . --quit` 通过。

备注：

- 商店卡片稀有度中文显示、背景色、文字颜色、按钮明暗效果复用 `RarityFormatter`。
- 商店购买结算留待后续阶段与 `EconomyManager`、`RosterManager` 拆分时再继续整理。

### 2026-05-06 阶段 1 / 步骤 6：主菜单与局内菜单控制器抽离

状态：已完成。

变更：

- 新增 `scripts/ui/menu_panel_controller.gd`。
- 将主菜单、游戏结束弹窗、局内菜单的创建、显示、隐藏、按钮样式和结束文本从 `main.gd` 移入 `MenuPanelController`。
- `MenuPanelController` 通过 `start_requested`、`game_end_confirmed`、`main_menu_requested`、`restart_requested` signal 通知 `main.gd`。
- 游戏状态切换、重开、返回主菜单、通关/失败流程仍由 `main.gd` 协调。
- `main.gd` 只保留 `_show_gameplay_menu()`、`_hide_gameplay_menu()`、`_show_game_end_dialog()`、`_hide_game_end_dialog()` 等薄包装。
- `main.gd` 体量从约 1265 行下降到约 1067 行。

验证：

- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\menu_controller_check.log --check-only --script res://scripts/ui/menu_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\shop_controller_check_2.log --check-only --script res://scripts/ui/shop_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_menu.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_menu.log --path . --quit` 通过。

备注：

- 阶段 1 中计划的主要 UI 控制器已经完成：商店、奖励、遗物、单位详情、主菜单/局内菜单。
- `main.gd` 仍保留开始战斗按钮样式、备战席列表、准备阶段拖拽和购买结算等逻辑，这些更适合后续阶段拆到流程、阵容或经济模块。

### 2026-05-06 阶段 2 / 步骤 1：金币经济管理器抽离

状态：已完成。

变更：

- 新增 `scripts/game/economy_manager.gd`。
- 将初始金币、基础胜利金币、精英奖励金币、Boss 奖励金币、金币增减、消费判断、消费执行、退款和胜利金币奖励公式移入 `EconomyManager`。
- `main.gd` 移除 `INITIAL_PLAYER_GOLD`、`BASE_WIN_GOLD`、`ELITE_WIN_GOLD_BONUS`、`BOSS_WIN_GOLD_BONUS` 和 `player_gold`。
- 商店购买、商店刷新、出售单位和战斗胜利奖励改为通过 `economy_manager.gold`、`spend_gold()`、`add_gold()`、`refund_gold()` 处理。
- 金币 UI 刷新仍保留在 `main.gd`，因为它依赖当前场景节点。

验证：

- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\economy_manager_check.log --check-only --script res://scripts/game/economy_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_economy.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_economy.log --path . --quit` 通过。

备注：

- 本步没有改变金币数值：初始金币仍为 8，基础胜利金币仍为 5，精英额外 +8，Boss 额外 +12，第 30 波 Boss 胜利不再额外发放局内金币。

### 2026-05-06 阶段 2 / 步骤 2：基础状态与波次控制器抽离

状态：已完成。

变更：

- 新增 `scripts/game/game_state.gd`。
- 新增 `scripts/game/run_controller.gd`。
- 将 `MAIN_MENU`、`PREPARE`、`BATTLE`、`REWARD`、`NEXT_PREPARE`、`GAME_OVER` 等状态常量移入 `GameState`。
- 将当前状态、当前波次、最大波次、进入主菜单、开始新局、进入准备/战斗/奖励/下一轮/结束、推进波次、波次上限判断和最终 Boss 胜利判断移入 `RunController`。
- `main.gd` 移除本地 `BattleState` 枚举、`current_round` 和 `max_round`，改为读取 `run_controller.state`、`run_controller.current_round` 和 `run_controller.max_round`。
- `main.gd` 仍负责根据状态变化刷新 UI、生成战斗、进入奖励和进入结束弹窗；这些流程协调会在后续更完整的 `RunController` 重构中继续收拢。
- `main.gd` 体量从约 1067 行下降到约 1054 行。

验证：

- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\game_state_check.log --check-only --script res://scripts/game/game_state.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\run_controller_check_2.log --check-only --script res://scripts/game/run_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_run_controller_2.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_run_controller_2.log --path . --quit` 通过。

备注：

- `--check-only --script` 不会自动识别刚新增的 `class_name GameState`，因此 `main.gd` 和 `run_controller.gd` 使用显式 `preload("res://scripts/game/game_state.gd")` 访问状态常量，避免依赖编辑器类缓存。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 3 / 步骤 1：单位目录、星级缩放与推荐站位抽离
状态：已完成。

变更：
- 新增 `scripts/catalog/unit_catalog.gd`。
- 新增 `scripts/roster/unit_scaling_service.gd`。
- 新增 `scripts/roster/roster_position_service.gd`。
- `UnitCatalog` 统一维护单位资源池、单位 ID、中文名读取、稀有度读取和按稀有度定价逻辑。
- `RosterManager` 和 `ShopManager` 改为复用 `UnitCatalog`，避免各自维护一份单位资源列表和单位 ID/名称/稀有度解析逻辑。
- `UnitScalingService` 接管星级成长表、战斗用 `UnitData` 复制和生命/攻击/防御/攻速/移速/暴击等缩放计算。
- `RosterPositionService` 接管准备阶段推荐站位、保存站位合法性判断、按角色推荐前/中/后排等逻辑。
- `RosterManager` 保持原有外部接口，继续负责 active/bench 阵容、出售、移动、升星入口和战斗配置组装，但内部已通过三个服务类委托单位目录、星级缩放与站位推荐。
- `roster_manager.gd` 体量从约 825 行下降到约 509 行。
- `shop_manager.gd` 体量从约 356 行下降到约 300 行，并复用同一套单位目录定价逻辑。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_catalog_check.log --check-only --script res://scripts/catalog/unit_catalog.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_scaling_service_check.log --check-only --script res://scripts/roster/unit_scaling_service.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\roster_position_service_check.log --check-only --script res://scripts/roster/roster_position_service.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\roster_manager_check_after_phase3.log --check-only --script res://scripts/roster_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\shop_manager_check_after_unit_catalog.log --check-only --script res://scripts/shop_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_phase3_roster.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_phase3_roster.log --path . --quit` 通过。

备注：
- 本步没有改变单位获取、解锁、自动升星、出售价格、推荐站位和商店栏位规则，只调整代码归属。
- `MergeService` 已在阶段 3 / 步骤 2 抽离；升星候选统计、合成组查找和合成执行已迁出 `RosterManager`。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 3 / 步骤 2：升星合成服务抽离
状态：已完成。

变更：
- 新增 `scripts/roster/merge_service.gd`。
- 将升星候选统计、预计可合成星级计算、合成组查找、合成执行、合成后保留站位、合成后回到 active/bench 的规则从 `RosterManager` 移入 `MergeService`。
- `RosterManager` 保留原有 `get_unit_upgrade_target_star()`、`check_auto_merge()`、`find_merge_group()`、`merge_units()` 等外部入口，并通过 `MergeService` 委托实现，商店升星提示与奖励升星提示无需改调用点。
- 单位出售价格中的星级折算也改为通过 `MergeService.get_star_sell_count()` 获取，保证升星规则和出售折算集中在同一服务。
- `roster_manager.gd` 体量从约 509 行下降到约 388 行。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\merge_service_check.log --check-only --script res://scripts/roster/merge_service.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\roster_manager_check_after_merge_service.log --check-only --script res://scripts/roster_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_merge_service.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_merge_service.log --path . --quit` 通过。

备注：
- 本步保持单位自动升星、升星提示、出售价格和 active/bench 回位规则不变，只调整职责归属。
- 阶段 3 的主要拆分已完成；后续如果继续细化，可以再把 active/bench 移动、出售和数量限制从 `RosterManager` 拆成更小的阵容操作服务。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 4 / 步骤 1：遭遇生成底层服务抽离
状态：已完成。

变更：
- 新增 `scripts/catalog/enemy_catalog.gd`。
- 新增 `scripts/encounter/wave_rule.gd`。
- 新增 `scripts/encounter/enemy_scaling_service.gd`。
- 新增 `scripts/encounter/enemy_position_service.gd`。
- 新增 `scripts/encounter/encounter_generator.gd`。
- `EnemyCatalog` 接管敌人资源 preload、敌人 ID 到资源的查询、敌人角色分类、普通/精英/Boss 敌人池、Boss 敌人池、敌人中文名和红方/Boss 显示名。
- `WaveRule` 接管每 5 波精英、每 10 波 Boss、普通敌人数、普通/精英/Boss 强度倍率、星级概率、精英星级概率增强、Boss 星级和护卫星级规则。
- `EnemyPositionService` 接管敌方前/中/后排站位与 Boss 固定站位。
- `EnemyScalingService` 接管战斗用敌方 `UnitData` 复制和生命、攻击、防御、攻速、移速、暴击、回蓝等缩放计算。
- `EncounterGenerator` 接管随机普通/精英/Boss 遭遇生成、模板角色数量、模板权重、精英兜底单位、精英高星兜底和随机遭遇数据组装。
- `EncounterManager` 保留原有外部入口：`get_encounter()`、`get_enemy_unit_configs()`、`get_enemy_unit_data_list()`、`get_encounter_debug_text()`；内部改为委托 `EnemyCatalog`、`EncounterGenerator` 和 `EnemyScalingService`。
- 前 10 波静态遭遇表已在阶段 4 / 步骤 2 迁出；本步完成后 `EncounterManager` 暂时保留这些表，避免当时同时改动手工配置波次内容。
- `encounter_manager.gd` 体量从约 871 行下降到约 247 行。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\enemy_catalog_check.log --check-only --script res://scripts/catalog/enemy_catalog.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\wave_rule_check.log --check-only --script res://scripts/encounter/wave_rule.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\enemy_scaling_service_check.log --check-only --script res://scripts/encounter/enemy_scaling_service.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\enemy_position_service_check.log --check-only --script res://scripts/encounter/enemy_position_service.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\encounter_generator_check.log --check-only --script res://scripts/encounter/encounter_generator.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\encounter_manager_check_after_generator.log --check-only --script res://scripts/encounter_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_encounter_generator.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_encounter_generator.log --path . --quit` 通过。

备注：
- 本步保持 30 波类型分布、普通/精英/Boss 倍率公式、敌人池、随机模板、敌人站位和 debug 文本格式不变，只调整职责归属。
- 阶段 4 的主要拆分已完成；前 10 波静态遭遇表已在阶段 4 / 步骤 2 迁入独立构建器，后续可以进入阶段 5 拆分技能与遗物效果。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 4 / 步骤 2：默认遭遇构建器抽离
状态：已完成。

变更：
- 新增 `scripts/encounter/default_encounter_builder.gd`。
- 将前 10 波手工配置的静态遭遇表、静态敌人条目创建、静态遭遇数据创建，以及第 11-30 波默认填充逻辑从 `EncounterManager` 移入 `DefaultEncounterBuilder`。
- `DefaultEncounterBuilder` 复用 `EnemyCatalog` 创建敌人显示名，并复用 `EncounterGenerator` 生成第 11-30 波默认遭遇。
- `EncounterManager` 的 `_build_default_encounters()` 变为薄包装，只负责从 `DefaultEncounterBuilder.build_default_encounters()` 接收结果。
- `EncounterManager` 当前主要保留遭遇缓存、对外查询、debug 文本、敌方战斗配置组装和敌人缩放委托。
- `encounter_manager.gd` 体量从约 247 行下降到约 142 行。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\default_encounter_builder_check.log --check-only --script res://scripts/encounter/default_encounter_builder.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\encounter_generator_check_after_default_builder.log --check-only --script res://scripts/encounter/encounter_generator.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\encounter_manager_check_after_default_builder.log --check-only --script res://scripts/encounter_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_default_encounter_builder.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_default_encounter_builder.log --path . --quit` 通过。

备注：
- 本步保持前 10 波静态遭遇内容、第 11-30 波默认生成方式、遭遇 debug 文本格式和敌人战斗配置行为不变，只调整职责归属。
- 阶段 4 计划中的敌人资源、波次规则、随机模板、数值缩放、站位推荐和默认遭遇构建均已拆分完成。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 5 / 步骤 1：遗物库存与奖励池抽离
状态：已完成。

变更：
- 新增 `scripts/relic/relic_inventory.gd`。
- 新增 `scripts/relic/relic_reward_pool.gd`。
- `RelicInventory` 接管玩家持有遗物列表、重复判断、按 ID 查询、只读列表输出和持有遗物打印。
- `RelicRewardPool` 接管全部遗物资源 preload 列表，以及奖励/商店共用的遗物奖励字典构建。
- `RelicManager` 保留原有 `add_relic()`、`has_relic()`、`has_relic_id()`、`get_relic_by_id()`、`get_available_relic_reward_options()` 等外部入口，内部改为委托 `RelicInventory` 和 `RelicRewardPool`。
- `RelicPanelController` 改为通过 `RelicManager.get_player_relics()` 获取已拥有遗物，不再直接读取 `player_relics` 字段。
- `relic_manager.gd` 当前约 624 行；遗物触发分发和具体效果实现仍留待阶段 5 后续步骤继续拆分。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_inventory_check.log --check-only --script res://scripts/relic/relic_inventory.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_reward_pool_check.log --check-only --script res://scripts/relic/relic_reward_pool.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_manager_check_after_relic_inventory.log --check-only --script res://scripts/relic_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_panel_controller_check_after_inventory.log --check-only --script res://scripts/ui/relic_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\reward_manager_check_after_relic_inventory.log --check-only --script res://scripts/reward_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\shop_manager_check_after_relic_inventory.log --check-only --script res://scripts/shop_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\battle_manager_check_after_relic_inventory.log --check-only --script res://scripts/battle_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_relic_inventory.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_relic_inventory.log --path . --quit` 通过。

备注：
- 本步保持遗物出现池、去重规则、奖励/商店遗物字段、遗物触发条件和战斗效果数值不变，只调整职责归属。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 5 / 步骤 2：遗物触发分发与效果执行抽离
状态：已完成。

变更：
- 新增 `scripts/relic/relic_trigger_dispatcher.gd`。
- 新增 `scripts/relic/relic_effect_resolver.gd`。
- `RelicTriggerDispatcher` 接管战斗开始、攻击命中、击杀、玩家单位死亡四类遗物触发条件判断，并根据已拥有遗物转发到效果执行器。
- `RelicEffectResolver` 接管战斗开始类遗物、猎手印记、决斗者手套、血之坠饰、最后阵线、魂火余烬、复仇火花等具体效果实现。
- `RelicManager` 保留原有四个战斗触发入口：`trigger_battle_start_relics()`、`trigger_attack_relics()`、`trigger_kill_relics()`、`trigger_death_relics()`，内部改为委托 `RelicTriggerDispatcher`。
- `RelicEffectResolver` 与 `RelicTriggerDispatcher` 对 `RelicManager` 使用 `WeakRef`，避免 `RefCounted` 双向引用导致项目退出时资源泄漏。
- `relic_manager.gd` 体量从约 624 行下降到约 179 行；当前主要保留遗物元数据读取、库存/奖励池委托和战斗触发入口转发。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_effect_resolver_check.log --check-only --script res://scripts/relic/relic_effect_resolver.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_trigger_dispatcher_check.log --check-only --script res://scripts/relic/relic_trigger_dispatcher.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_manager_check_after_trigger_dispatcher.log --check-only --script res://scripts/relic_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\battle_manager_check_after_relic_dispatcher.log --check-only --script res://scripts/battle_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_relic_dispatcher.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_effect_resolver_check_weakref.log --check-only --script res://scripts/relic/relic_effect_resolver.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_trigger_dispatcher_check_weakref.log --check-only --script res://scripts/relic/relic_trigger_dispatcher.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_manager_check_after_relic_weakref.log --check-only --script res://scripts/relic_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\battle_manager_check_after_relic_weakref.log --check-only --script res://scripts/battle_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_relic_weakref.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_relic_weakref.log --path . --quit` 通过。

备注：
- 本步保持遗物触发条件、目标筛选、数值、日志文本和遗物伤害统计不变，只调整职责归属。
- 首次项目检查时发现 `RelicManager` 与新服务之间存在 `RefCounted` 引用环，已通过弱引用修复；修复后项目退出不再出现 ObjectDB/resource leak 警告。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 5 / 步骤 3：状态效果工厂抽离
状态：已完成。

变更：
- 新增 `scripts/combat/status_effect_factory.gd`。
- `StatusEffectFactory` 接管状态效果类型常量、状态效果字典创建、目标是否有效/存活的保护，以及调用 `target.apply_status_effect()` 的统一入口。
- `UnitSkill` 改为通过 `StatusEffectFactory` 创建并应用状态效果；`HEAL_OVER_TIME`、`DAMAGE_OVER_TIME`、`STAT_ADD`、`STAT_MULTIPLY` 类型常量迁出 `unit_skill.gd`。
- `UnitSkill` 仍保留原有 `_apply_status_effect()` 薄包装，避免同时改动所有技能流程结构；后续拆 `PassiveResolver` 或 `ActiveSkillCaster` 时可以直接复用同一个工厂。
- `unit_skill.gd` 体量从约 948 行下降到约 940 行；本步主要收益是统一状态效果数据结构，而不是大幅减少行数。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\status_effect_factory_check.log --check-only --script res://scripts/combat/status_effect_factory.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_skill_check_after_status_effect_factory.log --check-only --script res://scripts/unit_skill.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_check_after_status_effect_factory.log --check-only --script res://scripts/unit.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\status_effect_check_after_factory.log --check-only --script res://scripts/status_effect.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\battle_manager_check_after_status_effect_factory.log --check-only --script res://scripts/battle_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_status_effect_factory.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_status_effect_factory.log --path . --quit` 通过。

备注：
- 本步保持持续治疗、持续伤害、属性加值、属性倍率、持续时间、tick 间隔和刷新行为不变，只调整状态效果创建入口。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 5 / 步骤 4：被动技能解析器抽离
状态：已完成。

变更：
- 新增 `scripts/combat/passive_resolver.gd`。
- `PassiveResolver` 接管玩家和敌人的被动 ID、被动数值常量、战斗开始被动、受击生命伤害修正、有效防御加成、普攻伤害修正、攻击命中被动、击杀被动，以及主动技能伤害/治疗倍率修正。
- `UnitSkill` 保留原有外部入口：`apply_battle_start_passives()`、`get_effective_defense_bonus()`、`apply_incoming_life_damage_passives()`、`get_basic_attack_damage()`、`apply_attack_landed_passives()`、`apply_kill_passives()`，内部改为委托 `PassiveResolver`。
- 主动技能实现暂时仍保留在 `UnitSkill`，但主动技能中的伤害倍率和治疗倍率已经通过 `PassiveResolver` 读取，避免主动技能继续直接关心被动 ID 与被动倍率常量。
- `unit_skill.gd` 体量从约 940 行下降到约 663 行。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\passive_resolver_check.log --check-only --script res://scripts/combat/passive_resolver.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_skill_check_after_passive_resolver.log --check-only --script res://scripts/unit_skill.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_check_after_passive_resolver.log --check-only --script res://scripts/unit.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_combat_check_after_passive_resolver.log --check-only --script res://scripts/unit_combat.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\battle_manager_check_after_passive_resolver.log --check-only --script res://scripts/battle_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_passive_resolver.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_passive_resolver.log --path . --quit` 通过。

备注：
- 本步保持所有玩家/敌人被动触发条件、数值、目标选择、日志文本、护盾阈值记录和主动技能倍率修正不变，只调整职责归属。
- `UnitSkill` 仍保留主动技能释放、主动技能目标选择和部分通用目标搜索函数；后续可以继续抽 `ActiveSkillCaster`。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 5 / 步骤 5：主动技能施放器抽离
状态：已完成。

变更：
- 新增 `scripts/combat/active_skill_caster.gd`。
- `ActiveSkillCaster` 接管主动技能 ID、主动技能数值常量、玩家主动技能、敌人主动技能、主动技能目标选择、技能伤害/治疗/护盾/持续效果应用。
- `UnitSkill` 保留原有 `try_cast_active_skill()`，内部委托 `ActiveSkillCaster`。
- `UnitSkill` 继续负责回蓝更新和被动入口转发；`ActiveSkillCaster` 复用同一个 `PassiveResolver`，保持主动技能伤害/治疗倍率修正一致。
- `unit_skill.gd` 体量从约 663 行下降到约 74 行。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\active_skill_caster_check.log --check-only --script res://scripts/combat/active_skill_caster.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_skill_check_after_active_skill_caster.log --check-only --script res://scripts/unit_skill.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\passive_resolver_check_after_active_skill_caster.log --check-only --script res://scripts/combat/passive_resolver.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\status_effect_factory_check_after_active_skill_caster.log --check-only --script res://scripts/combat/status_effect_factory.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_check_after_active_skill_caster.log --check-only --script res://scripts/unit.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\battle_manager_check_after_active_skill_caster.log --check-only --script res://scripts/battle_manager.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_active_skill_caster.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_active_skill_caster.log --path . --quit` 通过。

备注：
- 本步保持所有玩家/敌人主动技能触发条件、目标选择、数值、反馈文本、持续效果结构和被动倍率修正不变，只调整职责归属。
- 阶段 5 计划中的状态效果工厂、被动解析器、主动技能施放器、遗物库存/奖励/触发/效果均已完成；后续可继续优化 combat 文件内部结构，或进入阶段 6 场景文件拆分。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 6 / 步骤 1：菜单类场景模板拆分
状态：已完成。

变更：
- 新增 `scenes/ui/main_menu_panel.tscn`。
- 新增 `scenes/ui/gameplay_menu_panel.tscn`。
- 新增 `scenes/ui/game_end_panel.tscn`。
- `MenuPanelController` 改为 preload 并实例化上述三个场景，不再用脚本逐个创建主菜单、局内菜单和游戏结束弹窗的节点树。
- `MenuPanelController` 继续负责显示/隐藏、结算标题与说明文本、按钮信号转发和按钮/面板样式套用，避免场景模板直接掌握游戏流程。
- `menu_panel_controller.gd` 体量下降到约 176 行。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\menu_controller_check_after_scene_split.log --check-only --script res://scripts/ui/menu_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_menu_scene_split.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_menu_scene_split.log --path . --quit` 通过。

备注：
- 这三个菜单原本由 `MenuPanelController` 运行时动态创建，并不属于 `main.tscn` 的静态节点；因此本步主要降低菜单控制器的 UI 构造密度，`main.tscn` 体量暂不变化。
- 主菜单开始游戏、局内菜单返回主菜单/重开/继续、失败或通关确认返回主菜单的信号路径保持不变。
- 后续阶段 6 可继续拆分奖励面板、单位详情面板、商店面板和遗物面板，让 `main.tscn` 的静态 UI 节点逐步减少。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 6 / 步骤 2：奖励面板场景拆分
状态：已完成。

变更：
- 新增 `scenes/ui/reward_panel.tscn`。
- 将 `RewardPanel Panel`、`RewardTitle Label`、三个 `RewardButton` 从 `scenes/main.tscn` 迁入独立奖励面板场景。
- `scenes/main.tscn` 改为通过 `ExtResource("14_reward_panel")` 实例化 `RewardPanel Panel`，节点名与子节点名保持不变。
- `main.gd` 中原有 `@"UI CanvasLayer/RewardPanel Panel/..."` 节点路径保持可用，`RewardPanelController` 的 setup 参数和外部行为保持不变。
- `main.tscn` 体量从约 472 行下降到约 426 行；`reward_panel.tscn` 当前约 49 行。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\reward_panel_controller_check_after_scene_split.log --check-only --script res://scripts/ui/reward_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_reward_scene_split.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_reward_scene_split.log --path . --quit` 通过。

备注：
- 本步只迁移奖励面板节点归属，不改动奖励池、奖励抽取、奖励按钮文本、稀有度样式、升星提醒或奖励应用逻辑。
- 因节点名保持不变，现有 `main.gd` 与 `RewardPanelController` 不需要同步改接口，后续仍可继续把 setup 绑定改为面板场景自带脚本或导出 NodePath。
- 后续阶段 6 建议继续拆分单位详情面板，随后再处理遗物面板和商店面板。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。

### 2026-05-06 阶段 6 / 步骤 3：剩余 UI 面板场景拆分与计划收口
状态：已完成。

变更：
- 新增 `scenes/ui/shop_panel.tscn`，承载 10 格商店商品、购买按钮、金币文本、关闭按钮和刷新按钮。
- 新增 `scenes/ui/unit_detail_panel.tscn`，承载单位详情标题、关闭按钮和详情富文本。
- 新增 `scenes/ui/relic_bar_panel.tscn` 与 `scenes/ui/relic_detail_panel.tscn`，分别承载主界面遗物栏和遗物详情弹窗。
- 新增 `scenes/ui/bench_panel.tscn`、`scenes/ui/sell_zone_panel.tscn`、`scenes/ui/encounter_info_panel.tscn`、`scenes/ui/stats_panel.tscn`，将阵容面板、出售区、遭遇信息和战斗统计从主场景中拆出。
- `scenes/main.tscn` 改为实例化上述 UI 子场景；所有根节点名和子节点名保持不变，`main.gd` 中原有 `@"UI CanvasLayer/..."` 路径继续可用。
- `main.tscn` 体量从约 426 行下降到约 101 行；阶段 6 计划内 UI 场景拆分已全部完成。

验证：
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\main_check_after_full_scene_split.log --check-only --script res://scripts/main.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\shop_controller_check_after_full_scene_split.log --check-only --script res://scripts/ui/shop_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\unit_detail_controller_check_after_full_scene_split.log --check-only --script res://scripts/ui/unit_detail_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\relic_controller_check_after_full_scene_split.log --check-only --script res://scripts/ui/relic_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\reward_controller_check_after_full_scene_split.log --check-only --script res://scripts/ui/reward_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\menu_controller_check_after_full_scene_split.log --check-only --script res://scripts/ui/menu_panel_controller.gd --path .` 通过。
- `Godot_v4.6.2-stable_win64_console.exe --headless --log-file .godot_user\project_check_after_full_scene_split.log --path . --quit` 通过。

备注：
- 本步只改变 UI 节点归属，不改动商店刷新、购买、奖励、单位详情、遗物详情、阵容、出售、遭遇显示或统计文本逻辑。
- 遗物栏与遗物详情原本是两个主场景同级节点，因此拆为 `relic_bar_panel.tscn` 和 `relic_detail_panel.tscn` 两个场景，以保持原节点路径不变。
- 截至本步，原重构计划 1-6 阶段全部完成；后续结构优化建议转为按需求小步推进。
- 项目启动检查仍会输出 Windows 根证书读取警告，与本次重构无关。
