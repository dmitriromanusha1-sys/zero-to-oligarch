## Генератор процедурных портретов NPC (150x150)
class_name NPCAvatar

const SIZE := 150

# Цветовые палитры для разных архетипов
const PALETTES := [
	{"bg": Color(0.10, 0.06, 0.18), "skin": Color(0.95, 0.78, 0.62), "hair": Color(0.18, 0.10, 0.05), "accent": Color(0.55, 0.30, 0.80)},
	{"bg": Color(0.05, 0.12, 0.22), "skin": Color(0.88, 0.70, 0.52), "hair": Color(0.55, 0.35, 0.15), "accent": Color(0.25, 0.55, 0.90)},
	{"bg": Color(0.06, 0.16, 0.10), "skin": Color(0.98, 0.82, 0.68), "hair": Color(0.72, 0.58, 0.38), "accent": Color(0.20, 0.72, 0.40)},
	{"bg": Color(0.18, 0.08, 0.06), "skin": Color(0.92, 0.75, 0.58), "hair": Color(0.85, 0.72, 0.55), "accent": Color(0.88, 0.38, 0.22)},
	{"bg": Color(0.12, 0.10, 0.04), "skin": Color(0.96, 0.80, 0.64), "hair": Color(0.15, 0.12, 0.08), "accent": Color(0.82, 0.70, 0.15)},
	{"bg": Color(0.08, 0.05, 0.18), "skin": Color(0.90, 0.72, 0.56), "hair": Color(0.22, 0.18, 0.38), "accent": Color(0.60, 0.40, 0.95)},
]

# Форма причёски: 0=короткие 1=длинные 2=лысый 3=пучок 4=кудри
const HAIR_STYLES := {
	"🧔 Дядя Коля":            [0, true,  false],  # [стиль, борода, усы]
	"👵 Баба Нюра":            [3, false, false],
	"👮 Участковый":           [0, false, false],
	"🧒 Димка":                [4, false, false],
	"👷 Бригадир Степаныч":    [0, false, true],
	"👩‍🏭 Работница Галя":       [1, false, false],
	"🚛 Водила Вася":           [0, true,  false],
	"🔩 Слесарь Митя":         [0, false, false],
	"👩 Продавщица Люда":      [1, false, false],
	"🧑 Алёша (молодой папа)": [4, false, false],
	"👴 Дедушка Иван":         [2, true,  false],
	"🧕 Тётя Зина":            [3, false, false],
	"🧑‍💻 IT-специалист Антон": [0, false, false],
	"👩‍💼 Менеджер Катя":        [1, false, false],
	"🔧 Автомеханик Серёга":   [0, false, true],
	"👩‍🎓 Студентка Маша":        [1, false, false],
	"💼 Бизнесмен Петрович":   [0, false, true],
	"🧑‍💼 Брокер Антон":         [0, false, false],
	"👩‍🔬 Аналитик Виктория":    [1, false, false],
	"👨‍💻 Разработчик Макс":     [4, false, false],
	"🧑‍💰 Инвестор Борис":       [0, true,  false],
	"🏖 Олигарх":              [2, false, false],
	"👩 Светская дама":        [1, false, false],
	"🧔 Телохранитель":        [2, true,  false],
	"🤴 Мультимиллионер":      [0, false, false],
	"🧑‍🎨 Архитектор":           [4, false, false],
	"👩‍💼 Советник":              [1, false, false],
	"🕴 Министр":              [0, false, false],
	"💂 Охранник КПП":         [0, false, false],
	"👩‍💼 Чиновница":             [3, false, false],
	"👑 Сенатор":              [0, false, false],
	"🧑‍✈️ Пилот":                [0, false, false],
	"🤖 ИИ-консультант":       [0, false, false],
}

