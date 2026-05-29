# 控制效果系统设计与实现文档

更新时间：2026-05-29

本文档整理后续要加入的控制效果系统。目标是在现有 `StatusEffect` / `UnitEffectController` / `StatusEffectFactory` 基础上扩展，而不是另起一套完全独立的控制系统。控制效果统一先汇总为 `UnitControlState`，移动、普攻、施法、索敌和伤害结算只读取这个状态，避免控制逻辑散落在多个技能脚本中。

## 1. 当前项目基础

当前项目已经具备以下相关能力：

- `scripts/status_effect.gd`：支持 HoT、DoT、属性加算、属性乘算、持续时间模式、正负性、分类和多种叠层策略。
- `scripts/unit_effect_controller.gd`：负责应用、刷新、叠层、过期、移除和清空状态效果。
- `scripts/combat/status_effect_factory.gd`：统一创建并施加状态效果，剧毒羁绊已经通过这里修改状态数据。
- `scripts/unit.gd`：每帧先更新状态效果，再更新攻击冷却、索敌、技能和移动/攻击。
- `scripts/unit_targeting.gd`：负责目标合法性、最近/低血目标选择、移动到目标、卡住检测。
- `scripts/unit_skill.gd` 和 `scripts/combat/active_skill_caster.gd`：负责魔力、主动技能释放和大量技能目标选择。
- `scripts/combat/combat_resolver.gd`：普通攻击命中统一结算入口；远程弹道命中后才触发普攻命中逻辑。
- `scripts/unit_combat.gd`：最终 `take_damage()` 生命/护盾/暴击/闪避/死亡结算入口。

因此第一版控制系统应该扩展这些现有入口：

```text
StatusEffect
    ↓
UnitEffectController
    ↓
UnitControlState
    ↓
UnitTargeting / Unit._attack_current_target / UnitSkill / ActiveSkillCaster / UnitCombat
```

## 2. 设计目标

1. 支持减速、禁锢、眩晕、冻结、嘲讽五类控制。
2. 控制效果复用现有状态效果生命周期、来源、持续时间、清理和显示路径。
3. 控制效果不直接修改 `move_speed`、`attack_interval` 等基础属性，避免与属性修饰器系统互相覆盖。
4. 多个控制效果共存时，由 `UnitControlState` 统一计算最终行动能力。
5. 控制持续时间受现有 `status_resistance` 和新增控制抗性字段影响。
6. 远程弹道、已生成场地、已存在召唤物不因施法者后续被控而取消。
7. Boss / 精英拥有控制时长缩减，避免无限控制。
8. 第一版不实现击退、沉默、缴械、恐惧、变形、强制位移和不可选中。

## 3. 对初稿的关键调整

### 3.1 控制效果不要另建完全独立系统

初稿中的 `ControlEffectData` 可以理解为 `StatusEffect` 的控制字段扩展，不建议另建一个绕过 `UnitEffectController` 的生命周期系统。

原因：

- 当前项目已经解决了状态持续时间、叠层、来源、死亡清理、重算和测试问题。
- 剧毒羁绊已经接入 `StatusEffectFactory`，未来控制羁绊或遗物也应复用同一入口。
- 另起系统会让死亡、Restart、召唤物清理、详情显示、日志和测试重复一遍。

### 3.2 “不叠层”不等于“只保留一个效果记录”

减速、眩晕等控制最终效果不应该乘算叠加，但可以保留多个独立来源/技能的效果记录，然后在 `UnitControlState` 中聚合。

例如：

- 50% 减速 3 秒。
- 30% 减速 10 秒。

如果只保留最强减速，并用弱减速刷新强减速持续时间，会导致 50% 减速错误延长到 10 秒。更稳妥的方式是两个状态都保留，但最终移动倍率取最小值。强减速过期后，弱减速仍然自然生效。

### 3.3 冻结增伤需要伤害上下文

当前大量技能直接调用：

```gdscript
target.take_damage(skill_damage, unit)
```

