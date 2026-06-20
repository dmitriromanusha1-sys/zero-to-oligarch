extends Node2D

func _ready() -> void:
	var achm = get_node_or_null("/root/AchievementManager")
	if achm: achm.unlock("a34")
	_build()

func _build() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	# --- Фоновое изображение острова ---
	var bg_img := TextureRect.new()
	bg_img.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var img_path := "res://assets/ui/island_finale.png"
	if ResourceLoader.exists(img_path):
		bg_img.texture = load(img_path)
	else:
		# Fallback: тёмно-синий фон
		var fallback := ColorRect.new()
		fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
		fallback.color = Color(0.03, 0.10, 0.22)
		canvas.add_child(fallback)
	canvas.add_child(bg_img)

	# Затемнение поверх картинки для читаемости текста
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	canvas.add_child(overlay)

	# --- Блики на воде (горизонтальные полосы внизу) ---
	for i in 6:
		var glint := ColorRect.new()
		glint.color = Color(1.0, 0.88, 0.45, 0.07 + i * 0.012)
		glint.size = Vector2(randf_range(120, 340), 3)
		glint.position = Vector2(randf_range(0, 900), 580 + i * 30)
		canvas.add_child(glint)
		var gtw := create_tween().set_loops()
		gtw.tween_property(glint, "modulate:a", 0.15, randf_range(1.2, 2.8)).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		gtw.tween_property(glint, "modulate:a", 0.55, randf_range(1.2, 2.8)).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# --- Частицы (золотые искры) ---
	for _i in 28:
		_spawn_spark(canvas)

	# --- Панель статистики (центр экрана) ---
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(680, 480)
	panel.position = Vector2(-340, -280)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.02, 0.05, 0.12, 0.88)
	ps.border_color = Color(0.75, 0.58, 0.08, 0.95)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 14)
	panel.add_theme_stylebox_override("panel", ps)
	panel.clip_contents = true
	canvas.add_child(panel)

	# Анимация входа панели
	panel.modulate.a = 0.0
	panel.position.y += 60
	var etw := create_tween()
	etw.set_parallel(true)
	etw.tween_property(panel, "modulate:a", 1.0, 0.70)
	etw.tween_property(panel, "position:y", panel.position.y - 60, 0.70).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 7)
	vbox.offset_left   = 28
	vbox.offset_top    = 22
	vbox.offset_right  = -28
	vbox.offset_bottom = -22
	panel.add_child(vbox)

	# Иконка и заголовок
	var icon_lbl := Label.new()
	icon_lbl.text = "🏝"
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 52)
	vbox.add_child(icon_lbl)
	var itw := create_tween().set_loops()
	itw.tween_property(icon_lbl, "position:y", icon_lbl.position.y - 8, 1.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	itw.tween_property(icon_lbl, "position:y", icon_lbl.position.y,      1.6).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	var ttl := Label.new()
	ttl.text = "ТЫ ДОСТИГ ВЕРШИНЫ!"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_size_override("font_size", 30)
	ttl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.0))
	ttl.add_theme_constant_override("outline_size", 3)
	ttl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	vbox.add_child(ttl)

	_add_label(vbox, "Путь от бомжа до олигарха пройден. Добро пожаловать на остров.", 13, Color(0.80, 0.88, 1.0))
	_sep(vbox)

	var gm := get_node_or_null("/root/GameManager")
	if gm:
		_stat(vbox, "💰", "Наличные",      gm.format_money(gm.money),            Color(0.60, 1.0, 0.50))
		_stat(vbox, "📊", "Чистые активы", gm.format_money(gm.get_net_worth()),   Color(0.40, 1.0, 0.70))
		_stat(vbox, "📅", "Дней в игре",   str(gm.day),                           Color(0.80, 0.80, 0.95))
		_stat(vbox, "🏠", "Жильё",         gm.get_housing(),                      Color(0.80, 0.80, 0.95))
		_stat(vbox, "🏅", "Титул",         gm.get_title(),                        Color(1.0, 0.85, 0.25))

	var em := get_node_or_null("/root/EducationManager")
	if em:
		_stat(vbox, em.get_level_icon(), "Образование", em.get_level_name(), Color(0.50, 0.85, 1.0))

	var zm := get_node_or_null("/root/ZoneManager")
	if zm:
		_stat(vbox, "🗺", "Зон пройдено", str(zm.max_zone_reached + 1) + " из " + str(zm.ZONE_META.size()), Color(0.80, 0.80, 0.95))

	_sep(vbox)
	_add_label(vbox, "«Россия — страна возможностей. Ты это доказал.»", 11, Color(0.45, 0.50, 0.62))
	_spacer(vbox, 8)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	vbox.add_child(btn_row)

	var menu_btn := _make_btn("🏠 В главное меню", Color(0.10, 0.22, 0.46), Color(0.28, 0.50, 0.88))
	menu_btn.pressed.connect(func():
		if gm:
			var lb: Node = get_node_or_null("/root/LeaderboardManager")
			if lb: lb.try_add_entry()
			gm.save_game()
		SceneTransition.go("res://scenes/MainMenu.tscn")
	)
	btn_row.add_child(menu_btn)

	var new_btn := _make_btn("🔄 Новая игра", Color(0.06, 0.25, 0.10), Color(0.22, 0.62, 0.30))
	new_btn.pressed.connect(func():
		var lb2: Node = get_node_or_null("/root/LeaderboardManager")
		if lb2: lb2.try_add_entry()
		if gm: gm.reset_game()
		SceneTransition.go("res://scenes/World.tscn")
	)
	btn_row.add_child(new_btn)

	# --- Титры (снизу, появляются с задержкой) ---
	_build_credits(canvas)