# Цвет одежды по архетипу
const CLOTH_COLORS := {
	"🧔 Дядя Коля":            Color(0.30, 0.22, 0.15),
	"👵 Баба Нюра":            Color(0.55, 0.25, 0.35),
	"👮 Участковый":           Color(0.15, 0.22, 0.42),
	"🧒 Димка":                Color(0.20, 0.35, 0.58),
	"👷 Бригадир Степаныч":    Color(0.55, 0.42, 0.12),
	"👩‍🏭 Работница Галя":       Color(0.48, 0.28, 0.38),
	"🚛 Водила Вася":           Color(0.22, 0.28, 0.22),
	"🔩 Слесарь Митя":         Color(0.25, 0.30, 0.35),
	"👩 Продавщица Люда":      Color(0.58, 0.32, 0.42),
	"🧑 Алёша (молодой папа)": Color(0.28, 0.42, 0.62),
	"👴 Дедушка Иван":         Color(0.35, 0.35, 0.42),
	"🧕 Тётя Зина":            Color(0.42, 0.28, 0.48),
	"🧑‍💻 IT-специалист Антон": Color(0.18, 0.28, 0.45),
	"👩‍💼 Менеджер Катя":        Color(0.38, 0.20, 0.38),
	"🔧 Автомеханик Серёга":   Color(0.28, 0.28, 0.28),
	"👩‍🎓 Студентка Маша":        Color(0.30, 0.42, 0.62),
	"💼 Бизнесмен Петрович":   Color(0.15, 0.18, 0.28),
	"🧑‍💼 Брокер Антон":         Color(0.12, 0.20, 0.35),
	"👩‍🔬 Аналитик Виктория":    Color(0.20, 0.30, 0.45),
	"👨‍💻 Разработчик Макс":     Color(0.15, 0.22, 0.18),
	"🧑‍💰 Инвестор Борис":       Color(0.15, 0.18, 0.25),
	"🏖 Олигарх":              Color(0.55, 0.45, 0.10),
	"👩 Светская дама":        Color(0.45, 0.12, 0.32),
	"🧔 Телохранитель":        Color(0.08, 0.08, 0.10),
	"🤴 Мультимиллионер":      Color(0.48, 0.38, 0.08),
	"🧑‍🎨 Архитектор":           Color(0.28, 0.22, 0.38),
	"👩‍💼 Советник":              Color(0.22, 0.18, 0.32),
	"🕴 Министр":              Color(0.10, 0.10, 0.15),
	"💂 Охранник КПП":         Color(0.18, 0.22, 0.18),
	"👩‍💼 Чиновница":             Color(0.30, 0.20, 0.35),
	"👑 Сенатор":              Color(0.42, 0.32, 0.06),
	"🧑‍✈️ Пилот":                Color(0.12, 0.18, 0.32),
	"🤖 ИИ-консультант":       Color(0.10, 0.18, 0.28),
}

static func generate(npc_name: String) -> ImageTexture:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(npc_name) & 0x7FFFFFFF

	# Выбор палитры
	var pal: Dictionary = PALETTES[rng.randi() % PALETTES.size()]
	var bg_col: Color  = pal["bg"]
	var skin: Color    = pal["skin"]
	var hair_col: Color = pal["hair"]
	var accent: Color  = pal["accent"]
	var cloth_col: Color = CLOTH_COLORS.get(npc_name, Color(0.20, 0.25, 0.35))

	var hair_data: Array = HAIR_STYLES.get(npc_name, [0, false, false])
	var hair_style: int  = hair_data[0]
	var has_beard: bool  = hair_data[1]
	var has_mustache: bool = hair_data[2]

	# 1. Фон с градиентом
	_draw_gradient_bg(img, bg_col, accent)

	# 2. Одежда / плечи
	_draw_clothes(img, cloth_col, accent)

	# 3. Шея
	_fill_ellipse(img, 75, 118, 14, 12, skin)

	# 4. Голова
	_fill_ellipse(img, 75, 72, 36, 40, skin)

	# 5. Волосы
	_draw_hair(img, hair_style, hair_col, rng)

	# 6. Брови
	var brow_y := 60
	_fill_rect_img(img, 52, brow_y, 16, 3, hair_col.darkened(0.2))
	_fill_rect_img(img, 82, brow_y, 16, 3, hair_col.darkened(0.2))

	# 7. Глаза
	var eye_col := Color(rng.randf_range(0.1, 0.5), rng.randf_range(0.2, 0.6), rng.randf_range(0.4, 0.9))
	_fill_ellipse(img, 60, 72, 9, 7, Color(0.95, 0.95, 0.95))
	_fill_ellipse(img, 90, 72, 9, 7, Color(0.95, 0.95, 0.95))
	_fill_ellipse(img, 60, 73, 6, 5, eye_col)
	_fill_ellipse(img, 90, 73, 6, 5, eye_col)
	_fill_ellipse(img, 60, 73, 3, 3, Color(0.05, 0.05, 0.05))
	_fill_ellipse(img, 90, 73, 3, 3, Color(0.05, 0.05, 0.05))
	# Блик в глазу
	img.set_pixel(62, 70, Color(1, 1, 1, 0.9))
	img.set_pixel(92, 70, Color(1, 1, 1, 0.9))

	# 8. Нос
	_fill_ellipse(img, 75, 83, 4, 3, skin.darkened(0.12))

	# 9. Рот
	var mouth_type := rng.randi() % 3
	_draw_mouth(img, mouth_type, skin)

	# 10. Борода / усы
	if has_beard:
		_fill_ellipse(img, 75, 96, 22, 10, hair_col.darkened(0.1))
	if has_mustache:
		_fill_ellipse(img, 62, 88, 10, 4, hair_col)
		_fill_ellipse(img, 88, 88, 10, 4, hair_col)

	# 11. Ухо
	_fill_ellipse(img, 39, 75, 5, 7, skin.darkened(0.08))
	_fill_ellipse(img, 111, 75, 5, 7, skin.darkened(0.08))

	# 12. Золотое кольцо / рамка
	_draw_ring(img, accent)

	return ImageTexture.create_from_image(img)