`take_damage()` 目前不知道这次伤害是普攻、技能、DoT、场地还是遗物。冻结“受到技能伤害提高 10%”不能直接塞进通用 `damage_taken_multiplier`，否则会错误增强普攻、DoT、场地和遗物伤害。

推荐实现：

- 第一阶段可以先把冻结做成带冻结标签的眩晕。
- 同时新增技能伤害结算入口，例如 `CombatResolver.resolve_skill_damage(caster, target, amount, context = {})`。
- 主动技能、AoE 技能和需要算作技能伤害的召唤物主动技能逐步迁移到该入口。
- 迁移完成后，冻结的 `skill_damage_taken_multiplier` 只在 `damage_kind == "skill"` 时生效。

### 3.4 嘲讽必须覆盖主动技能中的自选敌方目标

当前很多主动技能不直接使用 `unit.current_target`，而是在 `ActiveSkillCaster` 内部调用 `_find_lowest_hp_ratio_enemy()` 或 `_find_nearest_enemy()`。如果只改 `UnitTargeting.find_target()`，这些技能会绕过嘲讽。

推荐新增统一辅助：

```gdscript
func _get_offensive_skill_target(unit, fallback_mode := "current_or_nearest") -> Variant
```

规则：

- 如果 `unit.control_state` 有合法 `forced_target`，敌方目标技能优先返回该目标。
- 治疗、护盾、友方增益、自身增益、纯召唤技能不受嘲讽影响。
- 特殊技能如果设计上无视嘲讽，需要显式传入 `ignore_taunt = true`。

### 3.5 卡住检测不能解除嘲讽目标

`UnitTargeting.check_targeting_stuck()` 当前会在单位长时间没移动且没攻击时清空目标。被嘲讽但又被禁锢、或嘲讽目标在攻击范围外时，单位会原地等待；此时不应因为“卡住”清空目标。

规则：

- `control_state.is_taunted == true` 且 `forced_target` 合法时，卡住检测不清空 `current_target`。
- 嘲讽来源死亡或不可选中时，由控制状态重建或嘲讽失效逻辑清理。

## 4. 控制类型

### 4.1 Slow / 减速

效果：

- 降低移动速度。
- 不影响普攻。
- 不影响施法。
- 不影响索敌。

推荐数据：

```gdscript
{
    "effect_id": "frost_slow",
    "effect_type": StatusEffect.EFFECT_CONTROL,
    "category": StatusEffect.CATEGORY_CONTROL,
    "control_type": "SLOW",
    "duration": 3.0,
    "move_speed_multiplier": 0.5,
    "stack_policy": StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH_LONGER,
    "polarity": StatusEffect.POLARITY_NEGATIVE
}
```

聚合规则：

- 多个减速同时存在时，最终 `move_speed_multiplier = min(all slow multipliers)`。
- 不做乘算叠加。
- `move_speed_multiplier` 建议下限为 `0.20`，避免单位几乎静止而又语义上不是禁锢。

### 4.2 Root / 禁锢

效果：

- 不能移动。
- 可以普通攻击。
- 可以释放主动技能。
- 可以正常索敌。

语义：

- 如果目标在攻击范围内，仍然可以攻击。
- 如果目标不在攻击范围内，因为不能移动，只能等待。
- 禁锢不会打断已经发射的远程弹道。

推荐数据：

```gdscript
{
    "effect_id": "vine_root",
    "effect_type": StatusEffect.EFFECT_CONTROL,
    "category": StatusEffect.CATEGORY_CONTROL,
    "control_type": "ROOT",
    "duration": 2.0,
    "disable_movement": true,
    "stack_policy": StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH_LONGER,
    "polarity": StatusEffect.POLARITY_NEGATIVE
}
```

### 4.3 Stun / 眩晕

效果：

- 不能移动。
- 不能普通攻击。
- 不能释放主动技能。
- 仍然可以受到伤害、治疗和护盾。
- 魔力继续恢复，但满魔后不能释放；眩晕结束后如果魔力仍满，可以立刻尝试释放。

