# Unit Design Document

> 维护提示：本文档仍作为玩家单位设计长表使用。当前可核对数值请优先查看自动生成的 `docs/content_reference.md`；英雄见 `hero_design.md`，敌人和召唤物以 `content_reference.md` 与对应资源文件为准。新增玩家单位资源应放入 `data/units`，召唤物放入 `data/summons`，敌人放入 `data/enemies`。

This document is the design source for unit attributes, passives, active skills, and star growth.
When adding a new unit later, add its design here first. Implementation should create the matching `.tres` resource and then update the relevant registration points:

- `scripts/unit_data.gd` only when the shared UnitData schema needs a new exported field
- `data/units/*.tres` / `data/summons/*.tres` / `data/enemies/*.tres`
- `scripts/combat/passive_resolver.gd`, `scripts/combat/active_skill_caster.gd`, or related combat resolver files when adding new skill logic
- `scripts/catalog/unit_catalog.gd`, `scripts/roster_manager.gd`, or encounter catalogs when the unit needs to enter a runtime pool
- `scripts/unit_text_formatter.gd` and `scripts/tools/generate_content_reference.gd` when skill or content reference text needs to be shown
- shop, encounter, or reward pools if the unit should appear there

## Runtime Attribute Model

`UnitData` currently supports these unit fields. Runtime combat bonuses are layered through `UnitStatController` in the order `BASE_OVERRIDE -> PERMANENT_FLAT -> PERMANENT_PERCENT -> RUNTIME_FLAT -> RUNTIME_PERCENT -> FINAL_FLAT -> FINAL_PERCENT -> FINAL_MULTIPLY`; resource values below are the base values captured before runtime modifiers.

| Field | Meaning | Default |
| --- | --- | --- |
| `unit_name` | English name / display fallback | `Unit` |
| `unit_name_cn` | Chinese display name. UI prefers this when non-empty. | empty |
| `description_cn` | Chinese short description used by shop, details, and content reference | empty |
| `unit_type` | Unit id / type key | `unit` |
| `catalog_id` | Stable sort id within the current category; used by encyclopedia, content reference, and art pipeline ordering only | `0` |
| `role` | Main lineup role: `tank`, `damage`, or `support` | `damage` |
| `bond_tags` | Synergy/bond tags counted by BondManager | empty |
| `star` | Star level | `1` |
| `rarity` | Unit rarity | `COMMON` |
| `enemy_tier` | Enemy tier override, `NORMAL`, `ELITE`, or `BOSS`; empty for player units | empty |
| `price` | 1-star shop price and sell base price | `2` |
| `max_hp` | Max HP | `100` |
| `attack_damage` | Basic attack damage | `10` |
| `crit_chance` | Critical chance, from `0.0` to `1.0` | `0.0` |
| `crit_damage_multiplier` | Critical damage multiplier | `1.5` |
| `defense` | Defense value | `0` |
| `skill_power` | Active skill damage/healing scaling bonus | `0.0` |
| `healing_power` | Healing output bonus | `0.0` |
| `shield_power` | Shield output bonus | `0.0` |
| `defense_penetration` | Flat defense penetration | `0` |
| `life_steal` | Lifesteal ratio | `0.0` |
| `damage_reduction` | Incoming life damage reduction after shield | `0.0` |
| `damage_taken_multiplier` | Final incoming damage multiplier | `1.0` |
| `initial_mana` | Initial mana at battle start | `0.0` |
| `mana_on_attack` | Mana restored on basic attack hit | `0.0` |
| `mana_on_hit_taken` | Mana restored when taking damage | `0.0` |
| `status_resistance` | Status/debuff resistance ratio | `0.0` |
| `dodge_chance` | Chance to dodge incoming attack | `0.0` |
| `attack_interval` | Seconds between attacks. Lower is faster. | `1.0` |
| `attack_range` | Attack range | `80.0` |
| `search_range` | Target search range | `999.0` |
| `move_speed` | Movement speed | `120.0` |
| `passive_id` | Passive ability id | empty |
| `active_skill_id` | Active skill id | empty |
| `max_mana` | Mana needed to cast active skill | `0` |
| `mana_regen_per_second` | Mana regen during battle | `0.0` |
| `target_mode` | Target mode, `NEAREST` or `LOWEST_HP` | `NEAREST` |
| `retarget_interval` | Retarget check interval | `0.4` |
| `lowest_hp_switch_threshold` | LOWEST_HP switch threshold | `0.1` |
| `basic_attack_type` | Basic attack presentation, `melee` or `projectile` | `melee` |
| `projectile_speed` | Projectile speed for ranged basic attacks | `500.0` |
| `projectile_visual_type` | Projectile visual style | `arrow` |
| `board_sprite` | Board icon/sprite texture | null |
| `portrait_texture` | UI portrait texture | null |
| `icon_texture` | UI icon/avatar texture | null |
| `art_scale` | Board art scale multiplier | `1.0` |
| `art_offset` | Board art offset | `Vector2.ZERO` |

