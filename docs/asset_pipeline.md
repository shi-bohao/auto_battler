# 素材处理流程

更新时间：2026-05-31

本文档记录当前项目中美术素材的预处理方式，重点用于遗物、单位图标等需要去除背景并输出透明 PNG 的素材。

## 背景图导入

当前主菜单和战斗场景共用同一套背景图库。背景图不做透明背景处理，直接从 `image/` 复制到稳定资源目录，再通过统一目录配置接入游戏。

### 输入文件命名

当前背景源文件位于：

```text
image/
```

命名使用中文展示名，格式为：

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

### 输出位置

背景图复制到：

```text
assets/game/ui/backgrounds/
```

资源文件使用英文稳定文件名，例如：

```text
assets/game/ui/backgrounds/grass_background_1.png
assets/game/ui/backgrounds/forest_background_2.png
assets/game/ui/backgrounds/magic_forest_background_3.png
```

### 游戏接入

背景列表统一维护在：

```text
scripts/ui/background_catalog.gd
```

`BackgroundCatalog.BACKGROUNDS` 同时保存：

- `name`：游戏内列表显示的中文名；
- `path`：Godot 资源路径。

主菜单和战斗棋盘都读取该目录：

- 主菜单：`scripts/ui/menu_panel_controller.gd` 创建背景下拉列表，选择后更新主菜单背景；
- 战斗棋盘：`scripts/battle_board.gd` 读取同一批 texture 和中文名，用于战斗/备战阶段背景选择；
- 流程协调：`scripts/main.gd` 负责把主菜单选择同步到 `BattleBoard`。

### 导入检查

新增或替换背景后，在项目根目录执行：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\background_import.log --import
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\background_catalog_check.log --check-only --script res://scripts/ui/background_catalog.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\menu_background_selector_check.log --check-only --script res://scripts/ui/menu_panel_controller.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\battle_board_background_check.log --check-only --script res://scripts/battle_board.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\main_background_check.log --check-only --script res://scripts/main.gd
```

### 后续维护建议

- 替换现有背景时，保持中文源文件名不变，只更新图片内容即可；
- 新增背景时，同时补充复制到 `assets/game/ui/backgrounds/` 的英文文件名，并在 `BackgroundCatalog.BACKGROUNDS` 增加一条记录；
- 如果某张背景不适合游戏，可以从 `BackgroundCatalog.BACKGROUNDS` 移除，不必删除源图片；
- 主菜单和战斗场景必须共用 `BackgroundCatalog`，不要在两个场景里各自维护一份列表。

## 遗物图标处理

当前遗物图标采用“双背景差分”方式进行透明背景处理。

### 适用场景

适用于以下情况：

- 同一批素材可以导出两份完全同尺寸、完全同构图的图片；
- 一份使用暗色背景；
- 一份使用白色背景；
- 希望只去除背景，尽量保留主体暗部、发光、阴影和边缘细节。

### 原理

传统按颜色阈值去背景容易误删主体暗色区域，例如黑色金属、阴影、深色描边。

当前流程使用同一素材的暗底版本和白底版本逐像素对比：

1. 读取暗底图和白底图；
2. 根据两张图在同一像素上的颜色差异，反推该像素的透明度；
3. 差异接近“背景从暗色变成白色”的区域判定为背景；
4. 两张图差异很小的区域判定为主体，保留为不透明；
5. 对半透明边缘保留 alpha，减少硬边和锯齿。

这个方法比单纯删除黑色或白色背景更可靠，后续同类素材优先使用该方式。

### 输入文件命名

当前遗物素材位于：

```text
image/
```

脚本默认读取以下三组文件：

```text
image/遗物1-16.png
image/遗物1-16白色背景.png

image/遗物17-32.png
image/遗物17-32白色背景.png

