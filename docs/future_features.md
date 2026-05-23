# 功能规划与实现记录

更新时间：2026-05-23

本文档记录已经明确设计方向的功能规划及完成后的实现入口。未完成内容用于后续开发拆分和验收；已完成内容保留为实现参考。

## 当前状态

| 功能 | 状态 | 实现日期 |
|------|------|----------|
| 远程普攻真实弹道 | **已完成** | 2026-05-23 |
| 非圆形瞬时 AoE（矩形/扇形） | **已完成** | 2026-05-23 |

已完成的功能设计文档仍保留在下方作为实现参考，标题以 ~~删除线~~ 标记。

## ~~1. 远程普攻真实弹道~~ （已完成）

> 此功能已于 2026-05-23 按本文档设计实现。实现入口见：
> - `scripts/combat/combat_resolver.gd` — 统一命中结算
> - `scripts/combat/attack_payload.gd` — 发射时快照
> - `scripts/combat/projectile_manager.gd` — 飞行物管理
> - `scripts/combat/projectile.gd` — 飞行物节点
> - `scenes/combat/projectile.tscn` — 飞行物场景
> - `scripts/unit.gd` — `launch_count` / `basic_attack_type` 分流
> - `scripts/battle_manager.gd` — ProjectileManager 集成与清理

### 原始设计（已按此实现）

### 目标

立项时普通攻击在 `Unit._attack_current_target()` 中即时结算：攻击间隔到达后，检查目标、立即造成伤害、触发 `attack_landed`、普攻被动、攻击遗物、吸血、普攻回魔和统计。

计划改为远程单位使用真实弹道：

```text
攻击间隔到
检查目标是否合法
发射 projectile
projectile 飞行
projectile 命中
再次检查目标是否合法
结算伤害
触发 attack_landed
触发普攻被动 / 遗物 / 吸血 / 回魔 / 击杀统计
```

关键原则：只有 projectile 命中后，才算一次真正的普通攻击命中。

因此以下逻辑必须延后到命中时：

- `attack_landed` 信号。
- 普攻命中被动。
- `ON_ATTACK` 遗物。
- 吸血。
- 普攻回魔。
- 伤害统计。
- 击杀归属。
- Hunter Mark、`unstable_bomb`、`cleaving_edge`、Duelist Glove 等依赖普攻命中次数的效果。

### 近战与远程分流

不要用 `attack_range` 自动推断是否远程。部分近战单位可能拥有较大的攻击范围，辅助单位也可能需要远程表现。第一版使用显式字段。

计划在 `UnitData` 中新增：

```gdscript
@export_enum("melee", "projectile") var basic_attack_type: String = "melee"
@export var projectile_speed: float = 500.0
@export_enum("arrow", "bolt", "magic", "holy", "flask", "bomb", "dark", "curse") var projectile_visual_type: String = "arrow"
```

推荐配置：

| 类型 | 单位 |
| --- | --- |
| `melee` | `warrior`, `tank`, `assassin`, `greatsword_knight`, `guardian_captain`, `bloodbound_berserker`, `summoned_skeleton`, `summoned_puppet` |
| `projectile` | `archer`, `mage`, `priest`, `bard`, `forest_druid`, `plague_caster`, `alchemist`, `bomb_thrower`, `cleric`, `necromancer`, `puppet_warlock`, `wind_chanter`, `arcane_mentor` |

远程表现建议：

| 单位 | `projectile_visual_type` | `projectile_speed` |
| --- | --- | --- |
| Archer | `arrow` | 600 |
| Mage | `magic` | 480 |
| Priest | `holy` | 420 |
| Alchemist | `flask` | 450 |
| Bomb Thrower | `bomb` | 380 |
| Necromancer | `dark` | 430 |
| Puppet Warlock | `curse` | 430 |

第一版不要求真实抛物线，爆弹投手也可以先用直线飞行。后续可单独扩展弧线弹道。

### AttackPayload

新增一次攻击的快照数据，避免 projectile 飞行期间完全依赖实时单位节点。

建议新增 `AttackPayload` 或使用统一 Dictionary：

