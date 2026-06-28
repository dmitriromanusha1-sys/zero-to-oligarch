extends Node2D

var _has_save: bool = false
var _slot_panel: Control = null
var _lb_panel: Control = null
var _settings_ui: CanvasLayer = null

# Анимированные элементы
var _stars: Array = []
var _windows: Array = []
var _time: float = 0.0

var _bg_canvas: CanvasLayer   # layer 1 — фон, звёзды, силуэт города
var _ui_canvas: CanvasLayer   # layer 2 — кнопки и интерфейс

func _ready() -> void:
	var gm0 = get_node_or_null("/root/GameManager")
	_has_save = false
	if gm0:
		for s in range(1, 4):
			if gm0.slot_exists(s):
				_has_save = true
				break

	_bg_canvas = CanvasLayer.new()
	_bg_canvas.layer = 1
	add_child(_bg_canvas)

	_ui_canvas = CanvasLayer.new()
	_ui_canvas.layer = 2
	add_child(_ui_canvas)

	var _has_bg_image: bool = ResourceLoader.exists("res://assets/ui/main_menu_bg.png")
	_build_background()
	if not _has_bg_image:
		_build_stars()
		_build_city_silhouette()
	else:
		_build_stars_overlay()
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _lb_panel and is_instance_valid(_lb_panel):
			_lb_panel.queue_free()
			_lb_panel = null
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_time += delta
	# Мерцание звёзд
	for d in _stars:
		var lbl: Label = d.node
		var phase: float = sin(_time * d.speed + d.offset)
		lbl.modulate.a = 0.4 + 0.6 * ((phase + 1.0) * 0.5)
	# Мигание окон в зданиях
	for d in _windows:
		var rect: ColorRect = d.node
		var t: float = _time * d.speed + d.offset
		# Редкое случайное мигание
		var flicker: float = sin(t) * sin(t * 2.3) * sin(t * 0.7)
		rect.modulate.a = 0.6 + 0.4 * clampf(flicker, 0.0, 1.0)

func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 60:
		var lbl := Label.new()
		lbl.text = "·" if rng.randf() > 0.15 else "✦"
		lbl.add_theme_font_size_override("font_size", rng.randi_range(8, 14))
		lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
		lbl.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 300))
		_bg_canvas.add_child(lbl)
		_stars.append({"node": lbl, "speed": rng.randf_range(0.3, 1.5), "offset": rng.randf_range(0, TAU)})

# Мерцающие звёзды поверх фото (тонкие, не закрывают картинку)
func _build_stars_overlay() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 22:
		var lbl := Label.new()
		lbl.text = "·" if rng.randf() > 0.25 else "✦"
		lbl.add_theme_font_size_override("font_size", rng.randi_range(7, 12))
		lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 0.55))
		lbl.position = Vector2(rng.randf_range(0, 1280), rng.randf_range(0, 220))
		_bg_canvas.add_child(lbl)
		_stars.append({"node": lbl, "speed": rng.randf_range(0.2, 0.9), "offset": rng.randf_range(0, TAU)})