image/遗物33-43.png
image/遗物33-43白色背景.png
```

要求：

- 每组暗底图和白底图尺寸必须一致；
- 每组暗底图和白底图的图标位置必须一致；
- 每张遗物图按 4 x 4 网格切分；
- 遗物顺序使用 `docs/content_reference.md` 中“遗物”表格的顺序；
- 当前第三张图只使用前 11 个有效格子，对应总计 43 个遗物。

### 输出位置

处理后的透明 PNG 输出到：

```text
assets/processed/relics/
```

输出文件名使用遗物 ID，例如：

```text
assets/processed/relics/crown_of_three.png
assets/processed/relics/golden_charm.png
```

脚本同时生成映射清单：

```text
assets/processed/relics/relic_icon_manifest.csv
```

清单记录：

- 遗物序号；
- relic_id；
- 暗底来源图；
- 白底来源图；
- 原始格子编号。

### 脚本路径

```text
tools/process_relic_icons_diff.ps1
```

### 调用方式

在项目根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools\process_relic_icons_diff.ps1
```

也可以指定路径：

```powershell
powershell -ExecutionPolicy Bypass -File tools\process_relic_icons_diff.ps1 `
  -ImageDir image `
  -OutputDir assets/processed/relics `
  -ContentDoc docs/content_reference.md
```

### 后续维护建议

- 新增遗物后，先更新 `docs/content_reference.md` 中的遗物顺序，再重跑脚本；
- 如果遗物数量超过当前图片容量，继续追加下一张 `遗物44-59.png` 和对应白底图，并扩展脚本中的 `$sheetPairs`；
- 不建议再使用单背景颜色阈值法处理图标；
- 如果主体边缘仍有背景残留，优先检查两张输入图是否完全对齐，而不是先调高删除阈值。

## 玩家单位图标处理

玩家单位图标同样使用“双背景差分”方式处理，并额外清除素材图中的细网格分隔线。

### 输入文件命名

当前玩家单位素材位于：

```text
image/
```

脚本默认读取以下两组文件：

```text
image/玩家单位1-16黑色背景.png
image/玩家单位1-16白色背景.png

image/玩家单位17-30黑色背景.png
image/玩家单位17-30白色背景.png
```

要求：

- 每组黑底图和白底图尺寸必须一致；
- 每组黑底图和白底图的单位位置必须一致；
- 每张图按 4 x 4 网格切分；
- 第二张图只使用前 14 个有效格子，对应总计 30 个玩家单位；
- 单位命名顺序使用 `docs/content_reference.md` 中“玩家单位”表格的顺序；
- 素材中的细网格线会在整图和单图输出中一起移除；
- 去除网格线时，脚本会先完成双背景差分，再在预期网格边界附近检测整行 / 整列的低饱和度线状像素比例；
- 被判定为分割线的行 / 列会和相邻 1 像素一起透明化，用于处理细线残留；
- 单图切分时优先从第一步检测出的分割线中选择切割边界，并要求切割线已经是纯透明空白；
- 如果检测出的分割线不满足空白条件，脚本会在理论边界附近微调，寻找最近的空白行 / 列；
- 如果附近没有纯空白行 / 列，则选择非透明像素最少的位置作为兜底切割线；
- 单图切分后会先填充到统一尺寸画布，再根据 alpha 包围盒自动居中，减少素材主体轻微偏离中心的问题。

### 处理流程

脚本路径：

```text
tools/process_player_unit_icons_diff.ps1
```

当前玩家单位图标处理流程如下：

1. 读取同一素材的黑底图和白底图。
2. 根据两张图的像素差异反推透明度，生成整张透明背景图。
3. 按 4 x 4 理论网格计算预期分割线位置。
4. 在每条理论分割线前后 16 像素范围内逐行 / 逐列扫描。
5. 统计每条候选行 / 列的非透明像素、线状像素、主导颜色桶等信息。
6. 将扫描记录写入 `player_unit_grid_scan.csv`。
7. 完整扫描结束后，统一抹除被标记的分割线及其相邻 1 像素行 / 列。
8. 保存整张去背景、去分割线后的透明图到 `image/`。
9. 切分单图时，从理论边界前后 24 像素范围内选择切割线。
10. 切割线选择优先级为：已标记分割线且空白、已标记分割线相邻行 / 列且空白、任意空白行 / 列、非透明像素最少的位置。
11. 将切分结果填充到统一尺寸画布。
12. 根据主体 alpha 包围盒居中，输出单个单位 PNG。

### 输出位置

单个玩家单位透明 PNG 输出到：

```text
assets/processed/player_units/
```

输出文件名使用单位 ID，例如：

```text
assets/processed/player_units/necromancer.png
assets/processed/player_units/warrior.png
```

脚本同时生成映射清单：

```text
assets/processed/player_units/player_unit_icon_manifest.csv
```

脚本还会生成分割线扫描记录，便于后续排查残留线或误删问题：

```text
assets/processed/player_units/player_unit_grid_scan.csv
```

该记录包含：

- 来源素材名；
- 扫描方向，`row` 或 `column`；
- 对应理论边界编号；
- 实际扫描行 / 列坐标；
- 非透明像素数量；
- 线状像素数量；
- 主导颜色桶；
- 是否判定为需要抹除。

整张去背景、去网格线后的透明图保存回 `image/`：

```text
image/玩家单位1-16透明背景.png
image/玩家单位17-30透明背景.png
```

### 脚本路径

```text
tools/process_player_unit_icons_diff.ps1
```

### 调用方式

在项目根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File tools\process_player_unit_icons_diff.ps1
```

