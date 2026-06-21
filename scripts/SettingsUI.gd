extends CanvasLayer

# Единое окно настроек — используется и в главном меню, и в игре.
# Студийный стиль: профили, вкладки (Звук/Экран/Геймплей/Доступность/Клавиши/
# История), перепривязка клавиш, экспорт/импорт, сброс.

var _sm: Node
var _L: Node

var _dimmer: ColorRect
var _panel: Panel
var _root_vbox: VBoxContainer
var _active_tab: String = "sound"

# Перепривязка клавиш
var _rebinding: bool = false
var _rebind_action: String = ""
var _rebind_btn: Button = null

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
	_panel.scale = Vector2(0.93, 0.93)
	_dimmer.color.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dimmer, "color:a", 0.55, dur)
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
	_dimmer.color = Color(0, 0, 0, 0.55)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_dimmer.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close())
	add_child(_dimmer)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.size = Vector2(500, 600)
	_panel.position = Vector2(-250, -300)
	add_child(_panel)

	_root_vbox = VBoxContainer.new()
	_root_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_vbox.offset_left = 20; _root_vbox.offset_right = -20
	_root_vbox.offset_top = 14; _root_vbox.offset_bottom = -14
	_root_vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(_root_vbox)

func _panel_style(hc: bool) -> void:
	var ps := StyleBoxFlat.new()
	if hc:
		ps.bg_color = Color(0.0, 0.0, 0.0, 1.0)
		ps.border_color = Color(1.0, 1.0, 0.0, 1.0)
		ps.set_border_width_all(3)
	else:
		ps.bg_color = Color(0.05, 0.05, 0.09, 0.98)
		ps.border_color = Color(0.40, 0.40, 0.55, 0.90)
		ps.set_border_width_all(2)
	ps.set_corner_radius_all(12)
	_panel.add_theme_stylebox_override("panel", ps)

# ── Полная пересборка содержимого ─────────────────────────────────────────────
func _rebuild_content() -> void:
	for c in _root_vbox.get_children():
		c.queue_free()
	var hc: bool = _sm.high_contrast if _sm else false
	_panel_style(hc)

	# Заголовок
	var hdr := HBoxContainer.new()
	_root_vbox.add_child(hdr)
	var ttl := Label.new()
	ttl.text = _t("settings_title", "⚙  Настройки")
	ttl.add_theme_font_size_override("font_size", 20)
	ttl.add_theme_color_override("font_color", Color(0.88, 0.88, 1.0))
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_child(ttl)
	var cls := Button.new()
	cls.text = "✕"
	cls.custom_minimum_size = Vector2(32, 32)
	cls.add_theme_font_size_override("font_size", 14)
	cls.add_theme_color_override("font_color", Color.WHITE)
	var lcs := StyleBoxFlat.new()
	lcs.bg_color = Color(0.22, 0.07, 0.07, 0.90)
	lcs.border_color = Color(0.55, 0.18, 0.18, 0.80)
	lcs.set_border_width_all(1); lcs.set_corner_radius_all(6)
	cls.add_theme_stylebox_override("normal", lcs)
	var lch := lcs.duplicate() as StyleBoxFlat
	lch.bg_color = Color(0.40, 0.10, 0.10)
	cls.add_theme_stylebox_override("hover", lch)
	cls.pressed.connect(_close)
	hdr.add_child(cls)

	_build_profiles()
	_root_vbox.add_child(HSeparator.new())

	# Вкладки
	var TAB_DEFS: Array = [
		{"label": _t("tab_sound", "🔊 Звук"),       "id": "sound"},
		{"label": _t("tab_screen", "🖥 Экран"),      "id": "screen"},
		{"label": _t("tab_gameplay", "🎮 Игра"),     "id": "gameplay"},
		{"label": _t("tab_access", "♿ Доступн."),    "id": "access"},
		{"label": _t("tab_controls", "⌨ Клавиши"),  "id": "controls"},
		{"label": _t("tab_history", "📋 История"),   "id": "history"},
	]
	var tab_bar := HBoxContainer.new()
	tab_bar.add_theme_constant_override("separation", 4)
	_root_vbox.add_child(tab_bar)

	var page_host := Control.new()
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_host.clip_contents = true
	_root_vbox.add_child(page_host)

	var pages := {}
	for td in TAB_DEFS:
		var scroll := ScrollContainer.new()
		scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.visible = false
		page_host.add_child(scroll)
		var pg := VBoxContainer.new()
		pg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pg.add_theme_constant_override("separation", 8)
		scroll.add_child(pg)
		pages[td.id] = pg
		pages[td.id + "_scroll"] = scroll

	var tab_btns: Array = []
	var switch_tab := func(tab_id: String) -> void:
		_active_tab = tab_id
		for td2 in TAB_DEFS:
			pages[td2.id + "_scroll"].visible = (td2.id == tab_id)
		for i in tab_btns.size():
			_style_tab_btn(tab_btns[i], TAB_DEFS[i].id == tab_id)
	for td in TAB_DEFS:
		var tb := Button.new()
		tb.text = td.label
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 32)
		tb.add_theme_font_size_override("font_size", 12)
		var tid: String = td.id
		tb.pressed.connect(func(): switch_tab.call(tid))
		tab_bar.add_child(tb)
		tab_btns.append(tb)

	_build_sound(pages["sound"])
	_build_screen(pages["screen"])
	_build_gameplay(pages["gameplay"])
	_build_access(pages["access"], hc)
	_build_controls(pages["controls"])
	_build_history(pages["history"])

	# Футер: экспорт/импорт
	_root_vbox.add_child(HSeparator.new())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	_root_vbox.add_child(footer)
	var exp_btn := _footer_btn("📤  Экспорт", Color(0.08, 0.14, 0.08), Color(0.28, 0.55, 0.28, 0.80))
	exp_btn.pressed.connect(_export_settings)
	footer.add_child(exp_btn)
	var imp_btn := _footer_btn("📥  Импорт", Color(0.08, 0.10, 0.18), Color(0.28, 0.40, 0.65, 0.80))
	imp_btn.pressed.connect(_import_settings)
	footer.add_child(imp_btn)

	if not pages.has(_active_tab):
		_active_tab = "sound"
	switch_tab.call(_active_tab)

