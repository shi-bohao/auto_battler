# 素材处理流程

更新时间：2026-06-03

## 目录

- [规范总览](#规范总览)
- [通用处理流程](#通用处理流程)
- [各素材类型](#各素材类型)
- [游戏内接入与导出注意事项](#游戏内接入与导出注意事项)

---

## 规范总览

| 素材类型 | 处理方式 | 输入位置 | 输出位置 | 状态 |
|---------|---------|---------|---------|------|
| 背景图 | 直接复制 | `image/背景图*.png` | `assets/game/ui/backgrounds/` | 已接入 |
| 遗物图标 | 双背景差分 + 切分 | `image/遗物*.png` | `assets/processed/relics/` | 已接入 |
| 玩家单位图标 | 双背景差分 + 去线 + 切分 | `image/玩家单位*.png` | `assets/processed/player_units/` | 已接入 |
| 敌人单位图标 | 双背景差分 + 去线 + 切分 | `image/敌人单位*.png` | `assets/processed/enemy_units/` | 已接入 |
| 召唤物图标 | — | — | — | 当前无素材 |

**核心原则：**

1. **显式资源引用**：处理后的 PNG 必须在对应 `.tres` 中通过 `[ext_resource]` 显式引用，代码中不再使用动态路径加载。
2. **`.png.import` 必须提交**：所有 `assets/processed/` 下的 `.png.import` 文件必须加入版本库。

---

## 通用处理流程

### 双背景差分法原理

使用同一构图的暗底图 + 白底图逐像素对比反推透明度：差异接近"背景从暗色变成白色"的区域判定为背景（透明），差异很小的区域判定为主体（保留）。对半透明边缘保留 alpha，减少硬边和锯齿。

### 处理步骤

1. **去除背景**：`remove_diff_background.py` 读取暗底图和白底图，生成整张透明背景图。
2. **去除网格线（可选）**：`slice_icon_sheet.py` 检测整行 / 整列的低饱和度线状像素并透明化。
3. **切分单图**：按理论网格边界前后 24 像素范围选择最优切割线（空白优先），填充到统一尺寸画布，根据 alpha 包围盒居中输出。

### Python 脚本工具链

```text
tools/art/remove_diff_background.py   # 步骤 1
tools/art/slice_icon_sheet.py         # 步骤 2+3
```

**去背景命令模板：**

```bash
uv run --with pillow python tools/art/remove_diff_background.py \
  --dark image/{暗底图}.png \
  --light image/{白底图}.png \
  --output image/{透明背景图}.png
```

**切分命令模板：**

```bash
uv run --with pillow python tools/art/slice_icon_sheet.py \
  --input image/{透明背景图}.png \
  --output-dir assets/processed/{目标目录} \
  --cols 4 --rows 4 \
  --names-file tools/art/{命名清单}.txt \
  --cleaned-output image/{去线后整图}.png
```

### 命名清单文件

切分前需创建 UTF-8 文本文件，每行一个 ID（不带扩展名），顺序对应合图格子（从左到右、从上到下）。

**ID 顺序来源**：`docs/content_reference.md` 中对应素材类型的表格，按 `catalog_id` 排序。

---

## 各素材类型

### 背景图

直接从 `image/` 复制到 `assets/game/ui/backgrounds/`，使用英文稳定文件名重命名，并在 `scripts/ui/background_catalog.gd` 的 `BACKGROUNDS` 数组中登记。

源文件使用中文展示名，如 `草地背景图1.png`、`火山背景图2.png`。

---

### 图标素材参数对照

以下三类图标素材共用同一套 Python 处理流程，仅在输入文件、输出目录、命名清单上有差异：

| 参数 | 遗物 | 玩家单位 | 敌人单位 |
|------|------|---------|---------|
| **输入暗底** | `image/遗物1-16.png` | `image/玩家单位1-16黑色背景.png` | `image/敌人单位1-16黑色背景.png` |
| **输入白底** | `image/遗物1-16白色背景.png` | `image/玩家单位1-16白色背景.png` | `image/敌人单位1-16白色背景.png` |
| **输出目录** | `assets/processed/relics/` | `assets/processed/player_units/` | `assets/processed/enemy_units/` |
| **命名清单** | `relic_names_*.txt` | `player_unit_names_*.txt` | `enemy_names_*.txt` |
| **合图组数** | 3 组（1-16, 17-32, 33-43） | 2 组（1-16, 17-30） | 2 组（1-16, 17-32） |
| **特殊说明** | 第三张图只用 11 格 | 第二张图只用 14 格 | `training_dummy` (catalog_id=0) 不参与 |
| **输出文件名** | `{relic_id}.png` | `{unit_type}.png` | `{unit_type}.png` |
| **清单文件** | `relic_icon_manifest.csv` | `player_unit_icon_manifest.csv` | `icon_manifest.csv` |
| **扫描记录** | — | `player_unit_grid_scan.csv` | `grid_scan.csv` |

**命名清单示例**（`tools/art/enemy_names_1_16.txt`）：

```text
enemy_boss_goblin_high_priest
enemy_boss_crystal_cannon
...
```

**`.tres` 接入字段**：

- 遗物：`icon_texture = ExtResource("2_icon")`
- 玩家单位：`board_sprite` / `portrait_texture` / `icon_texture = ExtResource("2_art")`
- 敌人单位：`board_sprite` / `portrait_texture` / `icon_texture = ExtResource("2_art")`

**后续维护**：

- 新增素材时先在 `.tres` 中追加 `catalog_id`，重新生成 `content_reference.md`，再创建命名清单并重跑脚本；
- 超出当前合图容量时追加下一组合图并扩展命名清单；
- `.png.import` 必须提交到版本库。

---

### 召唤物图标

**当前状态**：无专用素材，`data/summons/` 下 `.tres` 均未配置贴图字段，战场显示 `body` ColorRect 占位方块。

**预留规范**：如需新增，参照"图标素材参数对照"流程，输出到 `assets/processed/summon_units/`，在 `.tres` 中显式引用。

---

## 游戏内接入与导出注意事项

### 接入方式总览

| 素材类型 | `.tres` 字段 | 引用目标 |
|---------|-------------|---------|
| 玩家单位 | `board_sprite`, `portrait_texture`, `icon_texture` | `assets/processed/player_units/*.png` |
| 敌人单位 | `board_sprite`, `portrait_texture`, `icon_texture` | `assets/processed/enemy_units/*.png` |
| 英雄 | `portrait_texture` | `assets/game/heroes/*.png` |
| 遗物 | `icon_texture` | `assets/processed/relics/*.png` |
| 背景图 | `BackgroundCatalog.BACKGROUNDS[].path` | `assets/game/ui/backgrounds/*.png` |

`UnitArtHelper` 和 `RelicIconHelper` 仅保留通用尺寸调整工具，不再负责动态路径加载。

### `catalog_id` 使用规范

- 玩家单位、敌人、召唤物、英雄由 `UnitData.catalog_id` 保存；
- 遗物由 `RelicData.catalog_id` 保存；
- 仅用于稳定显示、文档和素材顺序，不替代 `unit_type`、`relic_id`、`hero_id` 等逻辑 ID。

### 导出规则

- **不要在 `assets/processed/` 根目录放 `.gdignore`**；
- 当前只保留 `assets/processed/ui/.gdignore`；
- **`.png.import` 必须提交**：`player_units/`、`enemy_units/`、`relics/` 下的全部 `.png.import`；
- 修改或新增 PNG 后，先执行 `--headless --import`，再导出正式包。

### 常用命令

```powershell
# 资源导入
Godot_v4.6.2-stable_win64_console.exe --headless --path . --import

# 导出正式包
Godot_v4.6.2-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" ..\auto_battler_output\auto_battler.exe

# 背景图变更后检查
Godot_v4.6.2-stable_win64_console.exe --headless --path . --check-only --script res://scripts/ui/background_catalog.gd
```

常见资源错误 `No loader found for resource: res://assets/processed/...png`，通常表示 PNG 被 `.gdignore` 排除、`.png.import` 未提交，或导出包不是当前资源状态重新导出的版本。
