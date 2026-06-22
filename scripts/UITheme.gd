class_name UITheme
extends RefCounted

# ─────────────────────────────────────────────────────────────────────────────
# Единый стиль интерфейса «люкс тёмный + золото».
# Используется как UITheme.GOLD, UITheme.panel_box(), UITheme.style_button(btn)…
# Один источник правды для цветов/панелей/кнопок/шрифтов — окна больше не плодят
# собственные StyleBoxFlat.
# ─────────────────────────────────────────────────────────────────────────────

# ── Палитра ───────────────────────────────────────────────────────────────────
const BG_DEEP   := Color(0.039, 0.055, 0.102)          # глубокий тёмно-синий фон
const PANEL     := Color(0.066, 0.086, 0.157, 0.98)    # фон панели
const CARD      := Color(0.098, 0.122, 0.200, 0.96)    # активная карточка
const CARD_DIM  := Color(0.063, 0.078, 0.133, 0.94)    # неактивная карточка
const GOLD      := Color(0.854, 0.722, 0.357)          # акцент-золото
const GOLD_DIM  := Color(0.541, 0.447, 0.220)          # приглушённое золото (рамки)
const BORDER    := Color(0.280, 0.310, 0.420, 0.55)    # нейтральная рамка
const TEXT      := Color(0.918, 0.925, 0.949)          # основной текст
const TEXT_DIM  := Color(0.560, 0.590, 0.680)          # вторичный текст
const GREEN     := Color(0.420, 0.850, 0.500)          # доход/успех
const RED       := Color(0.850, 0.370, 0.330)          # расход/опасность

# ── Шрифты (системный Segoe UI + полужирный для заголовков) ───────────────────
static var _display: FontVariation = null
static var _body: SystemFont = null

static func _ensure_fonts() -> void:
	if _body == null:
		_body = SystemFont.new()
		_body.font_names = PackedStringArray(["Segoe UI", "Arial Unicode MS", "Arial", "DejaVu Sans"])
		_body.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	if _display == null:
		var base := SystemFont.new()
		base.font_names = PackedStringArray(["Segoe UI Semibold", "Segoe UI", "Arial"])
		base.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		_display = FontVariation.new()
		_display.base_font = base
		_display.variation_embolden = 0.35

static func display_font() -> FontVariation:
	_ensure_fonts()
	return _display

static func body_font() -> SystemFont:
	_ensure_fonts()
	return _body

# ── Фабрики стилей ────────────────────────────────────────────────────────────
static func panel_box() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = PANEL
	s.border_color = GOLD_DIM
	s.set_border_width_all(1)
	s.set_corner_radius_all(16)
	s.content_margin_left = 20; s.content_margin_right = 20
	s.content_margin_top = 18; s.content_margin_bottom = 18
	s.shadow_color = Color(0, 0, 0, 0.55)
	s.shadow_size = 18
	s.anti_aliasing = true
	return s

static func card_box(active := true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CARD if active else CARD_DIM
	s.border_color = GOLD_DIM if active else BORDER
	s.set_border_width_all(1)
	s.set_corner_radius_all(11)
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top = 11; s.content_margin_bottom = 11
	return s

static func button_box(variant := "primary", hover := false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	match variant:
		"danger":
			s.bg_color = Color(0.34, 0.12, 0.12) if hover else Color(0.26, 0.09, 0.09)
			s.border_color = Color(0.62, 0.24, 0.24)
		"ghost":
			s.bg_color = Color(0.14, 0.16, 0.23, 0.85) if hover else Color(0.09, 0.10, 0.15, 0.55)
			s.border_color = BORDER
		_:  # primary — золотая обводка
			s.bg_color = Color(0.17, 0.21, 0.28) if hover else Color(0.115, 0.145, 0.205)
			s.border_color = GOLD if hover else GOLD_DIM
	s.set_border_width_all(1)
	s.set_corner_radius_all(9)
	s.content_margin_left = 12; s.content_margin_right = 12
	s.content_margin_top = 8; s.content_margin_bottom = 8
	return s

# Применяет к кнопке полный набор стилей (normal/hover/pressed/focus + цвет/шрифт)
static func style_button(btn: Button, variant := "primary") -> void:
	btn.add_theme_stylebox_override("normal",   button_box(variant, false))
	btn.add_theme_stylebox_override("hover",    button_box(variant, true))
	btn.add_theme_stylebox_override("pressed",  button_box(variant, false))
	btn.add_theme_stylebox_override("focus",    button_box(variant, false))
	btn.add_theme_stylebox_override("disabled", button_box("ghost", false))
	btn.add_theme_color_override("font_color", GOLD if variant == "primary" else TEXT)
	btn.add_theme_color_override("font_disabled_color", TEXT_DIM)
	btn.add_theme_font_override("font", body_font())

# Тонкая золотая линия-разделитель (растягивается по ширине контейнера)
static func gold_rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = GOLD_DIM
	r.custom_minimum_size = Vector2(0, 1)
	return r
