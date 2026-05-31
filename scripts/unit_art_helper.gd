class_name UnitArtHelper
extends RefCounted

const PLAYER_UNIT_ART_DIR: String = "res://assets/processed/player_units"

static var _texture_cache: Dictionary = {}


static func get_player_unit_art_texture(unit_data_or_id: Variant) -> Texture2D:
	var configured_texture: Texture2D = _get_configured_unit_texture(unit_data_or_id)
	if configured_texture != null:
		return configured_texture

	var unit_id: String = _resolve_unit_id(unit_data_or_id)
	if unit_id == "":
		return null

	var art_path: String = PLAYER_UNIT_ART_DIR + "/" + unit_id + ".png"
	if _texture_cache.has(art_path):
		return _texture_cache[art_path] as Texture2D

	var texture: Texture2D = _load_texture(art_path)
	_texture_cache[art_path] = texture
	return texture


static func get_player_unit_art_texture_sized(unit_data_or_id: Variant, size: Vector2i = Vector2i(96, 96)) -> Texture2D:
	var unit_id: String = _resolve_unit_id(unit_data_or_id)
	if unit_id == "":
		return null

	var art_path: String = PLAYER_UNIT_ART_DIR + "/" + unit_id + ".png"
	var cache_key: String = art_path + "#" + str(size.x) + "x" + str(size.y)
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D

	var source_texture: Texture2D = get_player_unit_art_texture(unit_data_or_id)
	if source_texture == null:
		return null

	var texture: Texture2D = get_texture_sized(source_texture, art_path, size)
	_texture_cache[cache_key] = texture
	return texture


static func get_texture_sized(source_texture: Texture2D, cache_key_base: String = "", size: Vector2i = Vector2i(96, 96)) -> Texture2D:
	if source_texture == null:
		return null

	var cache_key: String = cache_key_base.strip_edges()
	if cache_key == "":
		cache_key = source_texture.resource_path
	if cache_key == "":
		cache_key = "texture_" + str(source_texture.get_instance_id())
	cache_key += "#" + str(size.x) + "x" + str(size.y)
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D

	var image: Image = source_texture.get_image()
	if image == null or image.is_empty():
		_texture_cache[cache_key] = source_texture
		return source_texture

	var texture: Texture2D = _create_sized_texture_from_image(image, size)
	_texture_cache[cache_key] = texture
	return texture


static func has_player_unit_art(unit_data_or_id: Variant) -> bool:
	return get_player_unit_art_texture(unit_data_or_id) != null


static func _resolve_unit_id(unit_data_or_id: Variant) -> String:
	if unit_data_or_id is Resource:
		var unit_data: Resource = unit_data_or_id as Resource
		var configured_type: Variant = unit_data.get("unit_type")
		if configured_type != null and str(configured_type).strip_edges() != "":
			return str(configured_type).strip_edges()

		var configured_name: Variant = unit_data.get("unit_name")
		if configured_name != null and str(configured_name).strip_edges() != "":
			return str(configured_name).strip_edges().to_snake_case()

		return ""

	return str(unit_data_or_id).strip_edges()


static func _get_configured_unit_texture(unit_data_or_id: Variant) -> Texture2D:
	if not unit_data_or_id is Resource:
		return null

	var unit_data: Resource = unit_data_or_id as Resource
	var portrait_texture: Variant = unit_data.get("portrait_texture")
	if portrait_texture is Texture2D:
		return portrait_texture as Texture2D

	var icon_texture: Variant = unit_data.get("icon_texture")
	if icon_texture is Texture2D:
		return icon_texture as Texture2D

	var board_sprite: Variant = unit_data.get("board_sprite")
	if board_sprite is Texture2D:
		return board_sprite as Texture2D

	return null


static func _load_texture(art_path: String) -> Texture2D:
	if ResourceLoader.exists(art_path):
		var loaded_texture: Texture2D = ResourceLoader.load(art_path) as Texture2D
		if loaded_texture != null:
			return loaded_texture
	if not FileAccess.file_exists(art_path):
		return null

	var image: Image = Image.new()
	var error: Error = image.load(art_path)
	if error != OK:
		return null

	return ImageTexture.create_from_image(image)


static func _create_sized_texture_from_image(source_image: Image, size: Vector2i) -> Texture2D:
	var output_size: Vector2i = Vector2i(maxi(size.x, 1), maxi(size.y, 1))
	var output: Image = Image.create(output_size.x, output_size.y, false, Image.FORMAT_RGBA8)
	output.fill(Color(0.0, 0.0, 0.0, 0.0))

	if source_image == null or source_image.is_empty():
		return ImageTexture.create_from_image(output)

	var image: Image = source_image.duplicate()
	var source_size: Vector2i = image.get_size()
	if source_size.x <= 0 or source_size.y <= 0:
		return ImageTexture.create_from_image(output)

	var scale_ratio: float = minf(float(output_size.x) / float(source_size.x), float(output_size.y) / float(source_size.y))
	var target_size: Vector2i = Vector2i(
		maxi(1, int(round(float(source_size.x) * scale_ratio))),
		maxi(1, int(round(float(source_size.y) * scale_ratio)))
	)
	image.resize(target_size.x, target_size.y, Image.INTERPOLATE_NEAREST)
	var target_position: Vector2i = Vector2i((output_size.x - target_size.x) / 2, (output_size.y - target_size.y) / 2)
	output.blit_rect(image, Rect2i(Vector2i.ZERO, target_size), target_position)

	return ImageTexture.create_from_image(output)