推荐数据：

```gdscript
{
    "effect_id": "shield_bash_stun",
    "effect_type": StatusEffect.EFFECT_CONTROL,
    "category": StatusEffect.CATEGORY_CONTROL,
    "control_type": "STUN",
    "duration": 1.5,
    "disable_movement": true,
    "disable_attack": true,
    "disable_cast": true,
    "stack_policy": StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH_LONGER,
    "polarity": StatusEffect.POLARITY_NEGATIVE
}
```

额外规则：

- 攻击冷却继续计时。
- 眩晕期间不能发射新的 projectile。
- 眩晕前已经发射的 projectile 继续飞行并可命中。
- 眩晕不取消已经生成的持续场地。

### 4.4 Freeze / 冻结

第一版推荐分两阶段实现。

阶段 A：

- 冻结等同于带冻结显示标签的眩晕。
- 不移动、不普攻、不施法。

阶段 B：

- 在阶段 A 基础上，受到技能伤害提高 10%。
- 只影响 `damage_kind == "skill"` 的结算。
- 不影响普攻、DoT、场地、遗物伤害，除非后续设计明确扩展。

推荐数据：

```gdscript
{
    "effect_id": "ice_prison",
    "effect_type": StatusEffect.EFFECT_CONTROL,
    "category": StatusEffect.CATEGORY_CONTROL,
    "control_type": "FREEZE",
    "duration": 1.5,
    "disable_movement": true,
    "disable_attack": true,
    "disable_cast": true,
    "skill_damage_taken_multiplier": 1.1,
    "stack_policy": StatusEffect.STACK_POLICY_UNIQUE_PER_SOURCE_REFRESH_LONGER,
    "polarity": StatusEffect.POLARITY_NEGATIVE
}
```

聚合规则：

- 多个冻结不叠加行动限制。
- `skill_damage_taken_multiplier` 取最大值，不乘算。

### 4.5 Taunt / 嘲讽

效果：

- 不禁止移动、普攻、施法。
- 强制敌方目标技能和普通索敌优先选择嘲讽来源。
- 持续期间不能主动切换到其他敌方目标。
- 嘲讽来源死亡、不可选中、变为同队或被释放时，嘲讽目标失效。

推荐数据：

```gdscript
{
    "effect_id": "guardian_taunt",
    "effect_type": StatusEffect.EFFECT_CONTROL,
    "category": StatusEffect.CATEGORY_CONTROL,
    "control_type": "TAUNT",
    "duration": 3.0,
    "disable_retarget": true,
    "forced_target": source_unit,
    "stack_policy": StatusEffect.STACK_POLICY_REPLACE_BY_LAST,
    "polarity": StatusEffect.POLARITY_NEGATIVE
}
```

语义：

- 如果被嘲讽单位能攻击到嘲讽者，就攻击嘲讽者。
- 如果攻击不到，就向嘲讽者移动。
- 如果被禁锢且攻击不到，就原地等待。
- 如果被眩晕/冻结，嘲讽仍然计时；硬控结束后若嘲讽仍在，继续攻击嘲讽者。

## 5. 控制优先级与最终状态

行动限制不是用单一优先级覆盖，而是布尔聚合：

```text
can_move     = 没有 root/stun/freeze
can_attack   = 没有 stun/freeze
can_cast     = 没有 stun/freeze
can_retarget = 没有 taunt
```

移动倍率：

```text
move_speed_multiplier = min(所有 slow 的 move_speed_multiplier)
如果 root/stun/freeze 存在，can_move = false，移动倍率保留但暂时没有实际移动效果。
```

技能承伤倍率：

```text
skill_damage_taken_multiplier = max(所有 freeze 的 skill_damage_taken_multiplier)
没有 freeze 时为 1.0。
```

示例：

