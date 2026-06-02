# 战斗系统：索敌与目标控制

> 本文档记录索敌、目标合法性、嘲讽强制目标和控制状态对行动影响的当前规则。伤害结算、弹道、AoE、场地效果的实现入口位于 `scripts/combat/`，状态与控制规则见 `docs/systems/status_effect_system.md`。

## 已实现索敌模式

当前实现两种基础索敌模式，以及控制系统中的 TAUNT 覆盖：

| 模式 | 行为 |
| --- | --- |
| `NEAREST` | 选择距离最近的合法敌人，目标合法时不主动切换 |
| `LOWEST_HP` | 选择血量百分比最低的合法敌人，周期性重新评估 |
| TAUNT 覆盖 | 通过 `UnitControlState.forced_target` 强制覆盖当前目标 |

单位每帧先更新索敌再更新技能。进攻型主动技能通过 `_get_offensive_skill_target()` 优先读取强制目标；治疗、护盾和自我增益类技能不受嘲讽限制。

## 枚举定义

### 索敌模式

```
enum TargetMode {
    NEAREST,
    LOWEST_HP
}
```

### 单位状态

`scripts/unit.gd` 中定义 4 种状态：

```
enum UnitState {
    IDLE,        // 空闲，没有目标
    MOVING,      // 有目标但不在攻击范围内，正在靠近
    ATTACKING,   // 有目标且在攻击范围内，正在攻击
    DEAD,        // 自身死亡
}
```

## 目标合法性

所有索敌模式使用统一的目标合法性检查。合法目标需同时满足：

1. target 不为空且节点有效（`is_instance_valid`）
2. target 仍然存活
3. target 与自己不同阵营
4. target 可被选中
5. target 未被移出战场
6. target 在索敌范围（`search_range`）内

距离使用 Godot 2D 直线距离（`global_position.distance_to()`）计算。

## NEAREST 模式

- **适用**：普通近战、远程、坦克、召唤物、基础小兵
- **排序**：距离最近 → HP 更低 → unit_id 更小
- **目标黏性**：当前目标合法时不主动重新索敌，除非目标死亡、消失、不可选中或离开 `search_range`
- **追击**：目标离开 `attack_range` 但仍在 `search_range` 内时，进入 MOVING 继续靠近

## LOWEST_HP 模式

- **适用**：刺客、收割者、带斩杀技能的单位
- **排序**：`hp / max_hp` 最低 → 当前 HP 最低 → 距离最近 → unit_id 更小
- **周期性重评估**：每隔 `retarget_interval` 重新评估候选目标
- **切换阈值**：只有当新目标 `hp_ratio + lowest_hp_switch_threshold < current_target.hp_ratio` 时才切换，防止频繁抖动
- **追击与放弃**：同 NEAREST

## 嘲讽强制目标

- `TAUNT` 控制效果通过 `UnitControlState.forced_target` 设置强制目标
- `UnitTargeting` 在索敌时优先检查 `control_state.get_valid_forced_target()`
- 嘲讽来源死亡、失效或不再是合法目标时，重建控制状态并恢复正常索敌
- 治疗/护盾/自我增益类主动技能不读取强制目标

## 控制状态影响的行动

`UnitControlState` 提供以下布尔聚合字段：

| 字段 | 含义 |
| --- | --- |
| `can_move` | 是否可以移动 |
| `can_attack` | 是否可以普攻 |
| `can_cast` | 是否可以释放技能 |
| `can_retarget` | 是否可以主动重选目标 |

控制结束后重新检查 `current_target`：有效则根据距离进入 MOVING/ATTACKING，否则清空目标并重新索敌。

## 当前默认参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `search_range` | `999.0` | 当前项目默认全场索敌 |
| `retarget_interval` | `0.4` | LOWEST_HP 重评估间隔（秒） |
| `lowest_hp_switch_threshold` | `0.1` | LOWEST_HP 切换阈值 |

## 实现入口

| 内容 | 文件 |
| --- | --- |
| 索敌逻辑 | `scripts/unit_targeting.gd` |
| 单位状态与生命周期 | `scripts/unit.gd` |
| 控制状态聚合 | `scripts/combat/unit_control_state.gd` |
| 控制效果施加 | `scripts/combat/status_effect_factory.gd` |
| 伤害结算 | `scripts/combat/combat_resolver.gd` |
| 战斗管理 | `scripts/battle_manager.gd` |