## Damage Rules

Normal attacks and direct active skill damage use the same damage entry:

1. Start from base damage.
2. If attacker can crit, roll `crit_chance`.
3. On crit, multiply by `crit_damage_multiplier`.
4. Apply defender defense:

```text
damage_after_defense = damage_after_crit * 100 / (100 + defense)
```

5. Rounded final damage enters shield first.
6. Remaining damage enters HP.
7. Passives that reduce incoming life damage are applied after shield and before HP loss.
8. Actual effective damage is recorded in battle statistics.

Relic damage currently disables crit, but still uses the normal shield / HP damage path.

## Star Growth Rules

Star growth is applied only when creating runtime battle `UnitData` from the player roster.
Original `.tres` resources are not modified.

Growth fields:

| Field | Meaning |
| --- | --- |
| `max_hp_multiplier` | Multiplies base max HP |
| `attack_damage_multiplier` | Multiplies base attack damage |
| `defense_bonus` | Adds flat defense |
| `attack_interval_multiplier` | Multiplies attack interval. Lower means faster attacks. |
| `move_speed_multiplier` | Multiplies movement speed |
| `crit_chance_bonus` | Adds crit chance |
| `crit_damage_multiplier_bonus` | Adds crit damage multiplier |

Sell price remains based on unit price and star:

| Star | Sell Price |
| --- | --- |
| 1 | `price * 1` |
| 2 | `price * 3` |
| 3 | `price * 9` |

## Passive Abilities

### `armor`

Used by Warrior.

- Normal: incoming HP damage after shield is multiplied by `0.85`.
- 3-star enhanced: incoming HP damage after shield is multiplied by `0.75`.

### `long_shot`

Used by Archer.

- Trigger: target distance >= `attack_range * 0.6`.
- Normal: basic attack damage multiplier `1.15`.
- 3-star enhanced: basic attack damage multiplier `1.25`.

### `execute`

Used by Assassin.

- Normal trigger: target HP ratio <= `0.4`.
- Normal: basic attack damage multiplier `1.25`.
- 3-star trigger: target HP ratio <= `0.5`.
- 3-star enhanced: basic attack damage multiplier `1.4`.

### `fortress`

Used by Tank.

- Normal: incoming HP damage after shield is multiplied by `0.80`.
- Normal low-HP bonus: when current HP ratio is less than or equal to `0.40`, gain `+20` effective defense.
- 3-star enhanced: incoming HP damage after shield is multiplied by `0.70`.
- 3-star low-HP bonus: when current HP ratio is less than or equal to `0.40`, gain `+40` effective defense.

Design intent: Tank is the core damage absorber. Compared with Warrior, Tank has lower damage and mobility, but much stronger survival value.

### `arcane_focus`

Used by Mage.

- Normal: direct active skill damage multiplier is increased by `15%`.
- 3-star enhanced: direct active skill damage multiplier is increased by `30%`.

Design intent: Mage should rely on active skill burst rather than basic attack DPS.

### `benevolence`

Used by Priest.

- Normal: healing effects from this unit are increased by `20%`.
- 3-star enhanced: healing effects from this unit are increased by `40%`.

Design intent: Priest is a healing support unit. Its value comes from keeping allies alive through sustained recovery.

### `battle_song`

Used by Bard.

- Normal: all allied units gain `+8%` attack damage during battle.
- 3-star enhanced: all allied units gain `+12%` attack damage and `+10%` mana regen during battle.

Design intent: Bard is a team amplification support. Its own damage is low, but it increases overall team output and skill tempo.

## Active Skills

Active skills cast automatically when mana reaches `max_mana`.
On a successful cast, mana is reset to `0`.

### `guard_barrier`

Used by Warrior.

Normal:

- Self shield: `30 + max_hp * 0.25`.
- Lowest HP ally shield: `self_shield * 0.4`.

3-star enhanced:

- Self shield: `50 + max_hp * 0.35`.
- Lowest HP ally shield: `self_shield * 0.4`.

### `piercing_arrow`

Used by Archer.

Normal:

- Deals `attack_damage * 1.8` direct skill damage to current target.

3-star enhanced:

- Deals `attack_damage * 2.3` direct skill damage to current target.

Current version does not hit multiple targets.

### `shadow_strike`

Used by Assassin.

Normal:

- Deals `attack_damage * 2.2` direct skill damage to current target.
- If this skill kills the target, heal self for `20`.

3-star enhanced:

- Deals `attack_damage * 2.8` direct skill damage to current target.
- If this skill kills the target, heal self for `40`.

### `stone_guard`

Used by Tank.

Normal:

- Self shield: `40 + max_hp * 0.30`.
- Gain temporary defense: `+25` for `5` seconds.

3-star enhanced:

- Self shield: `70 + max_hp * 0.40`.
- Gain temporary defense: `+45` for `5` seconds.

Implementation note: the project now has a generic `StatusEffect` system, but `stone_guard` currently still applies only the shield effect in code. The temporary defense part has not yet been wired into this skill.

### `fireball`

Used by Mage.

Normal:

- Deals `attack_damage * 3.0` direct skill damage to current target.

3-star enhanced:

- Deals `attack_damage * 4.0` direct skill damage to current target.

Current version does not deal area damage. Future versions may add splash damage to one nearby enemy.

### `holy_light`

Used by Priest.

Normal:

- Heal the allied unit with the lowest HP ratio for `35 + attack_damage * 1.5`.
- If no damaged ally exists, heal self.

3-star enhanced:

- Heal the allied unit with the lowest HP ratio for `60 + attack_damage * 2.0`.
- Also heal self for `50%` of the final healing amount.

### `inspiring_song`

Used by Bard.

Normal:

- All allied units gain shield equal to `15 + attack_damage * 0.8`.
- All allied units gain `+10%` attack damage for `5` seconds.

3-star enhanced:

- All allied units gain shield equal to `25 + attack_damage * 1.2`.
- All allied units gain `+15%` attack damage and `+15%` mana regen for `5` seconds.

Implementation note: the project now has a generic `StatusEffect` system, but `inspiring_song` currently still applies only the all-ally shield effect in code. Timed team attack and mana regen buffs are implemented for newer units such as Guardian Captain and Wind Chanter, but have not yet been wired into this skill.

## Existing Units

Current Chinese display names:

| `unit_type` | English name | Chinese name |
| --- | --- | --- |
| `warrior` | Warrior | 战士 |
| `archer` | Archer | 弓手 |
| `assassin` | Assassin | 刺客 |
| `tank` | Tank | 重装坦克 |
| `mage` | Mage | 法师 |
| `priest` | Priest | 牧师 |
| `bard` | Bard | 吟游诗人 |
| `forest_druid` | Forest Druid | 森林德鲁伊 |
| `plague_caster` | Plague Caster | 瘟疫术士 |
| `guardian_captain` | Guardian Captain | 守护队长 |
| `wind_chanter` | Wind Chanter | 风语者 |

### Warrior

Role: frontline tank.

Resource: `data/units/warrior.tres`

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Warrior` |
| `unit_name_cn` | `战士` |
| `unit_type` | `warrior` |
| `role` | `tank` |
| `price` | `2` |
| `max_hp` | `180` |
| `attack_damage` | `10` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `0` |
| `attack_interval` | `1.1` |
| `attack_range` | `55.0` |
| `search_range` | `999.0` |
| `move_speed` | `75.0` |
| `passive_id` | `armor` |
| `active_skill_id` | `guard_barrier` |
| `max_mana` | `100` |
| `mana_regen_per_second` | `10.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Star growth:

| Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1.0` | `1.0` | `0` | `1.0` | `1.0` | `0.0` | `0.0` |
| 2 | `1.6` | `1.25` | `20` | `1.0` | `1.0` | `0.0` | `0.0` |
| 3 | `2.4` | `1.5` | `45` | `1.0` | `1.0` | `0.0` | `0.0` |

Expected runtime combat attributes before team/relic bonuses:

| Star | Max HP | Attack | Defense | Attack Interval | Move Speed | Crit Chance | Crit Damage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `180` | `10` | `0` | `1.1` | `75.0` | `0%` | `150%` |
| 2 | `288` | `13` | `20` | `1.1` | `75.0` | `0%` | `150%` |
| 3 | `432` | `15` | `45` | `1.1` | `75.0` | `0%` | `150%` |

### Archer

Role: backline sustained damage.

Resource: `data/units/archer.tres`

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Archer` |
| `unit_name_cn` | `弓手` |
| `unit_type` | `archer` |
| `role` | `damage` |
| `price` | `2` |
| `max_hp` | `80` |
| `attack_damage` | `22` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `0` |
| `attack_interval` | `1.2` |
| `attack_range` | `150.0` |
| `search_range` | `999.0` |
| `move_speed` | `95.0` |
| `passive_id` | `long_shot` |
| `active_skill_id` | `piercing_arrow` |
| `max_mana` | `70` |
| `mana_regen_per_second` | `14.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Star growth:

| Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1.0` | `1.0` | `0` | `1.0` | `1.0` | `0.0` | `0.0` |
| 2 | `1.25` | `1.5` | `0` | `0.9` | `1.0` | `0.10` | `0.0` |
| 3 | `1.6` | `2.1` | `0` | `0.75` | `1.0` | `0.20` | `0.25` |

