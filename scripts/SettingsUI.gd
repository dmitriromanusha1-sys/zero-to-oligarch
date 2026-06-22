extends CanvasLayer

# Профессиональное окно настроек: боковая навигация категорий, переключатели-
# свитчи, сегментированные выборы, перепривязка клавиш, профили, экспорт/импорт.
# Единый стиль «люкс тёмный + золото» (UITheme). Используется в меню и в игре.

var _sm: Node
var _L: Node

var _dimmer: ColorRect
var _panel: Panel
var _root: VBoxContainer
var _content_host: Control
var _nav_box: VBoxContainer
var _active_tab: String = "sound"
var _pages: Dictionary = {}
var _nav_btns: Dictionary = {}

# Перепривязка клавиш
var _rebinding: bool = false
var _rebind_action: String = ""
var _rebind_btn: Button = null

const NAV: Array = [
	{"id": "sound",    "icon": "🔊", "label": "Звук"},
	{"id": "screen",   "icon": "🖥", "label": "Экран"},
	{"id": "gameplay", "icon": "🎮", "label": "Игра"},
	{"id": "access",   "icon": "♿", "label": "Доступность"},
	{"id": "controls", "icon": "⌨", "label": "Управление"},
	{"id": "history",  "icon": "📋", "label": "История"},
]

func _ready() -> void:
	layer = 22
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group("settings_ui")
	_sm = get_node_or_null("/root/SettingsManager")
	_L = get_node_or_null("/root/Localization")

