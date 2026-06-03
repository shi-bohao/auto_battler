# 通用美术素材处理脚本

本目录保存通用图标素材处理脚本。后续遗物、玩家单位、敌人、召唤物等同类素材都优先使用这一套流程，不再按素材类型维护多份重复脚本。

## 脚本列表

- `remove_diff_background.py`：根据同一素材的深色背景图和浅色背景图进行差分去背景，输出透明背景整图。
- `slice_icon_sheet.py`：对透明背景整图进行分割线检测与去除，然后按网格切图、统一画布、主体自动居中。

两个脚本都依赖 Pillow：

```powershell
python -m pip install Pillow
```

如果当前环境没有直接暴露 `python` 命令，也可以使用项目里常用的 `uv`：

```powershell
uv run --with pillow python tools\art\remove_diff_background.py --help
uv run --with pillow python tools\art\slice_icon_sheet.py --help
```

## 推荐流程

```text
黑底图 + 白底图
        ↓
remove_diff_background.py
        ↓
透明背景整图
        ↓
slice_icon_sheet.py
        ↓
单个透明 PNG 图标
```

## 第一步：差分去背景

示例：

```powershell
uv run --with pillow python tools\art\remove_diff_background.py `
  --dark image\玩家单位1-16黑色背景.png `
  --light image\玩家单位1-16白色背景.png `
  --output image\玩家单位1-16透明背景.png
```

常用参数：

- `--dark`：深色背景版本。
- `--light`：浅色背景版本。
- `--output`：输出透明 PNG。
- `--diff-bucket-size`：统计深浅图像素差值时的量化桶大小，默认 `4`。
- `--min-background-diff`：寻找背景主峰时忽略过小差值，默认 `24`。
- `--background-diff-tolerance`：筛选背景候选像素时允许的单通道差值误差，默认 `10`。
- `--solid-diff-threshold`：深浅图差异很小时视为主体并保留不透明，默认 `14`。
- `--corner-inset`：全图差值法失败时，四角兜底取样避开边缘的像素距离，默认 `8`。

输入要求：

- 两张图尺寸完全一致；
- 两张图内主体位置完全一致；
- 背景颜色不同，主体内容相同；
- 优先使用黑底 / 白底组合。

### 差分去背景逻辑

新版 `remove_diff_background.py` 默认不再直接从四角取背景色，而是先全图统计深浅图差值：

1. 读取深色背景图和浅色背景图；
2. 对每个像素计算 `light - dark` 的 RGB 差值；
3. 忽略差值过小的主体区域；
4. 对剩余差值做量化统计，找出出现最多的背景差值主峰；
5. 根据该主峰筛选背景候选像素；
6. 从候选像素中分别提取深色图背景色、浅色图背景色和真实背景差值；
7. 使用背景差值计算每个像素的透明度；
8. 将 alpha 取整到 `0-255` 后，再反推主体原始 RGB，减少半透明边缘的浮点误差。

如果全图差值法找不到足够的背景候选像素，脚本才会退回四角中位数取样作为兜底。

## 第二步：去分割线并切图

示例：

```powershell
uv run --with pillow python tools\art\slice_icon_sheet.py `
  --input image\玩家单位1-16透明背景.png `
  --output-dir assets\processed\player_units `
  --cols 4 `
  --rows 4 `
  --names-file tools\art\player_unit_names_1_16.txt `
  --cleaned-output image\玩家单位1-16透明背景_去线.png
```

如果不提供名称文件，会使用 `--prefix` 和 `--start-index` 自动命名：

```powershell
uv run --with pillow python tools\art\slice_icon_sheet.py `
  --input image\遗物1-16透明背景.png `
  --output-dir assets\processed\relics `
  --cols 4 `
  --rows 4 `
  --prefix relic `
  --start-index 1
```

常用参数：

- `--input`：透明背景整图。
- `--output-dir`：单图输出目录。
- `--cols` / `--rows`：网格列数与行数，默认 `4 x 4`。
- `--names-file`：每行一个输出文件名，不需要写 `.png`。
- `--max-items`：只输出前 N 个格子，适合最后一张素材不足 16 个图标的情况。
- `--cleaned-output`：保存去除分割线后的整张透明图。
- `--manifest-output`：自定义输出清单 CSV 路径，默认在输出目录生成 `icon_manifest.csv`。
- `--grid-scan-output`：自定义分割线扫描记录 CSV 路径，默认在输出目录生成 `grid_scan.csv`。
- `--output-size`：指定最终画布尺寸，例如 `96` 或 `128x128`。
- `--no-center`：关闭主体自动居中。

## 分割线处理逻辑

`slice_icon_sheet.py` 会先按理论网格位置寻找分割线，而不是直接按固定坐标硬切。

处理顺序：

1. 根据 `rows / cols` 计算理论分割线；
2. 在理论分割线附近 `--scan-radius` 范围内逐行 / 逐列扫描；
3. 统计非透明像素、低饱和线状像素、主导颜色桶；
4. 标记疑似分割线；
5. 统一清除被标记的行 / 列，以及 `--clear-neighbor-radius` 指定范围内的相邻行 / 列；
6. 切图时优先选择已经被清理为空白的标记线；
7. 如果附近没有纯空白线，则选择非透明像素最少的位置作为兜底切割线。

扫描结果会写入 `grid_scan.csv`，用于排查残留分割线或误删问题。

## 命名文件格式

`--names-file` 使用 UTF-8 文本文件，每行一个输出文件名：

```text
warrior
archer
mage
tank
```

规则：

- 空行会被忽略；
- 以 `#` 开头的行会被忽略；
- 可以写 `warrior.png`，脚本会自动取文件主名 `warrior`；
- 文件名顺序必须与素材格子顺序一致，按从左到右、从上到下读取。

## 注意事项

- 本工具只负责素材预处理，不会自动修改 Godot 的 `.tres` 引用。
- 输出到 `assets/processed/...` 后，需要让 Godot 重新导入资源。
- 如果素材存在细分割线，优先调大 `--clear-neighbor-radius` 或 `--scan-radius`。
- 如果主体被误删，优先降低分割线检测强度，或检查素材是否在分割线附近贴得过近。
- 如果主体偏心，保持默认自动居中；只有需要保留原始构图时才使用 `--no-center`。