# ── Профили ───────────────────────────────────────────────────────────────────
func _build_profiles() -> void:
	var prof_header := HBoxContainer.new()
	prof_header.add_theme_constant_override("separation", 6)
	_root_vbox.add_child(prof_header)
	var prof_title := Label.new()
	prof_title.text = "ПРОФИЛИ"
	prof_title.add_theme_font_size_override("font_size", 10)
	prof_title.add_theme_color_override("font_color", Color(0.45, 0.45, 0.60))
	prof_title.custom_minimum_size = Vector2(58, 0)
	prof_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prof_header.add_child(prof_title)

	for pi in 3:
		var filled: bool = _sm and _sm.profile_filled(pi)
		var slot_bg := StyleBoxFlat.new()
		slot_bg.bg_color = Color(0.08, 0.08, 0.14)
		slot_bg.border_color = Color(0.25, 0.25, 0.38)
		slot_bg.set_border_width_all(1); slot_bg.set_corner_radius_all(5)
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
		name_lbl.text = "Слот %d" % (pi + 1)
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color",
			Color(0.75, 0.90, 0.75) if filled else Color(0.40, 0.40, 0.52))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		inner.add_child(name_lbl)
		var pslot: int = pi
		var save_btn := Button.new()
		save_btn.text = "💾"; save_btn.tooltip_text = "Сохранить профиль"
		save_btn.custom_minimum_size = Vector2(26, 24)
		save_btn.add_theme_font_size_override("font_size", 12)
		var ss := StyleBoxFlat.new()
		ss.bg_color = Color(0.10, 0.18, 0.10); ss.border_color = Color(0.28, 0.55, 0.28, 0.80)
		ss.set_border_width_all(1); ss.set_corner_radius_all(4)
		save_btn.add_theme_stylebox_override("normal", ss)
		save_btn.pressed.connect(func():
			if _sm: _sm.save_profile(pslot)
			_rebuild_content())
		inner.add_child(save_btn)
		var load_btn := Button.new()
		load_btn.text = "▶"; load_btn.tooltip_text = "Загрузить профиль"
		load_btn.custom_minimum_size = Vector2(26, 24)
		load_btn.add_theme_font_size_override("font_size", 11)
		load_btn.disabled = not filled
		var ls2 := StyleBoxFlat.new()
		ls2.bg_color = Color(0.10, 0.14, 0.22) if filled else Color(0.07, 0.07, 0.10)
		ls2.border_color = Color(0.28, 0.40, 0.70, 0.80) if filled else Color(0.18, 0.18, 0.25)
		ls2.set_border_width_all(1); ls2.set_corner_radius_all(4)
		load_btn.add_theme_stylebox_override("normal", ls2)
		load_btn.pressed.connect(func():
			if _sm and _sm.profile_filled(pslot):
				_sm.load_profile(pslot)
				_rebuild_content())
		inner.add_child(load_btn)