Expected runtime combat attributes before team/relic bonuses:

| Star | Max HP | Attack | Defense | Attack Interval | Move Speed | Crit Chance | Crit Damage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `80` | `22` | `0` | `1.2` | `95.0` | `0%` | `150%` |
| 2 | `100` | `33` | `0` | `1.08` | `95.0` | `10%` | `150%` |
| 3 | `128` | `46` | `0` | `0.9` | `95.0` | `20%` | `175%` |

### Assassin

Role: burst damage, cleanup, mobility.

Resource: `data/units/assassin.tres`

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Assassin` |
| `unit_name_cn` | `刺客` |
| `unit_type` | `assassin` |
| `role` | `damage` |
| `price` | `2` |
| `max_hp` | `115` |
| `attack_damage` | `18` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `0` |
| `attack_interval` | `0.8` |
| `attack_range` | `60.0` |
| `search_range` | `999.0` |
| `move_speed` | `145.0` |
| `passive_id` | `execute` |
| `active_skill_id` | `shadow_strike` |
| `max_mana` | `80` |
| `mana_regen_per_second` | `12.0` |
| `target_mode` | `LOWEST_HP` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Star growth:

| Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1.0` | `1.0` | `0` | `1.0` | `1.0` | `0.0` | `0.0` |
| 2 | `1.3` | `1.55` | `0` | `0.95` | `1.15` | `0.15` | `0.25` |
| 3 | `1.7` | `2.2` | `0` | `0.9` | `1.3` | `0.30` | `0.50` |

Expected runtime combat attributes before team/relic bonuses:

| Star | Max HP | Attack | Defense | Attack Interval | Move Speed | Crit Chance | Crit Damage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `115` | `18` | `0` | `0.8` | `145.0` | `0%` | `150%` |
| 2 | `150` | `28` | `0` | `0.76` | `166.75` | `15%` | `175%` |
| 3 | `196` | `40` | `0` | `0.72` | `188.5` | `30%` | `200%` |

### Tank

Role: core damage absorber.

Resource: `data/units/tank.tres`

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Tank` |
| `unit_name_cn` | `重装坦克` |
| `unit_type` | `tank` |
| `role` | `tank` |
| `price` | `2` |
| `max_hp` | `260` |
| `attack_damage` | `7` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `25` |
| `attack_interval` | `1.35` |
| `attack_range` | `50.0` |
| `search_range` | `999.0` |
| `move_speed` | `55.0` |
| `passive_id` | `fortress` |
| `active_skill_id` | `stone_guard` |
| `max_mana` | `110` |
| `mana_regen_per_second` | `9.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `fortress`
- normal effect:
  - Incoming HP damage after shield is multiplied by `0.80`.
  - When HP ratio <= `0.40`, gain `+20` effective defense.
- 3-star effect:
  - Incoming HP damage after shield is multiplied by `0.70`.
  - When HP ratio <= `0.40`, gain `+40` effective defense.

Active skill:

- id: `stone_guard`
- mana: `110`
- normal effect:
  - Gain shield: `40 + max_hp * 0.30`.
  - Gain temporary defense: `+25` for `5` seconds.
- 3-star effect:
  - Gain shield: `70 + max_hp * 0.40`.
  - Gain temporary defense: `+45` for `5` seconds.

Star growth:

| Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1.0` | `1.0` | `0` | `1.0` | `1.0` | `0.0` | `0.0` |
| 2 | `1.7` | `1.15` | `35` | `1.0` | `1.0` | `0.0` | `0.0` |
| 3 | `2.7` | `1.35` | `80` | `1.0` | `1.0` | `0.0` | `0.0` |

Expected runtime combat attributes before team/relic bonuses:

| Star | Max HP | Attack | Defense | Attack Interval | Move Speed | Crit Chance | Crit Damage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `260` | `7` | `25` | `1.35` | `55.0` | `0%` | `150%` |
| 2 | `442` | `8` | `60` | `1.35` | `55.0` | `0%` | `150%` |
| 3 | `702` | `9` | `105` | `1.35` | `55.0` | `0%` | `150%` |

### Mage

Role: skill damage dealer.

Resource: `data/units/mage.tres`

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Mage` |
| `unit_name_cn` | `法师` |
| `unit_type` | `mage` |
| `role` | `damage` |
| `price` | `2` |
| `max_hp` | `70` |
| `attack_damage` | `26` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `0` |
| `attack_interval` | `1.45` |
| `attack_range` | `135.0` |
| `search_range` | `999.0` |
| `move_speed` | `85.0` |
| `passive_id` | `arcane_focus` |
| `active_skill_id` | `fireball` |
| `max_mana` | `90` |
| `mana_regen_per_second` | `15.0` |
| `target_mode` | `LOWEST_HP` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `arcane_focus`
- normal effect:
  - Direct active skill damage multiplier is increased by `15%`.
