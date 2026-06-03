# 素材处理流程

更新时间：2026-06-03

本文档记录当前项目中全部美术素材的预处理方式和接入规范。

## 目录

- [规范总览](#规范总览)
- [通用处理流程](#通用处理流程)
- [各素材类型配置](#各素材类型配置)
  - [背景图](#背景图)
  - [遗物图标](#遗物图标)
  - [玩家单位图标](#玩家单位图标)
  - [敌人单位图标](#敌人单位图标)
  - [召唤物图标](#召唤物图标)
- [游戏内接入与导出注意事项](#游戏内接入与导出注意事项)

---

## 规范总览

| 素材类型 | 处理方式 | 输入位置 | 输出位置 |
|---------|---------|---------|---------|
| 背景图 | 直接复制 | `image/背景图*.png` | `assets/game/ui/backgrounds/` |
| 遗物图标 | 双背景差分 + 切分 | `image/遗物*.png` | `assets/processed/relics/` |
| 玩家单位图标 | 双背景差分 + 去线 + 切分 | `image/玩家单位*.png` | `assets/processed/player_units/` |
| 敌人单位图标 | 双背景差分 + 去线 + 切分 | `image/敌人单位*.png` | `assets/processed/enemy_units/` |
| 召唤物图标 | —（当前无素材） | — | — |

**核心原则：**

1. **双背景差分法**：所有需要去除背景的图标素材，优先使用同一构图的暗底图 + 白底图逐像素对比反推透明度。
2. **显式资源引用**：处理后的 PNG 必须在对应 `.tres` 中通过 `[ext_resource]` 显式引用，代码中不再使用动态路径加载。
3. **命名顺序由 `catalog_id` 驱动**：合图中的格子顺序与 `docs/content_reference.md` 中对应表格的 `catalog_id` 排序严格一致。
4. **`.png.import` 必须提交**：所有 `assets/processed/` 下的 `.png.import` 文件必须加入版本库。

---

## 通用处理流程

### 双背景差分法原理

传统按颜色阈值去背景容易误删主体暗色区域。双背景差分法使用同一素材的暗底版本和白底版本逐像素对比：

1. 读取暗底图和白底图；
2. 根据两张图在同一像素上的颜色差异反推透明度；
3. 差异接近"背景从暗色变成白色"的区域判定为背景（透明）；
4. 差异很小的区域判定为主体，保留为不透明；
5. 对半透明边缘保留 alpha，减少硬边和锯齿。

### 处理步骤

**步骤 1：去除背景**

使用 `remove_diff_background.py` 读取暗底图和白底图，生成整张透明背景图。

**步骤 2：去除网格线（可选）**

部分合图素材带有细网格分隔线。`slice_icon_sheet.py` 会在预期网格边界附近检测整行 / 整列的低饱和度线状像素比例，将判定为分割线的行 / 列及其相邻 1 像素透明化。

**步骤 3：切分单图**

`slice_icon_sheet.py` 按理论网格计算预期分割线位置，在边界前后 24 像素范围内选择切割线：

- 优先级 1：已标记分割线且为纯透明空白；
- 优先级 2：已标记分割线相邻行 / 列且为空白；
- 优先级 3：任意空白行 / 列；
- 优先级 4：非透明像素最少的位置。

切分后填充到统一尺寸画布，再根据 alpha 包围盒自动居中，输出单个 PNG。

### Python 脚本工具链

```text
tools/art/remove_diff_background.py   # 步骤 1：双背景差分去背景
tools/art/slice_icon_sheet.py         # 步骤 2+3：去线、切分、居中
```

**去除背景命令模板：**

```bash
uv run --with pillow python tools/art/remove_diff_background.py \
  --dark image/{暗底图}.png \
  --light image/{白底图}.png \
  --output image/{透明背景图}.png
```

**切分单图命令模板：**

```bash
uv run --with pillow python tools/art/slice_icon_sheet.py \
  --input image/{透明背景图}.png \
  --output-dir assets/processed/{目标目录} \
  --cols 4 --rows 4 \
  --names-file tools/art/{命名清单}.txt \
  --cleaned-output image/{去线后整图}.png
```

### 命名清单文件

切分前需准备 UTF-8 文本文件，每行一个输出 ID（不带扩展名），顺序对应合图中的格子顺序（从左到右、从上到下）。

**ID 顺序来源**：`docs/content_reference.md` 中对应素材类型的表格，按 `catalog_id` 排序。例如"遗物"表格中 `catalog_id = 1` 对应合图左上角第一个格子，`catalog_id = 2` 对应第二个格子，以此类推。

命名清单示例（`tools/art/enemy_names_1_16.txt`）：

```text
enemy_boss_goblin_high_priest
enemy_boss_crystal_cannon
enemy_boss_earthbreaker_colossus
...
```

---

## 各素材类型配置

### 背景图

**概述**：不做透明处理，直接复制并重命名。

**输入文件**（`image/`，中文展示名）：

```text
草地背景图1.png
草地背景图2.png
森林背景图1.png
森林背景图2.png
魔法森林背景图1.png
魔法森林背景图2.png
魔法森林背景图3.png
雪原背景图1.png
雪原背景图2.png
沙漠背景图1.png
沙漠背景图2.png
墓园背景图1.png
墓园背景图2.png
火山背景图1.png
火山背景图2.png
沼泽背景图1.png
沼泽背景图2.png
```

**输出位置**：`assets/game/ui/backgrounds/`（英文稳定文件名）。

**处理流程**：

1. 从 `image/` 复制到 `assets/game/ui/backgrounds/`；
2. 使用英文稳定文件名重命名；
3. 在 `scripts/ui/background_catalog.gd` 的 `BACKGROUNDS` 数组中增加/更新记录。

**游戏接入**：`BackgroundCatalog.BACKGROUNDS` 同时保存 `name`（中文名）和 `path`（Godot 资源路径）。主菜单和战斗棋盘共用该列表。

**后续维护建议**：

- 替换背景时保持中文源文件名不变；
- 新增背景时同步补充英文文件名和 `BACKGROUNDS` 记录；
- 不适合游戏的背景可从列表移除，不必删除源图片。

---

### 遗物图标

**输入文件**：

```text
image/遗物1-16.png              image/遗物1-16白色背景.png
image/遗物17-32.png             image/遗物17-32白色背景.png
image/遗物33-43.png             image/遗物33-43白色背景.png
```

第三张图只使用前 11 个有效格子，对应总计 43 个遗物。

**输出位置**：`assets/processed/relics/`

**输出文件名**：使用遗物 ID，如 `crown_of_three.png`、`golden_charm.png`。

**命名清单**：需创建 `tools/art/relic_names_1_16.txt`、`tools/art/relic_names_17_32.txt`、`tools/art/relic_names_33_43.txt`，ID 顺序从 `docs/content_reference.md` 的"遗物"表格按 `catalog_id` 获取。

**脚本调用**：

```bash
# 1-16
uv run --with pillow python tools/art/remove_diff_background.py \
  --dark image/遗物1-16.png \
  --light image/遗物1-16白色背景.png \
  --output image/遗物1-16透明背景.png

uv run --with pillow python tools/art/slice_icon_sheet.py \
  --input image/遗物1-16透明背景.png \
  --output-dir assets/processed/relics \
  --cols 4 --rows 4 \
  --names-file tools/art/relic_names_1_16.txt \
  --cleaned-output image/遗物1-16透明背景_去线.png

# 17-32（同上，替换文件名和清单）
# 33-43（同上，替换文件名和清单）
```

脚本同时生成 `assets/processed/relics/relic_icon_manifest.csv`（记录遗物序号、relic_id、来源图、原始格子编号）。

**游戏接入**：每个 `data/relics/*.tres` 显式引用 `assets/processed/relics/{relic_id}.png`，配置 `icon_texture = ExtResource("2_icon")`。

**后续维护建议**：

- 新增遗物后先在 `.tres` 中追加 `catalog_id`，再重新生成 `content_reference.md` 并重跑脚本；
- 超过 43 个时继续追加下一张合图并创建新的命名清单；
- 边缘残留优先检查两张输入图是否对齐，而非调高阈值。

---

### 玩家单位图标

**输入文件**：

```text
image/玩家单位1-16黑色背景.png      image/玩家单位1-16白色背景.png
image/玩家单位17-30黑色背景.png     image/玩家单位17-30白色背景.png
```

第二张图只使用前 14 个有效格子，对应总计 30 个玩家单位。

**输出位置**：`assets/processed/player_units/`

**输出文件名**：使用单位 ID，如 `necromancer.png`、`warrior.png`。

**命名清单**：需创建 `tools/art/player_unit_names_1_16.txt`、`tools/art/player_unit_names_17_30.txt`，ID 顺序从 `docs/content_reference.md` 的"玩家单位"表格按 `catalog_id` 获取。

**脚本调用**：

```bash
# 1-16
uv run --with pillow python tools/art/remove_diff_background.py \
  --dark image/玩家单位1-16黑色背景.png \
  --light image/玩家单位1-16白色背景.png \
  --output image/玩家单位1-16透明背景.png

uv run --with pillow python tools/art/slice_icon_sheet.py \
  --input image/玩家单位1-16透明背景.png \
  --output-dir assets/processed/player_units \
  --cols 4 --rows 4 \
  --names-file tools/art/player_unit_names_1_16.txt \
  --cleaned-output image/玩家单位1-16透明背景_去线.png

# 17-30（同上，替换文件名和清单）
```

脚本同时生成 `player_unit_icon_manifest.csv` 和 `player_unit_grid_scan.csv`。

**游戏接入**：每个 `data/units/*.tres` 显式引用 `assets/processed/player_units/{unit_type}.png`，配置 `board_sprite` / `portrait_texture` / `icon_texture`。

**后续维护建议**：

- 超过 30 个时追加下一组合图并创建新的命名清单；
- 网格线残留优先调整线状像素检测阈值；
- 切分位置不正确优先检查 `grid_scan.csv`；
- 主体偏心检查素材是否在原始格子中被裁掉。

---

### 敌人单位图标

**输入文件**：

```text
image/敌人单位1-16黑色背景.png      image/敌人单位1-16白色背景.png
image/敌人单位17-32黑色背景.png     image/敌人单位17-32白色背景.png
```

`training_dummy` (catalog_id = 0) 不参与切图。

**输出位置**：`assets/processed/enemy_units/`

**输出文件名**：使用单位 ID，如 `enemy_common_slime.png`。

**命名清单**：

```text
tools/art/enemy_names_1_16.txt
tools/art/enemy_names_17_32.txt
```

ID 顺序从 `docs/content_reference.md` 的"敌方单位"表格按 `catalog_id` 获取。

**脚本调用**：

```bash
# 1-16
uv run --with pillow python tools/art/remove_diff_background.py \
  --dark image/敌人单位1-16黑色背景.png \
  --light image/敌人单位1-16白色背景.png \
  --output image/敌人单位1-16透明背景.png

uv run --with pillow python tools/art/slice_icon_sheet.py \
  --input image/敌人单位1-16透明背景.png \
  --output-dir assets/processed/enemy_units \
  --cols 4 --rows 4 \
  --names-file tools/art/enemy_names_1_16.txt \
  --cleaned-output image/敌人单位1-16透明背景_去线.png

# 17-32（同上，替换文件名和清单）
```

脚本同时生成 `icon_manifest.csv` 和 `grid_scan.csv`。

**游戏接入**：每个 `data/enemies/*.tres` 显式引用 `assets/processed/enemy_units/{unit_type}.png`，配置 `board_sprite` / `portrait_texture` / `icon_texture`。

**后续维护建议**：

- 超过 32 个时追加下一组合图并创建新的命名清单；
- 映射顺序必须严格与 `content_reference.md` 一致；
- `.png.import` 必须提交到版本库。

---

### 召唤物图标

**当前状态**：无专用美术素材。`data/summons/` 下所有 `.tres` 均未配置贴图字段，战场上通过 `unit.gd` 的 `body` ColorRect 显示占位方块。

**预留规范**：

如需新增召唤物素材：

1. 准备召唤物合图（参照玩家单位 / 敌人单位的双背景差分规范）；
2. 使用 `remove_diff_background.py` + `slice_icon_sheet.py` 处理；
3. 创建命名清单文件，ID 顺序从 `docs/content_reference.md` 的"召唤物"表格按 `catalog_id` 获取；
4. 输出到 `assets/processed/summon_units/`（或复用现有目录）；
5. 在 `data/summons/*.tres` 中显式引用对应 PNG；
6. 运行 `--headless --import` 生成 `.png.import`；
7. 提交 `.png.import` 到版本库。

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

- **不要在 `assets/processed/` 根目录放 `.gdignore`**，否则子目录下的 PNG 不会被 Godot 导入/导出；
- 当前只保留 `assets/processed/ui/.gdignore`，用于忽略旧 UI 处理输出；
- **`.png.import` 文件必须提交到版本库**：
  - `assets/processed/player_units/*.png.import`
  - `assets/processed/enemy_units/*.png.import`
  - `assets/processed/relics/*.png.import`
  - `assets/game/ui/backgrounds/*.png.import`（如有新增）
- 它们记录 Godot 纹理导入目标，缺失时干净环境或导出包可能无法加载对应贴图。

### 导入与导出命令

修改或新增 PNG 后，先执行资源导入，再导出正式包：

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
