extends CanvasLayer

signal resume_pressed

var _main_panel: Control
var _speed_btns: Array = []

const SPEEDS: Array = [1.0, 2.0, 3.0]
const SPEED_LABELS: Array = ["×1", "×2", "×3"]

func _ready() -> void:
	layer = 50
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.72)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dimmer)

	# ── Главная панель паузы ──────────────────────────────────────────────────
	_main_panel = Panel.new()
	_main_panel.set_anchors_preset(Control.PRESET_CENTER)
	_main_panel.position = Vector2(-190, -270)
	_main_panel.size = Vector2(380, 540)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.05, 0.05, 0.09, 0.97)
	ps.border_color = Color(0.30, 0.33, 0.52, 0.90)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		ps.set_border_width(side, 2)
		ps.set_corner_radius(side, 10)
	_main_panel.add_theme_stylebox_override("panel", ps)
	add_child(_main_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	_main_panel.add_child(vbox)

	var title := Label.new()
	title.text = "⏸ Пауза"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.70))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Скорость игры
	var speed_lbl := Label.new()
	speed_lbl.text = "Скорость игры:"
	speed_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(speed_lbl)

	var speed_row := HBoxContainer.new()
	speed_row.alignment = BoxContainer.ALIGNMENT_CENTER
	speed_row.add_theme_constant_override("separation", 8)
	vbox.add_child(speed_row)

	for i in SPEEDS.size():
		var btn := Button.new()
		btn.text = SPEED_LABELS[i]
		btn.custom_minimum_size = Vector2(70, 36)
		btn.add_theme_font_size_override("font_size", 16)
		var spd: float = SPEEDS[i]
		btn.pressed.connect(func(): _set_speed(spd))
		speed_row.add_child(btn)
		_speed_btns.append(btn)
	_highlight_speed(Engine.time_scale)

	vbox.add_child(HSeparator.new())

	# ── Настройки звука и экрана ──────────────────────────────────────────────
	var settings_lbl := Label.new()
	settings_lbl.text = "⚙ Настройки"
	settings_lbl.add_theme_font_size_override("font_size", 13)
	settings_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.85))
	vbox.add_child(settings_lbl)

	var sm: Node = get_node_or_null("/root/SettingsManager")

	# Мастер / Музыка / Звуки
	_pause_slider_row(vbox, sm, "Мастер", ["🔇","🔈","🔊"],
		sm.master_vol if sm else 1.0,
		func(v: float): if sm: sm.set_master_vol(v))
	_pause_slider_row(vbox, sm, "Музыка", ["🔇","🎵","🎵"],
		sm.music_vol if sm else 1.0,
		func(v: float): if sm: sm.set_music_vol(v))
	_pause_slider_row(vbox, sm, "Звуки",  ["🔇","🔈","🔊"],
		sm.sfx_vol if sm else 1.0,
		func(v: float): if sm: sm.set_sfx_vol(v))

	# Полный экран + VSync в одну строку
	var screen_row := HBoxContainer.new()
	screen_row.add_theme_constant_override("separation", 10)
	vbox.add_child(screen_row)
	_pause_toggle_btn(screen_row, "🖥 Экран", sm and sm.fullscreen,
		func(on: bool): if sm: sm.set_fullscreen(on))
	_pause_toggle_btn(screen_row, "⟳ VSync", sm.vsync if sm else true,
		func(on: bool): if sm: sm.set_vsync(on))

	vbox.add_child(HSeparator.new())

	# Кнопки
	var btn_resume := Button.new()
	btn_resume.text = "▶  Продолжить   [ESC]"
	btn_resume.custom_minimum_size = Vector2(300, 42)
	btn_resume.add_theme_font_size_override("font_size", 16)
	btn_resume.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	_style_pause_btn(btn_resume, Color(0.08, 0.22, 0.10), Color(0.25, 0.62, 0.25, 0.90))
	btn_resume.pressed.connect(_resume)
	vbox.add_child(btn_resume)

	var btn_save := Button.new()
	btn_save.text = "💾  Сохранить игру"
	btn_save.custom_minimum_size = Vector2(300, 36)
	btn_save.add_theme_font_size_override("font_size", 14)
	_style_pause_btn(btn_save, Color(0.10, 0.12, 0.20), Color(0.30, 0.33, 0.52, 0.80))
	btn_save.pressed.connect(_save)
	vbox.add_child(btn_save)

	var btn_menu := Button.new()
	btn_menu.text = "🏠  В главное меню"
	btn_menu.custom_minimum_size = Vector2(300, 36)
	btn_menu.add_theme_font_size_override("font_size", 14)
	btn_menu.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	_style_pause_btn(btn_menu, Color(0.20, 0.08, 0.08), Color(0.52, 0.22, 0.22, 0.80))
	btn_menu.pressed.connect(_go_to_menu)
	vbox.add_child(btn_menu)

func _style_pause_btn(btn: Button, bg: Color, border: Color) -> void:
	var sn := StyleBoxFlat.new()
	sn.bg_color = bg
	sn.border_color = border
	for s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sn.set_border_width(s, 1)
		sn.set_corner_radius(s, 6)
	btn.add_theme_stylebox_override("normal", sn)
	var sh := sn.duplicate() as StyleBoxFlat
	sh.bg_color = bg.lightened(0.10)
	btn.add_theme_stylebox_override("hover", sh)