- 3-star effect:
  - Direct active skill damage multiplier is increased by `30%`.

Active skill:

- id: `fireball`
- mana: `90`
- normal effect:
  - Deals `attack_damage * 3.0` direct skill damage to current target.
  - This skill can crit.
- 3-star effect:
  - Deals `attack_damage * 4.0` direct skill damage to current target.
  - This skill can crit.

Star growth:

| Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1.0` | `1.0` | `0` | `1.0` | `1.0` | `0.0` | `0.0` |
| 2 | `1.2` | `1.65` | `0` | `0.95` | `1.0` | `0.05` | `0.0` |
| 3 | `1.45` | `2.4` | `0` | `0.9` | `1.0` | `0.10` | `0.25` |

Expected runtime combat attributes before team/relic bonuses:

| Star | Max HP | Attack | Defense | Attack Interval | Move Speed | Crit Chance | Crit Damage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `70` | `26` | `0` | `1.45` | `85.0` | `0%` | `150%` |
| 2 | `84` | `43` | `0` | `1.38` | `85.0` | `5%` | `150%` |
| 3 | `102` | `62` | `0` | `1.31` | `85.0` | `10%` | `175%` |

### Priest

Role: healing support.

Resource: `data/units/priest.tres`

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Priest` |
| `unit_name_cn` | `牧师` |
| `unit_type` | `priest` |
| `role` | `support` |
| `price` | `2` |
| `max_hp` | `95` |
| `attack_damage` | `12` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `0` |
| `attack_interval` | `1.25` |
| `attack_range` | `120.0` |
| `search_range` | `999.0` |
| `move_speed` | `90.0` |
| `passive_id` | `benevolence` |
| `active_skill_id` | `holy_light` |
| `max_mana` | `75` |
| `mana_regen_per_second` | `13.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `benevolence`
- normal effect:
  - Healing effects from this unit are increased by `20%`.
- 3-star effect:
  - Healing effects from this unit are increased by `40%`.

Active skill:

- id: `holy_light`
- mana: `75`
- normal effect:
  - Heal the allied unit with the lowest HP ratio for `35 + attack_damage * 1.5`.
  - If no damaged ally exists, heal self.
- 3-star effect:
  - Heal the allied unit with the lowest HP ratio for `60 + attack_damage * 2.0`.
  - Also heal self for `50%` of the final healing amount.

Star growth:

| Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1.0` | `1.0` | `0` | `1.0` | `1.0` | `0.0` | `0.0` |
| 2 | `1.35` | `1.25` | `5` | `0.95` | `1.0` | `0.0` | `0.0` |
| 3 | `1.8` | `1.55` | `15` | `0.9` | `1.0` | `0.0` | `0.0` |

Expected runtime combat attributes before team/relic bonuses:

| Star | Max HP | Attack | Defense | Attack Interval | Move Speed | Crit Chance | Crit Damage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `95` | `12` | `0` | `1.25` | `90.0` | `0%` | `150%` |
| 2 | `128` | `15` | `5` | `1.19` | `90.0` | `0%` | `150%` |
| 3 | `171` | `19` | `15` | `1.13` | `90.0` | `0%` | `150%` |

### Bard

Role: team amplification support.

Resource: `data/units/bard.tres`

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Bard` |
| `unit_name_cn` | `吟游诗人` |
| `unit_type` | `bard` |
| `role` | `support` |
| `price` | `2` |
| `max_hp` | `105` |
| `attack_damage` | `9` |
| `crit_chance` | `0.0` |
| `crit_damage_multiplier` | `1.5` |
| `defense` | `0` |
| `attack_interval` | `1.15` |
| `attack_range` | `115.0` |
| `search_range` | `999.0` |
| `move_speed` | `100.0` |
| `passive_id` | `battle_song` |
| `active_skill_id` | `inspiring_song` |
| `max_mana` | `95` |
| `mana_regen_per_second` | `11.0` |
| `target_mode` | `NEAREST` |
| `retarget_interval` | `0.4` |
| `lowest_hp_switch_threshold` | `0.1` |

Passive:

- id: `battle_song`
- normal effect:
  - All allied units gain `+8%` attack damage during battle.
- 3-star effect:
  - All allied units gain `+12%` attack damage during battle.
  - All allied units gain `+10%` mana regen during battle.

Active skill:

- id: `inspiring_song`
- mana: `95`
- normal effect:
  - All allied units gain shield equal to `15 + attack_damage * 0.8`.
  - All allied units gain `+10%` attack damage for `5` seconds.
- 3-star effect:
  - All allied units gain shield equal to `25 + attack_damage * 1.2`.
  - All allied units gain `+15%` attack damage and `+15%` mana regen for `5` seconds.

Star growth:

| Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1.0` | `1.0` | `0` | `1.0` | `1.0` | `0.0` | `0.0` |
| 2 | `1.35` | `1.2` | `5` | `0.95` | `1.05` | `0.0` | `0.0` |
| 3 | `1.75` | `1.45` | `15` | `0.9` | `1.1` | `0.0` | `0.0` |