```gdscript
{
    "source_unit_ref": attacker,
    "source_unit_id": attacker.unit_id,
    "source_team_id": attacker.team_id,
    "source_display_name": attacker.display_name,
    "source_unit_type": attacker.unit_type,
    "source_passive_id": attacker.passive_id,
    "source_bond_tags": attacker.bond_tags.duplicate(),
    "source_star": attacker.star,

    "target_unit_ref": target,
    "target_unit_id": target.unit_id,
    "target_team_id": target.team_id,

    "base_damage": damage,
    "crit_chance": attacker.crit_chance,
    "crit_damage_multiplier": attacker.crit_damage_multiplier,
    "defense_penetration": attacker.defense_penetration,
    "lifesteal": attacker.life_steal,
    "basic_attack_type": attacker.basic_attack_type,
    "can_crit": true,
    "is_basic_attack": true,

    "created_time": battle_time,
    "max_lifetime": 2.0
}
```

Projectile 飞行期间可能发生：

- 攻击者死亡。
- 攻击者被 `queue_free`。
- 攻击者属性变化。
- 目标死亡。
- 目标移动。
- 战斗结束。

因此至少基础伤害、暴击率、暴击伤害、来源 ID 和来源阵营要在发射时保存。

### 命中规则

第一版使用追踪型目标弹道，不做物理碰撞。

发射时：

1. 攻击者拥有合法目标。
2. 目标存活。
3. 目标是敌方。
4. 目标在攻击范围内。
5. 创建 projectile。
6. 攻击者进入下一次攻击冷却。

飞行时：

- Projectile 每帧向目标当前位置移动。
- 如果目标仍然存活，则追踪目标当前位置。
- 如果目标死亡或无效，则 projectile 失效。

命中时：

- 当 projectile 距离目标小于命中阈值，例如 `8` 或 `12`，触发命中结算。
- 命中前再次检查战斗仍在进行、目标仍有效、目标仍存活、目标阵营仍与来源阵营敌对。
- 如果检查失败，projectile 直接销毁，不造成伤害，不触发 `attack_landed`，不触发遗物。

### 攻击者和目标失效规则

目标在飞行中死亡：

- Projectile 失效。
- 不重新寻敌。
- 不造成伤害。
- 不触发攻击命中。

攻击者在飞行中死亡：

- Projectile 继续飞行。
- 命中后仍然造成伤害。
- 伤害归属使用发射时保存的 `source_unit_id`。
- 吸血、自身回魔、攻击者自身回血、攻击者身上的 on-hit 被动只在攻击者仍然有效且存活时触发。
- 伤害统计、击杀归属、部分全局遗物可以根据 `source_unit_id` 记录。

战斗结束时：

- 清理所有 projectile。
- 不再触发命中。
- 覆盖胜负已判定、Restart、进入奖励阶段、进入 Game Over、切换关卡等流程。

### 攻击计数

远程单位发射 projectile 不增加 `attack_count`。

Projectile 命中成功后才增加 `attack_count`。

这样可以避免：

- 箭还没命中，Hunter Mark 已经触发。
- 目标已死但攻击计数增加。
- 未命中也触发攻击遗物。

### 统一结算入口

不要让 projectile 自己实现复杂战斗逻辑。

推荐先抽出统一方法：

```gdscript
resolve_basic_attack_hit(attacker, target, payload = null)
```

或放到独立服务：

```gdscript
CombatResolver.resolve_basic_attack_hit(payload, target)
```

统一入口负责：

1. 根据 payload 计算基础伤害。
2. 判定暴击。
3. 计算防御、减伤、护盾和生命伤害。
4. 调用 `target.take_damage()` 或对应低层结算。
5. 记录伤害统计。
6. 判断击杀归属。
7. 触发 `attack_landed`。
8. 触发普通攻击被动。
9. 触发 `ON_ATTACK` 遗物。
10. 触发吸血。
11. 触发普攻回魔。
12. 刷新 UI。

近战和远程都调用同一个入口：

```text
近战：
try_attack()
resolve_basic_attack_hit()

远程：
try_attack()
spawn_projectile()
projectile hit
resolve_basic_attack_hit()
```

