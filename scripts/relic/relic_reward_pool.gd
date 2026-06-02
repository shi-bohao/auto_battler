class_name RelicRewardPool
extends RefCounted


const REWARD_TYPE_RELIC: String = "RELIC"

const BATTLE_BANNER_RELIC_DATA: Resource = preload("res://data/relics/battle_banner.tres")
const IRON_ARMOR_BADGE_RELIC_DATA: Resource = preload("res://data/relics/iron_armor_badge.tres")
const BLOOD_PENDANT_RELIC_DATA: Resource = preload("res://data/relics/blood_pendant.tres")
const SOUL_LANTERN_RELIC_DATA: Resource = preload("res://data/relics/soul_lantern.tres")
const EXECUTIONER_SIGIL_RELIC_DATA: Resource = preload("res://data/relics/executioner_sigil.tres")
const VICTORY_DRUM_RELIC_DATA: Resource = preload("res://data/relics/victory_drum.tres")
const HUNTER_MARK_RELIC_DATA: Resource = preload("res://data/relics/hunter_mark.tres")
const VENGEANCE_SPARK_RELIC_DATA: Resource = preload("res://data/relics/vengeance_spark.tres")
const STEEL_FORMATION_RELIC_DATA: Resource = preload("res://data/relics/steel_formation.tres")
const SHARP_EDGE_RELIC_DATA: Resource = preload("res://data/relics/sharp_edge.tres")
const BROKEN_FANG_RELIC_DATA: Resource = preload("res://data/relics/broken_fang.tres")
const ARCANE_CORE_RELIC_DATA: Resource = preload("res://data/relics/arcane_core.tres")
const FIRST_SPARK_RELIC_DATA: Resource = preload("res://data/relics/first_spark.tres")
const GUARDIAN_OATH_RELIC_DATA: Resource = preload("res://data/relics/guardian_oath.tres")
const LAST_STAND_RELIC_DATA: Resource = preload("res://data/relics/last_stand.tres")
const SOUL_EMBER_RELIC_DATA: Resource = preload("res://data/relics/soul_ember.tres")
const DUELIST_GLOVE_RELIC_DATA: Resource = preload("res://data/relics/duelist_glove.tres")
const MAGE_LENS_RELIC_DATA: Resource = preload("res://data/relics/mage_lens.tres")
const HEALING_BELL_RELIC_DATA: Resource = preload("res://data/relics/healing_bell.tres")
const RESONANCE_HARP_RELIC_DATA: Resource = preload("res://data/relics/resonance_harp.tres")
const STAR_CROWN_RELIC_DATA: Resource = preload("res://data/relics/star_crown.tres")
const CROWN_OF_THREE_RELIC_DATA: Resource = preload("res://data/relics/crown_of_three.tres")
const BACKLINE_SCOPE_RELIC_DATA: Resource = preload("res://data/relics/backline_scope.tres")
const FRONTLINE_PLATE_RELIC_DATA: Resource = preload("res://data/relics/frontline_plate.tres")
const ARCANE_PRISM_RELIC_DATA: Resource = preload("res://data/relics/arcane_prism.tres")
const MERCY_CENSER_RELIC_DATA: Resource = preload("res://data/relics/mercy_censer.tres")
const PIERCING_WHETSTONE_RELIC_DATA: Resource = preload("res://data/relics/piercing_whetstone.tres")
const BLOODGLASS_CHARM_RELIC_DATA: Resource = preload("res://data/relics/bloodglass_charm.tres")
const BULWARK_RUNE_RELIC_DATA: Resource = preload("res://data/relics/bulwark_rune.tres")
const OPENING_TOME_RELIC_DATA: Resource = preload("res://data/relics/opening_tome.tres")
const DYNAMO_NEEDLE_RELIC_DATA: Resource = preload("res://data/relics/dynamo_needle.tres")
const MIRAGE_CLOAK_RELIC_DATA: Resource = preload("res://data/relics/mirage_cloak.tres")
const GRAVEBONE_CHARM_RELIC_DATA: Resource = preload("res://data/relics/gravebone_charm.tres")
const VITALITY_TROPHY_RELIC_DATA: Resource = preload("res://data/relics/vitality_trophy.tres")
const OLD_COIN_POUCH_RELIC_DATA: Resource = preload("res://data/relics/old_coin_pouch.tres")
const SPOILS_LEDGER_RELIC_DATA: Resource = preload("res://data/relics/spoils_ledger.tres")
const BOUNTY_DAGGER_RELIC_DATA: Resource = preload("res://data/relics/bounty_dagger.tres")
const INVESTMENT_LEDGER_RELIC_DATA: Resource = preload("res://data/relics/investment_ledger.tres")
const GOLDEN_ARMOR_CONTRACT_RELIC_DATA: Resource = preload("res://data/relics/golden_armor_contract.tres")
const GOLDEN_CHARM_RELIC_DATA: Resource = preload("res://data/relics/golden_charm.tres")
const GOLDHUNTER_CONTRACT_RELIC_DATA: Resource = preload("res://data/relics/goldhunter_contract.tres")
const COMPOUND_CORE_RELIC_DATA: Resource = preload("res://data/relics/compound_core.tres")
const CROWN_OF_GREED_RELIC_DATA: Resource = preload("res://data/relics/crown_of_greed.tres")

