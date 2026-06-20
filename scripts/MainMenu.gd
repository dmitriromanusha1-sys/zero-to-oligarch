extends Node2D

var _has_save: bool = false
var _slot_panel: Control = null
var _lb_panel: Control = null
var _settings_panel: Control = null
var _rebind_panel_ref: Control = null

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
	# Перехват нажатия для перепривязки клавиш
	if _rebind_panel_ref and is_instance_valid(_rebind_panel_ref):
		var panel := _rebind_panel_ref
		if panel.has_meta("_rebind_action") and panel.get_meta("_rebinding")[0]:
			if event is InputEventKey and event.pressed and not event.echo:
				var action: String = panel.get_meta("_rebind_action")
				var btn: Button = panel.get_meta("_rebind_btn_ref")
				var rebinding: Array = panel.get_meta("_rebinding")
				# ESC = отмена
				if event.keycode == KEY_ESCAPE:
					btn.text = _get_action_key_label(action)
					_style_key_btn(btn, false)
					rebinding[0] = false
					get_viewport().set_input_as_handled()
					return
				# Применяем новую клавишу
				InputMap.action_erase_events(action)
				var new_ev := InputEventKey.new()
				new_ev.keycode = event.keycode
				InputMap.action_add_event(action, new_ev)
				btn.text = _get_action_key_label(action)
				_style_key_btn(btn, false)
				rebinding[0] = false
				get_viewport().set_input_as_handled()
				return

	if event.is_action_pressed("ui_cancel"):
		if _settings_panel and is_instance_valid(_settings_panel):
			_settings_panel.queue_free()
			_settings_panel = null
			get_viewport().set_input_as_handled()
		elif _lb_panel and is_instance_valid(_lb_panel):
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
	ver.text = "v0.6.3 beta — Godot 4"
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
	if _settings_panel and is_instance_valid(_settings_panel):
		_settings_panel.queue_free()
		_settings_panel = null
		return
	_show_settings()

