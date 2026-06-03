extends SceneTree

const RELIC_ICON_HELPER: Script = preload("res://scripts/ui/relic_icon_helper.gd")

var failures: Array[String] = []


func _init() -> void:
	_run_tests()
	_finish()


func _run_tests() -> void:
	var relic_data: Resource = ResourceLoader.load("res://data/relics/crown_of_three.tres") as Resource
	if relic_data == null:
		failures.append("Failed to load crown_of_three relic data.")
		return

	# Test 1: Explicit icon_texture reference loads from .tres
	var texture: Texture2D = RELIC_ICON_HELPER.get_relic_icon_texture(relic_data)
	if texture == null:
		failures.append("Expected crown_of_three icon texture to load from .tres.")
	elif texture.get_width() <= 0 or texture.get_height() <= 0:
		failures.append("Loaded crown_of_three icon texture has invalid dimensions.")

	# Test 2: Sized variant works
	var thumbnail: Texture2D = RELIC_ICON_HELPER.get_relic_icon_texture_sized(relic_data, null, Vector2i(52, 52))
	if thumbnail == null:
		failures.append("Expected crown_of_three thumbnail texture to load.")
	elif thumbnail.get_width() != 52 or thumbnail.get_height() != 52:
		failures.append("Expected 52x52 thumbnail, got " + str(thumbnail.get_width()) + "x" + str(thumbnail.get_height()) + ".")

	# Test 3: Fallback letter
	var fallback_letter: String = RELIC_ICON_HELPER.get_fallback_letter(relic_data)
	if fallback_letter != "C":
		failures.append("Expected fallback letter C, got " + fallback_letter + ".")

	# Test 4: Null relic returns null texture
	var null_texture: Texture2D = RELIC_ICON_HELPER.get_relic_icon_texture(null)
	if null_texture != null:
		failures.append("Expected null texture for null relic data.")


func _finish() -> void:
	if failures.is_empty():
		print("Relic icon helper tests passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)
