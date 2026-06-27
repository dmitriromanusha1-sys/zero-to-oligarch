extends CanvasLayer
# Экран «Жизнь»: личное измерение — возраст, этап жизни, счастье и настроение.
# Открывается кнопкой 👤 в HUD. Фаза 1 — фундамент; разделы дополняются далее.

var gm
var life
var _panel: PanelContainer
var _vb: VBoxContainer

func _ready() -> void:
	layer = 22
	visible = false
	add_to_group("life_ui")
	gm = get_node_or_null("/root/GameManager")
	life = get_node_or_null("/root/LifeManager")
	_build_shell()
	if life and life.has_signal("life_changed"):
		life.life_changed.connect(func(): if visible: _rebuild())

func _build_shell() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: close())
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.12, 0.98)
	sb.border_color = Color(0.65, 0.55, 0.80, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)

	_vb = VBoxContainer.new()
	_vb.add_theme_constant_override("separation", 6)
	_vb.custom_minimum_size = Vector2(440, 0)
	scroll.add_child(_vb)

func open() -> void:
	if gm == null: gm = get_node_or_null("/root/GameManager")
	if life == null: life = get_node_or_null("/root/LifeManager")
	_rebuild()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.95, 0.95)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false

func _rebuild() -> void:
	for c in _vb.get_children():
		c.queue_free()
	if life == null or gm == null:
		return
	_title("👤 Жизнь")

	var st: Dictionary = life.life_stage()
	_lbl(_vb, "%s  %d лет  ·  %s" % [st.get("icon", "🌱"), life.age(), st.get("name", "")],
		Color(0.86, 0.82, 0.96), 16)
	_lbl(_vb, "До дня рождения: %d дн." % life.days_to_birthday(), Color(0.66, 0.64, 0.76), 11)
	_sep()

	# Счастье
	_header("🙂 Настроение")
	_lbl(_vb, "Счастье: %d%%  ·  %s" % [int(round(life.happiness)), life.mood_label()], life.mood_color(), 14)
	_vb.add_child(_bar(life.happiness / 100.0, life.mood_color()))
	_lbl(_vb, "Стремится к %d%% (статус и здоровье)" % int(round(life.happiness_baseline())), Color(0.64, 0.62, 0.72), 11)
	var pm: float = life.productivity_mult()
	var pcol: Color = Color(0.55, 0.9, 0.6) if pm >= 1.0 else Color(0.95, 0.55, 0.5)
	_lbl(_vb, "Продуктивность работы: ×%.2f" % pm, pcol, 12)
	_sep()

	# Тело и форма
	_header("💪 Тело и форма")
	_lbl(_vb, "Физическая форма: %d%%" % int(round(life.fitness)), Color(0.7, 0.85, 0.95), 12)
	_vb.add_child(_bar(life.fitness / 100.0, Color(0.45, 0.7, 0.95)))
	_lbl(_vb, "Стиль / уход: %d%%" % int(round(life.style)), Color(0.9, 0.8, 0.95), 12)
	_vb.add_child(_bar(life.style / 100.0, Color(0.75, 0.55, 0.9)))
	_lbl(_vb, "Внешность: %d%%" % int(round(life.appearance())), Color(0.95, 0.82, 0.62), 12)
	_vb.add_child(_bar(life.appearance() / 100.0, Color(0.9, 0.7, 0.4)))
	_vb.add_child(_action_card("workout"))
	_vb.add_child(_action_card("groom"))
	_sep()

	# Личные навыки
	_header("🧠 Личные навыки")
	if gm.day <= life._last_dev_day:
		_lbl(_vb, "Сегодня вы уже занимались саморазвитием.", Color(0.64, 0.62, 0.72), 11)
	else:
		_lbl(_vb, "Одно занятие в день · %s" % gm.format_money(life.dev_cost()), Color(0.64, 0.62, 0.72), 11)
	for sk in life.SKILLS:
		_vb.add_child(_skill_card(sk))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_vb.add_child(spacer)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.add_theme_font_size_override("font_size", 16)
	_style(close_btn, Color(0.14, 0.12, 0.18), Color(0.45, 0.4, 0.6))
	close_btn.pressed.connect(close)
	_vb.add_child(close_btn)

