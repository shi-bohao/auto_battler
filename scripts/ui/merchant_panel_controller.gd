class_name MerchantPanelController
extends RefCounted

const RELIC_ICON_HELPER: Script = preload("res://scripts/ui/relic_icon_helper.gd")


signal item_purchased(item: Dictionary)
signal leave_requested()


var panel: Panel = null
var title_label: Label = null
var gold_label: Label = null
var refresh_button: Button = null
var leave_button: Button = null
var relic_buttons: Array[Button] = []
var special_buttons: Array[Button] = []
var merchant_manager: Variant = null
var economy_manager: Variant = null


func setup(
	panel_value: Panel,
	title_label_value: Label,
	gold_label_value: Label,
	refresh_button_value: Button,
	leave_button_value: Button,
	relic_buttons_value: Array[Button],
	special_buttons_value: Array[Button],
	merchant_manager_value: Variant,
	economy_manager_value: Variant
) -> void:
	panel = panel_value
	title_label = title_label_value
	gold_label = gold_label_value
	refresh_button = refresh_button_value
	leave_button = leave_button_value
	relic_buttons = relic_buttons_value
	special_buttons = special_buttons_value
	merchant_manager = merchant_manager_value
	economy_manager = economy_manager_value

	for i: int in range(relic_buttons.size()):
		relic_buttons[i].pressed.connect(_on_relic_button_pressed.bind(i))
	for i: int in range(special_buttons.size()):
		special_buttons[i].pressed.connect(_on_special_button_pressed.bind(i))
	refresh_button.pressed.connect(_on_refresh_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	hide_panel()


func show_panel() -> void:
	merchant_manager.enter_merchant()
	if panel != null:
		panel.visible = true
	_refresh_display()


func hide_panel() -> void:
	if panel != null:
		panel.visible = false


func _refresh_display() -> void:
	_refresh_relic_shelf()
	_refresh_special_shelf()
	_refresh_gold()
	_refresh_refresh_button()


func _refresh_relic_shelf() -> void:
	var shelf: Array[Dictionary] = merchant_manager.get_relic_shelf()
	for i: int in range(relic_buttons.size()):
		if i < shelf.size():
			var item: Dictionary = shelf[i]
			if item.get("is_sold", false):
				relic_buttons[i].text = "已售出"
				relic_buttons[i].icon = null
				relic_buttons[i].tooltip_text = ""
				relic_buttons[i].disabled = true
			else:
				var name: String = item.get("display_name", "遗物")
				var price: int = int(item.get("price", 0))
				var rarity: String = item.get("rarity", "RARE")
				var desc: String = item.get("description", "")
				var relic_data: Resource = item.get("relic_data", null) as Resource
				var icon_texture: Texture2D = RELIC_ICON_HELPER.get_relic_icon_texture_sized(relic_data, null, Vector2i(52, 52))
				relic_buttons[i].text = name + "\n[" + _get_rarity_cn(rarity) + "]\n" + str(price) + " 金币"
				relic_buttons[i].icon = icon_texture
				relic_buttons[i].expand_icon = false
				relic_buttons[i].tooltip_text = name + "  [" + _get_rarity_cn(rarity) + "]\n" + desc
				relic_buttons[i].disabled = false
			relic_buttons[i].visible = true
		else:
			relic_buttons[i].visible = false


func _refresh_special_shelf() -> void:
	var shelf: Array[Dictionary] = merchant_manager.get_special_shelf()
	for i: int in range(special_buttons.size()):
		if i < shelf.size():
			var item: Dictionary = shelf[i]
			if item.get("is_sold", false):
				special_buttons[i].text = "已售出"
				special_buttons[i].tooltip_text = ""
				special_buttons[i].disabled = true
			else:
				var name: String = item.get("display_name", "")
				var desc: String = item.get("description", "")
				var price: int = int(item.get("price", 0))
				special_buttons[i].text = name + "\n" + desc + "\n" + str(price) + " 金币"
				special_buttons[i].tooltip_text = name + "\n" + desc
				special_buttons[i].disabled = false
			special_buttons[i].visible = true
		else:
			special_buttons[i].visible = false


func _refresh_gold() -> void:
	if gold_label != null and economy_manager != null:
		gold_label.text = "金币: " + str(economy_manager.get_gold())


func _refresh_refresh_button() -> void:
	if refresh_button != null:
		var cost: int = merchant_manager.get_relic_refresh_cost()
		refresh_button.text = "刷新 (" + str(cost) + " 金币)"


func _on_relic_button_pressed(index: int) -> void:
	var shelf: Array[Dictionary] = merchant_manager.get_relic_shelf()
	if index < 0 or index >= shelf.size():
		return
	var item: Dictionary = shelf[index]
	if item.get("is_sold", false):
		return
	var price: int = int(item.get("price", 0))
	if not economy_manager.can_spend(price):
		return
	economy_manager.spend_gold(price)
	var purchased: Dictionary = merchant_manager.buy_relic_item(index)
	if not purchased.is_empty():
		item_purchased.emit(purchased)
	_refresh_display()


func _on_special_button_pressed(index: int) -> void:
	var shelf: Array[Dictionary] = merchant_manager.get_special_shelf()
	if index < 0 or index >= shelf.size():
		return
	var item: Dictionary = shelf[index]
	if item.get("is_sold", false):
		return
	var price: int = int(item.get("price", 0))
	if not economy_manager.can_spend(price):
		return
	economy_manager.spend_gold(price)
	var item_type: String = item.get("type", "")
	if item_type == "population":
		merchant_manager.buy_population()
		merchant_manager.update_population_item_in_shelf()
		item_purchased.emit(item)
	else:
		var purchased: Dictionary = merchant_manager.buy_special_item(index)
		if not purchased.is_empty():
			item_purchased.emit(purchased)
	_refresh_display()


func _on_refresh_pressed() -> void:
	var cost: int = merchant_manager.get_relic_refresh_cost()
	if not economy_manager.can_spend(cost):
		return
	economy_manager.spend_gold(cost)
	merchant_manager.refresh_relic_shelf()
	_refresh_display()


func _on_leave_pressed() -> void:
	leave_requested.emit()


func _get_rarity_cn(rarity: String) -> String:
	match rarity:
		"RARE":
			return "稀有"
		"EPIC":
			return "史诗"
		"LEGENDARY":
			return "传说"
		_:
			return rarity
