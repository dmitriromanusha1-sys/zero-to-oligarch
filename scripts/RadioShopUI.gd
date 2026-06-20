extends CanvasLayer

var _gm: Node
var _am: Node
var _panel: Control
var _list: VBoxContainer

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
	_panel.size     = Vector2(480, 420)
	_panel.position = Vector2(-240, -210)
	var ps = StyleBoxFlat.new()
	ps.bg_color     = Color(0.040, 0.047, 0.100, 0.98)
	ps.border_color = Color(0.70, 0.30, 0.75, 0.90)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(14)
	_panel.add_theme_stylebox_override("panel", ps)
	_panel.clip_contents = true
	add_child(_panel)

	# ── Шапка ────────────────────────────────────────────────────────────────
	var hdr = PanelContainer.new()
	hdr.position = Vector2(0, 0)
	hdr.size     = Vector2(480, 54)
	var hps = StyleBoxFlat.new()
	hps.bg_color     = Color(0.085, 0.040, 0.100, 1.0)
	hps.border_color = Color(0.70, 0.30, 0.75, 0.50)
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
	ico.text = "📻"
	ico.add_theme_font_size_override("font_size", 24)
	hdr_row.add_child(ico)

	var t1 = Label.new()
	t1.text = "Магазин радио"
	t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t1.add_theme_font_size_override("font_size", 18)
	t1.add_theme_color_override("font_color", Color(1.0, 0.75, 0.95))
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

	# ── Тело (список станций) ──────────────────────────────────────────────────
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(0, 54)
	scroll.size     = Vector2(480, 366)
	_panel.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	var lm = StyleBoxEmpty.new()
	lm.content_margin_left = 14; lm.content_margin_right = 14
	lm.content_margin_top = 12;  lm.content_margin_bottom = 14
	var lwrap = PanelContainer.new()
	lwrap.add_theme_stylebox_override("panel", lm)
	lwrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lwrap.add_child(_list)
	scroll.add_child(lwrap)

func _refresh() -> void:
	for c in _list.get_children(): c.queue_free()

	var zm: Node = get_node_or_null("/root/ZoneManager")
	for st in _am.RADIO_STATIONS:
		_list.add_child(_make_station_card(st, zm))

func _make_station_card(st: Dictionary, zm: Node) -> PanelContainer:
	var owned: bool    = _am.is_station_owned(st.id)
	var selected: bool = _am.current_station == st.id
	var zone_ok: bool  = zm == null or zm.max_zone_reached >= st.zone_req

	var card = PanelContainer.new()
	var cs   = StyleBoxFlat.new()
	cs.bg_color     = Color(0.12, 0.06, 0.12, 0.85) if selected else Color(0.07, 0.07, 0.10, 0.75)
	cs.border_color = Color(0.85, 0.45, 0.85, 0.90) if selected else Color(0.30, 0.30, 0.40, 0.60)
	cs.set_border_width_all(2 if selected else 1)
	cs.set_corner_radius_all(8)
	cs.content_margin_left = 12; cs.content_margin_right  = 12
	cs.content_margin_top  = 8;  cs.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", cs)

	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	vb.add_child(top_row)

	var name_lbl = Label.new()
	name_lbl.text = "%s  %s" % [st.icon, st.name]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color",
		Color(1.0, 0.80, 0.95) if selected else Color(0.85, 0.86, 0.92))
	top_row.add_child(name_lbl)

	if selected:
		var now_lbl = Label.new()
		now_lbl.text = "▶ Играет"
		now_lbl.add_theme_font_size_override("font_size", 11)
		now_lbl.add_theme_color_override("font_color", Color(0.85, 0.45, 0.85))
		top_row.add_child(now_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = st.desc
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.60, 0.60, 0.68))
	vb.add_child(desc_lbl)

	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 8)
	vb.add_child(btn_row)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 32)
	btn.add_theme_font_size_override("font_size", 12)

	if selected:
		btn.text = "▶ Играет сейчас"
		btn.disabled = true
		_style_disabled(btn)
	elif owned:
		btn.text = "🔊 Включить"
		btn.add_theme_color_override("font_color", Color(0.65, 1.00, 0.65))
		_style_btn(btn, Color(0.08, 0.20, 0.10), Color(0.25, 0.62, 0.30, 0.80))
		var sid: String = st.id
		btn.pressed.connect(func(): _am.select_station(sid); _refresh())
	elif not zone_ok:
		btn.text = "🔒 Нужна зона: " + str(st.zone_req + 1)
		btn.disabled = true
		_style_disabled(btn)
	else:
		var cost_str: String = _gm.format_money(st.cost) if st.cost > 0 else "Бесплатно"
		btn.text = "💰 Купить — " + cost_str
		var can_afford: bool = _gm.money >= st.cost
		if can_afford:
			btn.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
			_style_btn(btn, Color(0.18, 0.13, 0.03), Color(0.70, 0.55, 0.15, 0.85))
			var sid2: String = st.id
			btn.pressed.connect(func():
				if _am.buy_station(sid2):
					_am.select_station(sid2)
				_refresh())
		else:
			btn.disabled = true
			_style_disabled(btn)

	btn_row.add_child(btn)
	return card

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