### ProjectileManager

建议新增：

- `res://scripts/combat/projectile_manager.gd`
- `res://scripts/combat/projectile.gd`
- `res://scenes/combat/projectile.tscn`

`ProjectileManager` 职责：

1. 创建 projectile。
2. 保存所有 active projectiles。
3. 战斗结束时清理 projectile。
4. 提供 `spawn_basic_attack_projectile()`。
5. 根据 `projectile_visual_type` 设置样式。

`Projectile` 节点职责：

1. 按速度移动。
2. 追踪 target。
3. 判断命中。
4. 超时销毁。
5. 命中后回调统一结算入口。

Projectile 不应该知道遗物、羁绊、吸血、Hunter Mark 或伤害统计。

## ~~2. 非圆形瞬时 AoE~~ （已完成）

> 此功能已于 2026-05-23 按本文档设计实现。实现入口见：
> - `scripts/combat/shape_geometry.gd` — 形状顶点生成
> - `scripts/combat/aoe_resolver.gd` — 统一形状查询与判定
> - `scripts/combat/aoe_shape_visual.gd` — 瞬时形状视觉
> - `scripts/battle_manager.gd` — `create_aoe_shape_visual()` 入口
> - 巨剑骑士被动（扇形）+ 主动（矩形）为示例技能

### 原始设计（已按此实现）

### 目标

立项时范围攻击主要使用 `center_position + radius` 的圆形模型。此设计用于支持矩形、扇形等非圆形范围，用于剑气、冲击波、喷火、前方斩击、直线炮击等技能。

第一版只实现瞬时矩形和瞬时扇形，不实现持续非圆形区域。

### shape_data

建议将范围数据升级为统一结构：

```gdscript
{
    "shape_type": "circle", # circle / rect / sector
    "center": Vector2.ZERO,
    "origin": Vector2.ZERO,
    "direction": Vector2.RIGHT,
    "radius": 100.0,
    "width": 80.0,
    "length": 160.0,
    "angle_degrees": 90.0,
    "anchor": "center" # center / forward
}
```

### AoeResolver

新增或改造：

```gdscript
AoeResolver.get_units_in_shape(units, shape_data, excluded_units = [])
```

内部根据 `shape_type` 分发：

- `circle` -> `is_point_in_circle()`
- `rect` -> `is_point_in_rect()`
- `sector` -> `is_point_in_sector()`

保留旧接口：

```gdscript
get_units_in_radius(units, center, radius)
```

但内部改成：

```gdscript
return get_units_in_shape(units, {
    "shape_type": "circle",
    "center": center,
    "radius": radius
})
```

这样旧技能不需要大改。

### 矩形 AoE 判定

矩形应支持朝向矩形，而不是只能水平或垂直。

推荐参数：

- `origin`：通常是施法者位置。
- `direction`：从施法者指向目标。
- `length`：矩形向前延伸长度。
- `width`：矩形宽度。
- `anchor = "forward"`。

Forward 矩形判定：

```text
to_point = point - origin
forward_dist = dot(to_point, direction)
side_dist = dot(to_point, perpendicular)

命中条件：
forward_dist >= 0
forward_dist <= length
abs(side_dist) <= width / 2
```

适合技能：

- 剑气。
- 冲击波。
- 直线炮击。
- 火焰喷射。

### 扇形 AoE 判定

扇形参数：

- `origin`
- `direction`
- `radius`
- `angle_degrees`

判定方式：

```text
to_point = point - origin
distance <= radius
angle_between(direction, to_point) <= angle_degrees / 2
```

注意：

- `direction` 必须 normalize。
- `to_point` 长度接近 0 时可视为命中。

适合技能：

- 扇形斩击。
- 喷火。
- 前方冲击。
- 战吼。

### 瞬时 AoE 流程

```text
技能释放
生成 shape_data
AoeResolver.get_enemy_units_in_shape()
deal_aoe_damage()
生成 0.15 到 0.30 秒 AoE 视觉提示
结束
```

第一版不做持续非圆形区域。持续区域后续会涉及每 tick 重新判定、区域是否跟随施法者、方向是否更新、单位进出区域和视觉持续。