Expected runtime combat attributes before team/relic bonuses:

| Star | Max HP | Attack | Defense | Attack Interval | Move Speed | Crit Chance | Crit Damage |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `105` | `9` | `0` | `1.15` | `100.0` | `0%` | `150%` |
| 2 | `142` | `11` | `5` | `1.09` | `105.0` | `0%` | `150%` |
| 3 | `184` | `13` | `15` | `1.04` | `110.0` | `0%` | `150%` |

## High Rarity Synergy Units

This section records the newly implemented high-rarity units from `synergy_high_rarity_units_design.md`.
Runtime resources live in `data/units/`; the soul puppet summon lives in `data/summons/soul_puppet.tres`.

### Unit Summary

| Unit | `unit_type` | Role | Rarity | Price | Target | HP | Attack | Defense | Interval | Range | Move | Mana | Regen | Passive | Active |
| --- | --- | --- | --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 缚魂祭司 / Soul Binder | `soul_binder` | support | EPIC | 8 | NEAREST | 130 | 14 | 5 | 1.30 | 125 | 90 | 90 | 13 | `soul_thread` | `binding_rite` |
| 星铸禁卫 / Starforged Vanguard | `starforged_vanguard` | tank | EPIC | 8 | NEAREST | 300 | 11 | 35 | 1.35 | 55 | 55 | 115 | 8 | `starforged_body` | `astral_bulwark` |
| 奥术炮师 / Arcane Artillerist | `arcane_artillerist` | damage | EPIC | 8 | LOWEST_HP | 100 | 32 | 0 | 1.55 | 155 | 75 | 120 | 12 | `overload_core` | `arcane_barrage` |
| 剧毒女王 / Venom Matriarch | `venom_matriarch` | damage | EPIC | 8 | LOWEST_HP | 120 | 22 | 5 | 1.25 | 135 | 85 | 100 | 13 | `venom_brood` | `feast_of_venom` |
| 晨钟圣徒 / Dawnbell Saint | `dawnbell_saint` | support | LEGENDARY | 10 | NEAREST | 180 | 18 | 12 | 1.25 | 130 | 85 | 110 | 12 | `dawnbell_echo` | `bell_of_sanctuary` |
| 夜刃统领 / Nightblade Captain | `nightblade_captain` | damage | EPIC | 8 | LOWEST_HP | 150 | 28 | 5 | 0.95 | 75 | 145 | 85 | 13 | `nightblade_order` | `reaping_command` |
| 血契狂战 / Bloodbound Berserker | `bloodbound_berserker` | damage | RARE | 6 | NEAREST | 190 | 24 | 8 | 1.05 | 60 | 95 | 90 | 10 | `bloodbound_rage` | `blood_debt_slash` |
| 棱镜术师 / Prism Weaver | `prism_weaver` | support | RARE | 6 | NEAREST | 115 | 13 | 2 | 1.25 | 130 | 90 | 95 | 12 | `prism_refraction` | `focus_beam` |

### Summon Summary

| Unit | `unit_type` | Role | Rarity | HP | Attack | Defense | Interval | Range | Move | Mana | Regen | Passive | Active |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| 魂偶 / Soul Puppet | `summoned_soul_puppet` | tank | COMMON | 120 | 10 | 8 | 1.20 | 50 | 105 | 80 | 7 | `summoned_puppet_body` | `summoned_puppet_guard` |

### Passive Abilities

#### `soul_thread`

Used by Soul Binder.

- Normal: when an allied summon dies, restore `12` mana to Soul Binder. When an allied non-summon unit dies, restore `25` mana and grant `30` shield to the lowest HP-ratio ally.
- 3-star enhanced: summon death mana becomes `18`; non-summon death mana becomes `35`; grant `45` shield to the two lowest HP-ratio allies.

#### `starforged_body`

Used by Starforged Vanguard.

- Normal: for each allied 2-star unit on the player team, gain `+6` defense. For each allied 3-star unit, gain an additional `+12` defense and `25` shield.
- 3-star enhanced: each 2-star unit grants `+10` defense; each 3-star unit grants an additional `+20` defense and `40` shield.

