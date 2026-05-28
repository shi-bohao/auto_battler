> 历史草案：本文档记录 Tank、Mage、Priest、Bard 等早期新增单位与被动能力的设计过程。相关单位已经实现并进入当前资源池；后续高稀有度单位、运行时属性修饰器和当前数值不再维护在本文档中，最新内容请查看 `docs/content_reference.md`、`docs/unit_design.md` 与 `docs/bond_system.md`。

## Additional Passive Abilities

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

## Additional Active Skills

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

## Additional Units

### Tank

Role: core damage absorber.

Resource: `data/units/tank.tres`

Base attributes:

| Attribute | Value |
| --- | --- |
| `unit_name` | `Tank` |
| `unit_name_cn` | `重装坦克` |
| `unit_type` | `tank` |
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
  - This skill can crit if the current skill damage path supports crit.
- 3-star effect:
  - Deals `attack_damage * 4.0` direct skill damage to current target.
  - This skill can crit if the current skill damage path supports crit.

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