# ── Страница: Звук ────────────────────────────────────────────────────────────
func _build_sound(pg: VBoxContainer) -> void:
	_section(pg, _t("volume_section", "ГРОМКОСТЬ"))
	_add_slider_row(pg, _sm.master_vol if _sm else 1.0,
		func(v): if _sm: _sm.set_master_vol(v), ["🔇", "🔈", "🔊"], _t("master", "Мастер"))
	_add_slider_row(pg, _sm.music_vol if _sm else 1.0,
		func(v): if _sm: _sm.set_music_vol(v), ["🔇", "🎵", "🎵"], _t("music", "Музыка"))
	_add_slider_row(pg, _sm.sfx_vol if _sm else 1.0,
		func(v): if _sm: _sm.set_sfx_vol(v), ["🔇", "🔈", "🔊"], _t("sounds", "Звуки"))
	pg.add_child(HSeparator.new())
	_section(pg, _t("fps_section", "ОГРАНИЧЕНИЕ FPS"))
	_choice_row(pg, [30, 60, 120, 0], ["30", "60", "120", "∞"], _sm.fps_cap if _sm else 60,
		func(v): if _sm: _sm.set_fps_cap(v))
	pg.add_child(HSeparator.new())
	var reset_btn := Button.new()
	reset_btn.text = _t("reset_settings", "↺  Сбросить все настройки")
	reset_btn.custom_minimum_size = Vector2(0, 36)
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.add_theme_font_size_override("font_size", 13)
	reset_btn.add_theme_color_override("font_color", Color(0.85, 0.70, 0.70))
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.14, 0.10, 0.10, 0.80); rs.border_color = Color(0.40, 0.30, 0.30, 0.70)
	rs.set_border_width_all(1); rs.set_corner_radius_all(8)
	reset_btn.add_theme_stylebox_override("normal", rs)
	reset_btn.pressed.connect(_confirm_reset)
	pg.add_child(reset_btn)