func _build_city_silhouette() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var building_data := [
		{"y": 390, "min_h": 90, "max_h": 240, "col": Color(0.06, 0.06, 0.10), "count": 15, "wmin": 55, "wmax": 115, "win_col": Color(1.0, 0.85, 0.38)},
		{"y": 470, "min_h": 55, "max_h": 160, "col": Color(0.08, 0.08, 0.13), "count": 20, "wmin": 38, "wmax": 80,  "win_col": Color(1.0, 0.90, 0.50)},
		{"y": 530, "min_h": 30, "max_h":  90, "col": Color(0.05, 0.05, 0.08), "count": 28, "wmin": 28, "wmax": 55,  "win_col": Color(0.85, 0.78, 1.0)},
	]
	for row in building_data:
		var x: float = -20.0
		for _i in row.count:
			var w: float = rng.randf_range(row.wmin, row.wmax)
			var h: float = rng.randf_range(row.min_h, row.max_h)
			var bld := ColorRect.new()
			bld.color = row.col
			bld.position = Vector2(x, row.y - h)
			bld.size = Vector2(w - 3, h)
			_bg_canvas.add_child(bld)
			# Окна
			var win_cols_count: int = max(1, int((w - 10) / 18))
			var win_rows_count: int = max(1, int(h / 22))
			for wr in win_rows_count:
				for wc in win_cols_count:
					if rng.randf() < 0.38:
						continue
					var win := ColorRect.new()
					win.color = row.win_col
					win.color.a = 0.72
					win.position = Vector2(x + 8 + wc * 18, row.y - h + 8 + wr * 22)
					win.size = Vector2(9, 11)
					_bg_canvas.add_child(win)
					_windows.append({"node": win, "speed": rng.randf_range(0.08, 0.45), "offset": rng.randf_range(0, TAU)})
			# Антенны на высоких зданиях
			if h > 130 and rng.randf() < 0.55:
				var ant := ColorRect.new()
				ant.size = Vector2(2, rng.randf_range(18, 38))
				ant.position = Vector2(x + w * 0.5 - 1, row.y - h - ant.size.y)
				ant.color = row.col.lightened(0.18)
				_bg_canvas.add_child(ant)
				# Мигающий красный огонёк на антенне
				var dot := ColorRect.new()
				dot.size = Vector2(4, 4)
				dot.position = Vector2(x + w * 0.5 - 2, row.y - h - ant.size.y - 4)
				dot.color = Color(1.0, 0.18, 0.18, 0.90)
				_bg_canvas.add_child(dot)
				_windows.append({"node": dot, "speed": rng.randf_range(0.6, 1.2), "offset": rng.randf_range(0, TAU)})
			x += w

	# Отражения огней на асфальте (горизонтальные блики)
	var refl_rng := RandomNumberGenerator.new(); refl_rng.seed = 88
	for i in 22:
		var refl := ColorRect.new()
		refl.size = Vector2(refl_rng.randf_range(3, 8), refl_rng.randf_range(18, 45))
		refl.position = Vector2(refl_rng.randf_range(0, 1280), refl_rng.randf_range(530, 620))
		refl.color = Color(
			refl_rng.randf_range(0.6, 1.0),
			refl_rng.randf_range(0.5, 0.9),
			refl_rng.randf_range(0.2, 0.6),
			refl_rng.randf_range(0.08, 0.18))
		_bg_canvas.add_child(refl)
		_windows.append({"node": refl, "speed": refl_rng.randf_range(0.05, 0.25), "offset": refl_rng.randf_range(0, TAU)})

func _build_background() -> void:
	var bg_path := "res://assets/ui/main_menu_bg.png"
	if ResourceLoader.exists(bg_path):
		var bg_img := TextureRect.new()
		bg_img.texture = load(bg_path)
		bg_img.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_bg_canvas.add_child(bg_img)
	else:
		var sky_bands: Array = [
			[0,   180, Color(0.03, 0.02, 0.10)],
			[180, 120, Color(0.05, 0.04, 0.14)],
			[300, 100, Color(0.07, 0.05, 0.16)],
			[400,  80, Color(0.09, 0.06, 0.17)],
			[480,  60, Color(0.12, 0.07, 0.16)],
			[540,  60, Color(0.10, 0.06, 0.13)],
			[600,  60, Color(0.08, 0.05, 0.10)],
			[660,  60, Color(0.06, 0.04, 0.08)],
		]
		for b in sky_bands:
			var band := ColorRect.new()
			band.position = Vector2(0, b[0])
			band.size = Vector2(1280, b[1])
			band.color = b[2]
			_bg_canvas.add_child(band)
		var glow := ColorRect.new()
		glow.position = Vector2(0, 440); glow.size = Vector2(1280, 80)
		glow.color = Color(0.28, 0.10, 0.18, 0.22)
		_bg_canvas.add_child(glow)

	_build_moon()
	_start_shooting_star_timer()
	_spawn_city_embers()

