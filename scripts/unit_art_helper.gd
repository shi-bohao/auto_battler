class_name UnitArtHelper
extends RefCounted

static var _texture_cache: Dictionary = {}


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