| 同时存在 | 最终效果 |
| --- | --- |
| 减速 + 禁锢 | 不能移动；减速继续计时，禁锢结束后如果减速未过期则继续生效 |
| 禁锢 + 眩晕 | 不能移动、不能普攻、不能施法 |
| 眩晕 + 嘲讽 | 眩晕期间不能行动；眩晕结束后若嘲讽仍存在，继续以嘲讽者为目标 |
| 冻结 + 减速 | 冻结期间不能行动；冻结结束后减速可能继续影响移动 |

## 6. 数据结构设计

### 6.1 StatusEffect 扩展

建议在 `scripts/status_effect.gd` 中新增：

```gdscript
const EFFECT_CONTROL: String = "CONTROL"
const CATEGORY_CONTROL: String = "CONTROL"

const CONTROL_SLOW: String = "SLOW"
const CONTROL_ROOT: String = "ROOT"
const CONTROL_STUN: String = "STUN"
const CONTROL_FREEZE: String = "FREEZE"
const CONTROL_TAUNT: String = "TAUNT"

var control_type: String = ""
var control_tags: Array[String] = []

var move_speed_multiplier: float = 1.0
var disable_movement: bool = false
var disable_attack: bool = false
var disable_cast: bool = false
var disable_retarget: bool = false

var forced_target: Variant = null
var forced_target_unit_id: int = -1

var skill_damage_taken_multiplier: float = 1.0
var control_priority: int = 0
var control_ui_name: String = ""
var control_ui_color: Color = Color.WHITE
```

`setup()` / `refresh()` 需要读取这些字段。`get_debug_text()` 需要能输出控制效果，例如：

```text
STUN shield_bash_stun (1.2s)
SLOW frost_slow x0.50 (2.5s)
TAUNT guardian_taunt -> Guardian (1.8s)
```

### 6.2 新增 UnitControlState

建议新增：

```text
scripts/combat/unit_control_state.gd
```

职责：

- 保存单位当前最终控制状态。
- 从 `UnitEffectController.effects` 重建。
- 对外提供安全查询，避免直接读取可能已释放的 `forced_target`。

建议字段：

```gdscript
class_name UnitControlState
extends RefCounted

var can_move: bool = true
var can_attack: bool = true
var can_cast: bool = true
var can_retarget: bool = true

var move_speed_multiplier: float = 1.0
var forced_target: Variant = null
var forced_target_unit_id: int = -1

var is_slowed: bool = false
var is_rooted: bool = false
var is_stunned: bool = false
var is_frozen: bool = false
var is_taunted: bool = false

var skill_damage_taken_multiplier: float = 1.0
var active_control_types: Array[String] = []
```

建议方法：

```gdscript
func reset() -> void
func rebuild(owner_unit: Variant, effects: Array[StatusEffect]) -> bool
func get_valid_forced_target(owner_unit: Variant) -> Variant
func has_hard_control() -> bool
func get_ui_tags() -> Array[Dictionary]
```

`rebuild()` 返回状态是否发生变化，用于决定是否刷新 UI 或记录日志。

### 6.3 UnitData 扩展

建议在 `scripts/unit_data.gd` 与 `scripts/unit.gd` 中新增：

```gdscript
@export var control_duration_multiplier: float = 1.0
@export var hard_control_duration_multiplier: float = 1.0
@export var control_immunity_tags: Array[String] = []
```

`scripts/unit_data_applier.gd` 同步复制到运行时 `Unit`。

推荐默认：

| 单位类型 | control_duration_multiplier | hard_control_duration_multiplier | 说明 |
| --- | --- | --- | --- |
| 普通玩家/普通敌人/召唤物 | 1.0 | 1.0 | 完整控制时长 |
| 精英敌人 | 0.8 | 0.6 | 软控略短，硬控明显缩短 |
| Boss | 0.6 | 0.35 | 避免长时间硬控 |

持续时间计算建议：

```text
effective_duration =
    raw_duration
    * (1.0 - status_resistance)
    * control_duration_multiplier
    * (hard_control_duration_multiplier if hard_control else 1.0)
```

注意：