func _skill_card(sk: Dictionary) -> PanelContainer:
	var sid: String = sk.id
	var val: float = life.skill(sid)
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.09, 0.13, 0.92)
	cs.border_color = Color(0.42, 0.42, 0.55, 0.65)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var icon := Label.new(); icon.text = sk.get("icon", "🧠")
	icon.add_theme_font_size_override("font_size", 22); icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, "%s — %d%%" % [sk.get("name", "?"), int(round(val))], Color(0.86, 0.86, 0.94), 14)
	col.add_child(_bar(val / 100.0, Color(0.55, 0.6, 0.85)))
	_lbl(col, sk.get("desc", ""), Color(0.64, 0.62, 0.74), 11)
	var btn := Button.new()
	btn.text = sk.get("action", "Развивать")
	btn.add_theme_font_size_override("font_size", 11)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if life.can_train():
		_style(btn, Color(0.16, 0.13, 0.22), Color(0.5, 0.42, 0.68))
		btn.pressed.connect(func(): life.train_skill(sid))
	else:
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

func _action_card(kind: String) -> PanelContainer:
	var titles := {"workout":"🏋 Тренировка", "groom":"💇 Уход за собой"}
	var descs := {
		"workout":"+форма, +здоровье, +настроение · %s" % gm.format_money(life.workout_cost()),
		"groom":"+стиль и внешность · %s" % gm.format_money(life.groom_cost())}
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.10, 0.09, 0.13, 0.92)
	cs.border_color = Color(0.45, 0.40, 0.58, 0.7)
	cs.set_border_width_all(1); cs.set_corner_radius_all(8); cs.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", cs)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 10); card.add_child(row)
	var col := VBoxContainer.new(); col.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(col)
	_lbl(col, titles[kind], Color(0.88, 0.84, 0.96), 14)
	_lbl(col, descs[kind], Color(0.66, 0.64, 0.76), 11)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 12)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ok: bool = life.can_workout() if kind == "workout" else life.can_groom()
	var done_today: bool = (gm.day <= life._last_workout_day) if kind == "workout" else (gm.day <= life._last_groom_day)
	if done_today:
		btn.text = "✅ Сегодня"
		_style(btn, Color(0.12, 0.16, 0.10), Color(0.4, 0.55, 0.3)); btn.disabled = true
	elif ok:
		btn.text = "Сделать"
		_style(btn, Color(0.16, 0.13, 0.22), Color(0.5, 0.42, 0.68))
		if kind == "workout": btn.pressed.connect(func(): life.workout())
		else: btn.pressed.connect(func(): life.groom())
	else:
		btn.text = "Нет денег"
		_style(btn, Color(0.09, 0.09, 0.13), Color(0.26, 0.26, 0.36, 0.55)); btn.disabled = true
	row.add_child(btn)
	return card

# ── helpers ───────────────────────────────────────────────────────────────────
func _bar(frac: float, col: Color) -> Control:
	var pb := ProgressBar.new()
	pb.min_value = 0.0; pb.max_value = 1.0
	pb.value = clampf(frac, 0.0, 1.0)
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 12)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.16, 0.15, 0.20); bg.set_corner_radius_all(5)
	pb.add_theme_stylebox_override("background", bg)
	var fg := StyleBoxFlat.new()
	fg.bg_color = col; fg.set_corner_radius_all(5)
	pb.add_theme_stylebox_override("fill", fg)
	return pb

func _title(t: String) -> void:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color(1, 1, 1))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vb.add_child(l)

func _header(t: String) -> void:
	var s := Control.new(); s.custom_minimum_size = Vector2(0, 4); _vb.add_child(s)
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(0.72, 0.62, 0.92))
	_vb.add_child(l)

func _lbl(parent: Node, t: String, c: Color, sz: int) -> Label:
	var l := Label.new(); l.text = t
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", c)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	return l

func _sep() -> void:
	var line := ColorRect.new()
	line.color = Color(0.35, 0.32, 0.45, 0.5)
	line.custom_minimum_size = Vector2(0, 1)
	_vb.add_child(line)

func _style(b: Button, bg: Color, border: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = border
	sb.set_border_width_all(1); sb.set_corner_radius_all(8); sb.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", sb)
	var hov := sb.duplicate(); hov.bg_color = bg.lightened(0.10)
	b.add_theme_stylebox_override("hover", hov)
	b.add_theme_color_override("font_color", Color(0.92, 0.9, 0.96))
