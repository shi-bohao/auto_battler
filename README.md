# Auto_Battler

Godot 4.6 / GDScript 制作的 2D 肉鸽自走棋原型。

当前项目已经从单场自动战斗扩展为一套可玩的局内循环：主菜单、英雄选择、准备阶段、自动战斗、奖励、路径选择、商人、训练、事件、宝箱、Boss、图鉴和镜像挑战都已接入。项目仍处于 Demo / 原型阶段，重点是验证自动战斗、阵容成长、遗物和局内构筑。

## 当前内容

- 游戏模式：普通模式、镜像挑战。
- 回合结构：30 波推进，Boss 轮为第 10 / 20 / 30 波。
- 路径节点：普通战斗、精英战斗、商人、训练场、随机事件、宝箱。
- 当前内容规模：32 个玩家单位、4 个英雄、33 个敌方单位、8 个召唤物、43 个遗物。
- 战斗系统：自动索敌、近战即时命中、远程普攻弹道、圆形/矩形/扇形瞬时 AoE、持续场地效果、战斗加速、60 秒加时赛。
- 成长系统：单位购买、上阵、备战、出售、升星、单位解锁、奖励三选一、幸运值影响奖励稀有度、英雄经验与强化、局内永久属性成长。
- 构筑系统：遗物、动态金币光环、常驻光环、击杀/死亡/攻击/战斗开始/胜利结算触发、6 类羁绊、召唤机制、Buff/Debuff 堆叠与持续时间策略。
- 信息系统：图鉴、单位详情、遗物详情、羁绊详情、战斗统计、Boss 阵容快照。
- 美术与 UI：主菜单和战斗场景共用可切换背景列表、渲染式棋盘/备战席网格、英雄头像/立绘/棋盘图标、玩家单位图标、遗物图标、代码生成的统一像素风 UI；玩家单位和遗物图标已改为数据资源显式引用，导出时需要保留对应 `.png.import` 文件。

## 当前未纳入范围

以下内容不是当前 Demo 的真实功能，不应在文档或 README 中描述为已完成：

- 持久化存档系统。
- 装备背包或英雄装备。
- 战斗回放。
- 多人或联网同步。
- 完整路线地图表现；当前实现是波次之间的三选一路径节点。
- 完整动作动画与精灵图动画；当前单位和英雄主要使用静态 PNG 图标配合简单变形/闪烁表现。

## 运行方式

使用 Godot 4.6.2 stable 打开项目根目录，主场景为：

```text
res://scenes/main.tscn
```

也可以从命令行启动：

```text
Godot_v4.6.2-stable_win64_console.exe --path .
```

## 常用检查

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file main_check.log --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file content_reference.log --script res://scripts/tools/generate_content_reference.gd
```

Windows 下 `--log-file` 建议写入当前目录，或使用 `./logs/name.log` 这类正斜杠相对路径。避免 `logs\name.log` 这类反斜杠子目录路径；该写法即使退出码为 0，也可能额外输出 `Could not create directory: 'user://C:'`。

## 文档入口

- [docs/README.md](docs/README.md)：文档目录、维护规则和已移除旧文档说明。
- [docs/project_status.md](docs/project_status.md)：当前项目状态、系统范围、目录结构和近期更新。
- [docs/content_reference.md](docs/content_reference.md)：当前单位、英雄、敌人、召唤物和遗物数据总览，可由工具脚本重新生成。
- [docs/archive/feature_design_log.md](docs/archive/feature_design_log.md)：早期功能设计记录归档；当前状态以 `project_status.md` 和各 `docs/systems/*.md` 为准。

## Git 忽略

项目已忽略 Godot 本地缓存、用户日志和本地编辑器配置：

```text
.godot/
.godot_user/
*.log
.claude/
.vscode/
```

`.uid`、`.tres`、场景文件、脚本和导入后的资源元数据需要提交，以保证 Godot 资源引用稳定。
