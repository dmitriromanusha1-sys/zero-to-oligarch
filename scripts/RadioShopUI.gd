extends CanvasLayer

var _gm: Node
var _am: Node
var _panel: Control
var _content: VBoxContainer

func _ready() -> void:
	layer = 21
	visible = false
	add_to_group("radio_shop")
	_gm = get_node("/root/GameManager")
	_am = get_node("/root/AudioManager")
	_build_ui()

func open() -> void:
	_refresh()
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.93, 0.93)
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
	_panel.size = Vector2(540, 440)
	_panel.position = Vector2(-270, -220)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.040, 0.047, 0.100, 0.98)
	ps.border_color = Color(0.70, 0.30, 0.75, 0.90)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(14)
	_panel.add_theme_stylebox_override("panel", ps)
	_panel.clip_contents = true
	add_child(_panel)

	# Шапка
	var hdr = PanelContainer.new()
	hdr.position = Vector2(0, 0)
	hdr.size = Vector2(540, 52)
	var hps = StyleBoxFlat.new()
	hps.bg_color = Color(0.085, 0.040, 0.100, 1.0)
	hps.border_color = Color(0.70, 0.30, 0.75, 0.50)
	hps.set_border_width(SIDE_BOTTOM, 2)
	hps.set_corner_radius(CORNER_TOP_LEFT, 14)
	hps.set_corner_radius(CORNER_TOP_RIGHT, 14)
	hps.content_margin_left = 16; hps.content_margin_right = 10
	hps.content_margin_top = 8; hps.content_margin_bottom = 8
	hdr.add_theme_stylebox_override("panel", hps)
	_panel.add_child(hdr)
	var hdr_row = HBoxContainer.new()
	hdr_row.add_theme_constant_override("separation", 10)
	hdr.add_child(hdr_row)
	var ico = Label.new()
	ico.text = "📻"; ico.add_theme_font_size_override("font_size", 24)
	hdr_row.add_child(ico)
	var t1 = Label.new()
	t1.text = "Радиоприёмник"
	t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t1.add_theme_font_size_override("font_size", 18)
	t1.add_theme_color_override("font_color", Color(1.0, 0.75, 0.95))
	hdr_row.add_child(t1)
	var cls = Button.new()
	cls.text = "✖"; cls.custom_minimum_size = Vector2(36, 36)
	cls.add_theme_font_size_override("font_size", 14)
	cls.add_theme_color_override("font_color", Color.WHITE)
	var cbs = StyleBoxFlat.new()
	cbs.bg_color = Color(0.22, 0.07, 0.07); cbs.border_color = Color(0.55, 0.18, 0.18)
	cbs.set_border_width_all(1); cbs.set_corner_radius_all(6)
	cls.add_theme_stylebox_override("normal", cbs)
	var cbh = cbs.duplicate() as StyleBoxFlat
	cbh.bg_color = Color(0.40, 0.10, 0.10)
	cls.add_theme_stylebox_override("hover", cbh)
	cls.pressed.connect(_close)
	hdr_row.add_child(cls)

	# Контент
	_content = VBoxContainer.new()
	_content.position = Vector2(18, 64)
	_content.size = Vector2(504, 364)
	_content.add_theme_constant_override("separation", 12)
	_panel.add_child(_content)

func _unlocked_indices() -> Array:
	var arr: Array = []
	for i in _am.RADIO_STATIONS.size():
		if i <= _am.radio_level:
			arr.append(i)
	return arr

func _step_wave(dir: int) -> void:
	var unlocked := _unlocked_indices()
	if unlocked.size() <= 1:
		return
	var cur: int = _am.station_index(_am.current_station)
	var pos: int = unlocked.find(cur)
	if pos < 0: pos = 0
	pos = (pos + dir + unlocked.size()) % unlocked.size()
	_am.select_station(_am.RADIO_STATIONS[unlocked[pos]].id)
	_refresh()

# ── Перерисовка ────────────────────────────────────────────────────────────────
func _refresh() -> void:
	for c in _content.get_children():
		c.queue_free()
	_build_tuner_display()
	_build_scale()
	_content.add_child(_thin_sep())
	_build_upgrade_card()