#### `overload_core`

Used by Arcane Artillerist.

- Normal: when this unit gains mana from another unit or effect, has `25%` chance to gain `8` extra mana. This extra mana cannot trigger the passive again.
- 3-star enhanced: trigger chance becomes `50%`; extra mana becomes `12`.

#### `venom_brood`

Used by Venom Matriarch.

- Normal: every `4` player-team damage events against enemies apply `1` venom stack to the damaged target.
- 3-star enhanced: threshold becomes every `2` damage events.

Venom stack implementation: `venom_stack`, damage over time, `6` seconds, `5` damage per second per stack. The target keeps a single merged venom status: new venom adds stack count and refreshes duration; after duration ends, venom does not clear immediately and instead decays by `5` stacks per tick until removed.

#### `dawnbell_echo`

Used by Dawnbell Saint.

- Normal: player-team overhealing converts `70%` of overflow healing into shield. Once per battle, if a player unit would die and Dawnbell Saint is alive, prevent death, set target HP to `50%` max HP, and grant `100` shield.
- 3-star enhanced: overheal shield conversion becomes `150%`; death prevention can trigger `3` times per battle, restores target to `100%` max HP, and grants `250` shield.

Implementation note: death prevention is checked after the target's own incoming-damage passive reduction, so units with their own mitigation can still be saved.

#### `nightblade_order`

Used by Nightblade Captain.

- Normal: at battle start, all player Archers and Assassins gain `+15%` crit chance. Player Archers and Assassins deal `+25%` basic attack damage to targets below `50%` HP.
- 3-star enhanced: crit chance bonus becomes `+25%`; low-HP damage bonus becomes `+60%`.

#### `bloodbound_rage`

Used by Bloodbound Berserker.

- Normal: below `50%` HP, basic attack damage `+20%` and life steal `+10%`; below `25%` HP, basic attack damage `+35%` and life steal `+20%`.
- 3-star enhanced: below `70%` HP, basic attack damage `+40%` and life steal `+20%`; below `30%` HP, basic attack damage `+70%` and life steal `+35%`.

#### `prism_refraction`

Used by Prism Weaver.

- Normal: when a player unit deals active skill damage, has `40%` chance to increase that skill damage by `25%`.
- 3-star enhanced: trigger chance becomes `70%`; damage increase becomes `50%`.

### Active Skills

#### `binding_rite`

Used by Soul Binder.

- Mana: `90`.
- Normal: mark current target for `10` seconds. If the marked target dies during the mark, summon `1` Soul Puppet at the target position. The Soul Puppet gains bonus max HP and attack equal to `50%` of the marked target's values.
- 3-star enhanced: mark duration becomes `15` seconds; inherited HP and attack become `100%`; Soul Puppet gains `50` initial shield.

#### `astral_bulwark`

Used by Starforged Vanguard.

- Mana: `115`.
- Normal: gain shield equal to `80 + max_hp * 0.20`. If the player team has at least one 3-star unit, all allied units gain extra shield equal to `20%` of the self shield.
- 3-star enhanced: self shield becomes `120 + max_hp * 0.30`; all allied units gain extra shield equal to `35%` of the self shield; allied 3-star units also gain `15%` damage reduction for `5` seconds.

#### `arcane_barrage`

Used by Arcane Artillerist.

- Mana: `120`.
- Normal: around current target, deal `attack_damage * 2.4` skill damage to all enemies within radius `120`. For each enemy hit, all player units restore `2` mana.
- 3-star enhanced: radius becomes `145`; damage becomes `attack_damage * 3.6`; if at least `3` enemies are hit, all player units restore `15` mana.

#### `feast_of_venom`

Used by Venom Matriarch.

- Mana: `100`.
- Normal: apply `1` venom stack to every enemy, then deal burst damage to current target equal to `current venom stack count * attack_damage * 0.30`. Does not remove venom stacks.
- 3-star enhanced: apply `3` venom stacks to every enemy, double the current target's venom stacks before the burst, and use `current venom stack count * attack_damage * 0.50`.

#### `bell_of_sanctuary`

Used by Dawnbell Saint.

- Mana: `110`.
- Normal: heal all player units for `40 + target.max_hp * 0.15`, and grant `30` shield.
- 3-star enhanced: heal becomes `100 + target.max_hp * 0.25`, shield becomes `60`, and all player units restore `30` mana.

#### `reaping_command`

Used by Nightblade Captain.