# ── Страница: Экран ───────────────────────────────────────────────────────────
func _build_screen(pg: VBoxContainer) -> void:
	_section(pg, _t("window_mode", "РЕЖИМ ОКНА"))
	_add_toggle_row(pg, _t("fullscreen", "🖥  Полный экран"), _sm and _sm.fullscreen,
		func(on): if _sm: _sm.set_fullscreen(on))
	_add_toggle_row(pg, _t("vsync", "⟳  VSync"), _sm.vsync if _sm else true,
		func(on): if _sm: _sm.set_vsync(on))
	pg.add_child(HSeparator.new())
	_section(pg, _t("resolution", "РАЗРЕШЕНИЕ ОКНА"))
	var note := Label.new()
	note.text = _t("window_only", "Применяется только в оконном режиме")
	note.add_theme_font_size_override("font_size", 10)
	note.add_theme_color_override("font_color", Color(0.40, 0.40, 0.50))
	pg.add_child(note)
	var RES: Array = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
	var RES_L: Array = ["1280×720", "1600×900", "1920×1080"]
	var cur_size: Vector2i = DisplayServer.window_get_size()
	var res_row := HBoxContainer.new()
	res_row.alignment = BoxContainer.ALIGNMENT_CENTER
	res_row.add_theme_constant_override("separation", 6)
	pg.add_child(res_row)
	var res_btns: Array = []
	for ri in RES.size():
		var rb := Button.new()
		rb.text = RES_L[ri]
		rb.custom_minimum_size = Vector2(110, 32)
		rb.add_theme_font_size_override("font_size", 12)
		var rsize: Vector2i = RES[ri]
		rb.pressed.connect(func():
			if _sm and _sm.fullscreen: return
			DisplayServer.window_set_size(rsize)
			DisplayServer.window_set_position(DisplayServer.screen_get_size() / 2 - rsize / 2)
			for j in res_btns.size():
				_style_fps_btn(res_btns[j], RES[j] == rsize))
		_style_fps_btn(rb, cur_size == RES[ri])
		res_row.add_child(rb)
		res_btns.append(rb)
	pg.add_child(HSeparator.new())
	_section(pg, _t("language_section", "ЯЗЫК ИНТЕРФЕЙСА"))
	var lang_row := HBoxContainer.new()
	lang_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_row.add_theme_constant_override("separation", 10)
	pg.add_child(lang_row)
	var LANGS: Array = [{"id": "ru", "label": "🇷🇺  Русский"}, {"id": "en", "label": "🇬🇧  English"}]
	var cur_locale: String = _L.locale if _L else "ru"
	var lang_btns: Array = []
	for ld in LANGS:
		var lb := Button.new()
		lb.text = ld.label
		lb.custom_minimum_size = Vector2(150, 34)
		lb.add_theme_font_size_override("font_size", 13)
		var lid: String = ld.id
		lb.pressed.connect(func():
			if _sm: _sm.set_locale(lid)
			_rebuild_content())
		_style_tab_btn(lb, ld.id == cur_locale)
		lang_row.add_child(lb)
		lang_btns.append(lb)