func _show_settings() -> void:
	var sm: Node = get_node_or_null("/root/SettingsManager")

	# ── Backdrop ──────────────────────────────────────────────────────────────
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0, 0, 0, 0.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_ui_canvas.add_child(backdrop)
	backdrop.create_tween().tween_property(backdrop, "color:a", 0.35, 0.22)

	# ── Панель ────────────────────────────────────────────────────────────────
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(480, 580)
	panel.position = Vector2(-240, -290)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.40, 0.40, 0.55, 0.90)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 12)
	ps.content_margin_left   = 20
	ps.content_margin_right  = 20
	ps.content_margin_top    = 14
	ps.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", ps)
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	_ui_canvas.add_child(panel)
	_settings_panel = panel

	backdrop.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			panel.queue_free()
			_settings_panel = null
	)
	panel.tree_exiting.connect(func():
		if is_instance_valid(backdrop): backdrop.queue_free()
		_rebind_panel_ref = null
	)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 8)
	panel.add_child(root_vbox)

	var L: Node = get_node_or_null("/root/Localization")

	# ── Заголовок + кнопка закрыть ───────────────────────────────────────────
	var hdr := HBoxContainer.new()
	root_vbox.add_child(hdr)
	var ttl := Label.new()
	ttl.text = L.t("settings_title") if L else "⚙  Настройки"
	ttl.add_theme_font_size_override("font_size", 20)
	ttl.add_theme_color_override("font_color", Color(0.88, 0.88, 1.0))
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
	cls.pressed.connect(func(): panel.queue_free(); _settings_panel = null)
	hdr.add_child(cls)

	# ── Профили настроек ─────────────────────────────────────────────────────
	var prof_header := HBoxContainer.new()
	prof_header.add_theme_constant_override("separation", 6)
	root_vbox.add_child(prof_header)

	var prof_title := Label.new()
	prof_title.text = "ПРОФИЛИ"
	prof_title.add_theme_font_size_override("font_size", 10)
	prof_title.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60))
	prof_title.custom_minimum_size = Vector2(58, 0)
	prof_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prof_header.add_child(prof_title)

	var PROFILE_NAMES: Array = ["Слот 1", "Слот 2", "Слот 3"]
	for pi in 3:
		var slot_bg := StyleBoxFlat.new()
		slot_bg.bg_color = Color(0.08, 0.08, 0.14)
		slot_bg.border_color = Color(0.25, 0.25, 0.38)
		for _s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			slot_bg.set_border_width(_s, 1)
			slot_bg.set_corner_radius(_s, 5)

		var slot_panel := Panel.new()
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_panel.custom_minimum_size = Vector2(0, 28)
		slot_panel.add_theme_stylebox_override("panel", slot_bg)
		prof_header.add_child(slot_panel)

		var inner := HBoxContainer.new()
		inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		inner.add_theme_constant_override("separation", 2)
		slot_panel.add_child(inner)

		var sp1 := Control.new(); sp1.custom_minimum_size = Vector2(4, 0)
		inner.add_child(sp1)

		var name_lbl := Label.new()
		name_lbl.text = PROFILE_NAMES[pi]
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color",
			Color(0.75, 0.90, 0.75) if (sm and sm.profile_filled(pi)) else Color(0.40, 0.40, 0.52))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		inner.add_child(name_lbl)

		var save_btn := Button.new()
		save_btn.text = "💾"
		save_btn.tooltip_text = "Сохранить профиль"
		save_btn.custom_minimum_size = Vector2(26, 24)
		save_btn.add_theme_font_size_override("font_size", 12)
		var ss := StyleBoxFlat.new()
		ss.bg_color = Color(0.10, 0.18, 0.10)
		ss.border_color = Color(0.28, 0.55, 0.28, 0.80)
		for _s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			ss.set_border_width(_s, 1); ss.set_corner_radius(_s, 4)
		save_btn.add_theme_stylebox_override("normal", ss)
		var pslot: int = pi
		save_btn.pressed.connect(func():
			if sm:
				sm.save_profile(pslot)
				name_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 0.75))
				var tw2 := save_btn.create_tween()
				save_btn.modulate = Color(0.5, 1.8, 0.5)
				tw2.tween_property(save_btn, "modulate", Color(1, 1, 1), 0.5)
		)
		inner.add_child(save_btn)

		var load_btn := Button.new()
		load_btn.text = "▶"
		load_btn.tooltip_text = "Загрузить профиль"
		load_btn.custom_minimum_size = Vector2(26, 24)
		load_btn.add_theme_font_size_override("font_size", 11)
		load_btn.disabled = not (sm and sm.profile_filled(pi))
		var ls2 := StyleBoxFlat.new()
		ls2.bg_color = Color(0.10, 0.14, 0.22) if (sm and sm.profile_filled(pi)) else Color(0.07, 0.07, 0.10)
		ls2.border_color = Color(0.28, 0.40, 0.70, 0.80) if (sm and sm.profile_filled(pi)) else Color(0.18, 0.18, 0.25)
		for _s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			ls2.set_border_width(_s, 1); ls2.set_corner_radius(_s, 4)
		load_btn.add_theme_stylebox_override("normal", ls2)
		load_btn.pressed.connect(func():
			if sm and sm.profile_filled(pslot):
				sm.load_profile(pslot)
				panel.queue_free()
				_settings_panel = null
				_show_settings()
		)
		inner.add_child(load_btn)

	root_vbox.add_child(HSeparator.new())

	# ── Строка вкладок ────────────────────────────────────────────────────────
	var TAB_DEFS: Array = [
		{"label": L.t("tab_sound")    if L else "🔊 Звук",      "id": "sound"},
		{"label": L.t("tab_screen")   if L else "🖥 Экран",     "id": "screen"},
		{"label": L.t("tab_gameplay") if L else "🎮 Геймплей",  "id": "gameplay"},
		{"label": L.t("tab_access")   if L else "♿ Доступн.",   "id": "access"},
		{"label": L.t("tab_controls") if L else "⌨ Клавиши",   "id": "controls"},
		{"label": L.t("tab_history")  if L else "📋 История",   "id": "history"},
	]
	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 4)
	root_vbox.add_child(tab_bar)

	# Контейнер страниц
	var pages := {} # id → VBoxContainer
	var page_host := Control.new()
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(page_host)

	for td in TAB_DEFS:
		var pg := VBoxContainer.new()
		pg.set_anchors_preset(Control.PRESET_FULL_RECT)
		pg.add_theme_constant_override("separation", 10)
		pg.visible = false
		page_host.add_child(pg)
		pages[td.id] = pg

	var _active_tab := ["sound"]
	var tab_btns: Array = []

	var _switch_tab := func(tab_id: String) -> void:
		_active_tab[0] = tab_id
		for td2 in TAB_DEFS:
			pages[td2.id].visible = (td2.id == tab_id)
		for i in tab_btns.size():
			_style_tab_btn(tab_btns[i], TAB_DEFS[i].id == tab_id)

	for td in TAB_DEFS:
		var tb := Button.new()
		tb.text = td.label
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 34)
		tb.add_theme_font_size_override("font_size", 13)
		var tid: String = td.id
		tb.pressed.connect(func(): _switch_tab.call(tid))
		tab_bar.add_child(tb)
		tab_btns.append(tb)

	# ── Страница: Звук ────────────────────────────────────────────────────────
	var pg_sound: VBoxContainer = pages["sound"]

	var snd_lbl := Label.new()
	snd_lbl.text = L.t("volume_section") if L else "ГРОМКОСТЬ"
	snd_lbl.add_theme_font_size_override("font_size", 11)
	snd_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_sound.add_child(snd_lbl)

	_add_slider_row(pg_sound, sm.master_vol if sm else 1.0,
		func(v: float): if sm: sm.set_master_vol(v),
		["🔇", "🔈", "🔊"], L.t("master") if L else "Мастер")
	_add_slider_row(pg_sound, sm.music_vol if sm else 1.0,
		func(v: float): if sm: sm.set_music_vol(v),
		["🔇", "🎵", "🎵"], L.t("music") if L else "Музыка")
	_add_slider_row(pg_sound, sm.sfx_vol if sm else 1.0,
		func(v: float): if sm: sm.set_sfx_vol(v),
		["🔇", "🔈", "🔊"], L.t("sounds") if L else "Звуки")

	pg_sound.add_child(HSeparator.new())

	var fps_lbl2 := Label.new()
	fps_lbl2.text = L.t("fps_section") if L else "ОГРАНИЧЕНИЕ FPS"
	fps_lbl2.add_theme_font_size_override("font_size", 11)
	fps_lbl2.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_sound.add_child(fps_lbl2)

	var fps_row := HBoxContainer.new()
	fps_row.alignment = BoxContainer.ALIGNMENT_CENTER
	fps_row.add_theme_constant_override("separation", 6)
	pg_sound.add_child(fps_row)
	var fps_opts: Array = [30, 60, 120, 0]
	var fps_labels: Array = ["30", "60", "120", "∞"]
	var fps_btns: Array = []
	var cur_fps: int = sm.fps_cap if sm else 60
	for i in fps_opts.size():
		var fb := Button.new()
		fb.text = fps_labels[i]
		fb.custom_minimum_size = Vector2(70, 32)
		fb.add_theme_font_size_override("font_size", 14)
		var cap_val: int = fps_opts[i]
		fb.pressed.connect(func():
			if sm: sm.set_fps_cap(cap_val)
			for j in fps_btns.size():
				_style_fps_btn(fps_btns[j], fps_opts[j] == cap_val)
		)
		_style_fps_btn(fb, fps_opts[i] == cur_fps)
		fps_row.add_child(fb)
		fps_btns.append(fb)

	pg_sound.add_child(HSeparator.new())
	var reset_btn := Button.new()
	reset_btn.text = L.t("reset_settings") if L else "↺  Сбросить все настройки"
	reset_btn.custom_minimum_size = Vector2(0, 36)
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.add_theme_font_size_override("font_size", 13)
	reset_btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.14, 0.10, 0.10, 0.80)
	rs.border_color = Color(0.40, 0.30, 0.30, 0.70)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		rs.set_border_width(s, 1)
		rs.set_corner_radius(s, 8)
	reset_btn.add_theme_stylebox_override("normal", rs)
	var rsh := rs.duplicate() as StyleBoxFlat
	rsh.bg_color = rs.bg_color.lightened(0.10)
	reset_btn.add_theme_stylebox_override("hover", rsh)
	reset_btn.pressed.connect(func(): _confirm_reset(sm, panel))
	pg_sound.add_child(reset_btn)

	# ── Страница: Экран ───────────────────────────────────────────────────────
	var pg_screen: VBoxContainer = pages["screen"]

	var scr_lbl := Label.new()
	scr_lbl.text = L.t("window_mode") if L else "РЕЖИМ ОКНА"
	scr_lbl.add_theme_font_size_override("font_size", 11)
	scr_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_screen.add_child(scr_lbl)

	_add_toggle_row(pg_screen, L.t("fullscreen") if L else "🖥  Полный экран", sm and sm.fullscreen,
		func(on: bool): if sm: sm.set_fullscreen(on))
	_add_toggle_row(pg_screen, L.t("vsync") if L else "⟳  VSync", sm.vsync if sm else true,
		func(on: bool): if sm: sm.set_vsync(on))

	pg_screen.add_child(HSeparator.new())

	var res_lbl := Label.new()
	res_lbl.text = L.t("resolution") if L else "РАЗРЕШЕНИЕ ОКНА"
	res_lbl.add_theme_font_size_override("font_size", 11)
	res_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_screen.add_child(res_lbl)

	var res_note := Label.new()
	res_note.text = L.t("window_only") if L else "Применяется только в оконном режиме"
	res_note.add_theme_font_size_override("font_size", 10)
	res_note.add_theme_color_override("font_color", Color(0.40, 0.40, 0.50))
	pg_screen.add_child(res_note)

	var RES_OPTS: Array = [
		{"label": "1280×720",  "size": Vector2i(1280, 720)},
		{"label": "1600×900",  "size": Vector2i(1600, 900)},
		{"label": "1920×1080", "size": Vector2i(1920, 1080)},
	]
	var cur_size: Vector2i = DisplayServer.window_get_size()
	var res_btns: Array = []
	var res_row1 := HBoxContainer.new()
	res_row1.alignment = BoxContainer.ALIGNMENT_CENTER
	res_row1.add_theme_constant_override("separation", 6)
	pg_screen.add_child(res_row1)
	for ri in RES_OPTS.size():
		var rb := Button.new()
		rb.text = RES_OPTS[ri].label
		rb.custom_minimum_size = Vector2(110, 32)
		rb.add_theme_font_size_override("font_size", 12)
		var rsize: Vector2i = RES_OPTS[ri].size
		rb.pressed.connect(func():
			if sm and sm.fullscreen: return
			DisplayServer.window_set_size(rsize)
			var win_pos := DisplayServer.screen_get_size() / 2 - rsize / 2
			DisplayServer.window_set_position(win_pos)
			for j in res_btns.size():
				_style_fps_btn(res_btns[j], RES_OPTS[j].size == rsize)
		)
		var is_cur: bool = (cur_size == RES_OPTS[ri].size)
		_style_fps_btn(rb, is_cur)
		res_row1.add_child(rb)
		res_btns.append(rb)

	pg_screen.add_child(HSeparator.new())

	var lang_lbl := Label.new()
	lang_lbl.text = L.t("language_section") if L else "ЯЗЫК ИНТЕРФЕЙСА"
	lang_lbl.add_theme_font_size_override("font_size", 11)
	lang_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_screen.add_child(lang_lbl)

	var lang_row := HBoxContainer.new()
	lang_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_row.add_theme_constant_override("separation", 10)
	pg_screen.add_child(lang_row)

	var LANGS: Array = [{"id": "ru", "label": "🇷🇺  Русский"}, {"id": "en", "label": "🇬🇧  English"}]
	var lang_btns: Array = []
	var cur_locale: String = L.locale if L else "ru"
	for ld in LANGS:
		var lb2 := Button.new()
		lb2.text = ld.label
		lb2.custom_minimum_size = Vector2(150, 34)
		lb2.add_theme_font_size_override("font_size", 13)
		var lid: String = ld.id
		lb2.pressed.connect(func():
			if sm: sm.set_locale(lid)
			for j in lang_btns.size():
				_style_tab_btn(lang_btns[j], LANGS[j].id == lid)
			# Переоткрываем панель чтобы все строки обновились
			panel.queue_free()
			_settings_panel = null
			_show_settings()
		)
		_style_tab_btn(lb2, ld.id == cur_locale)
		lang_row.add_child(lb2)
		lang_btns.append(lb2)

	# ── Страница: Геймплей ───────────────────────────────────────────────────
	var pg_gp: VBoxContainer = pages["gameplay"]

	var diff_lbl := Label.new()
	diff_lbl.text = L.t("difficulty_section") if L else "СЛОЖНОСТЬ"
	diff_lbl.add_theme_font_size_override("font_size", 11)
	diff_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_gp.add_child(diff_lbl)

	var DIFFS: Array = [
		{
			"id":    "easy",
			"label": L.t("diff_easy")      if L else "🌱 Лёгкая",
			"desc":  L.t("diff_easy_desc") if L else "Штрафы и налоги ×0.5\nГолод убывает медленнее",
			"col":   Color(0.30, 0.72, 0.35),
		},
		{
			"id":    "normal",
			"label": L.t("diff_normal")      if L else "⚖ Нормальная",
			"desc":  L.t("diff_normal_desc") if L else "Стандартный баланс",
			"col":   Color(0.65, 0.65, 0.85),
		},
		{
			"id":    "hardcore",
			"label": L.t("diff_hardcore")      if L else "💀 Хардкор",
			"desc":  L.t("diff_hardcore_desc") if L else "Штрафы и налоги ×1.5\nГолод убывает быстрее",
			"col":   Color(0.90, 0.35, 0.35),
		},
	]

	var cur_diff: String = sm.difficulty if sm else "normal"
	var diff_btns: Array = []

	for dd in DIFFS:
		var card := Panel.new()
		card.custom_minimum_size = Vector2(0, 58)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pg_gp.add_child(card)

		var card_inner := HBoxContainer.new()
		card_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_inner.add_theme_constant_override("separation", 10)
		card.add_child(card_inner)

		var sp_l := Control.new(); sp_l.custom_minimum_size = Vector2(8, 0)
		card_inner.add_child(sp_l)

		var text_col := VBoxContainer.new()
		text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_col.alignment = BoxContainer.ALIGNMENT_CENTER
		card_inner.add_child(text_col)

		var d_name := Label.new()
		d_name.text = dd.label
		d_name.add_theme_font_size_override("font_size", 14)
		text_col.add_child(d_name)

		var d_desc := Label.new()
		d_desc.text = dd.desc
		d_desc.add_theme_font_size_override("font_size", 10)
		d_desc.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
		text_col.add_child(d_desc)

		var sel_btn := Button.new()
		sel_btn.custom_minimum_size = Vector2(80, 32)
		sel_btn.add_theme_font_size_override("font_size", 12)
		card_inner.add_child(sel_btn)

		var sp_r := Control.new(); sp_r.custom_minimum_size = Vector2(6, 0)
		card_inner.add_child(sp_r)

		diff_btns.append({"card": card, "btn": sel_btn, "dd": dd, "name_lbl": d_name})

	# Применяем стиль после сборки всех карточек
	var _apply_diff_styles := func(active_id: String) -> void:
		for entry in diff_btns:
			var is_active: bool = entry.dd.id == active_id
			var col: Color = entry.dd.col
			var cs := StyleBoxFlat.new()
			cs.bg_color = Color(col.r * 0.15, col.g * 0.15, col.b * 0.15, 0.90) if is_active \
				else Color(0.07, 0.07, 0.11, 0.90)
			cs.border_color = col.lerp(Color(1,1,1), 0.1) if is_active else Color(0.20, 0.20, 0.30)
			for sd in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
				cs.set_border_width(sd, 2 if is_active else 1)
				cs.set_corner_radius(sd, 7)
			entry.card.add_theme_stylebox_override("panel", cs)
			entry.btn.text = "✓ Выбрано" if is_active else "Выбрать"
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25) if is_active \
				else Color(0.10, 0.10, 0.16)
			bs.border_color = col if is_active else Color(0.28, 0.28, 0.42)
			for sd in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
				bs.set_border_width(sd, 1 if is_active else 1)
				bs.set_corner_radius(sd, 5)
			entry.btn.add_theme_stylebox_override("normal", bs)
			entry.btn.add_theme_color_override("font_color",
				col.lerp(Color(1,1,1), 0.3) if is_active else Color(0.60, 0.60, 0.70))
			entry.name_lbl.add_theme_color_override("font_color", col if is_active else Color(0.75, 0.75, 0.80))

	_apply_diff_styles.call(cur_diff)

	for entry in diff_btns:
		var did: String = entry.dd.id
		entry.btn.pressed.connect(func():
			if sm: sm.set_difficulty(did)
			_apply_diff_styles.call(did)
		)

	pg_gp.add_child(HSeparator.new())

	# Скорость времени по умолчанию
	var spd_lbl := Label.new()
	spd_lbl.text = L.t("speed_section") if L else "СКОРОСТЬ ВРЕМЕНИ ПО УМОЛЧАНИЮ"
	spd_lbl.add_theme_font_size_override("font_size", 11)
	spd_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_gp.add_child(spd_lbl)

	var spd_row := HBoxContainer.new()
	spd_row.alignment = BoxContainer.ALIGNMENT_CENTER
	spd_row.add_theme_constant_override("separation", 8)
	pg_gp.add_child(spd_row)

	var SPD_OPTS: Array = [1.0, 2.0, 3.0]
	var SPD_LABELS: Array = ["×1", "×2", "×3"]
	var spd_btns: Array = []
	var cur_spd: float = sm.default_speed if sm else 1.0
	for si in SPD_OPTS.size():
		var sb := Button.new()
		sb.text = SPD_LABELS[si]
		sb.custom_minimum_size = Vector2(80, 32)
		sb.add_theme_font_size_override("font_size", 14)
		var sv: float = SPD_OPTS[si]
		sb.pressed.connect(func():
			if sm: sm.set_default_speed(sv)
			for j in spd_btns.size():
				_style_fps_btn(spd_btns[j], absf(SPD_OPTS[j] - sv) < 0.01)
		)
		_style_fps_btn(sb, absf(SPD_OPTS[si] - cur_spd) < 0.01)
		spd_row.add_child(sb)
		spd_btns.append(sb)

	pg_gp.add_child(HSeparator.new())

	# Прочее
	var other_lbl := Label.new()
	other_lbl.text = L.t("autopause_section") if L else "ПРОЧЕЕ"
	other_lbl.add_theme_font_size_override("font_size", 11)
	other_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_gp.add_child(other_lbl)

	_add_toggle_row(pg_gp, L.t("autopause_label") if L else "⏸  Пауза при открытии меню",
		sm.autopause if sm else true,
		func(on: bool): if sm: sm.set_autopause(on))

	pg_gp.add_child(HSeparator.new())

	# Уведомления
	var notif_lbl := Label.new()
	notif_lbl.text = "УВЕДОМЛЕНИЯ"
	notif_lbl.add_theme_font_size_override("font_size", 11)
	notif_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_gp.add_child(notif_lbl)

	var NOTIFS: Array = [
		{"key": "autosave",     "label": "💾  Автосохранение",       "val": sm.notify_autosave     if sm else true},
		{"key": "events",       "label": "📰  Случайные события",     "val": sm.notify_events       if sm else true},
		{"key": "achievements", "label": "🏆  Достижения",            "val": sm.notify_achievements if sm else true},
		{"key": "taxes",        "label": "📋  Налоги",                "val": sm.notify_taxes        if sm else true},
		{"key": "police",       "label": "👮  Полиция",               "val": sm.notify_police       if sm else true},
		{"key": "hints",        "label": "💡  Подсказки для новичков","val": sm.show_hints          if sm else true},
	]
	for nd in NOTIFS:
		var nkey: String = nd.key
		_add_toggle_row(pg_gp, nd.label, nd.val,
			func(on: bool): if sm: sm.set_notify(nkey, on))

	# ── Страница: Доступность ────────────────────────────────────────────────
	var pg_acc: VBoxContainer = pages["access"]
	var hc: bool = sm.high_contrast if sm else false

	# Размер текста
	var fs_lbl := Label.new()
	fs_lbl.text = L.t("font_size_section") if L else "РАЗМЕР ТЕКСТА"
	fs_lbl.add_theme_font_size_override("font_size", 11)
	fs_lbl.add_theme_color_override("font_color",
		Color(1.0, 1.0, 0.0) if hc else Color(0.50, 0.50, 0.65))
	pg_acc.add_child(fs_lbl)

	var fs_row := HBoxContainer.new()
	fs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	fs_row.add_theme_constant_override("separation", 8)
	pg_acc.add_child(fs_row)

	var FS_OPTS: Array = [
		{"id": "normal", "label": L.t("font_normal")  if L else "Обычный"},
		{"id": "large",  "label": L.t("font_large")   if L else "Крупный"},
		{"id": "xlarge", "label": L.t("font_xlarge")  if L else "Очень крупный"},
	]
	var cur_fs: String = sm.font_size if sm else "normal"
	var fs_btns: Array = []
	for fi in FS_OPTS.size():
		var fb2 := Button.new()
		fb2.text = FS_OPTS[fi].label
		fb2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fb2.custom_minimum_size = Vector2(0, 34)
		fb2.add_theme_font_size_override("font_size", [13, 16, 20][fi])
		var fid: String = FS_OPTS[fi].id
		fb2.pressed.connect(func():
			if sm: sm.set_font_size(fid)
			for j in fs_btns.size():
				_style_fps_btn(fs_btns[j], FS_OPTS[j].id == fid)
			panel.queue_free(); _settings_panel = null; _show_settings()
		)
		_style_fps_btn(fb2, FS_OPTS[fi].id == cur_fs)
		fs_row.add_child(fb2)
		fs_btns.append(fb2)

	var fs_note := Label.new()
	fs_note.text = L.t("access_note") if L else "Изменения шрифта применяются\nпри следующем открытии панелей"
	fs_note.add_theme_font_size_override("font_size", 10)
	fs_note.add_theme_color_override("font_color", Color(0.40, 0.40, 0.50))
	fs_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pg_acc.add_child(fs_note)

	pg_acc.add_child(HSeparator.new())

	# Контраст
	var ct_lbl := Label.new()
	ct_lbl.text = L.t("contrast_section") if L else "КОНТРАСТ"
	ct_lbl.add_theme_font_size_override("font_size", 11)
	ct_lbl.add_theme_color_override("font_color",
		Color(1.0, 1.0, 0.0) if hc else Color(0.50, 0.50, 0.65))
	pg_acc.add_child(ct_lbl)

	_add_toggle_row(pg_acc, L.t("high_contrast_label") if L else "⬛  Высокий контраст",
		hc, func(on: bool):
			if sm: sm.set_high_contrast(on)
			panel.queue_free(); _settings_panel = null; _show_settings()
	)

	pg_acc.add_child(HSeparator.new())

	# Анимации
	var an_lbl := Label.new()
	an_lbl.text = L.t("anim_section") if L else "АНИМАЦИИ"
	an_lbl.add_theme_font_size_override("font_size", 11)
	an_lbl.add_theme_color_override("font_color",
		Color(1.0, 1.0, 0.0) if hc else Color(0.50, 0.50, 0.65))
	pg_acc.add_child(an_lbl)

	_add_toggle_row(pg_acc, L.t("ui_anim_label") if L else "✨  Анимации интерфейса",
		sm.ui_animations if sm else true,
		func(on: bool): if sm: sm.set_ui_animations(on))

	# ── Страница: Управление ──────────────────────────────────────────────────
	var pg_ctrl: VBoxContainer = pages["controls"]

	var ctrl_lbl := Label.new()
	ctrl_lbl.text = L.t("keybinds") if L else "ГОРЯЧИЕ КЛАВИШИ"
	ctrl_lbl.add_theme_font_size_override("font_size", 11)
	ctrl_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.65))
	pg_ctrl.add_child(ctrl_lbl)

	var ACTIONS: Array = [
		{"action": "move_up",    "label": L.t("action_up")       if L else "Вверх"},
		{"action": "move_down",  "label": L.t("action_down")     if L else "Вниз"},
		{"action": "move_left",  "label": L.t("action_left")     if L else "Влево"},
		{"action": "move_right", "label": L.t("action_right")    if L else "Вправо"},
		{"action": "interact",   "label": L.t("action_interact") if L else "Взаимодействие"},
		{"action": "ui_cancel",  "label": L.t("action_pause")    if L else "Пауза / Закрыть"},
		{"action": "sleep",      "label": L.t("action_sleep")    if L else "Сон"},
	]
	var _rebinding := [false]
	var _rebind_btn: Array = [null]

	for ad in ACTIONS:
		var act_row := HBoxContainer.new()
		act_row.add_theme_constant_override("separation", 8)
		pg_ctrl.add_child(act_row)
		var act_lbl := Label.new()
		act_lbl.text = ad.label
		act_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		act_lbl.add_theme_font_size_override("font_size", 13)
		act_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.85))
		act_row.add_child(act_lbl)
		var key_btn := Button.new()
		key_btn.custom_minimum_size = Vector2(110, 30)
		key_btn.add_theme_font_size_override("font_size", 12)
		key_btn.text = _get_action_key_label(ad.action)
		_style_key_btn(key_btn, false)
		var action_name: String = ad.action
		key_btn.pressed.connect(func():
			if _rebinding[0]: return
			_rebinding[0] = true
			if _rebind_btn[0] and is_instance_valid(_rebind_btn[0]):
				_style_key_btn(_rebind_btn[0], false)
				_rebind_btn[0].text = _get_action_key_label(
					_rebind_btn[0].get_meta("action_name", ""))
			_rebind_btn[0] = key_btn
			key_btn.text = L.t("waiting_key") if L else "[ нажми клавишу ]"
			_style_key_btn(key_btn, true)
			# Ждём нажатия через временный обработчик на панели
			panel.set_meta("_rebind_action", action_name)
			panel.set_meta("_rebind_btn_ref", key_btn)
			panel.set_meta("_rebinding", _rebinding)
		)
		key_btn.set_meta("action_name", action_name)
		act_row.add_child(key_btn)

	var ctrl_hint := Label.new()
	ctrl_hint.text = L.t("rebind_hint") if L else "Нажми кнопку → затем нажми нужную клавишу"
	ctrl_hint.add_theme_font_size_override("font_size", 10)
	ctrl_hint.add_theme_color_override("font_color", Color(0.38, 0.38, 0.50))
	ctrl_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pg_ctrl.add_child(ctrl_hint)

	# Перехват нажатий для перепривязки
	panel.set_process_unhandled_input(true)
	panel.set_script(null)  # панель — чистый Panel, подпишемся через метасигнал ниже

	# Используем _unhandled_input на уровне сцены, передаём контекст через meta
	_rebind_panel_ref = panel

	# ── Активируем первую вкладку ─────────────────────────────────────────────
	# ── Страница: История ────────────────────────────────────────────────────
	var pg_hist: VBoxContainer = pages["history"]

	var log_entries: Array = sm.change_log if sm else []

	if log_entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = L.t("history_empty") if L else "Изменений пока нет.\nОткрой настройки и что-нибудь измени."
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.52))
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pg_hist.add_child(empty_lbl)
	else:
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		pg_hist.add_child(scroll)

		var log_list := VBoxContainer.new()
		log_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		log_list.add_theme_constant_override("separation", 2)
		scroll.add_child(log_list)

		for i in log_entries.size():
			var entry: String = log_entries[i]
			var row := Panel.new()
			row.custom_minimum_size = Vector2(0, 28)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var row_style := StyleBoxFlat.new()
			row_style.bg_color = Color(0.10, 0.10, 0.16) if i % 2 == 0 else Color(0.07, 0.07, 0.12)
			for _sd in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
				row_style.set_corner_radius(_sd, 4)
			row.add_theme_stylebox_override("panel", row_style)
			log_list.add_child(row)

			var row_lbl := Label.new()
			row_lbl.text = entry
			row_lbl.add_theme_font_size_override("font_size", 12)
			row_lbl.add_theme_color_override("font_color",
				Color(0.85, 0.92, 0.85) if i == 0 else Color(0.60, 0.62, 0.65))
			row_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
			row_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			row_lbl.add_theme_constant_override("margin_left", 8)
			row.add_child(row_lbl)

	pg_hist.add_child(HSeparator.new())

	var clear_btn := Button.new()
	clear_btn.text = L.t("history_clear") if L else "🗑  Очистить журнал"
	clear_btn.custom_minimum_size = Vector2(0, 30)
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.add_theme_font_size_override("font_size", 12)
	clear_btn.add_theme_color_override("font_color", Color(0.65, 0.45, 0.45))
	var cls2 := StyleBoxFlat.new()
	cls2.bg_color = Color(0.12, 0.07, 0.07)
	cls2.border_color = Color(0.38, 0.20, 0.20, 0.80)
	for _sd in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		cls2.set_border_width(_sd, 1); cls2.set_corner_radius(_sd, 6)
	clear_btn.add_theme_stylebox_override("normal", cls2)
	clear_btn.pressed.connect(func():
		if sm: sm.clear_log()
		panel.queue_free(); _settings_panel = null; _show_settings()
	)
	pg_hist.add_child(clear_btn)

	# Высокий контраст — перекрашиваем панель
	if hc:
		var hc_ps := StyleBoxFlat.new()
		hc_ps.bg_color = Color(0.0, 0.0, 0.0, 1.0)
		hc_ps.border_color = Color(1.0, 1.0, 0.0, 1.0)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			hc_ps.set_border_width(side, 3)
			hc_ps.set_corner_radius(side, 12)
		hc_ps.content_margin_left = 20; hc_ps.content_margin_right  = 20
		hc_ps.content_margin_top  = 14; hc_ps.content_margin_bottom = 14
		panel.add_theme_stylebox_override("panel", hc_ps)

	_switch_tab.call("sound")

	# ── Футер: Экспорт / Импорт ───────────────────────────────────────────────
	root_vbox.add_child(HSeparator.new())

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	root_vbox.add_child(footer)

	var _mk_footer_btn := func(text: String, bg: Color, border: Color) -> Button:
		var b := Button.new()
		b.text = text
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 30)
		b.add_theme_font_size_override("font_size", 12)
		var fs2 := StyleBoxFlat.new()
		fs2.bg_color = bg; fs2.border_color = border
		for _sd in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			fs2.set_border_width(_sd, 1); fs2.set_corner_radius(_sd, 6)
		b.add_theme_stylebox_override("normal", fs2)
		var fsh := fs2.duplicate() as StyleBoxFlat
		fsh.bg_color = bg.lightened(0.12)
		b.add_theme_stylebox_override("hover", fsh)
		return b

	var export_btn: Button = _mk_footer_btn.call(
		"📤  Экспорт настроек", Color(0.08, 0.14, 0.08), Color(0.28, 0.55, 0.28, 0.80))
	export_btn.pressed.connect(func(): _export_settings(panel))
	footer.add_child(export_btn)

	var import_btn: Button = _mk_footer_btn.call(
		"📥  Импорт настроек", Color(0.08, 0.10, 0.18), Color(0.28, 0.40, 0.65, 0.80))
	import_btn.pressed.connect(func(): _import_settings(sm, panel))
	footer.add_child(import_btn)

	var _anim_dur: float = 0.22 if (not sm or sm.ui_animations) else 0.0
	var anim := _ui_canvas.create_tween()
	anim.set_parallel(true)
	anim.tween_property(panel, "modulate:a", 1.0, _anim_dur)
	anim.tween_property(panel, "scale", Vector2(1.0, 1.0), _anim_dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _vol_icon(icons: Array, v: float) -> String:
	if v <= 0.001: return icons[0]
	if v < 0.5:    return icons[1]
	return icons[2]

func _add_slider_row(parent: VBoxContainer, initial: float, on_change: Callable, icons: Array, label_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var icon_lbl := Label.new()
	icon_lbl.text = _vol_icon(icons, initial)
	icon_lbl.add_theme_font_size_override("font_size", 16)
	icon_lbl.custom_minimum_size = Vector2(26, 0)
	row.add_child(icon_lbl)

	var name_lbl := Label.new()
	name_lbl.text = label_text
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	name_lbl.custom_minimum_size = Vector2(62, 0)
	row.add_child(name_lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 24)
	var sl_bg := StyleBoxFlat.new()
	sl_bg.bg_color = Color(0.15, 0.15, 0.24)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sl_bg.set_corner_radius(s, 4)
	slider.add_theme_stylebox_override("slider", sl_bg)
	var sl_fill := StyleBoxFlat.new()
	sl_fill.bg_color = Color(0.32, 0.42, 0.78)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sl_fill.set_corner_radius(s, 4)
	slider.add_theme_stylebox_override("grabber_area", sl_fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", sl_fill)
	slider.add_theme_constant_override("grabber_offset", 0)
	slider.value_changed.connect(on_change)
	row.add_child(slider)

	var pct := Label.new()
	pct.text = "%d%%" % int(initial * 100)
	pct.custom_minimum_size = Vector2(38, 0)
	pct.add_theme_font_size_override("font_size", 12)
	pct.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	row.add_child(pct)

	slider.value_changed.connect(func(v: float):
		pct.text = "%d%%" % int(v * 100)
		icon_lbl.text = _vol_icon(icons, v)
	)

func _add_toggle_row(parent: VBoxContainer, label_text: String, initial: bool, on_toggle: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 32)
	btn.add_theme_font_size_override("font_size", 13)
	var _mk := func(on: bool) -> void:
		btn.text = "ВКЛ" if on else "ВЫКЛ"
		var s2 := StyleBoxFlat.new()
		s2.bg_color = Color(0.12, 0.35, 0.12) if on else Color(0.25, 0.12, 0.12)
		s2.border_color = Color(0.30, 0.72, 0.30) if on else Color(0.55, 0.22, 0.22)
		for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			s2.set_border_width(s, 1)
			s2.set_corner_radius(s, 6)
		btn.add_theme_stylebox_override("normal", s2)
		btn.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55) if on else Color(1.0, 0.55, 0.55))
	_mk.call(initial)
	var _state := [initial]
	btn.pressed.connect(func():
		_state[0] = not _state[0]
		_mk.call(_state[0])
		on_toggle.call(_state[0])
	)
	row.add_child(btn)

func _style_fps_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.20, 0.35) if active else Color(0.10, 0.10, 0.16)
	s.border_color = Color(0.40, 0.55, 0.90) if active else Color(0.28, 0.28, 0.40)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_border_width(side, 1 if not active else 2)
		s.set_corner_radius(side, 6)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0) if active else Color(0.55, 0.55, 0.60))