# Большой дисплей текущей волны с кнопками ◀ ▶
func _build_tuner_display() -> void:
	var cur: Dictionary = _am._get_station(_am.current_station)
	var disp := PanelContainer.new()
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.02, 0.05, 0.04, 1.0)
	ds.border_color = Color(0.30, 0.70, 0.45, 0.70)
	ds.set_border_width_all(1); ds.set_corner_radius_all(10)
	ds.content_margin_left = 12; ds.content_margin_right = 12
	ds.content_margin_top = 10; ds.content_margin_bottom = 10
	disp.add_theme_stylebox_override("panel", ds)
	_content.add_child(disp)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	disp.add_child(row)

	var prev_btn := _arrow_btn("◀")
	prev_btn.pressed.connect(func(): _step_wave(-1))
	row.add_child(prev_btn)

	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(mid)

	var freq := Label.new()
	freq.text = "%s FM" % cur.get("freq", "—")
	freq.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	freq.add_theme_font_size_override("font_size", 30)
	freq.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65))
	freq.add_theme_constant_override("outline_size", 2)
	freq.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	mid.add_child(freq)

	var name_lbl := Label.new()
	name_lbl.text = "%s  %s" % [cur.get("icon", "📻"), cur.get("name", "")]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", Color(0.90, 0.92, 0.95))
	mid.add_child(name_lbl)

	var play_lbl := Label.new()
	play_lbl.text = "▶ играет"
	play_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_lbl.add_theme_font_size_override("font_size", 10)
	play_lbl.add_theme_color_override("font_color", Color(0.45, 0.80, 0.55))
	mid.add_child(play_lbl)

	var next_btn := _arrow_btn("▶")
	next_btn.pressed.connect(func(): _step_wave(1))
	row.add_child(next_btn)

	var only_one: bool = _unlocked_indices().size() <= 1
	prev_btn.disabled = only_one
	next_btn.disabled = only_one

# Шкала частот: засечки-волны, открытые яркие, закрытые с замком
func _build_scale() -> void:
	var scale_wrap := PanelContainer.new()
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.05, 0.05, 0.09, 0.9)
	ss.border_color = Color(0.30, 0.30, 0.42, 0.6)
	ss.set_border_width_all(1); ss.set_corner_radius_all(8)
	ss.content_margin_left = 8; ss.content_margin_right = 8
	ss.content_margin_top = 8; ss.content_margin_bottom = 8
	scale_wrap.add_theme_stylebox_override("panel", ss)
	_content.add_child(scale_wrap)

	var ticks := HBoxContainer.new()
	ticks.add_theme_constant_override("separation", 6)
	ticks.alignment = BoxContainer.ALIGNMENT_CENTER
	scale_wrap.add_child(ticks)

	for i in _am.RADIO_STATIONS.size():
		var st: Dictionary = _am.RADIO_STATIONS[i]
		var unlocked: bool = i <= _am.radio_level
		var is_cur: bool = _am.current_station == st.id
		var tick := Button.new()
		tick.custom_minimum_size = Vector2(86, 50)
		tick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tick.add_theme_font_size_override("font_size", 12)
		if unlocked:
			tick.text = "%s\n%s" % [st.get("freq", "—"), st.icon]
		else:
			tick.text = "🔒\n%s" % st.get("freq", "—")
		var col_bg: Color
		var col_brd: Color
		var col_fg: Color
		if is_cur:
			col_bg = Color(0.20, 0.08, 0.20); col_brd = Color(0.90, 0.45, 0.90); col_fg = Color(1.0, 0.85, 1.0)
		elif unlocked:
			col_bg = Color(0.09, 0.11, 0.14); col_brd = Color(0.40, 0.55, 0.55, 0.8); col_fg = Color(0.85, 0.92, 0.92)
		else:
			col_bg = Color(0.06, 0.06, 0.09); col_brd = Color(0.22, 0.22, 0.28, 0.6); col_fg = Color(0.40, 0.40, 0.46)
		var tb := StyleBoxFlat.new()
		tb.bg_color = col_bg; tb.border_color = col_brd
		tb.set_border_width_all(2 if is_cur else 1); tb.set_corner_radius_all(6)
		tick.add_theme_stylebox_override("normal", tb)
		var tbh := tb.duplicate() as StyleBoxFlat
		tbh.bg_color = col_bg.lightened(0.10)
		tick.add_theme_stylebox_override("hover", tbh)
		tick.add_theme_stylebox_override("disabled", tb)
		tick.add_theme_color_override("font_color", col_fg)
		tick.add_theme_color_override("font_disabled_color", col_fg)
		if unlocked and not is_cur:
			var sid: String = st.id
			tick.pressed.connect(func(): _am.select_station(sid); _refresh())
		else:
			tick.disabled = true
		ticks.add_child(tick)