var _relic_data_list: Array[Resource] = [
	BATTLE_BANNER_RELIC_DATA,
	IRON_ARMOR_BADGE_RELIC_DATA,
	BLOOD_PENDANT_RELIC_DATA,
	SOUL_LANTERN_RELIC_DATA,
	EXECUTIONER_SIGIL_RELIC_DATA,
	VICTORY_DRUM_RELIC_DATA,
	HUNTER_MARK_RELIC_DATA,
	VENGEANCE_SPARK_RELIC_DATA,
	STEEL_FORMATION_RELIC_DATA,
	SHARP_EDGE_RELIC_DATA,
	BROKEN_FANG_RELIC_DATA,
	ARCANE_CORE_RELIC_DATA,
	FIRST_SPARK_RELIC_DATA,
	GUARDIAN_OATH_RELIC_DATA,
	LAST_STAND_RELIC_DATA,
	SOUL_EMBER_RELIC_DATA,
	DUELIST_GLOVE_RELIC_DATA,
	MAGE_LENS_RELIC_DATA,
	HEALING_BELL_RELIC_DATA,
	RESONANCE_HARP_RELIC_DATA,
	STAR_CROWN_RELIC_DATA,
	CROWN_OF_THREE_RELIC_DATA,
	BACKLINE_SCOPE_RELIC_DATA,
	FRONTLINE_PLATE_RELIC_DATA,
	ARCANE_PRISM_RELIC_DATA,
	MERCY_CENSER_RELIC_DATA,
	PIERCING_WHETSTONE_RELIC_DATA,
	BLOODGLASS_CHARM_RELIC_DATA,
	BULWARK_RUNE_RELIC_DATA,
	OPENING_TOME_RELIC_DATA,
	DYNAMO_NEEDLE_RELIC_DATA,
	MIRAGE_CLOAK_RELIC_DATA,
	GRAVEBONE_CHARM_RELIC_DATA,
	VITALITY_TROPHY_RELIC_DATA,
	OLD_COIN_POUCH_RELIC_DATA,
	SPOILS_LEDGER_RELIC_DATA,
	BOUNTY_DAGGER_RELIC_DATA,
	INVESTMENT_LEDGER_RELIC_DATA,
	GOLDEN_ARMOR_CONTRACT_RELIC_DATA,
	GOLDEN_CHARM_RELIC_DATA,
	GOLDHUNTER_CONTRACT_RELIC_DATA,
	COMPOUND_CORE_RELIC_DATA,
	CROWN_OF_GREED_RELIC_DATA,
]


func get_available_relic_reward_options(
	has_relic_func: Callable,
	get_relic_id_func: Callable,
	get_relic_name_func: Callable,
	get_relic_description_func: Callable,
	get_relic_rarity_func: Callable
) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	for relic_data in _get_sorted_relic_data_list():
		_append_relic_reward_if_available(
			rewards,
			relic_data,
			has_relic_func,
			get_relic_id_func,
			get_relic_name_func,
			get_relic_description_func,
			get_relic_rarity_func
		)

	return rewards


func get_relic_data_by_id(relic_id: String, get_relic_id_func: Callable) -> Resource:
	if relic_id.strip_edges() == "":
		return null

	for relic_data in _relic_data_list:
		if relic_data == null:
			continue

		if _call_string(get_relic_id_func, relic_data) == relic_id:
			return relic_data

	return null


func _append_relic_reward_if_available(
	rewards: Array[Dictionary],
	relic_data: Resource,
	has_relic_func: Callable,
	get_relic_id_func: Callable,
	get_relic_name_func: Callable,
	get_relic_description_func: Callable,
	get_relic_rarity_func: Callable
) -> void:
	if relic_data == null:
		return

	if _call_bool(has_relic_func, relic_data):
		return

	rewards.append({
		"type": REWARD_TYPE_RELIC,
		"id": _call_string(get_relic_id_func, relic_data),
		"name": _call_string(get_relic_name_func, relic_data),
		"description": _call_string(get_relic_description_func, relic_data),
		"rarity": _call_string(get_relic_rarity_func, relic_data),
		"relic_data": relic_data,
	})


func _call_bool(function: Callable, value: Resource) -> bool:
	if function.is_null():
		return false

	return bool(function.call(value))


func _call_string(function: Callable, value: Resource) -> String:
	if function.is_null():
		return ""

	return str(function.call(value))


func _get_sorted_relic_data_list() -> Array[Resource]:
	var relics: Array[Resource] = []
	for relic_data: Resource in _relic_data_list:
		if relic_data != null:
			relics.append(relic_data)
	relics.sort_custom(Callable(self, "_sort_relics_by_catalog_id"))
	return relics


func _sort_relics_by_catalog_id(a: Resource, b: Resource) -> bool:
	var a_catalog_id: int = _get_catalog_id(a)
	var b_catalog_id: int = _get_catalog_id(b)
	if a_catalog_id > 0 and b_catalog_id > 0 and a_catalog_id != b_catalog_id:
		return a_catalog_id < b_catalog_id
	if a_catalog_id > 0 and b_catalog_id <= 0:
		return true
	if a_catalog_id <= 0 and b_catalog_id > 0:
		return false
	return str(a.resource_path) < str(b.resource_path)


func _get_catalog_id(relic_data: Resource) -> int:
	if relic_data == null:
		return 0

	var value: Variant = relic_data.get("catalog_id")
	if value == null:
		return 0

	return maxi(0, int(value))