### AoE 视觉

建议新增：

- `AoeShapeVisual`

支持：

- `circle`
- `rect`
- `sector`

第一版只做短暂显示：

- `duration = 0.2`
- alpha 淡出。

矩形视觉可用 `draw_polygon()` 画 4 个点：

```gdscript
p1 = origin + perpendicular * width / 2
p2 = origin - perpendicular * width / 2
p3 = origin + direction * length - perpendicular * width / 2
p4 = origin + direction * length + perpendicular * width / 2
```

扇形视觉可用 16 段近似：

```gdscript
points = [origin]
for i in steps:
    angle = -half_angle 到 +half_angle
    point = origin + rotated_direction * radius
    points.append(point)
```

### 技能使用示例

横向剑气：

```gdscript
shape_data = {
    "shape_type": "rect",
    "origin": caster.global_position,
    "direction": (target.global_position - caster.global_position).normalized(),
    "length": 160.0,
    "width": 70.0,
    "anchor": "forward"
}
```

扇形斩击：

```gdscript
shape_data = {
    "shape_type": "sector",
    "origin": caster.global_position,
    "direction": (target.global_position - caster.global_position).normalized(),
    "radius": 120.0,
    "angle_degrees": 90.0
}
```

圆形爆炸：

```gdscript
shape_data = {
    "shape_type": "circle",
    "center": target.global_position,
    "radius": 100.0
}
```

## 3. 推荐实现步骤

1. 抽出普攻命中结算。
   - 先不做 projectile。
   - 将当前 `unit.gd` 中的普通攻击直接命中逻辑抽成统一方法。
   - 近战和远程仍然即时命中。
   - 验证所有被动、遗物、统计保持正常。

2. 新增 AttackPayload。
   - 封装一次攻击所需快照信息。
   - 验证使用 payload 后普通攻击结算结果和以前一致。

3. 新增 ProjectileManager 和 Projectile。
   - 先只接入 `archer`。
   - 验证 Archer 伤害变成命中后结算。
   - 验证 Hunter Mark、`ON_ATTACK`、吸血和回魔都在命中后触发。
   - 验证目标提前死亡时 projectile 消失。

4. 所有远程单位接入 projectile。
   - 给 `UnitData` 增加 `basic_attack_type`、`projectile_speed`、`projectile_visual_type`。
   - 近战单位保持即时命中。

5. 战斗结束清理 projectile。
   - 胜利、失败、Restart、进入奖励阶段和切换关卡都要清理。
   - 验证战斗结束后飞行物不会继续命中。

6. 抽象 `shape_data`。
   - 改造 `aoe_resolver.gd`。
   - 保留 `get_units_in_radius()` 作为兼容包装。
   - 验证原有圆形 AoE 技能不受影响。

7. 实现瞬时矩形 AoE。
   - 验证矩形前方单位命中，矩形外单位不命中。
   - 验证矩形可以随施法方向旋转。

8. 实现瞬时扇形 AoE。
   - 验证扇形内单位命中，扇形外单位不命中。
   - 验证角度和半径调整有效。

9. 新增 AoEShapeVisual。
   - 支持圆形、矩形和扇形短暂显示。
   - 第一版只做瞬时显示和淡出。

## 4. 边界情况清单

远程弹道必须处理：

1. 目标飞行中死亡。
2. 目标被 `queue_free`。
3. 攻击者飞行中死亡。
4. Projectile 飞行中战斗结束。
5. Projectile 超时。
6. 目标移动。
7. 目标不再是敌方。
8. Projectile 命中同一帧目标死亡。
9. 多个 projectile 同时命中同一目标。
10. 击杀后统计和遗物只触发一次。

AoE 必须处理：

1. 命中多个敌人。
2. 不命中死亡单位。
3. 不命中友方。
4. 不重复命中同一单位。
5. 单位在边界线上是否命中。
6. 矩形方向为零向量时回退。
7. 扇形方向为零向量时回退。
8. 圆形旧技能兼容。
9. AoE 击杀归属正确。
10. AoE 伤害统计正确。