func _spawn_city_embers() -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 991
	var palette: Array = [
		Color(1.0, 0.72, 0.28, 0.82),
		Color(0.90, 0.55, 1.0, 0.70),
		Color(0.50, 0.88, 1.0, 0.75),
		Color(1.0, 0.90, 0.38, 0.78),
	]
	for i in 28:
		var em := ColorRect.new()
		var sz: float = rng.randf_range(1.5, 3.8)
		em.size = Vector2(sz, sz)
		em.color = palette[rng.randi() % palette.size()]
		em.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sx: float = rng.randf_range(40.0, 1240.0)
		var sy: float = rng.randf_range(500.0, 565.0)
		em.position = Vector2(sx, sy)
		_bg_canvas.add_child(em)
		var period: float = rng.randf_range(4.5, 10.0)
		var delay: float = rng.randf_range(0.0, period)
		var drift_x: float = rng.randf_range(-20.0, 20.0)
		var rise_dist: float = rng.randf_range(70.0, 160.0)
		var tw := em.create_tween()
		tw.set_loops()
		tw.tween_callback(func(): em.position = Vector2(sx, sy); em.modulate.a = 0.0)
		tw.tween_interval(delay)
		tw.tween_property(em, "modulate:a", 0.90, 0.55)
		tw.set_parallel(true)
		tw.tween_property(em, "position:y", sy - rise_dist, period).set_ease(Tween.EASE_OUT)
		tw.tween_property(em, "position:x", sx + drift_x, period)
		tw.tween_property(em, "modulate:a", 0.0, period * 0.42).set_delay(period * 0.55)
		tw.set_parallel(false)
		tw.tween_interval(0.05)

func _build_moon() -> void:
	pass # луна на фото

func _start_shooting_star_timer() -> void:
	var t := Timer.new()
	t.wait_time = randf_range(6.0, 14.0)
	t.one_shot = true
	t.timeout.connect(_spawn_shooting_star)
	_bg_canvas.add_child(t)
	t.start()

func _spawn_shooting_star() -> void:
	var sx: float = randf_range(80, 900)
	var sy: float = randf_range(20, 200)
	var length: float = randf_range(55, 110)
	# Голова (яркая точка)
	var head := ColorRect.new()
	head.size = Vector2(4, 4); head.position = Vector2(sx, sy)
	head.color = Color(1.0, 1.0, 0.9, 0.95); _bg_canvas.add_child(head)
	# Хвост (полоса)
	var tail := ColorRect.new()
	tail.size = Vector2(length, 1.5); tail.rotation = deg_to_rad(-30)
	tail.position = Vector2(sx - length * 0.85, sy + length * 0.5)
	tail.color = Color(1.0, 1.0, 0.85, 0.60); _bg_canvas.add_child(tail)
	var tw := _bg_canvas.create_tween()
	tw.set_parallel(true)
	tw.tween_property(head, "position", Vector2(sx + 200, sy + 116), 0.55)
	tw.tween_property(tail, "position", Vector2(sx - length * 0.85 + 200, sy + length * 0.5 + 116), 0.55)
	tw.tween_property(head, "modulate:a", 0.0, 0.55)
	tw.tween_property(tail, "modulate:a", 0.0, 0.40)
	tw.tween_callback(head.queue_free).set_delay(0.56)
	tw.tween_callback(tail.queue_free).set_delay(0.56)
	_start_shooting_star_timer()

