extends Node

# Принудительно устанавливает шрифт с поддержкой кириллицы как тему по умолчанию.
# Без этого GL Compatibility + ANGLE/D3D12 на Windows может не найти нужный глиф.

func _ready() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "Arial Unicode MS", "Arial", "DejaVu Sans"])
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED

	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 14

	get_tree().root.theme = theme