也可以指定路径：

```powershell
powershell -ExecutionPolicy Bypass -File tools\process_player_unit_icons_diff.ps1 `
  -ImageDir image `
  -OutputDir assets/processed/player_units `
  -ContentDoc docs/content_reference.md
```

### 后续维护建议

- 新增玩家单位后，先更新 `docs/content_reference.md` 中的玩家单位顺序，再重跑脚本；
- 如果玩家单位数量超过 30，继续追加下一组黑底/白底素材，并扩展脚本中的 `$sheetPairs`；
- 如果网格线仍有残留，优先调整脚本中的整行 / 整列线状像素检测阈值；
- 如果切分位置不正确，优先检查 `player_unit_grid_scan.csv` 中对应理论边界附近是否存在已标记且空白的候选行 / 列；
- 如果单位主体仍明显偏心，检查素材是否在原始格子中被裁掉，脚本只能对切分后仍存在的主体做自动居中。

## 游戏内接入与导出注意事项

当前项目采用和英雄素材一致的显式资源引用方式：

- 玩家单位：`data/units/*.tres` 中的 `board_sprite`、`portrait_texture`、`icon_texture` 直接引用 `assets/processed/player_units/*.png`。
- 遗物：`RelicData` 提供 `icon_texture: Texture2D` 字段，`data/relics/*.tres` 直接引用 `assets/processed/relics/*.png`。
- 运行时 helper 只作为兜底：`UnitArtHelper` 和 `RelicIconHelper` 优先读取数据资源中配置的贴图；动态路径加载仅用于缺字段或旧资源兼容。

导出相关规则：

- 不要在 `assets/processed/` 根目录放 `.gdignore`，否则玩家单位和遗物图标不会被 Godot 导入/导出。
- 当前只保留 `assets/processed/ui/.gdignore`，用于忽略旧 UI 处理输出。
- `assets/processed/player_units/*.png.import` 和 `assets/processed/relics/*.png.import` 必须提交到版本库。它们记录 Godot 纹理导入目标，缺失时干净环境或导出包可能无法加载对应贴图。
- 修改或新增处理后 PNG 后，先执行一次资源导入，再导出正式包：

```powershell
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\asset_import.log --import
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\export.log --export-release "Windows Desktop" ..\auto_battler_output\auto_battler.exe
```

如果导出程序启动后立即退出，优先运行 console wrapper 查看日志：

```powershell
..\auto_battler_output\auto_battler.console.exe --log-file ..\auto_battler_output\run_console.log
```

常见资源错误为 `No loader found for resource: res://assets/processed/...png`，通常表示 PNG 被 `.gdignore` 排除、`.png.import` 未提交，或导出包不是当前资源状态重新导出的版本。