# ── Страница: Геймплей ────────────────────────────────────────────────────────
func _build_gameplay(pg: VBoxContainer) -> void:
	_section(pg, _t("difficulty_section", "СЛОЖНОСТЬ"))
	var DIFFS: Array = [
		{"id": "easy", "label": _t("diff_easy", "🌱 Лёгкая"),
		 "desc": _t("diff_easy_desc", "Штрафы и налоги ×0.5, голод медленнее. Старт весной 🌸"), "col": Color(0.30, 0.72, 0.35)},
		{"id": "normal", "label": _t("diff_normal", "⚖ Нормальная"),
		 "desc": _t("diff_normal_desc", "Стандартный баланс. Старт летом ☀"), "col": Color(0.65, 0.65, 0.85)},
		{"id": "hard", "label": _t("diff_hard", "🔥 Тяжёлая"),
		 "desc": _t("diff_hard_desc", "Штрафы и налоги ×1.25. Старт осенью 🍂"), "col": Color(0.92, 0.60, 0.25)},
		{"id": "hardcore", "label": _t("diff_hardcore", "💀 Хардкор"),
		 "desc": _t("diff_hardcore_desc", "Штрафы и налоги ×1.5, голод быстрее. Старт зимой ❄"), "col": Color(0.90, 0.35, 0.35)},
	]
	var cur_diff: String = _sm.difficulty if _sm else "normal"
	var diff_btns: Array = []
	for dd in DIFFS:
		var card := Panel.new()
		card.custom_minimum_size = Vector2(0, 58)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pg.add_child(card)
		var ci := HBoxContainer.new()
		ci.set_anchors_preset(Control.PRESET_FULL_RECT)
		ci.add_theme_constant_override("separation", 10)
		card.add_child(ci)
		var spl := Control.new(); spl.custom_minimum_size = Vector2(8, 0)
		ci.add_child(spl)
		var tcol := VBoxContainer.new()
		tcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tcol.alignment = BoxContainer.ALIGNMENT_CENTER
		ci.add_child(tcol)
		var dn := Label.new(); dn.text = dd.label; dn.add_theme_font_size_override("font_size", 14)
		tcol.add_child(dn)
		var de := Label.new(); de.text = dd.desc; de.add_theme_font_size_override("font_size", 10)
		de.add_theme_color_override("font_color", Color(0.55, 0.55, 0.60))
		tcol.add_child(de)
		var sb := Button.new(); sb.custom_minimum_size = Vector2(86, 32)
		sb.add_theme_font_size_override("font_size", 12)
		ci.add_child(sb)
		var spr := Control.new(); spr.custom_minimum_size = Vector2(6, 0)
		ci.add_child(spr)
		diff_btns.append({"card": card, "btn": sb, "dd": dd, "name_lbl": dn})
	var apply_styles := func(active_id: String) -> void:
		for e in diff_btns:
			var on: bool = e.dd.id == active_id
			var col: Color = e.dd.col
			var cs := StyleBoxFlat.new()
			cs.bg_color = Color(col.r * 0.15, col.g * 0.15, col.b * 0.15, 0.90) if on else Color(0.07, 0.07, 0.11, 0.90)
			cs.border_color = col.lerp(Color(1,1,1), 0.1) if on else Color(0.20, 0.20, 0.30)
			for sd in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
				cs.set_border_width(sd, 2 if on else 1); cs.set_corner_radius(sd, 7)
			e.card.add_theme_stylebox_override("panel", cs)
			e.btn.text = "✓ Выбрано" if on else "Выбрать"
			var bs := StyleBoxFlat.new()
			bs.bg_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25) if on else Color(0.10, 0.10, 0.16)
			bs.border_color = col if on else Color(0.28, 0.28, 0.42)
			bs.set_border_width_all(1); bs.set_corner_radius_all(5)
			e.btn.add_theme_stylebox_override("normal", bs)
			e.btn.add_theme_color_override("font_color", col.lerp(Color(1,1,1), 0.3) if on else Color(0.60, 0.60, 0.70))
			e.name_lbl.add_theme_color_override("font_color", col if on else Color(0.75, 0.75, 0.80))
	apply_styles.call(cur_diff)
	for e in diff_btns:
		var did: String = e.dd.id
		e.btn.pressed.connect(func():
			if _sm: _sm.set_difficulty(did)
			apply_styles.call(did))
	pg.add_child(HSeparator.new())
	_section(pg, _t("speed_section", "СКОРОСТЬ ВРЕМЕНИ ПО УМОЛЧАНИЮ"))
	_choice_row_f(pg, [1.0, 2.0, 3.0], ["×1", "×2", "×3"], _sm.default_speed if _sm else 1.0,
		func(v): if _sm: _sm.set_default_speed(v))
	pg.add_child(HSeparator.new())
	_section(pg, _t("autopause_section", "ПРОЧЕЕ"))
	_add_toggle_row(pg, _t("autopause_label", "⏸  Пауза при открытии меню"), _sm.autopause if _sm else true,
		func(on): if _sm: _sm.set_autopause(on))
	pg.add_child(HSeparator.new())
	_section(pg, "УВЕДОМЛЕНИЯ")
	var NOTIFS: Array = [
		{"key": "autosave", "label": "💾  Автосохранение", "val": _sm.notify_autosave if _sm else true},
		{"key": "events", "label": "📰  Случайные события", "val": _sm.notify_events if _sm else true},
		{"key": "achievements", "label": "🏆  Достижения", "val": _sm.notify_achievements if _sm else true},
		{"key": "taxes", "label": "📋  Налоги", "val": _sm.notify_taxes if _sm else true},
		{"key": "police", "label": "👮  Полиция", "val": _sm.notify_police if _sm else true},
		{"key": "hints", "label": "💡  Подсказки", "val": _sm.show_hints if _sm else true},
	]
	for nd in NOTIFS:
		var nkey: String = nd.key
		_add_toggle_row(pg, nd.label, nd.val, func(on): if _sm: _sm.set_notify(nkey, on))

