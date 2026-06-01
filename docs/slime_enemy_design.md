# 史莱姆系列敌人设计与实现文档

本文档记录史莱姆系列敌人的当前实现。精确数值以 `data/enemies/*.tres`、`scripts/combat/active_skill_caster.gd` 和 `scripts/combat/passive_resolver.gd` 为准，内容总览以 `docs/content_reference.md` 为准。

## 设计目标

- 提供一组低门槛、易识别的敌方变体，覆盖前排承伤、控制、燃烧、剧毒和分裂占场。
- 复用现有 `StatusEffectFactory`、`UnitControlState`、`burning`、`venom_stack`、`FieldEffectManager` 与 `SummonManager`。
- 不新增独立 DoT 或控制系统，避免后续维护时出现多套状态生命周期。

## 单位清单

| 单位 | unit_type | 阶等 | 定位 | 被动 | 主动 |
| --- | --- | --- | --- | --- | --- |
| 普通史莱姆 / Common Slime | `enemy_common_slime` | NORMAL | 前排小怪 | `slime_body` | `slime_bounce` |
| 冰霜史莱姆 / Frost Slime | `enemy_frost_slime` | NORMAL | 控制辅助 | `frost_burst` | `frost_explosion` |
| 火焰史莱姆 / Flame Slime | `enemy_flame_slime` | NORMAL | 持续伤害 | `flame_burst` | `fire_splash` |
| 毒液史莱姆 / Venom Slime | `enemy_venom_slime` | NORMAL | 剧毒叠层 | `venom_pool` | `toxic_blob` |
| 巨型史莱姆 / Giant Slime | `enemy_giant_slime` | ELITE | 高生命前排 | `slime_split` | `heavy_bounce` |

## 技能实现

### 普通史莱姆

- `slime_body`：基础版本使受到的普通攻击伤害降低 8%；三星提高到 15%。
- 该减伤只在 `CombatResolver.resolve_basic_attack_hit()` 中处理，不影响主动技能、DoT 和场地伤害。
- `slime_bounce`：对当前目标造成 160% 攻击力技能伤害；三星提高到 200%。

### 冰霜史莱姆

- `frost_burst`：死亡时冻结周围目标 1.5 秒；三星提高到 2 秒。
- 死亡爆发与寒霜区域基础半径为 115，三星提高到 140；两者都会显示范围提示。
- 死亡位置生成 3 秒寒霜区域，每秒施加一次迟缓。
- 迟缓沿用现有 `SLOW` 控制，基础行动速率降至 80%，持续 2 秒；三星降至 70%，持续 2.5 秒。
- `frost_explosion`：以当前目标为中心造成范围技能伤害并施加迟缓。
- 基础范围 90、伤害 100% 攻击力；三星范围 110、伤害 125% 攻击力。

### 火焰史莱姆

- `flame_burst`：普通攻击施加 `burning`，持续 4 秒，每秒造成 20% 攻击力伤害；三星提高到 30%。
- 死亡时发生爆燃，对范围内目标造成 100% 攻击力技能伤害；三星提高到 130%。
- 爆燃与熔岩区域基础半径为 120，三星提高到 145；两者都会显示范围提示。
- 死亡位置生成 3 秒熔岩区域，每秒施加一次同等燃烧。
- `fire_splash`：以当前目标为中心造成范围技能伤害并施加燃烧。
- 基础范围 90、伤害 130% 攻击力；三星范围 110、伤害 160% 攻击力。

### 毒液史莱姆

- `venom_pool`：普通攻击施加 1 层 `venom_stack`。
- 死亡时对周围目标施加 3 层剧毒；三星提高到 5 层。
- 毒液爆发与毒液区域基础半径为 120，三星提高到 145；两者都会显示范围提示。
- 死亡位置生成 5 秒毒液区域，每秒施加剧毒，基础 1 层，三星 2 层。
- `toxic_blob`：以当前目标为中心造成范围技能伤害并施加剧毒。
- 基础范围 90、伤害 110% 攻击力、3 层剧毒；三星范围 110、伤害 135% 攻击力、5 层剧毒。

### 巨型史莱姆

- `slime_split`：死亡时分裂为 2 个巨型史莱姆。
- 分裂体最大生命为本体死亡前最大生命的 30%，攻击和防御减半；三星生命继承提高到 40%。
- 每条分裂链记录 `slime_split_count`。基础最多触发 2 次，三星最多触发 3 次。
- 分裂体沿用召唤系统创建，标记为召唤物并参与胜负判定。
- `heavy_bounce`：对当前目标造成 140% 攻击力技能伤害，并获得 8% 最大生命护盾；三星提高到 170% 伤害和 12% 最大生命护盾。

## 实现入口

| 内容 | 文件 |
| --- | --- |
| 单位资源 | `data/enemies/common_slime.tres`、`frost_slime.tres`、`flame_slime.tres`、`venom_slime.tres`、`giant_slime.tres` |
| 敌方池接入 | `scripts/catalog/enemy_catalog.gd` |
| 遭遇权重 | `scripts/encounter/encounter_generator.gd` |
| 主动技能 | `scripts/combat/active_skill_caster.gd` |
| 被动技能 / 死亡效果 | `scripts/combat/passive_resolver.gd` |
| 状态区域 | `scripts/combat/field_effect_manager.gd`、`scripts/battle_manager.gd` |
| 分裂生成 | `scripts/summon_manager.gd`、`scripts/battle_manager.gd` |
| 技能说明 | `scripts/unit_text_formatter.gd` |
| 验证脚本 | `scripts/tests/test_slime_enemies.gd` |

## 验证方式

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\slime_check.log --check-only --script res://scripts/main.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\test_slime_enemies.log --script res://scripts/tests/test_slime_enemies.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\content_reference.log --script res://scripts/tools/generate_content_reference.gd
```

当前 `test_slime_enemies.gd` 覆盖：

- 五个史莱姆资源能从 `EnemyCatalog` 加载。
- 技能说明不会回退到 unknown。
- 普通史莱姆基础和三星普攻减伤。
- 冰霜/火焰/毒液主动技能能施加对应状态。
- 巨型史莱姆死亡后生成 2 个分裂体，并正确记录分裂代数与继承属性。