- `status_resistance` 已存在，会影响所有负面状态持续时间。
- 如果 Boss 同时拥有较高 `status_resistance` 和很低控制倍率，最终硬控可能过短。数值表中应避免双重缩减过度。
- 非免疫控制建议保留最小时长，例如硬控最短 0.2 秒、软控最短 0.5 秒，防止效果完全不可感知。

控制免疫：

```text
control_immunity_tags = ["FREEZE", "TAUNT"]
```

第一版可以只做持续时间缩减，免疫字段先预留；若实现免疫，需要返回 `null` 并记录 `CONTROL_RESISTED` 日志。

## 7. 叠层策略

当前项目已有大量叠层策略，但缺少“刷新但不缩短持续时间”和“后施加覆盖旧效果”的显式策略。控制系统建议补充两个策略：

```gdscript
const STACK_POLICY_REFRESH_LONGER_DURATION: String = "REFRESH_LONGER_DURATION"
const STACK_POLICY_REPLACE_BY_LAST: String = "REPLACE_BY_LAST"
```

含义：

- `REFRESH_LONGER_DURATION`：同一组效果已存在时，只在新持续时间更长时刷新持续时间；不会用短持续时间覆盖长持续时间。
- `REPLACE_BY_LAST`：同一组效果已存在时，旧效果过期并移除，新效果生效；适合嘲讽。

控制效果默认建议：

| 控制 | 效果记录 | 最终聚合 | 默认策略 |
| --- | --- | --- | --- |
| 减速 | 可多个来源/多个 effect_id 共存 | 移动倍率取最小 | 同 effect_id/source 刷新较长，不同来源共存 |
| 禁锢 | 可多个来源/多个 effect_id 共存 | 任意存在则不能移动 | 同 effect_id/source 刷新较长 |
| 眩晕 | 可多个来源/多个 effect_id 共存 | 任意存在则不能移动/攻击/施法 | 同 effect_id/source 刷新较长 |
| 冻结 | 可多个来源/多个 effect_id 共存 | 任意存在则不能行动，技能承伤倍率取最大 | 同 effect_id/source 刷新较长 |
| 嘲讽 | 同时只保留最后一个有效嘲讽 | forced target 使用最后来源 | 后施加覆盖旧嘲讽 |

## 8. Factory 接口

`StatusEffectFactory` 建议新增：

```gdscript
func apply_control_effect(
    target: Variant,
    control_type: String,
    source: Variant,
    duration: float,
    options: Dictionary = {}
) -> StatusEffect
```

调用示例：

```gdscript
status_effect_factory.apply_control_effect(target, "STUN", unit, 1.5, {
    "effect_id": "shield_bash_stun",
    "stack_key": "shield_bash_stun",
    "source_mode": UnitEffectController.SOURCE_MODE_PER_SOURCE,
})
```

辅助方法负责：

- 填充 `effect_type = CONTROL`。
- 填充默认字段。
- 根据 `control_type` 自动设置 `disable_*`、UI 文本、颜色和硬控标签。
- 调用现有 `_apply_bond_modifiers()`，为未来羁绊或遗物修改控制数据预留入口。
- 调用目标单位 `apply_status_effect()`。

## 9. UnitEffectController 接入

需要在以下时机重建控制状态：

- 新控制效果创建成功。
- 控制效果刷新。
- 控制效果被替换。
- 控制效果过期。
- 控制效果被 `remove_status_effect()` 移除。
- `clear_status_effects()` 清空。
- 嘲讽来源失效时。

推荐做法：

```gdscript
func _notify_control_state_changed(target_unit: Variant) -> void:
    if _is_valid_unit(target_unit) and target_unit.has_method("rebuild_control_state"):
        target_unit.rebuild_control_state()
```

`Unit` 新增：

```gdscript
var control_state: UnitControlState = UNIT_CONTROL_STATE_SCRIPT.new()

func rebuild_control_state() -> void:
    var changed := control_state.rebuild(self, effect_controller.effects)
    if changed:
        update_info_display()
```