func _build_ui() -> void:
	# ── Оверлей для затемнения при наведении ─────────────────────────────────
	var hover_dim := ColorRect.new()
	hover_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	hover_dim.color = Color(0.0, 0.0, 0.04, 0.0)
	hover_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_canvas.add_child(hover_dim)

	# ── Версия — нижний левый угол ───────────────────────────────────────────
	var ver := Label.new()
	ver.text = "v1.5.0 — Godot 4"
	ver.add_theme_font_size_override("font_size", 10)
	ver.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 0.70))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ver.position = Vector2(12, -22)
	ver.modulate.a = 0.0
	_ui_canvas.add_child(ver)

	# ── ЗАГОЛОВОК (верхняя часть, без панели-фона) ───────────────────────────
	var logo_root := Control.new()
	logo_root.set_anchors_preset(Control.PRESET_TOP_WIDE)
	logo_root.custom_minimum_size = Vector2(0, 260)
	logo_root.modulate.a = 0.0
	_ui_canvas.add_child(logo_root)

	# Тонкая декоративная линия сверху
	var deco_line_top := ColorRect.new()
	deco_line_top.color = Color(0.80, 0.62, 0.10, 0.70)
	deco_line_top.size = Vector2(320, 1)
	deco_line_top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	deco_line_top.position = Vector2(-160, 52)
	logo_root.add_child(deco_line_top)

	# Маленький герб / иконка над названием
	var crown := Label.new()
	crown.text = "👑"
	crown.add_theme_font_size_override("font_size", 28)
	crown.set_anchors_preset(Control.PRESET_CENTER_TOP)
	crown.position = Vector2(-18, 60)
	logo_root.add_child(crown)
	# Парение иконки
	var crown_tw := create_tween().set_loops()
	crown_tw.tween_property(crown, "position:y", 55.0, 1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	crown_tw.tween_property(crown, "position:y", 65.0, 1.8).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Главный заголовок
	var title := Label.new()
	title.text = "ZERO TO OLIGARCH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.08))
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.0, 1.0))
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-320, 96)
	title.size = Vector2(640, 70)
	logo_root.add_child(title)

	# Декоративная линия снизу заголовка
	var deco_line_bot := ColorRect.new()
	deco_line_bot.color = Color(0.80, 0.62, 0.10, 0.70)
	deco_line_bot.size = Vector2(320, 1)
	deco_line_bot.set_anchors_preset(Control.PRESET_CENTER_TOP)
	deco_line_bot.position = Vector2(-160, 172)
	logo_root.add_child(deco_line_bot)

	# Подзаголовок
	var sub := Label.new()
	sub.text = "— A Russian Success Story —"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.72, 0.65, 0.42, 0.85))
	sub.add_theme_constant_override("outline_size", 2)
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.position = Vector2(-200, 180)
	sub.size = Vector2(400, 30)
	logo_root.add_child(sub)

	# ── ПАНЕЛЬ КНОПОК (нижняя часть) ─────────────────────────────────────────
	var btn_root := Control.new()
	btn_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	btn_root.custom_minimum_size = Vector2(0, 320)
	btn_root.position = Vector2(0, -320)
	btn_root.modulate.a = 0.0
	_ui_canvas.add_child(btn_root)

	# Стеклянная подложка
	var glass := Panel.new()
	glass.set_anchors_preset(Control.PRESET_CENTER)
	glass.size = Vector2(380, 280)
	glass.position = Vector2(-190, -150)
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color(0.02, 0.03, 0.08, 0.72)
	gs.border_color = Color(0.70, 0.55, 0.12, 0.40)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		gs.set_border_width(side, 1)
		gs.set_corner_radius(side, 20)
	gs.content_margin_left   = 30
	gs.content_margin_right  = 30
	gs.content_margin_top    = 22
	gs.content_margin_bottom = 22
	glass.add_theme_stylebox_override("panel", gs)
	btn_root.add_child(glass)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	glass.add_child(vbox)

	# Единый стиль: тёмный фон, золотая рамка, акцентный цвет левой полосы
	var new_btn := _make_button("▶  Новая игра",        Color(0.07, 0.10, 0.18), Color(0.72, 0.56, 0.10))
	new_btn.pressed.connect(func(): _toggle_slot_panel("new"))
	vbox.add_child(new_btn)

	if _has_save:
		var cont_btn := _make_button("⏩  Продолжить",   Color(0.07, 0.10, 0.18), Color(0.72, 0.56, 0.10))
		cont_btn.pressed.connect(func(): _toggle_slot_panel("continue"))
		vbox.add_child(cont_btn)

	var sep := ColorRect.new()
	sep.color = Color(0.72, 0.56, 0.10, 0.25)
	sep.custom_minimum_size = Vector2(0, 1)
	vbox.add_child(sep)

	var lb_btn := _make_button("🏆  Таблица рекордов", Color(0.07, 0.10, 0.18), Color(0.72, 0.56, 0.10))
	lb_btn.pressed.connect(_toggle_leaderboard)
	vbox.add_child(lb_btn)

	var cfg_btn := _make_button("⚙  Настройки",         Color(0.07, 0.10, 0.18), Color(0.72, 0.56, 0.10))
	cfg_btn.pressed.connect(_toggle_settings)
	vbox.add_child(cfg_btn)

	# ── Подсказки внизу экрана ───────────────────────────────────────────────
	var hint := Label.new()
	hint.text = "WASD — движение   •   E — действие   •   ESC — пауза"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55, 0.70))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.position = Vector2(0, -36)
	hint.modulate.a = 0.0
	_ui_canvas.add_child(hint)

	# ── Анимация появления ────────────────────────────────────────────────────
	var tw := _ui_canvas.create_tween()
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.10)
	tw.set_parallel(true)
	tw.tween_property(logo_root, "modulate:a", 1.0, 0.55)
	tw.tween_property(logo_root, "position:y", logo_root.position.y - 18, 0.55)
	tw.set_parallel(false)
	tw.tween_interval(0.15)
	tw.set_parallel(true)
	tw.tween_property(btn_root, "modulate:a", 1.0, 0.45)
	tw.tween_property(btn_root, "position:y", btn_root.position.y - 14, 0.45)
	tw.set_parallel(false)
	tw.tween_property(hint, "modulate:a", 1.0, 0.30)
	tw.tween_property(ver,  "modulate:a", 1.0, 0.20)

