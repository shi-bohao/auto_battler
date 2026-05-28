class_name RelicManager
extends RefCounted


const RELIC_INVENTORY_SCRIPT: Script = preload("res://scripts/relic/relic_inventory.gd")
const RELIC_REWARD_POOL_SCRIPT: Script = preload("res://scripts/relic/relic_reward_pool.gd")
const RELIC_EFFECT_RESOLVER_SCRIPT: Script = preload("res://scripts/relic/relic_effect_resolver.gd")
const RELIC_TRIGGER_DISPATCHER_SCRIPT: Script = preload("res://scripts/relic/relic_trigger_dispatcher.gd")

var relic_inventory: Variant = RELIC_INVENTORY_SCRIPT.new()
var relic_reward_pool: Variant = RELIC_REWARD_POOL_SCRIPT.new()
var relic_effect_resolver: Variant = RELIC_EFFECT_RESOLVER_SCRIPT.new()
var relic_trigger_dispatcher: Variant = RELIC_TRIGGER_DISPATCHER_SCRIPT.new()
var relic_damage_dealt: int = 0
var owner_team_id: int = 1
var battle_start_gold_context: int = 0
var battle_gold_accumulator: int = 0
var gold_add_callback: Callable = Callable()
var get_gold_callable: Callable = Callable()


func _init() -> void:
	relic_effect_resolver.setup(self)
	relic_trigger_dispatcher.setup(self, relic_effect_resolver)


func clear_relics() -> void:
	relic_inventory.clear()
	reset_battle_relic_state()
	print_player_relics()


func reset_battle_stats() -> void:
	relic_damage_dealt = 0


func set_battle_gold_context(gold: int) -> void:
	battle_start_gold_context = gold
	battle_gold_accumulator = 0


func get_battle_gold_context() -> int:
	return battle_start_gold_context


func collect_battle_gold() -> int:
	var collected: int = battle_gold_accumulator
	battle_gold_accumulator = 0
	return collected


func set_gold_callback(callback: Callable) -> void:
	gold_add_callback = callback


func set_gold_query_callback(callback: Callable) -> void:
	get_gold_callable = callback


func get_live_gold() -> int:
	if not get_gold_callable.is_null():
		return int(get_gold_callable.call())
	return battle_start_gold_context


func _add_battle_gold(amount: int) -> void:
	battle_gold_accumulator += amount
	if not gold_add_callback.is_null():
		gold_add_callback.call(amount)


func trigger_round_reward_relics(encounter_type: String, current_round: int, max_round: int, pre_reward_gold: int, base_reward_gold: int) -> Dictionary:
	return relic_trigger_dispatcher.trigger_round_reward_relics(encounter_type, current_round, max_round, pre_reward_gold, base_reward_gold)


func reset_battle_relic_state() -> void:
	battle_gold_accumulator = 0
	relic_trigger_dispatcher.reset_battle_relic_state()


func refresh_dynamic_relic_auras_for_unit(unit: Unit) -> void:
	if not has_dynamic_gold_relics():
		return

	if relic_effect_resolver != null and relic_effect_resolver.has_method("refresh_dynamic_gold_relics_to_unit"):
		relic_effect_resolver.refresh_dynamic_gold_relics_to_unit(unit)


func refresh_dynamic_relic_auras_for_units(units: Array[Unit]) -> void:
	if not has_dynamic_gold_relics():
		return

	for unit: Unit in units:
		refresh_dynamic_relic_auras_for_unit(unit)


func has_dynamic_gold_relics() -> bool:
	if relic_effect_resolver == null or not relic_effect_resolver.has_method("has_dynamic_gold_relics"):
		return false

	return bool(relic_effect_resolver.has_dynamic_gold_relics())


func set_owner_team_id(team_id: int) -> void:
	owner_team_id = team_id


func get_owner_team_id() -> int:
	return owner_team_id


func add_relic(relic_data: Resource) -> void:
	if relic_inventory.add_relic(
		relic_data,
		Callable(self, "get_relic_unique_key"),
		Callable(self, "get_relic_debug_name")
	):
		print_player_relics()


func has_relic(relic_data: Resource) -> bool:
	return relic_inventory.has_relic(relic_data, Callable(self, "get_relic_unique_key"))


func has_relic_id(relic_id: String) -> bool:
	return relic_inventory.has_relic_id(relic_id, Callable(self, "get_relic_id"))


func get_relic_by_id(relic_id: String) -> Resource:
	return relic_inventory.get_relic_by_id(relic_id, Callable(self, "get_relic_id"))