为减少每帧重建，可以先使用“效果变化时重建”。但嘲讽来源死亡/释放属于外部状态变化，建议：

- `UnitTargeting.update_targeting()` 每次使用 forced target 前校验。
- 如果 forced target 无效，调用 `remove_status_effect()` 移除 TAUNT 类控制，或标记控制状态 dirty 后重建。

## 10. 行动系统接入

### 10.1 移动

修改 `UnitTargeting.move_toward_current_target()`：

```gdscript
if unit.control_state != null and not unit.control_state.can_move:
    return

var speed_multiplier := unit.control_state.move_speed_multiplier if unit.control_state != null else 1.0
var move_distance := minf(unit.move_speed * speed_multiplier * delta, distance - desired_distance)
```

禁锢、眩晕、冻结时 `can_move = false`，减速只影响倍率。

### 10.2 普攻

修改 `Unit._attack_current_target()`：

```gdscript
if control_state != null and not control_state.can_attack:
    return
```

攻击冷却仍在 `_process()` 中继续减少。这样眩晕结束后，如果冷却已经完成，可以立刻攻击。

远程弹道规则：

- 已发射 projectile 继续飞行。
- 控制期间不能发射新 projectile。
- 控制不修改已创建的 `AttackPayload`。

### 10.3 技能

修改 `UnitSkill.update()`：

```gdscript
if unit.current_mana >= float(unit.max_mana):
    if unit.control_state != null and not unit.control_state.can_cast:
        return
    var cast_success := try_cast_active_skill(unit)
```

重要：不能把“被控不能施法”当作施法失败后清空魔力。否则眩晕会变相烧掉满魔。

技能目标：

- 敌方目标技能：受嘲讽影响。
- 友方治疗技能：不受嘲讽影响。
- 自身增益技能：不受嘲讽影响。
- 召唤技能：默认不受嘲讽影响，除非召唤位置或目标明确依赖敌方目标。

### 10.4 索敌

`UnitTargeting.find_target()` 开头加入：

```gdscript
var forced_target := unit.control_state.get_valid_forced_target(unit)
if forced_target != null:
    return forced_target
```

`try_retarget_lowest_hp()` 中：

```gdscript
if unit.control_state != null and not unit.control_state.can_retarget:
    return
```

`check_targeting_stuck()` 中：

```gdscript
if unit.control_state != null and unit.control_state.is_taunted:
    if unit.control_state.get_valid_forced_target(unit) != null:
        return
```

### 10.5 伤害与冻结增伤

推荐新增技能伤害入口：

```gdscript
func resolve_skill_damage(caster: Variant, target: Variant, amount: int, context: Dictionary = {}) -> int:
    if _is_valid_unit(target) and target.control_state != null:
        amount = maxi(1, int(round(float(amount) * target.control_state.skill_damage_taken_multiplier)))
    return target.take_damage(amount, caster, bool(context.get("can_crit", false)))
```

后续迁移范围：

- `ActiveSkillCaster` 中所有主动技能直接伤害。
- `AoeResolver.deal_aoe_damage()` 的技能伤害路径。
- 召唤物主动技能。

暂不迁移：

- 普攻。
- DoT：`StatusEffect.EFFECT_DAMAGE_OVER_TIME`。
- 场地持续伤害，除非字段明确标记为技能场地。
- 遗物伤害。

## 11. UI 与显示

第一版建议轻量显示，不做复杂图标资源：

| 控制 | 显示文本 | 推荐颜色 |
| --- | --- | --- |
| 减速 | SLOW | 蓝色 |
| 禁锢 | ROOT | 绿色 |
| 眩晕 | STUN | 黄色 |
| 冻结 | FREEZE | 浅蓝 |
| 嘲讽 | TAUNT | 红色 |

接入方案：

1. `UnitControlState.get_ui_tags()` 返回当前控制标签。
2. `Unit.update_info_display()` 可在单位名后追加短标签，例如 `战士 ★★ [STUN]`。
3. 单位详情 UI 可在基础属性下方增加“当前状态”区域，显示剩余时间和来源。
4. 如果显示拥挤，战斗棋盘只显示最高优先级控制，详情面板显示完整列表。