func _make_button(text: String, bg: Color, border: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 50)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_constant_override("outline_size", 1)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	btn.add_theme_stylebox_override("normal",  _flat_style(bg, border))
	btn.add_theme_stylebox_override("hover",   _flat_style(bg.lightened(0.18), border.lightened(0.22)))
	btn.add_theme_stylebox_override("pressed", _flat_style(bg.darkened(0.10), border))
	btn.add_theme_stylebox_override("focus",   _flat_style(bg, border))

	# Плавное затемнение фона при наведении
	btn.mouse_entered.connect(func():
		var dim := _ui_canvas.get_child(0)
		if dim is ColorRect:
			var tw := dim.create_tween()
			tw.tween_property(dim, "color:a", 0.52, 0.20).set_ease(Tween.EASE_OUT)
	)
	btn.mouse_exited.connect(func():
		var dim := _ui_canvas.get_child(0)
		if dim is ColorRect:
			var tw := dim.create_tween()
			tw.tween_property(dim, "color:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	)
	return btn

func _flat_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width(SIDE_LEFT,   3)
	s.set_border_width(SIDE_RIGHT,  1)
	s.set_border_width(SIDE_TOP,    1)
	s.set_border_width(SIDE_BOTTOM, 1)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_corner_radius(side, 10)
	s.shadow_color = Color(border.r, border.g, border.b, 0.35)
	s.shadow_size = 4
	return s

func _spacer(parent: Node, h: int) -> void:
	var sp = Control.new()
	sp.custom_minimum_size = Vector2(0, h)
	parent.add_child(sp)

func _toggle_leaderboard() -> void:
	if _lb_panel and is_instance_valid(_lb_panel):
		_lb_panel.queue_free()
		_lb_panel = null
		return

	var lb: Node = get_node_or_null("/root/LeaderboardManager")
	var entries: Array = lb.entries if lb else []

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(260, -210)
	panel.size = Vector2(420, 420)
	var lps := StyleBoxFlat.new()
	lps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	lps.border_color = Color(0.55, 0.42, 0.10, 0.90)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		lps.set_border_width(side, 2)
		lps.set_corner_radius(side, 10)
	panel.add_theme_stylebox_override("panel", lps)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	_ui_canvas.add_child(panel)
	_lb_panel = panel
	var lb_tw := _ui_canvas.create_tween()
	lb_tw.set_parallel(true)
	lb_tw.tween_property(panel, "modulate:a", 1.0, 0.22)
	lb_tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.22).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)
	var ttl := Label.new()
	ttl.text = "🏆 Лучшие забеги (Топ-5)"
	ttl.add_theme_font_size_override("font_size", 18)
	ttl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	ttl.add_theme_constant_override("outline_size", 3)
	ttl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(ttl)
	var cls := Button.new()
	cls.text = "✕"
	cls.custom_minimum_size = Vector2(30, 30)
	cls.add_theme_font_size_override("font_size", 13)
	var lcs := StyleBoxFlat.new()
	lcs.bg_color = Color(0.22, 0.07, 0.07, 0.90)
	lcs.border_color = Color(0.55, 0.18, 0.18, 0.80)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		lcs.set_border_width(s, 1)
		lcs.set_corner_radius(s, 6)
	cls.add_theme_stylebox_override("normal", lcs)
	cls.pressed.connect(func(): panel.queue_free(); _lb_panel = null)
	hdr.add_child(cls)

	vbox.add_child(HSeparator.new())

	if entries.is_empty():
		var empty := Label.new()
		empty.text = "Рекордов пока нет.\nСыграй и выйди в главное меню!"
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(empty)
	else:
		var gm: Node = get_node_or_null("/root/GameManager")
		var medals := ["🥇","🥈","🥉","4️⃣","5️⃣"]
		for i in entries.size():
			var e: Dictionary = entries[i]
			var row := HBoxContainer.new()
			vbox.add_child(row)
			var rank := Label.new()
			rank.text = medals[i]
			rank.add_theme_font_size_override("font_size", 18)
			rank.custom_minimum_size = Vector2(30, 0)
			row.add_child(rank)
			var info := VBoxContainer.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)
			var name_lbl := Label.new()
			var money_str: String = gm.format_money(e.money) if gm else ("%.0f ₽" % e.money)
			name_lbl.text = "%s  |  %s" % [e.title, money_str]
			name_lbl.add_theme_font_size_override("font_size", 14)
			info.add_child(name_lbl)
			var det := Label.new()
			det.text = "День %d  |  %s" % [e.day, e.date]
			det.add_theme_font_size_override("font_size", 11)
			det.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			info.add_child(det)
			vbox.add_child(HSeparator.new())

