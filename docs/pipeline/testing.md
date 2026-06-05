# 测试与验证

更新时间：2026-06-05

本文档记录项目测试策略、测试脚本清单和常用验证命令。

## 测试脚本清单

当前 `scripts/tests/` 下共 **29 个 `.gd` 测试脚本**：

### 系统测试

| 脚本 | 覆盖范围 |
| --- | --- |
| `test_stat_modifier_system.gd` | 属性修饰器层级结算、金币动态光环重算 |
| `test_bond_manager.gd` | 羁绊统计、档位效果、战斗事件接入 |
| `test_control_effect_system.gd` | 控制效果施加、状态聚合、边界情况 |
| `test_status_effect_stack_policy.gd` | 叠层策略（堆叠/刷新/替换/延长） |
| `test_summon_system.gd` | 召唤上限、分裂继承、胜负判定 |
| `test_kill_relics.gd` | 击杀遗物触发、金币结算 |
| `test_extended_unit_attributes.gd` | 扩展属性遗物（技能强度/治疗/护盾/穿透等） |
| `test_hero_manager.gd` | 英雄选择、经验升级、强化池 |
| `test_hero_battle_spawn.gd` | 英雄战斗生成、站位、属性 |
| `test_hero_position_reservation.gd` | 英雄准备阶段站位调整 |
| `test_hero_exclusive_unit_pool.gd` | 英雄专属单位池、开局阵容、可用单位过滤 |
| `test_reward_rarity_roll.gd` | 奖励稀有度概率、波次成长、遭遇加成、幸运值修正 |
| `test_reward_stat_rewards.gd` | 五类属性奖励、五档稀有度数值、幸运奖励应用 |
| `test_reward_dynamic_unit_pool.gd` | 奖励单位池动态生成、随机单位、满阵容过滤 |
| `test_reward_hero_exclusive_integration.gd` | 真实 `RosterManager`/`RewardManager` 下的英雄专属单位奖励过滤 |
| `test_lineup_snapshot_manager.gd` | 快照保存/加载/还原 |
| `test_mirror_challenge_manager.gd` | 镜像选择规则、阵容镜像 |
| `test_battle_time_manager.gd` | 战斗时间缩放、加时赛 |

### 敌人测试

| 脚本 | 覆盖范围 |
| --- | --- |
| `test_slime_enemies.gd` | 史莱姆系列（5种）：资源加载、技能、分裂、死亡场地 |
| `test_boss_units.gd` | 新增 BOSS（5 种）：技能、被动、召唤、场地效果 |
| `test_elite_enemies.gd` | 新增精英敌人（4 种）：技能、被动、反射 |

### UI/素材测试

| 脚本 | 覆盖范围 |
| --- | --- |
| `test_unit_detail_panel_ui.gd` | 单位详情面板 |
| `test_encyclopedia_catalog.gd` | 图鉴目录、内容加载 |
| `test_unit_art_helper.gd` | 单位素材加载、兜底 |
| `test_relic_icon_helper.gd` | 遗物图标加载 |
| `test_unit_hp_bar_team_color.gd` | 血条颜色（己方绿/敌方红） |

### 高稀有度单位

| 脚本 | 覆盖范围 |
| --- | --- |
| `test_high_rarity_units.gd` | 高稀有度单位加载、成长、关键主动/被动 |

## 常用验证命令

### 日志路径约定

Windows 下使用 Godot headless 命令时，`--log-file` 建议写入项目当前目录，或使用正斜杠相对路径，例如：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file test_new_units.log --script res://scripts/tests/test_new_units.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file ./logs/test_new_units.log --script res://scripts/tests/test_new_units.gd
```

避免使用反斜杠子目录路径，例如 `--log-file logs\test_new_units.log`。该写法即使测试退出码为 0，也可能额外输出 `Could not create directory: 'user://C:'`。如果必须写入 `logs/`，先确保目录存在，并优先使用 `./logs/name.log`。

### 编译检查

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --check-only --script res://scripts/main.gd
```

### 运行测试脚本

```text
# 系统测试
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_stat_modifier_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_bond_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_control_effect_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_summon_system.gd

# 敌人测试
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_slime_enemies.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_boss_units.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_elite_enemies.gd

# 英雄测试
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_hero_manager.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_hero_battle_spawn.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_hero_exclusive_unit_pool.gd

# 奖励测试
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_reward_rarity_roll.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_reward_stat_rewards.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_reward_dynamic_unit_pool.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tests/test_reward_hero_exclusive_integration.gd
```

### 刷新内容参考文档

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --script res://scripts/tools/generate_content_reference.gd
```

## 测试模式

所有测试脚本使用 `extends SceneTree` 的 headless 模式，输出 `PASS` 或 `FAIL` 并列出失败原因。测试不依赖 GUI，可在 CI 环境中运行。