优先级建议：

```text
FREEZE > STUN > ROOT > TAUNT > SLOW
```

## 12. 日志

复用 `scripts/debug_log.gd`，默认仍由 `auto_battler/debug/combat_log_enabled` 控制。

建议日志事件：

- `CONTROL_APPLIED`
- `CONTROL_REFRESHED`
- `CONTROL_EXPIRED`
- `CONTROL_RESISTED`
- `CONTROL_STATE_CHANGED`
- `TAUNT_TARGET_SET`
- `TAUNT_TARGET_LOST`

日志不要每帧输出，只在状态变化时输出。

示例：

```text
CONTROL_APPLIED: Mage applies STUN to Crossbow Raider for 1.20s
CONTROL_RESISTED: Boss Void Cannon immune to FREEZE
TAUNT_TARGET_LOST: Archer taunt target invalid, resume normal targeting
```

## 13. 边界情况

必须明确处理：

1. 目标被控期间死亡：清空状态效果并重置 `UnitControlState`。
2. 控制来源死亡：除嘲讽外，已有控制继续计时；嘲讽若 forced target 无效则失效。
3. 目标被 `queue_free`：所有 Variant 引用必须先 `is_instance_valid()`，不要用强类型参数直接接收可能释放的 `Unit`。
4. 战斗结束或 Restart：`clear_status_effects()` 后必须 `control_state.reset()`。
5. 召唤物：可以被控制；控制不进入阵容快照。
6. 镜像挑战：镜像单位按普通运行时单位处理控制。
7. 战斗加速：控制持续时间随 `battle_delta` 缩放，与当前状态效果一致。
8. 加时赛：加时赛不改变控制规则。
9. 嘲讽目标不在攻击范围内：移动追击；若被禁锢则等待。
10. 嘲讽目标超出 `search_range`：第一版建议仍视为无效，避免跨全场异常追踪；如果需要全场嘲讽，应给该效果配置 `ignore_search_range = true`。
11. 冻结增伤和通用 `damage_taken_multiplier` 同时存在：冻结作为技能伤害上下文乘区，与通用承伤倍率相乘。
12. 状态抗性接近上限：持续时间不要变成负数或 0 秒；免疫才返回 `null`。

## 14. 文件级实现步骤

### Step 1：扩展数据字段

修改：

- `scripts/status_effect.gd`
- `scripts/unit_data.gd`
- `scripts/unit.gd`
- `scripts/unit_data_applier.gd`

内容：

- 新增 `EFFECT_CONTROL` / `CATEGORY_CONTROL`。
- 新增控制类型常量和控制字段。
- 新增 `control_duration_multiplier`、`hard_control_duration_multiplier`、`control_immunity_tags`。

### Step 2：新增 UnitControlState

新增：

- `scripts/combat/unit_control_state.gd`

内容：

- `reset()`
- `rebuild(owner_unit, effects)`
- `get_valid_forced_target(owner_unit)`
- `get_ui_tags()`

### Step 3：接入 UnitEffectController

修改：

- `scripts/unit_effect_controller.gd`
- `scripts/unit.gd`

内容：

- 控制效果创建、刷新、移除、过期、清空后重建控制状态。
- `Unit.clear_status_effects()` 后重置控制状态。
- `Unit.remove_status_effect()` 后刷新控制状态。

### Step 4：新增 Factory 入口

修改：

- `scripts/combat/status_effect_factory.gd`

内容：

- 新增 `apply_control_effect()`。
- 新增默认控制数据构建。
- 接入控制抗性和免疫检查。

### Step 5：接入移动、普攻、技能

修改：

- `scripts/unit_targeting.gd`
- `scripts/unit.gd`
- `scripts/unit_skill.gd`

内容：

- 移动读取 `can_move` 和 `move_speed_multiplier`。
- 普攻读取 `can_attack`。
- 技能读取 `can_cast`，且被控满魔不清空。

