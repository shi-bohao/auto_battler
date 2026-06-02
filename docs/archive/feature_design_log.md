# 功能设计与实现记录

> 本文档记录已完成的大型功能的设计决策和边界条件，用于后续扩展时回查决策背景。具体实现代码以当前 `scripts/` 为准，系统规则以 `docs/systems/` 对应文档为准。

## 当前状态

| 功能 | 状态 | 实现日期 |
|------|------|----------|
| 控制效果系统 | **已完成** | 2026-05-29 |
| 控制效果测试单位 | **单位资源与主动技能已完成；部分被动待补齐** | 2026-05-29 |
| 金币经济遗物 | **已完成** | 2026-05-25 |
| 远程普攻真实弹道 | **已完成** | 2026-05-23 |
| 非圆形瞬时 AoE（矩形/扇形） | **已完成** | 2026-05-23 |

控制效果系统的详细设计见 `docs/systems/status_effect_system.md`。

---
## 金币经济遗物（已完成 2026-05-25）

### 关键入口

| 文件 | 职责 |
| --- | --- |
| `scripts/relic/relic_effect_resolver.gd` | 金币遗物数值计算与效果应用 |
| `scripts/relic/relic_trigger_dispatcher.gd` | `ON_ROUND_REWARD` 分发与击杀金币接入 |
| `scripts/relic_manager.gd` | `trigger_round_reward_relics()` / `reset_battle_relic_state()` |
| `scripts/main.gd` | 胜利结算接入，金币回调与动态光环 deferred 合并刷新 |
| `scripts/battle_manager.gd` | 战斗开始时 `reset_battle_relic_state()` |
| `data/relics/` | 9 件新遗物资源 |

### 重要设计取舍

1. **`ON_ROUND_REWARD` 触发时机**：在基础胜利金币计算完成后、最终金币写入前。使用 `pre_reward_gold` 为基准，避免多个遗物互相递归计算。
2. **第 30 波**：最终 Boss 跳过 `ON_ROUND_REWARD`（后续没有商店或备战阶段可使用金币）。
3. **动态金币光环性能**：无动态金币光环遗物时，金币变化不触发全队重算。存在时同一帧内多次金币变化通过 deferred 合并刷新。
4. **击杀金币**：通过 `_add_battle_gold()` 累积，即时回调 `main.gd` 写入 `EconomyManager`，因此击杀金币可影响同场胜利结算类遗物。

### 边界条件

- Bounty Dagger：每场战斗独立计数（3 击杀 → 1 金币），每场最多 3 金币；新战斗通过 `reset_battle_relic_state()` 清零
- Goldhunter Contract：每次有效击杀独立 35% 概率判定，无上限
- 金币动态光环不永久写回 `UnitData` 或阵容；金币减少或失去前排条件后恢复基础属性

---

## 远程普攻真实弹道（已完成 2026-05-23）

### 关键入口

| 文件 | 职责 |
| --- | --- |
| `scripts/combat/combat_resolver.gd` | 统一命中结算 `resolve_basic_attack_hit()` |
| `scripts/combat/attack_payload.gd` | 发射时快照（伤害/暴击/来源ID/阵营） |
| `scripts/combat/projectile_manager.gd` | 飞行物生命周期管理 |
| `scripts/combat/projectile.gd` | 飞行物节点 |
| `scripts/unit.gd` | `basic_attack_type` 分流近战/远程 |
| `scripts/battle_manager.gd` | ProjectileManager 集成与战斗结束清理 |

### 重要设计取舍

1. **近战与远程分流**：使用显式 `basic_attack_type` 字段（`melee`/`projectile`），不用 `attack_range` 自动推断。
2. **AttackPayload 快照**：发射时保存基础伤害、暴击率、暴伤、来源 ID 和阵营。Projectile 飞行期间攻击者可能死亡、属性变化或目标移动，必须使用快照数据。
3. **统一结算入口**：近战和远程都调用 `CombatResolver.resolve_basic_attack_hit()`，保证普攻被动、遗物、吸血、回魔和统计的一致性。

### 边界条件

- 目标在飞行中死亡 → projectile 失效，不造成伤害，不触发攻击命中
- 攻击者在飞行中死亡 → projectile 继续飞行，伤害归属使用快照 `source_unit_id`；吸血和自身回魔仅在攻击者仍存活时触发
- 战斗结束 → 清理所有 projectile，不再触发命中
- 远程单位发射 projectile 不增加 `attack_count`，仅命中成功后增加

---

## 非圆形瞬时 AoE（已完成 2026-05-23）

### 关键入口

| 文件 | 职责 |
| --- | --- |
| `scripts/combat/shape_geometry.gd` | 形状顶点生成 |
| `scripts/combat/aoe_resolver.gd` | `get_units_in_shape()` 统一形状判定 |
| `scripts/combat/aoe_shape_visual.gd` | 瞬时形状视觉（0.15~0.3s 显示+淡出） |
| `scripts/battle_manager.gd` | `create_aoe_shape_visual()` 入口 |

### 重要设计取舍

1. **shape_data 统一结构**：`shape_type`（circle/rect/sector）+ `origin`/`direction`/`radius`/`width`/`length`/`angle_degrees`/`anchor`。
2. **圆形兼容**：`get_units_in_radius()` 保留，内部转为 `get_units_in_shape()` 调用，旧技能无需修改。
3. **矩形朝向**：支持 `anchor = "forward"`，矩形方向随施法者朝向旋转。
4. **第一版只做瞬时**：不做持续非圆形区域（涉及每 tick 重判定、区域跟随、进出区域和持续视觉）。

### 边界条件

- 矩形方向为零向量时回退为默认方向
- 扇形方向为零向量时回退
- 不命中死亡单位、友方单位
- 不重复命中同一单位
- AoE 命中 >1 单位时击杀归属和伤害统计正确

---