func open() -> void:
	visible = true
	var sm := get_node_or_null("/root/SettingsManager")
	if not sm or sm.autopause:
		get_tree().paused = true
	var dur: float = 0.22 if (not sm or sm.ui_animations) else 0.0
	_main_panel.modulate.a = 0.0
	_main_panel.scale = Vector2(0.90, 0.90)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_main_panel, "modulate:a", 1.0, dur)
	tw.tween_property(_main_panel, "scale", Vector2(1.0, 1.0), dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _resume() -> void:
	var sm2 := get_node_or_null("/root/SettingsManager")
	var dur2: float = 0.14 if (not sm2 or sm2.ui_animations) else 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_main_panel, "modulate:a", 0.0, dur2)
	tw.tween_property(_main_panel, "scale", Vector2(0.92, 0.92), dur2).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(func():
		visible = false
		_main_panel.modulate.a = 1.0
		_main_panel.scale = Vector2(1.0, 1.0)
		get_tree().paused = false
		emit_signal("resume_pressed")
	)

func _save() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm:
		gm.save_game()
	# Краткое визуальное подтверждение
	var lbl := Label.new()
	lbl.text = "✅ Сохранено!"
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.position = Vector2(-60, 80)
	_main_panel.add_child(lbl)
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(lbl):
		lbl.queue_free()

func _go_to_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm and gm.health > 0: gm.save_game()
	var lb: Node = get_node_or_null("/root/LeaderboardManager")
	if lb: lb.try_add_entry()
	SceneTransition.go("res://scenes/MainMenu.tscn")

func _set_speed(spd: float) -> void:
	Engine.time_scale = spd
	_highlight_speed(spd)

func _highlight_speed(spd: float) -> void:
	for i in _speed_btns.size():
		var btn: Button = _speed_btns[i]
		if absf(SPEEDS[i] - spd) < 0.01:
			btn.modulate = Color(1.0, 0.85, 0.2)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)

# ── Helpers для строк настроек ────────────────────────────────────────────────

func _vol_icon(icons: Array, v: float) -> String:
	if v <= 0.001: return icons[0]
	if v < 0.5:    return icons[1]
	return icons[2]

func _pause_slider_row(parent: VBoxContainer, _sm, label: String, icons: Array, initial: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var ic := Label.new()
	ic.text = _vol_icon(icons, initial)
	ic.add_theme_font_size_override("font_size", 14)
	ic.custom_minimum_size = Vector2(22, 0)
	row.add_child(ic)
	var nm := Label.new()
	nm.text = label
	nm.add_theme_font_size_override("font_size", 12)
	nm.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	nm.custom_minimum_size = Vector2(52, 0)
	row.add_child(nm)
	var sl := HSlider.new()
	sl.min_value = 0.0; sl.max_value = 1.0; sl.step = 0.05
	sl.value = initial
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.custom_minimum_size = Vector2(0, 20)
	var sl_bg := StyleBoxFlat.new()
	sl_bg.bg_color = Color(0.15, 0.15, 0.24)
	for _s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sl_bg.set_corner_radius(_s, 4)
	sl.add_theme_stylebox_override("slider", sl_bg)
	var sl_fill := StyleBoxFlat.new()
	sl_fill.bg_color = Color(0.32, 0.42, 0.78)
	for _s in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		sl_fill.set_corner_radius(_s, 4)
	sl.add_theme_stylebox_override("grabber_area", sl_fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", sl_fill)
	sl.value_changed.connect(on_change)
	row.add_child(sl)
	var pct := Label.new()
	pct.text = "%d%%" % int(initial * 100)
	pct.custom_minimum_size = Vector2(34, 0)
	pct.add_theme_font_size_override("font_size", 11)
	pct.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
	row.add_child(pct)
	sl.value_changed.connect(func(v: float):
		pct.text = "%d%%" % int(v * 100)
		ic.text = _vol_icon(icons, v)
	)

func _pause_toggle_btn(parent: HBoxContainer, label: String, initial: bool, on_toggle: Callable) -> void:
	var btn := Button.new()
	btn.text = label + ": " + ("ВКЛ" if initial else "ВЫКЛ")
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 28)
	btn.add_theme_font_size_override("font_size", 11)
	var _mk := func(on: bool) -> void:
		btn.text = label + ": " + ("ВКЛ" if on else "ВЫКЛ")
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.10, 0.28, 0.10) if on else Color(0.22, 0.10, 0.10)
		s.border_color = Color(0.28, 0.62, 0.28) if on else Color(0.50, 0.18, 0.18)
		for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
			s.set_border_width(side, 1)
			s.set_corner_radius(side, 5)
		btn.add_theme_stylebox_override("normal", s)
		btn.add_theme_color_override("font_color", Color(0.50, 1.0, 0.50) if on else Color(1.0, 0.50, 0.50))
	_mk.call(initial)
	var _state := [initial]
	btn.pressed.connect(func():
		_state[0] = not _state[0]
		_mk.call(_state[0])
		on_toggle.call(_state[0])
	)
	parent.add_child(btn)

