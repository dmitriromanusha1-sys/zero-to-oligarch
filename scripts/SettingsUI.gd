extends CanvasLayer

var _sm: Node
var _panel: Control
var _list: VBoxContainer

func _ready() -> void:
	layer = 22
	visible = false
	add_to_group("settings_ui")
	_sm = get_node("/root/SettingsManager")
	_build_ui()

func open() -> void:
	_refresh()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale      = Vector2(0.93, 0.93)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.18)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _close() -> void:
	visible = false

# ── Каркас окна ────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.82)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size     = Vector2(560, 640)
	_panel.position = Vector2(-280, -320)
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(0.040, 0.047, 0.100, 0.98)
	ps.border_color = Color(0.22, 0.48, 0.80, 0.90)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(14)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	# ── Шапка ────────────────────────────────────────────────────────────────
	var hdr = PanelContainer.new()
	hdr.position = Vector2(0, 0)
	hdr.size     = Vector2(560, 54)
	var hps = StyleBoxFlat.new()
	hps.bg_color     = Color(0.055, 0.100, 0.210, 1.0)
	hps.border_color = Color(0.22, 0.48, 0.80, 0.50)
	hps.set_border_width(SIDE_BOTTOM, 2)
	hps.set_corner_radius(CORNER_TOP_LEFT,  14)
	hps.set_corner_radius(CORNER_TOP_RIGHT, 14)
	hps.content_margin_left   = 16
	hps.content_margin_right  = 10
	hps.content_margin_top    = 8
	hps.content_margin_bottom = 8
	hdr.add_theme_stylebox_override("panel", hps)
	_panel.add_child(hdr)

	var hdr_row = HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 10)
	hdr.add_child(hdr_row)

	var ico = Label.new()
	ico.text = "⚙"
	ico.add_theme_font_size_override("font_size", 24)
	hdr_row.add_child(ico)

	var t1 = Label.new()
	t1.text = "Настройки"
	t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t1.add_theme_font_size_override("font_size", 18)
	t1.add_theme_color_override("font_color", Color(1.0, 0.90, 0.28))
	hdr_row.add_child(t1)

	var cls = Button.new()
	cls.text = "✖"
	cls.custom_minimum_size = Vector2(36, 36)
	cls.add_theme_font_size_override("font_size", 14)
	cls.add_theme_color_override("font_color", Color.WHITE)
	var cbs = StyleBoxFlat.new()
	cbs.bg_color = Color(0.22, 0.07, 0.07)
	cbs.border_color = Color(0.55, 0.18, 0.18)
	cbs.set_border_width_all(1); cbs.set_corner_radius_all(6)
	cls.add_theme_stylebox_override("normal", cbs)
	var cbh = cbs.duplicate() as StyleBoxFlat
	cbh.bg_color = Color(0.40, 0.10, 0.10)
	cls.add_theme_stylebox_override("hover", cbh)
	cls.pressed.connect(_close)
	hdr_row.add_child(cls)

	# ── Тело (скролл со списком настроек) ─────────────────────────────────────
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(0, 54)
	scroll.size     = Vector2(560, 586)
	_panel.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	var lm = StyleBoxEmpty.new()
	lm.content_margin_left = 16; lm.content_margin_right = 16
	lm.content_margin_top = 12;  lm.content_margin_bottom = 16
	var lwrap = PanelContainer.new()
	lwrap.add_theme_stylebox_override("panel", lm)
	lwrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lwrap.add_child(_list)
	scroll.add_child(lwrap)