# ─── Рисование фона ──────────────────────────────────────────────────────────
static func _draw_gradient_bg(img: Image, base: Color, accent: Color) -> void:
	for y in SIZE:
		for x in SIZE:
			var t: float = float(y) / SIZE
			var c: Color = base.lerp(base.darkened(0.35), t)
			# Лёгкий виньет по краям
			var dx: float = (x - SIZE * 0.5) / (SIZE * 0.5)
			var dy: float = (y - SIZE * 0.5) / (SIZE * 0.5)
			var vign: float = clampf(1.0 - (dx*dx + dy*dy) * 0.55, 0.0, 1.0)
			c = c.lerp(accent * 0.18, (1.0 - vign) * 0.5)
			img.set_pixel(x, y, c)

# ─── Одежда ──────────────────────────────────────────────────────────────────
static func _draw_clothes(img: Image, cloth: Color, accent: Color) -> void:
	# Плечи и грудь
	for y in range(110, SIZE):
		for x in SIZE:
			var cx: float = SIZE * 0.5
			var spread: float = 18.0 + float(y - 110) * 2.2
			if abs(x - cx) < spread:
				var t: float = abs(x - cx) / spread
				var c: Color = cloth.lerp(cloth.darkened(0.25), t * t)
				img.set_pixel(x, y, c)
	# Воротник — акцентная полоска
	for y in range(110, 116):
		for x in range(58, 92):
			img.set_pixel(x, y, accent.darkened(0.2))

# ─── Волосы ──────────────────────────────────────────────────────────────────
static func _draw_hair(img: Image, style: int, col: Color, _rng: RandomNumberGenerator) -> void:
	match style:
		0: # Короткие
			_fill_ellipse(img, 75, 45, 36, 22, col)
			_fill_rect_img(img, 39, 45, 72, 14, col)
		1: # Длинные
			_fill_ellipse(img, 75, 45, 36, 22, col)
			_fill_rect_img(img, 39, 45, 72, 14, col)
			# Пряди по бокам
			for i in 5:
				var lx: int = 39 + i * 2
				_fill_rect_img(img, lx, 58, 8, 30 + i * 4, col.darkened(float(i) * 0.06))
				_fill_rect_img(img, 103 - i * 2, 58, 8, 30 + i * 4, col.darkened(float(i) * 0.06))
		2: # Лысый
			_fill_ellipse(img, 75, 45, 36, 20, col.lightened(0.15))
		3: # Пучок
			_fill_ellipse(img, 75, 45, 36, 22, col)
			_fill_rect_img(img, 39, 45, 72, 14, col)
			_fill_ellipse(img, 75, 30, 12, 14, col.darkened(0.1))
		4: # Кудри
			_fill_ellipse(img, 75, 45, 36, 22, col)
			_fill_rect_img(img, 39, 45, 72, 14, col)
			for ci in 8:
				var cx: int = 42 + ci * 11
				var cy: int = 42 + (ci % 2) * 6
				_fill_ellipse(img, cx, cy, 9, 7, col.lightened(0.08 if ci % 2 == 0 else 0.0))

# ─── Рот ─────────────────────────────────────────────────────────────────────
static func _draw_mouth(img: Image, style: int, skin: Color) -> void:
	match style:
		0: # Нейтральный
			_fill_rect_img(img, 65, 91, 20, 3, skin.darkened(0.30))
		1: # Улыбка
			for i in range(-8, 9):
				var my: int = 92 + int(float(i * i) * 0.08)
				if my < SIZE and (65 + 8 + i) >= 0 and (65 + 8 + i) < SIZE:
					img.set_pixel(65 + 8 + i, my, skin.darkened(0.32))
					img.set_pixel(65 + 8 + i, my + 1, skin.darkened(0.28))
		2: # Серьёзный
			_fill_rect_img(img, 63, 91, 24, 2, skin.darkened(0.38))

# ─── Рамка ───────────────────────────────────────────────────────────────────
static func _draw_ring(img: Image, accent: Color) -> void:
	var cx: float = SIZE * 0.5
	var cy: float = SIZE * 0.5
	var r_outer: float = SIZE * 0.5 - 1
	var r_inner: float = SIZE * 0.5 - 4
	for y in SIZE:
		for x in SIZE:
			var dx: float = x - cx
			var dy: float = y - cy
			var d: float = sqrt(dx*dx + dy*dy)
			if d >= r_inner and d <= r_outer:
				var t: float = (d - r_inner) / (r_outer - r_inner)
				img.set_pixel(x, y, accent.lerp(accent.darkened(0.4), t))

# ─── Утилиты ─────────────────────────────────────────────────────────────────
static func _fill_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			if x < 0 or x >= SIZE or y < 0 or y >= SIZE:
				continue
			var dx: float = float(x - cx) / rx
			var dy: float = float(y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, col)

static func _fill_rect_img(img: Image, x: int, y: int, w: int, h: int, col: Color) -> void:
	for py in range(y, y + h):
		for px in range(x, x + w):
			if px >= 0 and px < SIZE and py >= 0 and py < SIZE:
				img.set_pixel(px, py, col)