func _toggle_settings() -> void:
	if _settings_ui and is_instance_valid(_settings_ui) and _settings_ui.visible:
		_settings_ui._close()
		return
	_open_settings()

func _open_settings() -> void:
	if _settings_ui == null or not is_instance_valid(_settings_ui):
		_settings_ui = CanvasLayer.new()
		_settings_ui.set_script(load("res://scripts/SettingsUI.gd"))
		add_child(_settings_ui)
	_settings_ui.open()

func _toggle_slot_panel(mode: String) -> void:
	if _slot_panel and is_instance_valid(_slot_panel):
		_slot_panel.queue_free()
		_slot_panel = null
		return

	var gm = get_node_or_null("/root/GameManager")

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(420, 320)
	panel.position = Vector2(-210, -160)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.72, 0.56, 0.10, 0.85)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 12)
	ps.content_margin_left = 18; ps.content_margin_right = 18
	ps.content_margin_top = 16; ps.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", ps)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	_ui_canvas.add_child(panel)
	_slot_panel = panel
	var sp_tw := _ui_canvas.create_tween()
	sp_tw.set_parallel(true)
	sp_tw.tween_property(panel, "modulate:a", 1.0, 0.20)
	sp_tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.20).set_ease(Tween.EASE_OUT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "Выбери сохранение" if mode == "new" else "Выбери сохранение для загрузки"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.90, 0.78, 0.35))
	vbox.add_child(header)

	for slot in range(1, 4):
		var has_save: bool = gm != null and gm.slot_exists(slot)
		var info: Dictionary = gm.slot_info(slot) if has_save else {}
		var label_text: String
		if has_save:
			label_text = "Слот %d — День %d, %s, %s" % [slot, info.day, gm.format_money(info.money), info.title]
		else:
			label_text = "Слот %d — пусто" % slot
		var slot_btn := _make_button(label_text, Color(0.07, 0.10, 0.18), Color(0.72, 0.56, 0.10))
		if mode == "continue" and not has_save:
			slot_btn.disabled = true
			slot_btn.modulate.a = 0.4
		else:
			slot_btn.pressed.connect(_make_slot_handler(mode, slot, has_save))
		vbox.add_child(slot_btn)

	var close_btn := _make_button("Отмена", Color(0.10, 0.07, 0.07), Color(0.50, 0.20, 0.20))
	close_btn.pressed.connect(func():
		if _slot_panel and is_instance_valid(_slot_panel):
			_slot_panel.queue_free()
			_slot_panel = null
	)
	vbox.add_child(close_btn)

