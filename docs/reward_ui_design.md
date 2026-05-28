# 奖励选择 UI 设计

> 维护提示：本文档仍可作为奖励三选一的 UI 规则参考。当前实现已加入悬停详情、单位技能详情和更多奖励来源；单位奖励池已扩展至 17 个指定单位，具体内容以 `docs/content_reference.md` 和实际 `RewardManager` 为准。

本文档记录当前奖励选择界面的布局、长文本处理、单位升星提示和稀有度颜色规则。

## 1. 目标

奖励选择 UI 用于在玩家战斗胜利后展示三选一奖励。当前版本的目标是：

- 面板出现在画面中央。
- 三个奖励选项在面板内稳定显示。
- 长描述不超出奖励按钮边界。
- 不同稀有度有清晰底色区分。
- 单位奖励在获得后可合成时提示可升星。
- 奖励 UI 只负责展示和选择，不在 UI 层实现奖励效果逻辑。

## 2. 场景结构

主要节点位于：

- `res://scenes/main.tscn`

核心结构：

```text
UI CanvasLayer
└── RewardPanel Panel
    ├── RewardTitle Label
    ├── RewardButton1 Button
    ├── RewardButton2 Button
    └── RewardButton3 Button
```

主要逻辑位于：

- `res://scripts/ui/reward_panel_controller.gd` — 奖励面板 UI 展示、按钮交互、稀有度样式
- `res://scripts/reward_manager.gd` — 奖励生成（三选一抽取、属性/单位/遗物类型分发）
- `res://scripts/main.gd` — 流程调度（进入奖励状态、调用 controller 展示、处理玩家选择后的阵容/遗物写入）

相关 UI 工具函数位于 `RewardPanelController` 和 `PixelUITheme`，负责读取奖励稀有度、转换中文显示、设置像素风按钮样式和展示悬停详情。

## 3. 布局规则

当前规则：

- `RewardPanel` 使用居中锚点。
- 面板尺寸扩大，避免三项奖励挤在一起。
- 奖励按钮宽度和高度固定，避免因文字变化造成布局跳动。
- 按钮文字启用自动换行。
- 按钮文字启用裁剪，超长文本不会冲出按钮边界。
- 奖励完整描述仍保留在 `tooltip_text` 中，方便后续鼠标悬停查看。

## 4. 奖励文字格式

当前按钮文字格式：

```text
奖励名称  [稀有度]

奖励描述

可选：可升星提示
```

示例：

```text
Mage Lens  [稀有]

战斗开始时，所有玩家法师获得 +20% 技能伤害。
```

单位奖励示例：

```text
获得弓手  [普通]
添加一名弓手到队伍。
可升星：获得后可合成 2 星
```

## 5. 稀有度颜色

奖励项使用 `reward["rarity"]` 控制显示。遗物奖励优先读取 `relic_data.rarity`，普通属性奖励默认 `COMMON`，单位奖励按奖励池配置读取；当前指定单位奖励包含基础单位、中期单位与召唤相关单位，实际列表以 `RewardManager._build_reward_pool()` 为准。

| 中文 | 标准枚举 | 兼容输入 | 底色 |
| --- | --- | --- | --- |
| 普通 | `COMMON` | `NORMAL`, `普通` | 灰白 |
| 精良 | `FINE` | `UNCOMMON`, `精良` | 绿色 |
| 稀有 | `RARE` | `稀有` | 蓝色 |
| 史诗 | `EPIC` | `史诗` | 紫色 |
| 传说 | `LEGENDARY` | `传说` | 橙色 |
| 神话 | `MYTHIC` | `MYTHICAL`, `神话` | 金色 |

说明：

- 标准枚举应优先使用英文大写。
- 中文输入用于兼容设计表或临时调试数据。
- 未识别稀有度会回退为 `COMMON`。

## 6. 数据来源

奖励生成位于：

- `res://scripts/reward_manager.gd`

当前奖励类型：

| 类型 | 来源 | 稀有度 |
| --- | --- | --- |
| 属性奖励 | `_build_reward_pool()` | 当前默认 `COMMON` |
| 单位奖励 | `_build_reward_pool()` | 读取奖励项配置，含 `unit_id` |
| 遗物奖励 | `RelicManager.get_available_relic_reward_options()` | 读取遗物资源 `rarity` |

单位奖励的 `unit_id` 会提供给 UI，用于通过 `RosterManager` 判断获得后是否能合成 2 星或 3 星。

后续如果加入稀有度权重，建议仍由 `RewardManager` 负责抽取，UI 只根据结果展示。

## 7. 验证清单

1. 战斗胜利后，奖励面板应出现在画面中央。
2. 三个奖励按钮应全部在面板内。
3. 长描述奖励不应超出按钮或面板边界。
4. 普通、精良、稀有、史诗、传说、神话应显示不同底色。
5. 遗物奖励应显示其资源中的真实稀有度。
6. 选择奖励后，奖励应用逻辑不应受 UI 样式影响。
7. 指定单位奖励在可触发合成时，应显示可升星提醒。