func _style_tab_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.18, 0.18, 0.30) if active else Color(0.08, 0.08, 0.14)
	s.border_color = Color(0.50, 0.55, 0.90) if active else Color(0.25, 0.25, 0.38)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_border_width(side, 2 if active else 1)
		s.set_corner_radius(side, 6)
	btn.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = s.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_color",
		Color(0.90, 0.92, 1.0) if active else Color(0.50, 0.50, 0.65))

func _get_action_key_label(action: String) -> String:
	if not InputMap.has_action(action):
		return "—"
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.keycode)
	return "—"

func _style_key_btn(btn: Button, waiting: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.22, 0.14, 0.04) if waiting else Color(0.10, 0.10, 0.18)
	s.border_color = Color(0.85, 0.55, 0.12) if waiting else Color(0.30, 0.30, 0.48)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_border_width(side, 2 if waiting else 1)
		s.set_corner_radius(side, 5)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color",
		Color(1.0, 0.80, 0.20) if waiting else Color(0.75, 0.85, 1.0))

func _confirm_reset(sm: Node, settings_panel: Panel) -> void:
	# Модальный диалог подтверждения поверх панели настроек
	var dlg := Panel.new()
	dlg.set_anchors_preset(Control.PRESET_CENTER)
	dlg.position = Vector2(-175, -80)
	dlg.size = Vector2(350, 160)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.08, 0.04, 0.04, 0.98)
	ds.border_color = Color(0.65, 0.20, 0.20, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ds.set_border_width(s, 2)
		ds.set_corner_radius(s, 10)
	ds.content_margin_left = 18; ds.content_margin_right = 18
	ds.content_margin_top = 16;  ds.content_margin_bottom = 16
	dlg.add_theme_stylebox_override("panel", ds)
	dlg.modulate.a = 0.0
	_ui_canvas.add_child(dlg)
	dlg.create_tween().tween_property(dlg, "modulate:a", 1.0, 0.18)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	dlg.add_child(vb)

	var L2: Node = get_node_or_null("/root/Localization")
	var msg := Label.new()
	msg.text = L2.t("confirm_reset_msg") if L2 else "Сбросить все настройки\nна значения по умолчанию?"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 14)
	msg.add_theme_color_override("font_color", Color(0.90, 0.80, 0.80))
	vb.add_child(msg)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vb.add_child(btn_row)

	var yes_btn := Button.new()
	yes_btn.text = L2.t("confirm_reset_yes") if L2 else "✓  Сбросить"
	yes_btn.custom_minimum_size = Vector2(130, 36)
	yes_btn.add_theme_font_size_override("font_size", 13)
	yes_btn.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75))
	var ys := StyleBoxFlat.new()
	ys.bg_color = Color(0.30, 0.06, 0.06)
	ys.border_color = Color(0.72, 0.18, 0.18, 0.90)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ys.set_border_width(s, 1)
		ys.set_corner_radius(s, 7)
	yes_btn.add_theme_stylebox_override("normal", ys)
	yes_btn.pressed.connect(func():
		dlg.queue_free()
		if sm:
			sm.reset_to_defaults()
			settings_panel.queue_free()
			_settings_panel = null
			_show_settings()
	)
	btn_row.add_child(yes_btn)
	# Если панель закрыта снаружи (ESC / backdrop) — удаляем диалог тоже
	settings_panel.tree_exiting.connect(func():
		if is_instance_valid(dlg): dlg.queue_free()
	)

	var no_btn := Button.new()
	no_btn.text = L2.t("confirm_reset_no") if L2 else "✕  Отмена"
	no_btn.custom_minimum_size = Vector2(130, 36)
	no_btn.add_theme_font_size_override("font_size", 13)
	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0.12, 0.12, 0.18)
	ns.border_color = Color(0.35, 0.35, 0.50, 0.80)
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ns.set_border_width(s, 1)
		ns.set_corner_radius(s, 7)
	no_btn.add_theme_stylebox_override("normal", ns)
	no_btn.pressed.connect(func(): dlg.queue_free())
	btn_row.add_child(no_btn)