func open() -> void:
	_ensure_built()
	_rebuild_content()
	visible = true
	var dur: float = 0.20 if (not _sm or _sm.ui_animations) else 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.94, 0.94)
	_dimmer.color.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dimmer, "color:a", 0.66, dur)
	tw.tween_property(_panel, "modulate:a", 1.0, dur)
	tw.tween_property(_panel, "scale", Vector2(1.0, 1.0), dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _close() -> void:
	_rebinding = false
	visible = false

func _t(key: String, fallback: String) -> String:
	return _L.t(key) if _L else fallback

# ── Каркас (строится один раз) ────────────────────────────────────────────────
func _ensure_built() -> void:
	if _panel != null and is_instance_valid(_panel):
		return
	_dimmer = ColorRect.new()
	_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dimmer.color = Color(0.02, 0.03, 0.06, 0.66)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_dimmer.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close())
	add_child(_dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(780, 584)
	_panel.position = Vector2(-390, -292)
	add_child(_panel)

	_root = VBoxContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.offset_left = 22; _root.offset_right = -22
	_root.offset_top = 18; _root.offset_bottom = -18
	_root.add_theme_constant_override("separation", 11)
	_panel.add_child(_root)

func _apply_panel_style(hc: bool) -> void:
	if hc:
		var ps := StyleBoxFlat.new()
		ps.bg_color = Color(0.0, 0.0, 0.0, 1.0)
		ps.border_color = Color(1.0, 1.0, 0.0, 1.0)
		ps.set_border_width_all(3)
		ps.set_corner_radius_all(14)
		_panel.add_theme_stylebox_override("panel", ps)
	else:
		_panel.add_theme_stylebox_override("panel", UITheme.panel_box())

# ── Полная пересборка содержимого ─────────────────────────────────────────────
func _rebuild_content() -> void:
	for c in _root.get_children():
		c.queue_free()
	_pages.clear()
	_nav_btns.clear()
	var hc: bool = _sm.high_contrast if _sm else false
	_apply_panel_style(hc)

	# ── Заголовок ──
	var hdr := HBoxContainer.new()
	_root.add_child(hdr)
	var ttl := Label.new()
	ttl.text = _t("settings_title", "⚙  Настройки")
	ttl.add_theme_font_override("font", UITheme.display_font())
	ttl.add_theme_font_size_override("font_size", 22)
	ttl.add_theme_color_override("font_color", UITheme.GOLD)
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr.add_child(ttl)
	_build_profiles(hdr)
	var cls := Button.new()
	cls.text = "✕"; cls.custom_minimum_size = Vector2(36, 36)
	cls.add_theme_font_size_override("font_size", 15)
	UITheme.style_button(cls, "danger")
	cls.pressed.connect(_close)
	hdr.add_child(cls)

	_root.add_child(UITheme.gold_rule())

	# ── Тело: боковая навигация + контент ──
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	_root.add_child(body)

	_nav_box = VBoxContainer.new()
	_nav_box.custom_minimum_size = Vector2(186, 0)
	_nav_box.add_theme_constant_override("separation", 5)
	body.add_child(_nav_box)

	var content_card := PanelContainer.new()
	content_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_card.add_theme_stylebox_override("panel", UITheme.card_box(true))
	body.add_child(content_card)

	_content_host = Control.new()
	_content_host.clip_contents = true
	content_card.add_child(_content_host)

	# Страницы (одна видима за раз)
	for nd in NAV:
		var scroll := ScrollContainer.new()
		scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.visible = false
		_content_host.add_child(scroll)
		var pg := VBoxContainer.new()
		pg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pg.add_theme_constant_override("separation", 9)
		scroll.add_child(pg)
		_pages[nd.id] = pg
		_pages[nd.id + "_scroll"] = scroll

	# Навигация
	for nd in NAV:
		var nid: String = nd.id
		var nb := Button.new()
		nb.text = "  %s   %s" % [nd.icon, nd.label]
		nb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nb.custom_minimum_size = Vector2(0, 40)
		nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nb.add_theme_font_size_override("font_size", 14)
		nb.pressed.connect(func(): _switch_tab(nid))
		_nav_box.add_child(nb)
		_nav_btns[nid] = nb

	_build_sound(_pages["sound"])
	_build_screen(_pages["screen"])
	_build_gameplay(_pages["gameplay"])
	_build_access(_pages["access"])
	_build_controls(_pages["controls"])
	_build_history(_pages["history"])

	_root.add_child(UITheme.gold_rule())

	# ── Футер: сброс / экспорт / импорт ──
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	_root.add_child(footer)
	var reset_btn := _footer_btn("↺  " + _t("reset_settings", "Сбросить"), "danger")
	reset_btn.pressed.connect(_confirm_reset)
	footer.add_child(reset_btn)
	var exp_btn := _footer_btn("📤  " + _t("export", "Экспорт"), "primary")
	exp_btn.pressed.connect(_export_settings)
	footer.add_child(exp_btn)
	var imp_btn := _footer_btn("📥  " + _t("import", "Импорт"), "ghost")
	imp_btn.pressed.connect(_import_settings)
	footer.add_child(imp_btn)

	if not _pages.has(_active_tab):
		_active_tab = "sound"
	_switch_tab(_active_tab)

func _switch_tab(tab_id: String) -> void:
	_active_tab = tab_id
	for nd in NAV:
		_pages[nd.id + "_scroll"].visible = (nd.id == tab_id)
		_style_nav_btn(_nav_btns[nd.id], nd.id == tab_id)

# ── Профили (компактно в шапке) ──────────────────────────────────────────────
func _build_profiles(parent: HBoxContainer) -> void:
	var wrap := HBoxContainer.new()
	wrap.add_theme_constant_override("separation", 5)
	parent.add_child(wrap)
	for pi in 3:
		var filled: bool = _sm and _sm.profile_filled(pi)
		var pslot: int = pi
		var save_btn := Button.new()
		save_btn.text = "💾%d" % (pi + 1)
		save_btn.tooltip_text = "Сохранить профиль %d" % (pi + 1)
		save_btn.custom_minimum_size = Vector2(40, 30)
		save_btn.add_theme_font_size_override("font_size", 12)
		UITheme.style_button(save_btn, "ghost")
		save_btn.pressed.connect(func():
			if _sm: _sm.save_profile(pslot)
			_rebuild_content())
		wrap.add_child(save_btn)
		var load_btn := Button.new()
		load_btn.text = "▶%d" % (pi + 1)
		load_btn.tooltip_text = "Загрузить профиль %d" % (pi + 1)
		load_btn.custom_minimum_size = Vector2(40, 30)
		load_btn.add_theme_font_size_override("font_size", 11)
		load_btn.disabled = not filled
		UITheme.style_button(load_btn, "primary" if filled else "ghost")
		load_btn.pressed.connect(func():
			if _sm and _sm.profile_filled(pslot):
				_sm.load_profile(pslot)
				_rebuild_content())
		wrap.add_child(load_btn)

# ── Страница: Звук ────────────────────────────────────────────────────────────
func _build_sound(pg: VBoxContainer) -> void:
	_section(pg, _t("volume_section", "ГРОМКОСТЬ"))
	_slider_row(pg, _t("master", "Мастер"), _sm.master_vol if _sm else 1.0, ["🔇", "🔈", "🔊"],
		func(v): if _sm: _sm.set_master_vol(v))
	_slider_row(pg, _t("music", "Музыка"), _sm.music_vol if _sm else 1.0, ["🔇", "🎵", "🎵"],
		func(v): if _sm: _sm.set_music_vol(v))
	_slider_row(pg, _t("sounds", "Звуки"), _sm.sfx_vol if _sm else 1.0, ["🔇", "🔈", "🔊"],
		func(v): if _sm: _sm.set_sfx_vol(v))
	_section(pg, _t("fps_section", "ОГРАНИЧЕНИЕ FPS"))
	var fps_row := _row(pg, "Лимит кадров", "Меньше нагрузка и нагрев на слабом железе")
	_segmented(fps_row, [30, 60, 120, 0], ["30", "60", "120", "∞"], _sm.fps_cap if _sm else 60,
		func(v): if _sm: _sm.set_fps_cap(v))

# ── Страница: Экран ───────────────────────────────────────────────────────────
func _build_screen(pg: VBoxContainer) -> void:
	_section(pg, _t("window_mode", "РЕЖИМ ОКНА"))
	_switch_row(pg, _t("fullscreen", "Полный экран"), "Растянуть игру на весь экран",
		_sm and _sm.fullscreen, func(on): if _sm: _sm.set_fullscreen(on))
	_switch_row(pg, _t("vsync", "Вертикальная синхронизация"), "Убирает разрывы кадра",
		_sm.vsync if _sm else true, func(on): if _sm: _sm.set_vsync(on))
	_section(pg, _t("resolution", "РАЗРЕШЕНИЕ ОКНА"))
	var res_row := _row(pg, "Размер окна", "Только в оконном режиме")
	var RES: Array = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
	var RES_L: Array = ["1280×720", "1600×900", "1920×1080"]
	_segmented(res_row, RES, RES_L, DisplayServer.window_get_size(),
		func(v):
			if _sm and _sm.fullscreen: return
			DisplayServer.window_set_size(v)
			DisplayServer.window_set_position(DisplayServer.screen_get_size() / 2 - v / 2))
	_section(pg, _t("language_section", "ЯЗЫК ИНТЕРФЕЙСА"))
	var lang_row := _row(pg, "Язык", "")
	_segmented(lang_row, ["ru", "en"], ["🇷🇺 Русский", "🇬🇧 English"], _L.locale if _L else "ru",
		func(v):
			if _sm: _sm.set_locale(v)
			_rebuild_content())

# ── Страница: Игра ────────────────────────────────────────────────────────────
func _build_gameplay(pg: VBoxContainer) -> void:
	_section(pg, _t("difficulty_section", "СЛОЖНОСТЬ"))
	var DIFFS: Array = [
		{"id": "easy",     "label": "🌱 Лёгкая",     "desc": "Штрафы/налоги ×0.5. При истощении максимум 75. Старт весной."},
		{"id": "normal",   "label": "⚖ Нормальная",  "desc": "Стандартный баланс. При истощении максимум 50. Старт летом."},
		{"id": "hard",     "label": "🔥 Тяжёлая",     "desc": "Штрафы/налоги ×1.25. При истощении максимум 25. Старт осенью."},
		{"id": "hardcore", "label": "💀 Хардкор",     "desc": "Штрафы/налоги ×1.5. При 0 здоровья — смерть. Старт зимой."},
	]
	var cur_diff: String = _sm.difficulty if _sm else "normal"
	var cards: Array = []
	for dd in DIFFS:
		var did: String = dd.id
		var card := Button.new()
		card.custom_minimum_size = Vector2(0, 54)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.toggle_mode = false
		card.clip_text = true
		card.add_theme_font_size_override("font_size", 1)
		pg.add_child(card)
		var ci := HBoxContainer.new()
		ci.set_anchors_preset(Control.PRESET_FULL_RECT)
		ci.offset_left = 12; ci.offset_right = -12
		ci.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(ci)
		var tcol := VBoxContainer.new()
		tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tcol.alignment = BoxContainer.ALIGNMENT_CENTER
		tcol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ci.add_child(tcol)
		var dn := Label.new(); dn.text = dd.label
		dn.add_theme_font_size_override("font_size", 15)
		tcol.add_child(dn)
		var de := Label.new(); de.text = dd.desc
		de.add_theme_font_size_override("font_size", 11)
		de.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		tcol.add_child(de)
		var mark := Label.new(); mark.add_theme_font_size_override("font_size", 16)
		mark.custom_minimum_size = Vector2(28, 0)
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ci.add_child(mark)
		cards.append({"btn": card, "id": did, "name": dn, "mark": mark})
		card.pressed.connect(func():
			if _sm: _sm.set_difficulty(did)
			_style_diff_cards(cards, did))
	_style_diff_cards(cards, cur_diff)

	_section(pg, _t("speed_section", "СКОРОСТЬ ВРЕМЕНИ ПО УМОЛЧАНИЮ"))
	var sp_row := _row(pg, "Темп времени", "С какой скоростью идёт игровое время на старте")
	_segmented(sp_row, [1.0, 2.0, 3.0], ["×1", "×2", "×3"], _sm.default_speed if _sm else 1.0,
		func(v): if _sm: _sm.set_default_speed(v))

	_section(pg, _t("autopause_section", "ПРОЧЕЕ"))
	_switch_row(pg, "Пауза при открытии меню", "Останавливать время, пока открыто меню",
		_sm.autopause if _sm else true, func(on): if _sm: _sm.set_autopause(on))

	_section(pg, "УВЕДОМЛЕНИЯ")
	var NOTIFS: Array = [
		{"key": "autosave",     "label": "💾  Автосохранение", "val": _sm.notify_autosave if _sm else true},
		{"key": "events",       "label": "📰  Случайные события", "val": _sm.notify_events if _sm else true},
		{"key": "achievements", "label": "🏆  Достижения", "val": _sm.notify_achievements if _sm else true},
		{"key": "taxes",        "label": "📋  Налоги", "val": _sm.notify_taxes if _sm else true},
		{"key": "police",       "label": "👮  Полиция", "val": _sm.notify_police if _sm else true},
		{"key": "hints",        "label": "💡  Подсказки", "val": _sm.show_hints if _sm else true},
	]
	for nd in NOTIFS:
		var nkey: String = nd.key
		_switch_row(pg, nd.label, "", nd.val, func(on): if _sm: _sm.set_notify(nkey, on))

# ── Страница: Доступность ─────────────────────────────────────────────────────
func _build_access(pg: VBoxContainer) -> void:
	var hc: bool = _sm.high_contrast if _sm else false
	_section(pg, _t("font_size_section", "РАЗМЕР ТЕКСТА"))
	var fs_row := _row(pg, "Шрифт интерфейса", "Крупнее — легче читать")
	_segmented(fs_row, ["normal", "large", "xlarge"], ["Обычный", "Крупный", "Очень крупный"],
		_sm.font_size if _sm else "normal",
		func(v):
			if _sm: _sm.set_font_size(v)
			_rebuild_content())
	_section(pg, _t("contrast_section", "КОНТРАСТ"))
	_switch_row(pg, "Высокий контраст", "Чёрный фон и яркие рамки для слабого зрения",
		hc, func(on):
			if _sm: _sm.set_high_contrast(on)
			_rebuild_content())
	_section(pg, _t("anim_section", "АНИМАЦИИ"))
	_switch_row(pg, "Анимации интерфейса", "Плавные появления окон и эффекты",
		_sm.ui_animations if _sm else true, func(on): if _sm: _sm.set_ui_animations(on))

# ── Страница: Управление ──────────────────────────────────────────────────────
func _build_controls(pg: VBoxContainer) -> void:
	_section(pg, _t("keybinds", "ГОРЯЧИЕ КЛАВИШИ"))
	var ACTIONS: Array = [
		{"action": "move_up", "label": "Вверх"},
		{"action": "move_down", "label": "Вниз"},
		{"action": "move_left", "label": "Влево"},
		{"action": "move_right", "label": "Вправо"},
		{"action": "interact", "label": "Взаимодействие"},
		{"action": "ui_cancel", "label": "Пауза / Закрыть"},
		{"action": "sleep", "label": "Сон"},
	]
	for ad in ACTIONS:
		var row := _row(pg, ad.label, "")
		var key_btn := Button.new()
		key_btn.custom_minimum_size = Vector2(140, 32)
		key_btn.add_theme_font_size_override("font_size", 12)
		key_btn.text = _get_action_key_label(ad.action)
		_style_key_btn(key_btn, false)
		var action_name: String = ad.action
		key_btn.pressed.connect(func():
			if _rebinding: return
			_rebinding = true
			if _rebind_btn and is_instance_valid(_rebind_btn):
				_style_key_btn(_rebind_btn, false)
				_rebind_btn.text = _get_action_key_label(_rebind_action)
			_rebind_action = action_name
			_rebind_btn = key_btn
			key_btn.text = "[ нажми клавишу ]"
			_style_key_btn(key_btn, true))
		row.add_child(key_btn)
	var hint := Label.new()
	hint.text = "Нажми кнопку клавиши → затем нужную клавишу (Esc — отмена)"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", UITheme.TEXT_DIM)
	pg.add_child(hint)

# ── Страница: История ─────────────────────────────────────────────────────────
func _build_history(pg: VBoxContainer) -> void:
	_section(pg, "ЖУРНАЛ ИЗМЕНЕНИЙ")
	var log_entries: Array = _sm.change_log if _sm else []
	if log_entries.is_empty():
		var empty := Label.new()
		empty.text = "Изменений пока нет.\nОткрой настройки и что-нибудь измени."
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pg.add_child(empty)
	else:
		for i in log_entries.size():
			var row := PanelContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var rstyle := StyleBoxFlat.new()
			rstyle.bg_color = Color(0.10, 0.12, 0.18, 0.6) if i % 2 == 0 else Color(0.07, 0.08, 0.13, 0.5)
			rstyle.set_corner_radius_all(6)
			rstyle.content_margin_left = 10; rstyle.content_margin_right = 10
			rstyle.content_margin_top = 5; rstyle.content_margin_bottom = 5
			row.add_theme_stylebox_override("panel", rstyle)
			pg.add_child(row)
			var rl := Label.new()
			rl.text = log_entries[i]
			rl.add_theme_font_size_override("font_size", 12)
			rl.add_theme_color_override("font_color", UITheme.GOLD if i == 0 else UITheme.TEXT_DIM)
			row.add_child(rl)
	var clear_btn := Button.new()
	clear_btn.text = "🗑  Очистить журнал"
	clear_btn.custom_minimum_size = Vector2(0, 32)
	clear_btn.add_theme_font_size_override("font_size", 12)
	UITheme.style_button(clear_btn, "danger")
	clear_btn.pressed.connect(func():
		if _sm: _sm.clear_log()
		_rebuild_content())
	pg.add_child(clear_btn)

# ── Перехват клавиши для перепривязки ─────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _rebinding and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _rebind_btn and is_instance_valid(_rebind_btn):
				_rebind_btn.text = _get_action_key_label(_rebind_action)
				_style_key_btn(_rebind_btn, false)
			_rebinding = false
			get_viewport().set_input_as_handled()
			return
		InputMap.action_erase_events(_rebind_action)
		var ev := InputEventKey.new()
		ev.keycode = event.keycode
		InputMap.action_add_event(_rebind_action, ev)
		if _rebind_btn and is_instance_valid(_rebind_btn):
			_rebind_btn.text = _get_action_key_label(_rebind_action)
			_style_key_btn(_rebind_btn, false)
		_rebinding = false
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

# ── Строки и контролы ─────────────────────────────────────────────────────────
func _section(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", UITheme.GOLD_DIM)
	parent.add_child(lbl)

# Строка настройки: слева подпись (+описание), контрол добавляет вызывающий справа.
func _row(parent: VBoxContainer, label_text: String, desc: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 1)
	row.add_child(col)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", UITheme.TEXT)
	col.add_child(lbl)
	if desc != "":
		var dl := Label.new()
		dl.text = desc
		dl.add_theme_font_size_override("font_size", 11)
		dl.add_theme_color_override("font_color", UITheme.TEXT_DIM)
		col.add_child(dl)
	return row

func _switch_row(parent: VBoxContainer, label_text: String, desc: String, initial: bool, on_toggle: Callable) -> void:
	var row := _row(parent, label_text, desc)
	row.add_child(_make_switch(initial, on_toggle))

# Переключатель-свитч (дорожка + бегунок)
func _make_switch(initial: bool, on_toggle: Callable) -> Control:
	var sw := Button.new()
	sw.custom_minimum_size = Vector2(48, 26)
	sw.flat = true
	sw.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	sw.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	sw.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	sw.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var track := Panel.new()
	track.set_anchors_preset(Control.PRESET_FULL_RECT)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sw.add_child(track)
	var knob := Panel.new()
	knob.size = Vector2(20, 20)
	knob.position = Vector2(3, 3)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sw.add_child(knob)
	var state := [initial]
	var refresh := func() -> void:
		var on: bool = state[0]
		var ts := StyleBoxFlat.new()
		ts.bg_color = UITheme.GOLD_DIM if on else Color(0.17, 0.19, 0.27)
		ts.border_color = UITheme.GOLD if on else Color(0.30, 0.32, 0.42)
		ts.set_border_width_all(1)
		ts.set_corner_radius_all(13)
		track.add_theme_stylebox_override("panel", ts)
		var ks := StyleBoxFlat.new()
		ks.bg_color = UITheme.GOLD if on else Color(0.55, 0.58, 0.66)
		ks.set_corner_radius_all(10)
		knob.add_theme_stylebox_override("panel", ks)
		knob.position.x = 25.0 if on else 3.0
	refresh.call()
	sw.pressed.connect(func():
		state[0] = not state[0]
		refresh.call()
		on_toggle.call(state[0]))
	return sw

func _slider_row(parent: VBoxContainer, label_text: String, initial: float, icons: Array, on_change: Callable) -> void:
	var row := _row(parent, label_text, "")
	var icon_lbl := Label.new()
	icon_lbl.text = _vol_icon(icons, initial)
	icon_lbl.add_theme_font_size_override("font_size", 15)
	icon_lbl.custom_minimum_size = Vector2(24, 0)
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon_lbl)
	var slider := HSlider.new()
	slider.min_value = 0.0; slider.max_value = 1.0; slider.step = 0.05
	slider.value = initial
	slider.custom_minimum_size = Vector2(220, 26)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sl_bg := StyleBoxFlat.new()
	sl_bg.bg_color = Color(0.14, 0.16, 0.22); sl_bg.set_corner_radius_all(4)
	sl_bg.content_margin_top = 4; sl_bg.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", sl_bg)
	var sl_fill := StyleBoxFlat.new()
	sl_fill.bg_color = UITheme.GOLD_DIM; sl_fill.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("grabber_area", sl_fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", sl_fill)
	row.add_child(slider)
	var pct := Label.new()
	pct.text = "%d%%" % int(initial * 100)
	pct.custom_minimum_size = Vector2(42, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pct.add_theme_font_size_override("font_size", 12)
	pct.add_theme_color_override("font_color", UITheme.GOLD)
	row.add_child(pct)
	slider.value_changed.connect(func(v: float):
		pct.text = "%d%%" % int(v * 100)
		icon_lbl.text = _vol_icon(icons, v)
		on_change.call(v))

func _vol_icon(icons: Array, v: float) -> String:
	if v <= 0.001: return icons[0]
	if v < 0.5: return icons[1]
	return icons[2]

# Сегментированный выбор (соединённые кнопки, активная — золотая)
func _segmented(row: HBoxContainer, values: Array, labels: Array, current, on_change: Callable) -> void:
	var seg := HBoxContainer.new()
	seg.add_theme_constant_override("separation", 4)
	seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(seg)
	var btns: Array = []
	for i in values.size():
		var b := Button.new()
		b.text = str(labels[i])
		b.custom_minimum_size = Vector2(0, 32)
		b.add_theme_font_size_override("font_size", 13)
		var v = values[i]
		b.pressed.connect(func():
			on_change.call(v)
			for j in btns.size():
				_style_seg_btn(btns[j], _seg_eq(values[j], v)))
		_style_seg_btn(b, _seg_eq(values[i], current))
		seg.add_child(b)
		btns.append(b)

func _seg_eq(a, b) -> bool:
	if a is float or b is float:
		return absf(float(a) - float(b)) < 0.01
	return a == b

func _style_seg_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	if active:
		s.bg_color = Color(0.20, 0.17, 0.09)
		s.border_color = UITheme.GOLD
	else:
		s.bg_color = Color(0.10, 0.12, 0.17)
		s.border_color = UITheme.BORDER
	s.set_border_width_all(1); s.set_corner_radius_all(7)
	s.content_margin_left = 12; s.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = s.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_color_override("font_color", UITheme.GOLD if active else UITheme.TEXT_DIM)

func _style_nav_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	if active:
		s.bg_color = Color(0.18, 0.15, 0.08)
		s.border_color = UITheme.GOLD
		s.set_border_width(SIDE_LEFT, 3)
		s.set_border_width(SIDE_RIGHT, 1); s.set_border_width(SIDE_TOP, 1); s.set_border_width(SIDE_BOTTOM, 1)
	else:
		s.bg_color = Color(0.08, 0.09, 0.14, 0.0)
		s.border_color = Color(0, 0, 0, 0)
		s.set_border_width_all(0)
	s.set_corner_radius_all(8)
	s.content_margin_left = 8
	btn.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = Color(0.14, 0.15, 0.21, 0.7)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_stylebox_override("focus", s)
	btn.add_theme_color_override("font_color", UITheme.GOLD if active else UITheme.TEXT_DIM)

func _style_diff_cards(cards: Array, active_id: String) -> void:
	for e in cards:
		var on: bool = e.id == active_id
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.18, 0.15, 0.08) if on else Color(0.09, 0.10, 0.15)
		s.border_color = UITheme.GOLD if on else UITheme.BORDER
		s.set_border_width_all(2 if on else 1)
		s.set_corner_radius_all(9)
		e.btn.add_theme_stylebox_override("normal", s)
		var sh := s.duplicate() as StyleBoxFlat
		sh.bg_color = s.bg_color.lightened(0.06)
		e.btn.add_theme_stylebox_override("hover", sh)
		e.btn.add_theme_stylebox_override("pressed", s)
		e.btn.add_theme_stylebox_override("focus", s)
		e.name.add_theme_color_override("font_color", UITheme.GOLD if on else UITheme.TEXT)
		e.mark.text = "✓" if on else ""
		e.mark.add_theme_color_override("font_color", UITheme.GOLD)

func _get_action_key_label(action: String) -> String:
	if not InputMap.has_action(action):
		return "—"
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.keycode)
	return "—"

func _style_key_btn(btn: Button, waiting: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.22, 0.16, 0.05) if waiting else Color(0.10, 0.12, 0.18)
	s.border_color = UITheme.GOLD if waiting else UITheme.BORDER
	s.set_border_width_all(2 if waiting else 1); s.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover", s)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_color_override("font_color", UITheme.GOLD if waiting else UITheme.TEXT)

func _footer_btn(text: String, variant: String) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 36)
	b.add_theme_font_size_override("font_size", 13)
	UITheme.style_button(b, variant)
	return b