### Step 6：接入嘲讽索敌

修改：

- `scripts/unit_targeting.gd`
- `scripts/combat/active_skill_caster.gd`

内容：

- 普通索敌优先 forced target。
- 低血重选被嘲讽时跳过。
- 卡住检测不清理合法嘲讽目标。
- 敌方目标主动技能统一经过 `_get_offensive_skill_target()`。

### Step 7：接入冻结技能增伤

修改：

- `scripts/combat/combat_resolver.gd`
- `scripts/combat/active_skill_caster.gd`
- `scripts/combat/aoe_resolver.gd`

内容：

- 新增 `resolve_skill_damage()`。
- 主动技能直接伤害迁移到该入口。
- AoE 技能伤害支持 `damage_kind = "skill"`。

### Step 8：UI 与日志

修改：

- `scripts/unit.gd`
- `scripts/ui/unit_detail_panel_controller.gd`
- `scripts/debug_log.gd`（如需要增加分类常量）

内容：

- 棋盘头顶显示简短控制标签。
- 单位详情显示当前控制列表。
- 状态变化时输出调试日志。

### Step 9：测试

新增：

- `scripts/tests/test_control_effect_system.gd`

建议测试：

1. 减速只降低移动速度，不影响攻击和施法。
2. 多个减速同时存在时取最强，强减速过期后弱减速继续生效。
3. 禁锢不能移动，但范围内可攻击、可施法。
4. 眩晕不能移动、普攻、施法；魔力保留。
5. 眩晕前发射的 projectile 仍能命中。
6. 冻结阶段 A 行为等同眩晕。
7. 冻结阶段 B 只增强技能伤害，不增强普攻/DoT/遗物。
8. 嘲讽强制普通索敌。
9. 嘲讽影响敌方目标主动技能，但不影响治疗/护盾技能。
10. 嘲讽来源死亡后恢复正常索敌。
11. Boss 控制时长按倍率缩短。
12. `control_immunity_tags` 生效时不施加控制。
13. 战斗结束、死亡、Restart 后控制状态清空。
14. 战斗加速下控制持续时间按战斗时间缩放。

常用检查命令：

```text
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\control_effect_check.log --check-only --script res://scripts/status_effect.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\control_effect_test.log --script res://scripts/tests/test_control_effect_system.gd
Godot_v4.6.2-stable_win64_console.exe --headless --path . --log-file .godot_user\main_control_check.log --check-only --script res://scripts/main.gd
```

## 15. 第一版验收标准

第一版完成后应能验证：

1. `StatusEffect` 支持 `CONTROL` 类型。
2. `Unit` 拥有 `UnitControlState`。
3. 减速、禁锢、眩晕、冻结、嘲讽均可通过 `StatusEffectFactory.apply_control_effect()` 施加。
4. 控制效果死亡/过期/清空后不会残留行动限制。
5. 减速不会永久修改 `move_speed`。
6. 禁锢不影响范围内攻击和施法。
7. 眩晕/冻结不清空满魔。
8. 远程 projectile 已发射后不因攻击者被控而取消。
9. 嘲讽目标无效后不会报 previously freed 相关错误。
10. Boss / 精英控制时长缩减生效。
11. 单位详情或棋盘头顶能看到控制状态。
12. 现有剧毒、腐痕、治疗、护盾、遗物、羁绊、召唤和弹道系统不被破坏。

## 16. 后续扩展

可在第一版稳定后加入：

- 沉默：不能释放主动技能，但可以移动和普攻。
- 缴械：不能普攻，但可以移动和施法。
- 恐惧：强制远离来源移动。
- 击退/拉拽：短时强制位移，需要路径和碰撞规则。
- 睡眠：不能行动，受到伤害解除。
- 变形：不能攻击/施法，移动速度降低。
- 控制递减：短时间连续受到硬控时，后续硬控时长递减。
- 控制免疫窗口：Boss 被硬控后获得短暂免疫，防止连控。