# ── Страница: Доступность ─────────────────────────────────────────────────────
func _build_access(pg: VBoxContainer, hc: bool) -> void:
	var sec_col: Color = Color(1.0, 1.0, 0.0) if hc else Color(0.50, 0.50, 0.65)
	_section(pg, _t("font_size_section", "РАЗМЕР ТЕКСТА"), sec_col)
	var FS: Array = [
		{"id": "normal", "label": _t("font_normal", "Обычный"), "sz": 13},
		{"id": "large", "label": _t("font_large", "Крупный"), "sz": 16},
		{"id": "xlarge", "label": _t("font_xlarge", "Очень крупный"), "sz": 20},
	]
	var cur_fs: String = _sm.font_size if _sm else "normal"
	var fs_row := HBoxContainer.new()
	fs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	fs_row.add_theme_constant_override("separation", 8)
	pg.add_child(fs_row)
	var fs_btns: Array = []
	for fi in FS.size():
		var fb := Button.new()
		fb.text = FS[fi].label
		fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fb.custom_minimum_size = Vector2(0, 34)
		fb.add_theme_font_size_override("font_size", FS[fi].sz)
		var fid: String = FS[fi].id
		fb.pressed.connect(func():
			if _sm: _sm.set_font_size(fid)
			_rebuild_content())
		_style_fps_btn(fb, FS[fi].id == cur_fs)
		fs_row.add_child(fb)
		fs_btns.append(fb)
	pg.add_child(HSeparator.new())
	_section(pg, _t("contrast_section", "КОНТРАСТ"), sec_col)
	_add_toggle_row(pg, _t("high_contrast_label", "⬛  Высокий контраст"), hc,
		func(on):
			if _sm: _sm.set_high_contrast(on)
			_rebuild_content())
	pg.add_child(HSeparator.new())
	_section(pg, _t("anim_section", "АНИМАЦИИ"), sec_col)
	_add_toggle_row(pg, _t("ui_anim_label", "✨  Анимации интерфейса"), _sm.ui_animations if _sm else true,
		func(on): if _sm: _sm.set_ui_animations(on))

# ── Страница: Клавиши ─────────────────────────────────────────────────────────
func _build_controls(pg: VBoxContainer) -> void:
	_section(pg, _t("keybinds", "ГОРЯЧИЕ КЛАВИШИ"))
	var ACTIONS: Array = [
		{"action": "move_up", "label": _t("action_up", "Вверх")},
		{"action": "move_down", "label": _t("action_down", "Вниз")},
		{"action": "move_left", "label": _t("action_left", "Влево")},
		{"action": "move_right", "label": _t("action_right", "Вправо")},
		{"action": "interact", "label": _t("action_interact", "Взаимодействие")},
		{"action": "ui_cancel", "label": _t("action_pause", "Пауза / Закрыть")},
		{"action": "sleep", "label": _t("action_sleep", "Сон")},
	]
	for ad in ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		pg.add_child(row)
		var lbl := Label.new()
		lbl.text = ad.label
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.85))
		row.add_child(lbl)
		var key_btn := Button.new()
		key_btn.custom_minimum_size = Vector2(120, 30)
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
			key_btn.text = _t("waiting_key", "[ нажми клавишу ]")
			_style_key_btn(key_btn, true))
		row.add_child(key_btn)
	var hint := Label.new()
	hint.text = _t("rebind_hint", "Нажми кнопку → затем нужную клавишу")
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.38, 0.38, 0.50))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pg.add_child(hint)