func get_relic_data_by_id(relic_id: String) -> Resource:
	return relic_reward_pool.get_relic_data_by_id(relic_id, Callable(self, "get_relic_id"))


func get_player_relics() -> Array[Resource]:
	return relic_inventory.get_all_relics()


func restore_relic_ids(relic_ids: Array[String]) -> void:
	relic_inventory.clear()
	for relic_id: String in relic_ids:
		var relic_data: Resource = get_relic_data_by_id(relic_id)
		if relic_data == null:
			push_warning("Cannot restore unknown relic id: " + relic_id)
			continue

		add_relic(relic_data)


func print_player_relics() -> void:
	relic_inventory.print_relics(Callable(self, "get_relic_debug_name"))


func get_relic_debug_name(relic_data: Resource) -> String:
	var relic_name: String = get_relic_name(relic_data)
	var relic_id: String = get_relic_id(relic_data)
	var rarity: String = get_relic_rarity(relic_data)

	var debug_name: String = relic_name
	if relic_id != "":
		debug_name += " [" + relic_id + "]"
	if rarity != "":
		debug_name += " (" + rarity + ")"

	return debug_name


func get_relic_unique_key(relic_data: Resource) -> String:
	var relic_id: String = get_relic_id(relic_data)
	if relic_id != "":
		return relic_id

	return get_relic_name(relic_data)


func get_relic_id(relic_data: Resource) -> String:
	if relic_data == null:
		return ""

	var configured_id: Variant = relic_data.get("relic_id")
	if configured_id == null:
		return ""

	return str(configured_id)


func get_relic_name(relic_data: Resource) -> String:
	if relic_data == null:
		return "遗物"

	var configured_cn_name: Variant = relic_data.get("relic_name_cn")
	if configured_cn_name != null and str(configured_cn_name).strip_edges() != "":
		return str(configured_cn_name)

	var configured_name: Variant = relic_data.get("relic_name")
	if configured_name == null:
		return "遗物"

	return str(configured_name)


func get_relic_description(relic_data: Resource) -> String:
	if relic_data == null:
		return ""

	var configured_cn_description: Variant = relic_data.get("description_cn")
	if configured_cn_description != null and str(configured_cn_description).strip_edges() != "":
		return str(configured_cn_description)

	var configured_description: Variant = relic_data.get("description")
	if configured_description == null:
		return ""

	return str(configured_description)


func get_relic_rarity(relic_data: Resource) -> String:
	if relic_data == null:
		return ""

	var configured_rarity: Variant = relic_data.get("rarity")
	if configured_rarity == null:
		return ""

	return str(configured_rarity)


func get_relic_trigger_type(relic_data: Resource) -> String:
	if relic_data == null:
		return ""

	var configured_trigger_type: Variant = relic_data.get("trigger_type")
	if configured_trigger_type == null:
		return ""

	return str(configured_trigger_type)


func get_relic_value(relic_data: Resource, default_value: float) -> float:
	if relic_data == null:
		return default_value

	var configured_value: Variant = relic_data.get("value")
	if configured_value == null:
		return default_value

	return float(configured_value)


func get_available_relic_reward_options() -> Array[Dictionary]:
	return relic_reward_pool.get_available_relic_reward_options(
		Callable(self, "has_relic"),
		Callable(self, "get_relic_id"),
		Callable(self, "get_relic_name"),
		Callable(self, "get_relic_description"),
		Callable(self, "get_relic_rarity")
	)


func trigger_battle_start_relics(player_units: Array[Unit]) -> void:
	relic_trigger_dispatcher.trigger_battle_start_relics(player_units)


func apply_always_on_relics_to_runtime_unit(unit: Unit) -> void:
	relic_effect_resolver.apply_always_on_relics_to_unit(unit)


func trigger_attack_relics(attacker: Unit, target: Unit) -> void:
	relic_trigger_dispatcher.trigger_attack_relics(attacker, target)


func trigger_kill_relics(attacker: Unit, target: Unit, roster_manager: Variant = null, hero_manager: Variant = null) -> void:
	relic_trigger_dispatcher.trigger_kill_relics(attacker, target, roster_manager, hero_manager)


func trigger_death_relics(dead_unit: Unit, enemy_units: Array[Unit], is_battle_active: bool, player_units: Array[Unit]) -> void:
	relic_trigger_dispatcher.trigger_death_relics(dead_unit, enemy_units, is_battle_active, player_units)
