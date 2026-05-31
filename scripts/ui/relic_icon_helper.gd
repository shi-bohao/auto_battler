class_name RelicIconHelper
extends RefCounted


const RELIC_ICON_DIR: String = "res://assets/processed/relics"

static var _texture_cache: Dictionary = {}


static func get_relic_icon_texture(relic_data: Resource, relic_manager: Variant = null) -> Texture2D:
	var relic_id: String = get_relic_id(relic_data, relic_manager)
	if relic_id == "":
		return null

	var icon_path: String = RELIC_ICON_DIR + "/" + relic_id + ".png"
	if _texture_cache.has(icon_path):
		return _texture_cache[icon_path] as Texture2D

	var texture: Texture2D = _get_configured_icon_texture(relic_data)
	if texture == null:
		texture = _load_texture(icon_path)
	_texture_cache[icon_path] = texture
	return texture


static func get_relic_icon_texture_sized(relic_data: Resource, relic_manager: Variant = null, size: Vector2i = Vector2i(48, 48)) -> Texture2D:
	var relic_id: String = get_relic_id(relic_data, relic_manager)
	if relic_id == "":
		return null

	var icon_path: String = RELIC_ICON_DIR + "/" + relic_id + ".png"
	var cache_key: String = icon_path + "#" + str(size.x) + "x" + str(size.y)
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D

	var source_texture: Texture2D = get_relic_icon_texture(relic_data, relic_manager)
	if source_texture == null:
		return null

	var image: Image = source_texture.get_image()
	if image == null or image.is_empty():
		_texture_cache[cache_key] = source_texture
		return source_texture
	image = image.duplicate()
	image.resize(maxi(size.x, 1), maxi(size.y, 1), Image.INTERPOLATE_NEAREST)
	var texture: Texture2D = ImageTexture.create_from_image(image)
	_texture_cache[cache_key] = texture
	return texture


static func has_relic_icon(relic_data: Resource, relic_manager: Variant = null) -> bool:
	return get_relic_icon_texture(relic_data, relic_manager) != null


static func get_relic_id(relic_data: Resource, relic_manager: Variant = null) -> String:
	if relic_data == null:
		return ""
	if relic_manager != null and relic_manager.has_method("get_relic_id"):
		return str(relic_manager.get_relic_id(relic_data)).strip_edges()

	var configured_id: Variant = relic_data.get("relic_id")
	if configured_id == null:
		return ""
	return str(configured_id).strip_edges()


static func get_relic_name(relic_data: Resource, relic_manager: Variant = null) -> String:
	if relic_data == null:
		return "Relic"
	if relic_manager != null and relic_manager.has_method("get_relic_name"):
		return str(relic_manager.get_relic_name(relic_data)).strip_edges()

	var name_cn: Variant = relic_data.get("relic_name_cn")
	if name_cn != null and str(name_cn).strip_edges() != "":
		return str(name_cn).strip_edges()

	var name: Variant = relic_data.get("relic_name")
	if name != null and str(name).strip_edges() != "":
		return str(name).strip_edges()

	var relic_id: String = get_relic_id(relic_data, relic_manager)
	return relic_id if relic_id != "" else "Relic"


static func get_fallback_letter(relic_data: Resource, relic_manager: Variant = null) -> String:
	var relic_id: String = get_relic_id(relic_data, relic_manager)
	if relic_id != "":
		return relic_id.substr(0, 1).to_upper()

	var relic_name: String = get_relic_name(relic_data, relic_manager)
	if relic_name != "":
		return relic_name.substr(0, 1).to_upper()

	return "?"


static func configure_icon_button(button: Button, relic_data: Resource, relic_manager: Variant = null, icon_size: Vector2 = Vector2(44.0, 44.0)) -> void:
	if button == null:
		return

	button.custom_minimum_size = icon_size
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.tooltip_text = get_relic_name(relic_data, relic_manager)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var texture: Texture2D = get_relic_icon_texture_sized(relic_data, relic_manager, Vector2i(int(icon_size.x), int(icon_size.y)))
	if texture != null:
		button.icon = texture
		button.expand_icon = true
		button.text = ""
	else:
		button.icon = null
		button.expand_icon = false
		button.text = get_fallback_letter(relic_data, relic_manager)


static func configure_icon_display(texture_rect: TextureRect, fallback_label: Label, relic_data: Resource, relic_manager: Variant = null) -> bool:
	var display_size: Vector2i = Vector2i(96, 96)
	if texture_rect != null:
		var available_size: Vector2 = texture_rect.size
		if available_size.x <= 0.0 or available_size.y <= 0.0:
			available_size = texture_rect.custom_minimum_size
		if available_size.x > 0.0 and available_size.y > 0.0:
			display_size = Vector2i(int(round(available_size.x)), int(round(available_size.y)))

	var texture: Texture2D = get_relic_icon_texture_sized(relic_data, relic_manager, display_size)
	if texture_rect != null:
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.texture = texture
		texture_rect.visible = texture != null

	if fallback_label != null:
		fallback_label.text = get_fallback_letter(relic_data, relic_manager)
		fallback_label.visible = texture == null

	return texture != null


static func _load_texture(icon_path: String) -> Texture2D:
	if ResourceLoader.exists(icon_path):
		var loaded_texture: Texture2D = ResourceLoader.load(icon_path) as Texture2D
		if loaded_texture != null:
			return loaded_texture
	if not FileAccess.file_exists(icon_path):
		return null

	var image: Image = Image.new()
	var error: Error = image.load(icon_path)
	if error != OK:
		return null

	return ImageTexture.create_from_image(image)


static func _get_configured_icon_texture(relic_data: Resource) -> Texture2D:
	if relic_data == null:
		return null

	var configured_icon: Variant = relic_data.get("icon_texture")
	if configured_icon is Texture2D:
		return configured_icon as Texture2D

	return null
