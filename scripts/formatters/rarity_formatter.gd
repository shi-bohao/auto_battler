class_name RarityFormatter
extends RefCounted


func normalize(rarity: String) -> String:
	var normalized: String = rarity.strip_edges().to_upper()
	match normalized:
		"普通", "NORMAL", "COMMON":
			return "COMMON"
		"精良", "FINE", "UNCOMMON":
			return "FINE"
		"稀有", "RARE":
			return "RARE"
		"史诗", "EPIC":
			return "EPIC"
		"传说", "LEGENDARY":
			return "LEGENDARY"
		"神话", "MYTHIC", "MYTHICAL":
			return "MYTHIC"
		_:
			return "COMMON"


func get_display_name(rarity: String) -> String:
	match normalize(rarity):
		"FINE":
			return "精良"
		"RARE":
			return "稀有"
		"EPIC":
			return "史诗"
		"LEGENDARY":
			return "传说"
		"MYTHIC":
			return "神话"
		_:
			return "普通"


func get_color(rarity: String) -> Color:
	match normalize(rarity):
		"FINE":
			return Color(0.20, 0.55, 0.26, 1.0)
		"RARE":
			return Color(0.18, 0.36, 0.82, 1.0)
		"EPIC":
			return Color(0.48, 0.25, 0.72, 1.0)
		"LEGENDARY":
			return Color(0.88, 0.46, 0.12, 1.0)
		"MYTHIC":
			return Color(0.96, 0.76, 0.18, 1.0)
		_:
			return Color(0.78, 0.80, 0.82, 1.0)


func get_text_color(bg_color: Color) -> Color:
	var brightness: float = bg_color.r * 0.299 + bg_color.g * 0.587 + bg_color.b * 0.114
	if brightness > 0.62:
		return Color(0.08, 0.08, 0.08, 1.0)

	return Color(1.0, 1.0, 1.0, 1.0)


func lighten_color(color: Color, amount: float) -> Color:
	return Color(
		minf(color.r + amount, 1.0),
		minf(color.g + amount, 1.0),
		minf(color.b + amount, 1.0),
		color.a
	)


func darken_color(color: Color, amount: float) -> Color:
	return Color(
		maxf(color.r - amount, 0.0),
		maxf(color.g - amount, 0.0),
		maxf(color.b - amount, 0.0),
		color.a
	)