func _make_slot_handler(mode: String, slot: int, has_save: bool) -> Callable:
	return func():
		if mode == "new" and has_save:
			var dlg := ConfirmationDialog.new()
			dlg.title = "Слот %d занят" % slot
			dlg.dialog_text = "В этом слоте уже есть сохранение. Весь прогресс в нём (деньги, кредиты, репутация, образование, бизнес, радио и т.д.) будет полностью удалён без возможности восстановления.\n\nНачать заново в слоте %d?" % slot
			dlg.ok_button_text = "Да, сбросить и начать"
			dlg.cancel_button_text = "Отмена"
			add_child(dlg)
			dlg.confirmed.connect(func(): _show_difficulty_dialog(slot))
			dlg.confirmed.connect(dlg.queue_free)
			dlg.canceled.connect(dlg.queue_free)
			dlg.popup_centered()
		elif mode == "new":
			_show_difficulty_dialog(slot)
		else:
			_continue_game(slot)

# Окно выбора сложности перед стартом новой игры в слоте
func _show_difficulty_dialog(slot: int) -> void:
	if _slot_panel and is_instance_valid(_slot_panel):
		_slot_panel.queue_free()
		_slot_panel = null
	var sm = get_node_or_null("/root/SettingsManager")

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(480, 430)
	panel.position = Vector2(-240, -215)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.72, 0.56, 0.10, 0.85)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 12)
	ps.content_margin_left = 18; ps.content_margin_right = 18
	ps.content_margin_top = 16; ps.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", ps)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	_ui_canvas.add_child(panel)
	_slot_panel = panel

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 9)
	panel.add_child(vbox)

	var header := Label.new()
	header.text = "Выбери сложность · Слот %d" % slot
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.90, 0.78, 0.35))
	vbox.add_child(header)

	# [ключ, подпись, цвет рамки]
	var diffs := [
		["easy",     "🟢 Лёгкая — при истощении максимум 75 (3 дн.)", Color(0.20, 0.55, 0.25)],
		["normal",   "🟡 Средняя — при истощении максимум 50 (3 дн.)", Color(0.62, 0.55, 0.15)],
		["hard",     "🟠 Тяжёлая — при истощении максимум 25 (3 дн.)", Color(0.62, 0.38, 0.12)],
		["hardcore", "🔴 Хардкор — при 0 здоровья смерть",              Color(0.60, 0.18, 0.18)],
	]
	for d in diffs:
		var key: String = d[0]
		var btn := _make_button(d[1], Color(0.07, 0.10, 0.18), d[2])
		btn.pressed.connect(func():
			if sm: sm.set_difficulty(key)
			_start_new(slot))
		vbox.add_child(btn)

	var cancel := _make_button("Отмена", Color(0.10, 0.07, 0.07), Color(0.50, 0.20, 0.20))
	cancel.pressed.connect(func():
		if _slot_panel and is_instance_valid(_slot_panel):
			_slot_panel.queue_free()
			_slot_panel = null)
	vbox.add_child(cancel)

	var tw := _ui_canvas.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.20)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.20).set_ease(Tween.EASE_OUT)

func _start_new(slot: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_slot = slot
		gm.reset_game()
	SceneTransition.go("res://scenes/World.tscn")

func _continue_game(slot: int) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_slot = slot
		gm.load_game()
	SceneTransition.go("res://scenes/World.tscn")
