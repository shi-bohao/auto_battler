# 素材处理流程

更新时间：2026-06-03

本文档记录当前项目中全部美术素材的预处理方式和接入规范。

## 目录

- [规范总览](#规范总览)
- [背景图处理](#背景图处理)
- [遗物图标处理](#遗物图标处理)
- [玩家单位图标处理](#玩家单位图标处理)
- [敌人单位图标处理](#敌人单位图标处理)
- [召唤物图标处理](#召唤物图标处理)
- [游戏内接入与导出注意事项](#游戏内接入与导出注意事项)

---

## 规范总览

| 素材类型 | 处理方式 | 输入位置 | 输出位置 | 脚本类型 |
|---------|---------|---------|---------|---------|
| 背景图 | 直接复制 | `image/背景图*.png` | `assets/game/ui/backgrounds/` | 手动复制 |
| 遗物图标 | 双背景差分 + 切分 | `image/遗物*.png` | `assets/processed/relics/` | PowerShell |
| 玩家单位图标 | 双背景差分 + 去线 + 切分 | `image/玩家单位*.png` | `assets/processed/player_units/` | PowerShell |
| 敌人单位图标 | 双背景差分 + 去线 + 切分 | `image/敌人单位*.png` | `assets/processed/enemy_units/` | Python |
| 召唤物图标 | —（当前无素材） | — | — | — |

**核心原则：**

1. **双背景差分法**：所有需要去除背景的图标素材，优先使用同一构图的暗底图 + 白底图逐像素对比反推透明度，比单背景颜色阈值法更可靠。
2. **显式资源引用**：处理后的 PNG 必须在对应 `.tres` 中通过 `[ext_resource]` 显式引用，代码中不再使用动态路径加载，以确保导出包能正确包含纹理。
3. **命名顺序由 `catalog_id` 驱动**：合图中的格子顺序与 `docs/content_reference.md` 中对应表格的 `catalog_id` 排序严格一致。
4. **`.png.import` 必须提交**：所有 `assets/processed/` 下的 `.png.import` 文件必须加入版本库。

---

## 背景图处理

### 概述

背景图不做透明背景处理，直接从 `image/` 复制到稳定资源目录，再通过统一目录配置接入游戏。主菜单和战斗场景共用同一套背景图库。

### 输入文件

当前背景源文件位于 `image/`，命名使用中文展示名：

```text
image/草地背景图1.png
image/草地背景图2.png
image/森林背景图1.png
image/森林背景图2.png
image/魔法森林背景图1.png
image/魔法森林背景图2.png
image/魔法森林背景图3.png
image/雪原背景图1.png
image/雪原背景图2.png
image/沙漠背景图1.png
image/沙漠背景图2.png
image/墓园背景图1.png
image/墓园背景图2.png
image/火山背景图1.png
image/火山背景图2.png
image/沼泽背景图1.png
image/沼泽背景图2.png
```

### 输出位置

复制到 `assets/game/ui/backgrounds/`，资源文件使用英文稳定文件名：

```text
assets/game/ui/backgrounds/grass_background_1.png
assets/game/ui/backgrounds/forest_background_2.png
assets/game/ui/backgrounds/magic_forest_background_3.png
```

### 处理流程

1. 从 `image/` 复制源文件到 `assets/game/ui/backgrounds/`；
2. 使用英文稳定文件名重命名；
3. 在 `scripts/ui/background_catalog.gd` 的 `BACKGROUNDS` 数组中增加/更新记录。

### 游戏接入

背景列表统一维护在 `scripts/ui/background_catalog.gd`。`BackgroundCatalog.BACKGROUNDS` 同时保存：

- `name`：游戏内列表显示的中文名；
- `path`：Godot 资源路径（硬编码字符串，导出时可被 Godot 自动检测包含）。

主菜单和战斗棋盘都读取该目录：

- 主菜单：`scripts/ui/menu_panel_controller.gd` 创建背景下拉列表，选择后更新主菜单背景；
- 战斗棋盘：`scripts/battle_board.gd` 读取同一批 texture 和中文名，用于战斗/备战阶段背景选择；
- 流程协调：`scripts/main.gd` 负责把主菜单选择同步到 `BattleBoard`。

### 后续维护建议

- 替换现有背景时，保持中文源文件名不变，只更新图片内容即可；
- 新增背景时，同时补充复制到 `assets/game/ui/backgrounds/` 的英文文件名，并在 `BackgroundCatalog.BACKGROUNDS` 增加一条记录；
- 如果某张背景不适合游戏，可以从 `BackgroundCatalog.BACKGROUNDS` 移除，不必删除源图片；
- 主菜单和战斗场景必须共用 `BackgroundCatalog`，不要在两个场景里各自维护一份列表。

---

## 遗物图标处理

### 概述

遗物图标采用**双背景差分**方式进行透明背景处理，按 4×4 网格切分为单图。

### 输入文件

```text
image/遗物1-16.png
image/遗物1-16白色背景.png

image/遗物17-32.png
image/遗物17-32白色背景.png

image/遗物33-43.png
image/遗物33-43白色背景.png
```

要求：

- 每组暗底图和白底图尺寸必须一致，图标位置必须一致；
- 每张图按 4×4 网格切分；
- 遗物顺序使用 `data/relics/*.tres` 中的 `catalog_id` 排序；`docs/content_reference.md` 的"遗物"表格由该字段生成，可作为切图顺序核对表；
- 第三张图只使用前 11 个有效格子，对应总计 43 个遗物。

### 输出位置

```text
assets/processed/relics/
```

输出文件名使用遗物 ID：

```text
assets/processed/relics/crown_of_three.png
assets/processed/relics/golden_charm.png
```

脚本同时生成映射清单：

```text
assets/processed/relics/relic_icon_manifest.csv
```

清单记录：遗物序号、relic_id、暗底来源图、白底来源图、原始格子编号。

### 处理流程

1. 读取同一素材的暗底图和白底图；
2. 根据两张图在同一像素上的颜色差异反推透明度；
3. 差异接近"背景从暗色变成白色"的区域判定为背景（透明）；
4. 差异很小的区域判定为主体，保留为不透明；
5. 对半透明边缘保留 alpha，减少硬边和锯齿；
6. 按 4×4 网格切分为单图，输出透明 PNG。

### 脚本路径与调用方式

脚本路径：

```text
tools/process_relic_icons_diff.ps1
```

在项目根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools\process_relic_icons_diff.ps1
```

也可指定路径：

```powershell
powershell -ExecutionPolicy Bypass -File tools\process_relic_icons_diff.ps1 `
  -ImageDir image `
  -OutputDir assets/processed/relics `
  -ContentDoc docs/content_reference.md
```

### 游戏接入

每个 `data/relics/*.tres` 通过 `[ext_resource]` 显式引用 `assets/processed/relics/{relic_id}.png`，并在 `[resource]` 中配置 `icon_texture = ExtResource("2_icon")`。

`RelicIconHelper` 仅保留 `get_texture_sized` 等通用工具方法，不再负责动态路径加载。

### 后续维护建议

- 新增遗物后，先在对应 `RelicData` 资源中追加新的 `catalog_id`，再重新生成 `docs/content_reference.md` 并重跑脚本；
- 如果遗物数量超过当前图片容量，继续追加下一张 `遗物44-59.png` 和对应白底图，并扩展脚本中的 `$sheetPairs`；
- 不建议再使用单背景颜色阈值法处理图标；
- 如果主体边缘仍有背景残留，优先检查两张输入图是否完全对齐，而不是先调高删除阈值。

---

## 玩家单位图标处理

### 概述

玩家单位图标采用**双背景差分**方式处理，并额外清除素材图中的细网格分隔线。

### 输入文件

```text
image/玩家单位1-16黑色背景.png
image/玩家单位1-16白色背景.png

image/玩家单位17-30黑色背景.png
image/玩家单位17-30白色背景.png
```

要求：

- 每组黑底图和白底图尺寸必须一致，单位位置必须一致；
- 每张图按 4×4 网格切分；
- 第二张图只使用前 14 个有效格子，对应总计 30 个玩家单位；
- 单位命名顺序使用 `data/units/*.tres` 中的 `catalog_id` 排序；`docs/content_reference.md` 的"玩家单位"表格由该字段生成，可作为切图顺序核对表；
- 素材中的细网格线会在整图和单图输出中一起移除。

### 输出位置

```text
assets/processed/player_units/
```

输出文件名使用单位 ID：

```text
assets/processed/player_units/necromancer.png
assets/processed/player_units/warrior.png
```

脚本同时生成：

```text
assets/processed/player_units/player_unit_icon_manifest.csv
assets/processed/player_units/player_unit_grid_scan.csv
```

`grid_scan.csv` 包含：来源素材名、扫描方向（row/column）、理论边界编号、实际扫描坐标、非透明像素数、线状像素数、主导颜色桶、是否判定抹除。

整张去背景、去网格线后的透明图保存回 `image/`：

```text
image/玩家单位1-16透明背景.png
image/玩家单位17-30透明背景.png
```

### 处理流程

1. 读取同一素材的黑底图和白底图；
2. 根据像素差异反推透明度，生成整张透明背景图；
3. 按 4×4 理论网格计算预期分割线位置；
4. 在每条理论分割线前后 16 像素范围内逐行 / 逐列扫描；
5. 统计每条候选行 / 列的非透明像素、线状像素、主导颜色桶等信息；
6. 将扫描记录写入 `player_unit_grid_scan.csv`；
7. 完整扫描结束后，统一抹除被标记的分割线及其相邻 1 像素行 / 列；
8. 切分单图时，从理论边界前后 24 像素范围内选择切割线；
9. 切割线优先级：已标记分割线且空白 > 已标记分割线相邻行 / 列且空白 > 任意空白行 / 列 > 非透明像素最少的位置；
10. 将切分结果填充到统一尺寸画布，根据 alpha 包围盒自动居中，输出单个单位 PNG。

### 脚本路径与调用方式

脚本路径：

```text
tools/process_player_unit_icons_diff.ps1
```

在项目根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools\process_player_unit_icons_diff.ps1
```

也可指定路径：

```powershell
powershell -ExecutionPolicy Bypass -File tools\process_player_unit_icons_diff.ps1 `
  -ImageDir image `
  -OutputDir assets/processed/player_units `
  -ContentDoc docs/content_reference.md
```

### 游戏接入

每个 `data/units/*.tres` 通过 `[ext_resource]` 显式引用 `assets/processed/player_units/{unit_type}.png`，并在 `[resource]` 中配置：

```gdscript
board_sprite = ExtResource("2_art")
portrait_texture = ExtResource("2_art")
icon_texture = ExtResource("2_art")
```

`unit_data_applier.gd` 直接读取 `.tres` 中已配置的贴图字段。`UnitArtHelper` 仅保留 `get_texture_sized` 通用工具方法。

### 后续维护建议

- 新增玩家单位后，先在对应 `UnitData` 资源中追加新的 `catalog_id`，再重新生成 `docs/content_reference.md` 并重跑脚本；
- 如果玩家单位数量超过 30，继续追加下一组黑底/白底素材，并扩展脚本中的 `$sheetPairs`；
- 如果网格线仍有残留，优先调整脚本中的整行 / 整列线状像素检测阈值；
- 如果切分位置不正确，优先检查 `player_unit_grid_scan.csv` 中对应理论边界附近是否存在已标记且空白的候选行 / 列；
- 如果单位主体仍明显偏心，检查素材是否在原始格子中被裁掉，脚本只能对切分后仍存在的主体做自动居中。

---

## 敌人单位图标处理

### 概述

敌人单位图标采用**双背景差分**方式处理，并清除素材图中的细网格分隔线。处理工具使用 Python 脚本而非 PowerShell。

### 输入文件

```text
image/敌人单位1-16黑色背景.png
image/敌人单位1-16白色背景.png

image/敌人单位17-32黑色背景.png
image/敌人单位17-32白色背景.png
```

要求：

- 每组黑底图和白底图尺寸必须一致，单位位置必须一致；
- 每张图按 4×4 网格切分；
- 单位命名顺序使用 `data/enemies/*.tres` 中的 `catalog_id` 排序；`docs/content_reference.md` 的"敌方单位"表格由该字段生成，可作为切图顺序核对表；
- `training_dummy` (catalog_id = 0) 不参与切图，不包含在合图中；
- 素材中的细网格线会在整图和单图输出中一起移除。

### 输出位置

```text
assets/processed/enemy_units/
```

输出文件名使用单位 ID：

```text
assets/processed/enemy_units/enemy_common_slime.png
assets/processed/enemy_units/enemy_boss_goblin_high_priest.png
```

脚本同时生成：

```text
assets/processed/enemy_units/icon_manifest.csv
assets/processed/enemy_units/grid_scan.csv
```

整张去背景、去网格线后的透明图保存回 `image/`：

```text
image/敌人单位1-16透明背景.png
image/敌人单位17-32透明背景.png
```

### 处理流程

1. 读取同一素材的黑底图和白底图；
2. `remove_diff_background.py` 根据像素差异反推透明度，生成整张透明背景图；
3. `slice_icon_sheet.py` 按 4×4 理论网格计算预期分割线位置；
4. 在每条理论分割线前后 16 像素范围内逐行 / 逐列扫描，检测低饱和度线状像素比例；
5. 将扫描记录写入 `grid_scan.csv`；
6. 完整扫描结束后，统一抹除被标记的分割线及其相邻 1 像素行 / 列；
7. 切分单图时，从理论边界前后 24 像素范围内选择切割线；
8. 切割线优先级：已标记分割线且空白 > 已标记分割线相邻行 / 列且空白 > 任意空白行 / 列 > 非透明像素最少的位置；
9. 将切分结果填充到统一尺寸画布，根据 alpha 包围盒居中，输出单个单位 PNG。

### 命名清单文件

切图顺序由以下命名清单文件控制：

```text
tools/art/enemy_names_1_16.txt
tools/art/enemy_names_17_32.txt
```

每行一个 `unit_type`（即 enemy_id），顺序对应合图中的格子顺序（1-16 和 17-32）。

### 脚本路径与调用方式

脚本路径：

```text
tools/art/remove_diff_background.py
tools/art/slice_icon_sheet.py
```

**第一步：去除背景**

```bash
uv run --with pillow python tools/art/remove_diff_background.py \
  --dark image/敌人单位1-16黑色背景.png \
  --light image/敌人单位1-16白色背景.png \
  --output image/敌人单位1-16透明背景.png

uv run --with pillow python tools/art/remove_diff_background.py \
  --dark image/敌人单位17-32黑色背景.png \
  --light image/敌人单位17-32白色背景.png \
  --output image/敌人单位17-32透明背景.png
```

**第二步：切分单图**

```bash
uv run --with pillow python tools/art/slice_icon_sheet.py \
  --input image/敌人单位1-16透明背景.png \
  --output-dir assets/processed/enemy_units \
  --cols 4 --rows 4 \
  --names-file tools/art/enemy_names_1_16.txt \
  --cleaned-output image/敌人单位1-16透明背景_去线.png

uv run --with pillow python tools/art/slice_icon_sheet.py \
  --input image/敌人单位17-32透明背景.png \
  --output-dir assets/processed/enemy_units \
  --cols 4 --rows 4 \
  --names-file tools/art/enemy_names_17_32.txt \
  --cleaned-output image/敌人单位17-32透明背景_去线.png
```

### 游戏接入

每个 `data/enemies/*.tres` 通过 `[ext_resource]` 显式引用 `assets/processed/enemy_units/{unit_type}.png`，并在 `[resource]` 中配置：

```gdscript
board_sprite = ExtResource("2_art")
portrait_texture = ExtResource("2_art")
icon_texture = ExtResource("2_art")
```

`unit_data_applier.gd` 直接读取 `.tres` 中已配置的贴图字段。

### 后续维护建议

- 新增敌人单位后，先在对应 `.tres` 资源中追加新的 `catalog_id`，再重新生成 `docs/content_reference.md`；
- 如果敌人单位数量超过 32，继续追加下一组合图素材，并扩展命名清单文件；
- 如果网格线仍有残留，优先调整 `slice_icon_sheet.py` 中的整行 / 整列线状像素检测阈值；
- 映射顺序必须严格与 `content_reference.md` 中的敌方单位表格一致，更新文档后需同步修改命名清单文件；
- `.png.import` 文件必须提交到版本库，新增或替换图片后务必运行 `--headless --import`。

---

## 召唤物图标处理

### 概述

召唤物当前**无专用美术素材**。`data/summons/` 下所有 `.tres` 均未配置 `board_sprite` / `portrait_texture` / `icon_texture`，战场上通过 `unit.gd` 的 `body` ColorRect 显示占位方块。

### 预留规范

如需新增召唤物素材，按以下规范执行：

1. 准备召唤物合图（参照玩家单位 / 敌人单位的双背景差分规范）；
2. 使用 `remove_diff_background.py` + `slice_icon_sheet.py` 处理；
3. 输出到 `assets/processed/summon_units/`（或复用现有目录）；
4. 在 `data/summons/*.tres` 中显式引用对应 PNG；
5. 运行 `--headless --import` 生成 `.png.import`；
6. 提交 `.png.import` 到版本库。

---

## 游戏内接入与导出注意事项

### 接入方式总览

当前项目采用统一的**显式资源引用**方式：

| 素材类型 | `.tres` 字段 | 引用目标 |
|---------|-------------|---------|
| 玩家单位 | `board_sprite`, `portrait_texture`, `icon_texture` | `assets/processed/player_units/*.png` |
| 敌人单位 | `board_sprite`, `portrait_texture`, `icon_texture` | `assets/processed/enemy_units/*.png` |
| 英雄 | `portrait_texture` | `assets/game/heroes/*.png`（或对应路径） |
| 遗物 | `icon_texture` | `assets/processed/relics/*.png` |
| 召唤物 | —（当前无） | — |
| 背景图 | `BackgroundCatalog.BACKGROUNDS[].path` | `assets/game/ui/backgrounds/*.png` |

`UnitArtHelper` 和 `RelicIconHelper` 仅保留通用的尺寸调整工具方法（如 `get_texture_sized`），不再负责任何动态路径加载。

### `catalog_id` 使用规范

- 玩家单位、敌人、召唤物和英雄运行时单位由 `UnitData.catalog_id` 保存；
- 遗物由 `RelicData.catalog_id` 保存；
- 英雄定义由 `HeroData.catalog_id` 保存；
- 该字段只用于稳定显示、文档和素材顺序，不替代 `unit_type`、`relic_id`、`hero_id` 等逻辑 ID。

### 导出规则

- **不要在 `assets/processed/` 根目录放 `.gdignore`**，否则 `player_units`、`enemy_units`、`relics` 目录下的 PNG 不会被 Godot 导入/导出；
- 当前只保留 `assets/processed/ui/.gdignore`，用于忽略旧 UI 处理输出；
- **`.png.import` 文件必须提交到版本库**：
  - `assets/processed/player_units/*.png.import`
  - `assets/processed/enemy_units/*.png.import`
  - `assets/processed/relics/*.png.import`
  - `assets/game/ui/backgrounds/*.png.import`（如有新增）
- 它们记录 Godot 纹理导入目标，缺失时干净环境或导出包可能无法加载对应贴图。

### 导入与导出命令

修改或新增处理后 PNG 后，先执行一次资源导入，再导出正式包：

```powershell
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\asset_import.log --import
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\export.log --export-release "Windows Desktop" ..\auto_battler_output\auto_battler.exe
```

背景图变更后，额外运行以下检查：

```powershell
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\background_catalog_check.log --check-only --script res://scripts/ui/background_catalog.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\menu_background_selector_check.log --check-only --script res://scripts/ui/menu_panel_controller.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\battle_board_background_check.log --check-only --script res://scripts/battle_board.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\main_background_check.log --check-only --script res://scripts/main.gd
```

如果导出程序启动后立即退出，优先运行 console wrapper 查看日志：

```powershell
..\auto_battler_output\auto_battler.console.exe --log-file ..\auto_battler_output\run_console.log
```

常见资源错误为 `No loader found for resource: res://assets/processed/...png`，通常表示：

- PNG 被 `.gdignore` 排除；
- `.png.import` 未提交；
- 导出包不是当前资源状态重新导出的版本。