# ── Страница: История ─────────────────────────────────────────────────────────
func _build_history(pg: VBoxContainer) -> void:
	var log_entries: Array = _sm.change_log if _sm else []
	if log_entries.is_empty():
		var empty := Label.new()
		empty.text = _t("history_empty", "Изменений пока нет.\nОткрой настройки и что-нибудь измени.")
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.40, 0.40, 0.52))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pg.add_child(empty)
	else:
		for i in log_entries.size():
			var entry: String = log_entries[i]
			var row := Panel.new()
			row.custom_minimum_size = Vector2(0, 26)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var rstyle := StyleBoxFlat.new()
			rstyle.bg_color = Color(0.10, 0.10, 0.16) if i % 2 == 0 else Color(0.07, 0.07, 0.12)
			rstyle.set_corner_radius_all(4)
			row.add_theme_stylebox_override("panel", rstyle)
			pg.add_child(row)
			var rl := Label.new()
			rl.text = entry
			rl.add_theme_font_size_override("font_size", 12)
			rl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.85) if i == 0 else Color(0.60, 0.62, 0.65))
			rl.set_anchors_preset(Control.PRESET_FULL_RECT)
			rl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			rl.add_theme_constant_override("margin_left", 8)
			row.add_child(rl)
	pg.add_child(HSeparator.new())
	var clear_btn := Button.new()
	clear_btn.text = _t("history_clear", "🗑  Очистить журнал")
	clear_btn.custom_minimum_size = Vector2(0, 30)
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.add_theme_font_size_override("font_size", 12)
	clear_btn.add_theme_color_override("font_color", Color(0.65, 0.45, 0.45))
	var cls2 := StyleBoxFlat.new()
	cls2.bg_color = Color(0.12, 0.07, 0.07); cls2.border_color = Color(0.38, 0.20, 0.20, 0.80)
	cls2.set_border_width_all(1); cls2.set_corner_radius_all(6)
	clear_btn.add_theme_stylebox_override("normal", cls2)
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

# ── Вспомогательные ───────────────────────────────────────────────────────────
func _section(parent: VBoxContainer, text: String, col: Color = Color(0.50, 0.50, 0.65)) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", col)
	parent.add_child(lbl)

func _vol_icon(icons: Array, v: float) -> String:
	if v <= 0.001: return icons[0]
	if v < 0.5: return icons[1]
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
	slider.min_value = 0.0; slider.max_value = 1.0; slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 24)
	var sl_bg := StyleBoxFlat.new()
	sl_bg.bg_color = Color(0.15, 0.15, 0.24); sl_bg.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("slider", sl_bg)
	var sl_fill := StyleBoxFlat.new()
	sl_fill.bg_color = Color(0.32, 0.42, 0.78); sl_fill.set_corner_radius_all(4)
	slider.add_theme_stylebox_override("grabber_area", sl_fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", sl_fill)
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
		on_change.call(v))

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
	var mk := func(on: bool) -> void:
		btn.text = "ВКЛ" if on else "ВЫКЛ"
		var s2 := StyleBoxFlat.new()
		s2.bg_color = Color(0.12, 0.35, 0.12) if on else Color(0.25, 0.12, 0.12)
		s2.border_color = Color(0.30, 0.72, 0.30) if on else Color(0.55, 0.22, 0.22)
		s2.set_border_width_all(1); s2.set_corner_radius_all(6)
		btn.add_theme_stylebox_override("normal", s2)
		btn.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55) if on else Color(1.0, 0.55, 0.55))
	mk.call(initial)
	var state := [initial]
	btn.pressed.connect(func():
		state[0] = not state[0]
		mk.call(state[0])
		on_toggle.call(state[0]))
	row.add_child(btn)

func _choice_row(parent: VBoxContainer, values: Array, labels: Array, current, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var btns: Array = []
	for i in values.size():
		var b := Button.new()
		b.text = labels[i]
		b.custom_minimum_size = Vector2(70, 32)
		b.add_theme_font_size_override("font_size", 14)
		var v = values[i]
		b.pressed.connect(func():
			on_change.call(v)
			for j in btns.size():
				_style_fps_btn(btns[j], values[j] == v))
		_style_fps_btn(b, values[i] == current)
		row.add_child(b)
		btns.append(b)

func _choice_row_f(parent: VBoxContainer, values: Array, labels: Array, current: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var btns: Array = []
	for i in values.size():
		var b := Button.new()
		b.text = labels[i]
		b.custom_minimum_size = Vector2(80, 32)
		b.add_theme_font_size_override("font_size", 14)
		var v: float = values[i]
		b.pressed.connect(func():
			on_change.call(v)
			for j in btns.size():
				_style_fps_btn(btns[j], absf(float(values[j]) - v) < 0.01))
		_style_fps_btn(b, absf(float(values[i]) - current) < 0.01)
		row.add_child(b)
		btns.append(b)

func _style_fps_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.15, 0.20, 0.35) if active else Color(0.10, 0.10, 0.16)
	s.border_color = Color(0.40, 0.55, 0.90) if active else Color(0.28, 0.28, 0.40)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_border_width(side, 2 if active else 1); s.set_corner_radius(side, 6)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0) if active else Color(0.55, 0.55, 0.60))