func _copy_file(from_path: String, to_path: String) -> bool:
	var src := FileAccess.open(from_path, FileAccess.READ)
	if not src:
		return false
	var data := src.get_buffer(src.get_length())
	src.close()
	var dst := FileAccess.open(to_path, FileAccess.WRITE)
	if not dst:
		return false
	dst.store_buffer(data)
	dst.close()
	return true

func _show_footer_toast(panel: Panel, text: String, ok: bool) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color",
		Color(0.45, 1.0, 0.45) if ok else Color(1.0, 0.45, 0.45))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.position.y = -36
	lbl.modulate.a = 0.0
	panel.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.20)
	tw.tween_interval(2.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.30)
	tw.tween_callback(lbl.queue_free)

func _export_settings(panel: Panel) -> void:
	var src_path := "user://settings.cfg"
	if not FileAccess.file_exists(src_path):
		_show_footer_toast(panel, "⚠ Нет файла настроек для экспорта", false)
		return

	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		var home: String = OS.get_environment("USERPROFILE") \
			if OS.get_name() == "Windows" else OS.get_environment("HOME")
		DisplayServer.file_dialog_show(
			"Экспорт настроек", home, "settings.cfg", false,
			DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
			PackedStringArray(["*.cfg ; Файл настроек"]),
			func(status: bool, paths: PackedStringArray, _fi: int):
				if status and paths.size() > 0:
					var ok := _copy_file(src_path, paths[0])
					_show_footer_toast(panel,
						"✓ Экспортировано: " + paths[0].get_file() if ok \
						else "⚠ Ошибка при экспорте", ok)
		)
	else:
		# Платформа без нативного диалога — копируем рядом с исполняемым файлом
		var fallback := OS.get_executable_path().get_base_dir().path_join("settings_export.cfg")
		var ok := _copy_file(src_path, fallback)
		_show_footer_toast(panel,
			("✓ Сохранено: settings_export.cfg") if ok else "⚠ Ошибка при экспорте", ok)