# ─── Золотая искра ─────────────────────────────────────────────────────────
func _spawn_spark(parent: Node) -> void:
	var spark := Label.new()
	spark.text = ["✦", "★", "·", "✧", "✶"][randi() % 5]
	spark.add_theme_font_size_override("font_size", randi_range(8, 20))
	spark.add_theme_color_override("font_color", Color(1.0, randf_range(0.72, 1.0), 0.2, 0.0))
	spark.position = Vector2(randf_range(30, 1250), randf_range(30, 680))
	parent.add_child(spark)
	var stw := create_tween().set_loops()
	var delay: float = randf_range(0.0, 4.0)
	stw.tween_interval(delay)
	stw.tween_property(spark, "modulate:a", 1.0,  randf_range(0.6, 1.6)).set_ease(Tween.EASE_OUT)
	stw.tween_property(spark, "modulate:a", 0.0,  randf_range(0.6, 1.6)).set_ease(Tween.EASE_IN)
	stw.tween_interval(randf_range(0.5, 2.0))

# ─── Титры ─────────────────────────────────────────────────────────────────
func _build_credits(canvas: Node) -> void:
	var credits_lines := [
		["ПРОЕКТ РАЗРАБОТАН КОМАНДОЙ", 13, Color(0.55, 0.60, 0.75)],
		["ASPECT", 28, Color(1.0, 0.85, 0.10)],
		["", 8, Color.TRANSPARENT],
		["Разработчик", 12, Color(0.55, 0.60, 0.75)],
		["Романуша Д.С.", 20, Color(0.90, 0.90, 1.0)],
		["", 8, Color.TRANSPARENT],
		["Спасибо, что играете в наши игры ❤", 14, Color(0.75, 0.50, 0.80)],
	]

	# Полоса снизу
	var credits_bg := ColorRect.new()
	credits_bg.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	credits_bg.size.y = 160
	credits_bg.position.y = -160
	credits_bg.color = Color(0.0, 0.0, 0.0, 0.0)
	canvas.add_child(credits_bg)

	# Плавно проявляется через 1.5с
	var c_tween := create_tween()
	c_tween.tween_interval(1.5)
	c_tween.tween_property(credits_bg, "color", Color(0.0, 0.0, 0.0, 0.72), 0.8)

	var credits_vbox := VBoxContainer.new()
	credits_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	credits_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	credits_vbox.add_theme_constant_override("separation", 2)
	credits_bg.add_child(credits_vbox)

	for line_data in credits_lines:
		var lbl := Label.new()
		lbl.text = line_data[0]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", line_data[1])
		lbl.add_theme_color_override("font_color", line_data[2])
		if str(line_data[0]) in ["ASPECT", "Романуша Д.С."]:
			lbl.add_theme_constant_override("outline_size", 2)
			lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		lbl.modulate.a = 0.0
		credits_vbox.add_child(lbl)

	# Строки появляются одна за другой
	var delay: float = 2.0
	for child in credits_vbox.get_children():
		var ltw := create_tween()
		ltw.tween_interval(delay)
		ltw.tween_property(child, "modulate:a", 1.0, 0.55).set_ease(Tween.EASE_OUT)
		delay += 0.22

	# Золотая линия над титрами
	var gold_line := ColorRect.new()
	gold_line.color = Color(0.75, 0.58, 0.08, 0.0)
	gold_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	gold_line.size.y = 2
	gold_line.position.y = 0
	credits_bg.add_child(gold_line)
	var gltw := create_tween()
	gltw.tween_interval(1.4)
	gltw.tween_property(gold_line, "color:a", 0.85, 0.6)

# ─── Хелперы ───────────────────────────────────────────────────────────────
func _stat(parent: Control, icon: String, label: String, value: String, col: Color) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)

	var ico := Label.new()
	ico.text = icon
	ico.add_theme_font_size_override("font_size", 15)
	row.add_child(ico)

	var lbl := Label.new()
	lbl.text = label + ":"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.60, 0.62, 0.72))
	lbl.custom_minimum_size.x = 130
	row.add_child(lbl)

	var val := Label.new()
	val.text = value
	val.add_theme_font_size_override("font_size", 14)
	val.add_theme_color_override("font_color", col)
	val.add_theme_constant_override("outline_size", 1)
	val.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	row.add_child(val)

func _add_label(parent: Control, text: String, size: int, col: Color = Color.WHITE) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", col)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	parent.add_child(lbl)

func _sep(parent: Control) -> void:
	var s := ColorRect.new()
	s.custom_minimum_size = Vector2(0, 2)
	s.color = Color(0.60, 0.45, 0.08, 0.60)
	parent.add_child(s)

func _spacer(parent: Control, h: int) -> void:
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, h)
	parent.add_child(sp)

func _make_btn(text: String, bg: Color, border: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(210, 48)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var sn := StyleBoxFlat.new()
	sn.bg_color = bg
	sn.border_color = border
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sn.set_border_width(s, 2)
		sn.set_corner_radius(s, 10)
	btn.add_theme_stylebox_override("normal", sn)
	var sh := sn.duplicate() as StyleBoxFlat
	sh.bg_color = bg.lightened(0.18)
	sh.border_color = border.lightened(0.20)
	btn.add_theme_stylebox_override("hover", sh)
	var sp2 := sn.duplicate() as StyleBoxFlat
	sp2.bg_color = bg.darkened(0.12)
	btn.add_theme_stylebox_override("pressed", sp2)
	return btn