# ── Сброс / экспорт / импорт ──────────────────────────────────────────────────
func _confirm_reset() -> void:
	var dlg := Panel.new()
	dlg.set_anchors_preset(Control.PRESET_CENTER)
	dlg.position = Vector2(-185, -85)
	dlg.size = Vector2(370, 170)
	dlg.add_theme_stylebox_override("panel", UITheme.panel_box())
	add_child(dlg)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 20; vb.offset_right = -20; vb.offset_top = 18; vb.offset_bottom = -18
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 16)
	dlg.add_child(vb)
	var msg := Label.new()
	msg.text = "Сбросить все настройки\nна значения по умолчанию?"
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 14)
	msg.add_theme_color_override("font_color", UITheme.TEXT)
	vb.add_child(msg)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vb.add_child(btn_row)
	var yes := Button.new()
	yes.text = "✓  Сбросить"; yes.custom_minimum_size = Vector2(140, 38)
	yes.add_theme_font_size_override("font_size", 13)
	UITheme.style_button(yes, "danger")
	yes.pressed.connect(func():
		dlg.queue_free()
		if _sm: _sm.reset_to_defaults()
		_rebuild_content())
	btn_row.add_child(yes)
	var no := Button.new()
	no.text = "✕  Отмена"; no.custom_minimum_size = Vector2(140, 38)
	no.add_theme_font_size_override("font_size", 13)
	UITheme.style_button(no, "ghost")
	no.pressed.connect(func(): dlg.queue_free())
	btn_row.add_child(no)