func _import_settings(sm: Node, panel: Panel) -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		var home: String = OS.get_environment("USERPROFILE") \
			if OS.get_name() == "Windows" else OS.get_environment("HOME")
		DisplayServer.file_dialog_show(
			"Импорт настроек", home, "", false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
			PackedStringArray(["*.cfg ; Файл настроек"]),
			func(status: bool, paths: PackedStringArray, _fi: int):
				if not status or paths.is_empty():
					return
				var ok := _copy_file(paths[0], "user://settings.cfg")
				if ok and sm:
					sm.load_settings()
					sm._apply_all()
					panel.queue_free()
					_settings_panel = null
					_show_settings()
				else:
					_show_footer_toast(panel, "⚠ Не удалось импортировать файл", false)
		)
	else:
		# Ищем settings_export.cfg рядом с исполняемым
		var fallback := OS.get_executable_path().get_base_dir().path_join("settings_export.cfg")
		if not FileAccess.file_exists(fallback):
			_show_footer_toast(panel,
				"⚠ Поместите settings_export.cfg рядом с игрой", false)
			return
		var ok := _copy_file(fallback, "user://settings.cfg")
		if ok and sm:
			sm.load_settings()
			sm._apply_all()
			panel.queue_free()
			_settings_panel = null
			_show_settings()
		else:
			_show_footer_toast(panel, "⚠ Ошибка при импорте", false)

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
			dlg.confirmed.connect(func(): _start_new(slot))
			dlg.confirmed.connect(dlg.queue_free)
			dlg.canceled.connect(dlg.queue_free)
			dlg.popup_centered()
		elif mode == "new":
			_start_new(slot)
		else:
			_continue_game(slot)

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