func _style_tab_btn(btn: Button, active: bool) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.18, 0.18, 0.30) if active else Color(0.08, 0.08, 0.14)
	s.border_color = Color(0.50, 0.55, 0.90) if active else Color(0.25, 0.25, 0.38)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		s.set_border_width(side, 2 if active else 1); s.set_corner_radius(side, 6)
	btn.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate() as StyleBoxFlat
	sh.bg_color = s.bg_color.lightened(0.08)
	btn.add_theme_stylebox_override("hover", sh)
	btn.add_theme_color_override("font_color", Color(0.90, 0.92, 1.0) if active else Color(0.50, 0.50, 0.65))

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
		s.set_border_width(side, 2 if waiting else 1); s.set_corner_radius(side, 5)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_color_override("font_color", Color(1.0, 0.80, 0.20) if waiting else Color(0.75, 0.85, 1.0))

func _footer_btn(text: String, bg: Color, border: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 30)
	b.add_theme_font_size_override("font_size", 12)
	var fs := StyleBoxFlat.new()
	fs.bg_color = bg; fs.border_color = border
	fs.set_border_width_all(1); fs.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", fs)
	var fsh := fs.duplicate() as StyleBoxFlat
	fsh.bg_color = bg.lightened(0.12)
	b.add_theme_stylebox_override("hover", fsh)
	return b

func _confirm_reset() -> void:
	var dlg := Panel.new()
	dlg.set_anchors_preset(Control.PRESET_CENTER)
	dlg.position = Vector2(-175, -80)
	dlg.size = Vector2(350, 160)
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.08, 0.04, 0.04, 0.98); ds.border_color = Color(0.65, 0.20, 0.20, 0.90)
	ds.set_border_width_all(2); ds.set_corner_radius_all(10)
	ds.content_margin_left = 18; ds.content_margin_right = 18
	ds.content_margin_top = 16; ds.content_margin_bottom = 16
	dlg.add_theme_stylebox_override("panel", ds)
	add_child(dlg)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	dlg.add_child(vb)
	var msg := Label.new()
	msg.text = _t("confirm_reset_msg", "Сбросить все настройки\nна значения по умолчанию?")
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 14)
	msg.add_theme_color_override("font_color", Color(0.90, 0.80, 0.80))
	vb.add_child(msg)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 12)
	vb.add_child(btn_row)
	var yes := Button.new()
	yes.text = _t("confirm_reset_yes", "✓  Сбросить")
	yes.custom_minimum_size = Vector2(130, 36)
	yes.add_theme_font_size_override("font_size", 13)
	yes.add_theme_color_override("font_color", Color(1.0, 0.75, 0.75))
	var ys := StyleBoxFlat.new()
	ys.bg_color = Color(0.30, 0.06, 0.06); ys.border_color = Color(0.72, 0.18, 0.18, 0.90)
	ys.set_border_width_all(1); ys.set_corner_radius_all(7)
	yes.add_theme_stylebox_override("normal", ys)
	yes.pressed.connect(func():
		dlg.queue_free()
		if _sm: _sm.reset_to_defaults()
		_rebuild_content())
	btn_row.add_child(yes)
	var no := Button.new()
	no.text = _t("confirm_reset_no", "✕  Отмена")
	no.custom_minimum_size = Vector2(130, 36)
	no.add_theme_font_size_override("font_size", 13)
	var ns := StyleBoxFlat.new()
	ns.bg_color = Color(0.12, 0.12, 0.18); ns.border_color = Color(0.35, 0.35, 0.50, 0.80)
	ns.set_border_width_all(1); ns.set_corner_radius_all(7)
	no.add_theme_stylebox_override("normal", ns)
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
	lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.45) if ok else Color(1.0, 0.45, 0.45))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.position.y = -34
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