func _copy_file(from_path: String, to_path: String) -> bool:
	var src := FileAccess.open(from_path, FileAccess.READ)
	if not src: return false
	var data := src.get_buffer(src.get_length())
	src.close()
	var dst := FileAccess.open(to_path, FileAccess.WRITE)
	if not dst: return false
	dst.store_buffer(data)
	dst.close()
	return true

func _toast(text: String, ok: bool) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", UITheme.GREEN if ok else UITheme.RED)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.position.y = -40
	lbl.modulate.a = 0.0
	_panel.add_child(lbl)
	var tw := lbl.create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.20)
	tw.tween_interval(2.0)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.30)
	tw.tween_callback(lbl.queue_free)

func _export_settings() -> void:
	var src_path := "user://settings.cfg"
	if not FileAccess.file_exists(src_path):
		_toast("⚠ Нет файла настроек для экспорта", false)
		return
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		var home: String = OS.get_environment("USERPROFILE") if OS.get_name() == "Windows" else OS.get_environment("HOME")
		DisplayServer.file_dialog_show("Экспорт настроек", home, "settings.cfg", false,
			DisplayServer.FILE_DIALOG_MODE_SAVE_FILE, PackedStringArray(["*.cfg ; Файл настроек"]),
			func(status: bool, paths: PackedStringArray, _fi: int):
				if status and paths.size() > 0:
					var ok := _copy_file(src_path, paths[0])
					_toast("✓ Экспортировано: " + paths[0].get_file() if ok else "⚠ Ошибка при экспорте", ok))
	else:
		var fallback := OS.get_executable_path().get_base_dir().path_join("settings_export.cfg")
		var ok := _copy_file(src_path, fallback)
		_toast("✓ Сохранено: settings_export.cfg" if ok else "⚠ Ошибка при экспорте", ok)

func _import_settings() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		var home: String = OS.get_environment("USERPROFILE") if OS.get_name() == "Windows" else OS.get_environment("HOME")
		DisplayServer.file_dialog_show("Импорт настроек", home, "", false,
			DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, PackedStringArray(["*.cfg ; Файл настроек"]),
			func(status: bool, paths: PackedStringArray, _fi: int):
				if not status or paths.is_empty(): return
				var ok := _copy_file(paths[0], "user://settings.cfg")
				if ok and _sm:
					_sm.load_settings(); _sm._apply_all(); _rebuild_content()
				else:
					_toast("⚠ Не удалось импортировать файл", false))
	else:
		var fallback := OS.get_executable_path().get_base_dir().path_join("settings_export.cfg")
		if not FileAccess.file_exists(fallback):
			_toast("⚠ Поместите settings_export.cfg рядом с игрой", false)
			return
		var ok := _copy_file(fallback, "user://settings.cfg")
		if ok and _sm:
			_sm.load_settings(); _sm._apply_all(); _rebuild_content()
		else:
			_toast("⚠ Ошибка при импорте", false)
