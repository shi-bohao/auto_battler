class_name UnitDragController
extends RefCounted

var can_drag: bool = false
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_start_position: Vector2 = Vector2.ZERO


func set_can_drag(value: bool) -> void:
	can_drag = value
	if not can_drag:
		is_dragging = false


func handle_input(
	event: InputEvent,
	unit: Node2D,
	body: ColorRect,
	is_battle_active: bool,
	is_alive: bool
) -> void:
	if unit == null or not is_instance_valid(unit):
		is_dragging = false
		return

	if not can_drag or is_battle_active or not is_alive:
		is_dragging = false
		return

	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return

		if mouse_button.pressed and _is_mouse_over_blocking_ui(unit):
			return

		if mouse_button.pressed and _is_mouse_over_unit(unit, body, unit.get_global_mouse_position()):
			is_dragging = true
			drag_start_position = unit.position
			drag_offset = unit.global_position - unit.get_global_mouse_position()
			unit.get_viewport().set_input_as_handled()
		elif not mouse_button.pressed:
			if is_dragging:
				_handle_drop(unit)
			is_dragging = false

	if event is InputEventMouseMotion and is_dragging:
		unit.global_position = unit.get_global_mouse_position() + drag_offset
		unit.get_viewport().set_input_as_handled()


func _is_mouse_over_unit(unit: Node2D, body: ColorRect, mouse_position: Vector2) -> bool:
	if body == null:
		return false

	var local_position: Vector2 = unit.to_local(mouse_position)
	var body_rect: Rect2 = Rect2(body.position, body.size)
	return body_rect.has_point(local_position)


func _handle_drop(unit: Node2D) -> void:
	var drop_handler: Callable = unit.get("prepare_drop_handler") as Callable
	if drop_handler.is_valid():
		drop_handler.call(unit, drag_start_position)
		return

	_snap_or_revert_to_board(unit)


func _snap_or_revert_to_board(unit: Node2D) -> void:
	var battle_board: Variant = unit.get("battle_board")
	if battle_board == null or not is_instance_valid(battle_board):
		return

	if not battle_board.has_method("get_player_drop_position"):
		return

	unit.position = battle_board.get_player_drop_position(unit, drag_start_position)


func _is_mouse_over_blocking_ui(unit: Node2D) -> bool:
	var viewport: Viewport = unit.get_viewport()
	if viewport == null or not viewport.has_method("gui_get_hovered_control"):
		return false

	var hovered_control: Control = viewport.gui_get_hovered_control() as Control
	if hovered_control == null:
		return false

	if unit.is_ancestor_of(hovered_control):
		return false

	return hovered_control.mouse_filter != Control.MOUSE_FILTER_IGNORE