func _refresh() -> void:
	for c in _list.get_children(): c.queue_free()

	_section("🔊  Звук")
	_slider_row("Общая громкость", _sm.master_vol, func(v): _sm.set_master_vol(v))
	_slider_row("Музыка",          _sm.music_vol,  func(v): _sm.set_music_vol(v))
	_slider_row("Звуковые эффекты",_sm.sfx_vol,    func(v): _sm.set_sfx_vol(v))

	_section("🖥  Видео")
	_check_row("Полноэкранный режим", _sm.fullscreen, func(on): _sm.set_fullscreen(on))
	_check_row("Вертикальная синхронизация (VSync)", _sm.vsync, func(on): _sm.set_vsync(on))
	_option_row("Лимит FPS", ["30", "60", "120", "∞"], [30, 60, 120, 0], _sm.fps_cap,
		func(v): _sm.set_fps_cap(v))

	_section("🎮  Геймплей")
	_option_row("Сложность", ["Лёгкая", "Обычная", "Хардкор"], ["easy", "normal", "hardcore"], _sm.difficulty,
		func(v): _sm.set_difficulty(v))
	_check_row("Автопауза при открытии меню", _sm.autopause, func(on): _sm.set_autopause(on))

	_section("👁  Доступность")
	_option_row("Размер текста", ["Обычный", "Крупный", "Очень крупный"], ["normal", "large", "xlarge"], _sm.font_size,
		func(v): _sm.set_font_size(v))
	_check_row("Высокий контраст", _sm.high_contrast, func(on): _sm.set_high_contrast(on))
	_check_row("Анимации интерфейса", _sm.ui_animations, func(on): _sm.set_ui_animations(on))

	_section("🔔  Уведомления")
	_check_row("Автосохранение",        _sm.notify_autosave,     func(on): _sm.set_notify("autosave", on))
	_check_row("Случайные события",     _sm.notify_events,       func(on): _sm.set_notify("events", on))
	_check_row("Достижения",            _sm.notify_achievements, func(on): _sm.set_notify("achievements", on))
	_check_row("Налоги",                _sm.notify_taxes,        func(on): _sm.set_notify("taxes", on))
	_check_row("Полиция / события риска", _sm.notify_police,     func(on): _sm.set_notify("police", on))
	_check_row("Подсказки",             _sm.show_hints,           func(on): _sm.set_notify("hints", on))

	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(0.22, 0.22, 0.30, 0.6)
	_list.add_child(sep)

	var reset_btn = Button.new()
	reset_btn.text = "↺  Сбросить настройки по умолчанию"
	reset_btn.custom_minimum_size = Vector2(0, 38)
	reset_btn.add_theme_font_size_override("font_size", 13)
	reset_btn.add_theme_color_override("font_color", Color(1.00, 0.65, 0.55))
	var rbs = StyleBoxFlat.new()
	rbs.bg_color = Color(0.20, 0.07, 0.07); rbs.border_color = Color(0.55, 0.20, 0.18, 0.80)
	rbs.set_border_width_all(1); rbs.set_corner_radius_all(8)
	reset_btn.add_theme_stylebox_override("normal", rbs)
	reset_btn.pressed.connect(func(): _sm.reset_to_defaults(); _refresh())
	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_top", 10)
	top_margin.add_child(reset_btn)
	_list.add_child(top_margin)

# ── Вспомогательные элементы ───────────────────────────────────────────────────
func _section(text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.78, 1.00))
	var m = StyleBoxEmpty.new()
	m.content_margin_top = 14; m.content_margin_bottom = 4
	lbl.add_theme_stylebox_override("normal", m)
	_list.add_child(lbl)

func _row_container() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 28)
	_list.add_child(row)
	return row

func _row_label(row: HBoxContainer, text: String) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.82, 0.84, 0.90))
	row.add_child(lbl)

func _slider_row(label: String, value: float, on_change: Callable) -> void:
	var row = _row_container()
	_row_label(row, label)
	var pct = Label.new()
	pct.text = "%d%%" % int(round(value * 100))
	pct.custom_minimum_size = Vector2(38, 0)
	pct.add_theme_font_size_override("font_size", 11)
	pct.add_theme_color_override("font_color", Color(0.60, 0.85, 1.00))
	var slider = HSlider.new()
	slider.min_value = 0.0; slider.max_value = 1.0; slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(180, 0)
	slider.value_changed.connect(func(v: float):
		pct.text = "%d%%" % int(round(v * 100))
		on_change.call(v))
	row.add_child(slider)
	row.add_child(pct)

func _check_row(label: String, value: bool, on_change: Callable) -> void:
	var row = _row_container()
	_row_label(row, label)
	var cb = CheckBox.new()
	cb.button_pressed = value
	cb.toggled.connect(func(on: bool): on_change.call(on))
	row.add_child(cb)

func _option_row(label: String, labels: Array, values: Array, current, on_change: Callable) -> void:
	var row = _row_container()
	_row_label(row, label)
	var opt = OptionButton.new()
	opt.custom_minimum_size = Vector2(140, 0)
	for i in labels.size():
		opt.add_item(labels[i])
		if values[i] == current:
			opt.select(i)
	opt.item_selected.connect(func(idx: int): on_change.call(values[idx]))
	row.add_child(opt)