- Mana: `85`.
- Normal: deal `attack_damage * 3.6` skill damage to the enemy with the lowest HP ratio. If it kills the target, all player Archers and Assassins restore `20` mana and gain `+50%` crit damage for `5` seconds.
- 3-star enhanced: damage becomes `attack_damage * 5.0`; kill reward becomes `35` mana, `+100%` crit damage, and `+15%` crit chance for `5` seconds.

#### `blood_debt_slash`

Used by Bloodbound Berserker.

- Mana: `90`.
- Normal: spend `10%` current HP, never dropping below `1` HP, then deal `attack_damage * 2.5` skill damage to current target. Heal self for `35%` of actual damage dealt.
- 3-star enhanced: HP cost becomes `8%`; damage becomes `attack_damage * 3.2`; heal ratio becomes `70%`.

#### `focus_beam`

Used by Prism Weaver.

- Mana: `95`.
- Normal: buff the allied unit with the highest skill power for `5` seconds, granting `+50%` skill power and `+10%` crit chance.
- 3-star enhanced: duration becomes `7` seconds; bonuses become `+80%` skill power and `+20%` crit chance; target also restores `25` mana.

### Star Growth

| Unit | Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `soul_binder` | 2 | 1.30 | 1.25 | 8 | 0.95 | 1.00 | 0.00 | 0.00 |
| `soul_binder` | 3 | 1.75 | 1.55 | 20 | 0.90 | 1.00 | 0.00 | 0.00 |
| `starforged_vanguard` | 2 | 1.65 | 1.18 | 35 | 1.00 | 1.00 | 0.00 | 0.00 |
| `starforged_vanguard` | 3 | 2.45 | 1.40 | 80 | 1.00 | 1.00 | 0.00 | 0.00 |
| `arcane_artillerist` | 2 | 1.22 | 1.55 | 0 | 0.95 | 1.00 | 0.05 | 0.00 |
| `arcane_artillerist` | 3 | 1.55 | 2.20 | 0 | 0.90 | 1.00 | 0.12 | 0.30 |
| `venom_matriarch` | 2 | 1.25 | 1.45 | 6 | 0.95 | 1.00 | 0.05 | 0.00 |
| `venom_matriarch` | 3 | 1.65 | 2.00 | 18 | 0.90 | 1.00 | 0.10 | 0.25 |
| `dawnbell_saint` | 2 | 1.35 | 1.25 | 12 | 0.95 | 1.00 | 0.00 | 0.00 |
| `dawnbell_saint` | 3 | 1.90 | 1.65 | 30 | 0.90 | 1.00 | 0.00 | 0.00 |
| `nightblade_captain` | 2 | 1.30 | 1.50 | 5 | 0.92 | 1.10 | 0.12 | 0.30 |
| `nightblade_captain` | 3 | 1.75 | 2.15 | 15 | 0.85 | 1.20 | 0.25 | 0.65 |
| `bloodbound_berserker` | 2 | 1.45 | 1.45 | 12 | 0.95 | 1.05 | 0.10 | 0.20 |
| `bloodbound_berserker` | 3 | 2.00 | 2.05 | 30 | 0.90 | 1.10 | 0.20 | 0.45 |
| `prism_weaver` | 2 | 1.30 | 1.25 | 5 | 0.95 | 1.00 | 0.00 | 0.00 |
| `prism_weaver` | 3 | 1.70 | 1.55 | 15 | 0.90 | 1.00 | 0.05 | 0.00 |
| `summoned_soul_puppet` | 2 | 1.55 | 1.35 | 12 | 0.95 | 1.05 | 0.00 | 0.00 |
| `summoned_soul_puppet` | 3 | 2.15 | 1.75 | 30 | 0.90 | 1.10 | 0.05 | 0.15 |

## New Unit Design Template

Use this template when designing a new unit.

### Unit Name

Role:

Resource path:

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | |
| `unit_name_cn` | |
| `unit_type` | |
| `role` | |
| `price` | |
| `max_hp` | |
| `attack_damage` | |
| `crit_chance` | |
| `crit_damage_multiplier` | |
| `defense` | |
| `attack_interval` | |
| `attack_range` | |
| `search_range` | |
| `move_speed` | |
| `passive_id` | |
| `active_skill_id` | |
| `max_mana` | |
| `mana_regen_per_second` | |
| `target_mode` | |
| `retarget_interval` | |
| `lowest_hp_switch_threshold` | |

Passive:

- id:
- normal effect:
- 3-star effect:

Active skill:

- id:
- mana:
- normal effect:
- 3-star effect:

Star growth:

| Star | HP Mult | Attack Mult | Defense Bonus | Attack Interval Mult | Move Speed Mult | Crit Chance Bonus | Crit Damage Bonus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `1.0` | `1.0` | `0` | `1.0` | `1.0` | `0.0` | `0.0` |
| 2 | | | | | | | |
| 3 | | | | | | | |