# Карточка апгрейда антенны
func _build_upgrade_card() -> void:
	var card := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.set_corner_radius_all(8)
	cs.content_margin_left = 12; cs.content_margin_right = 12
	cs.content_margin_top = 10; cs.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", cs)
	_content.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	if _am.is_radio_maxed():
		cs.bg_color = Color(0.06, 0.10, 0.07, 0.9); cs.border_color = Color(0.30, 0.55, 0.35, 0.7)
		var done := Label.new()
		done.text = "✅ Антенна максимального уровня — открыты все волны"
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		done.autowrap_mode = TextServer.AUTOWRAP_WORD
		done.add_theme_font_size_override("font_size", 13)
		done.add_theme_color_override("font_color", Color(0.65, 1.0, 0.70))
		vb.add_child(done)
		return

	var nxt: Dictionary = _am.next_upgrade_station()
	var cost: int = _am.next_upgrade_cost()
	var zm: Node = get_node_or_null("/root/ZoneManager")
	var zone_ok: bool = zm == null or zm.max_zone_reached >= int(nxt.get("zone_req", 0))
	var can_afford: bool = _gm.money >= cost

	cs.bg_color = Color(0.10, 0.07, 0.04, 0.9); cs.border_color = Color(0.70, 0.55, 0.20, 0.7)

	var title := Label.new()
	title.text = "⬆ Улучшить антенну"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	vb.add_child(title)

	var info := Label.new()
	info.text = "Откроет волну: %s %s — %s FM" % [nxt.get("icon", ""), nxt.get("name", ""), nxt.get("freq", "—")]
	info.add_theme_font_size_override("font_size", 12)
	info.add_theme_color_override("font_color", Color(0.85, 0.86, 0.92))
	vb.add_child(info)

	var desc := Label.new()
	desc.text = nxt.get("desc", "")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.60, 0.60, 0.68))
	vb.add_child(desc)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 34)
	btn.add_theme_font_size_override("font_size", 13)
	if not zone_ok:
		btn.text = "🔒 Нужна зона: %d" % (int(nxt.get("zone_req", 0)) + 1)
		btn.disabled = true
		_style_disabled(btn)
	elif not can_afford:
		btn.text = "💰 Улучшить — %s (не хватает)" % _gm.format_money(cost)
		btn.disabled = true
		_style_disabled(btn)
	else:
		btn.text = "💰 Улучшить — %s" % _gm.format_money(cost)
		btn.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
		_style_btn(btn, Color(0.18, 0.13, 0.03), Color(0.70, 0.55, 0.15, 0.85))
		btn.pressed.connect(func():
			if _am.upgrade_radio():
				if _am.is_station_owned(nxt.id):
					_am.select_station(nxt.id)
				var a := get_node_or_null("/root/AudioManager")
				if a: a.play_buy()
			_refresh())
	vb.add_child(btn)

# ── Хелперы ────────────────────────────────────────────────────────────────────
func _arrow_btn(txt: String) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(46, 56)
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(0.85, 0.92, 0.95))
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.09, 0.11, 0.14); s.border_color = Color(0.40, 0.55, 0.55, 0.8)
	s.set_border_width_all(1); s.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = s.bg_color.lightened(0.12)
	b.add_theme_stylebox_override("hover", h)
	var d := s.duplicate() as StyleBoxFlat
	d.bg_color = Color(0.06, 0.06, 0.09); d.border_color = Color(0.20, 0.20, 0.26, 0.5)
	b.add_theme_stylebox_override("disabled", d)
	b.add_theme_color_override("font_disabled_color", Color(0.35, 0.35, 0.40))
	return b

func _thin_sep() -> ColorRect:
	var s := ColorRect.new()
	s.custom_minimum_size = Vector2(0, 1)
	s.color = Color(0.30, 0.30, 0.42, 0.5)
	return s

func _style_btn(btn: Button, bg: Color, border: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg; s.border_color = border
	s.set_border_width_all(1); s.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = bg.lightened(0.10)
	btn.add_theme_stylebox_override("hover", h)

func _style_disabled(btn: Button) -> void:
	btn.add_theme_color_override("font_color", Color(0.40, 0.40, 0.46))
	btn.add_theme_color_override("font_disabled_color", Color(0.40, 0.40, 0.46))
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.09, 0.09, 0.12); s.border_color = Color(0.22, 0.22, 0.28, 0.6)
	s.set_border_width_all(1); s.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("disabled", s)
	btn.add_theme_stylebox_override("normal", s)
